import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'spacing.dart';

/// Assembles the Flutter [ThemeData] from the design tokens. Bright,
/// glossy, chunky per the mainstream-puzzle-app restyle — no dark mode, no
/// neon-as-default (Neon stays an opt-in tube palette, never the app chrome).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.p1,
    brightness: Brightness.light,
    primary: AppColors.p1,
    secondary: AppColors.violet,
    tertiary: AppColors.gold,
    error: AppColors.hot,
    surface: AppColors.ink2,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    canvasColor: AppColors.ink,
    fontFamily: null, // platform default (SF Pro on iOS), matches the HTML's system-font stack
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.edge),
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
