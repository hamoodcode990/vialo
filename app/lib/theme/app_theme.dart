import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'spacing.dart';

/// Assembles the Flutter [ThemeData] from the design tokens. Dark,
/// futuristic, simple — neon-adjacent accents and glow are part of the
/// design now (CLAUDE.md, updated 2026-08-30 override of the earlier
/// warm-light "no dark mode" decision).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.p1,
    brightness: Brightness.dark,
    primary: AppColors.p1,
    secondary: AppColors.violet,
    tertiary: AppColors.gold,
    error: AppColors.hot,
    surface: AppColors.ink2,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Transparent so every Scaffold shows the shared AnimatedAppBackground
    // mounted at the MaterialApp root instead of a flat colour.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: AppColors.ink,
    // Fredoka: rounded, heavy-weight display font for the candy-puzzle look
    // (CLAUDE.md Step 3) — bundled OFL asset, see assets/fonts/.
    fontFamily: 'Fredoka',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: AppColors.txt,
      ),
      headlineSmall: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.txt,
      ),
      titleMedium: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: AppColors.txt,
      ),
      bodyMedium: TextStyle(fontSize: 13.5, color: AppColors.mute, height: 1.4),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: AppColors.mute,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.txt,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.txt,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.ink2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.outline, width: 3),
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
