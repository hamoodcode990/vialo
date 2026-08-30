import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen soft gradient behind every screen, slowly drifting instead of
/// sitting as a static flat colour (CLAUDE.md Step 3 theme pass). Stays
/// within the warm ivory/parchment + emerald/rose/plum/gold palette — no
/// section gets its own distinct gradient yet, this is one shared backdrop
/// mounted once at the MaterialApp root via `builder:` so every Scaffold
/// (which is transparent, see buildAppTheme) shows it through.
class AnimatedAppBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAppBackground({super.key, required this.child});

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))
    ..repeat(reverse: true);

  static const _a = [Color(0xFFFBF7EE), Color(0xFFF3E9FF), Color(0xFFE9FBF2), Color(0xFFFFF1E6)];
  static const _b = [Color(0xFFFFF1E6), Color(0xFFFBF7EE), Color(0xFFF3E9FF), Color(0xFFE9FBF2)];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(_a[0], _b[0], t)!,
                Color.lerp(_a[1], _b[1], t)!,
                Color.lerp(_a[2], _b[2], t)!,
                Color.lerp(_a[3], _b[3], t)!,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Fallback flat colour for contexts that render before the animated
/// backdrop mounts (e.g. the native launch screen).
const kBackgroundFallback = AppColors.ink;
