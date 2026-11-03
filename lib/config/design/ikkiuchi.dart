part of '../design.dart';

/// The 一騎打ち board (`IkkiuchiBoardLayout`, `IkkiuchiBoardPainter`): the
/// field on the tatami, folded in portrait and true scale in landscape,
/// the band across the middle, and Tobi at the far side. dp.
abstract final class IkkiuchiBoardStyle {
  /// Kept clear inside the board's edges, and under the field in portrait.
  static const double pad = 6;
  static const double bottomGap = 16;

  /// The band between the sides: its height, just enough for the called
  /// card's kimariji and a note under it; the ink rules along it, its fill,
  /// and the kimariji.
  static const double band = 40;
  static const double bandRule = 3;
  static const Color bandFill = Palette.paper;
  static const Color bandRuleColor = Palette.ink;
  static const double kimariji = 20;
  static const Color kimarijiColor = Palette.ink;

  /// A note under the kimariji (the developer's readout), [noteGap] below.
  static const double noteFont = 10;
  static const double noteGap = 2;
  static const Color noteColor = Palette.mute;
  static const String noteEllipsis = '…';

  /// A からふだ's kimariji, and the tag in front of it, [karafudaGap] apart.
  static const Color karafudaColor = Palette.inkShadow;
  static const double karafudaTag = 10;
  static const String karafudaGap = '  ';

  /// A card is never wider than [maxCardW].
  static const double maxCardW = 80;

  /// Portrait: Tobi stands [tobiFeetGap] above his side, [tobiHeight] tall
  /// at most, with at least [tobiMinRoom] kept above the field for him and
  /// [tobiTopRoom] above his head. Landscape: he sits in the open middle of
  /// his half, [tobiShare] of its height, [tobiTop] under its top.
  static const double tobiHeight = 170;
  static const double tobiMinRoom = 150;
  static const double tobiFeetGap = 4;
  static const double tobiTopRoom = 24;
  static const double tobiShare = 0.8;
  static const double tobiTop = 2;

  /// The tatami behind the field: a seamless tile drawn for [tatamiScale]×
  /// density, on [ground] until it loads.
  static const String tatami = 'assets/graphics/sidetrips/play/tatami.webp';
  static const double tatamiScale = 3;
  static const Color ground = Palette.desk;

  /// The board shakes [shakeReach] for [shakeMs] after a hit.
  static const double shakeMs = 140;
  static const double shakeReach = 3.5;
  static const double shakeRateX = 0.9;
  static const double shakeRateY = 1.3;

  /// Speed lines behind a card sliding faster than [streakMinSpeed] dp/s:
  /// as long as its speed times [streakPerSpeed], at most [streakMax],
  /// inked fully [streakFullOver] dp/s over the least. Each line is
  /// (across the card as a share of its reach, length share, width).
  static const double streakMinSpeed = 700;
  static const double streakMax = 90;
  static const double streakPerSpeed = 0.035;
  static const double streakFullOver = 900;
  static const double streakBack = 4;
  static const List<(double, double, double)> streaks = [(-0.85, 1, 2.2), (0, 0.7, 1.6), (0.85, 0.9, 2.2), (0.45, 0.5, 1.2)];

  /// The お手つき stamp on a faulted card: [stampLift] above it, turned
  /// [stampTurn], popping in from [stampPop] over [stampPopMs].
  static const String stamp = 'お手つき';
  static const Color stampFill = Palette.alarm;
  static const Color stampInk = Palette.paper;
  static const Color stampBorder = Palette.ink;
  static const double stampBorderWidth = 2;
  static const double stampFont = 12;
  static const double stampHeight = 20;
  static const double stampPadding = 6;
  static const double stampLift = 6;
  static const double stampTurn = -0.1;
  static const double stampPop = 1.6;
  static const double stampPopMs = 120;
}

/// Tobi's arm in a strike (`IkkiuchiArmPainter`): one ink line in his pen
/// from his shoulder to a white fist, and its effects. Lengths are in
/// Tobi units (k dp each) where they say so, else dp.
abstract final class IkkiuchiArmStyle {
  static const Color ink = Palette.ink;
  static const Color fistFill = Palette.paper;

  /// His pen, Tobi units. An arm [restLength] Tobi units long keeps it; a
  /// longer one thins by (rest / length) ^ [thinPower], within
  /// [thinMin]..[thinMax].
  static const double pen = 3;
  static const double restLength = 22;
  static const double thinPower = 0.22;
  static const double thinMin = 0.62;
  static const double thinMax = 1.1;

  /// The fist's outline as a share of the pen; it stretches along its way
  /// by its speed over [fistStretchSpeed] dp/s, at most [fistStretchMax],
  /// narrowing by [fistNarrow] of that.
  static const double fistPen = 0.9;
  static const double fistStretchSpeed = 4000;
  static const double fistStretchMax = 0.6;
  static const double fistNarrow = 0.6;

  /// Wind lines: tapered ink streaks tracing the fist's last [windWindow]
  /// ms in [windSamples] points, shown from [windMinSpeed] and fully inked
  /// at [windFullSpeed] dp/ms; [windOffsets] fist radii off the path,
  /// [windWidths] dp at their widest, the third line [windCut] points
  /// shorter. Points [armWindUs] along the arm leave sweep lines over
  /// [armWindow] ms, [armWindWidth] wide, once they moved [armWindMin] dp.
  static const double windWindow = 120;
  static const int windSamples = 14;
  static const double windMinSpeed = 0.9;
  static const double windFullSpeed = 2.6;
  static const double windOnAfter = 30;
  static const List<double> windOffsets = [-2, 2, 3.8];
  static const List<double> windWidths = [2.2, 2.2, 1.5];
  static const int windCut = 4;
  static const double windTaper = 0.9;
  static const List<double> armWindUs = [0.55, 0.78];
  static const double armWindow = 80;
  static const int armWindSamples = 10;
  static const int armWindShown = 8;
  static const double armWindWidth = 1.5;
  static const double armWindMin = 30;
  static const double armWindInk = 0.85;

  /// The row sweep's wind runs along the card's edges instead, [sweepGap]
  /// and [sweepGapOuter] dp off them, over [sweepWindow] ms.
  static const double sweepGap = 5;
  static const double sweepGapOuter = 11;
  static const List<double> sweepWidths = [2, 2, 1.3];
  static const double sweepWindow = 150;

  /// The smear swing's afterimages: a faint swoosh between the arm now and
  /// [smearBack] ms ago, and ghost arms (ms back, ink).
  static const double smearBack = 46;
  static const double smearSwoosh = 0.16;
  static const List<(double, double)> smearGhosts = [(16, 0.5), (30, 0.32), (44, 0.18)];

  /// The hit: a paper flash for [flashMs] (big [flashBigMs]), its radius
  /// [flashShare] of the burst ([flashBigShare] big), growing by [flashGrow];
  /// a burst of focus lines [burst] across per dp of size, from
  /// [burstFrom] to [burstTo] its size as it fades over its life.
  static const double lifeMs = 340;
  static const double lifeBigMs = 460;
  static const double flashMs = 70;
  static const double flashBigMs = 110;
  static const double flashShare = 0.5;
  static const double flashBigShare = 0.75;
  static const double flashGrow = 0.7;
  static const double flashStroke = 2;
  static const double burstFrom = 0.7;
  static const double burstTo = 1.3;
  static const double burstFade = 0.45;

  /// Burst sizes: a take, the smear's big one, and the sweep's clean one.
  static const double sizeSmall = 30;
  static const double sizeBig = 44;
  static const double sizeClean = 24;

  /// The focus lines of each burst, in a box twice its size.
  static const BurstSpec burstSmall =
      BurstSpec(box: Size(60, 60), center: Offset(30, 30), count: 13, innerMin: 12, innerMax: 18, width: 3, seed: 11);
  static const BurstSpec burstBig =
      BurstSpec(box: Size(88, 88), center: Offset(44, 44), count: 18, innerMin: 18, innerMax: 26, width: 4, seed: 13);
  static const BurstSpec burstClean =
      BurstSpec(box: Size(48, 48), center: Offset(24, 24), count: 8, innerMin: 10, innerMax: 14, width: 2, seed: 17);

  /// The lettering at the hit: the take's バシッ and the sweep's シュッ,
  /// [sfxSize] (big [sfxBigSize]), set off [sfxOut] dp outward and
  /// [sfxUp] dp up, turned [sfxTurn]; it pops from [sfxPop] over [sfxPopMs]
  /// and fades over the last [sfxFade] of the life.
  static const String sfx = 'バシッ';
  static const String sfxSweep = 'シュッ';
  static const Color sfxColor = Palette.ink;
  static const double sfxSize = 28;
  static const double sfxBigSize = 34;
  static const double sfxOut = 34;
  static const double sfxAcross = 6;
  static const double sfxUp = 30;
  static const double sfxTurn = -0.2;
  static const double sfxPop = 1.5;
  static const double sfxPopMs = 90;
  static const double sfxFade = 0.3;
}
