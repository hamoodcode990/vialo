import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

enum AppButtonStyle { primary, secondary, ghost, gold, violet }

/// Chunky, beveled, tappable button — port of decant.html's `.go`/`.gh`/
/// `.buy` button treatment (thick radius, layered shadow, scale-down press).
/// Every tap plays the shared "button tap" SFX (CLAUDE.md Step 9) — this is
/// the one shared widget every screen's buttons already go through, so it's
/// the single place that covers the whole app rather than wiring it at
/// every call site.
class AppButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
  });

  @override
  ConsumerState<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends ConsumerState<AppButton> {
  bool _pressed = false;

  void _handleTap() {
    ref.read(audioControllerProvider).buttonTap();
    widget.onPressed?.call();
  }

  ({Color bg, Color fg, Gradient? gradient, Border? border}) _colors() {
    switch (widget.style) {
      case AppButtonStyle.primary:
        return (bg: AppColors.p1, fg: Colors.white, gradient: const LinearGradient(colors: [AppColors.p1, AppColors.p1d], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: AppColors.outline, width: 3));
      case AppButtonStyle.gold:
        return (bg: AppColors.gold, fg: Colors.white, gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldd], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: AppColors.outline, width: 3));
      case AppButtonStyle.violet:
        return (bg: AppColors.violet, fg: Colors.white, gradient: const LinearGradient(colors: [AppColors.violet, AppColors.violetd], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: AppColors.outline, width: 3));
      case AppButtonStyle.secondary:
        return (bg: AppColors.ink2, fg: AppColors.mute, gradient: null, border: Border.all(color: AppColors.outline, width: 3));
      case AppButtonStyle.ghost:
        return (bg: Colors.transparent, fg: AppColors.mute, gradient: null, border: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: disabled ? null : _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: c.gradient == null ? c.bg : null,
              gradient: c.gradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: c.border,
              // A soft colour-matched glow rather than a glossy bevel — reads
              // as neon/futuristic against the dark backdrop (CLAUDE.md,
              // updated 2026-08-30: glow effects are now part of the design).
              boxShadow: c.gradient == null
                  ? null
                  : [
                      BoxShadow(color: c.bg.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 1, offset: const Offset(0, 6)),
                      BoxShadow(color: c.bg.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 2),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: c.fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
