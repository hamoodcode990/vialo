import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The full-screen backdrop every route paints for itself (AppRoute,
/// GameRoute): a deep near-black navy-to-plum gradient. Scaffolds are
/// transparent, so this is what makes each screen opaque.
///
/// Fully static: no ticker, no Timer, nothing scheduling a repaint here.
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

/// Flat colour under the Navigator, for anything that renders before a
/// route's backdrop mounts.
const kBackgroundFallback = AppColors.ink;
