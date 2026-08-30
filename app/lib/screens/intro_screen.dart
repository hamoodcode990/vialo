import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cold-launch logo/wordmark reveal (CLAUDE.md Step 4). Runs once, fixed
/// 2.4s duration — the "1.5-2.5s max" ceiling, bumped up from 1.8s after
/// it read as too rushed — then calls [onDone]. Independent of profile
/// load time: [_AppGate] in main.dart
/// keeps this on screen (its rest frame + a small spinner) if the
/// shared_preferences read is still pending once the reveal finishes, so
/// the player never sees a blank frame either way.
class IntroScreen extends StatefulWidget {
  final VoidCallback onDone;
  final bool showLoadingSpinner;

  /// False for the "still waiting on the profile load" rest frame shown
  /// after the reveal already played once — avoids replaying the pop-in.
  final bool animate;

  const IntroScreen({super.key, required this.onDone, this.showLoadingSpinner = false, this.animate = true});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2400);
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: _duration);

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _ctrl.value = 1;
      return;
    }
    _ctrl.forward();
    Future.delayed(_duration, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            // Droplets pop in staggered (0.0-0.55 of the timeline), then the
            // wordmark + tagline fade/slide up (0.4-0.9). Widened windows
            // and a single-overshoot curve (not elasticOut's multi-wobble)
            // so the reveal reads as smooth and deliberate, not a quick snap.
            const dropColors = [AppColors.p2, AppColors.violet, AppColors.p1, AppColors.gold];
            final dropScales = List.generate(4, (i) {
              final start = i * 0.09;
              final t = ((_ctrl.value - start) / 0.42).clamp(0.0, 1.0);
              return Curves.easeOutBack.transform(t);
            });
            final wordT = Curves.easeOutCubic.transform(((_ctrl.value - 0.4) / 0.45).clamp(0.0, 1.0));
            final tagT = Curves.easeOutCubic.transform(((_ctrl.value - 0.6) / 0.35).clamp(0.0, 1.0));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Transform.scale(
                        scale: dropScales[i],
                        child: Container(
                          width: 16,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: dropColors[i],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.outline, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: wordT,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - wordT)),
                    child: const Text(
                      'VIALO',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.6, color: AppColors.txt),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: tagT,
                  child: const Text(
                    'ONE BOARD · TWO MINDS · CLAIM IT',
                    style: TextStyle(fontSize: 10.5, letterSpacing: 3.6, color: AppColors.mute, fontWeight: FontWeight.w600),
                  ),
                ),
                if (widget.showLoadingSpinner) ...[
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: tagT,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.mute),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
