// Phase 2 balance tests — bot-vs-bot self-play, asserting win rates stay
// near the values CLAUDE.md documents as measured-and-fixed. This is the
// last gate before any UI work: flutter_port_plan.md says any deviation
// means the port broke something. Do not "fix" a failure here by loosening
// the bounds — find the bug.
//
// Methodology mirrors the depth-1-AI/blunder-rate self-play sims described
// in CLAUDE.md/decant.html's balance comments (e.g. Recipe's "500-game sim,
// depth-1 AI, 10% blunder").
import 'package:vialo/game/game.dart';
import 'package:test/test.dart';

const _games = 300;
const _depth = 1;
const _blunder = 0.10;
const _maxMoves = 400;

/// Self-play [games] games of the mode built by [make], returning how many
/// were won by player 0, player 1, and how many were draws.
({int p0, int p1, int draws}) _simulate(GameEngine Function(int seed) make) {
  var p0 = 0, p1 = 0, draws = 0;
  for (var i = 0; i < _games; i++) {
    final seed = i * 97 + 13;
    final g = make(seed);
    final rnd = mb32(seed * 2654435761 + 12345);
    var guard = 0;
    while (!g.over && guard < _maxMoves) {
      final m = best(g, _depth, _blunder, rnd);
      if (m == null) break;
      g.act(m.$1, m.$2);
      guard++;
    }
    final l = g.leader;
    if (l == 0) {
      p0++;
    } else if (l == 1) {
      p1++;
    } else {
      draws++;
    }
  }
  return (p0: p0, p1: p1, draws: draws);
}

void main() {
  group('balance: $_games bot-vs-bot games per mode', () {
    test('Pour: ~50/50 with the stall clock active', () {
      final r = _simulate((s) => Pour(s, 9, 5));
      final p0Rate = r.p0 / _games;
      final drawRate = r.draws / _games;
      // A broken stall clock historically produced ~50% draws and 480+
      // turn games — keep draws a small minority as a regression guard.
      expect(drawRate, lessThan(0.30), reason: 'draw rate ${r.draws}/$_games — stall clock may be broken');
      expect(p0Rate, inClosedOpenRange(0.35, 0.65), reason: 'p0=${r.p0} p1=${r.p1} draws=${r.draws}');
    });

    test('Split: ~50/50 with the single gold colour', () {
      final r = _simulate((s) => Split(s, 7, 3, 3));
      final p0Rate = r.p0 / _games;
      expect(p0Rate, inClosedOpenRange(0.35, 0.65), reason: 'p0=${r.p0} p1=${r.p1} draws=${r.draws}');
    });

    test('Fuse: ~52/48 with ties to player 2', () {
      final r = _simulate((s) => Fuse(s));
      // Fuse's leader is always decisive (komi breaks every tie), so
      // p0 + p1 == _games exactly.
      expect(r.p0 + r.p1, _games);
      final p1Rate = r.p1 / _games;
      // Historically P1 won 82% when keep-turn/no-komi regressed in — this
      // band would catch that reversal decisively while tolerating normal
      // simulation variance around the measured 52/48.
      expect(p1Rate, inClosedOpenRange(0.42, 0.68), reason: 'p0=${r.p0} p1=${r.p1}');
    });

    test('Recipe: ~50/50', () {
      final r = _simulate((s) => Recipe(s));
      final p0Rate = r.p0 / _games;
      expect(p0Rate, inClosedOpenRange(0.35, 0.65), reason: 'p0=${r.p0} p1=${r.p1} draws=${r.draws}');
    });
  });
}
