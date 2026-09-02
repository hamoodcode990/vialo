import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/chapters.dart';
import '../widgets/star_row.dart';

enum LevelNodeState { locked, current, complete }

class LevelNodeData {
  final int level;
  final LevelNodeState state;
  final int stars; // 0-3, meaningful only when state == complete
  const LevelNodeData({required this.level, required this.state, this.stars = 0});
}

/// One chapter's stretch of winding road (CLAUDE.md Step 10) — a 2D path
/// with perspective tricks rather than a real 3D scene: node horizontal
/// position follows a sine wave (the "curves left/right" the prompt calls
/// for) and node size varies slightly along the same wave to suggest depth,
/// with a smoothed curve drawn through every node center. Self-contained
/// and lazily built per chapter by the caller (a ListView.builder) so this
/// never has to lay out all 350 Solo levels at once.
class LevelRoadSection extends StatelessWidget {
  final Chapter chapter;
  final List<LevelNodeData> nodes;
  final void Function(LevelNodeData node) onTapNode;

  const LevelRoadSection({super.key, required this.chapter, required this.nodes, required this.onTapNode});

  static const double _rowHeight = 96;
  static const double _amplitude = 0.30; // fraction of section width
  static const double _period = 0.85; // radians per node

  Offset _fracPosition(int i) {
    final dx = 0.5 + _amplitude * math.sin(i * _period);
    final dy = (i + 0.5) * _rowHeight;
    return Offset(dx, dy);
  }

  double _sizeFor(int i) => 54 + 8 * math.sin(i * _period * 0.5);

  @override
  Widget build(BuildContext context) {
    final height = nodes.length * _rowHeight + 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChapterTitleCard(chapter: chapter),
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final points = [for (var i = 0; i < nodes.length; i++) _fracPosition(i).scale(w, 1)];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _RoadPainter(points: points, color: chapter.accent)),
                  ),
                  for (var i = 0; i < nodes.length; i++)
                    Positioned(
                      left: points[i].dx - _sizeFor(i) / 2,
                      top: points[i].dy - _sizeFor(i) / 2,
                      child: _LevelNode(
                        data: nodes[i],
                        size: _sizeFor(i),
                        accent: chapter.accent,
                        onTap: () => onTapNode(nodes[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChapterTitleCard extends StatelessWidget {
  final Chapter chapter;
  const _ChapterTitleCard({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [chapter.accent.withValues(alpha: 0.16), chapter.accent.withValues(alpha: 0.04)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHAPTER ${chapter.index + 1}',
            style: TextStyle(fontSize: 10.5, letterSpacing: 2, fontWeight: FontWeight.w800, color: chapter.accent),
          ),
          const SizedBox(height: 2),
          Text(chapter.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.txt)),
          const SizedBox(height: 3),
          Text(chapter.blurb, style: const TextStyle(fontSize: 12.5, color: AppColors.mute, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final LevelNodeData data;
  final double size;
  final Color accent;
  final VoidCallback onTap;

  const _LevelNode({required this.data, required this.size, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = data.state == LevelNodeState.locked;
    final current = data.state == LevelNodeState.current;
    final complete = data.state == LevelNodeState.complete;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size + (complete ? 16 : 0),
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: current ? 4 : 3),
                gradient: locked
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, Color.lerp(accent, Colors.black, 0.28)!],
                      ),
                color: locked ? AppColors.ink2 : null,
                // Locked nodes are flat/inert (just a circle + lock icon) and
                // are the large majority of nodes on any level-road screen —
                // most of a mode's 100-350 levels sit past the unlock
                // frontier. A blurred BoxShadow on every one of them, on top
                // of the completed/current nodes that actually earn a glow,
                // was a lot of simultaneous blur for the compositor on
                // screens with several dozen nodes visible at once.
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: (current ? accent : AppColors.txt).withValues(alpha: current ? 0.45 : 0.14),
                          blurRadius: current ? 18 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: locked
                  ? const Icon(Icons.lock_rounded, color: AppColors.mute, size: 20)
                  : Text(
                      '${data.level}',
                      style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
            if (complete) ...[
              const SizedBox(height: 3),
              StarRow(stars: data.stars, size: 9),
            ],
          ],
        ),
      ),
    );
  }
}

/// Draws a smooth curve through every node center (a quadratic-bezier
/// "through-points" pass — moves to each midpoint, using the raw point as
/// the control) plus a soft double-line "road" treatment.
class _RoadPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  const _RoadPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final mid = Offset((points[i].dx + points[i + 1].dx) / 2, (points[i].dy + points[i + 1].dy) / 2);
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.14);
    canvas.drawPath(path, base);

    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.4);
    canvas.drawPath(path, dashed);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => oldDelegate.points != points || oldDelegate.color != color;
}
