import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Three soft, blurred colour blobs drifting at different fractions of
/// scroll speed — the "parallax background layers" CLAUDE.md Step 10 asks
/// for, shared by every mode's level-map/road screen (Solo plus the four
/// duel modes). Deliberately simple (no image assets, matching the app's
/// no-external-asset posture) rather than a painted landscape.
class ParallaxBackdrop extends StatelessWidget {
  final ScrollController scrollController;
  const ParallaxBackdrop({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients ? scrollController.offset : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -60,
              top: 40 - offset * 0.12,
              child: _Blob(color: AppColors.p1.withValues(alpha: 0.10), size: 220),
            ),
            Positioned(
              right: -80,
              top: 420 - offset * 0.22,
              child: _Blob(color: AppColors.violet.withValues(alpha: 0.09), size: 260),
            ),
            Positioned(
              left: -40,
              top: 900 - offset * 0.17,
              child: _Blob(color: AppColors.gold.withValues(alpha: 0.10), size: 200),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
