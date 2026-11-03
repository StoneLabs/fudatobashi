import 'dart:math' as math;

/// How a curve reads between two anchors: in a straight line, or straight
/// on a log scale, where each equal step in rating multiplies the value by
/// the same factor.
enum CurveScale { plain, log }

/// One of Tobi's values by rating (一騎打ち): [anchors] (rating, value) in
/// rising rating, read between them on its [scale] and held flat past the
/// first and the last. A log curve's values are all above 0.
class IkkiuchiCurve {
  const IkkiuchiCurve(this.anchors) : scale = CurveScale.plain;
  const IkkiuchiCurve.log(this.anchors) : scale = CurveScale.log;

  final List<(double, double)> anchors;
  final CurveScale scale;

  /// The value at [rating]; an anchor's rating gives its value exactly.
  double at(double rating) {
    final (firstRating, firstValue) = anchors.first;
    if (rating <= firstRating) return firstValue;
    for (var i = 1; i < anchors.length; i++) {
      final (r1, v1) = anchors[i];
      if (rating > r1) continue;
      if (rating == r1) return v1;
      final (r0, v0) = anchors[i - 1];
      final t = (rating - r0) / (r1 - r0);
      return switch (scale) {
        CurveScale.plain => v0 + t * (v1 - v0),
        CurveScale.log => math.exp(math.log(v0) + t * (math.log(v1) - math.log(v0))),
      };
    }
    return anchors.last.$2;
  }
}
