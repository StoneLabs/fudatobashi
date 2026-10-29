part of '../design.dart';

/// One picture of a scene: its asset (a lossless 3× render) and where it
/// sits, in the scene's design units (the picture's pixel size ÷ 3).
@immutable
class ScenePiece {
  const ScenePiece(this.asset, this.rect);
  final String asset;
  final Rect rect;
}

/// The dojo scene at the top of the Side Trips tab (`DojoScene`,
/// `research/design/sidetrips_b2.html`): pictures from
/// `assets/graphics/sidetrips/scene/`, back to front, in a design frame [width]
/// units wide whose top is the screen's top, scaled to the screen's width.
/// The islands stand in a ring (`DojoRingLayout`).
abstract final class DojoSceneLayout {
  static const double width = 390;
  static const _dir = 'assets/graphics/sidetrips/scene';

  static const sky = ScenePiece('$_dir/sky.webp', Rect.fromLTWH(0, 0, 390, 200));

  /// The smiling sun peeking out in the top right corner, behind the
  /// clouds: its rays, and its face with eyes open or shut ([sunBlink]),
  /// all centred on the sun. Like the clouds, it keeps its place when the
  /// scene lifts.
  static const sunRays = ScenePiece('$_dir/sun-rays.webp', Rect.fromLTWH(284, -14, 128, 128));
  static const sunFace = ScenePiece('$_dir/sun-face.webp', Rect.fromLTWH(308, 10, 80, 80));
  static const sunBlink = ScenePiece('$_dir/sun-face-blink.webp', Rect.fromLTWH(308, 10, 80, 80));

  /// The sun bobs [sunLift] units and rocks [sunTurnDeg] either way once per
  /// [sunPeriod]; its rays turn round once per [sunRayTurn] and swell by up
  /// to [sunRayPulse] of their size once per [sunRayPulsePeriod]; it shuts
  /// its eyes for [sunBlinkFor] at the end of every [sunBlinkEvery]. All
  /// still under reduced motion, redrawn every [sunStep].
  static const double sunLift = 2;
  static const double sunTurnDeg = 3;
  static const sunPeriod = Duration(milliseconds: 6400);
  static const sunRayTurn = Duration(seconds: 80);
  static const double sunRayPulse = 0.05;
  static const sunRayPulsePeriod = Duration(milliseconds: 4200);
  static const sunBlinkEvery = Duration(milliseconds: 5300);
  static const sunBlinkFor = Duration(milliseconds: 160);
  static const sunStep = Duration(milliseconds: 40);

  /// The clouds, drifting right across the sky and round again: each
  /// crosses the frame and its own width [DriftingPiece.laps] times per
  /// [cloudLoop]. They keep their place when the scene lifts.
  static const clouds = [
    DriftingPiece(ScenePiece('$_dir/cloud-small.webp', Rect.fromLTWH(184, 39, 58, 24)), laps: 2),
    DriftingPiece(ScenePiece('$_dir/cloud-large.webp', Rect.fromLTWH(276, 61, 95, 40)), laps: 1),
  ];
  static const cloudLoop = Duration(minutes: 6);
  static const cloudStep = Duration(milliseconds: 50);

  static const sea = ScenePiece('$_dir/sea.webp', Rect.fromLTWH(0, 200, 390, 644));
  static const toriiLocked = ScenePiece('$_dir/torii-locked.webp', Rect.fromLTWH(280, 338, 104, 140));
  static const toriiOpen = ScenePiece('$_dir/torii-open.webp', Rect.fromLTWH(280, 338, 104, 140));
  static const boat = ScenePiece('$_dir/tobi-boat.webp', Rect.fromLTWH(114, 374, 124, 110));

  /// The near swell that carries each island's entry, at its own top
  /// left: the front of the sea's paper layers. Its crest line runs no
  /// deeper than [crest] below its top, and sits [crestGap] dp above the
  /// entry. Below the picture, its plain halftone [fill] (a whole number of
  /// dot rows) repeats.
  static const seaNear = ScenePiece('$_dir/wave-1.webp', Rect.fromLTWH(0, 0, 390, 320));
  static const double crest = 60;
  static const double crestGap = 2;
  static const Rect fill = Rect.fromLTWH(0, 170, 390, 150);

  /// The paper layers behind the near swell, back to front, sharing its
  /// box; Tobi's boat sails between them and the swell. Each repeats
  /// across the frame, slides [WaveLayer.speed] times as far as the swell
  /// when the ring turns, and bobs [WaveLayer.bob] units once per
  /// [WaveLayer.period] (still under reduced motion), redrawn every
  /// [waveStep].
  static const backWaves = [
    WaveLayer(ScenePiece('$_dir/wave-4.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.25, bob: 0.8, period: Duration(milliseconds: 7300)),
    WaveLayer(ScenePiece('$_dir/wave-3.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.45, bob: 1, period: Duration(milliseconds: 5900)),
    WaveLayer(ScenePiece('$_dir/wave-2.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.7, bob: 1.2, period: Duration(milliseconds: 4700)),
  ];
  static const waveStep = Duration(milliseconds: 40);

  /// The bottom of the boat's hull, and how far below the swell's top its
  /// crest line runs under the hull. A screen too short to show the hull
  /// above the swell lifts the scene by up to [maxLift]; beyond that the
  /// swell rises over the boat.
  static const double foreground = 474;
  static const double hullTrough = 50;
  static const double maxLift = 60;

  /// The least of the scene kept above the entry; a screen too short for
  /// it and the entry scrolls.
  static const double minHeight = 360;

  /// The torii and Tobi's boat bob (and the boat rocks) once per period.
  static const double toriiLift = 2;
  static const toriiPeriod = Duration(milliseconds: 5200);
  static const double boatLift = 3;
  static const double boatTurnDeg = 1.5;
  static const boatPeriod = Duration(milliseconds: 3800);
}

/// One of the sea's paper layers behind the near swell
/// ([DojoSceneLayout.backWaves]): its [piece], how far it slides for the
/// swell's every unit ([speed]), and its gentle [bob] up and down, in
/// units, once per [period].
@immutable
class WaveLayer {
  const WaveLayer(this.piece, {required this.speed, required this.bob, required this.period});
  final ScenePiece piece;
  final double speed, bob;
  final Duration period;
}

/// A picture that drifts sideways across the scene and round again, [laps]
/// times per loop.
@immutable
class DriftingPiece {
  const DriftingPiece(this.piece, {required this.laps});
  final ScenePiece piece;
  final int laps;
}

/// Where an island stands in one slot of the ring ([DojoRingLayout]): its
/// canvas's [DojoRingLayout.foot] at [foot] on the scene, at [scale]; in
/// colour or blue [haze] (0–1); its label shown by [label] (0–1), a "coming
/// soon" tag pinned by its [tagAlign] point to [tag] on the canvas; and its
/// [depth], the deepest painted first.
@immutable
class RingSlotSpec {
  const RingSlotSpec({
    required this.foot,
    required this.scale,
    required this.haze,
    required this.label,
    required this.tag,
    required this.tagAlign,
    required this.depth,
  });
  final Offset foot, tag;
  final double scale, haze, label, depth;
  final Alignment tagAlign;

  static RingSlotSpec lerp(RingSlotSpec a, RingSlotSpec b, double t) => RingSlotSpec(
        foot: Offset.lerp(a.foot, b.foot, t)!,
        scale: lerpDouble(a.scale, b.scale, t)!,
        haze: lerpDouble(a.haze, b.haze, t)!,
        label: lerpDouble(a.label, b.label, t)!,
        tag: Offset.lerp(a.tag, b.tag, t)!,
        tagAlign: Alignment.lerp(a.tagAlign, b.tagAlign, t)!,
        depth: lerpDouble(a.depth, b.depth, t)!,
      );
}

/// One arm of the ring's track beyond the screen's left edge, run along
/// from a slot (at 0) to [exit] (at 1), out of sight: the island's foot
/// on the curve from the slot's toward [bend] and on to [exit]'s; the rest
/// part of the way between the slot's and [exit]'s.
@immutable
class RingArmSpec {
  const RingArmSpec({required this.exit, required this.bend});
  final RingSlotSpec exit;
  final Offset bend;

  /// [t] of the way along the arm from [slot].
  RingSlotSpec at(RingSlotSpec slot, double t) {
    final spec = RingSlotSpec.lerp(slot, exit, t);
    final u = 1 - t;
    final foot = slot.foot * (u * u) + bend * (2 * u * t) + exit.foot * (t * t);
    return RingSlotSpec(
      foot: foot,
      scale: spec.scale,
      haze: spec.haze,
      label: spec.label,
      tag: spec.tag,
      tagAlign: spec.tagAlign,
      depth: spec.depth,
    );
  }
}

/// One island of the ring: its picture in [colour] and the same drawing in
/// blue [haze], both 3× renders filling the island canvas. Unlike the
/// scene's pictures they are lossy, as hand-painted texture runs large
/// lossless.
@immutable
class RingIsleArt {
  const RingIsleArt(this.colour, this.haze);
  final String colour, haze;
}

/// The ring of islands on the dojo scene (`SideTripRing`). Every island is
/// drawn on one [canvas] (units as the scene's) and stands on its
/// waterline at [foot]; each slot of the ring ([slots], one per island, in
/// `SideTripRing`'s order: the front, the right, round the back from right
/// to left, the left) puts it somewhere on the scene. An island between
/// two slots is part of the way between the two. In front its tag hangs in
/// the water under its left end; elsewhere it floats over the island,
/// clear of the one in front.
///
/// The track is a parabola opening to the left, its tip near the right
/// slot: its [near] arm runs on from the front and its [far] arm from the
/// left slot, both past the screen's left edge. An island between the
/// front and the left slot shows on both at once, the same share of the
/// way out along one as in along the other: leaving the front past the
/// viewer, growing a little, as its blue twin comes into the left slot.
abstract final class DojoRingLayout {
  static const _dir = 'assets/graphics/sidetrips/islands';
  static const Size canvas = Size(370, 226);
  static const Offset foot = Offset(185, 213);

  static const slots = [
    RingSlotSpec(
        foot: Offset(169, 397), scale: 1, haze: 0, label: 1, tag: _under, tagAlign: Alignment.topLeft, depth: 3),
    RingSlotSpec(
        foot: Offset(334, 248), scale: 0.36, haze: 0, label: 1, tag: _over, tagAlign: Alignment.bottomCenter, depth: 2),
    RingSlotSpec(
        foot: Offset(242, 204), scale: 0.25, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 0.5),
    RingSlotSpec(
        foot: Offset(131, 201), scale: 0.21, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 0),
    RingSlotSpec(
        foot: Offset(30, 201), scale: 0.16, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 1),
  ];
  static const _under = Offset(36, 231);
  static const _over = Offset(185, -4);

  static const near = RingArmSpec(
    exit: RingSlotSpec(
        foot: Offset(-212, 422), scale: 1.12, haze: 0, label: 0, tag: _under, tagAlign: Alignment.topLeft, depth: 4),
    bend: Offset(-21.5, 422),
  );
  static const far = RingArmSpec(
    exit: RingSlotSpec(
        foot: Offset(-28, 199), scale: 0.12, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 1),
    bend: Offset(1, 200),
  );

  static const ankiren = RingIsleArt('$_dir/ankiren.webp', '$_dir/ankiren-haze.webp');
  static const storehouse = RingIsleArt('$_dir/storehouse.webp', '$_dir/storehouse-haze.webp');
  static const hall = RingIsleArt('$_dir/hall.webp', '$_dir/hall-haze.webp');
  static const rocks = RingIsleArt('$_dir/rocks.webp', '$_dir/rocks-haze.webp');
  static const fort = RingIsleArt('$_dir/fort.webp', '$_dir/fort-haze.webp');

  /// 暗記練's banner on its island's grass, once it is open: its label.
  static const nobori = ScenePiece('assets/graphics/sidetrips/ankiren/nobori.webp', Rect.fromLTWH(238, 73, 30, 100));
}

/// How the ring of islands turns (`SideTripsScreen`).
abstract final class DojoRingMotion {
  /// The settle onto a step, from wherever the swipe let go: critically
  /// damped, so it clicks into place.
  static const settle = SpringDescription(mass: 1, stiffness: 420, damping: 41);

  /// Under reduced motion the islands and entries crossfade instead.
  static const crossfade = Duration(milliseconds: 220);

  /// How far Tobi's boat drifts with a whole step, in scene units, and the
  /// spring that brings it back once the ring stops.
  static const double boatDrift = 16;
  static const boatReturn = SpringDescription(mass: 1, stiffness: 55, damping: 8);
}

/// The tab's title lettering over the sky, and the scene's "coming soon"
/// tags (`DojoScene`). In dp, not scaled with the scene.
abstract final class DojoSceneStyle {
  /// The title's top left corner, below the status bar.
  static const Offset title = Offset(16, 6);
  static const double titleFont = 42;
  static const double titleOutline = 10;

  /// Clear sky kept between the title lettering and the sun.
  static const double titleSunGap = 6;
  static const double titleBannerFont = 11;
  static const double titleBannerGap = 6;

  static const double tagFont = 11;
  static const double tagLineHeight = 1.2;
  static const double tagBorder = 1.8;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
  static const double chipFont = 9.5;
  static const double chipTracking = 0.08;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double chipGap = 4;
}

/// The unlock moment, once, when 暗記練 first opens on the hub: the
/// padlocked torii rattles, snaps at [snapAt] of [unlock], and gives way to
/// the open one popping in while the banner rises.
abstract final class DojoUnlockMotion {
  static const unlock = Duration(milliseconds: 1100);
  static const double snapAt = 0.45;
  static const double rattle = 3;
  static const double rattleHz = 14;

  /// The torii's swell at the swap, a share of its size.
  static const double pop = 0.14;

  /// How far the banner rises into place, in scene units.
  static const double banner = 24;
}

/// The Side Trips tab's entry for 暗記練 under the dojo scene
/// (`research/design/sidetrips_c.html`): its lettering and rank stamp
/// breaking out over the panel's top; the rating and next game and the
/// burst to the trip's page, or while it is locked the cards still to
/// remember and under them the rules.
abstract final class SideTripsLayout {
  /// The entry never grows wider than this (a landscape screen).
  static const double maxWidth = 480;

  /// Left between the entry and the tab bar.
  static const double bottomGap = 12;

  /// Display lettering (the tab's title, the trip's name, the scene's tags)
  /// grows with the system text size only up to this factor.
  static const double letteringMaxScale = 1.1;

  /// How far the lettering and stamp hang over the panel's top.
  static const double overlap = 13;
  static const double headInset = 6;
  static const double letteringFont = 37;
  static const double letteringOutline = 10;
  static const double letteringGap = 8;
  static const double letteringDrop = 4;
  static const double bannerFont = 11;

  /// The rank stamp pressed on the panel's top right corner: tilted clockwise
  /// (degrees), its class lettered big with 級 small inside a double rule,
  /// lifted [stampLift] off the head's foot so it stays off the panel's rows,
  /// and hanging [stampHang] out past the panel's right edge.
  static const double stampTilt = 10;
  static const double stampFont = 18;
  static const double stampSuffixFont = 13;

  /// The widest the stamp's lettering grows: a longer English class name
  /// scales down to fit.
  static const double stampMaxWidth = 54;
  static const double stampGap = 2;
  static const EdgeInsets stampPadding = EdgeInsets.symmetric(horizontal: 7, vertical: 4);
  static const double stampLift = 4;
  static const double stampHang = 8;

  /// How far the panel's top-left corner is cut down.
  static const double cut = 12;

  /// The rows inside the panel: a label (with its other-language sub) over
  /// a value, side by side when there are two, split by a rule.
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(14, 4, 6, 4);
  static const double rowMinHeight = 56;
  static const double lockedRowMinHeight = 50;
  static const double rowGap = 12;
  static const double ruleWidth = 2;
  static const double ruleInset = 8;
  static const int ratingFlex = 5;
  static const int nextFlex = 6;
  static const double labelFont = 12;
  static const double labelLineHeight = 1.2;
  static const double subFont = 11;
  static const double subTracking = 0.14;
  static const double labelGap = 3;
  static const double valueFont = 22;
  static const double unrankedFont = 20;
  static const double valueGap = 6;
  static const double factsFont = 13.5;
  static const double factsNumber = 15;

  /// The next game's cards and time, on their own line under its level.
  static const double noteGap = 3;

  /// The last game's rating change: ▲ on ink, ▼ on paper.
  static const double deltaFont = 12.5;
  static const EdgeInsets deltaPadding = EdgeInsets.fromLTRB(4, 3, 5, 4);

  /// The ranked burst (`burst.svg`): one fixed piece, scaled down only to
  /// fit a narrow panel; its label in the art's safe box.
  static const Size burst = Size(344, 64);
  static const Rect burstLabel = Rect.fromLTRB(34, 17, 310, 47);
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(0, 6, 0, 8);
  static const double burstFont = 21;
  static const double burstSubFont = 11;
  static const double burstSubTracking = 0.12;
  static const double burstGap = 8;
  static const double burstIcon = 22;
  static const double burstIconStroke = 3.2;

  /// While locked: the cards to remember as rows of pips, then a grey bar
  /// where the burst will be.
  static const EdgeInsets pipsPadding = EdgeInsets.fromLTRB(14, 2, 14, 0);
  static const int pipsPerRow = 25;
  static const double pipGap = 3;
  static const double pipRowGap = 3;

  /// Narrow pips keep a card's shape.
  static const double pipAspect = 1.45;
  static const double lockTop = 8;
  static const double lockMinHeight = 60;
  static const EdgeInsets lockPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);
  static const double lockIcon = 24;
  static const double lockIconStroke = 2.6;
  static const double lockGap = 10;
  static const double lockTitleFont = 18;
  static const double lockLineFont = 12;
  static const double lockLineNumber = 14;

  /// Between the pair of buttons on the trip's page.
  static const double pairGap = Gaps.panelWide;

  static const Size lockBalloon = Size(270, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);

  /// An island still being built: smaller lettering over a small panel
  /// that says so.
  static const double soonLetteringFont = 30;
  static const EdgeInsets soonPadding = EdgeInsets.fromLTRB(14, 4, 14, 12);
  static const double soonTitleFont = 16;
  static const double soonLineFont = 13;
  static const double soonLineGap = 3;
}
