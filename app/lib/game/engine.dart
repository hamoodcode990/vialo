/// Result of a single accepted move. Shared shape across all four modes —
/// fields not meaningful for a given mode are left null (Fuse has no [col],
/// the tube modes have no [value]).
class MoveResult {
  final int from;
  final int to;
  final int? n;
  final int? value;
  final int? col;
  final int? sealed;
  final int by;

  const MoveResult({
    required this.from,
    required this.to,
    this.n,
    this.value,
    this.col,
    this.sealed,
    required this.by,
  });
}

/// Shared surface the AI search (ai.dart) needs to operate generically over
/// Pour, Split, Fuse and Recipe — JS relies on duck typing for this, Dart
/// needs an explicit interface.
abstract class GameEngine {
  String get kind;
  List<int> get scores;
  int get turn;
  bool get over;
  int get leader;

  /// All legal (from, to) pairs for the current turn.
  List<(int, int)> moves();

  bool canAct(int a, int b);

  /// Attempts the move; returns null if illegal or the game is already over.
  MoveResult? act(int a, int b);

  /// Deep-enough copy for AI search — history is intentionally dropped, same
  /// as the JS `clonePour`/`cloneSplit`/`cloneFuse`/`cloneRecipe` helpers.
  GameEngine clone();
}

/// The subset of modes whose board is a row of tubes (Pour, Split, Recipe —
/// everything except Fuse's grid). Lets the UI render/tap any of the three
/// generically instead of branching on `kind`.
abstract class TubeGameEngine implements GameEngine {
  List<List<int>> get tubes;
  List<bool> get sealed;
  List<int> get owner;
  int get colors;
  int get stall;
  bool get komi;
}
