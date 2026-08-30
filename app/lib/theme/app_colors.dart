import 'package:flutter/material.dart';

/// Brand/UI colours. Dark/futuristic theme (CLAUDE.md, updated 2026-08-30 —
/// explicitly overrides the project's earlier warm-light "no dark mode, no
/// neon, no glow" decision, at the user's direction). Deep near-black/navy
/// chrome, saturated neon-adjacent accents, glow permitted — kept simple
/// (few colours, used consistently) rather than busy.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF0A0C16); // app background — near-black navy
  static const ink2 = Color(0xFF12162A); // card/surface background
  static const edge = Color(0x14FFFFFF); // rgba(255,255,255,.08) hairline border
  static const txt = Color(0xFFF0F1FA);
  static const mute = Color(0xFF8890B8);

  /// Bold outline used on buttons/cards/tiles/tubes for the "juicy" read
  /// (CLAUDE.md Step 3). Deliberately desaturated slate-blue, not a bright
  /// hue — it used to be a saturated indigo only ~30° around the wheel from
  /// [violet], so every bordered element visually competed with the actual
  /// violet accent instead of reading as neutral structure. Not the same
  /// as [edge], which stays a near-invisible hairline for secondary chrome.
  static const outline = Color(0xFF4A5580);

  // Accents spaced deliberately around the hue wheel (roughly 40/160/260/335°)
  // so no two are mistakable for each other, even before the desaturated
  // outline above is factored in — this is what "colours too close
  // together" was actually about, not any one colour in isolation.
  static const p1 = Color(0xFF00E5A0); // neon emerald ~160° — player 1 / success
  static const p1d = Color(0xFF00B37D);
  static const p2 = Color(0xFFFF3D81); // neon rose ~335° — player 2 / life
  static const p2d = Color(0xFFE01463);
  static const violet = Color(0xFF9D5CFF); // ~260°
  static const violetd = Color(0xFF7A2FF0);
  static const gold = Color(0xFFFFC13C); // ~40°, also "coin"
  static const goldd = Color(0xFFE89A0A);
  static const hot = Color(0xFFFF4C29); // ~11°, urgent/error/lost — was ~5° from p2, pulled further from it

  static const life = p2;
  static const coin = gold;
}
