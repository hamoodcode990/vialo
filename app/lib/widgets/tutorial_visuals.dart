/// Small illustrative widgets used by [ModeTutorialScreen] to *show* a
/// mechanic instead of only describing it in prose — a narrow tube filling
/// and locking, two tiles merging, a formula card completing. Kept as plain
/// shapes built from existing theme tokens (no image assets, matching the
/// app's no-external-asset posture) rather than bespoke art.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Cycles through [frames] on a fixed interval, crossfading between them.
/// The generic "show state A, then state B, then loop" building block every
/// mode's demo is made of.
class TutorialLoopDemo extends StatefulWidget {
  final List<Widget> frames;
  final Duration holdEach;

  const TutorialLoopDemo({
    super.key,
    required this.frames,
    this.holdEach = const Duration(milliseconds: 1400),
  });

  @override
  State<TutorialLoopDemo> createState() => _TutorialLoopDemoState();
}

class _TutorialLoopDemoState extends State<TutorialLoopDemo> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer = Timer(widget.holdEach, () {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % widget.frames.length);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(_frame),
        child: widget.frames[_frame],
      ),
    );
  }
}

/// A narrow capsule of stacked colour blocks — one tube. [blocks] runs
/// bottom-to-top (matching how a real tube pours), [capacity] pads the rest
/// with empty space. [sealed] draws a gold glow ring, as a claimed tube.
class TubeVisual extends StatelessWidget {
  final List<Color> blocks;
  final int capacity;
  final bool sealed;

  const TubeVisual({
    super.key,
    required this.blocks,
    this.capacity = 4,
    this.sealed = false,
  });

  @override
  Widget build(BuildContext context) {
    final empties = capacity - blocks.length;
    return Container(
      width: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: sealed ? AppColors.gold : AppColors.outline, width: sealed ? 2.5 : 2),
        boxShadow: sealed
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < empties; i++) const SizedBox(height: 14),
          for (final c in blocks.reversed)
            Container(
              width: double.infinity,
              height: 14,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
            ),
        ],
      ),
    );
  }
}

/// A numbered square tile (Fuse). Glows gold and shows the claimed number
/// when [sealed].
class TileVisual extends StatelessWidget {
  final int value;
  final Color color;
  final bool sealed;
  final bool empty;

  const TileVisual({
    super.key,
    required this.value,
    required this.color,
    this.sealed = false,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: empty ? AppColors.ink : color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: sealed ? AppColors.gold : AppColors.outline, width: sealed ? 2.5 : 2),
        boxShadow: sealed
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: empty
          ? null
          : Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
    );
  }
}

/// A row of dots standing in for a secret recipe/formula sequence. Filled
/// dots (up to [filled]) are coloured; the rest stay outline-only. Glows
/// gold when [complete].
class FormulaVisual extends StatelessWidget {
  final int total;
  final int filled;
  final Color color;
  final bool complete;

  const FormulaVisual({
    super.key,
    required this.total,
    required this.filled,
    required this.color,
    this.complete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: complete ? AppColors.gold : AppColors.outline, width: complete ? 2.5 : 2),
        boxShadow: complete
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 16,
              height: 16,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? color : Colors.transparent,
                border: Border.all(color: i < filled ? color : AppColors.outline, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small right-pointing chevron used between "before" and "after" tubes to
/// read as a pour/action, without implying a specific direction on screen.
class DemoArrow extends StatelessWidget {
  const DemoArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Icon(Icons.arrow_forward_rounded, color: AppColors.mute, size: 20),
    );
  }
}
