import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen soft gradient behind every screen (CLAUDE.md Step 3 theme
/// pass) — mounted once at the MaterialApp root via `builder:` so every
/// Scaffold (which is transparent, see buildAppTheme) shows it through.
///
/// This used to drift slowly (first a 60fps AnimationController, then a
/// throttled Timer after that was reported as janky) — now fully static.
/// Reported lag persisted even after throttling, so rather than keep
/// tuning an update rate I can't measure, this removes the one thing that
/// was *guaranteed* to cost something on every frame: there is no ticker,
/// no Timer, nothing scheduling repaints here at all now. If page
/// transitions are still slow after this, the cause is elsewhere (a
/// specific screen's build/animation work, or the app running in debug
/// mode — debug builds are inherently much slower than release/profile,
/// worth checking before hunting for more code-level causes).
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
          colors: [Color(0xFFFBF7EE), Color(0xFFF3E9FF), Color(0xFFE9FBF2), Color(0xFFFFF1E6)],
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
