import 'engine.dart';
import 'fuse.dart';

/// Difficulty preset: [depth] plies of search, [blunder] probability of
/// picking a uniformly random legal move instead. Mirrors the JS `AI` map
/// in decant.html.
class AiProfile {
  final int depth;
  final double blunder;
  final String name;
  const AiProfile({required this.depth, required this.blunder, required this.name});
}

const Map<String, AiProfile> kAiProfiles = {
  'easy': AiProfile(depth: 1, blunder: 0.45, name: 'Easy'),
  'normal': AiProfile(depth: 1, blunder: 0.12, name: 'Normal'),
  'hard': AiProfile(depth: 2, blunder: 0.02, name: 'Hard'),
};

double _evalG(GameEngine g, int me) =>
    (g.scores[me] - g.scores[1 - me]) * 100.0;

/// In Fuse, a move that grows a tile close to the merge target is worth
/// something even before it seals — this nudges the AI toward building up
/// rather than only chasing immediate claims. Zero for every other mode.
int _fuseBonus(GameEngine g, int cellIndex) {
  if (g is Fuse) return g.grid[cellIndex];
  return 0;
}

/// Port of `best` from decant.html: shallow minimax with a blunder chance,
/// used to drive the bot in all four duel modes.
(int, int)? best(
  GameEngine g,
  int depth,
  double blunder,
  double Function() rnd,
) {
  final mv = g.moves();
  if (mv.isEmpty) return null;
  if (rnd() < blunder) return mv[(rnd() * mv.length).floor()];
  final me = g.turn;
  (int, int)? b;
  var bs = double.negativeInfinity;
  for (final move in mv) {
    final c = g.clone();
    c.act(move.$1, move.$2);
    var sc = _evalG(c, me) + _fuseBonus(c, move.$2);
    if (depth > 1 && !c.over) {
      final r = best(c, depth - 1, 0, rnd);
      if (r != null) {
        final c2 = c.clone();
        c2.act(r.$1, r.$2);
        sc = _evalG(c2, me) + _fuseBonus(c2, r.$2);
      }
    }
    sc += (rnd() - 0.5) * 0.01;
    if (sc > bs) {
      bs = sc;
      b = move;
    }
  }
  return b;
}
