import 'dart:math' as math;
import 'dart:ui';

/// Geometry for a tilted tube: liquid surfaces stay horizontal while the tube
/// rotates, so each colour band's surface height is solved from its volume.
///
/// The tube is treated as a polygon. "Below y" means screen-down, the larger
/// y values, which is where liquid settles.

/// The tube outline, in tube-local coordinates, as a polygon.
List<Offset> tubeOutline(Size size) {
  final w = size.width, h = size.height;
  final top = w * 0.16, bottom = w * 0.4;
  final points = <Offset>[];
  void arc(double cx, double cy, double r, double start) {
    const steps = 8;
    for (var i = 0; i <= steps; i++) {
      final a = start + (math.pi / 2) * (i / steps);
      points.add(Offset(cx + r * math.cos(a), cy + r * math.sin(a)));
    }
  }

  arc(top, top, top, math.pi); // top-left
  arc(w - top, top, top, -math.pi / 2); // top-right
  arc(w - bottom, h - bottom, bottom, 0); // bottom-right
  arc(bottom, h - bottom, bottom, math.pi / 2); // bottom-left
  return points;
}

double polygonArea(List<Offset> p) {
  var a = 0.0;
  for (var i = 0; i < p.length; i++) {
    final q = p[(i + 1) % p.length];
    a += p[i].dx * q.dy - q.dx * p[i].dy;
  }
  return a.abs() / 2;
}

/// The area of [poly] at or below the horizontal line at [y].
double areaBelow(List<Offset> poly, double y) {
  final out = <Offset>[];
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i], b = poly[(i + 1) % poly.length];
    final aIn = a.dy >= y, bIn = b.dy >= y;
    if (aIn) out.add(a);
    if (aIn != bIn) {
      final t = (y - a.dy) / (b.dy - a.dy);
      out.add(Offset(a.dx + (b.dx - a.dx) * t, y));
    }
  }
  return out.length < 3 ? 0 : polygonArea(out);
}

/// Solves for the y where the area below it equals [area].
double surfaceForArea(List<Offset> poly, double area) {
  var top = poly.first.dy, bottom = poly.first.dy;
  for (final p in poly) {
    top = math.min(top, p.dy);
    bottom = math.max(bottom, p.dy);
  }
  var lo = top, hi = bottom;
  for (var i = 0; i < 18; i++) {
    final mid = (lo + hi) / 2;
    if (areaBelow(poly, mid) > area) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// The volume of [units] of liquid: exactly what that many units occupy with
/// the tube upright, so nothing changes size as it tilts.
double volumeOfUnits(List<Offset> uprightPoly, Size size, int capacity, double units) {
  return areaBelow(uprightPoly, size.height - units * size.height / capacity);
}

/// The surface y of each band in a rotated tube, bottom band first.
/// [bandUnits] are the bands' sizes in units, bottom-up.
List<double> solveBandSurfaces({
  required List<Offset> uprightPoly,
  required List<Offset> rotatedPoly,
  required Size size,
  required int capacity,
  required List<double> bandUnits,
}) {
  final out = <double>[];
  var units = 0.0;
  for (final u in bandUnits) {
    units += u;
    out.add(surfaceForArea(rotatedPoly, volumeOfUnits(uprightPoly, size, capacity, units)));
  }
  return out;
}

/// Rotates [p] by [angle] about [pivot], then moves [pivot] to [to].
Offset rotateAbout(Offset p, Offset pivot, double angle, Offset to) {
  final d = p - pivot;
  final c = math.cos(angle), s = math.sin(angle);
  return Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c) + to;
}
