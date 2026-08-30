import 'package:flutter/material.dart';

/// Brand/UI colours — ported verbatim from decant.html's `:root` CSS custom
/// properties. This is the design reference (per flutter_port_plan.md
/// Phase 4); do not "improve" these by feel.
class AppColors {
  AppColors._();

  static const ink = Color(0xFFF5F3FF); // app background
  static const ink2 = Color(0xFFFFFFFF); // card/surface background
  static const edge = Color(0x141C1B2D); // rgba(28,27,45,.08) hairline border
  static const txt = Color(0xFF1C1B24);
  static const mute = Color(0xFF83809A);

  /// Bold, dark "ink line" outline used on buttons/cards/tiles/tubes for the
  /// candy-puzzle "juicy" read (CLAUDE.md Step 3) — not the same as [edge],
  /// which stays a near-invisible hairline for secondary chrome.
  static const outline = Color(0xFF241A38);

  static const p1 = Color(0xFF00C389); // emerald — player 1 / success
  static const p1d = Color(0xFF009A6C);
  static const p2 = Color(0xFFFF4D74); // rose — player 2 / life
  static const p2d = Color(0xFFE22F58);
  static const violet = Color(0xFF7B5CFA);
  static const violetd = Color(0xFF5F3FE0);
  static const gold = Color(0xFFFFB020); // also "coin"
  static const goldd = Color(0xFFE8930A);
  static const hot = Color(0xFFFF4438); // urgent/error/lost

  static const life = p2;
  static const coin = gold;
}
