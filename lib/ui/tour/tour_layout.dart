import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../config/design.dart';
import '../manga/seeded_random.dart';

/// A hand-scribbled arrow: its tail, and its tip just off the spotlight.
class Scribble {
  const Scribble(this.tail, this.tip);
  final Offset tail, tip;

  Rect get bounds => Rect.fromPoints(tail, tip).inflate(TourStyle.scribbleMargin);
}

/// The marquee arrow: its centre, and the way it points (radians).
class Marquee {
  const Marquee(this.center, this.angle);
  final Offset center;
  final double angle;

  Rect get bounds => boundsAt(center, angle);

  /// The arrow's box turned by [angle] around [center].
  static Rect boundsAt(Offset center, double angle) {
    final c = math.cos(angle).abs(), s = math.sin(angle).abs();
    const l = TourStyle.marqueeLength, h = TourStyle.marqueeHeadHeight;
    return Rect.fromCenter(center: center, width: l * c + h * s, height: l * s + h * c);
  }
}

/// Where one tour stop puts its pieces on a screen of [size] with the
/// system's [safe] insets, around [spot] (null for a stop with no
/// spotlight): the spotlight [hole]; Tobi's [block] on the roomier side of
/// it; the [marquee] between them, or across or beside the spotlight when
/// there is no room; and the [scribbles] all around, clear of all three.
/// Pure, so it is the same for the same inputs (random picks come from
/// [seed]).
class TourLayout {
  const TourLayout._(this.hole, this.block, this.marquee, this.scribbles);

  factory TourLayout.of({required Size size, required EdgeInsets safe, Rect? spot, required int seed}) {
    final area = Rect.fromLTRB(
      safe.left + Gaps.gutter,
      safe.top + Gaps.gutter,
      size.width - safe.right - Gaps.gutter,
      size.height - safe.bottom - Gaps.gutter,
    );
    if (spot == null) {
      final h = math.min(TourStyle.blockTall, area.height);
      return TourLayout._(null, Rect.fromCenter(center: area.center, width: area.width, height: h), null, const []);
    }
    final hole = RRect.fromRectAndRadius(spot.inflate(TourStyle.spotPad), const Radius.circular(TourStyle.spotRadius));
    final h = hole.outerRect;
    const gap = TourStyle.gap;
    final above = h.top - area.top >= area.bottom - h.bottom;
    final room = above ? h.top - gap - area.top : area.bottom - h.bottom - gap;
    final stacked = room >= TourStyle.blockStacked + TourStyle.marqueeRoom + gap;
    final blockHeight =
        stacked ? TourStyle.blockStacked : room.clamp(TourStyle.blockMin, TourStyle.block).toDouble();
    final withMarquee = room >= blockHeight + TourStyle.marqueeRoom + gap;
    final reach = withMarquee ? TourStyle.marqueeRoom + gap : 0.0;
    final top = (above ? h.top - gap - reach - blockHeight : h.bottom + gap + reach)
        .clamp(area.top, math.max(area.top, area.bottom - blockHeight))
        .toDouble();
    final block = Rect.fromLTWH(area.left, top, area.width, blockHeight);

    final marquee = _placeMarquee(area, h, block, above: above, between: withMarquee);
    final scribbles = _scribbles(area, h, [block, if (marquee != null) marquee.bounds], SeededRandom(seed));
    return TourLayout._(hole, block, marquee, scribbles);
  }

  final RRect? hole;
  final Rect block;
  final Marquee? marquee;
  final List<Scribble> scribbles;

  /// Tries the band between the spotlight and the block, then the far
  /// side of the spotlight, then beside it; above or below, it sits off to
  /// one side and aims at the middle of the spotlight's near edge, so it
  /// comes in at a slant.
  static Marquee? _placeMarquee(Rect area, Rect h, Rect block, {required bool above, required bool between}) {
    const gap = TourStyle.gap;
    const band = TourStyle.marqueeRoom;
    const half = TourStyle.marqueeLength / 2;
    final toCentre = h.center.dx < area.center.dx ? 1.0 : -1.0;
    final x = h.center.dx + toCentre * TourStyle.marqueeShift;
    final (near, far) = above ? (h.top, h.bottom) : (h.bottom, h.top);
    final out = above ? -1.0 : 1.0;
    final candidates = [
      if (between) (Offset(x, near + out * (gap + band / 2)), Offset(h.center.dx, near)),
      (Offset(x, far - out * (gap + band / 2)), Offset(h.center.dx, far)),
      (Offset(h.left - gap - half, h.center.dy), Offset(h.left, h.center.dy)),
      (Offset(h.right + gap + half, h.center.dy), Offset(h.right, h.center.dy)),
    ];
    for (final (c, target) in candidates) {
      final center = Offset(c.dx.clamp(area.left + half, area.right - half), c.dy);
      final aim = target - center;
      final m = Marquee(center, math.atan2(aim.dy, aim.dx));
      final b = m.bounds;
      if (area.inflate(1).contains(b.topLeft) &&
          area.inflate(1).contains(b.bottomRight) &&
          !b.overlaps(block) &&
          !b.overlaps(h)) {
        return m;
      }
    }
    return null;
  }

  /// Arrows pointing in at the spotlight from all round it, in two rings,
  /// kept on screen and off [avoid] and each other.
  static List<Scribble> _scribbles(Rect area, Rect h, List<Rect> avoid, SeededRandom r) {
    final spots = <(Offset, Offset)>[
      for (final f in TourStyle.scribbleAlongTop) ...[
        (Offset(h.left + h.width * f, h.top), const Offset(0, -1)),
        (Offset(h.left + h.width * f, h.bottom), const Offset(0, 1)),
      ],
      for (final f in TourStyle.scribbleAlongSide) ...[
        (Offset(h.left, h.top + h.height * f), const Offset(-1, 0)),
        (Offset(h.right, h.top + h.height * f), const Offset(1, 0)),
      ],
      (h.topLeft, const Offset(-math.sqrt1_2, -math.sqrt1_2)),
      (h.topRight, const Offset(math.sqrt1_2, -math.sqrt1_2)),
      (h.bottomLeft, const Offset(-math.sqrt1_2, math.sqrt1_2)),
      (h.bottomRight, const Offset(math.sqrt1_2, math.sqrt1_2)),
    ];
    final candidates = <Scribble>[
      for (final gap in TourStyle.scribbleRings)
        for (final (at, normal) in spots) _scribbleAt(at, normal, gap, r),
    ];
    for (var i = candidates.length - 1; i > 0; i--) {
      final j = (r.next() * (i + 1)).floor();
      final t = candidates[i];
      candidates[i] = candidates[j];
      candidates[j] = t;
    }
    final kept = <Scribble>[];
    for (final c in candidates) {
      if (kept.length == TourStyle.scribbles) break;
      final b = c.bounds;
      final onScreen = area.contains(b.topLeft) && area.contains(b.bottomRight);
      final clear = !Rect.fromPoints(c.tail, c.tip).overlaps(h) &&
          avoid.every((a) => !b.overlaps(a)) &&
          kept.every((k) => !b.overlaps(k.bounds));
      if (onScreen && clear) kept.add(c);
    }
    return kept;
  }

  static Scribble _scribbleAt(Offset at, Offset normal, double gap, SeededRandom r) {
    final turn = (r.next() * 2 - 1) * TourStyle.scribbleTurnDeg * math.pi / 180;
    final out = Offset(
      normal.dx * math.cos(turn) - normal.dy * math.sin(turn),
      normal.dx * math.sin(turn) + normal.dy * math.cos(turn),
    );
    final length = TourStyle.scribbleMin + r.next() * (TourStyle.scribbleMax - TourStyle.scribbleMin);
    final tip = at + normal * gap;
    return Scribble(tip + out * length, tip);
  }
}
