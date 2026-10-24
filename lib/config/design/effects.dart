part of '../design.dart';

/// A balloon popping out of a tapped control (`BalloonPop`, e.g. "coming
/// soon"): its default size, the gap to the control (the tail bridges it),
/// how long it stays by default, and how it pops in and fades.
abstract final class BalloonPopStyle {
  static const Size size = Size(150, 64);
  static const double gap = 12;

  /// With Tobi saying it: Tobi's height, the gap to the balloon, and where
  /// the tail points (at Tobi, left of the balloon).
  static const double tobi = 74;
  static const double tobiGap = 2;
  static const Alignment tobiSpeaker = Alignment(-1.3, 0.45);
  static const Duration life = Duration(milliseconds: 1600);
  static const Duration fade = Duration(milliseconds: 260);
  static const pop = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 320), curve: Entrances.springy);
}

/// Sky and hero backgrounds: radial and linear gradients (CSS angles, degrees).
abstract final class Backdrops {
  static const skyCenter = Alignment(-0.46, 0.24);
  static const skyColors = [Color(0xFFFFFBE6), Color(0xFFFFF1A8), Palette.sun];
  static const skyStops = [0.0, 0.38, 1.0];

  /// The pace question: the sky, lit from its lower right.
  static const paceSkyCenter = Alignment(0.7, 0.6);

  /// The relaxed pace: calm sea blues, sea dots rising toward Tobi's feet.
  static const relaxedCenter = Alignment(0, -0.45);
  static const relaxedColors = [Palette.paper, Palette.seaSoft, Palette.shallow];
  static const relaxedStops = [0.0, 0.42, 1.0];
  static const double relaxedToneAngle = 180;
  static const relaxedToneStops = [0.3, 0.75];

  /// The sprint pace: hot pink, glowing around Tobi.
  static const sprintCenter = Alignment(0, -0.19);
  static const sprintColors = [Palette.pinkSoft, Palette.pink, Palette.pinkDeep];
  static const sprintStops = [0.0, 0.5, 1.0];

  static const heroCenter = Alignment(0.6, -0.64);
  static const heroColors = [Palette.paper, Color(0xFFFFF6CC), Color(0xFFFFE36B)];
  static const heroStops = [0.0, 0.4, 1.0];

  /// The pink hero tone fades in toward the bottom left.
  static const double heroToneAngle = 198;
  static const heroToneStops = [0.46, 0.9];

  static const double freePlayAngle = 100;
  static const freePlayStops = [0.52, 1.0];
  static const nigateStops = [0.7, 1.0];

  /// A half-white mist over the top of the journey map.
  static const double mapFogHeight = 74;
  static const mapFogStops = [0.0, 0.38, 1.0];
  static const mapFogAlpha = [0.5, 0.46, 0.0];
}

/// A focus-line burst: [count] wedges converging on [center] (a point in a
/// box of [box] size; it scales with the actual box), starting between
/// [innerMin] and [innerMax] from it. A wedge whose middle would cross
/// [clear] (in the same box) is left out, keeping lettering there free.
@immutable
class BurstSpec {
  const BurstSpec({
    required this.box,
    required this.center,
    required this.count,
    required this.innerMin,
    required this.innerMax,
    required this.width,
    required this.seed,
    this.color = Palette.ink,
    this.clear,
  });

  final Size box;
  final Offset center;
  final int count;
  final double innerMin, innerMax, width;
  final int seed;
  final Color color;
  final Rect? clear;

  /// The same burst drawn with other random lines.
  BurstSpec reseeded(int offset) => BurstSpec(
      box: box,
      center: center,
      count: count,
      innerMin: innerMin,
      innerMax: innerMax,
      width: width,
      seed: seed + offset,
      color: color,
      clear: clear);

  @override
  bool operator ==(Object other) =>
      other is BurstSpec &&
      other.box == box &&
      other.center == center &&
      other.count == count &&
      other.innerMin == innerMin &&
      other.innerMax == innerMax &&
      other.width == width &&
      other.seed == seed &&
      other.color == color &&
      other.clear == clear;

  @override
  int get hashCode => Object.hash(box, center, count, innerMin, innerMax, width, seed, color, clear);
}

/// A band of horizontal speed lines. Streaks float freely; [fromEdge] lines
/// all start at the right edge and taper off to the left.
@immutable
class SpeedLinesSpec {
  const SpeedLinesSpec({required this.count, required this.seed, this.fromEdge = false, this.color = Palette.ink});
  final int count;
  final int seed;
  final bool fromEdge;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is SpeedLinesSpec &&
      other.count == count &&
      other.seed == seed &&
      other.fromEdge == fromEdge &&
      other.color == color;

  @override
  int get hashCode => Object.hash(count, seed, fromEdge, color);
}

/// Focus-line bursts of the spec's panels.
abstract final class Bursts {
  static const onboarding =
      BurstSpec(box: Size(358, 344), center: Offset(92, 206), count: 120, innerMin: 76, innerMax: 110, width: 3, seed: 7);
  static const journeyHero =
      BurstSpec(box: Size(358, 206), center: Offset(300, 40), count: 120, innerMin: 56, innerMax: 86, width: 3.2, seed: 3);
  static const hero =
      BurstSpec(box: Size(358, 318), center: Offset(290, 62), count: 130, innerMin: 66, innerMax: 96, width: 3.4, seed: 3);
  static const sprint =
      BurstSpec(box: Size(170, 540), center: Offset(85, 220), count: 64, innerMin: 64, innerMax: 84, width: 2.8, seed: 5);
}

/// A CSS-style `from` keyframe: the state an element enters from before
/// settling at rest. Opacity reaches 1 at [opaqueAt] of the eased progress.
@immutable
class EntranceFrom {
  const EntranceFrom({this.opacity = 0, this.scale = 1, this.turnDeg = 0, this.offset = Offset.zero, this.opaqueAt = 1});
  final double opacity, scale, turnDeg;
  final Offset offset;
  final double opaqueAt;
}

/// One element's entrance on a celebration's timeline: [from] to rest over
/// [duration], starting [delay] after the page appears.
@immutable
class EntranceSpec {
  const EntranceSpec(this.from, {required this.duration, this.delay = Duration.zero, this.curve = Curves.ease});
  final EntranceFrom from;
  final Duration duration, delay;
  final Curve curve;

  Duration get end => delay + duration;
}

/// The spec's entrance keyframes and easing curves (`@keyframes` in
/// final.html).
abstract final class Entrances {
  static const flin = EntranceFrom(scale: 1.35);
  static const flash = EntranceFrom(scale: 0.4);
  static const slam = EntranceFrom(scale: 1.9, turnDeg: -7);
  static const slideL = EntranceFrom(offset: Offset(-60, 0));
  static const pop = EntranceFrom(scale: 0.4);
  static const up = EntranceFrom(offset: Offset(0, 22));
  static const isrise = EntranceFrom(scale: 0.15, opaqueAt: 0.3);
  static const thump = EntranceFrom(scale: 2.4, opaqueAt: 0.3);
  static const stamp = EntranceFrom(scale: 2.6, turnDeg: -14, opaqueAt: 0.3);

  /// For an `EntranceBuilder`, which draws its own motion from the progress.
  static const custom = EntranceFrom(opacity: 1);

  static const settle = Cubic(0.2, 0.8, 0.2, 1);
  static const springy = Cubic(0.2, 1.5, 0.4, 1);
  static const bouncy = Cubic(0.2, 1.6, 0.4, 1);
  static const lift = Cubic(0.15, 0.9, 0.25, 1.12);
  static const glide = Cubic(0.2, 0.9, 0.3, 1);
  static const swell = Cubic(0.2, 1.4, 0.4, 1);
}

/// The confetti rain on the island-complete page (`ConfettiRain`), in the
/// spec's px.
abstract final class Confetti {
  static const int count = 30;
  static const int seed = 77;
  static const List<Color> colors = [
    Palette.pink,
    Palette.sun,
    Palette.land,
    Palette.paper,
    Palette.sea,
    Color(0xFFFF9A2E),
  ];

  /// Pieces are scattered across this width and scaled to the actual one.
  static const double specWidth = 390;
  static const double fall = 600;
  static const double drift = 90;
  static const double stroke = 2;

  /// Seconds.
  static const double minDuration = 2.2, durationRange = 1.8;
  static const double maxDelay = 2.4;
  static const double minTurns = 1, turnsRange = 1.5;
  static const Size minSize = Size(9, 12);
  static const Size sizeRange = Size(7, 8);

  /// Every this-many pieces is round.
  static const int roundEvery = 3;
}

/// One looping firework: bursting at [center] (in the 390 × 844 spec box)
/// in [color], first after [delay] and then every [period] seconds.
@immutable
class FireworkSpec {
  const FireworkSpec(this.center, this.color, {required this.delay, required this.period, this.seed = 0});
  final Offset center;
  final Color color;
  final double delay, period;
  final int seed;
}

/// The fireworks over the graduation page (`Fireworks`), in the spec's px.
abstract final class FireworksStyle {
  static const List<FireworkSpec> bursts = [
    FireworkSpec(Offset(72, 200), Palette.pink, delay: 0.2, period: 2.1, seed: 1),
    FireworkSpec(Offset(322, 190), Palette.sun, delay: 0.55, period: 2.3, seed: 2),
    FireworkSpec(Offset(40, 470), Palette.land, delay: 0.9, period: 2.2, seed: 3),
    FireworkSpec(Offset(352, 450), Palette.paper, delay: 1.25, period: 2.5, seed: 4),
    FireworkSpec(Offset(196, 60), Palette.sea, delay: 1.6, period: 2.4, seed: 5),
    FireworkSpec(Offset(200, 580), Color(0xFFFF9A2E), delay: 1.95, period: 2.2, seed: 6),
  ];
  static const double specWidth = 390;
  static const double specHeight = 844;
  static const int sparks = 18;

  /// How far a spark's direction strays from even spacing, in shares of
  /// the gap between two.
  static const double jitter = 0.5;
  static const double minRadius = 70, radiusRange = 34;

  /// Seconds a burst lasts.
  static const double life = 1.5;

  /// How far the sparks droop by the end, px.
  static const double droop = 46;

  /// Each spark is a streak this share of its distance long, ending in a dot.
  static const double streak = 0.28;
  static const double streakWidth = 3.5;
  static const double dot = 3.8;

  /// Share of its size a spark's dot has lost by the end.
  static const double dotShrink = 0.5;
  static const double outline = 1.5;

  /// The flash at a burst's heart, over this share of its life.
  static const double flashShare = 0.18;
  static const double flashSize = 30;

  /// Opacity holds until this share of the life, then fades out.
  static const double fadeFrom = 0.6;

  /// Under reduced motion every burst hangs still at this share of its life.
  static const double stillAt = 0.45;
}

/// [curve] advancing in [count] whole steps, like CSS `steps(count, end)`:
/// the stop-motion of manga entrances.
class StepCurve extends Curve {
  const StepCurve(this.count, [this.curve = Curves.linear]);
  final int count;
  final Curve curve;

  @override
  double transformInternal(double t) => curve.transform((t * count).floor() / count);
}
