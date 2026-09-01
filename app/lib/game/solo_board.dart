import 'constants.dart';
import 'generator.dart';

/// Single-player sort board — port of decant.html's inline Solo logic
/// (`sLegal`/`tapSolo`/`soloStuck`/`soloHintMove`). Not one of the four duel
/// engines from Phase 1, but the same pure-Dart treatment applies: no
/// Flutter here.
class SoloBoard {
  final int seed;
  final int colors;
  final int empty;
  final List<List<int>> tubes;
  final List<List<List<int>>> _undoStack = [];

  /// The real pass/fail cap ([soloMoveLimit] in level_curves.dart) — null
  /// for Daily/Shuffle, which have never cost a life on failure and stay
  /// exempt (see solo_game_screen.dart's `_onFailed`). Without this, a Solo
  /// level had no way to fail short of a genuine dead-end board state, so a
  /// player could pour forever and never lose — this is what actually
  /// closes that gap.
  final int? moveLimit;

  int moves = 0;
  bool done = false;
  bool failed = false;
  bool usedHint = false;
  int freeUndo = 1;

  SoloBoard({required this.seed, required this.colors, required this.empty, this.moveLimit})
      : tubes = genTubes(seed, colors, empty);

  bool legal(int s, int d) {
    if (s == d || tubes[s].isEmpty || tubes[d].length >= kCap) return false;
    return tubes[d].isEmpty || tubes[s].last == tubes[d].last;
  }

  bool get solved => tubes.every((t) => t.isEmpty || isUniformFullTube(t));

  bool get stuck {
    for (var i = 0; i < tubes.length; i++) {
      for (var j = 0; j < tubes.length; j++) {
        if (i != j && legal(i, j)) return false;
      }
    }
    return true;
  }

  bool get canUndo => _undoStack.isNotEmpty;

  /// Pours from [s] to [d]; returns the number of items moved (0 if
  /// illegal). Updates [done]/[failed] as a side effect.
  int pour(int s, int d) {
    if (done || failed || !legal(s, d)) return 0;
    _undoStack.add([for (final t in tubes) List<int>.from(t)]);
    final col = tubes[s].last;
    var n = 0;
    while (tubes[s].isNotEmpty && tubes[s].last == col && tubes[d].length < kCap) {
      tubes[d].add(tubes[s].removeLast());
      n++;
    }
    moves++;
    if (solved) {
      done = true;
    } else if (stuck || (moveLimit != null && moves >= moveLimit!)) {
      failed = true;
    }
    return n;
  }

  /// Reverts the last pour. The caller is responsible for the coin cost
  /// once [freeUndo] is exhausted (this only performs the state change).
  bool undo() {
    if (_undoStack.isEmpty) return false;
    final prev = _undoStack.removeLast();
    tubes
      ..clear()
      ..addAll(prev);
    if (moves > 0) moves--;
    failed = false;
    return true;
  }

  /// A lightweight move-picker for the "reveal a move" hint: prefers a move
  /// that completes a tube, else the first legal move found. Not a solver.
  (int, int)? hintMove() {
    (int, int)? fallback;
    for (var s = 0; s < tubes.length; s++) {
      if (tubes[s].isEmpty) continue;
      for (var d = 0; d < tubes.length; d++) {
        if (!legal(s, d)) continue;
        final col = tubes[s].last;
        final clone = [for (final t in tubes) List<int>.from(t)];
        while (clone[s].isNotEmpty && clone[s].last == col && clone[d].length < kCap) {
          clone[d].add(clone[s].removeLast());
        }
        if (isUniformFullTube(clone[d])) return (s, d);
        fallback ??= (s, d);
      }
    }
    return fallback;
  }

  /// Adds an empty tube (the "add a tube" hint).
  void addTube() {
    tubes.add(<int>[]);
    usedHint = true;
  }
}
