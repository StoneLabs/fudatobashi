part of '../design.dart';

/// 暗記練's rules sheet (遊び方, `ankiren_rules_sheet.dart`): its three steps
/// in pictures with a line on each, then the rules and the scoring as
/// lists, each line with the other language's under it.
abstract final class AnkirenRulesLayout {
  static const String memorise = 'assets/images/sidetrips/ankiren/howto-memorize.webp';
  static const String flip = 'assets/images/sidetrips/ankiren/howto-flip.webp';
  static const String take = 'assets/images/sidetrips/ankiren/howto-take.webp';

  /// The scoring rules print a share of the points to this many decimal
  /// places at most.
  static const int shareDecimals = 2;

  /// A step: its picture on desk grey, then its number and name, then its
  /// line.
  static const double pictureHeight = 90;
  static const double pictureBorder = Strokes.label;
  static const double stepGap = 6;
  static const double stepInnerGap = 5;
  static const double stepFont = 14;
  static const double numberBox = 18;
  static const double numberFont = 11;
  static const double stepLineFont = 12;
  static const double stepSubFont = 11;
  static const double lineHeight = 1.35;

  /// A list row: a marked box, then the line.
  static const double markBox = 28;
  static const double markBorder = Strokes.label;
  static const double markFont = 12;
  static const double markIcon = 17;
  static const double markIconStroke = 2.6;
  static const double markGap = 10;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 8);
  static const double ruleLineFont = 13;
  static const double ruleSubFont = 11.5;

  /// A table under a rule's line: points by where a tap lands.
  static const double belowGap = 6;
  static const EdgeInsets tierCellPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 4);
  static const double tierHeadFont = 11;
  static const double tierFont = 12.5;
  static const double tierSubFont = 10.5;
}

/// 暗記練's play screen (`lib/ui/ankiren/`): the field scaled into the screen
/// like the layout mock (`research/design/ankiren_layouts.html`), the band
/// across its centre, and the cards' backs and feedback.
abstract final class AnkirenPlayLayout {
  /// Kept clear around the field.
  static const double padding = 6;

  /// The centre band's height: in portrait, and in landscape, where it
  /// widens the real field's gap between the halves.
  static const double bandPortrait = 72;
  static const double bandLandscape = 40;

  /// A card is never drawn wider than [maxCardW] (portrait), and zoom never
  /// lets one get narrower than [minTapCardW], a comfortable tap.
  static const double maxCardW = 80;
  static const double minTapCardW = 48;

  /// Dev mode's scoring readout (the play overlay) has room of its own, so
  /// it never hides a card: a strip [readoutStrip] tall above the field in
  /// portrait, a column [readoutColumn] wide beside it in landscape. It is
  /// scaled down should it not fit.
  static const double readoutStrip = 158;
  static const double readoutColumn = 236;

  static const Color background = Palette.desk;

  /// A face-down card: a plain back in the torifuda's frame colour.
  static const Color backFill = Palette.cardFrame;
  static const Color backBorder = Palette.ink;
  static const double backBorderWidth = 1;

  /// Outlines over a card: just found, tapped wrongly, and (under reduced
  /// motion) shown after the wrong taps.
  static const Color rightGlow = Palette.land;
  static const Color wrongTint = Palette.alarm;
  static const double wrongTintOpacity = 0.75;
  static const Color revealGlow = Palette.sun;
  static const double glowWidth = 3;

  /// The band: a paper strip between ink rules, its controls inset.
  static const Color bandColor = Palette.paper;
  static const double bandRule = Strokes.panel;
  static const EdgeInsets bandPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const EdgeInsets bandPaddingLandscape = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double bandGap = 8;

  /// Each of the band's two control slots, either side of its centre.
  static const double sideSlot = 96;
  static const double timerFont = 34;
  static const double timerFontLandscape = 24;
  static const double promptFont = 32;
  static const double promptFontLandscape = 24;
  static const double labelFont = 12;
  static const double labelTracking = 0.14;
  static const double countFont = 13;
  static const double controlFont = 14;
  static const double controlIcon = 18;
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(horizontal: 8);

  /// The kimariji just found, or just given up, while the next prompt
  /// waits.
  static const Color foundText = Palette.landDeep;
  static const Color givenUpText = Palette.violetDeep;

  /// The tatami behind the field: a seamless tile drawn for [tatamiScale]×
  /// density, on [background] until it loads.
  static const String tatami = 'assets/images/ankiren/tatami.webp';
  static const double tatamiScale = 3;
}

/// 暗記練's card animations.
abstract final class AnkirenMotion {
  /// A card turning over, both halves of the turn.
  static const Duration flip = Duration(milliseconds: 220);

  /// A right tap's glow fading out.
  static const Duration rightGlow = Duration(milliseconds: 650);

  /// A wrong tap: the tint fading out while the card shakes [wrongShakes]
  /// times, [wrongShakeReach] px to either side, settling.
  static const Duration wrongFlash = Duration(milliseconds: 450);
  static const int wrongShakes = 3;
  static const double wrongShakeReach = 5;

  /// The card shown after the wrong taps rumbles until it is tapped.
  static const double revealShakeReach = 4;
  static const Duration revealShakeStep = Duration(milliseconds: 50);
  static const int revealShakeSeed = 7;
}

/// 暗記練's results (`AnkirenResultsScreen`).
abstract final class AnkirenResultsLayout {
  static const double scoreFont = 56;
  static const double scoreOutline = 11;
  static const double scoreOfFont = 15;
  static const EdgeInsets splashPadding = EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: 18);
  static const double splashMinHeight = 190;
  static const Size tobi = Size(64, 76);
  static const double noteFont = 13;
}

/// 暗記練's sheets (`ankiren_free_sheet.dart`, `ankiren_rules_sheet.dart`):
/// free practice's floating panel, its top edge tilted, a head with the
/// close button, and for free play the level keys and the steppers.
abstract final class AnkirenSheetLayout {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 22, 14, 14);
  static const double gap = 12;

  /// The head: the title with its other-language sub, and a line under it.
  static const double titleFont = 26;
  static const double titleSubFont = 11;
  static const double titleSubTracking = 0.18;
  static const double lineFont = 12;
  static const double lineGap = 3;
  static const double headGap = 10;

  /// A section's label with its other-language sub.
  static const double labelFont = 13;
  static const double labelSubFont = 11;
  static const double labelSubTracking = 0.14;
  static const double labelGap = 6;

  /// The level keys, [keysPerRow] a row: the chosen one sun-lit with a
  /// thicker border, one the known cards cannot fill desk grey.
  static const int keysPerRow = 6;
  static const double keyGap = 5;
  static const double keyHeight = 50;
  static const double keyBorder = Strokes.control;
  static const double keyChosenBorder = 4;
  static const double keyFont = 19;
  static const double keySubFont = 11;
  static const double keyCustomFont = 11;
  static const double keyCustomSubFont = 9;
  static const double keyLabelGap = 4;
  static const EdgeInsets keyPadding = EdgeInsets.symmetric(horizontal: 2);

  /// − value +: a stepper beside its label, which gives way first.
  static const double stepperButton = 48;
  static const double stepperGap = 4;
  static const double stepperSignFont = 22;
  static const double stepperValueWidth = 84;
  static const double stepperValueFont = 24;
  static const double stepperUnitFont = 12;

  static const Size lockBalloon = Size(280, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);
}

/// 暗記練's page (`ankiren_page.dart`): the record strip, the last games or
/// placement, the next ranked game's panel with a preview of its field and
/// the ranked burst, then Home's button pair.
abstract final class AnkirenPageLayout {
  /// Between the page's blocks; above the next game's panel, whose tag
  /// rises [tagRise] over its top edge; and under the pair.
  static const double gap = 12;
  static const double nextTop = 8;
  static const double bottomGap = 12;

  /// A label in black type, its other-language sub in small tracked
  /// capitals.
  static const double labelFont = 11;
  static const double labelTracking = 0.14;
  static const double labelLineHeight = 1.2;
  static const double labelGap = 3;

  /// The record strip (History's): the class and the rating split by an
  /// ink rule, over the gauge to the next class.
  static const double stripCut = HistoryHeaderLayout.stripCut;
  static const EdgeInsets cellsPadding = EdgeInsets.fromLTRB(14, 9, 14 + stripCut, 8);
  static const double cellGap = 12;
  static const double stripFont = 26;
  static const double classSuffixFont = 16;
  static const double valueGap = 6;
  static const EdgeInsets gaugePadding = EdgeInsets.fromLTRB(11, 7, 12 + stripCut, 8);
  static const double gaugeFont = 12;
  static const double gaugeNumber = 15;
  static const double gaugeGap = 10;

  /// The last games or the placement games, in a panel: a heading, then a
  /// column a game, split by light rules.
  static const EdgeInsets gamesPadding = EdgeInsets.fromLTRB(10, 6, 10, 6);
  static const int lastGames = 5;
  static const double headFont = 14;
  static const double headGap = 6;
  static const double countFont = 12;
  static const double countNumber = 15;
  static const double linkFont = 12.5;
  static const double linkIcon = 14;
  static const double linkIconStroke = 3;
  static const double linkGap = 3;
  static const double linkUnderline = 2;
  static const double scoreFont = 17;
  static const double gameLevelFont = 11;
  static const double gameGap = 4;
  static const EdgeInsets gamePadding = EdgeInsets.fromLTRB(2, 2, 2, 3);
  static const Color lightRule = Color(0xFFC9C6BF);
  static const double lightRuleWidth = Strokes.hairline;

  /// A placement game still to play: its number in a dashed slot, both
  /// greyed.
  static const double slot = 26;
  static const double slotFont = 13;
  static const double slotBorder = Strokes.label;
  static const Color slotInk = Color(0xFF8A8A8A);
  static const Color todo = Color(0xFF6B6B6B);

  /// The next game's panel: the side trips' cut corner, its tag breaking
  /// the top edge, then the stats, the hint, the field and the burst.
  static const double tagRise = 13;
  static const double tagLeft = 18;
  static const EdgeInsets statsPadding = EdgeInsets.fromLTRB(15, 22, 14, 0);
  static const double statFont = 28;
  static const double statUnitFont = 15;
  static const double statSuffixFont = 13;
  static const double statGap = 3;
  static const EdgeInsets hintPadding = EdgeInsets.fromLTRB(15, 9, 14, 0);
  static const double hintFont = 12;
  static const double hintNumber = 14;
  static const double hintIcon = 15;
  static const double hintIconStroke = 2.6;
  static const double hintGap = 4;
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(6, 12, 6, 12);

  /// The field preview: the next game's shape, face down on the play
  /// screen's tatami, as big as the room left allows, cards at most
  /// [previewMaxCardW] wide; hidden below [previewMinHeight].
  static const EdgeInsets previewMargin = EdgeInsets.fromLTRB(14, 11, 14, 0);
  static const double previewMinHeight = 96;
  static const double previewBorder = Strokes.control;
  static const double previewPadding = 10;
  static const double previewBand = 9;
  static const double previewBandRule = Strokes.label;
  static const double previewBandGap = 7;
  static const double previewMaxCardW = 30;
  static const Color previewGround = Color(0xFF99A083);
}

/// 暗記練's rating page (`AnkirenRatingOverlay`): its rank flag hoisted up a
/// flagpole whose height is the class, the bottom its threshold and the
/// finial the next class's. Over it the reading (the old rating, the new
/// one counting, the change) or the placement slots; under it what's left
/// to the next class, with Tobi.
abstract final class AnkirenRatingLayout {
  /// A rise, a reveal or a breakthrough: a sea page with a light glow and
  /// streaks rising; a fall: a calmer, lighter page with neither.
  static const Color color = Palette.sea;
  static const Alignment glowAt = Alignment(0.1, -0.1);
  static const List<Color> glowColors = [Color(0xFFDDF1FF), Color(0xFF7CC4FF), Palette.sea];
  static const List<double> glowStops = [0, 0.45, 1];
  static const tone = ToneSpec(dot: Color(0xFF1E86E6), radius: 1.5, spacing: 6);
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.55, 1];
  static const streaks = SpeedLinesSpec(count: 40, seed: 29, fromEdge: true, color: Color(0x73FFFFFF));
  static const Color calmColor = Palette.shallow;
  static const List<Color> calmGlowColors = [Palette.paper, Color(0xFFD6EEFF), Palette.shallow];
  static const calmTone = ToneSpec(dot: Color(0xFF8CCBFA), radius: 1.3, spacing: 6);

  /// The title: display lettering, sun for a rise, paper for a fall.
  static const double topGap = 4;
  static const double titleFont = 72;
  static const double titleOutline = 9;
  static const double bandInset = 44;
  static const double bandFont = 18;
  static const double bandTracking = 0.24;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 6, 8, 7);
  static const double bandTurnDeg = -2;
  static const double headGap = 10;

  /// The reading: the old rating, an arrow, the new one counting in big
  /// lettering, and the change slapped on its corner as it lands.
  static const double readingFont = 56;
  static const double readingOutline = 9;
  static const double oldFont = 22;
  static const double arrowFont = 20;
  static const double readingGap = 8;
  static const double changeFont = 20;
  static const EdgeInsets changePadding = EdgeInsets.fromLTRB(8, 2, 8, 4);
  static const double changeTurnDeg = -6;
  static const Offset changeAt = Offset(-6, -14);
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(150, 70), count: 40, innerMin: 50, innerMax: 70, width: 5, seed: 33);
  static const Size impactSize = Size(300, 140);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.3;
  static const double landPulse = 0.14;

  /// The placement slots: one panel a game, its number over its score, the
  /// games played stamped done; those to come dashed, the next one marked.
  static const double slotHeight = 64;
  static const double slotGap = 8;
  static const double slotLabelFont = 11;
  static const double slotLabelTracking = 0.14;
  static const double slotScoreFont = 24;
  static const double slotTodoFont = 22;
  static const double slotBorder = Strokes.control;
  static const Color slotInk = Color(0xFF6B6B6B);

  /// The stamp overhangs a played slot's top right corner by [stampAt],
  /// at [stampScale] of its size.
  static const Offset stampAt = Offset(-7, -9);
  static const double stampScale = 0.72;

  /// The stage: the flagpole's art (its box in pole units, scaled to the
  /// stage's height), its centre at [poleAt] of the stage's width.
  static const String pole = 'assets/images/sidetrips/ui/flagpole.webp';
  static const Size poleBox = Size(64, 440);
  static const double poleCentre = 32;
  static const double poleWidth = 7;
  static const double poleAt = 0.27;

  /// The cloth's frames, cycled in the wind: their box, where their rings
  /// meet the pole, and the calm field the class is written in, all in the
  /// art's own units; on the stage the cloth is [clothScale] times the
  /// pole's scale.
  static const List<String> cloth = [
    'assets/images/sidetrips/ui/rank-cloth-0.webp',
    'assets/images/sidetrips/ui/rank-cloth-1.webp',
    'assets/images/sidetrips/ui/rank-cloth-2.webp',
  ];
  static const Size clothBox = Size(168, 84);
  static const double clothPole = 5;
  static const Rect clothText = Rect.fromLTRB(30, 22, 122, 62);
  static const double clothScale = 1.25;
  static const double clothFont = 34;
  static const double clothSuffixFont = 22;
  static const String veiled = '?';

  /// The cloth's top travels from [hoistLow] (the floor) to [hoistHigh] (the
  /// finial: the next class), in pole units, its band clear of the collar
  /// and the base; the rating sits level with the band's top edge, [bandTop]
  /// into the cloth's box (art units).
  static const double hoistHigh = 15;
  static const double hoistLow = 311;
  static const double bandTop = 16;

  /// The veiled flag: the cloth drained of colour, with a question mark.
  static const List<double> veil = [
    0.33, 0.59, 0.11, 0, 12, //
    0.33, 0.59, 0.11, 0, 12,
    0.33, 0.59, 0.11, 0, 12,
    0, 0, 0, 1, 0,
  ];

  /// The scale left of the pole: the class's ends, the old rating with an
  /// arrow, and a class's line crossing the pole.
  static const double scaleFont = 13;

  /// An end of the class is left unlabelled when the old rating's mark
  /// comes this close to it.
  static const double scaleClear = 22;
  static const double tickLength = 8;
  static const double tickStroke = 2;
  static const double oldMarkFont = 15;
  static const double oldArrow = 9;
  static const double oldArrowGap = 4;
  static const double lineReach = 26;
  static const double lineStroke = 2.5;
  static const double lineDash = 5;
  static const double lineBadgeFont = 15;
  static const double lineBadgeSuffixFont = 10;

  /// The flag lands with バサッ!! over its fly end, kept on the page: its
  /// right edge [landSfxAt] in from the fly's (or the page's), and up from
  /// the cloth's top; or hanging from the cloth's bottom when the flag
  /// flies higher than [sfxBelowFrom] of the pole (ジャン!! too).
  static const String landSfx = 'バサッ!!';
  static const double landSfxFont = 26;
  static const int landSfxSeed = 18;
  static const double landSfxTurnDeg = 8;
  static const Offset landSfxAt = Offset(4, -34);
  static const double sfxBelowFrom = 0.55;

  /// The reveal: a white flash, ジャン!! over the flag ([revealSfxAt] of the
  /// way along it) and a burst behind it.
  static const double revealSfxAt = 0.4;
  static const String revealSfx = 'ジャン!!';
  static const double revealSfxFont = 38;
  static const int revealSfxSeed = 21;
  static const double revealSfxTurnDeg = -8;
  static const revealBurst = BurstSpec(
      box: revealSize, center: Offset(170, 170), count: 52, innerMin: 70, innerMax: 100, width: 5, seed: 37);
  static const Size revealSize = Size(340, 340);
  static const double revealFromScale = 0.5;
  static const double revealToScale = 1.4;

  /// The suspense before a reveal or a breakthrough: the page darkens and
  /// the title dims; on a breakthrough the flag strains against the finial.
  static const double darkness = 0.6;
  static const double dimTo = 0.35;
  static const double strainPush = 7;
  static const double strainJitter = 2;
  static const int rumbleSeed = 61;
  static const Color flash = Palette.paper;

  /// What's left to the next class, with Tobi at its right end.
  static const double stripGap = 10;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(12, 8, 70, 9);
  static const double stripFont = 16;
  static const double stripNumberFont = 24;
  static const Placement tobi = Placement(right: -2, bottom: 2, size: Size(64, 76));

  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// The 暗記練 rating page's timeline. The flag moves from [moveAt]: it
/// climbs, or sinks more slowly, and lands; on a breakthrough it strains
/// against the finial and the page flashes into the rank-up; on the last
/// placement game a drumroll ends in the reveal and the rating counts up.
abstract final class AnkirenRatingMotion {
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.springy);
  static const calmTitle =
      EntranceSpec(Entrances.up, duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.glide);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 350));
  static const head = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 450), curve: Entrances.springy);
  static const stage = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.glide);
  static const strip = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 650), curve: Entrances.glide);

  static const moveAt = Duration(milliseconds: 1000);
  static const climb = Duration(milliseconds: 1300);
  static const climbToTop = Duration(milliseconds: 1100);
  static const sink = Duration(milliseconds: 1700);
  static const Curve climbCurve = Curves.easeOutCubic;
  static const Curve sinkCurve = Curves.easeInOutCubic;

  /// The cloth flutters a frame every [flutter]; a class it sinks into
  /// fades in over [relabel].
  static const flutter = Duration(milliseconds: 170);
  static const relabel = Duration(milliseconds: 300);

  /// A ratchet click each time the rating goes up, at most this often.
  static const tickStep = Duration(milliseconds: 60);

  /// Landing: the reading pulses with a burst, the change and バサッ!! pop
  /// on, then the button.
  static const landPulse = Duration(milliseconds: 380);
  static const burst = Duration(milliseconds: 450);
  static const change = Duration(milliseconds: 400);
  static const changeAfter = Duration(milliseconds: 80);
  static const sfx = Duration(milliseconds: 400);
  static const tobi = Duration(milliseconds: 400);
  static const jolt = Duration(milliseconds: 300);
  static const double joltReach = 6;
  static const int joltSteps = 9;
  static const int joltSeed = 67;
  static const actionsAfter = Duration(milliseconds: 250);
  static const actions = Duration(milliseconds: 400);

  /// Placement: this game's slot pops in at [slotAt] and is stamped done at
  /// [stampAt]; the veiled flag climbs its step meanwhile.
  static const slotAt = Duration(milliseconds: 700);
  static const slot = Duration(milliseconds: 350);
  static const stampAt = Duration(milliseconds: 1150);
  static const stamp = Duration(milliseconds: 300);

  /// The drumroll before the reveal, with a heartbeat at each of [beats]
  /// after the flag stops; the reveal flashes white over [flashIn], holds,
  /// and fades over [flashOut], and the rating counts up over [count].
  static const List<Duration> beats = [
    Duration(milliseconds: 150),
    Duration(milliseconds: 600),
    Duration(milliseconds: 980),
    Duration(milliseconds: 1280),
  ];
  static const drumroll = Duration(milliseconds: 1500);
  static const beatPulse = Duration(milliseconds: 220);
  static const double beatScale = 0.03;
  static const flashIn = Duration(milliseconds: 110);
  static const flashHold = Duration(milliseconds: 60);
  static const flashOut = Duration(milliseconds: 420);
  static const countAfter = Duration(milliseconds: 250);
  static const count = Duration(milliseconds: 1100);
  static const Curve countCurve = Curves.easeOutCubic;

  /// A breakthrough: the flag strains against the finial with heartbeats,
  /// then the page flashes into the rank-up.
  static const strain = Duration(milliseconds: 1000);
  static const List<Duration> strainBeats = [Duration.zero, Duration(milliseconds: 420), Duration(milliseconds: 760)];
  static const strainPeriod = Duration(milliseconds: 140);
  static const rumbleStep = Duration(milliseconds: 40);
  static const Curve darken = Curves.easeIn;

  static const double hopHeight = 10;
  static const hopPeriod = Duration(milliseconds: 1000);
  static const double hopAirShare = 0.4;
}

/// 暗記練's own rank-up and rank-down pages (`AnkirenRankUpOverlay`,
/// `AnkirenRankDownOverlay`): a stage where the classes are fought out, in
/// its own units and scaled down to fit, and the result under it.
abstract final class AnkirenRankLayout {
  /// The rank-up's charge plays on a black page under a dark tone, white
  /// focus lines rushing in from [rushFrom] times their size onto
  /// [lines]' centre (about the stage's). From the impact on, the page is
  /// sea blue under a sun glow, the same lines boiling.
  static const Color night = Palette.ink;
  static const nightTone = ToneSpec(dot: Color(0xFF303030), radius: 1.6, spacing: 6);
  static const Color color = Palette.sea;
  static const Alignment glowAt = Alignment(0, -0.18);
  static const List<Color> glowColors = [Color(0xFFFFF4C2), Color(0xFF8FD0FF), Palette.sea];
  static const List<double> glowStops = [0, 0.42, 1];
  static const lines = BurstSpec(
      box: Size(384, 832),
      center: Offset(192, 330),
      count: 170,
      innerMin: 120,
      innerMax: 175,
      width: 4,
      seed: 41,
      color: Color(0xE6FFFFFF));
  static const double rushFrom = 2.4;

  /// The impact frame: the page in negative grey, its contrast pushed
  /// (brightness weighted 0.299 red, 0.587 green, 0.114 blue, times −2.2,
  /// about the middle grey).
  static const List<double> negative = [
    -0.658, -1.291, -0.251, 0, 408, //
    -0.658, -1.291, -0.251, 0, 408,
    -0.658, -1.291, -0.251, 0, 408,
    0, 0, 0, 1, 0,
  ];

  /// The band naming the page, and the gaps round the stage.
  static const double topGap = 8;
  static const double bandInset = 40;
  static const double bandFont = 19;
  static const double bandTracking = 0.2;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 6, 8, 7);
  static const double bandTurnDeg = -3;
  static const double stageGap = 10;

  /// The rank-up's stage: the old class in its middle, the blade's path
  /// across it, and the new class stamped where the old one stood, onto
  /// the ink splash, with ドン!! on its corner and Tobi below.
  static const Size stage = Size(330, 330);
  static const double oldFont = 56;
  static const double oldSuffixFont = 30;
  static const EdgeInsets oldPadding = EdgeInsets.fromLTRB(18, 10, 18, 12);
  static const double oldBorder = 4;
  static const double newFont = 64;
  static const double newSuffixFont = 34;
  static const EdgeInsets newPadding = EdgeInsets.fromLTRB(20, 12, 20, 14);
  static const double newBorder = 5;
  static const double newTurnDeg = -5;

  /// The old class trembles through the charge under ゴゴゴ.
  static const double trembleReach = 2.5;
  static const String rumble = 'ゴゴゴ';
  static const double rumbleFont = 40;
  static const Offset rumbleAt = Offset(0, 50);
  static const int rumbleSeed = 13;

  /// The blade: a paper streak round a sun core, [bladeWidth] at its
  /// widest, cutting from [bladeFrom] to [bladeTo]; ズバッ!! by where it
  /// starts.
  static const Offset bladeFrom = Offset(6, 101);
  static const Offset bladeTo = Offset(324, 229);
  static const double bladeWidth = 18;
  static const double bladeCore = 0.42;
  static const double bladeWidest = 0.7;
  static const double bladeOutline = 2;
  static const String slashSfx = 'ズバッ!!';
  static const double slashFont = 40;
  static const Offset slashAt = Offset(4, 22);
  static const double slashTurnDeg = -10;
  static const int slashSeed = 17;

  /// The halves slide apart along the cut by [splitSlide] and away from it
  /// by [splitGap], turning [splitTurnDeg] as they fade.
  static const double splitSlide = 54;
  static const double splitGap = 16;
  static const double splitTurnDeg = 8;
  static const double splitFadeFrom = 0.35;

  static const String splash = 'assets/images/sidetrips/ankiren/rank-splash.webp';
  static const Size splashSize = Size(360, 280);
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(200, 160), count: 54, innerMin: 96, innerMax: 120, width: 6, seed: 43);
  static const Size impactSize = Size(400, 320);
  static const double impactFromScale = 0.7;
  static const double impactToScale = 1.35;
  static const String hitSfx = 'ドン!!';
  static const double hitFont = 58;
  static const Offset hitAt = Offset(-6, 26);
  static const double hitTurnDeg = 10;
  static const int hitSeed = 29;
  static const Placement tobi = Placement(right: 4, bottom: 0, size: Size(64, 76));

  /// The rank-down: the calm page of a fall, until ガーン!! drops a shadow
  /// from the top, [gloomReach] of the page down, with gloom lines (縦線)
  /// hanging in it.
  static const List<Color> gloomColors = [Color(0x99141414), Color(0x00141414)];
  static const double gloomReach = 0.6;
  static const int gloomCount = 44;
  static const int gloomSeed = 7;
  static const double gloomShortest = 0.18;
  static const double gloomLongest = 0.5;
  static const double gloomThinnest = 1.2;
  static const double gloomThickest = 3.4;
  static const Color gloomLine = Color(0xB3141414);

  /// The rank-down's stage: the old class cracking and falling away, the
  /// lower class dropping into its place, ガーン!! over them and Tobi
  /// shocked below.
  static const Size downStage = Size(330, 300);
  static const String crack = 'assets/images/sidetrips/ankiren/rank-crack.webp';
  static const double fallDrop = 170;
  static const double fallTurnDeg = 18;
  static const String shockSfx = 'ガーン!!';
  static const double shockFont = 56;
  static const double shockTop = 2;
  static const double shockTurnDeg = -6;
  static const int shockSeed = 37;
  static const double tobiTremble = 1.3;
  static const tobiTrembleStep = Duration(milliseconds: 70);

  /// The result: the old class → the new one, the rating with its change,
  /// and the points to the next class (to win the lost one back after a
  /// fall).
  static const EdgeInsets resultPadding = EdgeInsets.fromLTRB(14, 12, 14, 12);
  static const double resultGap = 8;
  static const double resultBadgeFont = 24;
  static const double resultBadgeSuffixFont = 14;
  static const double arrowFont = 22;
  static const double arrowGap = 10;
  static const double ratingOldFont = 18;
  static const double ratingFont = 28;
  static const double changeFont = 17;
  static const EdgeInsets changePadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
  static const double nextFont = 15;
  static const double nextNumberFont = 22;

  static const double actionGap = 10;
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// 暗記練's rank-up, cut in at the rating page's white flash: the flash
/// fades over [flash] as focus lines rush in on the old class, which
/// trembles; at [slashAt] the blade cuts across it and the halves slide
/// apart; the new class slams down at [impactAt] with the impact frame,
/// the splash, ドン!! and a shake; then the band, Tobi, the result and the
/// button settle in.
abstract final class AnkirenRankUpMotion {
  static const flash = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 180), curve: Curves.easeIn);
  static const rush = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 480), curve: Curves.easeOutCubic);
  static const linesStep = Duration(milliseconds: 60);
  static const int linesFrames = 3;
  static const old = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 260), delay: Duration(milliseconds: 60), curve: Entrances.bouncy);
  static const rumble = EntranceSpec(EntranceFrom(scale: 0.3),
      duration: Duration(milliseconds: 200), delay: Duration(milliseconds: 200), curve: StepCurve(3, Entrances.bouncy));
  static const trembleStep = Duration(milliseconds: 40);

  static const slashAt = Duration(milliseconds: 660);
  static const slash = Duration(milliseconds: 90);
  static const slashFade = Duration(milliseconds: 240);
  static const slashSfx = EntranceSpec(EntranceFrom(scale: 0.3),
      duration: Duration(milliseconds: 220), delay: Duration(milliseconds: 680), curve: StepCurve(3, Entrances.bouncy));
  static const split = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 320), delay: Duration(milliseconds: 750), curve: Curves.easeOutCubic);

  /// The new class drops from high above and lands at [impactAt]; the
  /// impact frame lasts [impactFrame].
  static const impactAt = Duration(milliseconds: 1080);
  static const stamp = EntranceSpec(EntranceFrom(scale: 3, turnDeg: -20, opaqueAt: 0.05),
      duration: Duration(milliseconds: 110), delay: Duration(milliseconds: 970), curve: Curves.easeIn);
  static const impactFrame = Duration(milliseconds: 70);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 400), delay: impactAt, curve: Curves.linear);
  static const double joltReach = 10;
  static const int joltSteps = 11;
  static const int joltSeed = 71;
  static const splash = EntranceSpec(EntranceFrom(scale: 0.3),
      duration: Duration(milliseconds: 280), delay: impactAt, curve: Entrances.bouncy);
  static const burst = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 450), delay: impactAt, curve: Curves.easeOut);
  static const hitSfx = EntranceSpec(EntranceFrom(scale: 0.2),
      duration: Duration(milliseconds: 260), delay: Duration(milliseconds: 1100), curve: StepCurve(3, Entrances.bouncy));

  static const band = EntranceSpec(EntranceFrom(offset: Offset(-300, 0), opaqueAt: 0.3),
      duration: Duration(milliseconds: 200), delay: Duration(milliseconds: 1340), curve: StepCurve(3));
  static const tobi = EntranceSpec(EntranceFrom(offset: Offset(0, 30)),
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 1440), curve: StepCurve(4, Entrances.bouncy));
  static const double hopHeight = 10;
  static const hopPeriod = Duration(milliseconds: 1000);
  static const double hopAirShare = 0.4;
  static const result = EntranceSpec(EntranceFrom(offset: Offset(0, 24)),
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 1540), curve: StepCurve(4));
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1880), curve: Entrances.springy);

  static Duration get length => actions.end;
}

/// 暗記練's rank-down, a smaller beat: ガーン!! drops onto the old class at
/// [hitAt], cracking it with a jolt as the gloom comes down and Tobi
/// starts in shock; the old class falls away and the lower one drops into
/// its place at [landAt]; then the result and the button.
abstract final class AnkirenRankDownMotion {
  static const band =
      EntranceSpec(Entrances.up, duration: Duration(milliseconds: 300), curve: Entrances.glide);
  static const old = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 60), curve: Entrances.springy);
  static const shock = EntranceSpec(EntranceFrom(offset: Offset(0, -90), opaqueAt: 0.3),
      duration: Duration(milliseconds: 150), delay: Duration(milliseconds: 330), curve: StepCurve(3));
  static const hitAt = Duration(milliseconds: 480);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 260), delay: hitAt, curve: Curves.linear);
  static const double joltReach = 6;
  static const int joltSteps = 7;
  static const int joltSeed = 73;
  static const crack = EntranceSpec(EntranceFrom(scale: 1.3),
      duration: Duration(milliseconds: 120), delay: hitAt, curve: StepCurve(2));
  static const gloom = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 360), delay: hitAt, curve: StepCurve(6));
  static const tobi = EntranceSpec(EntranceFrom(offset: Offset(0, 30), scale: 0.5),
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 500), curve: StepCurve(3, Entrances.bouncy));
  static const fall = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 380), delay: Duration(milliseconds: 760), curve: Curves.easeInCubic);
  static const landAt = Duration(milliseconds: 1040);
  static const drop = EntranceSpec(EntranceFrom(offset: Offset(0, -110), opaqueAt: 0.2),
      duration: Duration(milliseconds: 140), delay: Duration(milliseconds: 900), curve: Curves.easeInCubic);
  static const thud = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 200), delay: landAt, curve: Curves.linear);
  static const double thudReach = 3;
  static const int thudSteps = 4;
  static const int thudSeed = 79;
  static const result = EntranceSpec(EntranceFrom(offset: Offset(0, 24)),
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 1140), curve: StepCurve(4));
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1340), curve: Entrances.springy);

  static Duration get length => actions.end;
}
