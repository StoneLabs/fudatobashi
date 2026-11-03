import 'dart:math' as math;

/// A point or a direction on the 一騎打ち board, in dp, y down.
class Vec {
  const Vec(this.x, this.y);

  static const zero = Vec(0, 0);

  final double x, y;

  Vec operator +(Vec o) => Vec(x + o.x, y + o.y);
  Vec operator -(Vec o) => Vec(x - o.x, y - o.y);
  Vec operator *(double s) => Vec(x * s, y * s);
  Vec operator -() => Vec(-x, -y);

  double dot(Vec o) => x * o.x + y * o.y;
  double cross(Vec o) => x * o.y - y * o.x;
  double get length => math.sqrt(x * x + y * y);

  /// This direction at length 1; the zero vector stays zero.
  Vec get unit {
    final l = length;
    return l == 0 ? this : Vec(x / l, y / l);
  }

  /// Turned a quarter turn (clockwise on screen).
  Vec get perp => Vec(-y, x);

  Vec lerp(Vec to, double t) => Vec(x + (to.x - x) * t, y + (to.y - y) * t);

  Vec rotated(double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return Vec(x * c - y * s, x * s + y * c);
  }

  double distanceTo(Vec o) => (o - this).length;

  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// A card lying on the board: its [centre], half its width and height
/// ([hw], [hh]) and the [angle] it is turned by.
class CardBox {
  const CardBox(this.centre, this.hw, this.hh, [this.angle = 0]);

  final Vec centre;
  final double hw, hh, angle;

  /// The card's own axes across and down it.
  (Vec, Vec) get axes {
    final c = math.cos(angle), s = math.sin(angle);
    return (Vec(c, s), Vec(-s, c));
  }

  /// How far the card reaches from its centre along the unit [dir].
  double reachAlong(Vec dir) {
    final (u, v) = axes;
    return dir.dot(u).abs() * hw + dir.dot(v).abs() * hh;
  }

  /// The point of the card nearest [p]: [p] itself when inside.
  Vec closestTo(Vec p) {
    final (u, v) = axes;
    final d = p - centre;
    final lu = d.dot(u).clamp(-hw, hw), lv = d.dot(v).clamp(-hh, hh);
    return centre + u * lu + v * lv;
  }

  /// How far [p] is from the card: 0 inside it.
  double gapTo(Vec p) => closestTo(p).distanceTo(p);

  /// The card's four corners.
  List<Vec> get corners {
    final (u, v) = axes;
    return [
      for (final (sx, sy) in const [(1, 1), (-1, 1), (-1, -1), (1, -1)]) centre + u * (hw * sx) + v * (hh * sy),
    ];
  }

  CardBox movedTo(Vec centre, double angle) => CardBox(centre, hw, hh, angle);

  /// On the way from this box to [to] at [t]: its centre, size and the
  /// shortest turn between their angles.
  CardBox lerp(CardBox to, double t) => CardBox(
        centre.lerp(to.centre, t),
        hw + (to.hw - hw) * t,
        hh + (to.hh - hh) * t,
        angle + turnBetween(angle, to.angle) * t,
      );

  /// Whether any part of the card lies inside the upright rectangle from
  /// ([left], [top]) to ([right], [bottom]): they are not apart along any
  /// of the rectangle's or the card's axes.
  bool overlapsArea(double left, double top, double right, double bottom) {
    final (u, v) = axes;
    final xReach = u.x.abs() * hw + v.x.abs() * hh, yReach = u.y.abs() * hw + v.y.abs() * hh;
    if (centre.x + xReach <= left || centre.x - xReach >= right) return false;
    if (centre.y + yReach <= top || centre.y - yReach >= bottom) return false;
    final area = [Vec(left, top), Vec(right, top), Vec(right, bottom), Vec(left, bottom)];
    for (final (axis, reach) in [(u, hw), (v, hh)]) {
      final along = [for (final p in area) (p - centre).dot(axis)];
      if (along.reduce(math.min) >= reach || along.reduce(math.max) <= -reach) return false;
    }
    return true;
  }
}

/// How far [p] is from the nearest of [cards]: 0 inside one, infinity with none.
double gapToCards(Iterable<CardBox> cards, Vec p) {
  var best = double.infinity;
  for (final c in cards) {
    best = math.min(best, c.gapTo(p));
  }
  return best;
}

/// [dir] at length 1 with any part against [keep] (a unit vector) taken
/// out, and the share of it left; straight against [keep], it turns square
/// to it.
({Vec dir, double share}) notAgainst(Vec dir, Vec keep) {
  final d = dir.unit;
  final against = d.dot(keep);
  final kept = against < 0 ? d - keep * against : d;
  final share = kept.length;
  return (dir: share > 1e-3 ? kept * (1 / share) : keep.perp, share: share);
}

/// The shortest turn from angle [from] to [to], radians: within ±π.
double turnBetween(double from, double to) {
  final turn = (to - from) % (2 * math.pi);
  return turn > math.pi ? turn - 2 * math.pi : turn;
}

/// The quadratic Bézier from [a] by [q] to [b] at [t].
Vec bezier(Vec a, Vec q, Vec b, double t) {
  final u = 1 - t;
  return a * (u * u) + q * (2 * u * t) + b * (t * t);
}
