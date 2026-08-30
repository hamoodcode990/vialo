import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../state/profile_provider.dart';
import 'sfx_library.dart';
import 'wave_synth.dart';

/// Glues the synthesized SFX/music (CLAUDE.md Step 9) to the profile's
/// independent `muted` (SFX) / `musicMuted` toggles — the Store/Settings
/// screens never touch audioplayers directly, same role
/// MonetizationController plays for purchases. Every public method
/// degrades silently on any failure (no audio backend on this platform,
/// player init failure, etc.) rather than throwing, matching
/// PurchaseService/AdsService/CloudProfileSync's contract.
///
/// Plays from real temp `.wav` files rather than audioplayers' `BytesSource`
/// directly, for two concrete reasons found by reading the plugin's own
/// source (not guessed):
/// 1. On iOS/macOS/Linux, `BytesSource` writes to an *extensionless* temp
///    file internally and, unless a `mimeType` is supplied, hands it to
///    AVFoundation with no format hint at all — a very plausible reason
///    for silent (no error, no sound) playback failure. Writing our own
///    `.wav`-named file up front and always passing `mimeType: 'audio/wav'`
///    removes that ambiguity entirely.
/// 2. `BytesSource` re-does that temp-file write on *every single play*,
///    even for a tone played a hundred times a session — real (if small)
///    disk I/O on every pour drip, on the UI thread's critical path,
///    during exactly the moments (staggered pour animations) most likely
///    to read as stutter. Caching one file per tone and reusing it turns
///    every play after the first into pure playback, no I/O.
class AudioController {
  final SfxLibrary _sfx = SfxLibrary();
  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency));
  int _poolIndex = 0;
  final AudioPlayer _music = AudioPlayer();
  final ProfileController _profile;

  bool _contextReady = false;
  String? _currentTrack; // 'menu' | 'game' | null
  final Map<String, String> _filePaths = {}; // tone key -> cached .wav file path

  AudioController(this._profile);

  // ---- lazily-rendered, calm-vs-lighter looping pads --------------------

  Uint8List _menuTrackBytes() => renderPad(
        freqs: const [261.63, 329.63, 392.00], // C4 E4 G4 — calm, for menu screens
        duration: 6,
        volume: 0.045,
      );

  Uint8List _gameTrackBytes() => renderPad(
        freqs: const [293.66, 369.99, 440.00], // D4 F#4 A4 — a touch brighter, for gameplay
        duration: 4,
        volume: 0.05,
      );

  Future<void> _ensureContext() async {
    if (_contextReady) return;
    _contextReady = true;
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(respectSilence: true).build());
    } catch (e) {
      debugPrint('AudioController: could not set shared audio context: $e');
    }
  }

  /// Writes [render]'s bytes to a stable `.wav` file the first time [key] is
  /// requested, then reuses that same file path on every later call.
  Future<String> _fileFor(String key, Uint8List Function() render) async {
    final cached = _filePaths[key];
    if (cached != null) return cached;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vialo_audio_$key.wav';
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsBytes(render(), flush: true);
    }
    _filePaths[key] = path;
    return path;
  }

  // ---- SFX ----------------------------------------------------------------

  Future<void> _play(String key, Uint8List Function() render) async {
    if (_profile.currentProfile.muted) return;
    try {
      await _ensureContext();
      final path = await _fileFor(key, render);
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
      await player.play(DeviceFileSource(path, mimeType: 'audio/wav'));
    } catch (e) {
      debugPrint('AudioController: sfx playback unavailable: $e');
    }
  }

  void _playSequence(String keyPrefix, List<Uint8List> tones, int staggerMs) {
    for (var i = 0; i < tones.length; i++) {
      final key = '${keyPrefix}_$i';
      if (i == 0) {
        unawaited(_play(key, () => tones[i]));
      } else {
        Future.delayed(Duration(milliseconds: i * staggerMs), () => _play(key, () => tones[i]));
      }
    }
  }

  /// Generic UI tap — also used for tube/tile pickup on selection.
  void pick() => unawaited(_play('pick', _sfx.pick));
  void buttonTap() => unawaited(_play('tap', _sfx.tap));
  void pourDrip(int i) => unawaited(_play('drip_$i', () => _sfx.drip(i)));
  void splash() => _playSequence('splash', _sfx.splash(), 0);
  void claim() => _playSequence('claim', _sfx.claim(), 85);
  void fuseMerge(int value) => unawaited(_play('fuse_$value', () => _sfx.fuse(value)));
  void invalidMove() => unawaited(_play('bad', _sfx.bad));
  void levelWin() => _playSequence('win', _sfx.win(), 100);
  void levelLose() => _playSequence('lose', _sfx.lose(), 140);
  void coinGain() => _playSequence('coin', _sfx.coinGain(), 40);

  // ---- music ----------------------------------------------------------------

  Future<void> playMenuMusic() => _playTrack('menu');
  Future<void> playGameMusic() => _playTrack('game');

  Future<void> _playTrack(String track) async {
    if (_currentTrack == track) return;
    _currentTrack = track;
    if (_profile.currentProfile.musicMuted) return;
    try {
      await _ensureContext();
      await _music.setReleaseMode(ReleaseMode.loop);
      final path = await _fileFor('music_$track', track == 'menu' ? _menuTrackBytes : _gameTrackBytes);
      await _music.play(DeviceFileSource(path, mimeType: 'audio/wav'), volume: 0.35);
    } catch (e) {
      debugPrint('AudioController: music playback unavailable: $e');
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Call after the music-mute toggle changes so a currently-playing (or
  /// currently-silenced) track responds immediately instead of waiting for
  /// the next screen transition.
  Future<void> refreshMusicMuteState() async {
    final track = _currentTrack;
    if (track == null) return;
    if (_profile.currentProfile.musicMuted) {
      try {
        await _music.stop();
      } catch (_) {}
    } else {
      _currentTrack = null; // force _playTrack to actually (re)start it
      await _playTrack(track);
    }
  }

  void dispose() {
    for (final p in _sfxPool) {
      p.dispose();
    }
    _music.dispose();
  }
}

final audioControllerProvider = Provider<AudioController>((ref) {
  final ctrl = AudioController(ref.watch(profileControllerProvider.notifier));
  ref.onDispose(ctrl.dispose);
  return ctrl;
});
