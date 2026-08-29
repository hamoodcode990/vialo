/// Level-ladder curves and star thresholds — ported from decant.html's
/// economy layer (modeSeed/soloCfg/pourLvlCfg/etc). Not part of the core
/// engines (Phase 1) since these are content/pacing policy, not game rules,
/// but they live alongside the engines they configure and stay pure Dart.
library;

import 'constants.dart';

const Map<String, int> kLevelCounts = {
  'solo': 300,
  'pour': 150,
  'split': 150,
  'fuse': 100,
  'recipe': 100,
};

/// Deterministic per-level seed: same board for every player, every time.
/// Bit-for-bit port of decant.html's `modeSeed` (32-bit string hash).
int modeSeed(String modeId, int n) {
  var h = 0;
  final s = '$modeId:$n';
  for (var i = 0; i < s.length; i++) {
    h = ((h * 31) + s.codeUnitAt(i)).toSigned(32);
  }
  return h.abs() % 900000;
}

/// Same 32-bit string hash as [modeSeed], applied directly to a `yyyy-mm-dd`
/// date string — everyone gets the same daily board. Port of decant.html's
/// `dailySeed`.
int dailySeed(String dateStr) {
  var h = 0;
  for (var i = 0; i < dateStr.length; i++) {
    h = ((h * 31) + dateStr.codeUnitAt(i)).toSigned(32);
  }
  return h.abs() % 900000;
}

String _aiTier(double t) => t < 0.34 ? 'easy' : (t < 0.7 ? 'normal' : 'hard');

class SoloLevelConfig {
  final int colors;
  final int empty;
  const SoloLevelConfig(this.colors, this.empty);
}

SoloLevelConfig soloCfg(int n) {
  final t = (n - 1) / (kLevelCounts['solo']! - 1);
  final c = (4 + t * 8).round();
  final e = (3 - t * 2).round();
  return SoloLevelConfig(c, e < 1 ? 1 : e);
}

class PourLevelConfig {
  final int colors;
  final int empty;
  final String ai;
  const PourLevelConfig(this.colors, this.empty, this.ai);
}

PourLevelConfig pourLvlCfg(int n) {
  final t = (n - 1) / (kLevelCounts['pour']! - 1);
  final e = (5 - t * 2).round();
  return PourLevelConfig((5 + t * 6).round(), e < 2 ? 2 : e, _aiTier(t));
}

class SplitLevelConfig {
  final int own;
  final int colors;
  final int empty;
  final String ai;
  const SplitLevelConfig(this.own, this.colors, this.empty, this.ai);
}

SplitLevelConfig splitLvlCfg(int n) {
  final t = (n - 1) / (kLevelCounts['split']! - 1);
  final own = 2 + (t * 3).round();
  return SplitLevelConfig(own, own * 2 + 1, 3, _aiTier(t));
}

String fuseLvlCfg(int n) => _aiTier((n - 1) / (kLevelCounts['fuse']! - 1));

String recipeLvlCfg(int n) => _aiTier((n - 1) / (kLevelCounts['recipe']! - 1));

/// Solo star pacing: a UX heuristic, not a measured balance constant — it
/// never changes a rule or outcome, only how the win is graded afterward.
int soloPar(int colors, int empty) => (colors * 2.3 + (3 - empty)).round();

int soloStars({required bool usedHint, required int moves, required int par}) {
  if (usedHint) return 1;
  return moves <= par ? 3 : 2;
}

/// Duel ladder star pacing: 3 for a decisive win margin, 2 for any other
/// win. No 1-star tier — hints are Solo-only.
int duelStars({
  required String kind,
  required int myScore,
  required int oppScore,
  required int colors,
}) {
  final margin = myScore - oppScore;
  final scale = kind == 'fuse' ? 6 : (kind == 'recipe' ? kCap : colors);
  return margin >= (scale * 0.4).ceil() ? 3 : 2;
}
