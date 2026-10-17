part of '../design.dart';

/// Play, mid-run (spec phone 4).
abstract final class PlayLayout {
  static const double toneBandHeight = 230;

  static const double chipHeight = 48;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(14, 0, 15, 0);
  static const double chipRadius = 24;
  static const double chipKanaFont = 23;
  static const double chipBracketFont = 20;
  static const double chipTimeFont = 15;
  static const double chipTimeUnitFont = 12;
  static const double chipGap = 6;
  static const Size chipTail = Size(13, 13);
  static const Offset chipTailAt = Offset(24, 6);
  static const Duration chipBumpDuration = Duration(milliseconds: 260);
  static const double chipBumpScale = 1.08;

  static const double counterHeight = 48;
  static const EdgeInsets counterPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double counterNumberFont = 28;
  static const double counterSlashFont = 15;
  static const double counterOutline = 1.2;
  static const double counterGap = 6;

  static const double buttonRowHeight = 62;
  static const double buttonGap = 14;
}

/// The start card on top of every run's deck (`StartCard`), drawn in the
/// torifuda's card units (374 × 525) and scaled to the card's size.
abstract final class StartCardStyle {
  static const Size size = Size(374, 525);
  static const double radius = 12;

  /// The lacquer's soft glow, brightest at [glowCenter] (an [Alignment]).
  static const Alignment glowCenter = Alignment(-0.35, -0.6);
  static const double glowRadius = 1.25;

  /// The gold frame: a heavy outer line and a fine inner one, with gold
  /// brackets in the inner corners.
  static const double outerFrameInset = 13;
  static const double outerFrameWidth = 4.5;
  static const double innerFrameInset = 23;
  static const double innerFrameWidth = 1.6;
  static const double cornerBracket = 24;
  static const double cornerBracketWidth = 3;
  static const double cornerBracketInset = 5;
  static const List<Color> goldLeaf = [Palette.goldLight, Palette.gold, Palette.goldDeep, Palette.gold];

  static const EdgeInsets padding = EdgeInsets.fromLTRB(40, 40, 40, 38);
  static const double titleFont = 25;
  static const double titleTracking = 0.7;
  static const double titleRule = 58;
  static const double titleRuleGap = 12;
  static const double titleGap = 16;

  /// The 序歌 in 散らし書き (scattered writing): five columns, right to
  /// left, each dropped by its share of a character from the top.
  static const double jokaFont = 42;
  static const double jokaLineHeight = 1.06;
  static const double jokaColumnGap = 13;
  static const List<double> jokaDrops = [0, 1.15, 0.35, 1.5, 0.75];

  /// The seal pressed beside the poem's last column, [sealDrop]
  /// characters down.
  static const String sealText = '飛';
  static const double seal = 42;
  static const double sealRadius = 5;
  static const double sealDrop = 5.2;
  static const double sealFont = 27;
  static const double sealTurnDeg = -6;

  /// The vermilion band with the greeting and the swipe cue.
  static const double bandGap = 18;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(10, 12, 10, 12);
  static const double bandRule = 1.4;
  static const double greetingFont = 27;
  static const double cueGap = 6;
  static const double cueFont = 14;
  static const double cueTracking = 0.26;
  static const String cueMarks = '›';
  static const double cueMarkGap = 10;

  /// A glint sweeping across the lacquer every [sheenPeriod], taking
  /// [sheenSweep] to cross; frozen off the card under reduced motion.
  static const Duration sheenPeriod = Duration(milliseconds: 3600);
  static const Duration sheenSweep = Duration(milliseconds: 1200);
  static const double sheenWidth = 120;
  static const double sheenTurnDeg = 24;
  static const double sheenAlpha = 0.2;
}

/// The tutorial round's practice cards (`TestCard`): a TV test pattern
/// crossed with a karuta card, in the torifuda's card units (374 × 525).
abstract final class TestCardStyle {
  static const Size size = Size(374, 525);
  static const double radius = 12;

  /// Each card's big kana, one per card of the round: テ, ス, ト.
  static const List<String> kana = ['テ', 'ス', 'ト'];

  /// The colour bars (75% SMPTE), then the thin strip of reversed bars
  /// under them.
  static const List<Color> bars = [
    Color(0xFFC0C0C0),
    Color(0xFFC0C000),
    Color(0xFF00C0C0),
    Color(0xFF00C000),
    Color(0xFFC000C0),
    Color(0xFFC00000),
    Color(0xFF0000C0),
  ];
  static const List<Color> reverseBars = [
    Color(0xFF0000C0),
    Palette.ink,
    Color(0xFFC000C0),
    Palette.ink,
    Color(0xFF00C0C0),
    Palette.ink,
    Color(0xFFC0C0C0),
  ];
  static const double inset = 12;
  static const double barsHeight = 318;
  static const double reverseBarsHeight = 30;

  /// The test pattern's circle, with the kana on its crosshair.
  static const Offset circleCenter = Offset(187, 176);
  static const double circleRadius = 112;
  static const double circleStroke = 6;
  static const double crosshairStroke = 2.5;

  /// The inner ring's radius, as a share of the circle's.
  static const double innerRing = 0.68;
  static const double kanaFont = 150;

  /// The channel bug in the bars' lower-left corner (the play chrome
  /// covers the card's top corners).
  static const String channel = 'TOBI TV';
  static const Offset channelAt = Offset(22, 290);
  static const EdgeInsets channelPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double channelFont = 15;

  /// The label under the bars.
  static const String title = '練習札';
  static const String sub = 'TEST CARD';
  static const double titleFont = 44;
  static const double subFont = 14;
  static const double subTracking = 0.3;
  static const double numberFont = 30;
  static const EdgeInsets labelPadding = EdgeInsets.fromLTRB(26, 0, 26, 8);
}

/// The tutorial round's coach: Tobi below the card with a balloon
/// (`TutorialCoach`).
abstract final class TutorialStyle {
  static const double tobiHeight = 104;
  static const double gap = 4;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(Gaps.gutter, Gaps.small, Gaps.gutter, 0);
  static const Alignment speaker = Alignment(-1.3, 0.35);
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(vertical: 4);
  static const double font = 14;
  static const Duration linePop = Duration(milliseconds: 220);
  static const double linePopFrom = 0.8;
}

/// Tobi's tour of Home (`TourOverlay`): a greyed-out screen with a
/// spotlight, Tobi large with a balloon, a spray of hand-scribbled arrows
/// and a marquee arrow with chasing bulbs, all pointing at the spot.
abstract final class TourStyle {
  /// The greyed-out wall: lighter near the spotlight, darker at the edges,
  /// fading over [dimReach] of the screen's longer side.
  static const Color dimNear = Color(0xDCD6D9DD);
  static const Color dimFar = Color(0xF0868C94);
  static const double dimReach = 0.95;

  /// The spotlight: its margin around the spot, corner radius, and a paper
  /// ring with an ink line around it.
  static const double spotPad = 6;
  static const double spotRadius = 10;
  static const double spotRing = 7;
  static const double spotInk = 3;

  /// Gaps between the spotlight, the marquee and Tobi's block.
  static const double gap = 10;

  /// Tobi's block (Tobi and his balloon): beside the balloon, at most
  /// [block] tall and at least [blockMin] where room is short; from
  /// [stackAt] up, under a full-width balloon instead, [blockStacked] tall
  /// beside a spotlight with room for it and [blockTall] with none. Tobi
  /// takes [besideTobi] of the block's height beside the balloon, and
  /// [stackedTobi] under it.
  static const double block = 196;
  static const double blockMin = 136;
  static const double stackAt = 250;
  static const double blockStacked = 320;
  static const double blockTall = 390;
  static const double besideTobi = 0.9;
  static const double stackedTobi = 0.56;
  static const Alignment speakerLeft = Alignment(-1.22, 0.38);
  static const Alignment speakerRight = Alignment(1.22, 0.38);
  static const Alignment speakerBelowLeft = Alignment(-0.62, 1.25);
  static const Alignment speakerBelowRight = Alignment(0.62, 1.25);
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 2);
  static const double font = 15.5;
  static const double hintFont = 11.5;
  static const double hintGap = 5;

  /// The Skip button, beside Back at the top left.
  static const double skipGap = 8;
  static const EdgeInsets skipPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double skipFont = TypeScale.button;
  static const Duration pop = Duration(milliseconds: 380);
  static const double popFrom = 0.6;

  /// Hand-scribbled arrows around the spotlight: up to [scribbles] of
  /// them, [scribbleMin]–[scribbleMax] px long, their tips on
  /// [scribbleRings] (px off the spotlight), turned up to
  /// [scribbleTurnDeg] off square.
  static const int scribbles = 10;
  static const double scribbleMin = 40;
  static const double scribbleMax = 66;
  static const List<double> scribbleRings = [14, 44, 76];
  static const double scribbleTurnDeg = 30;
  static const double scribbleMargin = 9;
  static const List<double> scribbleAlongTop = [0.1, 0.3, 0.5, 0.7, 0.9];
  static const List<double> scribbleAlongSide = [0.25, 0.5, 0.75];

  /// How one is drawn: two marker passes [scribblePass] px apart (the
  /// second thinner), a shaft
  /// bent by up to [scribbleBend] px and a head of two strokes.
  static const Color scribbleInk = Palette.alarm;
  static const double scribbleWidth = 3.8;
  static const double scribbleWidthThin = 2.6;
  static const double scribblePass = 1.7;
  static const double scribbleBend = 7;
  static const double scribbleHead = 19;
  static const double scribbleHeadDeg = 27;

  /// Stop-motion boil: the lines are redrawn every [boil], cycling through
  /// [boilFrames] drawings, each wobbling by up to [boilJitter] px.
  static const Duration boil = Duration(milliseconds: 120);
  static const int boilFrames = 3;
  static const double boilJitter = 1.8;

  /// Each arrow stamps in over [scribbleIn] from [scribbleInFrom] of its
  /// size, [scribbleStagger] after the one before, then jabs at the spot by
  /// [jab] px every [jabPeriod].
  static const Duration scribbleIn = Duration(milliseconds: 170);
  static const Duration scribbleStagger = Duration(milliseconds: 45);
  static const double scribbleInFrom = 1.6;
  static const Duration jabPeriod = Duration(milliseconds: 700);
  static const double jab = 5;

  /// The marquee arrow: a fat red arrow [marqueeLength] long with a head
  /// [marqueeHead] long and [marqueeHeadHeight] tall on a [marqueeBody]
  /// tall body, placed [marqueeShift] px to one side of the spot's centre
  /// in a band [marqueeRoom] tall.
  static const double marqueeLength = 132;
  static const double marqueeHead = 50;
  static const double marqueeHeadHeight = 76;
  static const double marqueeBody = 40;
  static const double marqueeStroke = 3;
  static const double marqueeRoom = 150;
  static const double marqueeShift = 72;
  static const Color marqueeFill = Palette.alarmDeep;
  static const double marqueeFont = 16;

  /// The label is only on a marquee within this of level, so it reads.
  static const double marqueeLabelMaxDeg = 50;

  /// Its light bulbs, [bulbPitch] px apart just inside its outline; every
  /// [chaseEvery]th is lit, and the lit ones move on every [chase].
  static const double bulb = 3.2;
  static const double bulbGlow = 6.5;
  static const double bulbPitch = 12.5;
  static const double bulbInset = 7;
  static const Color bulbOn = Palette.goldLight;
  static const Color bulbOff = Color(0xFF5A3714);
  static const Color bulbHalo = Color(0x66FFE9A0);
  static const Duration chase = Duration(milliseconds: 90);
  static const int chaseEvery = 3;

  /// The typed-out line's still-to-come tail: laid out like the rest, just
  /// invisible, so the balloon never resizes as it types.
  static const Color typingHidden = Color(0x00000000);

  /// The balloon's continue control (steps with nothing to tap): faded out
  /// and untappable until the line has finished typing.
  static const Duration continueFade = Duration(milliseconds: 200);
}

/// Free practice (始める): its setup sheet (`free_practice_sheet.dart`), the
/// island / card / 友札 pickers behind it, and the balloon of its lock.
abstract final class FreePracticeLayout {
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const double sheetCut = 14;
  static const Placement tobi = Placement(right: 18, top: -66, size: Size(78, 93));
  static const double title = 30;
  static const double deckFont = 14;
  static const double deckNumber = 22;
  static const double titleGap = 2;

  /// The island / card / 友札 rows.
  static const double rowMinHeight = 46;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(12, 6, 10, 6);
  static const double rowLabelFont = 15;
  static const double rowValueFont = 13.5;
  static const double rowChevron = 16;
  static const double rowGap = 6;

  /// 隠し字's level chips.
  static const double maskChip = 31;
  static const double maskChipFont = 14;
  static const double maskGap = 4;
  static const double maskNoteFont = 12.5;

  /// The counts / custom strip above the start button.
  static const EdgeInsets statusPadding = EdgeInsets.fromLTRB(10, 7, 8, 8);
  static const double statusNoteFont = 12.5;
  static const double resetMinHeight = 34;
  static const EdgeInsets resetPadding = EdgeInsets.symmetric(horizontal: 9, vertical: 4);
  static const double resetIcon = 15;
  static const double resetFont = 13;
  static const double shoutHeight = 64;
  static const Color barrier = Color(0x8C141414);

  /// Pickers: the header count, hint, section titles and the footer buttons.
  static const double hintFont = 12.5;
  static const double sectionFont = 18;
  static const double sectionGap = 14;
  static const double footerMinHeight = 48;
  static const double footerFont = 15;

  /// A card chip (its kimariji), in the card and 友札 pickers.
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(9, 5, 9, 6);
  static const double chipFont = 16;
  static const double chipSmallFont = 13.5;
  static const EdgeInsets chipSmallPadding = EdgeInsets.fromLTRB(7, 3, 7, 4);
  static const double chipMinHeight = 40;
  static const double chipGap = 6;

  /// The all / some / none box of an island or 友札 set.
  static const double coverageBox = 28;
  static const double coverageIcon = 20;
  static const Size coverageDash = Size(12, 3.5);
  static const EdgeInsets setRowPadding = EdgeInsets.fromLTRB(10, 8, 10, 8);

  /// The island picker's legend.
  static const double legendDot = 12;
  static const double legendFont = 12;
  static const double legendGap = 12;

  static const Size lockBalloon = Size(270, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);
}
