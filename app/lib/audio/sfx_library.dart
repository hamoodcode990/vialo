import 'dart:typed_data';

import 'wave_synth.dart';

/// The full set of SFX tones (CLAUDE.md Step 9), ported note-for-note from
/// decant.html's `SFX` object (see decant.html's SOUND section) — same
/// frequencies/durations/waveforms/volumes — plus two the HTML prototype
/// didn't need (`tap`, `coinGain`) that this batch's SFX list calls for.
/// Bytes are rendered once per shape (lazily, on first use) and cached,
/// since these are pure functions of their (small, fixed) parameters.
class SfxLibrary {
  final Map<String, Uint8List> _cache = {};

  Uint8List _cached(String key, Uint8List Function() render) => _cache.putIfAbsent(key, render);

  /// Tube/tile lift on selection tap — reused as the generic "button tap" cue.
  Uint8List pick() => _cached('pick', () => renderTone(freq: 560, duration: 0.06, volume: 0.08));

  Uint8List tap() => pick();

  /// One droplet departing the source tube; `i` is the drop's stagger index.
  Uint8List drip(int i) => _cached(
        'drip$i',
        () => renderTone(freq: 320 + i * 60, duration: 0.1, shape: WaveShape.triangle, volume: 0.09, toFreq: 540 + i * 60),
      );

  /// Both tones fire together — caller plays them back to back with no gap.
  List<Uint8List> splash() => [
        _cached('splash1', () => renderTone(freq: 200, duration: 0.08, volume: 0.10)),
        _cached('splash2', () => renderTone(freq: 680, duration: 0.05, shape: WaveShape.triangle, volume: 0.05)),
      ];

  /// Three-note chime, one entry per staggered ~85ms step — a tube/tile
  /// sealing/claiming.
  List<Uint8List> claim() => [700, 930, 1400]
      .asMap()
      .entries
      .map((e) => _cached(
            'claim${e.key}',
            () => renderTone(freq: e.value.toDouble(), duration: 0.16, shape: WaveShape.triangle, volume: 0.14 - e.key * 0.02),
          ))
      .toList();

  /// A Fuse merge; `v` is the resulting tile's value.
  Uint8List fuse(int v) => _cached(
        'fuse$v',
        () => renderTone(freq: 300 + v * 130, duration: 0.14, shape: WaveShape.square, volume: 0.09, toFreq: 520 + v * 130),
      );

  /// Invalid move.
  Uint8List bad() => _cached('bad', () => renderTone(freq: 140, duration: 0.12, shape: WaveShape.sawtooth, volume: 0.06, toFreq: 80));

  /// Five-note ascending run, staggered ~100ms per step — level win.
  List<Uint8List> win() => [523, 659, 784, 1047, 1319]
      .asMap()
      .entries
      .map((e) => _cached('win${e.key}', () => renderTone(freq: e.value.toDouble(), duration: 0.3, shape: WaveShape.triangle, volume: 0.13)))
      .toList();

  /// Three-note descending run, staggered ~140ms per step — level lose.
  List<Uint8List> lose() => [440, 370, 294]
      .asMap()
      .entries
      .map((e) => _cached('lose${e.key}', () => renderTone(freq: e.value.toDouble(), duration: 0.32, volume: 0.10)))
      .toList();

  /// A short bright two-note cue — coin gain. Not in the HTML reference
  /// (it has no coin-gain moment outside the same UI flow as claim/win), so
  /// this is new, kept in the same synthesized-tone style as the rest.
  List<Uint8List> coinGain() => [
        _cached('coin1', () => renderTone(freq: 880, duration: 0.08, shape: WaveShape.triangle, volume: 0.10, toFreq: 1200)),
        _cached('coin2', () => renderTone(freq: 1200, duration: 0.06, volume: 0.08)),
      ];
}
