/// A Solo-board solver used offline to *measure* a real per-level move par
/// (see tool/measure_solo_par.dart) instead of guessing a formula — the
/// previous `soloPar` was explicitly a placeholder ("a UX heuristic, not a
/// measured balance constant") and was never even wired up as a pass/fail
/// limit, just star-grading. Pure logic, no Flutter — same footing as the
/// four duel engines.
///
/// IDA* with an admissible "colour runs remaining" heuristic and a
/// per-iteration transposition table — the standard approach real
/// water-sort solvers use. A first cut at this used plain greedy best-first
/// play with random restarts; it failed to find any solution at all on a
/// large and growing fraction of levels as soon as spare (empty) tubes got
/// scarce, because greedy play can paint itself into a genuine dead end
/// with no way back. IDA* backtracks, so it finds a solution for any board
/// that has one — which, as it turns out, is *not* every board `genTubes`
/// produces: exhaustive search proved some boards (concentrated in the
/// empty=1 tier) are unreachable from solved by any forward move sequence
/// at all, a real bug in the reverse-move scrambler. See
/// level_curves.dart's `kSoloSeedOverride` for how the shipped game works
/// around it without touching `genTubes` itself.
library;

import 'constants.dart';

bool _solved(List<List<int>> tubes) =>
    tubes.every((t) => t.isEmpty || isUniformFullTube(t));

/// Total colour-run count across every tube. A solved board has exactly one
/// run per colour, so `runs - colors` is 0 at the goal. Every pour reduces
/// this by at most 1 (a full merge onto a matching top) or leaves it
/// unchanged (pouring onto an empty tube, or a partial merge) — it never
/// increases — so `runs - colors` never overestimates the moves remaining:
/// an admissible heuristic for IDA*.
int _runCount(List<List<int>> tubes) {
  var runs = 0;
  for (final t in tubes) {
    if (t.isEmpty) continue;
    runs++;
    for (var i = 1; i < t.length; i++) {
      if (t[i] != t[i - 1]) runs++;
    }
  }
  return runs;
}

/// Canonical form for the transposition table: which physical tube index
/// holds what doesn't matter, only the multiset of tube contents — so two
/// states that are just a relabelling of each other are the same state for
/// search purposes.
String _canon(List<List<int>> tubes) {
  final parts = [for (final t in tubes) t.join(',')]..sort();
  return parts.join('|');
}

class _Move {
  final int s;
  final int d;
  const _Move(this.s, this.d);
}

class _SoloSolver {
  final int colors;
  final int nodeBudget;
  final double weight;
  int nodesVisited = 0;
  bool budgetExceeded = false;

  _SoloSolver({required this.colors, required this.nodeBudget, required this.weight});

  bool _legal(List<List<int>> tubes, int s, int d) {
    if (s == d || tubes[s].isEmpty || tubes[d].length >= kCap) return false;
    return tubes[d].isEmpty || tubes[s].last == tubes[d].last;
  }

  List<_Move> _movesOrderedByPromise(List<List<int>> tubes) {
    final scored = <(int, _Move)>[];
    for (var s = 0; s < tubes.length; s++) {
      if (tubes[s].isEmpty) continue;
      for (var d = 0; d < tubes.length; d++) {
        if (!_legal(tubes, s, d)) continue;
        final clone = [for (final t in tubes) List<int>.from(t)];
        _apply(clone, s, d);
        var score = -_runCount(clone) * 10;
        if (isUniformFullTube(clone[d])) score += 5;
        scored.add((score, _Move(s, d)));
      }
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final e in scored) e.$2];
  }

  void _apply(List<List<int>> tubes, int s, int d) {
    final col = tubes[s].last;
    while (tubes[s].isNotEmpty && tubes[s].last == col && tubes[d].length < kCap) {
      tubes[d].add(tubes[s].removeLast());
    }
  }

  void _undo(List<List<int>> tubes, int s, int d, int n) {
    for (var i = 0; i < n; i++) {
      tubes[s].add(tubes[d].removeLast());
    }
  }

  /// Returns the move count if a solution at or under [threshold] is found,
  /// or `null` plus updates [nextThresholdHolder] (the smallest f-value that
  /// exceeded the current threshold) otherwise. [seen] maps a canonical
  /// state to the best `g` it's been reached at *within this threshold
  /// iteration only* — it's reset for every new iteration (see [solve]),
  /// since a state whose subtree exploration was cut short by the old,
  /// smaller threshold hasn't actually been exhausted yet, and a stale
  /// "already visited" entry would wrongly block the deeper re-exploration
  /// the new, larger threshold is supposed to allow.
  int? _search(
    List<List<int>> tubes,
    int g,
    int threshold,
    Map<String, int> seen,
    List<int> nextThresholdHolder,
  ) {
    nodesVisited++;
    if (nodesVisited > nodeBudget) {
      budgetExceeded = true;
      return null;
    }

    final h = _runCount(tubes) - colors;
    // f uses a weighted heuristic (weight > 1 trades proven optimality for
    // dramatically fewer node expansions — "weighted A*/IDA*", the standard
    // practical answer to IDA* thrashing on boards this tightly packed).
    // Solutions found this way are no longer guaranteed shortest-possible,
    // but they're still real, measured, in-the-right-ballpark move counts —
    // exactly what a gameplay move-limit needs, as opposed to a proof.
    final f = g + (h * weight).ceil();
    if (f > threshold) {
      if (f < nextThresholdHolder[0]) nextThresholdHolder[0] = f;
      return null;
    }
    if (h == 0 && _solved(tubes)) return g;

    final canon = _canon(tubes);
    final bestSeen = seen[canon];
    if (bestSeen != null && bestSeen <= g) return null;
    seen[canon] = g;

    for (final m in _movesOrderedByPromise(tubes)) {
      final before = tubes[m.d].length;
      _apply(tubes, m.s, m.d);
      final n = tubes[m.d].length - before;
      final result = _search(tubes, g + 1, threshold, seen, nextThresholdHolder);
      _undo(tubes, m.s, m.d, n);
      if (budgetExceeded) return null;
      if (result != null) return result;
    }
    return null;
  }

  /// Runs (weighted) IDA*, returning a move count, or `null` if the node
  /// budget was exhausted before a solution was confirmed.
  int? solve(List<List<int>> initialTubes) {
    var threshold = ((_runCount(initialTubes) - colors) * weight).ceil();
    while (true) {
      final nextThresholdHolder = [1 << 30];
      final result = _search(
        [for (final t in initialTubes) List<int>.from(t)],
        0,
        threshold,
        <String, int>{}, // reset every iteration — see _search's doc comment
        nextThresholdHolder,
      );
      if (result != null) return result;
      if (budgetExceeded) return null;
      if (nextThresholdHolder[0] >= 1 << 30) return null; // exhausted search space — not solvable (shouldn't happen)
      threshold = nextThresholdHolder[0];
    }
  }
}

/// Finds a move count to solve [initialTubes] via IDA*, or `null` if
/// [nodeBudget] was exhausted first. [weight] > 1 trades proven optimality
/// for speed (see [_SoloSolver._search]) — use 1.0 where exact-optimal search
/// is fast enough, and something like 1.5-2.0 for boards tight enough that
/// plain IDA* thrashes (see tool/measure_solo_par.dart for which is which).
int? nearOptimalSolveLength(
  List<List<int>> initialTubes, {
  required int colors,
  int nodeBudget = 4000000,
  double weight = 1.0,
}) {
  return _SoloSolver(colors: colors, nodeBudget: nodeBudget, weight: weight).solve(initialTubes);
}
