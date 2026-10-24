part of '../design.dart';

/// My Profile (opened from Home's level button): Tobi's welcome, rank,
/// learned/well-remembered counts, level progress and the first-swipe line.
abstract final class ProfileLayout {
  static const double tobiWidth = 76;
  static const double tobiHeight = 90;
  static const double greetingFont = 14;
  static const double statLabelFont = 13;
  static const double statNumberFont = 20;
  static const double levelFont = 28;
  static const double levelBarHeight = 14;

  /// The side trips' ranks under the main one, smaller: a class badge, the
  /// trip's name and its rating.
  static const double tripGap = 8;
  static const double tripLabelFont = 11;
  static const double tripLabelTracking = 0.14;
  static const double tripBadgeFont = 15;
  static const double tripBadgeSuffixFont = 10;
  static const EdgeInsets tripBadgePadding = EdgeInsets.fromLTRB(7, 3, 7, 4);
  static const double tripNameFont = 18;
  static const double tripRatingFont = 20;
  static const double tripUnrankedFont = 14;
}

/// Island map rendering (`IslandMap`).
abstract final class MapStyle {
  static const double coastStroke = 2.6;
  static const double shoalStroke = 1.8;
  static const List<double> shoalDash = [5, 4];
  static const double surf = 9;
  static const double treeStroke = 1.3;
  static const double treeMaxRadius = 5.2;
  static const double treeInset = 0.3;
  static const double treeHighlightOffset = 0.34;
  static const double treeHighlightRadius = 0.3;
  static const Color tree = Palette.landDeep;
  static const Color treeHighlight = Color(0xFFB5E68F);
  static const double dotStroke = 1.4;
  static const double pendingStroke = 1.5;
  static const double hollowStroke = 1.6;
  static const double hollowInset = 0.4;
  static const double waveStroke = 2;
  static const double waveOpacity = 0.85;

  /// One wave squiggle per this many square map units.
  static const double waveDensity = 4200;
  static const double waveHalf = 4;
  static const double waveHeight = 4.5;
  static const double routeStroke = 3.6;
  static const List<double> routeDoneDash = [9, 6];
  static const List<double> routeAheadDash = [0.1, 8];

  /// Where the route starts, relative to the first island's centre.
  static const Offset routeStart = Offset(-46, 56);
  static const Size flag = Size(19, 26);
  static const Offset flagOffset = Offset(10, -14);

  /// A flag planted on a card site (`SiteMark.flag`), map units, and where
  /// its pole's foot sits in that box (the art's 16 × 22 box has it at
  /// 2.5, 21).
  static const Size siteFlag = Size(6.3, 8.6);
  static const Offset siteFlagFoot = Offset(1, 8.2);
  static const Size boat = Size(36, 33);

  /// Boat anchor above the route point, as a fraction of its height.
  static const double boatLift = 0.7;

  /// How far along the last sailed leg the boat floats.
  static const double boatAlong = 0.5;
  static const double plateFont = 14;
  static const double plateFontLong = 13;
  static const double platePad = 6;
  static const double plateExtraHeight = 9;
  static const double plateRadius = 4;
  static const double plateStroke = 2;
  static const double plateStrokeCurrent = 2.6;
  static const List<double> plateDash = [4, 3];
  static const double chipScale = 0.9;
  static const double chipPad = 10;
  static const double chipGap = 4;
  static const double chipRadius = 3;
  static const double chipStroke = 1.3;
  static const double chipInset = 3;

  /// The mark after a chip's text (`IslandPlate.chipMark`), and its size as
  /// a share of the plate's font.
  static const String chipMarkGlyph = '▼';
  static const double chipMarkScale = 0.7;

  /// The art at a plate's end (`IslandPlate.mark`), as a share of its font.
  static const double markScale = 1;
  static const double tapSlop = 6;
}

/// The Home screens (spec phones 2 and 3).
abstract final class HomeLayout {
  static const double mapCut = 12;
  static const EdgeInsets mapLabelInsets = EdgeInsets.fromLTRB(12, 10, 12, 0);
  static const double mapBannerFont = 14;
  static const double mapCountTop = 44;
  static const double mapCountFont = 13;
  static const double mapCountNumber = 15;

  /// The count label's line, as a multiple of [mapCountNumber], a little over
  /// what its fonts need at any text scale: the map keeps the labels' height
  /// clear above it.
  static const double mapCountLine = 1.35;
  static const EdgeInsets mapCountPadding = EdgeInsets.fromLTRB(9, 3, 9, 3);
  static const double mapMistFont = 12.5;
  static const EdgeInsets mapMistPadding = EdgeInsets.fromLTRB(8, 3, 8, 3);

  static const EdgeInsets progressPadding = EdgeInsets.fromLTRB(12, 6, 12, 8);
  static const double pipWidth = 21;
  static const double pipHeight = 24;
  static const double pipAspect = pipHeight / pipWidth;
  static const double pipGap = 6;
  static const double pipTop = 8;
  static const double pipRadius = 3;
  static const double pipInset = 3;

  /// The known-card speed tag (`KnownSpeedTag`), on Home.
  static const double knownSpeedFont = 12;
  static const double knownSpeedNumber = 14;
  static const double knownSpeedTrendIcon = 11;

  /// Above the known-card speed under the journey's card pips.
  static const double pipsSpeedGap = 8;

  static const double journeyHeroHeight = 180;
  static const double journeyHeroCut = 8;
  static const double journeyTitle = 52;
  static const double journeyTitleOutline = 11;
  static const EdgeInsets journeyHeroPadding = EdgeInsets.fromLTRB(18, 12, 18, 6);
  static const double journeyNarrationGap = 0;
  static const double journeyShoutHeight = 52;
  static const double journeyShoutLeft = 14;
  static const double journeyShoutRight = 18;
  static const journeyShout = ShoutSpec(spikes: 28, outer: 7);
  static const Placement journeyTobi = Placement(right: 8, top: -14, size: Size(84, 100));
  static const Placement journeyBalloon = Placement(right: 90, top: 20, size: Size(96, 50));
  static const double journeyBalloonFont = 13.5;
  static const Alignment journeyBalloonSpeaker = Alignment(1.9, -0.3);

  /// A button beside the hero's narration (journey's Learn ahead): its
  /// smallest and largest share of the row.
  static const double heroBesideMinShare = 0.3;
  static const double heroBesideMaxShare = 0.42;

  /// How much of the hero's width its title may take, keeping clear of Tobi.
  static const double heroTitleMaxShare = 0.34;
  static const double heroBesideGap = 8;

  static const double rankGap = 12;
  static const double classFont = 32;
  static const double classSuffixFont = 18;

  /// The widest the class sticker grows: a longer English class name scales
  /// down to fit.
  static const double classMaxWidth = 96;
  static const double ratingLabelFont = 12;
  static const double ratingLabelTracking = 0.14;
  static const double ratingFont = 26;
  static const double ratingBarWidth = 112;
  static const double ratingBarHeight = 12;
  static const double ratingBarGap = 4;
  static const double ratingNoteFont = 12.5;

  static const double heroCut = 22;
  static const double heroTitle = 68;
  static const double heroTitleOutline = 12;
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(22, 14, 18, 32);
  static const double heroNarrationIndent = -4;
  static const double heroNarrationGap = 19;
  static const double heroShoutHeight = 74;
  static const double heroShoutLeft = 14;
  static const double heroShoutRight = 14;
  static const heroShout = ShoutSpec(spikes: 30);
  static const Placement heroTobi = Placement(right: 12, top: -20, size: Size(118, 140));
  static const Placement heroBalloon = Placement(right: 110, top: 38, size: Size(94, 50));
  static const double heroBalloonFont = 14.5;
  static const Alignment heroBalloonSpeaker = Alignment(1.8, -0.5);

  /// The slim guest bar at the foot of all-known Home.
  static const double guestHeight = 36;
  static const EdgeInsets guestPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 4);
  static const double guestIcon = 24;
  static const double guestGap = 9;
  static const double guestTitle = 15;
  static const double guestSub = 12.5;

  static const double rowJpFont = 17;
  static const double rowLineHeight = 1.1;
  static const double rowSubFont = 12;
  static const double untrackedFont = 12;
  static const double untrackedTracking = 0.08;
  static const EdgeInsets untrackedPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double untrackedGap = 4;
}

/// Journey Home's today box (`TodayBox`): today's set as one bar, in the
/// slanted panel between the map and the hero. Its height is fixed, so the
/// map keeps its size; text that grows with the font scale shrinks to fit.
abstract final class TodayBoxLayout {
  static const double height = 130.6;
  static const double headerHeight = 33;
  static const double barHeight = 22;
  static const double legendHeight = 29;
  static const double sectionGap = 6;

  /// The largest font scale its text follows: as much as a legend row holds.
  static const double maxTextScale = legendRow / legendFont;

  /// "Today:", the total in looks and "cards in one run". The two labels
  /// shrink (down to [minLabelScale]) before the whole line does.
  static const double labelFont = 12.5;
  static const double labelLineHeight = 1.08;
  static const double number = 31;
  static const double numberLineHeight = headerHeight / number;
  static const double headerGap = 7;
  static const double todayGap = 5;
  static const double minLabelScale = 0.75;

  /// Segments are split by hairlines and never narrower than [minSegment].
  static const double barBorder = Strokes.control;
  static const double barSeparator = Strokes.hairline;
  static const double minSegment = 5;

  /// The legend: two rows of two cells, each a swatch and a label.
  static const double legendRow = 14;
  static const double legendColumnGap = 12;
  static const double legendFont = 12;
  static const double swatch = 11;
  static const double swatchBorder = 1.8;
  static const double swatchGap = 5;

  /// Diagonal sun and paper stripes of the paused new cards' swatch.
  static const double hatch = 2;
  static const Color pausedText = Color(0xFF666666);

  /// Week stamps: circles with their weekday under them. The ring sizes are
  /// shares of the circle.
  static const double stamp = 15;
  static const double stampGap = 4;
  static const double stampBorder = 0.12;
  static const double missedBorder = 0.1;
  static const double todayRing = 0.15;
  static const double todayRingOuter = 0.24;
  static const double check = 11;
  static const double checkStroke = 4.4;
  static const double weekdayGap = 2.5;
  static const double weekdayFont = 8.5;
  static const double weekdayHeight = 9;

  /// The 本日完了 hanko of a done day, centred over the bar and the legend's
  /// room (a done day has no legend), clear of the header: its centre this
  /// far below the top of the inside, a paper face and a double rule.
  static const double doneStampCenter = headerHeight + sectionGap + (barHeight + sectionGap + legendHeight) / 2;
  static const double doneStampFont = 25;
  static const double doneStampTracking = 0.06;
  static const double doneStampTurn = -7;
  static const double doneStampBorder = Strokes.button;
  static const double doneStampRule = 2;
  static const double doneStampInnerRule = 1.6;
  static const double doneStampPaper = 0.86;
  static const double doneStampRuleOpacity = 0.92;
  static const EdgeInsets doneStampPadding = EdgeInsets.fromLTRB(13, 6, 13, 8);
}

/// The sheet that offers to pause today's new cards when reviews pile up.
abstract final class PauseSheetLayout {
  static const double cut = 14;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 33, 20, 20);
  static const double title = 22;
  static const double sub = 13;
  static const double subGap = 3;
  static const double body = 14;
  static const double bodyLineHeight = 1.45;
  static const double bodyGap = 12;
  static const double note = 12.5;
  static const double noteGap = 4;
  static const double shoutGap = 14;
  static const double shoutHeight = 64;
  static const double shoutFont = 17;
  static const shout = ShoutSpec(spikes: 26, outer: 7);
  static const double keepGap = 8;
  static const double keepHeight = 48;
  static const double keepFont = 15;
  static const double keepSub = 11.5;
  static const double keepSubGap = 8;
  static const Placement tobi = Placement(right: 14, top: -50, size: Size(76, 90));
  static const Color barrier = Color(0x8C141414);
}

/// The 正 tally of the streak: strokes of one 正 in writing order, in a
/// 70 × 32 box holding two characters.
abstract final class Tally {
  static const Size box = Size(70, 32);

  /// Loaded from `assets/graphics/tally.svg`, in writing order.
  static late final List<String> strokes;
  static const double glyphAdvance = 38;

  /// 正 characters drawn: the tally stops growing at this many.
  static const int glyphs = 2;
  static const double stroke = 3.2;
  static const double latestStroke = 3.8;
  static const double ghostStroke = 1.4;
  static const List<double> ghostDash = [2, 3];
  static const double ghostOpacity = 0.5;
}

/// The guest-mode confirmation sheet.
abstract final class GuestSheetStyle {
  static const double title = 22;
  static const double body = 14;
  static const double bodyLineHeight = 1.45;
  static const double shoutHeight = 64;
  static const double cancelHeight = 48;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 22, 20, 20);
  static const double cut = 14;
  static const Placement tobi = Placement(right: 18, top: -64, size: Size(76, 90));
  static const Color barrier = Color(0x8C141414);
}

/// The ranked run's questions (`ranked_sheets.dart`): start, and forfeit.
abstract final class RankedSheetStyle {
  static const double title = 24;
  static const double body = 14;
  static const double bodyLineHeight = 1.45;
  static const double shoutHeight = 60;
  static const double plainHeight = 48;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 22, 20, 20);
  static const EdgeInsets warningPadding = EdgeInsets.fromLTRB(10, 8, 10, 8);
  static const Color warningFill = Palette.pinkSoft;
  static const double cut = 14;
  static const Placement tobi = Placement(right: 18, top: -64, size: Size(76, 90));
  static const Color barrier = GuestSheetStyle.barrier;
}

/// All-known Home's ランク戦 hero (`ranked_hero.dart`), as big as journey
/// Home's 修行 and drawn like it: the lettering over its tag, the START
/// RANKED shout, and Tobi with his balloon at the top right. Its top edge
/// slants with the rank map's foot above it.
abstract final class RankedHeroLayout {
  static const String title = 'ランク戦';
  static const EdgeInsets padding = EdgeInsets.only(top: 27, bottom: 10);

  /// The lettering keeps clear of Tobi on the right.
  static const EdgeInsets titlePadding = EdgeInsets.only(left: 14, right: 100);
  static const double titleFont = 40;
  static const double titleOutline = 9;
  static const double bannerFont = 12;
  static const double bannerGap = 3;
  static const double shoutHeight = 58;
  static const double shoutFont = 22;
  static const EdgeInsets shoutMargin = EdgeInsets.fromLTRB(10, 0, 12, 0);
  static const Placement balloon = Placement(right: 98, top: 64, size: Size(84, 42));
  static const double balloonFont = 13;
  static const Alignment balloonSpeaker = Alignment(1.9, -0.4);
}

/// The rank before the first ranked run places the player (Home's rating
/// card, My Profile): a blank sticker and "Unranked" in place of the rating.
abstract final class UnrankedStyle {
  static const String mark = '?';
  static const Color sticker = Palette.paper;
  static const double font = 20;
}

/// All-known Home (`known_home.dart`): the rank map, the ランク戦 hero, free
/// play and 苦手 side by side, and the guest bar.
abstract final class KnownHomeLayout {
  /// How far the map's foot and the hero's top slant, parallel and
  /// [heroGap] apart.
  static const double slant = 18;
  static const double heroGap = 8;
  static const double heroHeight = HomeLayout.journeyHeroHeight;
  static const double buttonsGap = 12;
  static const double guestGap = 8;

  /// The 苦手 button's mark with nothing weak: a check on a land circle.
  static const double doneMark = StickerStyle.badgeSize;
  static const double doneCheck = 20;
}

/// All-known Home's rank map (`rank_map.dart`): one island per class, each a
/// journey island's coast, laid out in map units that are dp on a map
/// [designWidth] wide (a wider or narrower one scales).
abstract final class RankMapStyle {
  static const double designWidth = 352;

  /// The journey island (its index in `assets/data/islands.json`) whose
  /// coast each class takes, Novice to A: smallest to largest.
  static const List<int> coasts = [4, 5, 6, 0, 7, 8, 9, 1, 2];

  /// Before the first ranked run, the whole ladder in two rows: the first
  /// [overviewRow] classes left to right along the bottom from
  /// [overviewLeft], the rest right to left along the top from
  /// [overviewHighRight], centres [overviewStep] apart, and the rows' island
  /// bottoms [overviewLow] and [overviewHigh] above the map's foot (the
  /// cards' top).
  static const double overviewScale = 0.62;
  static const int overviewRow = 5;
  static const double overviewLeft = 72;
  static const double overviewHighRight = 292;
  static const double overviewStep = 62;
  static const double overviewLow = 42;
  static const double overviewHigh = 98;
  static const double overviewPlateFont = 11.5;
  static const double overviewPlateGap = 3;

  /// Where the route starts, from Novice's centre.
  static const Offset overviewHarbour = Offset(-96, 5);

  /// Once placed, the ladder in one row, the player's class [rowFocus] from
  /// the map's left ([rowFocusTop] in the top class), with the islands'
  /// bottoms at [rowLow] and [rowHigh] above the foot in turn.
  static const double rowScale = 1.2;
  static const double rowStep = 140;
  static const double rowFocus = 150;
  static const double rowFocusTop = 236;
  static const double rowLow = 36;
  static const double rowHigh = 52;
  static const double rowPlateGap = 4;

  /// Where the route starts, from Novice's centre.
  static const Offset rowHarbour = Offset(-196, 24);

  /// Plates no nearer the map's sides than this, so none is cut in half.
  static const double plateEdge = 30;

  /// Sea kept clear between the banner over the map and the highest island.
  static const double labelsGap = 3;
  static const int seaSeed = 31;
}

/// The labels over the rank map and the cards at its foot.
abstract final class RankMapLayout {
  static const double bannerFont = 17;
  static const EdgeInsets cornerPadding = EdgeInsets.fromLTRB(9, 3, 8, 3);

  /// The rating and streak cards, clear of the map's slanted foot. Their
  /// text grows with the font scale up to [maxTextScale], keeping the
  /// islands above them clear of the labels at the map's top.
  static const EdgeInsets footMargin = EdgeInsets.fromLTRB(8, 0, 11, 16 + KnownHomeLayout.slant);
  static const double maxTextScale = 1.15;
  static const int ratingFlex = 222;
  static const int streakFlex = 103;
  static const double cardGap = 8;
  static const double cardBorder = Strokes.panel;
  static const Offset cardShadow = Offset(3, 3);
  static const double cardMinHeight = 74;

  /// The class stamp sticks up out of the rating card's top left, in a
  /// slot at least [stampSlot] wide before the rating.
  static const double stampRaise = 15;
  static const double stampTilt = -6;
  static const double stampSlot = 66;
  static const double stampGap = 12;
  static const EdgeInsets ratingPadding = EdgeInsets.fromLTRB(8, cardBorder, 10, cardBorder);
  static const double labelFont = 9.5;
  static const double labelTracking = 0.16;
  static const double labelGap = 2;
  static const double ratingFont = 28;
  static const double unrankedFont = 19;
  static const double barGap = 3;
  static const double noteFont = 11.5;
  static const double noteLineHeight = 1.2;

  static const EdgeInsets streakPadding = EdgeInsets.symmetric(horizontal: 6, vertical: cardBorder);
  static const double tallyWidth = 58;
  static const double streakGap = 5;
  static const double streakFont = 12;
  static const double streakNumber = 16;
}

/// Home's "Learn ahead" (`LearnAheadButton`) beside the training hero's
/// narration, and the balloon that says why it is locked.
abstract final class LearnAheadStyle {
  static const double minHeight = 36;
  static const double font = 13;
  static const double icon = 16;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  static const double iconGap = 5;
  static const Size balloon = Size(270, 96);

  /// The balloon of the longer daily-limit message.
  static const Size limitBalloon = Size(300, 116);

  static const Duration balloonLife = Duration(milliseconds: 2800);
}

/// The Home journey map: how much of the archipelago is visible.
abstract final class JourneyView {
  /// The current island and the boat sit this far down the part of the box
  /// the labels leave clear.
  static const double focus = 0.62;

  /// Map units below an island's plate anchor that stay in view, so a short
  /// box raises the current island rather than cut off its plate.
  static const double plateReach = 22;

  /// Sea kept clear under the labels when the map is scrolled to its top,
  /// and under the map's last plate when it is scrolled to its bottom.
  static const double labelsGap = 3;
  static const double bottomGap = HomeLayout.mapCut;

  /// How long the view takes to move to the boat when the boat moves.
  static const Duration refocus = Duration(milliseconds: 420);

  /// Sea seed for the wave squiggles.
  static const int seaSeed = 4;

  /// Upcoming islands that get a (dashed) name plate.
  static const int platesAhead = 3;
}

/// Journey Home's graduation exam strip (`exam_strip.dart`): a black band
/// along the bottom of the islands map, the journey's last stop, with its
/// state on a pill at the right.
abstract final class ExamStripStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(12, 6, 10, 6);

  /// Lifts the pill clear of the map panel's bottom edge, which rises
  /// toward the right (`HomeLayout.mapCut`).
  static const double pillLift = HomeLayout.mapCut * 0.6;
  static const double titleFont = 16;
  static const double subFont = 10.5;
  static const double ruleFont = 11.5;
  static const double ruleNumber = 13;
  static const double ruleLineHeight = 1.3;
  static const double gap = 10;
  static const double maxTextScale = 1.15;

  /// The sun rule along the strip's top edge, where it meets the sea.
  static const double edge = 3;

  static const EdgeInsets pillPadding = EdgeInsets.symmetric(horizontal: 9);
  static const double pillHeight = 28;
  static const double pillLineHeight = 1.15;
  static const double pillFont = 12.5;
  static const double pillTime = 15;
  static const double pillIcon = 14;
  static const double pillIconGap = 4;
  static const Color openFill = Palette.land;
  static const Color waitFill = Palette.paper;

  /// The countdown's refresh while a try is cooling down, and Tobi's word
  /// on why a tap then does not start it.
  static const Duration tick = Duration(seconds: 1);
  static const Size waitBalloon = Size(270, 96);
  static const Duration waitBalloonLife = Duration(milliseconds: 2800);

  /// How far the map keeps going under the strip or the banner below it, so
  /// the sea runs on behind them while the focused island stays above.
  static const double mapOverhang = 140;
}

/// Journey Home's banner once the exam is passed (`switch_banner.dart`): a
/// sun card with a hard shadow over the bottom of the islands map. Its ✕
/// folds it into a square button at its right end.
abstract final class SwitchBannerStyle {
  /// Clear of the map panel's slanted bottom (`HomeLayout.mapCut`), shadow
  /// included.
  static const EdgeInsets margin = EdgeInsets.fromLTRB(8, 0, 11, 16);
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 6, 0, 6);
  static const Color fill = Palette.sun;
  static const Offset shadow = Offset(3, 3);
  static const double tagFont = 10.5;
  static const double font = 12;
  static const double lineHeight = 1.3;
  static const double gap = 8;
  static const double arrowIcon = 16;
  static const double closeIcon = 14;

  /// The folded button's side, and the width of the ✕ it folds into.
  static const double square = 48;
  static const double closeTarget = square;
  static const double maxTextScale = 1.15;

  /// The RANKED mark on the folded button: the tag over an arrow.
  static const double markTagFont = 8.5;
  static const double markArrow = 14;
  static const double markGap = 3;
  static const EdgeInsets markTagPadding = EdgeInsets.fromLTRB(3, 2, 3, 3);

  /// The fold and unfold. The text is gone by the half way point of a fold,
  /// and the mark comes in over the second half.
  static const Duration fold = Duration(milliseconds: 240);
  static const Curve foldCurve = Curves.easeOutCubic;
  static const Interval textShown = Interval(0.5, 1);
  static const Interval markHidden = Interval(0, 0.5);
}

/// The question after passing the exam (`switch_banner.dart`): move to
/// all-known mode now, or later.
abstract final class SwitchSheetStyle {
  static const double title = 24;
  static const double body = 14;
  static const double lineHeight = 1.4;
  static const double note = 12;
  static const double shoutHeight = RankedSheetStyle.shoutHeight;
  static const EdgeInsets padding = RankedSheetStyle.padding;
  static const double cut = RankedSheetStyle.cut;
  static const Placement tobi = RankedSheetStyle.tobi;
  static const Color barrier = RankedSheetStyle.barrier;
}
