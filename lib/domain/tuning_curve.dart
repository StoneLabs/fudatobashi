import 'dart:math' as math;

/// How a curve is smoothed between its points: on the plain values, or on
/// their logs, where each equal step in x multiplies the value by the same
/// factor.
enum CurveScale { plain, log }

/// A value by x: [anchors] (x, y) in rising x, joined by a smooth curve
/// that passes through each point and never overshoots (monotone cubic,
/// Fritsch-Carlson), and held flat past the first and the last. A log
/// curve's values are all above 0.
class TuningCurve {
  const TuningCurve(this.anchors) : scale = CurveScale.plain;
  const TuningCurve.log(this.anchors) : scale = CurveScale.log;

  final List<(double, double)> anchors;
  final CurveScale scale;

  // Slopes are worked out on first use; const instances are shared, so each
  // curve gets them once.
  static final _slopes = Expando<List<double>>();

  double _y(double v) => scale == CurveScale.log ? math.log(v) : v;

  /// The value at [x]; a point's x gives its y exactly.
  double at(double x) {
    if (x <= anchors.first.$1) return anchors.first.$2;
    for (var i = 1; i < anchors.length; i++) {
      final (x1, v1) = anchors[i];
      if (x > x1) continue;
      if (x == x1) return v1;
      final (x0, v0) = anchors[i - 1];
      final slopes = _slopes[this] ??= _fritschCarlson();
      final h = x1 - x0, t = (x - x0) / h;
      final (y0, y1) = (_y(v0), _y(v1));
      final t2 = t * t, t3 = t2 * t;
      final y = (2 * t3 - 3 * t2 + 1) * y0 +
          (t3 - 2 * t2 + t) * h * slopes[i - 1] +
          (-2 * t3 + 3 * t2) * y1 +
          (t3 - t2) * h * slopes[i];
      return scale == CurveScale.log ? math.exp(y) : y;
    }
    return anchors.last.$2;
  }

  /// The slope at each point, as SciPy's PchipInterpolator: a plateau or a
  /// turn gets 0, otherwise a weighted harmonic mean of the two sides.
  List<double> _fritschCarlson() {
    final n = anchors.length;
    final h = [for (var i = 1; i < n; i++) anchors[i].$1 - anchors[i - 1].$1];
    final d = [for (var i = 1; i < n; i++) (_y(anchors[i].$2) - _y(anchors[i - 1].$2)) / h[i - 1]];
    if (n == 2) return [d[0], d[0]];
    final m = List<double>.filled(n, 0);
    for (var i = 1; i < n - 1; i++) {
      if (d[i - 1] * d[i] <= 0) continue;
      final w1 = 2 * h[i] + h[i - 1], w2 = h[i] + 2 * h[i - 1];
      m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i]);
    }
    m[0] = _end(h[0], h[1], d[0], d[1]);
    m[n - 1] = _end(h[n - 2], h[n - 3], d[n - 2], d[n - 3]);
    return m;
  }

  // The three-point end slope, kept from reversing or overshooting.
  static double _end(double h0, double h1, double d0, double d1) {
    final s = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1);
    if (s * d0 <= 0) return 0;
    if (d0 * d1 <= 0 && s.abs() > 3 * d0.abs()) return 3 * d0;
    return s;
  }
}
