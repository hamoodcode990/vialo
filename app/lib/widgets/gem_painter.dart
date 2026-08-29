import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tube_painter.dart' show shade;

/// Fuse tile visual, Step 2 of the Vialo UI/content batch: value is read
/// through gem size/gloss/facet count first, the numeral second. Three
/// live tiers (Fuse's grid starts values at 1-3 and a merge that reaches
/// [kFuseTarget]=4 seals the cell instead of ever sitting at value 4
/// unclaimed — see CLAUDE.md/fuse.dart) escalate from a small plain drop
/// to a bigger, brighter, multi-facet gem:
///
/// - tier 1: small circle, one soft highlight.
/// - tier 2: bigger, a second facet streak, crisper rim.
/// - tier 3: biggest and roundest, two highlights + a sparkle glint and a
///   soft drop shadow, reads as the most "precious" of the three.
///
/// Sealed/claimed cells keep the existing owner-coloured border treatment
/// from FuseCellView untouched — this file only re-skins the base gem.
class GemGlyph extends StatelessWidget {
  final double size;
  final int value; // 1-3
  final Color color;

  const GemGlyph({super.key, required this.size, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: GemPainter(tier: value.clamp(1, 3), color: color),
    );
  }
}

class GemPainter extends CustomPainter {
  final int tier; // 1, 2, or 3
  final Color color;

  GemPainter({required this.tier, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final frac = switch (tier) { 1 => 0.46, 2 => 0.62, _ => 0.78 };
    final r = size.width * frac / 2;

    if (tier == 3) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(c.translate(0, r * 0.14), r * 0.98, shadow);
    }

    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.95,
        colors: [shade(color, tier == 1 ? 26 : 40), color, shade(color, -(18 + tier * 6))],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, base);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tier == 1 ? 1.0 : 1.6
      ..color = Colors.white.withValues(alpha: tier == 1 ? 0.35 : 0.55);
    canvas.drawCircle(c, r - rim.strokeWidth / 2, rim);

    final mainHi = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: tier == 1 ? 0.55 : 0.8), Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c.translate(-r * 0.32, -r * 0.34), radius: r * 0.5));
    canvas.drawCircle(c.translate(-r * 0.32, -r * 0.34), r * 0.5, mainHi);

    if (tier >= 2) {
      final facet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawLine(
        c.translate(-r * 0.5, r * 0.25),
        c.translate(r * 0.15, r * 0.55),
        facet,
      );
    }

    if (tier >= 3) {
      final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.9);
      final sp = c.translate(r * 0.4, r * 0.15);
      _drawSparkle(canvas, sp, r * 0.14, sparkle);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tip = center + Offset(math.cos(a), math.sin(a)) * radius;
      final side1 = center + Offset(math.cos(a + math.pi / 4), math.sin(a + math.pi / 4)) * (radius * 0.28);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(side1.dx, side1.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GemPainter oldDelegate) => oldDelegate.tier != tier || oldDelegate.color != color;
}
