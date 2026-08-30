import 'package:flutter/material.dart';

import 'tube_painter.dart' show shade;

/// Flying-droplet pour animation, ported from decant.html's `animPour`
/// (CLAUDE.md Step 5): behaviour, not literal HTML/CSS — arc trajectory
/// (rise straight-line to just above the target with a stretch, then a
/// short bounced drop with a squash), a splash ring on landing, and
/// staggered multi-drop pours. Runs on a single [AnimationController] and
/// repaints only itself via [CustomPaint]'s `repaint` listenable — no
/// parent setState per frame, so the board underneath never rebuilds
/// during the flight.
///
/// Usage: mount one of these (via a [GlobalKey]) as an [IgnorePointer]
/// layer above the tube board, sized to match it, then call [playPour]
/// with the source/destination tube rects (in the same coordinate space
/// as this widget) each time a pour move starts. [onDone] fires once the
/// last drop lands — that's when the caller should actually mutate game
/// state, mirroring the HTML original's "animate, then commit" ordering.
class PourFlightOverlay extends StatefulWidget {
  const PourFlightOverlay({super.key});

  @override
  State<PourFlightOverlay> createState() => PourFlightOverlayState();
}

class PourFlightOverlayState extends State<PourFlightOverlay>
    with SingleTickerProviderStateMixin {
  static const _stagger = 72;
  static const int _flight =
      475; // _PourFlightPainter.rise + .land, kept as an int for Duration math

  AnimationController? _ctrl;
  Rect _from = Rect.zero;
  Rect _to = Rect.zero;
  Color _color = Colors.transparent;
  int _count = 1;

  /// Starts a pour flight of [count] staggered drops from [from] to [to].
  /// [onDone] fires once, when the last drop lands (not when its splash
  /// ring finishes fading — that's purely cosmetic and outlives it).
  void playPour({
    required Rect from,
    required Rect to,
    required Color color,
    required int count,
    required VoidCallback onDone,
  }) {
    _ctrl?.dispose();
    final commitMs = (count - 1) * _stagger + _flight;
    final totalMs =
        commitMs +
        _PourFlightPainter.splashLife
            .round(); // let the last splash fade before clearing
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    var committed = false;
    ctrl.addListener(() {
      if (!committed && ctrl.value * totalMs >= commitMs) {
        committed = true;
        onDone();
      }
    });
    setState(() {
      _ctrl = ctrl;
      _from = from;
      _to = to;
      _color = color;
      _count = count;
    });
    ctrl.forward().whenCompleteOrCancel(() {
      if (mounted) setState(() => _ctrl = null);
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _PourFlightPainter(
        controller: ctrl,
        from: _from,
        to: _to,
        color: _color,
        count: _count,
      ),
    );
  }
}

class _PourFlightPainter extends CustomPainter {
  static const double rise = 300;
  static const double land = 175;
  static const double splashLife = 450;

  final Animation<double> controller;
  final Rect from;
  final Rect to;
  final Color color;
  final int count;

  _PourFlightPainter({
    required this.controller,
    required this.from,
    required this.to,
    required this.color,
    required this.count,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final totalMs = (controller as AnimationController).duration!.inMilliseconds
        .toDouble();
    final tMs = controller.value * totalMs;

    final w = from.width * 0.3 < 7 ? 7.0 : from.width * 0.3;
    final dropH = w * 1.25;
    final sx = from.center.dx - w / 2;
    final sy = from.top + 4;
    final ex = to.center.dx - w / 2;
    final ey = to.top + 8;

    final dark = shade(color, -24);

    for (var i = 0; i < count; i++) {
      final localMs = tMs - i * PourFlightOverlayState._stagger;
      if (localMs < 0) continue;

      if (localMs <= rise) {
        final t = Curves.easeOutCubic.transform(
          (localMs / rise).clamp(0.0, 1.0),
        );
        final dx = sx + (ex - sx) * t;
        final dy = sy + ((ey - 34) - sy) * t;
        _drawDrop(canvas, Offset(dx, dy), w, dropH, 1.0 + 0.3 * t, color, dark);
      } else if (localMs <= rise + land) {
        final t = Curves.easeOutBack.transform(
          ((localMs - rise) / land).clamp(0.0, 1.0),
        );
        final dy0 = ey - 34;
        final dy = dy0 + (ey - dy0) * t;
        _drawDrop(
          canvas,
          Offset(ex, dy),
          w,
          dropH,
          1.3 + (0.8 - 1.3) * t,
          color,
          dark,
        );
      }

      final splashElapsed = localMs - (rise + land);
      if (splashElapsed >= 0 && splashElapsed <= splashLife) {
        final st = splashElapsed / splashLife;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - st) * 0.8);
        canvas.drawCircle(Offset(ex + w / 2, ey), w * (0.9 + 0.5 * st), paint);
      }
    }
  }

  void _drawDrop(
    Canvas canvas,
    Offset topLeft,
    double w,
    double h,
    double scaleY,
    Color top,
    Color bottom,
  ) {
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, w, h * scaleY);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w / 2));
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PourFlightPainter oldDelegate) => true;
}
