import 'package:flutter/material.dart';

import '../theme/board_colors.dart';

/// A contiguous run of one colour, bottom-up. Fractional while a pour is
/// moving liquid between tubes.
class LiquidSegment {
  final Color color;
  final double count;
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
    out.add(LiquidSegment(colorOf(contents[k]), (j - k + 1).toDouble()));
    k = j + 1;
  }
  return out;
}

/// [bands] with [delta] units of [color] added to (or, if negative, taken off)
/// the top.
List<LiquidSegment> adjustTop(List<LiquidSegment> bands, Color color, double delta) {
  if (delta == 0) return bands;
  final out = List<LiquidSegment>.of(bands);
  if (delta > 0) {
    if (out.isNotEmpty && out.last.color == color) {
      out[out.length - 1] = LiquidSegment(color, out.last.count + delta);
    } else {
      out.add(LiquidSegment(color, delta));
    }
    return out;
  }
  var remove = -delta;
  while (remove > 1e-9 && out.isNotEmpty) {
    final top = out.last;
    if (top.count > remove) {
      out[out.length - 1] = LiquidSegment(top.color, top.count - remove);
      remove = 0;
    } else {
      remove -= top.count;
      out.removeLast();
    }
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

/// The darker outer edge that separates a tube from the background. Selected,
/// legal-target and sealed tubes replace it with their own colour.
const Color kTubeEdgeColor = Color(0xFF2B3252);

/// Each colour band: a touch lighter at the top, a touch darker at the bottom.
/// tube_palettes.dart's audited hex values are untouched; only how a resolved
/// colour gets painted changes here.
List<Color> _bandGradient(Color base) => [
      Color.lerp(base, Colors.white, 0.10)!,
      base,
      Color.lerp(base, Colors.black, 0.20)!,
    ];

RRect tubeRRect(Size size) => RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: Radius.circular(size.width * 0.16),
      topRight: Radius.circular(size.width * 0.16),
      bottomLeft: Radius.circular(size.width * 0.4),
      bottomRight: Radius.circular(size.width * 0.4),
    );

/// The fill for one colour band spanning [rect].
Paint bandPaint(Color color, Rect rect) {
  final metallic = color == kMetallicGold;
  return Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: metallic ? kMetallicGoldStops : _bandGradient(color),
      stops: metallic ? const [0.0, 0.3, 0.7, 1.0] : const [0.0, 0.45, 1.0],
    ).createShader(rect);
}

/// A fixed diagonal glint on gold rather than a moving shimmer: an animated one
/// would keep the screen repainting while nothing is happening.
void paintGoldGlint(Canvas canvas, Rect rect) {
  canvas.save();
  canvas.clipRect(rect);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.28, 0.42, 0.56],
      ).createShader(rect),
  );
  canvas.restore();
}

/// The lighter line along a liquid's surface.
Paint meniscusPaint(Color color) => Paint()
  ..color = Color.lerp(color == kMetallicGold ? kMetallicGoldStops.first : color, Colors.white, 0.45)!
  ..strokeWidth = 2
  ..style = PaintingStyle.stroke;

/// Clear glass: the background shows through, with the faintest white tint.
void paintGlassBack(Canvas canvas, Size size) {
  canvas.drawRRect(
    tubeRRect(size),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.05)],
      ).createShader(Offset.zero & size),
  );
}

/// Everything in front of the liquid: inner shadow at the bottom curve, the
/// left streak, a faint right-edge highlight and the bright rim.
void paintGlassFront(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final rrect = tubeRRect(size);

  canvas.save();
  canvas.clipRRect(rrect);
  final shadow = Rect.fromLTWH(0, h - w * 0.55, w, w * 0.55);
  canvas.drawRect(
    shadow,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.22)],
      ).createShader(shadow),
  );
  canvas.restore();

  final streak = Rect.fromLTWH(w * 0.13, h * 0.04, w * 0.1, h * 0.84);
  canvas.drawRRect(
    RRect.fromRectAndRadius(streak, Radius.circular(w * 0.05)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.62), Colors.white.withValues(alpha: 0)],
      ).createShader(streak),
  );

  final rightEdge = Rect.fromLTWH(w * 0.86, h * 0.06, w * 0.045, h * 0.74);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rightEdge, Radius.circular(w * 0.03)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.20), Colors.white.withValues(alpha: 0)],
      ).createShader(rightEdge),
  );

  canvas.drawRRect(
    rrect.deflate(0.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.35),
  );
}

/// The liquid in an upright tube. [wobble] tips the top surface, in pixels.
void paintUprightLiquid(
  Canvas canvas,
  Size size,
  int capacity,
  List<LiquidSegment> bands, {
  double wobble = 0,
  bool sealed = false,
}) {
  final w = size.width, h = size.height;
  final unit = h / capacity;
  canvas.save();
  canvas.clipRRect(tubeRRect(size));
  var bottomY = h;
  for (var i = 0; i < bands.length; i++) {
    final band = bands[i];
    final top = bottomY - unit * band.count;
    final rect = Rect.fromLTRB(0, top, w, bottomY);
    final paint = bandPaint(band.color, rect);
    if (sealed) paint.color = paint.color.withValues(alpha: 0.62);
    final isTop = i == bands.length - 1;
    if (isTop) {
      final surface = Path()
        ..moveTo(0, top - wobble)
        ..lineTo(w, top + wobble)
        ..lineTo(w, bottomY)
        ..lineTo(0, bottomY)
        ..close();
      canvas.drawPath(surface, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
    if (band.color == kMetallicGold) paintGoldGlint(canvas, rect);
    if (isTop) {
      canvas.drawLine(Offset(0, top - wobble + 1), Offset(w, top + wobble + 1), meniscusPaint(band.color));
    }
    bottomY = top;
  }
  canvas.restore();
}

/// What a tube draws while a pour is moving liquid through it. Repaints itself
/// off the pour's animation, so nothing else rebuilds per frame.
abstract class TubeLive implements Listenable {
  /// Units to add to the tube's contents as drawn.
  double get delta;
  Color get color;

  /// Top-surface tip in pixels.
  double get wobble;

  /// Reduce Motion only: 0..1 between the current contents and contents +
  /// [crossfadeUnits]. Null when not cross-fading.
  double? get crossfade;
  double get crossfadeUnits;
}

class TubePainter extends CustomPainter {
  final int capacity;
  final List<LiquidSegment> segments;
  final bool sealed;
  final TubeLive? live;

  TubePainter({required this.capacity, required this.segments, required this.sealed, this.live})
      : super(repaint: live);

  @override
  void paint(Canvas canvas, Size size) {
    paintGlassBack(canvas, size);
    final l = live;
    final fade = l?.crossfade;
    if (l != null && fade != null) {
      void layer(double alpha, List<LiquidSegment> bands) {
        canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: alpha));
        paintUprightLiquid(canvas, size, capacity, bands, sealed: sealed);
        canvas.restore();
      }

      layer(1 - fade, segments);
      layer(fade, adjustTop(segments, l.color, l.crossfadeUnits));
    } else {
      final bands = l == null ? segments : adjustTop(segments, l.color, l.delta);
      paintUprightLiquid(canvas, size, capacity, bands, wobble: l?.wobble ?? 0, sealed: sealed);
    }
    paintGlassFront(canvas, size);
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.sealed != sealed || oldDelegate.live != live;
}
