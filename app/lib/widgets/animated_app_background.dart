import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen backdrop behind every screen — mounted once at the
/// MaterialApp root via `builder:` so every Scaffold (which is transparent,
/// see buildAppTheme) shows it through. Dark/futuristic theme (CLAUDE.md,
/// updated 2026-08-30): a deep near-black navy-to-plum gradient, matching
/// the app icon's own dark tube-pour art instead of clashing with it.
///
/// Fully static — no ticker, no Timer, nothing scheduling a repaint here.
/// This was previously an animated drift (first a 60fps AnimationController,
/// then a throttled Timer) but reported lag persisted even after
/// throttling, so rather than keep tuning an update rate that can't be
/// measured in this environment, the animation was removed entirely.
class AnimatedAppBackground extends StatelessWidget {
  final Widget child;
  const AnimatedAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0C16), Color(0xFF141230), Color(0xFF0D1220), Color(0xFF0A0C16)],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Fallback flat colour for contexts that render before the backdrop mounts
/// (e.g. the native launch screen).
const kBackgroundFallback = AppColors.ink;
