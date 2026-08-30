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

/// Renders a soft looping pad: a chord of sine tones under one shared
/// raised-cosine envelope (fades in over the first 12%, out over the last
/// 12%, flat in between) so consecutive loop iterations join seamlessly at
/// silence rather than clicking. This is the placeholder background-music
/// half of Step 9 — same "synthesize it, don't ship a file" approach as
/// [renderTone], just shaped for looping instead of a one-shot accent.
Uint8List renderPad({required List<double> freqs, required double duration, double volume = 0.05}) {
  final sampleCount = (kSynthSampleRate * duration).round();
  final samples = Float64List(sampleCount);
  final fadeSamples = (sampleCount * 0.12).round();

  for (var i = 0; i < sampleCount; i++) {
    final t = i / kSynthSampleRate;
    double mix = 0;
    for (final f in freqs) {
      mix += math.sin(2 * math.pi * f * t);
    }
    mix /= freqs.length;

    double env;
    if (i < fadeSamples) {
      env = 0.5 - 0.5 * math.cos(math.pi * i / fadeSamples);
    } else if (i > sampleCount - fadeSamples) {
      env = 0.5 - 0.5 * math.cos(math.pi * (sampleCount - i) / fadeSamples);
    } else {
      env = 1.0;
    }

    samples[i] = mix * volume * env;
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
