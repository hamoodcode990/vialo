import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import 'app_button.dart';
import 'star_row.dart';

/// The win/loss/draw result card shown at the bottom of a game screen once
/// it's over. Port of decant.html's `.res` card.
class GameResultPanel extends StatelessWidget {
  final String title;
  final Color color;
  final String subtitle;
  final int? stars;
  final List<Widget> actions;

  const GameResultPanel({
    super.key,
    required this.title,
    required this.color,
    required this.subtitle,
    this.stars,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.txt.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
          if (stars != null) ...[
            const SizedBox(height: 8),
            StarRow(stars: stars!, size: 22),
          ],
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: actions[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget primaryAction(String label, VoidCallback onPressed) =>
    AppButton(label: label, onPressed: onPressed);

Widget secondaryAction(String label, VoidCallback onPressed) =>
    AppButton(label: label, onPressed: onPressed, style: AppButtonStyle.secondary);
