import 'constants.dart';
import 'engine.dart';
import 'generator.dart';

/// Port of the `Split` class in decant.html: `own` colours each, one shared
/// neutral colour.
///
/// Tuned rules — do not change without being asked:
/// - The single neutral colour is essential. An even split produced 100%
///   draws across 400 games, because every colour completes and the scores
///   always tie.
/// - A tube scores for the *owner of the colour*, not whoever poured it.
/// - No chaining: unlike Pour, turn always alternates here even on a claim.
class Split implements TubeGameEngine {
  @override
  final String kind = 'split';

  final int seed;
  @override
  final int colors;
  final int own;
  @override
  final List<List<int>> tubes;
  @override
  final List<bool> sealed;
  @override
  final List<int> owner;
  @override
  final List<int> scores;
  @override
  int turn;
  final List<MoveResult> history;
  (int, int)? last;
  @override
  int stall;
  @override
  final bool komi = false;

  Split(this.seed, int c, int e, this.own)
      : colors = c,
        tubes = genTubes(seed, c, e),
        sealed = List<bool>.filled(c + e, false),
        owner = List<int>.filled(c + e, -1),
        scores = [0, 0],
        turn = 0,
        history = <MoveResult>[],
        last = null,
        stall = 0;

  Split._clone(
    this.seed,
    this.colors,
    this.own,
    this.tubes,
    this.sealed,
    this.owner,
    this.scores,
    this.turn,
    this.stall,
    this.last,
  ) : history = <MoveResult>[];

  /// -1 = neutral (belongs to whoever pours it), 0/1 = the owning player.
  int colOwner(int col) {
    if (col < own) return 0;
    if (col < own * 2) return 1;
    return -1;
  }

  @override
  bool canAct(int s, int d) {
    if (s == d || sealed[s]) return false;
    final l = last;
    if (l != null && l.$1 == d && l.$2 == s) return false;
    final a = tubes[s], b = tubes[d];
    if (a.isEmpty || b.length >= kCap) return false;
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
  bool get over => claimed >= colors || stall >= kStall || moves().isEmpty;

  @override
  int get leader =>
      scores[0] == scores[1] ? -1 : (scores[0] > scores[1] ? 0 : 1);

  @override
  MoveResult? act(int s, int d) {
    if (over || !canAct(s, d)) return null;
    final col = tubes[s].last;
    var n = 0;
    while (tubes[s].isNotEmpty &&
        tubes[s].last == col &&
        tubes[d].length < kCap) {
      tubes[d].add(tubes[s].removeLast());
      n++;
    }
    int? sl;
    for (var i = 0; i < tubes.length; i++) {
      if (!sealed[i] && isUniformFullTube(tubes[i])) {
        var o = colOwner(tubes[i][0]);
        if (o == -1) o = turn; // neutral goes to the pourer
        sealed[i] = true;
        owner[i] = o;
        scores[o]++;
        sl = i;
      }
    }
    final who = turn;
    last = sl == null ? (s, d) : null;
    stall = sl == null ? stall + 1 : 0;
    turn = 1 - turn; // no chaining here — the neutral race is the tension
    final r = MoveResult(from: s, to: d, n: n, col: col, sealed: sl, by: who);
    history.add(r);
    return r;
  }

  @override
  Split clone() => Split._clone(
        seed,
        colors,
        own,
        [for (final t in tubes) List<int>.from(t)],
        List<bool>.from(sealed),
        List<int>.from(owner),
        List<int>.from(scores),
        turn,
        stall,
        last,
      );
}
