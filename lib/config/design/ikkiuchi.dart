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

  /// In landscape there is no band: the sides lie [landscapeGap] apart.
  static const double landscapeGap = 17;
  static const Color bandFill = Palette.paper;
  static const Color bandRuleColor = Palette.ink;
  static const double kimariji = 20;
  static const Color kimarijiColor = Palette.ink;

  /// A note under the kimariji (the developer's readout), [noteGap] below.
  static const double noteFont = 10;
  static const double noteGap = 2;
  static const Color noteColor = Palette.mute;
  static const String noteEllipsis = '…';

  /// Words on the band in portrait instead of a call, as while a card is
  /// sent or the memory time runs: a title over a line, [wordsGap] apart.
  static const double wordsTitle = 20;
  static const double wordsLine = 10;
  static const double wordsGap = 2;
  static const Color wordsTitleInk = Palette.ink;
  static const Color wordsLineInk = Palette.mute;

  /// A からふだ's kimariji, and the tag in front of it, [karafudaGap] apart.
  static const Color karafudaColor = Palette.inkShadow;
  static const double karafudaTag = 10;
  static const String karafudaGap = '  ';

  /// A card of a 3-row match is never wider than [maxCardW]. A 1- or 2-row
  /// match keeps the 3-row field, as wide and, in landscape, as tall, and
  /// grows its cards from the 3-row card as far as that field lets them:
  /// its rows fit the field's height, and a full row
  /// (`IkkiuchiLayout.rowRoom`), its groups apart, fits across it; in
  /// landscape, a full row of Tobi's with his room in its open middle too.
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
  /// around it. In landscape just right of Tobi, `gap` clear of him, in
  /// the open middle of his half and over his cards where it must: at most
  /// `landscapeScale` field cards wide, and as tall as his half takes it
  /// with its tag, `gap` clear of the half's edges.
  static const wait = (maxHeight: 150.0, tobiShare: 0.78, margin: 12.0, scale: 1.8, landscapeScale: 2.3, gap: 6.0);

  /// Under the waiting card's tag a second tag says how to place it, its
  /// words [hintFont], [hintRoom] tall; the layout keeps room for both.
  static const double hintFont = 10.5;
  static const double hintRoom = 19;

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
    notePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    noteFont: 12.5,
    noteIcon: 16,
  );

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

/// The opening of a match (`IkkiuchiOpeningFlow`, `IkkiuchiOpeningLayer`):
/// the player lays out their side from a stack with the placing's look
/// (`IkkiuchiSendStyle.look`). dp.
abstract final class IkkiuchiOpeningStyle {
  /// In landscape the stack lies in the margin right of the player's side,
  /// [stackGap] clear of the field, its top card [stackScale] field cards
  /// wide.
  static const double stackScale = 2.3;
  static const double stackGap = 6;

  /// A placed card let go within [stackReach] of the stack goes back onto it.
  static const double stackReach = 6;

  /// The hint before the first card is placed: beside the stack over the
  /// player's half, at most [noteWidth] wide and [noteGap] clear of the
  /// spots at the half's edges; above the stack where that leaves it less
  /// than [noteMinWidth].
  static const double noteGap = 18;
  static const double noteWidth = 330;
  static const double noteMinWidth = 200;
}

/// The match's greetings over the board (`IkkiuchiGreeting`), as play
/// begins and once it is over: the board dimmed by [scrim], and the words
/// slammed onto each half in [font] [fill] lettering with an [outline] wide
/// [ink] outline, Tobi's half's turned [tobiTurnDeg] and landing first
/// ([tobiIn]), the player's turned [playerTurnDeg] ([playerIn]), each kept
/// [inset] inside its half. dp.
abstract final class IkkiuchiGreetingStyle {
  static const Color scrim = Color(0x66141414);
  static const double font = 46;
  static const double outline = 11;
  static const Color fill = Palette.sun;
  static const Color ink = Palette.ink;
  static const double tobiTurnDeg = -4;
  static const double playerTurnDeg = 3;
  static const EdgeInsets inset = EdgeInsets.all(10);
  static const tobiIn = EntranceSpec(Entrances.slam, duration: Duration(milliseconds: 420), curve: Entrances.springy);
  static const playerIn = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 280), curve: Entrances.springy);
  static Duration get length => playerIn.end;
}

/// How a match ended, over its board (`IkkiuchiMatchResult`): the board
/// dimmed by [scrim], fading in ([dimIn]); focus [lines] in [linesColor]
/// meeting in the board's middle, none across Tobi, rushing in
/// ([linesIn]); Tobi's rating tag over them, fading in dimmed by [scrim]
/// too, [tagGap] over his box or, short of room there, [tagGap] left of it
/// with its middle [tagDrop] of his height down; the result in [font]
/// [fill] lettering with an [outline] wide [ink] outline, turned
/// [turnDeg], slammed down ([letteringIn]) and kept [inset] inside the
/// board's sides; and [subGap] under it a line of [subFont] [subInk] words
/// on an [ink] banner [subHeight] tall and [subPadding] wider than them at
/// each end, turned with it and rising into place ([subIn]). dp.
abstract final class IkkiuchiResultStyle {
  static const Color scrim = Color(0x8C141414);
  static const double tagGap = 10;
  static const double tagDrop = 0.3;
  static const lines = (count: 120, innerMin: 120.0, innerMax: 170.0, width: 4.0, seed: 31);
  static const Color linesColor = Palette.paper;
  static const double font = 46;
  static const double outline = 22;
  static const Color fill = Palette.sun;
  static const Color ink = Palette.ink;
  static const double turnDeg = -5;
  static const double inset = 20;
  static const double subGap = 13;
  static const double subFont = 15;
  static const Color subInk = Palette.paper;
  static const double subHeight = 28;
  static const double subPadding = 10;
  static const dimIn = EntranceSpec(EntranceFrom(), duration: Duration(milliseconds: 220));
  static const linesIn =
      EntranceSpec(EntranceFrom(scale: 1.6), duration: Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  static const letteringIn = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 120), curve: Entrances.springy);
  static const subIn = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 480), curve: Entrances.settle);
  static Duration get length => subIn.end;
}

/// Tobi's rating on an ink tag (`IkkiuchiTobiTag`): his name in [nameFont]
/// [name] lettering, [gap], then the rating in [font] display lettering,
/// [padding] round them. dp.
abstract final class IkkiuchiTobiTagStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(7, 4, 7, 4);
  static const double nameFont = 11;
  static const double font = 15;
  static const double gap = 5;
  static const Color name = Palette.sun;
}

/// The call in the gap between the sides in landscape (`IkkiuchiCallStrip`):
/// paper words on a see-through [fill] that fades out over [fade] toward
/// both ends, [inset] solid beyond the words, reaching [bleed] into the
/// rows either side. The kimariji grows kana by kana in [kimariji]
/// lettering, each kana opening its room and popping in from [kanaPop] its
/// size over [kanaIn] ([kanaCurve]); the strip fades out over [fadeOut]
/// once nothing is read. A prompt is its [title] in display lettering,
/// [dot], then what to do in [line], [lineInk]. dp.
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
  static const double title = 16;
  static const String dot = '·';
  static const double dotGap = 7;
  static const double line = 12;
  static const Color lineInk = Color(0xE6FFFFFF);

  /// The 下の句 being read: its word in [kimariji] lettering, [shimonokuGap]
  /// before the 余韻 mark, [shimonokuTail] long and as tall as the lettering,
  /// tapering to the right. Both wipe away from the left as the 下の句 plays,
  /// with an edge [shimonokuEdge] wide.
  static const double shimonokuGap = 6;
  static const double shimonokuTail = 50;
  static const double shimonokuEdge = 6;

  /// How a read ended (`IkkiuchiFeedbackBanner`): [feedback] lettering on
  /// the strip; it slides in from
  /// [feedbackSlide] dp left, eased by [feedbackInCurve], and out as far
  /// right by [feedbackOutCurve], fading in and out on the way.
  static const double feedback = 20;
  static const double feedbackSlide = 90;
  static const Curve feedbackInCurve = Curves.easeOutCubic;
  static const Curve feedbackOutCurve = Curves.easeInCubic;
}

/// The game column at the board's right edge in landscape
/// (`IkkiuchiMatchColumn`), [width] wide, [edge] in from the board's right,
/// top and bottom edges, and at least [fieldGap] clear of the field. dp.
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

  /// The buttons at its foot, [buttonsGap] apart: each an icon over its
  /// word, 並べ替え on paper, 完了 and 覚えた on sun once they can be used;
  /// faded to [dimmed] while a button can't be used.
  static const double buttonIcon = 18;
  static const double buttonIconStroke = 2.4;
  static const double buttonFont = 10.5;
  static const double buttonGap = 2;
  static const double buttonsGap = 6;
  static const EdgeInsets buttonPadding = EdgeInsets.fromLTRB(2, 6, 2, 5);
  static const Color arrangeFill = Palette.paper;
  static const Color doneFill = Palette.sun;
  static const double dimmed = 0.38;

  /// 完了 blinks once every card is placed, until tapped: a [blinkInk] ring
  /// [blinkWidth] wide lies [blinkGap] outside its edge, and once every
  /// [blinkPeriod] the ring fades out as the button swells by [blinkSwell]
  /// of its size, then flashes back as it shrinks. Under reduced motion it
  /// stands still, the ring shown.
  static const Duration blinkPeriod = Duration(milliseconds: 1100);
  static const double blinkSwell = 0.06;
  static const Color blinkInk = Palette.sun;
  static const double blinkWidth = 3;
  static const double blinkGap = 2;
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

/// A ranked mode's colours on 一騎打ち's page (`IkkiuchiModeTabs`): [tint]
/// fills its tab while another is chosen; its halftone [tone] fills its
/// tab when chosen, its class badge and the ground under its rating
/// curve; [deep] fills the bar to the next class and marks the curve's
/// latest match.
@immutable
class IkkiuchiModeTone {
  const IkkiuchiModeTone({required this.tint, required this.tone, required this.deep});
  final Color tint;
  final ToneSpec tone;
  final Color deep;
}

/// A ranked mode's class badge (`IkkiuchiClassBadge`): [size] square in the
/// mode's tone, edged [stroke], the class kept [inset] in from its sides:
/// the stem at [classFont] and 級 at [suffixFont], a longer stem at
/// [longFont] and [longSuffixFont], and the mark of no class yet at
/// [unplacedFont]. dp.
@immutable
class IkkiuchiBadgeStyle {
  const IkkiuchiBadgeStyle({
    required this.size,
    required this.classFont,
    required this.suffixFont,
    required this.longFont,
    required this.longSuffixFont,
    required this.unplacedFont,
    this.stroke = Strokes.panel,
    this.inset = 5,
  });
  final double size, stroke, inset;
  final double classFont, suffixFont, longFont, longSuffixFont, unplacedFont;
}

/// A ranked mode's rating curve (`IkkiuchiCurveScale`), [top] kept clear
/// over the line: each match in its own slot from [labelRoom] in to
/// [inset] short of the right, the line [line] wide, the matches dots of
/// radius [dot] ringed [ring], the latest a diamond reaching [mark] each
/// way ringed [markRing]; the y range padded by [rangeShare] of it, or
/// [minPad] at least. dp.
@immutable
class IkkiuchiCurveStyle {
  const IkkiuchiCurveStyle({
    required this.labelRoom,
    required this.inset,
    required this.top,
    required this.line,
    required this.dot,
    required this.mark,
    required this.markRing,
    required this.minPad,
    required this.rangeShare,
    this.ring = Strokes.hairline,
  });
  final double labelRoom, inset, top, line, dot, ring, mark, markRing, minPad, rangeShare;
}

/// 一騎打ち's page (`ikkiuchi_page.dart`): the mode tabs [tabsTop] under the
/// header, the free play panel at the foot, then the button pair [pairTop]
/// under it and [bottomGap] over the screen's foot.
///
/// The tabs (`IkkiuchiModeTabs`): three, [tabGap] apart, the chosen one
/// [tabHeight] tall. Their tops lie on one line that falls [tabSlant] from
/// the right edge to the left; the others stand [tabDrop] lower, in their
/// mode's tint, edged [quietStroke], behind the box's top line. The chosen
/// tab and the box are one outline [frameStroke] wide, the tab in its
/// mode's tone. A tab shows the mode's name in display type over its cards
/// a side ([tabSubGap] between), [tabTop] under the chosen tab's top or
/// [quietTabTop] under the others': the chosen name at [tabName] in ink,
/// the others' at [quietTabName] in [quietName], their cards in
/// [quietSub]; Latin names a size bigger ([tabNameLatin],
/// [quietTabNameLatin]) and tracked [tabNameLatinTracking].
///
/// The box: the player's standing ([standPadding]), the rating curve or its
/// note while placing ([curveMargin], its top the gap under the standing),
/// a light rule, the mode's match ([factsPadding]) and the burst
/// ([burstMargin]). The curve's room takes the screen's height left over:
/// on the user's phone at the usual text size about the mock's 58 dp, more
/// on a taller screen. Under [curveMinHeight] the curve's labels crowd its
/// line and it no longer reads, so it gives way: the box closes up to the
/// gap under the standing and the rest goes over free play. A curve shown
/// is tapped anywhere in its room, the gap over it too.
///
/// The standing: the class [badge] in the mode's tone, [unplaced] in it
/// while placing. [standGap] right of it the labels at
/// [labelFont]; [ratingTop] under the label the rating at [ratingFont],
/// its change [changeGap] after it on a tag at [changeFont]; then
/// [gaugeTop] under it, [gaugeHeight] tall, the way to the next class at
/// [gaugeFont] (its number at [gaugeNumber]), no wider than
/// [gaugeWordsShare] of the room, and its bar filling the rest, [barHeight]
/// tall, [barGap] after the words. While placing: [slotsTop] under the
/// label the four placement matches as slots, [slot] square and [slotGap]
/// apart, played ones 勝 on ink or 負 in [lostInk], the next one edged
/// [nextSlotBorder], the rest dashed in [slotInk]; then [noteTop] under
/// them the line on what placement decides, as tall as the gauge.
///
/// The curve (`IkkiuchiRatingCurve`, drawn by [curve]): the rating after
/// each of the mode's last ranked matches, each in its own slot from the
/// left, the latest a diamond in the mode's colour. The class lines
/// dashed in [classLine], their names [classLabelLift] over them in
/// [classLabelInk], kept [classLabelClear] above the caption, which sits
/// [captionDrop] over the floor in [captionInk]; labels at
/// [curveLabelFont]. The floor, [curveFloor] wide, starts the curve's
/// inset left of the line. While the line is short, [growsDrop] over the floor, a note
/// at [growsFont] in its empty part says it grows. While placing, the same
/// room holds a dashed outline in [lightRule] with a note on one line at
/// [curveNoteFont], or smaller to fit, until a placement match is played;
/// then the estimate after each of them, from the start, in the curve's
/// style: each placement match in its own slot, the line dashed
/// [placementDash] while an estimate and the latest a paper diamond
/// ringed [placementMarkRing].
///
/// The mode's match: its field ([field], [fieldGap] before the rest), its
/// cards a side and memory time under their labels ([factGap] between),
/// at [factFont] with the unit at [factUnitFont], split by an ink rule
/// [factRuleGap] clear of each, [factRuleInset] short at both ends.
///
/// Free play: its panel's heading at [headingFont], [headingPadding] round
/// it, beside the tag: smaller where the room there is short, down to
/// [headingMinScale] of its size, and left out where even that does not
/// fit; the bots row at least [botsRowHeight] tall, inside
/// [botsRowPadding] (its robot in a [botFrame] frame filled
/// [botFrameFill], its name at [botsTitleFont] tracked [botsTitleTracking],
/// its line at [botsLineFont]), then under a light rule the custom row at
/// least [customRowHeight] tall, inside [customRowPadding] (its gear
/// [gearBox] wide, its name at [customTitleFont] tracked
/// [customTitleTracking], its line on one line at [customLineFont], or
/// smaller to fit); each row's
/// other-language name at [rowSubFont],
/// [rowSubGap] after its own; Latin names tracked [rowTitleLatinTracking];
/// [rowGap] between a row's parts and a chevron at its end. The rules
/// sheet dims the page to [barrier].
abstract final class IkkiuchiPageLayout {
  static const double tabsTop = 8;
  static const double pairTop = 12;
  static const double bottomGap = 12;
  static const Color barrier = Color(0x8C141414);

  static const bullet = IkkiuchiModeTone(
    tint: Color(0xFFFFEDF3),
    tone: ToneSpec(dot: Color(0xFFFF8DB3), radius: 1.15, spacing: 6, background: Palette.pinkSoft, phase: 0.25),
    deep: Palette.pink,
  );
  static const blitz = IkkiuchiModeTone(
    tint: Color(0xFFFFF8D9),
    tone: ToneSpec(dot: Color(0xFFFFC400), radius: 1.15, spacing: 6, background: Palette.sunSoft, phase: 0.25),
    deep: Palette.sun,
  );
  static const rapid = IkkiuchiModeTone(
    tint: Color(0xFFEAF5FF),
    tone: ToneSpec(dot: Color(0xFF7CC2FF), radius: 1.15, spacing: 6, background: Palette.seaSoft, phase: 0.25),
    deep: Palette.sea,
  );

  static const double tabHeight = 64;
  static const double tabGap = 6;
  static const double tabSlant = 10;
  static const double tabDrop = 10;
  static const double frameStroke = Strokes.panel;
  static const double quietStroke = Strokes.control;
  static const double tabTop = 6;
  static const double quietTabTop = 16;
  static const double tabName = 19;
  static const double quietTabName = 16;
  static const double tabNameLatin = 20;
  static const double quietTabNameLatin = 17;
  static const double tabNameLatinTracking = 0.5;
  static const double tabSub = 11;
  static const double tabSubTracking = 0.6;
  static const double tabSubGap = 5;
  static const Color quietName = Color(0xFF4A4A4A);
  static const Color quietSub = Color(0xFF6B6B6B);

  static const EdgeInsets standPadding = EdgeInsets.fromLTRB(16, 16, 16, 0);
  static const badge = IkkiuchiBadgeStyle(
    size: 74,
    classFont: 40,
    suffixFont: 17,
    longFont: 30,
    longSuffixFont: 14,
    unplacedFont: 38,
  );
  static const String unplaced = '?';
  static const double standGap = 14;
  static const double labelFont = 12;
  static const double ratingTop = 3;
  static const double ratingFont = 32;
  static const double changeGap = 8;
  static const double changeFont = 13;
  static const EdgeInsets changePadding = EdgeInsets.fromLTRB(4, 3, 5, 4);
  static const double changeBorder = Strokes.label;
  static const double gaugeTop = 9;
  static const double gaugeHeight = 22;
  static const double gaugeFont = 12;
  static const double gaugeNumber = 14;
  static const double gaugeWordsShare = 0.7;
  static const double barGap = 10;
  static const double barHeight = 14;
  static const double barBorder = Strokes.control;
  static const double slotsTop = 6;
  static const double slot = 30;
  static const double slotGap = 6;
  static const double slotFont = 14;
  static const double slotBorder = Strokes.label;
  static const double nextSlotBorder = Strokes.control;
  static const Color slotInk = Color(0xFF8A8A8A);
  static const Color lostInk = Color(0xFF6B6B6B);
  static const double noteTop = 8;

  static const EdgeInsets curveMargin = EdgeInsets.fromLTRB(16, 14, 16, 12);
  static const double curveMinHeight = 32;
  static const curve = IkkiuchiCurveStyle(
    labelRoom: 60,
    inset: 7,
    top: 6,
    line: 2.2,
    dot: 2.6,
    mark: 6,
    markRing: Strokes.hairline,
    minPad: 18,
    rangeShare: 0.14,
  );
  static const List<double> placementDash = [6, 4];
  static const double placementMarkRing = Strokes.label;
  static const double curveFloor = Strokes.hairline;
  static const double classLineWidth = Strokes.hairline;
  static const Color classLine = Color(0xFF9B978F);
  static const Color classLabelInk = Color(0xFF8A8680);
  static const double classLabelLift = 4;
  static const double classLabelClear = 14;
  static const double curveLabelFont = 10.5;
  static const double captionDrop = 1;
  static const double captionTracking = 0.4;
  static const Color captionInk = Color(0xFF6B6B6B);
  static const double growsFont = 11;
  static const double growsDrop = 10;
  static const double curveNoteFont = 11.5;
  static const double curveNotePadding = 10;
  static const double curveNoteBorder = Strokes.label;
  static const Color lightRule = Color(0xFFC9C6BF);
  static const double splitHeight = Strokes.label;
  static const double splitInset = 16;

  static const EdgeInsets factsPadding = EdgeInsets.fromLTRB(16, 14, 16, 0);
  static const Size field = Size(118, 70);
  static const double fieldGap = 16;
  static const double factGap = 8;
  static const double factFont = 27;
  static const double factUnitFont = 13;
  static const double factRule = Strokes.control;
  static const double factRuleGap = 12;
  static const double factRuleInset = 2;
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(4, 14, 4, 12);

  static const double headingFont = 12;
  static const double headingMinScale = 0.75;
  static const EdgeInsets headingPadding = EdgeInsets.fromLTRB(0, 3, 0, 2);
  static const EdgeInsets rowMargin = EdgeInsets.symmetric(horizontal: 14);
  static const double rowGap = 14;
  static const double rowSubFont = 10.5;
  static const double rowSubTracking = 1.7;
  static const double rowSubGap = 6;
  static const double rowTitleHeight = 1.2;
  static const double rowTitleLatinTracking = 0.4;
  static const double chevron = 22;
  static const double chevronStroke = 3;
  static const double botsRowHeight = 88;
  static const EdgeInsets botsRowPadding = EdgeInsets.fromLTRB(0, 4, 0, 6);
  static const double botFrame = 60;
  static const double botFrameBorder = Strokes.control;
  static const Color botFrameFill = Palette.desk;
  static const double botIcon = 38;
  static const double botIconStroke = 2.2;
  static const double botsTitleFont = 21;
  static const double botsTitleTracking = 1;
  static const double botsLineFont = 12.5;
  static const double botsLineHeight = 1.45;
  static const double botsLineTop = 4;
  static const double customRowHeight = 60;
  static const EdgeInsets customRowPadding = EdgeInsets.symmetric(vertical: 5);
  static const double customRule = Strokes.label;
  static const double gearBox = 60;
  static const double gear = 30;
  static const double gearStroke = 2.2;
  static const double customTitleFont = 15;
  static const double customTitleTracking = 1.5;
  static const double customLineFont = 12;
  static const double customLineHeight = 1.3;
}

/// The popup of a ranked mode's curve on 一騎打ち's page
/// (`IkkiuchiCurvePopup`): the rank change page's mode box at rest,
/// [height] tall, as on the rank change page on the user's phone at the
/// usual text size (less where the screen is shorter), over the page dimmed
/// as for its sheets ([IkkiuchiPageLayout.barrier]). Its tab stands on the
/// mode's ground as on that page, in a strip [head] taller than the tab,
/// outlined in ink with the box; the close button stands in the middle of
/// the strip's height, as far in from its right end. dp.
abstract final class IkkiuchiCurvePopupLayout {
  static const double height = 474;
  static const double head = 18;
}

/// The bots page (`IkkiuchiBotsPage`): its line about the bots
/// ([introPadding], at [introFont]).
abstract final class IkkiuchiBotsLayout {
  static const EdgeInsets introPadding = EdgeInsets.fromLTRB(4, 10, 4, 0);
  static const double introFont = 13;
  static const double introLineHeight = 1.55;
}

/// The field picture (`IkkiuchiFieldPicture`): the field's [ground] under
/// the match's tatami in an ink frame [border] wide, the cards [padding]
/// inside it; the band [band] tall in paper with ink rules [bandRule]
/// wide, [bandGap] from the cards; every card face down in the card
/// frame's green with a [cardEdge] ink edge.
abstract final class IkkiuchiFieldPictureStyle {
  static const Color ground = Color(0xFF99A083);
  static const double border = Strokes.control;
  static const double padding = 0;
  static const double band = 5;
  static const double bandRule = 1;
  static const double bandGap = 1.5;
  static const double cardEdge = 0.7;
}

/// 一騎打ち's custom page (`ikkiuchi_custom_page.dart`): one panel [panelTop]
/// under the header, its top-left corner [cut] down, its blocks [padding]
/// inside it, and [bottomGap] under it when the page scrolls. In guest
/// mode a line at [guestLineFont] lies [guestLineGap] under the title.
///
/// Each setting's label at [labelFont] in a row [labelHeight] tall, the
/// other language's at [labelSubFont] with [labelSubTracking], [labelSubGap]
/// after it; [barGap] under it its keys, joined in one bar: a [barBorder]
/// ink outline, [keyRule] ink rules between the keys, each [keyHeight] tall
/// ([rowKeyHeight] for the rows), its name in display type at [keyFont]
/// over its value at [keySubFont], [keySubGap] apart. The chosen key is
/// [chosen] inside a [chosenRing] ink ring; a shut one is hatched, bands
/// of [hatchLight] [hatchBand] wide and of [hatchDark] [hatchLine] wide,
/// its type in [shut] with a lock [lockSize] big, [lockInset] from its top
/// right corner.
///
/// A stepper, [barGap] under the keys, beside its label at [fineFont]:
/// [stepperHeight] tall in a [barBorder] outline, − and + [stepperButton]
/// wide (their rules within) round the value [stepperValueWidth] wide, in
/// display type at [valueFont] with its unit at [unitFont]; held down it
/// steps on every [repeatEvery]. Between the settings, a [splitHeight]
/// rule in [split], [splitAbove] under the one before and [splitBelow]
/// over the next. Under the rows' keys, [whyGap] down, why some are shut,
/// at [whyFont] in rows [whyLineHeight] tall, the count in display type.
/// The memory time's label at [labelFont] over the other language's at
/// [labelSubFont], [memorySubGap] apart.
///
/// Then the setup in brief, [summaryTop] down: a picture of the field
/// [picture] big, [summaryGap] from two lines at [summaryFont] in rows
/// [summaryLineHeight] tall, numbers in display type at
/// [summaryNumberFont]; and the burst in [burstMargin].
abstract final class IkkiuchiCustomLayout {
  static const double panelTop = 10;
  static const double cut = 12;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(16, 16, 16, 2);
  static const double bottomGap = 12;
  static const double guestLineFont = 12;
  static const double guestLineGap = 3;

  static const double labelHeight = 20;
  static const double labelFont = 13;
  static const double labelSubFont = 10.5;
  static const double labelSubTracking = 1.6;
  static const double labelSubGap = 6;

  static const double barGap = 8;
  static const double barBorder = Strokes.control;
  static const double keyRule = 2;
  static const double keyHeight = 48;
  static const double rowKeyHeight = 52;
  static const double keyFont = 17;
  static const double keySubFont = 10.5;
  static const double keySubGap = 4;
  static const Color chosen = Palette.sun;
  static const double chosenRing = 2;
  static const Color hatchLight = Color(0xFFEFEDE9);
  static const Color hatchDark = Palette.desk;
  static const double hatchBand = 5;
  static const double hatchLine = 2;
  static const Color shut = Color(0xFF9B978F);
  static const double lockSize = 12;
  static const double lockStroke = 2.6;
  static const Offset lockInset = Offset(5, 4);

  static const double fineFont = 12.5;
  static const double stepperHeight = 48;
  static const double stepperButton = 48;
  static const double stepperValueWidth = 116;
  static const double signFont = 20;
  static const double valueFont = 25;
  static const double unitFont = 12;
  static const Duration repeatEvery = Duration(milliseconds: 90);

  static const double splitHeight = 2;
  static const Color split = Color(0xFFC9C6BF);
  static const double splitAbove = 12;
  static const double splitBelow = 10;

  static const double whyGap = 7;
  static const double whyFont = 12;
  static const double whyLineHeight = 1.4;
  static const double memorySubGap = 3;

  static const double summaryTop = 12;
  static const Size picture = Size(86, 50);
  static const double summaryGap = 12;
  static const double summaryFont = 12.5;
  static const double summaryLineHeight = 1.5;
  static const double summaryNumberFont = 14;
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(0, 10, 0, 8);
}

/// A recorded match's page in History. The Overview's hero, Tobi on it
/// smaller than on a run's; the cards shown in a panel's shelf. The Speed
/// chart numbers every bar up to [allLabelsUpTo] reads, else every
/// [labelEvery]th, and draws a take before the deciding sound as a sliver
/// [earlyTakeMs] tall. The Field's cards [fieldPadding] inside its box;
/// its 送り札: the dashed outline where each went, its word in [sentWord],
/// and its arrow in [sentArrow]; a fault's chip in the step box. The
/// rating's hero, [ratingHeight] tall, its lines [linesTop] down across
/// the whole panel.
abstract final class IkkiuchiHistoryStyle {
  static const heroMetrics = HeroMetrics(
    countTop: 52,
    countFont: 80,
    wordTop: 54,
    plainWordTop: 66,
    plainWordFont: 52,
    wordWidth: 236,
    subTop: 108,
    timeTop: 66,
    timeFont: 66,
    tobi: Size(66, 79),
    stampAt: Offset(122, 122),
    topStampInset: Offset(0, 16),
  );
  static const int shownCards = SummaryPanelLayout.perLine;

  static const int allLabelsUpTo = 16;
  static const int labelEvery = 5;
  static const double earlyTakeMs = 20;

  static const double fieldPadding = 6;
  static const List<double> sentDash = [3, 3];
  static const Color sentWord = HistoryRunStyle.muted;
  static const Color sentArrow = Palette.ink;
  static const Color faultChip = Palette.ink;
  static const Color faultChipText = Palette.paper;

  static const ratingMetrics = HeroMetrics(
    countTop: 52,
    countFont: 80,
    wordTop: 54,
    plainWordTop: 66,
    plainWordFont: 52,
    wordWidth: 236,
    subTop: 108,
    timeTop: 66,
    timeFont: 66,
    tobi: Size(70, 83),
    stampAt: Offset(122, 122),
    bodyWidth: 324,
  );
  static const double ratingHeight = 222;
  static const double linesTop = 44;
}

/// A ranked mode's own colours on its rank change page, beside its page
/// tone (`IkkiuchiModeTone`): the [glow] behind the title, the dots of the
/// impact frame ([impactDot]) and the [streak]s rising behind a win.
@immutable
class IkkiuchiRankTone {
  const IkkiuchiRankTone({required this.glow, required this.impactDot, required this.streak});
  final Color glow, impactDot, streak;
}

/// The rank change page after a ranked match (`IkkiuchiRankOverlay`, mock
/// B): the match card, then the mode's box from the 一騎打ち page with this
/// match added to its rating curve (or, while placing, to the placement
/// chart), and the button. dp; sizes marked (so) grow with the text size.
///
/// The ground: the mode's soft colour, its [bullet] / [blitz] / [rapid]
/// glow round [glowAt] fading out at [glowStops], the mode's dots
/// ([groundSpacing] apart, [groundPhase]) swelling toward the foot
/// ([groundRadii] at [groundStops] of the height), and after a win
/// [streakCount] streaks rising ([streakSeed]).
///
/// The column, [topGap] under the status bar and [bottomGap] over the
/// navigation bar: the title in [titleFont] display lettering (so) on
/// [titleOutline] of ink, in a room [titleRoom] tall (so), shrinking to the
/// width. [cardGap] under it the match card, [cardHeight] tall (so), its
/// top-left corner cut [cardCut], split at [cardSplit] of its width by a
/// line slanting [cardSlant], the winner's half in the mode's tone, edged
/// [cardStroke]. Your half, [youInset] in and [halfGap] clear of the line:
/// 勝 / 負 on a [mark] square edged [markBorder] at [markFont] (so),
/// [youGap] before your name at [nameFont] (so) over the margin at
/// [marginFont] (so) with its number at [marginNumber] (so), [whoGap]
/// apart. Tobi's half, [tobiInset] from the right: Tobi ([tobi]) over his
/// plate (`IkkiuchiTobiTag` at [plateName] and [plateFont] (so) inside
/// [platePadding], as tall as the name with its full line), [tobiGap]
/// apart, at the card's foot. VS on an ink
/// parallelogram ([vs], skewed [vsSkewDeg]) at [vsFont], tracked
/// [vsTracking].
///
/// [boxGap] under it the mode's tab ([tabWidth] by [tabHeight], its
/// lettering [tabTop] down, its top falling [tabSlant] across the box's
/// width) joined to the box in one [frameStroke] outline, with the ランク戦
/// tag [rankedGap] after it and [rankedDrop] over the box (at [rankedFont]
/// (so), tracked [rankedTracking], inside [rankedPadding], skewed
/// [rankedSkewDeg]). Inside [boxPadding]: the class [badge], [badgeDrop]
/// under the standing's middle, [standGap] before the label at [labelFont] (so; numbers at [labelNumber]) in a
/// room [labelRoom] tall (so), [ratingTop] over the rating at [ratingFont]
/// (so) with its change [tagGap] after it on a tag at [tagFont] (so)
/// inside [tagPadding], edged [tagBorder], in a room [tagRoom] tall (so)
/// and at least [tagMinWidth] wide. A class change shows as chips at
/// [chipFont] (so) inside [chipPadding], edged [chipBorder], [chipGap] each
/// side of the arrow, the old one in [oldChip] edged [oldChipEdge] and
/// struck through [strike]. [gaugeTop] under the rating, [gaugeHeight]
/// tall (so), the way to the next class at [gaugeFont] (so; its number at
/// [gaugeNumber]) and its bar [barGap] after it, [barHeight] tall, edged
/// [barBorder], at least [barMinWidth] wide. While placing a note at
/// [noteFont] (so; numbers at [noteNumber]) [noteTop] under the rating,
/// its lines [noteLineHeight] apart, breaking between phrases; a line up
/// to [noteSqueeze] too wide shrinks to fit instead. [plotTop] under the standing the
/// curve or the chart takes the rest, at least [plotMinHeight], [plotFoot]
/// clear of the box's foot.
///
/// [ctaTop] under the box the button, at least [ctaHeight] tall, its label
/// at [ctaFont] and the other language's at [ctaSubFont] (both so).
abstract final class IkkiuchiRankLayout {
  static const bullet = IkkiuchiRankTone(
      glow: Color(0xFFFFF6F9), impactDot: Color(0xFFE0246A), streak: Color(0xBFFFFFFF));
  static const blitz = IkkiuchiRankTone(
      glow: Color(0xFFFFFCEB), impactDot: Color(0xFFFF9A2E), streak: Color(0xCCFFFFFF));
  static const rapid = IkkiuchiRankTone(
      glow: Color(0xFFF4FAFF), impactDot: Color(0xFF1463C4), streak: Color(0xCCFFFFFF));

  static const Alignment glowAt = Alignment(0, -0.64);
  static const List<double> glowStops = [0, 0.014, 0.263, 1];
  static const List<double> groundRadii = [0, 0, 1, 1.9];
  static const List<double> groundStops = [0, 0.35, 0.7, 1];
  static const double groundSpacing = 6;
  static const double groundPhase = 0.25;
  static const int streakCount = 40;
  static const int streakSeed = 29;

  static const double topGap = 6;
  static const double bottomGap = 12;
  static const double titleFont = 62;
  static const double titleOutline = 9;
  static const double titleRoom = 64;

  static const double cardGap = 8;
  static const double cardHeight = 104;
  static const double cardCut = 12;
  static const double cardSplit = 0.55;
  static const double cardSlant = 24;
  static const double cardStroke = Strokes.panel;
  static const double halfGap = 8;
  static const double youInset = 14;
  static const double youGap = 12;
  static const double mark = 42;
  static const double markBorder = Strokes.control;
  static const double markFont = 22;
  static const double nameFont = 19;
  static const double whoGap = 5;
  static const double marginFont = 13;
  static const double marginNumber = 15;
  static const double tobiInset = 10;
  static const double tobiGap = 3;
  static const Size tobi = Size(56, 67);
  static const double plateName = 12;
  static const double plateFont = 17;
  static const EdgeInsets platePadding = EdgeInsets.fromLTRB(7, 5.5, 7, 6.5);
  static const Size vs = Size(34, 24);
  static const double vsSkewDeg = -14;
  static const double vsFont = 13;
  static const double vsTracking = 0.5;

  static const double boxGap = 14;
  static const double tabWidth = 132;
  static const double tabHeight = 42;
  static const double tabTop = 4;
  static const double tabSlant = 10;
  static const double frameStroke = Strokes.panel;
  static const double rankedGap = 12;
  static const double rankedDrop = 8;
  static const double rankedFont = 13;
  static const double rankedTracking = 1.5;
  static const EdgeInsets rankedPadding = EdgeInsets.fromLTRB(9, 3, 9, 4);
  static const double rankedSkewDeg = -12;
  static const EdgeInsets boxPadding = EdgeInsets.fromLTRB(14, 14, 14, 18);

  static const badge = IkkiuchiBadgeStyle(
    size: 82,
    classFont: 46,
    suffixFont: 18,
    longFont: 33,
    longSuffixFont: 15,
    unplacedFont: 44,
  );
  static const double badgeDrop = 5;
  static const double standGap = 14;
  static const double labelFont = 12.5;
  static const double labelNumber = 13;
  static const double labelRoom = 15;
  static const double ratingTop = 3;
  static const double ratingFont = 42;
  static const double tagGap = 8;
  static const double tagFont = 15;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(5, 3, 6, 4);
  static const double tagBorder = Strokes.label;
  static const double tagRoom = 26;
  static const double tagMinWidth = 70;
  static const double chipFont = 12;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double chipBorder = Strokes.label;
  static const double chipGap = 5;
  static const double strike = Strokes.label;
  static const Color oldChip = Color(0xFF6B6B6B);
  static const Color oldChipEdge = Color(0xFF8A8A8A);
  static const double gaugeTop = 8;
  static const double gaugeHeight = 18;
  static const double gaugeFont = 12.5;
  static const double gaugeNumber = 15;
  static const double barGap = 10;
  static const double barHeight = 14;
  static const double barBorder = Strokes.control;
  static const double barMinWidth = 30;
  static const double noteTop = 7;
  static const double noteFont = 12;
  static const double noteNumber = 14;
  static const double noteLineHeight = 1.35;
  static const double noteSqueeze = 0.04;
  static const double plotTop = 12;
  static const double plotMinHeight = 140;
  static const double plotFoot = 2;

  static const double ctaTop = 12;
  static const double ctaHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;

  /// The curve: the page's, drawn a size bigger by [curve]. The class line
  /// the match crosses turns ink and grows [strainWidth] wide, swelling
  /// [strainSwell] more at each heartbeat; broken through, it opens
  /// [breakGap] each side of the line, cracked [crackGap]. Until this match
  /// lands a dashed guide ([guideDash], [guideInk]) stands in its slot, from
  /// [guideOver] over the top. Where the line lands or breaks through,
  /// [burstStrokes] ink strokes [burstStroke] wide fly out from [burstFrom]
  /// to [burstReach] more ([burstEnd] at the last), turned up to
  /// [burstJitter] off even ([burstSeed]), [breakBurst] times as big at a
  /// break, where the [breakMark] stays, a [breakMarkSize] square centred
  /// on the break.
  static const curve = IkkiuchiCurveStyle(
    labelRoom: 60,
    inset: 14,
    top: 12,
    line: 2.4,
    dot: 2.8,
    mark: 8,
    markRing: Strokes.label,
    minPad: 16,
    rangeShare: 0.16,
  );
  static const double strainWidth = 2.2;
  static const double strainSwell = 1.6;
  static const double breakGap = 16;
  static const double crackGap = 30;
  static const List<double> guideDash = [3, 3];
  static const Color guideInk = Color(0x5C141414);
  static const double guideOver = 4;
  static const int burstStrokes = 12;
  static const double burstFrom = 10;
  static const double burstReach = 10;
  static const double burstEnd = 4;
  static const double burstStroke = 2.4;
  static const double burstJitter = 0.3;
  static const int burstSeed = 33;
  static const double breakBurst = 1.8;
  static const String breakMark = 'assets/graphics/sidetrips/ikkiuchi/rank-break.webp';
  static const double breakMarkSize = 64;

  /// The placement chart: the estimate after each placement match over its
  /// slot, between [chartLow] and [chartHigh] or further to hold the path
  /// with [chartPad] to spare; the slots [chartLabelRoom] + [chartLeft] in
  /// to [chartRight] short of the right, [chartTop] under the top and
  /// [chartAxis] over the foot. The path [chartLine] wide, dashed
  /// [chartDash] while an estimate; its points dots of radius [chartDot]
  /// edged [chartRing], the latest a diamond reaching [chartMark] edged
  /// [chartMarkRing]. Each step at [stepFont] (so), [stepGap] beside and
  /// [stepLift] over its point after a win, [stepDrop] (so) under after a
  /// loss. Matches to come as dashed columns ([futureDash], [futureInk])
  /// under their step (±) at [futureFont] (so), [futureDrop] under the top.
  /// Class names at the curve's size in [chartLabelInk]. The axis: 開始
  /// [startDrop] (so) under it and the start rating [startRatingDrop] (so)
  /// under its point, at [startFont] (so) in [startInk], and a [slot]
  /// square per match [slotTop] under the axis, played at [slotFont] (so)
  /// edged [slotBorder] (負 in [lostInk]), the next edged [nextSlotBorder],
  /// the rest dashed ([slotDash], [slotInk]), their number at [slotNumber]
  /// (so). Once the class shows its band fills from [bandInset] left of
  /// the class lines' room, and ここから marks the last point on an ink tag
  /// at [hereFont] (so), [hereHeight] tall (so), [herePad] wider than the
  /// words each side, [hereLift] over the point; a Latin letter takes
  /// [hereLatinShare] of a kana's width.
  static const double chartLow = 1100;
  static const double chartHigh = 2650;
  static const double chartPad = 100;
  static const double chartLabelRoom = 62;
  static const double chartLeft = 14;
  static const double chartRight = 26;
  static const double chartTop = 12;
  static const double chartAxis = 34;
  static const double chartLine = 2.6;
  static const List<double> chartDash = [7, 5];
  static const double chartDot = 3.4;
  static const double chartRing = Strokes.label;
  static const double chartMark = 8.5;
  static const double chartMarkRing = 2.2;
  static const Color chartLabelInk = Color(0xFF8A8680);
  static const double stepFont = 11;
  static const double stepGap = 7;
  static const double stepLift = 8;
  static const double stepDrop = 18;
  static const List<double> futureDash = [3, 3];
  static const Color futureInk = Color(0x2E141414);
  static const double futureFont = 12;
  static const double futureDrop = 2;
  static const double startFont = 11;
  static const double startDrop = 15;
  static const double startRatingDrop = 18;
  static const Color startInk = Color(0xFF6B6B6B);
  static const double slot = 22;
  static const double slotTop = 7;
  static const double slotFont = 13;
  static const double slotNumber = 12;
  static const double slotBorder = Strokes.label;
  static const double nextSlotBorder = Strokes.control;
  static const List<double> slotDash = [3, 2.5];
  static const Color slotInk = Color(0xFF8A8A8A);
  static const Color lostInk = Color(0xFF6B6B6B);
  static const double bandInset = 4;
  static const double hereFont = 10.5;
  static const double hereHeight = 17;
  static const double herePad = 6;
  static const double hereLift = 22;
  static const double hereLatinShare = 0.55;

  /// The points changing hands: a chip (the change tag) between Tobi's
  /// plate, [plateLift] over it, and the curve, bowing out [chipBow] on its
  /// way, shrinking by [chipShrink] and turning from [chipTurnDeg]. Tobi's
  /// plate swells by [plateSwell] as they leave or arrive, and the diamond
  /// by [chipSwell] as they reach it.
  static const double plateLift = 6;
  static const Offset chipBow = Offset(40, 30);
  static const double chipShrink = 0.35;
  static const double chipTurnDeg = -6;
  static const double plateSwell = 0.14;
  static const double chipSwell = 0.5;

  /// The landing: the diamond swells by [landSwell] and the rating by
  /// [ratingSwell], the box jolts [winJolt] (a win) or [lossJolt] in
  /// [joltSteps] ([joltSeed]). At a rank up's heartbeats the diamond
  /// swells by [strainSwellMark] and the old class trembles [strainTremble]
  /// more than [restTremble]; at the break the diamond swells by
  /// [breakSwell]. While the class is hidden it beats by [hiddenBeat] and
  /// the diamond by [hiddenSwell], swelling by [revealSwell] as it shows.
  /// Tobi trembles [tobiTremble] once beaten ([tobiSeed]); the old class
  /// trembles by [trembleSeed] in the box and by [stageSeed] on the stage. The card's halves slide in
  /// from [halvesFrom] as it grows from [cardFrom], and it jolts
  /// [clashJolt] as they meet ([clashSteps], [clashSeed]).
  static const double landSwell = 0.6;
  static const double ratingSwell = 0.12;
  static const double winJolt = 5;
  static const double lossJolt = 3;
  static const int joltSteps = 7;
  static const int joltSeed = 67;
  static const double strainSwellMark = 0.35;
  static const double strainTremble = 1.6;
  static const double restTremble = 0.6;
  static const double breakSwell = 0.7;
  static const double hiddenBeat = 0.07;
  static const double hiddenSwell = 0.3;
  static const double revealSwell = 0.8;
  static const double tobiTremble = 1.3;
  static const int tobiSeed = 5;
  static const int trembleSeed = 3;
  static const int stageSeed = 4;
  static const double halvesFrom = 70;
  static const double cardFrom = 0.96;
  static const double clashJolt = 5;
  static const int clashSteps = 7;
  static const int clashSeed = 9;

  /// A rank up's strain: the page darkens to [darkness] but for a hole
  /// round the gate, clear out to [holeClear] and dark from [holeDark];
  /// ゴゴゴ ([rumble], [rumbleFont], violet) rumbles [rumbleShake] down both
  /// sides, the right one [rumbleRight] from the screen's right edge and
  /// the box's top, the left one [rumbleLeft] from its left edge
  /// ([rumbleSeeds], shaking by [rumbleShakeSeeds]). While the class is hidden the page dims to
  /// [hiddenDim] and the title to [hiddenTitle]. The break and the reveal
  /// flash white up to [flash].
  static const double darkness = 0.66;
  static const double holeClear = 34;
  static const double holeDark = 120;
  static const String rumble = 'ゴゴゴ';
  static const double rumbleFont = 40;
  static const double rumbleShake = 2;
  static const Offset rumbleRight = Offset(-54, 30);
  static const Offset rumbleLeft = Offset(4, 215);
  static const (int, int) rumbleSeeds = (13, 14);
  static const (int, int) rumbleShakeSeeds = (11, 12);
  static const double hiddenDim = 0.18;
  static const double hiddenTitle = 0.45;
  static const double flash = 0.85;

  /// The impact frame of a rank up and of the first class: the mode's
  /// colour, glowing white and then the mode's glow round the stage at
  /// [stageAt] out to [stageGlow] ([stageGlowStops]), its dots growing
  /// toward the foot ([impactRadii] at [impactStops]), white focus lines on
  /// the stage ([impactLines]). The class stands there [stageScale] times
  /// its badge: the old one pops up from [oldFrom] times, trembles
  /// [stageTremble], and is cut in two ([cut], in the badge's own size) by
  /// the [blade] (on a [bladeBox] round the stage), ズバッ!! ([slash],
  /// [slashFont], [slashSeed]) [slashAt] from the stage, turned
  /// [slashTurnDeg]. The new one drops from [dropFrom] times as big, turned
  /// [dropTurnDeg], onto the ink [splat] ([splatSize], settling to
  /// [splatRest] of it) with ドン!! ([hit]) or, for the first class,
  /// ジャン!! ([reveal]) [sfxAt] from it, turned [sfxTurnDeg]; the frame
  /// jolts [impactJolt] ([impactSteps], [impactSeed]).
  static const Alignment stageAt = Alignment(0, 0.058);
  static const double stageGlow = 300;
  static const List<double> stageGlowStops = [0, 0.35, 1];
  static const List<double> impactRadii = [0, 0, 1.6];
  static const List<double> impactStops = [0, 0.6, 1];
  static const impactLines = (count: 150, innerMin: 150.0, innerMax: 185.0, width: 4.0, seed: 41);
  static const double stageScale = 2.4;
  static const double oldFrom = 1.7;
  static const double stageTremble = 1.4;
  static const cut = BladeSpec(
    from: Offset(0, 51.22),
    to: Offset(82, 30.78),
    width: 0,
    core: 0,
    widest: 0,
    outline: 0,
    slide: 18,
    gap: 8,
    turnDeg: 8,
    fadeFrom: 0.35,
  );
  static const Size bladeBox = Size(360, 200);
  static const blade = BladeSpec(
    from: Offset(15, 100),
    to: Offset(335.2, 20.2),
    width: 18,
    core: 0.42,
    widest: 0.7,
    outline: Strokes.label,
    slide: 0,
    gap: 0,
    turnDeg: 0,
    fadeFrom: 0,
  );
  static const String slash = 'ズバッ!!';
  static const double slashFont = 40;
  static const int slashSeed = 17;
  static const Offset slashAt = Offset(-170, -190);
  static const double slashTurnDeg = -10;
  static const double dropFrom = 3;
  static const double dropTurnDeg = -20;
  static const String splat = 'assets/graphics/sidetrips/ui/rank-splash.webp';
  static const Size splatSize = Size(380, 296);
  static const double splatRest = 0.36;
  static const String hit = 'ドン!!';
  static const double hitFont = 58;
  static const int hitSeed = 29;
  static const String reveal = 'ジャン!!';
  static const double revealFont = 50;
  static const int revealSeed = 23;
  static const Offset sfxAt = Offset(-24, -196);
  static const double sfxTurnDeg = 10;
  static const double impactJolt = 10;
  static const int impactSteps = 11;
  static const int impactSeed = 71;

  /// A rank down: the crack ([crack]) where the line goes through the
  /// class line, [lineCrack] wide, [lineCrackAt] off it, reaching no more
  /// than [lineCrackOverhang] past the plot's right; ガーン!! ([shock],
  /// [shockFont], [shockSeed]) dropping to [shockAt] from the badge's top
  /// left, turned [shockTurnDeg]; the box jolts [knockJolt] ([knockSteps],
  /// [knockSeed]), the [gloom] comes down, and the badge cracks
  /// ([badgeCrack] wide, [badgeCrackAt] from its left middle, turned
  /// [badgeCrackTurnDeg]); the class falls [fallDrop] turning
  /// [fallTurnDeg], and the lower one drops in from [dropIn] with a thud
  /// ([thudJolt], [thudSteps], [thudSeed]).
  static const String crack = 'assets/graphics/sidetrips/ui/rank-crack.webp';
  static const double lineCrack = 110;
  static const Offset lineCrackAt = Offset(-55, -17);
  static const double lineCrackOverhang = 6;
  static const String shock = 'ガーン!!';
  static const double shockFont = 46;
  static const int shockSeed = 37;
  static const Offset shockAt = Offset(40, -64);
  static const double shockTurnDeg = -6;
  static const double knockJolt = 6;
  static const int knockSteps = 7;
  static const int knockSeed = 73;
  static const gloom = GloomSpec(
    colors: [Color(0x99141414), Color(0x00141414)],
    reach: 0.6,
    count: 44,
    seed: 7,
    shortest: 0.18,
    longest: 0.5,
    thinnest: 1.2,
    thickest: 3.4,
    line: Color(0xB3141414),
  );
  static const double badgeCrack = 96;
  static const Offset badgeCrackAt = Offset(-7, -14);
  static const double badgeCrackTurnDeg = -8;
  static const double fallDrop = 170;
  static const double fallTurnDeg = 18;
  static const double dropIn = -110;
  static const double thudJolt = 3;
  static const int thudSteps = 4;
  static const int thudSeed = 79;

  /// The class change's sticker on the badge's corner, [stickerAt] from
  /// its top left, turned [stickerTurnDeg]: 昇級! in sun on ink with a sun
  /// [stickerShadow], 降級 in ink on paper; at [stickerFont] (so) inside
  /// [stickerPadding], edged [stickerBorder]. The first class's NEW tag
  /// turns [newTurnDeg].
  static const Offset stickerAt = Offset(-10, -12);
  static const double stickerTurnDeg = -10;
  static const Offset stickerShadow = Offset(2, 2);
  static const double stickerFont = 15;
  static const EdgeInsets stickerPadding = EdgeInsets.fromLTRB(7, 4, 7, 5);
  static const double stickerBorder = Strokes.control;
  static const double newTurnDeg = -6;

  /// Where parts turn and grow from: titles a little under their middle,
  /// tags and lettering toward their start, the rating toward its foot.
  static const Alignment titleOrigin = Alignment(0, 0.2);
  static const Alignment tagOrigin = Alignment(-0.4, 0);
  static const Alignment sfxOrigin = Alignment(-0.4, 0);
  static const Alignment ratingOrigin = Alignment(-0.4, 0.2);
}

/// When the rank change page moves (mock B's timing around the count the
/// user asked for), each from the page's start unless said otherwise.
///
/// The opening: the [title] slams in; the card's halves slide in over
/// [halves] from [cardAt] as the card grows over [cardGrowShare] of that,
/// and meet with a jolt at [clashAt] ([clash]), the VS tag popping
/// ([vsPop]); the [box] rises.
///
/// The heart of the page is the count: this match's point runs to its
/// place on the curve (the diamond along the line, the rating counting,
/// the bar filling, up or down) over [run] on [runCurve], an ease in and
/// out: slow at the start, fast in the middle, slow into the landing.
/// Every rating point it passes ticks, so the ticks come slowly, rush and
/// slow again; ticks closer than [tickSpacing] to the last (or to the
/// landing) are left out, never a mush. It starts at [runAt] after a loss;
/// after a win the points first pop off Tobi's plate ([chipPopAt],
/// [chipPop]) and fly to the curve from [chipFlyAt], the run starting
/// as they arrive ([winRunAt]). After a loss they go to Tobi once the point
/// has landed: they pop [chipAfterLand] after the landing and fly from
/// [chipFlyAfter] after that for [chipFly]. The diamond swells as they reach
/// it ([chipSwell]) and Tobi's plate as they leave or arrive
/// ([plateSwell]); this match's slot shows a guide fading in over
/// [guideIn] once the box has risen.
///
/// The landing: the diamond pulses ([landPulse]) with a burst ([burst]),
/// the box jolts ([landJolt]), the change tag stamps on [tagAfterLand]
/// after it ([tag]) and the button pops ([cta]) [ctaAfterLand] after a
/// win's landing or [ctaAfterChip] after the chip of a loss reaches Tobi;
/// the page rests [endAfterCta] later. Beaten Tobi trembles a step every
/// [tobiStep].
///
/// A rank up, at the crossing: the page darkens ([darken]), ゴゴゴ comes in
/// [rumbleAfter] the crossing ([rumblePop], shaking every [rumbleStep]),
/// heartbeats at [beats] (each [beatPulse]), then the break [breakAfter]
/// the crossing: the dark lifts ([lift]) and the page flashes ([flashIn],
/// [flashHold], [flashOut]), the mark pops ([markPop]) and the diamond
/// swells ([breakPulse]); the run goes on to its landing. It cuts to the
/// impact frame [cutAfterBreak] after the break or [cutAfterLand] after
/// the landing, whichever comes later. From the cut: the old class pops
/// up ([oldPop]) trembling every [trembleStep], the blade cuts at
/// [slashAfterCut] ([slash], fading over [slashFade]; ズバッ!!
/// [slashSfxAfterCut], [slashSfx]), the halves part from [splitAfterCut]
/// ([split]), the new class drops from [stampAfterCut] and hits at
/// [impactAfterCut]: the splat ([splat]), ドン!! [sfxAfterImpact] later
/// ([sfx]), the frame's jolt ([impactJolt]) and title ([title]). It
/// settles back into the page from [settleAfterCut] ([settle]); the class
/// change shows at [labelAfterCut] ([label]), the change tag at
/// [tagAfterCut] and the button at [ctaAfterCut].
///
/// A rank down, at the crossing: the class line cracks ([crack]),
/// ガーン!! drops [shockAfterCrack] after it ([shock]), the hit comes
/// [hitAfterCrack] after it (the box's jolt [hitJolt], the [gloom], the
/// badge's crack), the class falls from [fallAfterCrack] ([fall]) and the
/// lower one drops in from [dropAfterCrack], landing [thudAfterCrack]
/// after it ([thud]). The class change, the change tag and the points to
/// Tobi follow [labelAfterThud] after the thud or [tagAfterLand] after the
/// landing, whichever comes later; ガーン!! lifts then ([shockLift]).
///
/// The placement: the match's slot is stamped ([slotStamp]) with its tag.
/// The last one then holds a drumroll: [suspenseAfterLand] after a won
/// landing (or [suspenseAfterChip] after a lost one's chip) the page dims
/// ([dim]) under heartbeats at [suspenseBeats]; [revealAfterSuspense] in
/// the class shows with a flash, the dashed estimate turning solid and the
/// class's band filling ([bandFill]); it cuts to the impact frame
/// [cutAfterReveal] later, the class landing [placedImpactAfterCut] after
/// the cut and settling from [placedSettleAfterImpact] after that; the
/// rating, NEW and the bar ([gauge], from [gaugeAfterLabel]) show
/// [labelAfterSettle] after it, ここから [hereAfterLabel] ([here]), the
/// button [placedCtaAfterLabel].
abstract final class IkkiuchiRankMotion {
  static const title = EntranceSpec(EntranceFrom(scale: 2.2, opaqueAt: 0.3),
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.springy);
  static const cardAt = Duration(milliseconds: 150);
  static const halves = Duration(milliseconds: 380);
  static const double cardGrowShare = 0.6;
  static const clashAt = Duration(milliseconds: 470);
  static const clash = Duration(milliseconds: 260);
  static const vsPop = EntranceSpec(EntranceFrom(scale: 0.3),
      duration: Duration(milliseconds: 300), delay: clashAt, curve: Entrances.bouncy);
  static const box = EntranceSpec(EntranceFrom(offset: Offset(0, 24)),
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 300), curve: Entrances.glide);

  /// The count and its ticks, which it follows step for step. The first tick
/// comes [firstTickAt] into it and the last one [landingGap] before the
/// landing. The gaps
  /// between ticks start long and shrink: [tickSlowGaps] (the first ones),
  /// then [tickRampGaps] down to [tickRushGap], the rush, and the same
  /// mirrored into the landing. A change of more points than [maxTicks]
  /// ticks [maxTicks] times; one of fewer ticks once per point, with the
  /// long ends kept. The count's length is the sum of the gaps.
  /// Halfway between the first 3 s cubic count and the long-ended one.
  static const firstTickAt = Duration(milliseconds: 310);
  static const List<Duration> tickSlowGaps = [
    Duration(milliseconds: 540),
    Duration(milliseconds: 430),
    Duration(milliseconds: 290),
  ];
  static const List<Duration> tickRampGaps = [
    Duration(milliseconds: 160),
    Duration(milliseconds: 105),
    Duration(milliseconds: 80),
  ];
  static const tickRushGap = Duration(milliseconds: 65);
  static const landingGap = Duration(milliseconds: 710);
  static const maxTicks = 20;
  static const runAt = Duration(milliseconds: 1000);
  static const winRunAt = Duration(milliseconds: 1400);
  static const chipPopAt = Duration(milliseconds: 800);
  static const chipFlyAt = Duration(milliseconds: 1050);
  static const chipPop = Duration(milliseconds: 250);
  static const chipAfterLand = Duration(milliseconds: 50);
  static const chipFlyAfter = Duration(milliseconds: 200);
  static const chipFly = Duration(milliseconds: 350);
  static const chipSwell = Duration(milliseconds: 260);
  static const plateSwell = Duration(milliseconds: 300);
  static const guideIn = Duration(milliseconds: 300);

  static const landPulse = Duration(milliseconds: 380);
  static const burst = Duration(milliseconds: 450);
  static const landJolt = Duration(milliseconds: 300);
  static const tagAfterLand = Duration(milliseconds: 50);
  static const tag = Duration(milliseconds: 350);
  static const ctaAfterLand = Duration(milliseconds: 400);
  static const ctaAfterChip = Duration(milliseconds: 200);
  static const cta = Duration(milliseconds: 400);
  static const endAfterCta = Duration(milliseconds: 450);
  static const tobiStep = Duration(milliseconds: 70);

  /// The same sound twice within this plays once (a thud and a stamp).
  static const soundGap = Duration(milliseconds: 150);

  static const darken = Duration(milliseconds: 400);
  static const rumbleAfter = Duration(milliseconds: 100);
  static const rumblePop = Duration(milliseconds: 200);
  static const rumbleStep = Duration(milliseconds: 40);
  static const List<Duration> beats = [
    Duration.zero,
    Duration(milliseconds: 350),
    Duration(milliseconds: 630),
  ];
  static const beatPulse = Duration(milliseconds: 220);
  static const breakAfter = Duration(milliseconds: 850);
  static const lift = Duration(milliseconds: 150);
  static const flashIn = Duration(milliseconds: 60);
  static const flashHold = Duration(milliseconds: 40);
  static const flashOut = Duration(milliseconds: 260);
  static const markPop = Duration(milliseconds: 300);
  static const breakPulse = Duration(milliseconds: 500);
  static const cutAfterBreak = Duration(milliseconds: 450);
  static const cutAfterLand = Duration(milliseconds: 350);
  static const oldPop = Duration(milliseconds: 200);
  static const trembleStep = Duration(milliseconds: 40);
  static const slashAfterCut = Duration(milliseconds: 200);
  static const slash = Duration(milliseconds: 90);
  static const slashFade = Duration(milliseconds: 240);
  static const slashSfxAfterCut = Duration(milliseconds: 220);
  static const slashSfx = Duration(milliseconds: 220);
  static const splitAfterCut = Duration(milliseconds: 290);
  static const split = Duration(milliseconds: 320);
  static const stampAfterCut = Duration(milliseconds: 410);
  static const impactAfterCut = Duration(milliseconds: 520);
  static const splat = Duration(milliseconds: 280);
  static const sfxAfterImpact = Duration(milliseconds: 20);
  static const sfx = Duration(milliseconds: 260);
  static const impactJolt = Duration(milliseconds: 400);
  static const settleAfterCut = Duration(milliseconds: 1050);
  static const settle = Duration(milliseconds: 420);
  static const labelAfterCut = Duration(milliseconds: 1250);
  static const label = Duration(milliseconds: 300);
  static const tagAfterCut = Duration(milliseconds: 1300);
  static const ctaAfterCut = Duration(milliseconds: 1550);

  static const crack = Duration(milliseconds: 120);
  static const shockAfterCrack = Duration(milliseconds: 50);
  static const shock = Duration(milliseconds: 150);
  static const hitAfterCrack = Duration(milliseconds: 200);
  static const hitJolt = Duration(milliseconds: 260);
  static const gloom = Duration(milliseconds: 360);
  static const fallAfterCrack = Duration(milliseconds: 500);
  static const fall = Duration(milliseconds: 380);
  static const dropAfterCrack = Duration(milliseconds: 650);
  static const thudAfterCrack = Duration(milliseconds: 790);
  static const thud = Duration(milliseconds: 200);
  static const labelAfterThud = Duration(milliseconds: 110);
  static const shockLift = Duration(milliseconds: 300);

  static const slotStamp = Duration(milliseconds: 300);
  static const suspenseAfterLand = Duration(milliseconds: 250);
  static const suspenseAfterChip = Duration(milliseconds: 50);
  static const dim = Duration(milliseconds: 300);
  static const List<Duration> suspenseBeats = [
    Duration(milliseconds: 50),
    Duration(milliseconds: 400),
    Duration(milliseconds: 680),
    Duration(milliseconds: 900),
  ];
  static const revealAfterSuspense = Duration(milliseconds: 1050);
  static const bandFill = Duration(milliseconds: 400);
  static const cutAfterReveal = Duration(milliseconds: 400);
  static const placedImpactAfterCut = Duration(milliseconds: 110);
  static const placedSettleAfterImpact = Duration(milliseconds: 540);
  static const labelAfterSettle = Duration(milliseconds: 200);
  static const gaugeAfterLabel = Duration(milliseconds: 50);
  static const gauge = Duration(milliseconds: 500);
  static const hereAfterLabel = Duration(milliseconds: 100);
  static const here = Duration(milliseconds: 300);
  static const placedCtaAfterLabel = Duration(milliseconds: 250);

  /// Where parts come in from: the change tag ([tagFrom]), NEW
  /// ([newFrom]), the points' chip and sound-effect lettering ([popFrom]),
  /// ドン!! and ジャン!! ([hitFrom]), the sticker ([stickerFrom]), ガーン!!
  /// ([shockFrom], in [shockSteps]), a crack ([crackFrom] times as big, in
  /// [crackSteps]); lettering pops in [sfxSteps]. The lower class shows
  /// once [dropShow] of its drop is done, the new class on the stage once
  /// [stampShow] of its; the first class's bar shows over [gaugeShow] and
  /// the class change's label rises [labelRise] into place. The gloom
  /// comes down in [gloomSteps].
  static const tagFrom = EntranceFrom(scale: 2, turnDeg: -10, opaqueAt: 0.2);
  static const newFrom = EntranceFrom(scale: 2.4, turnDeg: -16, opaqueAt: 0.2);
  static const popFrom = EntranceFrom(scale: 0.3);
  static const hitFrom = EntranceFrom(scale: 0.2);
  static const stickerFrom = EntranceFrom(scale: 2.6, turnDeg: -20, opaqueAt: 0.2);
  static const shockFrom = EntranceFrom(offset: Offset(0, -90), opaqueAt: 0.3);
  static const shockSteps = StepCurve(3);
  static const double crackFrom = 1.3;
  static const crackSteps = StepCurve(2);
  static const sfxSteps = StepCurve(3, Entrances.bouncy);
  static const double dropShow = 0.2;
  static const double stampShow = 0.05;
  static const gaugeShow = Duration(milliseconds: 200);
  static const double labelRise = 8;
  static const gloomSteps = StepCurve(6);
}
