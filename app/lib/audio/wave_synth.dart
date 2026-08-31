import 'dart:math' as math;
import 'dart:typed_data';

/// Oscillator waveform shapes, matching decant.html's `tn()` helper
/// (CLAUDE.md Step 9 — "generate simple placeholder tones the same way the
/// HTML prototype did"). The HTML version drives a real-time Web Audio
/// oscillator; Dart has no equivalent, so this renders the same envelope
/// and waveform math to a short in-memory 16-bit PCM WAV buffer instead —
/// synthesized at runtime, never a bundled asset file, which is the part
/// of "synthesized, no files" that actually carries over.
enum WaveShape { sine, triangle, square, sawtooth }

const int kSynthSampleRate = 22050; // plenty for short accent tones, keeps buffers tiny

/// Renders one tone: linear 10ms attack to [volume], then an exponential
/// decay to silence over [duration] — the same envelope shape as `tn()`'s
/// `gain.linearRampToValueAtTime` + `gain.exponentialRampToValueAtTime`.
/// If [toFreq] is given, pitch sweeps from [freq] to [toFreq] exponentially
/// over [duration], mirroring `oscillator.frequency.exponentialRampToValueAtTime`.
Uint8List renderTone({
  required double freq,
  required double duration,
  WaveShape shape = WaveShape.sine,
  double volume = 0.13,
  double? toFreq,
}) {
  final sampleCount = (kSynthSampleRate * duration).round();
  final samples = Float64List(sampleCount);
  final ratio = (toFreq != null && toFreq != freq) ? toFreq / freq : 1.0;
  final lnRatio = math.log(ratio);
  const attack = 0.01;

  for (var i = 0; i < sampleCount; i++) {
    final t = i / kSynthSampleRate;

    // Phase = 2*pi * integral of instantaneous frequency from 0..t, matching
    // an exponential frequency ramp (or a constant tone when ratio == 1).
    final double phase;
    if (ratio == 1.0) {
      phase = 2 * math.pi * freq * t;
    } else {
      phase = 2 * math.pi * freq * duration / lnRatio * (math.pow(ratio, t / duration) - 1);
    }

    final wave = _waveAt(phase, shape);

    double env;
    if (t < attack) {
      env = volume * (t / attack);
    } else {
      // Exponential decay from volume to ~0.0001 over the remaining time.
      final decayT = (t - attack) / (duration - attack).clamp(1e-6, double.infinity);
      env = volume * math.pow(0.0001 / volume, decayT.clamp(0.0, 1.0));
    }

    samples[i] = wave * env;
  }

  return _pcm16Wav(samples);
}

/// One chord in a pad progression: the frequencies (Hz) sounding together.
typedef Chord = List<double>;

/// Renders a slowly evolving ambient pad: [chords] held in equal shares of
/// [duration], each one crossfading softly into the next, under a shared
/// raised-cosine envelope (fades in over the first 12%, out over the last
/// 12%) so consecutive loop iterations join seamlessly at silence. This is
/// the background-music half of Step 9 — same "synthesize it, don't ship a
/// file" approach as [renderTone] — but a moving chord progression instead
/// of one static chord held for the whole loop, which is what previously
/// read as a flat, grating drone on repeat. Every note is voiced as three
/// slightly detuned partials (a cheap chorus, avoiding the sterile sound of
/// a bare sine), there's a slow tremolo for a sense of breathing, and a
/// soft two-tap echo for a little space — all still just math, no assets.
Uint8List renderAmbientPad({
  required List<Chord> chords,
  required double duration,
  double volume = 0.05,
}) {
  assert(chords.isNotEmpty);
  final sampleCount = (kSynthSampleRate * duration).round();
  final samples = Float64List(sampleCount);
  final fadeSamples = (sampleCount * 0.12).round();
  final chordDuration = duration / chords.length;
  const crossfadeFrac = 0.3;

  double chordSampleAt(Chord chord, double t) {
    var mix = 0.0;
    for (final f in chord) {
      // Three-partial chorus (root + ~0.3% detuned above/below) rather than
      // one bare sine per note — the detuning is what keeps a held chord
      // from sounding like a sterile test tone.
      mix += math.sin(2 * math.pi * f * t) +
          0.5 * math.sin(2 * math.pi * f * 1.003 * t) +
          0.5 * math.sin(2 * math.pi * f * 0.997 * t);
    }
    return mix / (chord.length * 2);
  }

  for (var i = 0; i < sampleCount; i++) {
    final t = i / kSynthSampleRate;

    final chordIndex = (t / chordDuration).floor().clamp(0, chords.length - 1);
    final tInChord = t - chordIndex * chordDuration;
    final progress = tInChord / chordDuration;

    var mix = chordSampleAt(chords[chordIndex], t);
    final crossfadeStart = 1 - crossfadeFrac;
    if (progress > crossfadeStart) {
      final nextChord = chords[(chordIndex + 1) % chords.length];
      final blend = (progress - crossfadeStart) / crossfadeFrac;
      mix = mix * (1 - blend) + chordSampleAt(nextChord, t) * blend;
    }

    // Slow tremolo (~7.7s cycle) so a held chord still feels like it's
    // breathing rather than sitting perfectly static.
    final tremolo = 1 - 0.06 * math.sin(2 * math.pi * 0.13 * t);

    double env;
    if (i < fadeSamples) {
      env = 0.5 - 0.5 * math.cos(math.pi * i / fadeSamples);
    } else if (i > sampleCount - fadeSamples) {
      env = 0.5 - 0.5 * math.cos(math.pi * (sampleCount - i) / fadeSamples);
    } else {
      env = 1.0;
    }

    samples[i] = mix * volume * tremolo * env;
  }

  // Soft two-tap echo (slap-back at 0.35s/0.6s) read from the dry signal
  // computed above — adds a sense of space without a real feedback loop
  // that could build up and clip.
  final dry = Float64List.fromList(samples);
  final tap1 = (kSynthSampleRate * 0.35).round();
  final tap2 = (kSynthSampleRate * 0.6).round();
  for (var i = 0; i < sampleCount; i++) {
    if (i >= tap1) samples[i] += dry[i - tap1] * 0.22;
    if (i >= tap2) samples[i] += dry[i - tap2] * 0.12;
  }

  return _pcm16Wav(samples);
}

double _waveAt(double phase, WaveShape shape) {
  final cycles = phase / (2 * math.pi);
  final frac = cycles - cycles.floorToDouble(); // 0..1 position within the cycle
  switch (shape) {
    case WaveShape.sine:
      return math.sin(phase);
    case WaveShape.square:
      return frac < 0.5 ? 1.0 : -1.0;
    case WaveShape.sawtooth:
      return 2 * (frac - 0.5);
    case WaveShape.triangle:
      return 4 * (frac - 0.5).abs() - 1;
  }
}

/// Wraps [samples] (each in roughly [-1, 1]) as a minimal mono 16-bit PCM
/// WAV file — the smallest container audioplayers' BytesSource can decode
/// on every platform without a codec.
Uint8List _pcm16Wav(Float64List samples) {
  const bitsPerSample = 16;
  const channels = 1;
  const byteRate = kSynthSampleRate * channels * bitsPerSample ~/ 8;
  final dataLength = samples.length * 2;
  final buffer = ByteData(44 + dataLength);

  void writeString(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // fmt chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, channels, Endian.little);
  buffer.setUint32(24, kSynthSampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);
  writeString(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    buffer.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }

  return buffer.buffer.asUint8List();
}
