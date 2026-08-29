// Port of the RNG and board-generation utilities from decant.html's
// `/* ================= ENGINES ================= */` section.
//
// Critical: `mb32` must produce byte-identical output to the JS version for
// the same seed. JS's bitwise operators (`|0`, `>>>`, `Math.imul`) all work
// on 32-bit values; Dart's `int` is 64-bit, so every step below explicitly
// masks to 32 bits via `toSigned(32)`/`toUnsigned(32)` at exactly the points
// where JS's implicit ToInt32/ToUint32 coercions would happen. See Phase 1
// of flutter_port_plan.md — every tuned balance number depends on this.
library;

import 'constants.dart';

int _toInt32(int x) => x.toSigned(32);
int _toUint32(int x) => x.toUnsigned(32);
int _imul(int a, int b) => (_toInt32(a) * _toInt32(b)).toSigned(32);

/// Bit-for-bit port of the JS `mb32` mulberry32 PRNG. Returns a generator
/// function producing doubles in `[0, 1)`, matching `mb32(seed)()` in JS.
double Function() mb32(int seed) {
  int a = seed;
  return () {
    a = _toInt32(a);
    a = _toInt32(a + 0x6D2B79F5);
    int t = _imul(a ^ (_toUint32(a) >> 15), 1 | a);
    t = _toInt32((t + _imul(t ^ (_toUint32(t) >> 7), 61 | t)) ^ t);
    return _toUint32(t ^ (_toUint32(t) >> 14)) / 4294967296.0;
  };
}

/// A reverse move used only to scramble a freshly-solved board: take [k]
/// items of the top colour off the top of tube [d] and place them on tube
/// [s] (which must not already show that colour on top — that would just be
/// an ordinary forward pour, not a scramble).
class InvMove {
  final int d;
  final int s;
  final int k;
  const InvMove(this.d, this.s, this.k);
}

/// Port of `invMoves` from decant.html.
List<InvMove> invMoves(List<List<int>> tubes) {
  final out = <InvMove>[];
  for (var d = 0; d < tubes.length; d++) {
    final t = tubes[d];
    if (t.isEmpty) continue;
    final x = t.last;
    var r = 0;
    for (var i = t.length - 1; i >= 0 && t[i] == x; i--) {
      r++;
    }
    for (var s = 0; s < tubes.length; s++) {
      if (s == d) continue;
      final sp = kCap - tubes[s].length;
      if (sp <= 0) continue;
      if (tubes[s].isNotEmpty && tubes[s].last == x) continue;
      final mk = r < sp ? r : sp;
      for (var k = 1; k <= mk; k++) {
        out.add(InvMove(d, s, k));
      }
    }
  }
  return out;
}

/// Port of `genTubes` from decant.html: builds [c] full colour tubes plus
/// [e] empty tubes, then scrambles the board via random *reverse* legal
/// moves from the solved state, so the result is always solvable.
List<List<int>> genTubes(int seed, int c, int e) {
  final rnd = mb32(seed);
  final tb = <List<int>>[];
  for (var i = 0; i < c; i++) {
    tb.add([i, i, i, i]);
  }
  for (var i = 0; i < e; i++) {
    tb.add(<int>[]);
  }
  for (var i = 0; i < c * 20; i++) {
    final m = invMoves(tb);
    if (m.isEmpty) break;
    final mv = m[(rnd() * m.length).floor()];
    for (var j = 0; j < mv.k; j++) {
      tb[mv.s].add(tb[mv.d].removeLast());
    }
  }
  return tb;
}

/// Port of `shuffleN` from decant.html: Fisher–Yates partial shuffle,
/// returning the first [k] of a shuffled `0..n-1` sequence. Used by Recipe
/// to deal each player's secret formula.
List<int> shuffleN(int n, int k, double Function() rnd) {
  final a = List<int>.generate(n, (i) => i);
  for (var i = a.length - 1; i > 0; i--) {
    final j = (rnd() * (i + 1)).floor();
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a.sublist(0, k);
}
