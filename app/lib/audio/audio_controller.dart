import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class AudioController {
  final SfxLibrary _sfx = SfxLibrary();
  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _poolIndex = 0;
  final AudioPlayer _music = AudioPlayer();
  final ProfileController _profile;

  bool _contextReady = false;
  String? _currentTrack; // 'menu' | 'game' | null

  AudioController(this._profile);

  // ---- lazily-rendered, calm-vs-lighter looping pads --------------------

  Uint8List? _menuTrack;
  Uint8List _menuTrackBytes() => _menuTrack ??= renderPad(
        freqs: const [261.63, 329.63, 392.00], // C4 E4 G4 — calm, for menu screens
        duration: 6,
        volume: 0.045,
      );

  Uint8List? _gameTrack;
  Uint8List _gameTrackBytes() => _gameTrack ??= renderPad(
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

  // ---- SFX ----------------------------------------------------------------

  Future<void> _playOne(Uint8List bytes) async {
    if (_profile.currentProfile.muted) return;
    try {
      await _ensureContext();
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
      await player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('AudioController: sfx playback unavailable: $e');
    }
  }

  void _playSequence(List<Uint8List> tones, int staggerMs) {
    for (var i = 0; i < tones.length; i++) {
      if (i == 0) {
        unawaited(_playOne(tones[i]));
      } else {
        Future.delayed(Duration(milliseconds: i * staggerMs), () => _playOne(tones[i]));
      }
    }
  }

  /// Generic UI tap — also used for tube/tile pickup on selection.
  void pick() => unawaited(_playOne(_sfx.pick()));
  void buttonTap() => unawaited(_playOne(_sfx.tap()));
  void pourDrip(int i) => unawaited(_playOne(_sfx.drip(i)));
  void splash() => _playSequence(_sfx.splash(), 0);
  void claim() => _playSequence(_sfx.claim(), 85);
  void fuseMerge(int value) => unawaited(_playOne(_sfx.fuse(value)));
  void invalidMove() => unawaited(_playOne(_sfx.bad()));
  void levelWin() => _playSequence(_sfx.win(), 100);
  void levelLose() => _playSequence(_sfx.lose(), 140);
  void coinGain() => _playSequence(_sfx.coinGain(), 40);

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
      await _music.play(BytesSource(track == 'menu' ? _menuTrackBytes() : _gameTrackBytes()), volume: 0.35);
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
