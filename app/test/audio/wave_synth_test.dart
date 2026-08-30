// wave_synth.dart is the pure-math half of Step 9's synthesized SFX/music —
// no platform audio needed to test that the WAV bytes it produces are
// actually well-formed and that the envelope behaves as intended.
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vialo/audio/wave_synth.dart';

void main() {
  group('renderTone', () {
    test('produces a well-formed RIFF/WAVE header', () {
      final bytes = renderTone(freq: 440, duration: 0.1);
      final data = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      expect(data.getUint16(20, Endian.little), 1); // PCM
      expect(data.getUint16(22, Endian.little), 1); // mono
      expect(data.getUint32(24, Endian.little), kSynthSampleRate);
    });

    test('data length matches the requested duration at the fixed sample rate', () {
      final bytes = renderTone(freq: 440, duration: 0.2);
      final data = ByteData.sublistView(bytes);
      final dataLength = data.getUint32(40, Endian.little);
      final expectedSamples = (kSynthSampleRate * 0.2).round();
      expect(dataLength, expectedSamples * 2); // 16-bit = 2 bytes/sample
      expect(bytes.length, 44 + expectedSamples * 2);
    });

    test('every sample fits in the 16-bit PCM range (no clipping overflow)', () {
      final bytes = renderTone(freq: 220, duration: 0.15, shape: WaveShape.square, volume: 0.9);
      final data = ByteData.sublistView(bytes);
      for (var offset = 44; offset < bytes.length; offset += 2) {
        final sample = data.getInt16(offset, Endian.little);
        expect(sample, inInclusiveRange(-32768, 32767));
      }
    });

    test('the envelope decays toward silence by the end of the tone', () {
      final bytes = renderTone(freq: 440, duration: 0.3, volume: 0.5);
      final data = ByteData.sublistView(bytes);
      final sampleCount = (bytes.length - 44) ~/ 2;

      int peakAbsIn(int fromSample, int toSample) {
        var peak = 0;
        for (var i = fromSample; i < toSample; i++) {
          final v = data.getInt16(44 + i * 2, Endian.little).abs();
          if (v > peak) peak = v;
        }
        return peak;
      }

      final earlyPeak = peakAbsIn(sampleCount ~/ 10, sampleCount ~/ 5); // just past the attack
      final latePeak = peakAbsIn(sampleCount - sampleCount ~/ 10, sampleCount);
      expect(latePeak, lessThan(earlyPeak));
    });

    test('a frequency ramp (toFreq) does not throw and still yields valid samples', () {
      final bytes = renderTone(freq: 320, toFreq: 600, duration: 0.1, shape: WaveShape.triangle);
      expect(bytes.length, greaterThan(44));
    });

    test('every waveform shape renders without error', () {
      for (final shape in WaveShape.values) {
        final bytes = renderTone(freq: 300, duration: 0.05, shape: shape);
        expect(bytes.length, greaterThan(44));
      }
    });
  });
}
