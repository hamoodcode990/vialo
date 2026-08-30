import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';

/// Avatar · lives (with countdown) · coins — shown on every non-gameplay
/// screen. Port of decant.html's `headerBar()`.
class HeaderBar extends StatelessWidget {
  final AvatarOption avatar;
  final int lives;
  final int lifeMax;
  final String? countdownText;
  final int coins;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLivesTap;
  final VoidCallback? onCoinsTap;

  const HeaderBar({
    super.key,
    required this.avatar,
    required this.lives,
    required this.lifeMax,
    this.countdownText,
    required this.coins,
    this.onAvatarTap,
    this.onLivesTap,
    this.onCoinsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          GestureDetector(onTap: onAvatarTap, child: AvatarGlyph(avatar: avatar)),
          const Spacer(),
          _Pill(
            color: AppColors.life,
            onTap: onLivesTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text('$lives', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.life)),
                if (countdownText != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    countdownText!,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.mute),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            color: AppColors.goldd,
            onTap: onCoinsTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldd)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  const _Pill({required this.color, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outline, width: 2.5),
          boxShadow: [BoxShadow(color: AppColors.txt.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: child,
      ),
    );
  }
}
