import 'dart:math' as math;
import 'dart:ui';

/// Polygon helpers for panels.
abstract final class Polygon {
  static Path path(List<Offset> points) => Path()..addPolygon(points, true);

  /// Moves every edge of a convex polygon [t] inward along its normal and
  /// returns the new corners (the border's inner edge).
  static List<Offset> inset(List<Offset> p, double t) {
    final n = p.length;
    var c = Offset.zero;
    for (final v in p) {
      c += v;
    }
    c /= n.toDouble();
    final lines = <(Offset, Offset)>[];
    for (var i = 0; i < n; i++) {
      final a = p[i], b = p[(i + 1) % n];
      final d = b - a;
      var normal = Offset(-d.dy, d.dx) / d.distance;
      if ((c - a).dx * normal.dx + (c - a).dy * normal.dy < 0) normal = -normal;
      lines.add((a + normal * t, d));
    }
    final out = <Offset>[];
    for (var i = 0; i < n; i++) {
      final (pa, da) = lines[(i - 1 + n) % n];
      final (pb, db) = lines[i];
      final den = da.dx * db.dy - da.dy * db.dx;
      if (den.abs() < 1e-9) {
        out.add(pb);
        continue;
      }
      final s = ((pb.dx - pa.dx) * db.dy - (pb.dy - pa.dy) * db.dx) / den;
      out.add(pa + da * s);
    }
    return out;
  }
}

/// Dashed copies of paths, cached per source path and pattern.
abstract final class Dashes {
  static final _cache = Expando<Map<String, Path>>();

  static Path of(Path source, List<double> pattern) {
    final byPattern = _cache[source] ??= {};
    return byPattern[pattern.join(',')] ??= _dash(source, pattern);
  }

  static Path _dash(Path source, List<double> pattern) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      var i = 0;
      var draw = true;
      while (d < metric.length) {
        final len = pattern[i % pattern.length];
        if (draw) out.addPath(metric.extractPath(d, math.min(d + len, metric.length)), Offset.zero);
        d += len;
        i++;
        draw = !draw;
      }
    }
    return out;
  }
}

/// CSS gradient geometry.
abstract final class CssGradient {
  /// Start and end of a CSS `linear-gradient(<deg>)` across [rect].
  static (Offset, Offset) linear(Rect rect, double degrees) {
    final a = degrees * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final half = (rect.width * math.sin(a).abs() + rect.height * math.cos(a).abs()) / 2;
    return (rect.center - dir * half, rect.center + dir * half);
  }

  /// Radius of a CSS `radial-gradient(circle at …)` (farthest corner).
  static double farthestCorner(Rect rect, Offset center) => [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ].map((c) => (c - center).distance).reduce(math.max);
}
