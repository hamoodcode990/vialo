/// Level-ladder curves and star thresholds — ported from decant.html's
/// economy layer (modeSeed/soloCfg/pourLvlCfg/etc). Not part of the core
/// engines (Phase 1) since these are content/pacing policy, not game rules,
/// but they live alongside the engines they configure and stay pure Dart.
library;

import 'constants.dart';

const Map<String, int> kLevelCounts = {
  'solo': 350,
  'pour': 150,
  'split': 150,
  'fuse': 100,
  'recipe': 100,
};

/// Solo's original design size — kept fixed (not read from
/// [kLevelCounts]) so levels 1-300 keep their exact original difficulty,
/// measured pars, and seed overrides as the ladder grows past it. Levels
/// beyond it ([soloCfg] extrapolating `t` past 1.0) continue the same
/// curve rather than being squeezed into a rescaled 1..350 range, which
/// would silently change the puzzle on every single one of the first 300
/// levels — store screenshots/marketing said "300+ levels", so this only
/// ever adds levels past that mark, never renumbers or reshapes it.
const int kSoloOriginalLevelCount = 300;

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
  final t = (n - 1) / (kSoloOriginalLevelCount - 1);
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

/// Measured (not guessed) near-optimal move count per Solo level — see
/// tool/measure_solo_par.dart, which solves every level with a real IDA*
/// search (falling back to a weighted/approximate search only where exact
/// search thrashes on the tightest boards). Index 0 = level 1. Drives both
/// star grading ([soloStars]) and the actual pass/fail cap ([soloMoveLimit])
/// — the previous `soloPar(colors, empty)` was an explicit placeholder
/// formula that was never even wired up as a limit, only used for stars.
const List<int> kSoloMovePar = [
  12, 14, 11, 12, 12, 12, 11, 12, 12, 12, 13, 12, 13, 12, 11, 13, 12, 13, 12, 14,
  16, 15, 15, 16, 16, 16, 13, 17, 14, 16, 16, 16, 16, 16, 15, 14, 16, 13, 13, 16,
  16, 15, 14, 14, 16, 15, 17, 16, 14, 17, 16, 16, 14, 16, 15, 16, 15, 19, 17, 17,
  19, 19, 19, 19, 20, 18, 19, 20, 19, 19, 17, 17, 17, 21, 20, 19, 17, 19, 17, 20,
  20, 17, 19, 18, 19, 19, 17, 18, 18, 17, 17, 18, 20, 19, 23, 21, 20, 22, 20, 22,
  20, 22, 21, 21, 19, 20, 22, 18, 22, 24, 22, 24, 23, 21, 23, 20, 20, 22, 21, 21,
  22, 21, 22, 21, 22, 23, 22, 21, 20, 22, 22, 23, 25, 26, 25, 24, 24, 25, 26, 25,
  27, 24, 24, 24, 23, 26, 24, 24, 26, 25, 27, 25, 25, 26, 24, 24, 25, 26, 26, 25,
  25, 25, 25, 22, 28, 23, 23, 26, 26, 30, 27, 28, 28, 29, 28, 29, 29, 25, 26, 28,
  28, 26, 26, 30, 29, 25, 27, 27, 27, 29, 30, 28, 29, 28, 25, 27, 26, 28, 28, 27,
  26, 25, 28, 24, 26, 26, 32, 28, 30, 29, 30, 30, 30, 29, 28, 32, 31, 29, 26, 31,
  29, 32, 30, 30, 30, 24, 24, 24, 24, 24, 24, 24, 24, 24, 26, 26, 26, 26, 26, 24,
  24, 24, 24, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 26,
  26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 25,
  // Levels 301-350, added so "300+ levels" is literally true rather than an
  // exact 300 — same curve, same measurement, extending soloCfg's t past 1.0.
  25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 37, 37,
  37, 37, 37, 37, 37, 37, 37, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
];

/// A small number of levels (measured, not guessed) whose default
/// `modeSeed('solo', n)` board turned out to be mathematically unreachable
/// from solved by *any* forward move sequence — a genuine bug in
/// `genTubes`' reverse-move scrambler (taking a whole top run when a
/// different colour sits underneath isn't actually invertible by a single
/// forward pour, and it gets more likely as spare capacity shrinks —
/// confirmed via exhaustive search, and it hits almost the entire empty=1
/// tier — levels 226 onward, including the 301-350 extension). Rather than
/// touch `genTubes` itself (shared with
/// the duel modes, and JS-parity-tested), affected levels get an alternate
/// seed instead — see [soloLevelSeed]. The value is a seed *offset*, found
/// by the same measurement script trying +1, +2, ... until the board is
/// solvable.
const Map<int, int> kSoloSeedOverride = {
  86: 1, 161: 1, 180: 1,
  226: 29, 227: 28, 228: 27, 229: 26, 230: 4, 231: 3, 232: 2, 233: 1,
  235: 4, 236: 3, 237: 2, 238: 1,
  240: 46, 241: 45, 242: 44, 243: 43, 244: 35, 245: 34, 246: 33, 247: 32,
  248: 31, 249: 30, 250: 8, 251: 7, 252: 6, 253: 5, 254: 4, 255: 3, 256: 2,
  257: 1, 259: 15, 260: 84, 261: 83, 262: 82, 263: 81, 264: 80, 265: 79,
  266: 78, 267: 77, 268: 76, 269: 75, 270: 53, 271: 52, 272: 51, 273: 50,
  274: 49, 275: 48, 276: 47, 277: 46, 278: 45, 279: 44, 280: 22, 281: 21,
  282: 63, 283: 62, 284: 61, 285: 60, 286: 59, 287: 58, 288: 57, 289: 56,
  290: 34, 291: 33, 292: 32, 293: 31, 294: 30, 295: 29, 296: 28, 297: 27,
  298: 26, 299: 25, 300: 52,
  // Levels 301-350 (added past the original 300 — see kSoloOriginalLevelCount).
  301: 51, 302: 50, 303: 49, 304: 48, 305: 47, 306: 46, 307: 45, 308: 44,
  309: 43, 310: 21, 311: 20, 312: 19, 313: 18, 314: 17, 315: 16, 316: 15,
  317: 14, 318: 13, 319: 29, 320: 7, 321: 6, 322: 5, 323: 4, 324: 3, 325: 2,
  326: 1, 328: 65, 329: 64, 330: 42, 331: 41, 332: 40, 333: 39, 334: 38,
  335: 37, 336: 36, 337: 35, 338: 34, 339: 33, 340: 11, 341: 10, 342: 9,
  343: 8, 344: 7, 345: 6, 346: 5, 347: 4, 348: 3, 349: 2, 350: 171,
};

/// The actual seed to generate a Solo *level* board with — [modeSeed] offset
/// by [kSoloSeedOverride] where the default board was unsolvable. Daily
/// Challenge and Shuffle use their own seeding and never consult this.
int soloLevelSeed(int levelNumber) =>
    modeSeed('solo', levelNumber) + (kSoloSeedOverride[levelNumber] ?? 0);

int soloMovePar(int levelNumber) => kSoloMovePar[levelNumber - 1];

/// The real pass/fail move cap for a Solo level: measured near-optimal play
/// plus slack, so a good-but-imperfect solve still passes — only truly
/// wandering (the "infinite moves, never lose" gap this replaces) fails.
int soloMoveLimit(int levelNumber) => (soloMovePar(levelNumber) * 1.6).ceil();

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
