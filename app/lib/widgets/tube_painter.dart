import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A contiguous run of one colour, bottom-up — mirrors how decant.html's
/// `tubesHTML`/`drawSolo` merge same-colour runs into one visual liquid
/// block instead of drawing every unit slice separately.
class LiquidSegment {
  final Color color;
  final int count;
  const LiquidSegment(this.color, this.count);
}

List<LiquidSegment> mergeSegments(List<int> contents, Color Function(int) colorOf) {
  final out = <LiquidSegment>[];
  var k = 0;
  while (k < contents.length) {
    var j = k;
    while (j + 1 < contents.length && contents[j + 1] == contents[k]) {
      j++;
    }
    out.add(LiquidSegment(colorOf(contents[k]), j - k + 1));
    k = j + 1;
  }
  return out;
}

Color shade(Color c, int delta) {
  final d = delta / 255.0;
  double clamp01(double v) => v.clamp(0.0, 1.0);
  return Color.from(
    alpha: c.a,
    red: clamp01(c.r + d),
    green: clamp01(c.g + d),
    blue: clamp01(c.b + d),
  );
}

// A shared "essence" undertone every liquid blends toward near the bottom of
// its vial — a deep plum-black rather than a paint-chip darken of the same
// hue. This is what actually reads as "a mixed liquid in a glass vial" (one
// consistent depth colour every essence sits in) instead of "a flat colour
// with a gradient slapped on" — CLAUDE.md's tube_palettes.dart hex values
// (deuteranopia-audited, distance-measured) are untouched; only how a
// resolved colour gets *painted* changes here.
const _essenceUndertone = Color(0xFF1A0E2E);

/// A cheap, tasteful "blend" for one liquid segment: a touch lighter/warmer
/// at the surface (a highlight the essence catches), true to the palette
/// colour through the body, and blended toward [_essenceUndertone] — not a
/// flat darken — near the bottom, so every colour reads as one liquid
/// sharing the same glass rather than a solid paint chip.
List<Color> _essenceGradient(Color base) => [
      Color.lerp(base, Colors.white, 0.18)!,
      base,
      Color.lerp(base, _essenceUndertone, 0.42)!,
    ];

/// Renders the glass tube outline (rounded top, more-rounded bottom —
/// decant.html's `border-radius: 16% 16% 40% 40%` flask shape) with a
/// specular highlight streak, plus the stacked liquid segments with a
/// curved meniscus on the topmost one. Port of `.glass`/`.liq` CSS.
class TubePainter extends CustomPainter {
  final int capacity;
  final List<LiquidSegment> segments;
  final bool sealed;

  TubePainter({required this.capacity, required this.segments, required this.sealed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = h / capacity;

    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: Radius.circular(w * 0.16),
      topRight: Radius.circular(w * 0.16),
      bottomLeft: Radius.circular(w * 0.4),
      bottomRight: Radius.circular(w * 0.4),
    );

    // Glass body base tint.
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.55), AppColors.txt.withValues(alpha: 0.05)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, glassPaint);

    // Liquid, bottom-up.
    canvas.save();
    canvas.clipRRect(rrect);
    var bottomY = h;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final segH = unit * seg.count;
      final top = bottomY - segH;
      final isTopSegment = i == segments.length - 1;
      final rect = Rect.fromLTRB(0, top, w, bottomY);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _essenceGradient(seg.color),
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect);
      if (sealed) paint.color = paint.color.withValues(alpha: 0.62);

      if (isTopSegment) {
        final path = Path()
          ..moveTo(0, top + 6)
          ..quadraticBezierTo(w / 2, top - 5, w, top + 6)
          ..lineTo(w, bottomY)
          ..lineTo(0, bottomY)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
      bottomY = top;
    }

    // A single soft diagonal sheen across every liquid segment at once —
    // one extra shader fill per tube, not per segment, so this stays as
    // cheap as the rest of the paint. A warm gold catch-light (this game's
    // established accent for "something precious", not a random tint) is
    // what actually reads as "an essence", not a flat colour swatch.
    if (segments.isNotEmpty) {
      final sheen = Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.10),
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTRB(0, 0, w, h));
      canvas.drawRect(Rect.fromLTRB(0, 0, w, h), sheen);
    }
    canvas.restore();

    // Glass outline + specular highlight.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawRRect(rrect.deflate(0.75), outline);

    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(w * 0.13, h * 0.04, w * 0.1, h * 0.84));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.13, h * 0.04, w * 0.1, h * 0.84),
        Radius.circular(w * 0.05),
      ),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.sealed != sealed;
}
