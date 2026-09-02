import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'entrance_reveal.dart';
import 'gem_painter.dart';

/// One Fuse grid cell: a gem that reads through size/gloss/facets first and
/// a small secondary numeral second (see gem_painter.dart), plus the
/// claimed-cell owner-coloured border. Re-skin of decant.html's `.cell` /
/// `.ess` / `.essN` / `.crown` — the claim border treatment is unchanged
/// from CLAUDE.md's spec, only the base tile's look was replaced.
class FuseCellView extends StatefulWidget {
  final double size;
  final int value; // 0 = empty
  final bool sealed;
  final int owner; // -1 none, 0 or 1
  final Color Function(int) colorOf;
  final bool selected;
  final bool isTarget;
  final bool dimmed;

  /// This cell's index in the 6x6 grid (row-major) — staggers its one-time
  /// entrance pop-in in a diagonal wave across the board instead of every
  /// tile materializing in the same frame. Purely cosmetic/perf.
  final int index;
  final int gridWidth;

  final int shakeTrigger;
  final VoidCallback? onTap;

  const FuseCellView({
    super.key,
    required this.size,
    required this.value,
    required this.sealed,
    required this.owner,
    required this.colorOf,
    this.selected = false,
    this.isTarget = false,
    this.dimmed = false,
    this.index = 0,
    this.gridWidth = 6,
    this.shakeTrigger = 0,
    this.onTap,
  });

  @override
  State<FuseCellView> createState() => _FuseCellViewState();
}

class _FuseCellViewState extends State<FuseCellView>
    with TickerProviderStateMixin {
  late final AnimationController _growCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..value = 1;
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(FuseCellView old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && widget.value != 0) {
      _growCtrl.forward(from: 0.5);
    }
    if (widget.shakeTrigger != old.shakeTrigger) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.value == 0;
    final color = empty ? null : widget.colorOf(widget.value - 1);

    Color borderColor;
    double borderWidth = 2.5;
    if (widget.sealed) {
      borderColor = widget.owner == 0 ? AppColors.p1 : AppColors.p2;
    } else if (widget.selected) {
      borderColor = AppColors.p1;
    } else if (widget.isTarget) {
      borderColor = AppColors.p1;
    } else {
      borderColor = AppColors.outline;
    }

    // Colour-matched glow — claimed cells glow in the owner's colour
    // (stronger, since that's the "this is won" signal), live gems glow
    // softly in their own colour. Part of the dark/futuristic theme's
    // glow-is-permitted update, not just decoration on empty cells.
    final List<BoxShadow>? glow = widget.sealed
        ? [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ]
        : (!empty
              ? [
                  BoxShadow(
                    color: color!.withValues(alpha: 0.32),
                    blurRadius: 11,
                  ),
                ]
              : null);

    final row = widget.index ~/ widget.gridWidth;
    final col = widget.index % widget.gridWidth;

    return EntranceReveal(
      delay: Duration(milliseconds: ((row + col) * 22).clamp(0, 260)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: widget.dimmed ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (context, child) {
              final t = _shakeCtrl.value;
              final dx = t == 0 || t == 1
                  ? 0.0
                  : (6 * (1 - t)) * ((t * 4).floor().isEven ? 1 : -1);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: empty
                    ? AppColors.txt.withValues(alpha: 0.02)
                    : AppColors.ink2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                  style: empty ? BorderStyle.solid : BorderStyle.solid,
                ),
                boxShadow: glow,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (!empty)
                    ScaleTransition(
                      scale: _growCtrl,
                      child: GemGlyph(
                        size: widget.size * 0.86,
                        value: widget.value,
                        color: color!,
                      ),
                    ),
                  if (!empty)
                    Positioned(
                      bottom: 3,
                      right: 4,
                      child: Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ink2,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.edge),
                        ),
                        child: Text(
                          '${widget.value}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mute,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  if (widget.sealed)
                    Positioned(
                      top: 3,
                      right: 5,
                      child: Text(
                        widget.owner == 0 ? '▲' : '▼',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
