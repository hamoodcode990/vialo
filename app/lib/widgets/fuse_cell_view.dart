import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'tube_painter.dart' show shade;

/// One Fuse grid cell: an "essence droplet" that grows with the tile value,
/// a small numeral, and a crown once claimed. Port of decant.html's `.cell`
/// / `.ess` / `.essN` / `.crown`.
class FuseCellView extends StatefulWidget {
  final double size;
  final int value; // 0 = empty
  final bool sealed;
  final int owner; // -1 none, 0 or 1
  final Color Function(int) colorOf;
  final bool selected;
  final bool isTarget;
  final bool dimmed;
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
    this.shakeTrigger = 0,
    this.onTap,
  });

  @override
  State<FuseCellView> createState() => _FuseCellViewState();
}

class _FuseCellViewState extends State<FuseCellView> with TickerProviderStateMixin {
  late final AnimationController _growCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 240))..value = 1;
  late final AnimationController _shakeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

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
    final dropSize = empty ? 0.0 : widget.size * (0.34 + 0.15 * (widget.value - 1));
    final color = empty ? null : widget.colorOf(widget.value - 1);

    Color borderColor;
    double borderWidth = 1;
    if (widget.sealed) {
      borderColor = widget.owner == 0 ? AppColors.p1 : AppColors.p2;
    } else if (widget.selected) {
      borderColor = AppColors.p1;
      borderWidth = 2.5;
    } else if (widget.isTarget) {
      borderColor = AppColors.p1;
      borderWidth = 2;
    } else {
      borderColor = AppColors.edge;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.dimmed ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (context, child) {
            final t = _shakeCtrl.value;
            final dx = t == 0 || t == 1 ? 0.0 : (6 * (1 - t)) * ((t * 4).floor().isEven ? 1 : -1);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: empty ? AppColors.txt.withValues(alpha: 0.02) : AppColors.ink2,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
                style: empty ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (!empty)
                  ScaleTransition(
                    scale: _growCtrl,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: dropSize,
                        height: dropSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(dropSize / 2),
                            topRight: Radius.circular(dropSize / 2),
                            bottomRight: Radius.circular(dropSize / 2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color!, shade(color, -30)],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!empty)
                  Positioned(
                    bottom: 4,
                    right: 6,
                    child: Text(
                      '${widget.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mute,
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
    );
  }
}
