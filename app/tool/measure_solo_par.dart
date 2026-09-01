// ignore_for_file: avoid_print, avoid_relative_lib_imports
// print is this script's whole output mechanism, and the relative lib/
// imports are the standard way an offline tool/ script reaches into a
// package's own lib/ without adding a pubspec dependency on itself.
//
// One-off measurement script (CLAUDE.md's "measure it, don't guess" ethos —
// same idea as the bot-vs-bot balance sims, applied to Solo's move par
// instead of duel-mode win rates). Run with:
//   dart run tool/measure_solo_par.dart [startLevel] [endLevel]
//
// Prints two tables to paste into lib/game/level_curves.dart:
//   - kSoloMovePar: measured near-optimal move count per level.
//   - kSoloSeedOverride: a handful of levels whose default `modeSeed('solo',
//     n)` board turned out to be mathematically unreachable from solved by
//     ANY forward move sequence (a genuine bug in genTubes' reverse-move
//     scrambler — see the note above genTubes: taking a whole top run when
//     a different colour sits underneath isn't actually invertible by a
//     single forward pour, and it gets more likely as spare capacity
//     shrinks — confirmed via exhaustive BFS on level 245, and it turned out
//     to hit exactly the empty=1 tier, levels 226-300). Rather than touch
//     genTubes itself (shared with the duel modes and JS-parity-tested),
//     affected Solo levels get an alternate seed, found here by trying
//     seed+1, +2, ... until genTubes produces a board this solver can
//     actually solve.
//
// Not part of the shipped app and not run by `flutter test` — this is a
// one-time measurement; the results are static tables baked into the game.
import 'dart:io';

import '../lib/game/generator.dart';
import '../lib/game/level_curves.dart';
import '../lib/game/solo_solver.dart';

// Exact (weight 1.0) search is fast for most levels but thrashes once spare
// tubes get scarce. Rather than guess a threshold, just try exact first and
// escalate weight (trading proven optimality for convergence speed) only
// where it actually fails — most levels stay exact.
const _attempts = [
  (weight: 1.0, budget: 4000000),
  (weight: 1.3, budget: 4000000),
  (weight: 1.6, budget: 8000000),
  (weight: 2.0, budget: 15000000),
  (weight: 3.0, budget: 20000000),
];

int? _solve(List<List<int>> tubes, int colors) {
  for (final a in _attempts) {
    final par = nearOptimalSolveLength(tubes, colors: colors, weight: a.weight, nodeBudget: a.budget);
    if (par != null) return par;
  }
  return null;
}

void main(List<String> args) {
  final total = kLevelCounts['solo']!;
  final start = args.isNotEmpty ? int.parse(args[0]) : 1;
  final end = args.length > 1 ? int.parse(args[1]) : total;

  final results = <int>[];
  final overrides = <int, int>{}; // level -> seed offset actually used
  final stopwatch = Stopwatch()..start();

  for (var n = start; n <= end; n++) {
    final cfg = soloCfg(n);
    final baseSeed = modeSeed('solo', n);
    final levelStart = stopwatch.elapsedMilliseconds;

    var par = _solve(genTubes(baseSeed, cfg.colors, cfg.empty), cfg.colors);

    if (par == null) {
      // Default seed's board is unsolvable (or, in principle, just beyond
      // this solver's reach — but see the file header: every failure
      // observed exhausts near-instantly, the same signature as level 245's
      // confirmed-by-BFS unsolvable board, not a budget timeout). Search
      // for the first nearby seed offset that gives a solvable board.
      for (var offset = 1; offset <= 2000; offset++) {
        final altSeed = baseSeed + offset;
        final altTubes = genTubes(altSeed, cfg.colors, cfg.empty);
        final altPar = _solve(altTubes, cfg.colors);
        if (altPar != null) {
          par = altPar;
          overrides[n] = offset;
          break;
        }
      }
    }

    final levelMs = stopwatch.elapsedMilliseconds - levelStart;
    if (par == null) {
      stderr.writeln('!! level $n (colors=${cfg.colors}, empty=${cfg.empty}) — no solvable seed found within 2000 offsets (${levelMs}ms)');
      results.add(-1);
    } else {
      results.add(par);
      if (levelMs > 200 || overrides.containsKey(n)) {
        stderr.writeln('level $n (colors=${cfg.colors}, empty=${cfg.empty}) -> par=$par'
            '${overrides.containsKey(n) ? ' [seed override +${overrides[n]}]' : ''} (${levelMs}ms)');
      }
    }
    if (n % 10 == 0) {
      stderr.writeln('...$n/$end done (${stopwatch.elapsedMilliseconds}ms elapsed)');
    }
  }

  stderr.writeln('Total: ${stopwatch.elapsedMilliseconds}ms for levels $start..$end');
  stderr.writeln('Seed overrides needed: ${overrides.length}');
  final failures = results.where((v) => v == -1).length;
  if (failures > 0) stderr.writeln('WARNING: $failures level(s) had no solve found at all — investigate before shipping.');

  print('// levels $start..$end');
  print('const List<int> kSoloMovePar = [');
  for (var i = 0; i < results.length; i += 20) {
    final chunk = results.sublist(i, (i + 20).clamp(0, results.length));
    print('  ${chunk.join(', ')},');
  }
  print('];');
  print('');
  print('// level -> seed offset (added to modeSeed) needed to reach a solvable board.');
  print('const Map<int, int> kSoloSeedOverride = {');
  for (final entry in overrides.entries) {
    print('  ${entry.key}: ${entry.value},');
  }
  print('};');
}
