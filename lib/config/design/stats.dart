part of '../design.dart';

/// The Stats screen (spec phone 6): the archipelago map, its legend, and the
/// selected-island panel.
abstract final class StatsLayout {
  /// The Islands | All switch beside the summary line, and the joined
  /// Rank | SRS links in the header, a heavy ink rule between the two.
  static const double segHeight = 36;
  static const double segPadding = 12;
  static const double segFont = 13;

  static const double summaryFont = 13.5;
  static const double summaryNumberFont = 15;

  /// Small corner cuts on the map panel (eyeballed from the spec's `data-pts`).
  static const double mapCut = 8;

  static const double legendHeight = 58;
  static const EdgeInsets legendPadding = EdgeInsets.fromLTRB(12, 7, 12, 0);
  static const double legendHeadingFont = 12;
  static const double legendRowGap = 5;
  static const double legendFont = 12.5;
  static const double legendSwatch = 14;
  static const double legendSwatchBorder = 1.6;
  static const double legendItemGap = 4;

  /// The selected-island panel: text on the left, Tobi under his balloon
  /// (pointing down at him) in a column on the right. The red slowest tag
  /// sits [focusTagGap] after the panel's own tag.
  static const double focusCut = 6;
  static const EdgeInsets focusPadding = EdgeInsets.fromLTRB(14, 12, 10, 12);
  static const double focusGap = 4;
  static const double focusNameFont = 40;
  static const double focusSpeedFont = 17;

  /// In the speed box until a card of the island has enough tries, as the
  /// map's legend says it.
  static const double focusFewTriesFont = 15;
  static const EdgeInsets focusSpeedPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);
  static const double focusLineFont = 13;
  static const double focusButtonGap = 10;
  static const double focusTagGap = 6;
  static const Size focusTobi = Size(62, 74);
  static const Size focusBalloon = Size(92, 50);
  static const Alignment focusBalloonSpeaker = Alignment(0.2, 2.2);
  static const double focusBalloonFont = 13;

  static const double playButtonHeight = 40;
  static const EdgeInsets playButtonPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double playButtonFont = 14;

  /// The Details button after Play, [detailsButtonGap] apart.
  static const double detailsButtonGap = 6;
  static const EdgeInsets detailsButtonPadding = EdgeInsets.symmetric(horizontal: 12);

  /// Locked (not fully uncovered): the lock icon beside the label, and the
  /// balloon explaining why, sized like Home's "Learn ahead" lock.
  static const double playButtonIcon = 16;
  static const double playButtonIconGap = 5;
  static const Size playButtonBalloon = Size(270, 96);
  static const Duration playButtonBalloonLife = Duration(milliseconds: 2800);

  /// Why the header's rank link is locked in journey mode.
  static const Size rankLockedBalloon = Size(260, 96);
}

/// A page opened from Stats or Home (`StatsPage`): room under its list.
abstract final class StatsPageLayout {
  static const double bottomPad = 24;
}

/// The SRS page (`SrsScreen`) and its sections.
abstract final class SrsLayout {
  /// The Upright | Upside-down switches.
  static const double toggleHeight = 30;
  static const EdgeInsets togglePadding = EdgeInsets.symmetric(horizontal: 9);
  static const double toggleFont = 12;

  /// #1's strip: three cells over the pace bar.
  static const EdgeInsets glancePadding = EdgeInsets.fromLTRB(4, 8, 4 + HistoryListStyle.stripCut, 4);
  static const EdgeInsets glanceCellPadding = EdgeInsets.fromLTRB(8, 0, 6, 4);
  static const double glanceFont = 24;
  static const double glanceUnitFont = 12;
  static const EdgeInsets gaugeMargin = EdgeInsets.fromLTRB(4, 4, 0, 0);
  static const EdgeInsets gaugePadding = EdgeInsets.fromLTRB(4, 7, 4, 2);
  static const double gaugeHeight = 14;

  /// The day charts (`DayLineChart`).
  static const double chartHeight = 170;
  static const double chartTopPad = 6;
  static const double chartDot = 3;
  static const double chartMark = 5;
  static const List<double> knownTicks = [0, 25, 50, 75, 100];
  static const double knownStroke = 2.6;
  static const double paceStroke = 3;
  static const double trendStroke = 2.2;

  /// The Known cards chart's bands, in the pace bar's pinks: Known's pink
  /// (a little see-through) under its line, the pale pink between it and
  /// the Unlocked line, and that line's heavier dashes.
  static const Color knownFill = Color(0xB3FF3D7F);
  static const Color unlockedFill = Palette.pinkSoft;
  static const double unlockedStroke = 2;
  static const List<double> unlockedDash = [8, 4];
  static const List<double> dotDash = [1, 5];
  static const EdgeInsets calloutPadding = EdgeInsets.fromLTRB(10, 7, 10, 8);
  static const double calloutFont = 22;

  /// #3's wall: ten tiles a row at the mock's 1 : 1.22, the kana a share
  /// of the tile's width, and a sun dot on a mastered tile.
  static const int wallColumns = 10;
  static const double wallGap = 3;
  static const double wallTileAspect = 1 / 1.22;
  static const double wallFontShare = 0.5;
  static const double masteredDot = 6;
  static const double masteredDotInset = 2;
  static const Color notStartedInk = Color(0xFF9A9A9A);

  /// #4's stacked bars and stage table.
  static const double stackHeight = 28;
  static const double stackFont = 11;
  static const int stackMinLabel = 4;
  static const double stageSwatchColumn = 22;

  /// #17: the gridline steps in minutes, and the weeks summed under it.
  static const List<int> minuteSteps = [1, 2, 5, 10, 15, 30, 60];
  static const int weeks = 3;

  /// #18: the seconds grid's step.
  static const double speedStepMs = 500;

  /// #19: the small card over each column, and the label column's share.
  static const double sideCard = 34;
  static const String sideCardGlyph = 'あ';
  static const double sideCardFont = 16;
  static const double sideLabelFlex = 1.4;

  /// #34's table: column shares (card, stability, difficulty, recall,
  /// next, lapses, time), its cells and the sort arrows.
  static const List<int> tableFlex = [24, 13, 10, 15, 14, 13, 11];
  static const EdgeInsets tableCellPadding = EdgeInsets.symmetric(horizontal: 3, vertical: 6);
  static const EdgeInsets tableEmptyPadding = EdgeInsets.all(12);
  static const TextStyle tableHeadStyle = TextStyle(fontWeight: Weights.black, fontSize: 10.5, color: Palette.paper);
  static const TextStyle tableCellStyle = TextStyle(fontWeight: Weights.bold, fontSize: 11.5);
  static const TextStyle tableCardStyle = TextStyle(fontFamily: Fonts.display, fontSize: 13);
  static const TextStyle invertedTagStyle =
      TextStyle(fontWeight: Weights.black, fontSize: 9.5, color: Palette.paper, height: 1.2);
  static const EdgeInsets invertedTagPadding = EdgeInsets.symmetric(horizontal: 3);
  static const Color tableShade = Color(0xFFFAF8F4);
  static const String upArrow = ' ▲';
  static const String downArrow = ' ▼';

  /// Stabilities under this many days read "<0.1d".
  static const double stabilityFloor = 0.1;
}

/// The practice calendar (`PracticeCalendarScreen`): a month's grid of
/// days, today ringed in sun and ink, a finished set's tick.
abstract final class CalendarLayout {
  static const double monthGap = 18;

  /// Week rows of next month shown under this one.
  static const int nextMonthRows = 2;
  static const double cellGap = 4;
  static const double cellHeight = 40;
  static const EdgeInsets numberPadding = EdgeInsets.fromLTRB(3, 2, 2, 0);
  static const double numberFont = 10.5;
  static const Color futureInk = Color(0xFF9A9A9A);
  static const double todayRing = 2.5;
  static const double todayRingOuter = 4.5;
  static const double tick = 16;
  static const double tickInset = 2;
  static const double tickRim = 1.5;
  static const double tickIconShare = 0.62;
  static const double tickStroke = 2.2;
}

/// Small charts shared by the island list (a per-card sparkline) and the card
/// detail screen (the attempt chart).
abstract final class ChartStyle {
  static const double sparklineWidth = 96;
  static const double sparklineHeight = 24;
  static const double dotRadius = 2.6;
  static const double lineStroke = 1.8;

  /// Opacity of a toggled-off series tile (spec's `aria-pressed=false`).
  static const double dimOpacity = 0.45;

  /// The attempt chart (spec phone 8). The plot keeps its height; the axis
  /// labels add their own rows around it, so they grow with the font scale.
  static const double plotHeight = 140;
  static const double labelFont = 12;
  static const double tickLabelGap = 6;
  static const double plotTopGap = 5;
  static const double xLabelGap = 6;
  static const double plotRightPad = 12;
  static const Color grid = Color(0xFFE0E0E0);

  static const double attemptDotRadius = 2.9;
  static const double attemptDotRim = 0.9;

  /// A "don't know" marker: a ▽ in the top label row, above its attempt.
  static const Size missMarker = Size(10, 8);
  static const double missMarkerStroke = 1.4;

  static const Color bandFill = Color(0xFFCFE6FF);
  static const Color bandEdge = Color(0xFF7FB8F0);
  static const double bandEdgeStroke = 1;

  static const Color shortAverage = Palette.pink;
  static const double shortAverageStroke = 1.8;
  static const Color midAverage = Palette.ink;
  static const double midAverageStroke = 2.2;
  static const Color longAverage = Palette.violetDeep;
  static const double longAverageStroke = 4.2;
  static const double longAverageHalo = 7.5;

  /// TOP SPEED: a dashed line across the plot, a star on the attempt nearest
  /// to it, and its label beside the star (below the line, above it when the
  /// plot has no room below).
  static const Color topSpeedLine = Palette.landDeep;
  static const Color topSpeedText = Color(0xFF3E6B2C);
  static const double topSpeedStroke = 1.6;
  static const double topSpeedDash = 4;
  static const double starRadius = 9;
  static const double starInnerRatio = 0.45;
  static const double starStroke = 1.1;
  static const double starLabelGap = 12;
  static const double starLabelDrop = 3;

  static const Color latestRing = Palette.pink;
  static const double latestRingRadius = 6;
  static const double latestRingStroke = 2.4;

  /// `DailyChart`: a bar's share of its day's width, the dash of a dashed
  /// line, and the grid's stroke.
  static const double dailyBarShare = 0.6;
  static const double dash = 4;
  static const double gridStroke = 1;
}

/// The island detail screen (spec phone 7): the zoomed mini-map, this
/// island's stat summary, the sort chips and the scrollable card list. The
/// sort chip and card row tokens are shared with the Stats "All" tab
/// (`CardListView`, `CardTile` in `card_list.dart`).
abstract final class IslandDetailLayout {
  static const double titleFont = 26;
  static const double subFont = 12.5;

  static const double heroHeight = 150;
  static const double heroCut = 8;
  static const double heroMapMargin = 22;
  static const double mapWidth = 150;
  static const EdgeInsets summaryPadding = EdgeInsets.fromLTRB(12, 10, 12, 10);
  static const double summaryLabelFont = 12;
  static const double summaryAvgFont = 25;
  static const double summaryAvgUnitFont = 14;
  static const EdgeInsets summaryAvgPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);

  static const double distHeight = 14;
  static const double distBorder = 1.5;
  static const double dueLineFont = 13;

  static const double sortButtonFont = 13;
  static const EdgeInsets sortButtonPadding = EdgeInsets.fromLTRB(11, 4, 11, 5);

  static const double rowHeight = 82;
  static const double rowImageWidth = 42;
  static const double rowKimarijiFont = 21;
  static const double rowDueFont = 11.5;
  static const EdgeInsets rowDuePadding = EdgeInsets.fromLTRB(6, 1, 6, 2);
  static const double rowSpeedFont = 16;
  static const double rowSpeedSmallFont = 11.5;
  static const EdgeInsets rowSpeedPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
}

/// The card detail screen (spec phone 8): the card's own header, the mode
/// filter, the attempt chart and its toggleable stat tiles, and the FSRS
/// memory panel.
abstract final class CardDetailLayout {
  static const double topBarHeight = 40;
  static const double crumbFont = 13.5;
  static const double orientationFont = 12;
  static const double orientationHeight = 30;
  static const double orientationPadding = 10;

  static const double cardImageWidth = 104;
  static const double kimarijiFont = 44;

  /// The kana under the romaji, in romaji mode.
  static const double kimarijiKanaFont = 16;
  static const double captionFont = 11.5;

  static const double authorFont = 14;

  /// The whole poem under the card, 上の句 then 下の句, with readings.
  static const double poemFont = 16;
  static const double poemLineHeight = 1.25;
  static const double verseGap = 2;

  /// A look-alike (友札) chip: a miniature torifuda, its kimariji, a chevron.
  static const EdgeInsets lookAlikePadding = EdgeInsets.fromLTRB(5, 5, 8, 5);
  static const double lookAlikeCardWidth = 26;
  static const double lookAlikeKimarijiFont = 17;
  static const double lookAlikeChevron = 14;

  static const double modeFont = 13;

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(4, 6, 4, 4);
  static const EdgeInsets chartEmptyPadding = EdgeInsets.symmetric(vertical: 40);

  static const double seriesTileValueFont = 15;
  static const double seriesTileLabelFont = 11;
  static const EdgeInsets seriesTilePadding = EdgeInsets.fromLTRB(8, 5, 8, 6);
  static const double seriesSwatchHeight = 4;

  static const double memPadding = 12;
  static const double memHeadingFont = 12.5;

  /// The figures of the speed strip and the memory panel.
  static const double statLabelFont = 11.5;
  static const double statValueFont = 21;
  static const double statSuffixFont = 13;
  static const EdgeInsets statPadding = EdgeInsets.fromLTRB(9, 4, 9, 5);

  static const double balloonFont = 13;
  static const Alignment balloonSpeaker = Alignment(1.3, -0.2);
  static const double tobiWidth = 60;
  static const double tobiHeight = 72;
}

/// The rank ladder screen (spec phone 9): nine class rungs running top to
/// bottom from A級 down to 入門, each a step of the class's colour
/// progression, with the player's own rung, the next threshold and every
/// cleared class marked, plus a rank-up preview reachable from the next rung.
abstract final class RankLayout {
  static const double ratingLabelFont = 12;
  static const double ratingLabelTracking = 0.14;
  static const double ratingFont = 26;

  static const double rungHeight = 84;
  static const double rungGap = 8;

  /// The lock beside the badge of a class still ahead.
  static const double lockIcon = 20;
  static const double lockGap = 10;
  static const EdgeInsets rungPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);

  static const EdgeInsets badgePadding = EdgeInsets.fromLTRB(10, 5, 10, 6);
  static const double badgeFont = 22;
  static const double badgeSuffixFont = 13;

  static const double tagLabelFont = 11;
  static const double tagLabelTracking = 0.14;
  static const double tagNumberFont = 17;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(8, 3, 8, 4);

  static const double topNoteFont = 12.5;
  static const double topNoteTracking = 0.18;

  static const double stampFont = 14;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(8, 4, 8, 5);
  static const double stampTurn = -11;
  static const double stampRadius = 5;
  static const double stampRight = 20;

  /// Tobi stands inside the player's rung at its right, the "to go"
  /// balloon beside the YOU tag speaking from him; neither reaches the
  /// rungs above or below.
  static const Placement tobiPlacement = Placement(right: -4, top: (rungHeight - 70) / 2, size: Size(58, 70));
  static const double tobiRoom = 44;
  static const Size balloonSize = Size(96, 46);
  static const double balloonGap = 6;

  /// The least space between a rung's badge and its markers.
  static const double markerGap = 8;
  static const double balloonFont = 12.5;
  static const Alignment balloonSpeaker = Alignment(1.5, 0.6);

  static const double previewGap = 8;
  static const double previewFont = 12.5;
  static const EdgeInsets previewPadding = EdgeInsets.fromLTRB(10, 4, 10, 5);

  /// The small "Rank ›" entry point in the Stats header.
  static const double statsEntryIconSize = 14;
}

/// The rank ladder before there is a rank (`rank_screen.dart`): locked in
/// journey mode, waiting for the first ranked run in all-known mode.
abstract final class RankLockLayout {
  /// The locked ladder shows through this faintly behind its card.
  static const double ladderOpacity = 0.32;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const double cardCut = 12;
  static const double titleFont = 20;
  static const double bodyFont = 14;
  static const double bodyLineHeight = 1.45;
  static const double lockIcon = 22;
  static const double buttonHeight = 48;
  static const Placement tobi = Placement(right: 14, top: -62, size: Size(70, 84));

  /// Room left above the card for Tobi.
  static const double tobiRoom = 56;
  static const double noteFont = 13.5;
}
