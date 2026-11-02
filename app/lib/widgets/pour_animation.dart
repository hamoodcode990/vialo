import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tube_geometry.dart';
import 'tube_painter.dart';

/// The tilt-and-pour: the source travels to the target, tilts, a stream runs
/// while the source drains and the target rises in sync, then the target's
/// surface settles as the source returns.
///
/// One AnimationController per pour. Only this stage and the target tube
/// repaint per frame, off that controller; the screen rebuilds three times per
/// pour at most (start, commit, end).

/// Border width of a tube's glass, matching TubeView's Container.
const double kTubeBorder = 3;

/// The pour's fixed timings. Pure, so they can be tested without a widget.
class PourTimeline {
  static const double moveMs = 200;
  static const double tiltMs = 150;
  static const double unitMs = 110;
  static const double returnMs = 200;
  static const double wobbleMs = 250;
  static const double reduceMotionMs = 200;

  static const double startAngle = 60 * math.pi / 180;
  static const double endAngle = 80 * math.pi / 180;

  final int units;
  final bool reduceMotion;
  const PourTimeline(this.units, {this.reduceMotion = false});

  double get streamStart => reduceMotion ? 0 : moveMs + tiltMs;
  double get streamMs => reduceMotion ? reduceMotionMs : unitMs * units;
  double get streamEnd => streamStart + streamMs;
  double get total => reduceMotion ? streamEnd : streamEnd + math.max(returnMs, wobbleMs);

  /// Units moved so far.
  double moved(double ms) => ((ms - streamStart) / streamMs).clamp(0.0, 1.0) * units;

  /// 0 at the slot, 1 at the pour position.
  double travel(double ms) {
    if (ms >= streamEnd) {
      return 1 - Curves.easeInOutCubic.transform(((ms - streamEnd) / returnMs).clamp(0.0, 1.0));
    }
    return Curves.easeInOutCubic.transform((ms / moveMs).clamp(0.0, 1.0));
  }

  /// Tilt in radians. Keeps creeping up during the stream as the source drains.
  double angle(double ms) {
    if (ms >= streamEnd) {
      return endAngle * (1 - Curves.easeInOutCubic.transform(((ms - streamEnd) / returnMs).clamp(0.0, 1.0)));
    }
    if (ms >= streamStart) {
      return startAngle + (endAngle - startAngle) * ((ms - streamStart) / streamMs);
    }
    return startAngle * Curves.easeInOut.transform(((ms - moveMs) / tiltMs).clamp(0.0, 1.0));
  }

  /// Target surface tip in pixels: settles after the stream ends.
  double wobble(double ms, double tubeWidth) {
    if (ms < streamEnd) return 0;
    final t = ((ms - streamEnd) / wobbleMs).clamp(0.0, 1.0);
    return tubeWidth * 0.07 * (1 - t) * math.sin(t * math.pi * 4);
  }
}

/// One pour, as asked for by a game screen.
class PourSpec {
  final int source;
  final int target;
  final int units;
  final Color color;
  final List<LiquidSegment> sourceBefore;
  final int targetUnitsBefore;
  final bool lifted;
  final int capacity;
  final bool reduceMotion;
  final VoidCallback onStreamEnd;
  final void Function(int unit)? onUnit;

  const PourSpec({
    required this.source,
    required this.target,
    required this.units,
    required this.color,
    required this.sourceBefore,
    required this.targetUnitsBefore,
    required this.capacity,
    required this.onStreamEnd,
    this.lifted = false,
    this.reduceMotion = false,
    this.onUnit,
  });
}

/// A running pour.
class PourRun {
  final PourSpec spec;
  final AnimationController controller;
  final PourTimeline timeline;
  bool committed = false;
  int _unitsAnnounced = 0;

  PourRun(this.spec, this.controller) : timeline = PourTimeline(spec.units, reduceMotion: spec.reduceMotion);

  double get ms => controller.value * timeline.total;
  double get moved => timeline.moved(ms);
  bool touches(int tube) => tube == spec.source || tube == spec.target;
}

class _LiveTube implements TubeLive {
  final PourRun run;
  final bool isTarget;
  final double width;
  _LiveTube(this.run, this.isTarget, this.width);

  @override
  void addListener(VoidCallback listener) => run.controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => run.controller.removeListener(listener);

  @override
  Color get color => run.spec.color;

  @override
  double get delta {
    if (run.committed || run.spec.reduceMotion) return 0;
    return isTarget ? run.moved : 0;
  }

  @override
  double get wobble => isTarget && !run.spec.reduceMotion ? run.timeline.wobble(run.ms, width) : 0;

  @override
  double? get crossfade {
    if (!run.spec.reduceMotion || run.committed) return null;
    return (run.ms / run.timeline.total).clamp(0.0, 1.0);
  }

  @override
  double get crossfadeUnits => (isTarget ? 1 : -1) * run.spec.units.toDouble();
}

/// Owns the pours for one game screen.
class PourDirector {
  final TickerProvider vsync;

  /// Rebuild the board: a pour started, committed, or ended.
  final VoidCallback onChanged;

  /// The tube's slot in the stage's coordinates: the whole of its TubeView.
  final Rect? Function(int tube) slotRect;

  PourDirector({required this.vsync, required this.onChanged, required this.slotRect});

  final List<PourRun> runs = [];
  final List<PourSpec> _queued = [];
  final ValueNotifier<int> _stageVersion = ValueNotifier(0);
  final Map<(PourRun, bool), _LiveTube> _live = {};

  bool _touched(int tube) => runs.any((r) => r.touches(tube));

  /// Starts [spec], or starts it as soon as any pour still finishing with one
  /// of its tubes is done: the only time a pour has to wait, and at most the
  /// length of a return.
  void start(PourSpec spec) {
    if (_touched(spec.source) || _touched(spec.target)) {
      _queued.add(spec);
      return;
    }
    final timeline = PourTimeline(spec.units, reduceMotion: spec.reduceMotion);
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: timeline.total.round()),
    );
    final run = PourRun(spec, controller);
    runs.add(run);
    controller.addListener(() => _tick(run));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _end(run);
    });
    _stageVersion.value++;
    onChanged();
    controller.forward();
  }

  void _tick(PourRun run) {
    final moved = run.moved;
    while (run._unitsAnnounced < run.spec.units && moved >= run._unitsAnnounced) {
      run.spec.onUnit?.call(run._unitsAnnounced);
      run._unitsAnnounced++;
    }
    if (!run.committed && run.ms >= run.timeline.streamEnd) {
      run.committed = true;
      run.spec.onStreamEnd();
    }
  }

  void _end(PourRun run) {
    if (!run.committed) {
      run.committed = true;
      run.spec.onStreamEnd();
    }
    runs.remove(run);
    _live.removeWhere((k, _) => k.$1 == run);
    run.controller.dispose();
    _stageVersion.value++;
    onChanged();
    final waiting = List<PourSpec>.of(_queued);
    _queued.clear();
    waiting.forEach(start);
  }

  /// Drops every pour on the spot, without committing: the board they were
  /// moving is about to be replaced (restart, undo).
  void cancelAll() {
    _queued.clear();
    for (final r in runs) {
      r.controller.dispose();
    }
    runs.clear();
    _live.clear();
    _stageVersion.value++;
  }

  void dispose() {
    cancelAll();
    _stageVersion.dispose();
  }

  /// True while [tube]'s glass is being drawn by the stage instead of its slot.
  bool isLifted(int tube) => runs.any((r) => r.spec.source == tube && !r.spec.reduceMotion);

  TubeLive? live(int tube, double width) {
    for (final r in runs) {
      final isTarget = r.spec.target == tube;
      final isReducedSource = r.spec.source == tube && r.spec.reduceMotion;
      if (isTarget || isReducedSource) {
        return _live.putIfAbsent((r, isTarget), () => _LiveTube(r, isTarget, width));
      }
    }
    return null;
  }
}

/// Glass height for a tube [width] wide. TubeView's sizing.
double tubeGlassHeight(double width, int capacity) => (width * 1.05).clamp(20.0, double.infinity) * capacity;

/// Paints the moving source tubes and streams. Mount above the board, sized
/// to match it, under an IgnorePointer.
class PourStage extends StatelessWidget {
  final PourDirector director;
  const PourStage({super.key, required this.director});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: director._stageVersion,
      builder: (context, _, _) {
        final moving = director.runs.where((r) => !r.spec.reduceMotion).toList();
        if (moving.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) => RepaintBoundary(
            child: CustomPaint(
              size: constraints.biggest,
              painter: _StagePainter(moving, director.slotRect),
            ),
          ),
        );
      },
    );
  }
}

class _StagePainter extends CustomPainter {
  final List<PourRun> runs;
  final Rect? Function(int) slotRect;

  _StagePainter(this.runs, this.slotRect) : super(repaint: Listenable.merge([for (final r in runs) r.controller]));

  @override
  void paint(Canvas canvas, Size size) {
    for (final run in runs) {
      final from = slotRect(run.spec.source);
      final to = slotRect(run.spec.target);
      if (from == null || to == null) continue;
      _paintRun(canvas, size, run, from, to);
    }
  }

  void _paintRun(Canvas canvas, Size stage, PourRun run, Rect fromSlot, Rect toSlot) {
    final spec = run.spec;
    final t = run.timeline;
    final ms = run.ms;
    final w = fromSlot.width;
    final h = tubeGlassHeight(w, spec.capacity);
    final inner = Size(w - kTubeBorder * 2, h - kTubeBorder * 2);

    final side = pourSide(fromSlot, toSlot, h, stage.width);
    // Pivot at the lip nearest the target; the body swings away from it.
    final lipLocal = Offset(side < 0 ? w : 0, 0);
    final angle = t.angle(ms) * (side < 0 ? 1 : -1);

    final liftPx = spec.lifted && ms < PourTimeline.moveMs ? 0.14 * (h + 19) : 0.0;
    final homeLip = fromSlot.topLeft + lipLocal - Offset(0, liftPx * (1 - t.travel(ms)));
    final toCentreX = toSlot.left + toSlot.width / 2;
    final pourLip = Offset(toCentreX + side * toSlot.width * 0.3, toSlot.top - 10);

    final travel = t.travel(ms);
    final arcLift = math.sin(travel * math.pi) * h * 0.12;
    final lip = Offset.lerp(homeLip, pourLip, travel)! - Offset(0, arcLift);

    final drained = run.committed ? spec.units.toDouble() : run.moved;
    final bands = adjustTop(spec.sourceBefore, spec.color, -drained);

    // Stream first, so the source's mouth sits over its start.
    if (ms >= t.streamStart && ms <= t.streamEnd) {
      _paintStream(canvas, run, lip, toSlot, inner, spec.capacity);
    }
    _paintTiltedTube(canvas, lip, lipLocal, angle, inner, spec.capacity, bands, spec, ms >= t.streamStart && ms < t.streamEnd);
  }

  void _paintTiltedTube(
    Canvas canvas,
    Offset lip,
    Offset lipLocal,
    double angle,
    Size inner,
    int capacity,
    List<LiquidSegment> bands,
    PourSpec spec,
    bool pouring,
  ) {
    // Glass (rotated), in tube-local coordinates with the border as its origin.
    void inTubeSpace(void Function() paint) {
      canvas.save();
      canvas.translate(lip.dx, lip.dy);
      canvas.rotate(angle);
      canvas.translate(-lipLocal.dx + kTubeBorder, -lipLocal.dy + kTubeBorder);
      paint();
      canvas.restore();
    }

    inTubeSpace(() => paintGlassBack(canvas, inner));

    // Liquid (world-aligned): surfaces stay horizontal, each band clipped to
    // the rotated tube.
    final upright = tubeOutline(inner);
    Offset toWorld(Offset local) =>
        rotateAbout(local + const Offset(kTubeBorder, kTubeBorder), lipLocal, angle, lip);
    final rotated = [for (final p in upright) toWorld(p)];
    final surfaces = solveBandSurfaces(
      uprightPoly: upright,
      rotatedPoly: rotated,
      size: inner,
      capacity: capacity,
      bandUnits: [for (final b in bands) b.count],
    );

    final clip = Path()..addPolygon(rotated, true);
    var left = rotated.first.dx, right = rotated.first.dx, bottom = rotated.first.dy;
    for (final p in rotated) {
      left = math.min(left, p.dx);
      right = math.max(right, p.dx);
      bottom = math.max(bottom, p.dy);
    }
    canvas.save();
    canvas.clipPath(clip);
    var below = bottom;
    for (var i = 0; i < bands.length; i++) {
      final rect = Rect.fromLTRB(left, surfaces[i], right, below);
      canvas.drawRect(rect, bandPaint(bands[i].color, rect));
      if (i == bands.length - 1) {
        canvas.drawLine(Offset(left, surfaces[i] + 1), Offset(right, surfaces[i] + 1), meniscusPaint(bands[i].color));
      }
      below = surfaces[i];
    }
    canvas.restore();

    // When the pool sits below the lip, a thin film runs along the low wall so
    // the liquid visibly reaches the mouth.
    if (pouring && bands.isNotEmpty) {
      final surface = surfaces.last;
      final lipWorld = toWorld(Offset(lipLocal.dx == 0 ? 0 : inner.width, 0));
      if (surface > lipWorld.dy) {
        final wall = lipLocal.dx == 0 ? 0.0 : inner.width;
        final far = toWorld(Offset(wall, inner.height));
        final reach = ((surface - lipWorld.dy) / (far.dy - lipWorld.dy)).clamp(0.0, 1.0);
        final end = Offset.lerp(lipWorld, far, reach)!;
        canvas.save();
        canvas.clipPath(clip);
        canvas.drawLine(
          lipWorld,
          end,
          Paint()
            ..color = spec.color
            ..strokeWidth = inner.width * 0.3
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      }
    }

    inTubeSpace(() {
      paintGlassFront(canvas, inner);
      canvas.drawRRect(
        tubeRRect(inner).inflate(kTubeBorder / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kTubeBorder
          ..color = kTubeEdgeColor,
      );
    });
  }

  void _paintStream(Canvas canvas, PourRun run, Offset lip, Rect toSlot, Size inner, int capacity) {
    final spec = run.spec;
    final t = run.timeline;
    final ms = run.ms;
    final unit = inner.height / capacity;
    final h = tubeGlassHeight(toSlot.width, capacity);
    // The target's liquid surface, as drawn right now.
    final surfaceY = toSlot.top + h - kTubeBorder - (spec.targetUnitsBefore + run.moved) * unit;
    final end = Offset(toSlot.left + toSlot.width / 2, surfaceY);

    // The stream's ends arrive and leave rather than appearing whole.
    const edgeMs = 45.0;
    final head = ((ms - t.streamStart) / edgeMs).clamp(0.0, 1.0);
    final tail = ((ms - (t.streamEnd - edgeMs)) / edgeMs).clamp(0.0, 1.0);

    final wobble = math.sin(ms / 28) * toSlot.width * 0.025;
    final control = Offset(end.dx + wobble, lip.dy + (end.dy - lip.dy) * 0.25);
    Offset at(double p) {
      final a = Offset.lerp(lip, control, p)!;
      final b = Offset.lerp(control, end, p)!;
      return Offset.lerp(a, b, p)!;
    }

    const steps = 14;
    final path = Path();
    var moved = false;
    for (var i = 0; i <= steps; i++) {
      final p = tail + (head - tail) * (i / steps);
      final q = at(p);
      if (!moved) {
        path.moveTo(q.dx, q.dy);
        moved = true;
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = toSlot.width * 0.17
        ..color = spec.color,
    );
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) => true;
}

/// Which side of the target the source pours from: -1 left, 1 right. Keeps the
/// source's own side when the swung-out tube fits on screen there.
int pourSide(Rect from, Rect to, double glassHeight, double stageWidth) {
  final toCentre = to.left + to.width / 2;
  final preferred = from.left + from.width / 2 <= toCentre ? -1 : 1;
  bool fits(int side) {
    final reach = glassHeight * math.sin(PourTimeline.endAngle) + to.width * 0.5;
    return side < 0 ? toCentre - reach >= 0 : toCentre + reach <= stageWidth;
  }

  if (fits(preferred)) return preferred;
  if (fits(-preferred)) return -preferred;
  // Neither fits fully: the side with more room.
  return toCentre >= stageWidth - toCentre ? -1 : 1;
}
