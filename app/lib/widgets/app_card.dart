import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// A rounded, shadowed, tappable card — the base surface used for mode
/// tiles, hub rows, and list rows throughout the app (decant.html's
/// `.card`/`.hub-card`/`.mtile`).
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accentColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.ink2,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: AppColors.outline, width: 3),
            // A faint glow in the card's own accent when it has one (mode
            // tiles, hub rows), else a neutral ambient one — CLAUDE.md,
            // updated 2026-08-30: glow is part of the dark/futuristic theme.
            boxShadow: [
              BoxShadow(
                color: (widget.accentColor ?? AppColors.outline).withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (widget.accentColor != null)
                    Container(width: 4, color: widget.accentColor),
                  Expanded(child: Padding(padding: widget.padding, child: widget.child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row-style card: leading icon tile, title/subtitle, trailing chevron.
/// Port of decant.html's `.hub-card`.
class HubCard extends StatelessWidget {
  final String emoji;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const HubCard({
    super.key,
    required this.emoji,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor, Color.lerp(accentColor, Colors.black, 0.3)!],
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.txt)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
        ],
      ),
    );
  }
}
