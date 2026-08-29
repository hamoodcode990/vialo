import 'constants.dart';
import 'engine.dart';
import 'generator.dart';

// 10 shared source tubes, 8 colours, each recipe is kCap(4) long.
//
// (was 8 tubes / 6 colours: measured 500-game sim at that size was a 62/38
// skew toward whoever moves first — 6 colours gave the two 4-long formulas
// too much forced overlap, so first pick off the shared tubes usually
// decided it. At 8 colours/10 tubes the same sim comes out ~247/253 and
// ~232/268 depending who starts — close enough, combined with per-match
// starter alternation, to call this fixed rather than merely improved.)
const int kRecipeSrc = 10;
const int kRecipeColors = 8;

/// Port of the `Recipe` class in decant.html: each player secretly races to
/// build their own exact colour sequence (own vial = `tubes[kRecipeSrc +
/// turn]`) from the shared source tubes.
///
/// No chaining, no take-backs on the vials — a wrong-order pour is simply
/// illegal, so the tension is entirely in setting up the right top colour
/// before your opponent claims it for their own build.
///
/// Balance history: at 6 colours/8 tubes this was a 62/38 skew toward
/// whoever moved first (500-game sim, depth-1 AI, 10% blunder). Tried and
/// rejected: a bonus move for the responder (overshot to ~55-60% in their
/// favour), a formula-length handicap (same overshoot), delaying the
/// starter's first fill by 1-3 plies (overshot even harder — being able to
/// fill on move 1 turned out to matter far more than raw move count). What
/// actually worked: more colours relative to formula length (8 colours
/// instead of 6, same kCap-4 formula) — same sim now lands at ~247/253 and
/// ~232/268 depending who starts. ~9% of games now resolve via the shared
/// stall clock instead of a clean finish (up from 0%); those go through the
/// same komi as a tie. Combined with per-match starter alternation, this is
/// close enough to call fixed rather than merely improved. Do not adjust by
/// feel — re-measure if you touch it.
class Recipe implements TubeGameEngine {
  @override
  final String kind = 'recipe';

  final int seed;
  @override
  final int colors = kRecipeColors;
  @override
  final List<List<int>> tubes;
  final List<List<int>> recipes;
  @override
  final List<bool> sealed;
  @override
  final List<int> owner;
  @override
  final List<int> scores;
  @override
  int turn;
  final List<MoveResult> history;
  @override
  int stall;
  @override
  final bool komi = true;

  Recipe(this.seed)
      : tubes = _initialTubes(seed),
        recipes = _initialRecipes(seed),
        sealed = List<bool>.filled(kRecipeSrc + 2, false),
        owner = List<int>.filled(kRecipeSrc + 2, -1),
        scores = [0, 0],
        turn = 0,
        history = <MoveResult>[],
        stall = 0;

  Recipe._clone(
    this.seed,
    this.tubes,
    this.recipes,
    this.sealed,
    this.owner,
    this.scores,
    this.turn,
    this.stall,
  ) : history = <MoveResult>[];

  static List<List<int>> _initialTubes(int seed) {
    final tb = genTubes(seed, kRecipeColors, 2);
    tb.add(<int>[]); // kRecipeSrc      = player 0 vial
    tb.add(<int>[]); // kRecipeSrc + 1  = player 1 vial
    return tb;
  }

  static List<List<int>> _initialRecipes(int seed) {
    final rnd = mb32((seed * 2654435761).toUnsigned(32));
    return [
      shuffleN(kRecipeColors, kCap, rnd),
      shuffleN(kRecipeColors, kCap, rnd),
    ];
  }

  @override
  bool canAct(int s, int d) {
    if (s == d || s >= kRecipeSrc) return false;
    final a = tubes[s];
    if (a.isEmpty) return false;
    if (d >= kRecipeSrc) {
      final p = d - kRecipeSrc;
      if (p != turn) return false;
      final b = tubes[d];
      return b.length < kCap && a.last == recipes[p][b.length];
    }
    final b = tubes[d];
    if (b.length >= kCap) return false;
    return b.isEmpty || a.last == b.last;
  }

  List<int> targets(int s) {
    final o = <int>[];
    for (var d = 0; d < tubes.length; d++) {
      if (canAct(s, d)) o.add(d);
    }
    return o;
  }

  @override
  List<(int, int)> moves() {
    final o = <(int, int)>[];
    for (var s = 0; s < tubes.length; s++) {
      for (var d = 0; d < tubes.length; d++) {
        if (canAct(s, d)) o.add((s, d));
      }
    }
    return o;
  }

  int get claimed => scores[0] + scores[1];
  int get left {
    final r = kStall - stall;
    return r < 0 ? 0 : r;
  }

  @override
  bool get over =>
      scores[0] >= kCap || scores[1] >= kCap || stall >= kStall || moves().isEmpty;

  @override
  int get leader {
    if (scores[0] >= kCap) return 0;
    if (scores[1] >= kCap) return 1;
    // komi: P2 wins ties/incomplete
    return scores[0] == scores[1] ? 1 : (scores[0] > scores[1] ? 0 : 1);
  }

  @override
  MoveResult? act(int s, int d) {
    if (over || !canAct(s, d)) return null;
    final isVial = d >= kRecipeSrc;
    final col = tubes[s].last;
    var n = 0;
    int? sl;
    if (isVial) {
      final p = d - kRecipeSrc;
      tubes[d].add(tubes[s].removeLast());
      n = 1;
      scores[p]++;
      stall = 0;
      if (tubes[d].length >= kCap) {
        sealed[d] = true;
        owner[d] = p;
        sl = d;
      }
    } else {
      while (tubes[s].isNotEmpty &&
          tubes[s].last == col &&
          tubes[d].length < kCap) {
        tubes[d].add(tubes[s].removeLast());
        n++;
      }
      stall++;
    }
    final who = turn;
    turn = 1 - turn;
    final r = MoveResult(from: s, to: d, n: n, col: col, sealed: sl, by: who);
    history.add(r);
    return r;
  }

  @override
  Recipe clone() => Recipe._clone(
        seed,
        [for (final t in tubes) List<int>.from(t)],
        [for (final r in recipes) List<int>.from(r)],
        List<bool>.from(sealed),
        List<int>.from(owner),
        List<int>.from(scores),
        turn,
        stall,
      );
}
