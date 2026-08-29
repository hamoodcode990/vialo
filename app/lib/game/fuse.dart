import 'engine.dart';
import 'generator.dart';

const int kFuseWidth = 6;
const int kFuseHeight = 6;
const int kFuseTarget = 4;

/// Merge Duel. Port of the `Fuse` class in decant.html.
///
/// Tuned rules — do not change without being asked:
/// - No keep-turn on a claim (with chaining, player 1 won 82% in
///   simulation).
/// - Ties go to player 2 (komi). Balance measured at 52/48.
/// - Every merge removes a tile, so the board always runs down and the game
///   always terminates.
class Fuse implements GameEngine {
  @override
  final String kind = 'fuse';

  final int seed;
  final int w = kFuseWidth;
  final int h = kFuseHeight;
  final int target = kFuseTarget;
  final List<int> grid;
  final List<bool> sealed;
  final List<int> owner;
  @override
  final List<int> scores;
  @override
  int turn;
  final List<MoveResult> history;
  final bool komi = true; // half point to P2

  Fuse(this.seed)
      : grid = _initialGrid(seed),
        sealed = List<bool>.filled(kFuseWidth * kFuseHeight, false),
        owner = List<int>.filled(kFuseWidth * kFuseHeight, -1),
        scores = [0, 0],
        turn = 0,
        history = <MoveResult>[];

  Fuse._clone(
    this.seed,
    this.grid,
    this.sealed,
    this.owner,
    this.scores,
    this.turn,
  ) : history = <MoveResult>[];

  static List<int> _initialGrid(int seed) {
    final rnd = mb32(seed);
    return List<int>.generate(
      kFuseWidth * kFuseHeight,
      (_) => 1 + (rnd() * 3).floor(),
    );
  }

  bool adj(int a, int b) {
    final ax = a % w, ay = a ~/ w, bx = b % w, by = b ~/ w;
    return (ax - bx).abs() + (ay - by).abs() == 1;
  }

  @override
  bool canAct(int a, int b) {
    if (a == b || sealed[a] || sealed[b]) return false;
    if (grid[a] == 0 || grid[b] == 0) return false;
    if (!adj(a, b)) return false;
    return grid[a] == grid[b];
  }

  List<int> targets(int a) {
    final o = <int>[];
    for (var b = 0; b < grid.length; b++) {
      if (canAct(a, b)) o.add(b);
    }
    return o;
  }

  @override
  List<(int, int)> moves() {
    final o = <(int, int)>[];
    for (var a = 0; a < grid.length; a++) {
      for (var b = 0; b < grid.length; b++) {
        if (canAct(a, b)) o.add((a, b));
      }
    }
    return o;
  }

  int get claimed => scores[0] + scores[1];

  @override
  bool get over => moves().isEmpty;

  @override
  int get leader => scores[0] > scores[1] ? 0 : 1; // komi: P2 wins ties

  @override
  MoveResult? act(int a, int b) {
    if (over || !canAct(a, b)) return null;
    final v = grid[b] + 1;
    grid[b] = v;
    grid[a] = 0;
    int? sl;
    if (v >= target) {
      sealed[b] = true;
      owner[b] = turn;
      scores[turn]++;
      sl = b;
    }
    final who = turn;
    turn = 1 - turn; // no keep-turn: it made P1 win 82%
    final r = MoveResult(from: a, to: b, value: v, sealed: sl, by: who);
    history.add(r);
    return r;
  }

  @override
  Fuse clone() => Fuse._clone(
        seed,
        List<int>.from(grid),
        List<bool>.from(sealed),
        List<int>.from(owner),
        List<int>.from(scores),
        turn,
      );
}
