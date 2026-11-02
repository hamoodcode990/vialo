// Measures the board colours the same way decant.html's palette audit did:
// CIE76 distance in Lab, both as-is and through the Machado et al. 2009
// deuteranopia matrix. Run with --reporter expanded to see the numbers.
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vialo/game/level_curves.dart';
import 'package:vialo/theme/board_colors.dart';
import 'package:vialo/theme/tube_palettes.dart';

double _lin(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _gam(double c) => c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;

List<double> _lab(double r, double g, double b) {
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) => t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

double _dist(List<double> a, List<double> b) =>
    math.sqrt(math.pow(a[0] - b[0], 2) + math.pow(a[1] - b[1], 2) + math.pow(a[2] - b[2], 2));

List<double> _normal(Color c) => _lab(_lin(c.r), _lin(c.g), _lin(c.b));

List<double> _deut(Color c) {
  final r = _lin(c.r), g = _lin(c.g), b = _lin(c.b);
  double cl(double v) => v.clamp(0.0, 1.0);
  final r2 = cl(0.367322 * r + 0.860646 * g - 0.227968 * b);
  final g2 = cl(0.280085 * r + 0.672501 * g + 0.047413 * b);
  final b2 = cl(-0.011820 * r + 0.042940 * g + 0.968881 * b);
  // Round trip through gamma so the clamp above is the only distortion.
  return _lab(_lin(_gam(r2)), _lin(_gam(g2)), _lin(_gam(b2)));
}

double _minPair(List<Color> cs, List<double> Function(Color) f) {
  var best = double.infinity;
  for (var i = 0; i < cs.length; i++) {
    for (var j = i + 1; j < cs.length; j++) {
      best = math.min(best, _dist(f(cs[i]), f(cs[j])));
    }
  }
  return best;
}

String _hex(Color c) => c.toARGB32().toRadixString(16).substring(2).toUpperCase();

void main() {
  group('every palette', () {
    for (final p in kTubePalettes) {
      test('${p.id}: extra colours never lower the palette\'s own measured minimum', () {
        final all = boardColours(p);
        expect(all.toSet().length, kBoardColourCount);
        expect(all.take(9).toList(), p.colors, reason: 'audited slots must stay untouched');
        final report = '${p.id} palette ${_minPair(p.colors, _normal).toStringAsFixed(1)}/${_minPair(p.colors, _deut).toStringAsFixed(1)} '
            'all13 ${_minPair(all, _normal).toStringAsFixed(1)}/${_minPair(all, _deut).toStringAsFixed(1)}';
        // ignore: avoid_print
        print(report);
        expect(_minPair(all, _normal), greaterThanOrEqualTo(_minPair(p.colors, _normal) - 0.001));
        expect(_minPair(all, _deut), greaterThanOrEqualTo(_minPair(p.colors, _deut) - 0.001));
      });

      test('${p.id}: gold stands apart from every Split player colour', () {
        final players = splitPlayerColours(p);
        expect(players.length, greaterThanOrEqualTo(10), reason: 'Split levels 126-150 need 10');
        var n = double.infinity, d = double.infinity;
        for (final c in players.take(10)) {
          n = math.min(n, _dist(_normal(c), _normal(kMetallicGold)));
          d = math.min(d, _dist(_deut(c), _deut(kMetallicGold)));
        }
        final split = [...players.take(10), kMetallicGold];
        // ignore: avoid_print
        print('${p.id} gold-to-player ${n.toStringAsFixed(1)}/${d.toStringAsFixed(1)} '
            'split11 ${_minPair(split, _normal).toStringAsFixed(1)}/${_minPair(split, _deut).toStringAsFixed(1)} '
            'first ${players.take(6).map(_hex).join(",")}');
        expect(n, greaterThan(25));
        expect(d, greaterThan(15));
      });
    }
  });

  test('the neutral renders as the same gold at every Split tier', () {
    for (var level = 1; level <= kLevelCounts['split']!; level++) {
      final cfg = splitLvlCfg(level);
      for (final p in kTubePalettes) {
        expect(splitColour(p, cfg.own * 2, cfg.own), kMetallicGold);
      }
    }
    expect(splitColour(kTubePalettes.first, 6, 3), kMetallicGold);
  });

  test('no two engine colours draw the same on any Split, Pour or Solo level', () {
    for (final p in kTubePalettes) {
      for (var level = 1; level <= kLevelCounts['split']!; level++) {
        final cfg = splitLvlCfg(level);
        final shown = {for (var i = 0; i < cfg.colors; i++) splitColour(p, i, cfg.own)};
        expect(shown.length, cfg.colors, reason: '${p.id} split $level');
      }
      for (var level = 1; level <= kLevelCounts['pour']!; level++) {
        final c = pourLvlCfg(level).colors;
        expect({for (var i = 0; i < c; i++) boardColour(p, i)}.length, c, reason: '${p.id} pour $level');
      }
      for (var level = 1; level <= kLevelCounts['solo']!; level++) {
        final c = soloCfg(level).colors;
        expect({for (var i = 0; i < c; i++) boardColour(p, i)}.length, c, reason: '${p.id} solo $level');
      }
    }
  });
}
