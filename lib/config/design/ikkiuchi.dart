part of '../design.dart';

/// The 一騎打ち board (`IkkiuchiBoardLayout`, `IkkiuchiBoardPainter`): the
/// field on the tatami, its cards as big as the board lets them grow, the
/// band across the middle, and Tobi at the far side. dp.
abstract final class IkkiuchiBoardStyle {
  /// Kept clear inside the board's left and right edges, and in portrait
  /// above it and under the field too.
  static const double pad = 6;
  static const double bottomGap = 16;

  /// The band between the sides: its height, just enough for the called
  /// card's kimariji and a note under it; the ink rules along it, its fill,
  /// and the kimariji.
  static const double band = 40;
  static const double bandRule = 3;

  /// In landscape there is no band: the sides lie [landscapeGap] apart, half
  /// of [band].
  static const double landscapeGap = band / 2;
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

  /// A card marked on the board: an outline [markWidth] wide in
  /// [markColor], [markGap] outside its edge, its corners rounded
  /// [markRadius]; in [takenMarkColor] once the player took it. A card the
  /// player faulted on (お手つき) gets one in [faultMarkColor].
  static const Color markColor = Palette.pink;
  static const Color takenMarkColor = Palette.land;
  static const Color faultMarkColor = Palette.alarm;
  static const double markWidth = 3;
  static const double markGap = 1;
  static const double markRadius = 3;

  /// Portrait: Tobi stands [tobiFeetGap] above his side, [tobiHeight] tall
  /// at most, with at least [tobiMinRoom] kept above the field for him and
  /// [tobiTopRoom] above his head. Landscape: he sits in the open middle of
  /// his half, [tobiShare] of its height, [tobiTop] under its top, his cards
  /// at least [tobiSideRoom] card widths from him on each side.
  static const double tobiHeight = 170;
  static const double tobiMinRoom = 150;
  static const double tobiFeetGap = 4;
  static const double tobiTopRoom = 24;
  static const double tobiShare = 0.7;
  static const double tobiTop = 0;
  static const double tobiSideRoom = 0.1;

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

  /// Speed lines behind a card sliding faster than [streakMinSpeed] card
  /// widths a second: as long as its speed times [streakPerSpeed] seconds,
  /// at most [streakMax] card widths, inked fully [streakFullOver] card
  /// widths a second over the least. Each line is (across the card as a
  /// share of its reach, length share, width).
  static const double streakMinSpeed = 19.5;
  static const double streakMax = 2.5;
  static const double streakPerSpeed = 0.035;
  static const double streakFullOver = 25;
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

/// 送り札 in a match (`IkkiuchiSendFlow`, `IkkiuchiSendLayer`): the card
/// Tobi sends waits for the player as a big stack of one, tagged; the
/// player lays it out with the placing's look ([look]) and drags a card of
/// theirs onto Tobi's side, one spot, to send it. dp.
abstract final class IkkiuchiSendStyle {
  /// The waiting card, never smaller than the field's cards. In portrait at
  /// most `maxHeight` tall and `tobiShare` of Tobi's height, or `scale`
  /// field cards wide where that is bigger, `margin` clear of what is
  /// around it. In landscape at most `scale` field cards wide, `gap` clear
  /// of the field and the board's halves: in the room right of the field
  /// where that room takes one at least `leastScale` field cards wide, else
  /// over Tobi's side.
  static const wait = (maxHeight: 150.0, tobiShare: 0.78, margin: 12.0, scale: 1.8, leastScale: 1.4, gap: 6.0);

  /// Tobi's side, which takes a card the player sends anywhere on it, as
  /// one spot reaching [sideOutset] past the edges of his half.
  static const double sideOutset = 4;

  /// The placing's look.
  static const look = PlacingLook(
    spotInk: Color(0xEEFFFFFF),
    spotFill: Color(0x14FFFFFF),
    spotBorder: Strokes.label,
    middleLabelFont: 10,
    middleLabelTracking: 0.16,
    middleLabelRoom: 60,
    landingFill: Color(0x99FFD53D),
    landingBorder: 2.5,
    landingTagFont: 11.5,
    landingTagGap: 4,
    landingTagRoom: 26,
    landingTagFlip: 330,
    dragLift: 0.55,
    dragScale: 1.1,
    dragLeastWidth: 48,
    dragBorder: 2.5,
    stackDepth: 3,
    stackStep: 2.5,
    stackTagOverlap: 4,
    stackTagRoom: 20,
    stackTagFont: 13,
    tagPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    edgeFill: Palette.cardFrame,
    edgeInk: Palette.ink,
    edgeBorder: 1,
  );

  /// The band while a card is sent (in portrait): its title over a line
  /// saying what to do, [lineGap] apart.
  static const double bandTitle = 20;
  static const double bandLine = 10;
  static const double lineGap = 2;
  static const Color bandInk = Palette.ink;
  static const Color lineInk = Palette.mute;

  /// Tobi's balloon while his card waits: [balloonSize], left of his box
  /// by [balloonGap] and [balloonDrop] of his height down it, its tail at
  /// [balloonSpeaker], its words [balloonFont].
  static const Size balloonSize = Size(80, 46);
  static const double balloonGap = 2;
  static const double balloonDrop = 0.12;
  static const Alignment balloonSpeaker = Alignment(1.5, 0.9);
  static const double balloonFont = 13;
  static const EdgeInsets balloonPadding = EdgeInsets.zero;
}

/// The call in the gap between the sides in landscape (`IkkiuchiCallStrip`):
/// paper words on a see-through [fill] that fades out over [fade] toward
/// both ends, [inset] solid beyond the words, reaching [bleed] into the
/// rows either side. The kimariji grows kana by kana in [kimariji]
/// lettering, each kana opening its room and popping in from [kanaPop] its
/// size over [kanaIn] ([kanaCurve]); the strip fades out over [fadeOut]
/// once nothing is read. A からふだ's tag comes first in [karafudaTag],
/// [karafudaInk]. A prompt is its [title] in display lettering, [dot], then
/// what to do in [line], [lineInk]. dp.
abstract final class IkkiuchiCallStyle {
  static const double bleed = 2.5;
  static const Color fill = Color(0xC4000000);
  static const double fade = 40;
  static const double inset = 8;
  static const Color ink = Palette.paper;
  static const double kimariji = 21;
  static const Duration kanaIn = Duration(milliseconds: 150);
  static const Curve kanaCurve = Curves.easeOutCubic;
  static const double kanaPop = 1.45;
  static const Duration fadeOut = Duration(milliseconds: 180);
  static const double karafudaTag = 10;
  static const Color karafudaInk = Color(0xB3FFFFFF);
  static const double karafudaGap = 6;
  static const double title = 16;
  static const String dot = '·';
  static const double dotGap = 7;
  static const double line = 12;
  static const Color lineInk = Color(0xE6FFFFFF);
}

/// The game column at the board's right edge in landscape
/// (`IkkiuchiMatchColumn`), [width] wide, [edge] in from the board's right
/// edge and from the field's top and foot, and at least [fieldGap] clear of
/// the field. dp.
abstract final class IkkiuchiColumnStyle {
  static const double width = 54;
  static const double edge = 6;
  static const double fieldGap = 8;

  /// 終了 at its top: a small arming button ([end]), its flag [endIcon].
  static const HoldConfirmLook end = HoldConfirmLook(
    ringSize: 40,
    ringStroke: 3.5,
    fillStroke: 2.5,
    bezel: 4,
    bezelStripe: 3,
    domeBorder: 2,
    countOutline: 6,
    shakeReach: 1.5,
    labelGap: 3,
    labelFont: 11,
    labelPadding: EdgeInsets.fromLTRB(6, 2, 6, 3),
  );
  static const double endIcon = 15;
  static const double endIconStroke = 2.6;

  /// The score in its middle, split on the gap between the sides: an ink
  /// panel with a hard [shadow], Tobi's name in [nameInk] over his cards
  /// left, then the player's under a [rule], the numbers in [count]
  /// lettering, the names in [name], [nameGap] from them.
  static const Color scoreFill = Palette.ink;
  static const Offset shadow = Offset(2, 2);
  static const Color shadowInk = Palette.inkShadow;
  static const EdgeInsets scorePadding = EdgeInsets.fromLTRB(2, 5, 2, 5);
  static const Color nameInk = Palette.sun;
  static const double name = 9;
  static const double nameTracking = 0.06;
  static const double nameGap = 2;
  static const Color countInk = Palette.paper;
  static const double count = 21;
  static const double ruleGap = 5;
  static const double rule = 1.5;
  static const Color ruleInk = Color(0x59FFFFFF);
  static const double ruleInset = 8;

  /// 並べ替え at its foot: an icon over its word, on paper, or on sun as
  /// 完了 while the player moves their cards; faded to [dimmed] while it
  /// can't be used.
  static const double buttonIcon = 18;
  static const double buttonIconStroke = 2.4;
  static const double buttonFont = 10.5;
  static const double buttonGap = 2;
  static const EdgeInsets buttonPadding = EdgeInsets.fromLTRB(2, 6, 2, 5);
  static const Color arrangeFill = Palette.paper;
  static const Color doneFill = Palette.sun;
  static const double dimmed = 0.38;
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
