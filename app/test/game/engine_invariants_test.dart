// Phase 2 invariant tests — port of the checks flutter_port_plan.md requires
// before any UI work begins. These guard the *rules*, independent of the
// JS-parity fixture in engine_parity_test.dart.
import 'package:vialo/game/game.dart';
import 'package:test/test.dart';

final _seeds = List<int>.generate(50, (i) => i + 1);

Map<int, int> _colorCounts(List<List<int>> tubes) {
  final counts = <int, int>{};
  for (final t in tubes) {
    for (final v in t) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
  }
  return counts;
}

void main() {
  group('genTubes reproducibility', () {
    test('the same seed always produces an identical board', () {
      for (final seed in _seeds) {
        final a = genTubes(seed, 9, 5);
        final b = genTubes(seed, 9, 5);
        expect(a, equals(b), reason: 'seed=$seed');
      }
    });
  });

  group('no board is born solved or stuck', () {
    test('Pour: fresh board is never already solved', () {
      for (final seed in _seeds) {
        final tubes = genTubes(seed, 9, 5);
        final solved = tubes.every((t) => t.isEmpty || isUniformFullTube(t));
        expect(solved, isFalse, reason: 'seed=$seed');
      }
    });

    test('Pour/Split/Recipe: fresh board always has a legal move', () {
      for (final seed in _seeds) {
        expect(Pour(seed, 9, 5).moves(), isNotEmpty, reason: 'Pour seed=$seed');
        expect(Split(seed, 7, 3, 3).moves(), isNotEmpty, reason: 'Split seed=$seed');
        expect(Recipe(seed).moves(), isNotEmpty, reason: 'Recipe seed=$seed');
      }
    });

    test('Fuse: fresh grid always has a legal move', () {
      for (final seed in _seeds) {
        expect(Fuse(seed).moves(), isNotEmpty, reason: 'Fuse seed=$seed');
      }
    });
  });

  group('piece counts conserved', () {
    test('Pour: colour counts are unchanged by any sequence of legal moves', () {
      for (final seed in _seeds.take(15)) {
        final g = Pour(seed, 9, 5);
        final before = _colorCounts(g.tubes);
        var guard = 0;
        while (!g.over && guard < 200) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          g.act(s, d);
          guard++;
        }
        final after = _colorCounts(g.tubes);
        expect(after, equals(before), reason: 'seed=$seed');
      }
    });

    test('Split: colour counts are unchanged by any sequence of legal moves', () {
      for (final seed in _seeds.take(15)) {
        final g = Split(seed, 7, 3, 3);
        final before = _colorCounts(g.tubes);
        var guard = 0;
        while (!g.over && guard < 200) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          g.act(s, d);
          guard++;
        }
        final after = _colorCounts(g.tubes);
        expect(after, equals(before), reason: 'seed=$seed');
      }
    });
  });

  group('boards contain mixed tubes (regression guard)', () {
    test(
      'genTubes scrambles with reverse moves, not forward ones — a board '
      'with every tube already uniform means someone swapped the scramble '
      'to use forward legality, which produces no puzzle at all',
      () {
        for (final seed in _seeds) {
          final tubes = genTubes(seed, 9, 5);
          final hasMixedTube = tubes.any((t) {
            if (t.isEmpty) return false;
            final first = t[0];
            return t.any((v) => v != first);
          });
          expect(hasMixedTube, isTrue, reason: 'seed=$seed');
        }
      },
    );
  });

  group('sealed tubes can never be poured from', () {
    test('Pour', () {
      for (final seed in _seeds.take(20)) {
        final g = Pour(seed, 9, 5);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          final r = g.act(s, d);
          if (r?.sealed != null) {
            final sealedIdx = r!.sealed!;
            for (var i = 0; i < g.tubes.length; i++) {
              expect(
                g.canAct(sealedIdx, i),
                isFalse,
                reason: 'seed=$seed sealed tube $sealedIdx should never be a legal source',
              );
            }
          }
          guard++;
        }
      }
    });

    test('Split', () {
      for (final seed in _seeds.take(20)) {
        final g = Split(seed, 7, 3, 3);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          final r = g.act(s, d);
          if (r?.sealed != null) {
            final sealedIdx = r!.sealed!;
            for (var i = 0; i < g.tubes.length; i++) {
              expect(g.canAct(sealedIdx, i), isFalse, reason: 'seed=$seed');
            }
          }
          guard++;
        }
      }
    });

    test('Fuse (sealed cell can never be a source or target)', () {
      for (final seed in _seeds.take(20)) {
        final g = Fuse(seed);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (a, b) = mv[guard % mv.length];
          final r = g.act(a, b);
          if (r?.sealed != null) {
            final sealedIdx = r!.sealed!;
            for (var i = 0; i < g.grid.length; i++) {
              expect(g.canAct(sealedIdx, i), isFalse, reason: 'seed=$seed');
              expect(g.canAct(i, sealedIdx), isFalse, reason: 'seed=$seed');
            }
          }
          guard++;
        }
      }
    });
  });

  group('games always terminate', () {
    void assertTerminates(GameEngine Function(int) make, String label) {
      for (final seed in _seeds) {
        final g = make(seed);
        var guard = 0;
        while (!g.over && guard < 400) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (a, b) = mv[guard % mv.length];
          g.act(a, b);
          guard++;
        }
        expect(g.over, isTrue, reason: '$label seed=$seed did not terminate within 400 moves');
      }
    }

    test('Pour', () => assertTerminates((s) => Pour(s, 9, 5), 'Pour'));
    test('Split', () => assertTerminates((s) => Split(s, 7, 3, 3), 'Split'));
    test('Fuse', () => assertTerminates((s) => Fuse(s), 'Fuse'));
    test('Recipe', () => assertTerminates((s) => Recipe(s), 'Recipe'));
  });

  group('turn ownership rules', () {
    test('Pour: claiming a tube keeps the turn', () {
      for (final seed in _seeds.take(20)) {
        final g = Pour(seed, 9, 5);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          final turnBefore = g.turn;
          final r = g.act(s, d);
          if (r != null) {
            if (r.sealed != null) {
              expect(g.turn, turnBefore, reason: 'seed=$seed claim should keep the turn');
            } else {
              expect(g.turn, 1 - turnBefore, reason: 'seed=$seed non-claim should flip the turn');
            }
          }
          guard++;
        }
      }
    });

    test('Split: turn always alternates, even on a claim', () {
      for (final seed in _seeds.take(20)) {
        final g = Split(seed, 7, 3, 3);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (s, d) = mv[guard % mv.length];
          final turnBefore = g.turn;
          final r = g.act(s, d);
          if (r != null) {
            expect(g.turn, 1 - turnBefore, reason: 'seed=$seed turn must always flip in Split');
          }
          guard++;
        }
      }
    });

    test('Fuse: turn always alternates, even on a claim', () {
      for (final seed in _seeds.take(20)) {
        final g = Fuse(seed);
        var guard = 0;
        while (!g.over && guard < 300) {
          final mv = g.moves();
          if (mv.isEmpty) break;
          final (a, b) = mv[guard % mv.length];
          final turnBefore = g.turn;
          final r = g.act(a, b);
          if (r != null) {
            expect(g.turn, 1 - turnBefore, reason: 'seed=$seed turn must always flip in Fuse');
          }
          guard++;
        }
      }
    });
  });
}
