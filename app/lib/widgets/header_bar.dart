import 'package:flutter/material.dart';

import '../profile/player_profile.dart';
import '../theme/app_colors.dart';
import '../theme/cosmetics.dart';
import '../theme/spacing.dart';

/// Avatar · lives (with a refill countdown) · coins — shown on every
/// non-gameplay screen. Port of decant.html's `headerBar()`.
///
/// Takes the whole [profile] rather than pulling out `lives`/`countdownText`
/// at each call site — that used to mean only the Home screen actually
/// bothered to compute and pass a countdown, so the other three screens
/// with a header (mode hub, level select, Solo's map) silently showed a
/// bare life count with no refill timer at all. Computing it once, here,
/// makes every screen consistent for free.
class HeaderBar extends StatelessWidget {
  final AvatarOption avatar;
  final PlayerProfile profile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLivesTap;
  final VoidCallback? onCoinsTap;

  const HeaderBar({
    super.key,
    required this.avatar,
    required this.profile,
    this.onAvatarTap,
    this.onLivesTap,
    this.onCoinsTap,
  });

  @override
  Widget build(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final unlimited = profile.livesUnlimited(nowMs);
    final nextMs = profile.nextLifeMs(nowMs);

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
                Text(
                  unlimited ? '∞' : '${profile.lives}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.life),
                ),
                if (!unlimited && nextMs > 0) ...[
                  const SizedBox(width: 5),
                  Text('⏳', style: TextStyle(fontSize: 9, color: AppColors.mute.withValues(alpha: 0.8))),
                  const SizedBox(width: 2),
                  Text(
                    formatLifeCountdown(nextMs),
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.mute),
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
                Text('${profile.coins}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldd)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `"47m"` under an hour, `"2h 13m"` at or past one — the one place this
/// formatting happens, shared by [HeaderBar] and the Store's lives status.
String formatLifeCountdown(int ms) {
  final s = (ms / 1000).ceil();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
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
