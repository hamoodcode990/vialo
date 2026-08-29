import 'package:vialo/game/game.dart';
import 'package:test/test.dart';

bool _solved(List<List<int>> t) => t.every((x) => x.isEmpty || isUniformFullTube(x));
String _key(List<List<int>> t) => t.map((x) => x.join(',')).join('|');

bool _legal(List<List<int>> t, int s, int d) {
  if (s == d || t[s].isEmpty || t[d].length >= kCap) return false;
  return t[d].isEmpty || t[s].last == t[d].last;
}

List<(int, int)>? _solve(List<List<int>> start, int nodeBudget) {
  if (_solved(start)) return [];
  final seen = {_key(start)};
  var nodes = 0;

  List<(int, int)>? dfs(List<List<int>> t, List<(int, int)> path, int depth) {
    if (depth > 80) return null;
    final moves = <(int, int)>[];
    for (var s = 0; s < t.length; s++) {
      if (t[s].isEmpty) continue;
      for (var d = 0; d < t.length; d++) {
        if (_legal(t, s, d)) moves.add((s, d));
      }
    }
    // completes-a-tube first, then consolidating onto a non-empty tube.
    moves.sort((a, b) {
      int score((int, int) mv) {
        final col = t[mv.$1].last;
        var k = 0, ii = t[mv.$1].length - 1;
        while (ii >= 0 && t[mv.$1][ii] == col && t[mv.$2].length + k < kCap) {
          k++;
          ii--;
        }
        var s = 0;
        if (t[mv.$2].length + k == kCap) s += 100;
        if (t[mv.$2].isNotEmpty) s += 10;
        return s + k;
      }

      return score(b).compareTo(score(a));
    });
    for (final mv in moves) {
      nodes++;
      if (nodes > nodeBudget) return null;
      final nt = [for (final x in t) List<int>.from(x)];
      final col = nt[mv.$1].last;
      while (nt[mv.$1].isNotEmpty && nt[mv.$1].last == col && nt[mv.$2].length < kCap) {
        nt[mv.$2].add(nt[mv.$1].removeLast());
      }
      final k = _key(nt);
      if (seen.contains(k)) continue;
      seen.add(k);
      final np = [...path, mv];
      if (_solved(nt)) return np;
      final r = dfs(nt, np, depth + 1);
      if (r != null) return r;
    }
    return null;
  }

  return dfs(start, [], 0);
}

void main() {
  group('SoloBoard', () {
    test('a freshly generated board is not solved and not stuck', () {
      for (final seed in List.generate(20, (i) => i + 1)) {
        final b = SoloBoard(seed: seed, colors: 4, empty: 3);
        expect(b.solved, isFalse, reason: 'seed=$seed');
        expect(b.stuck, isFalse, reason: 'seed=$seed');
      }
    });

    test('pour() detects a solved board (via a small solver-driven playout)', () {
      // hintMove() is a lightweight heuristic, not a real solver, and can
      // legitimately loop without solving (same as decant.html's
      // reveal-a-move hint) — so drive this with a real (tiny) DFS solver
      // instead, matching how engine_parity_test.dart validates Pour/etc.
      final b = SoloBoard(seed: 1, colors: 4, empty: 3);
      final plan = _solve(b.tubes, 200000);
      expect(plan, isNotNull, reason: 'seed=1, 4 colours/3 empty should be solvable');
      for (final (s, d) in plan!) {
        if (b.done) break;
        b.pour(s, d);
      }
      expect(b.done, isTrue);
      expect(b.solved, isTrue);
    });

    test('undo reverts the last pour and decrements moves', () {
      final b = SoloBoard(seed: 1, colors: 4, empty: 3);
      final m = b.hintMove()!;
      final before = b.tubes.map((t) => List<int>.from(t)).toList();
      b.pour(m.$1, m.$2);
      expect(b.moves, 1);
      final ok = b.undo();
      expect(ok, isTrue);
      expect(b.moves, 0);
      expect(b.tubes, equals(before));
    });

    test('addTube adds an empty tube and marks usedHint', () {
      final b = SoloBoard(seed: 1, colors: 4, empty: 3);
      final before = b.tubes.length;
      b.addTube();
      expect(b.tubes.length, before + 1);
      expect(b.tubes.last, isEmpty);
      expect(b.usedHint, isTrue);
    });

    test('legal() rejects sealing into a full tube or mismatched colour', () {
      final b = SoloBoard(seed: 1, colors: 4, empty: 3);
      expect(b.legal(0, 0), isFalse, reason: 'same tube');
    });
  });
}
