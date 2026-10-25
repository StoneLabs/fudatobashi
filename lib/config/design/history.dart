part of '../design.dart';

/// The History tab: each run's mode tag, timestamp, card/miss count and
/// total time, laid out for high contrast — ink on paper, unlike the
/// original app's dim grey-on-green history text.
abstract final class HistoryLayout {
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double rowDateFont = 12.5;
  static const double rowTimeFont = 18;
  static const EdgeInsets emptyPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

/// History's header under its title: the record strip summing up the runs
/// on show, and the run-kind filter, a segmented control whose segments wrap
/// into as few rows as fit.
abstract final class HistoryHeaderLayout {
  /// The record strip: a sun-toned panel with its right edge cut in, each
  /// stat a tracked label over its number, split by ink rules.
  static const double stripCut = 14;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(14, 9, 14 + stripCut, 10);
  static const double statLabelFont = 11;
  static const double statLabelTracking = 0.14;
  static const double statGap = 2;
  static const double statFont = 26;
  static const double statRuleInset = 12;

  /// Between the strip and the filter.
  static const double filterGap = 10;
  static const double segmentHeight = 40;
  static const double segmentPadding = 10;
  static const double segmentFont = 13;
}

/// One kind of run's colour, the same wherever a run's kind is shown by
/// colour: its tag and its row's edge in History's lists, and the open tab
/// of its page, with [onAccent] for text on it.
class KindLook {
  const KindLook(this.accent, {this.onAccent = Palette.ink});
  final Color accent, onAccent;
}

/// The [KindLook] of each kind of run and of 暗記練's games.
abstract final class HistoryLooks {
  static const ranked = KindLook(Palette.pink);
  static const exam = KindLook(Palette.sun);
  static const free = KindLook(Palette.sea);
  static const weak = KindLook(Palette.orange);
  static const training = KindLook(Palette.land);
  static const ankiren = KindLook(Palette.pink);
}

/// History's run pages and rows: sections, fact grids, result badges.
abstract final class HistoryRunStyle {
  /// The hard ink shadow under History's panels.
  static const Offset panelShadow = Offset(3, 3);

  /// A section title's marker stripe: where its top and bottom sit as
  /// shares of the line's height, how far it reaches past the text, its
  /// tilt and its colour.
  static const double titleMarkTop = 0.5;
  static const double titleMarkBottom = 0.94;
  static const double titleMarkReach = 4;
  static const double titleMarkSkew = -0.25;
  static const Color headingMark = Palette.sun;

  static const double sectionGap = 18;

  /// `HistoryButton`: an icon, its label and the smaller line after it.
  static const double buttonHeight = 50;
  static const double buttonShadow = 3;
  static const double buttonIcon = 18;
  static const double buttonFont = 15;
  static const double buttonSubFont = 11;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// The Every swipe table: row height, column widths (the card takes the
  /// rest), a miss row's tint and the rule every ten cards.
  static const double rowHeight = 25;
  static const double tableInset = 4;
  static const double cellGap = 3;
  static const double tableMaxColumnScale = 1.15;
  static const double colNumber = 26;
  static const double colSide = 18;
  static const double colTime = 42;
  static const double colAt = 50;
  static const Color missRow = Palette.pinkSoft;
  static const Color missTime = Palette.pinkDeep;
  static const Color headRow = Palette.ink;
  static const int ruleEvery = 10;
  static const double subFont = 11;
  static const double noteFont = 11.5;
  static const double labelFont = 10;
  static const double labelTracking = 1.2;
  static const double factFont = 20;
  static const EdgeInsets factPadding = EdgeInsets.fromLTRB(8, 7, 6, 7);
  static const double badgeFont = 10;

  /// The star before a badge worth celebrating, with its space.
  static const String cheerMark = '★ ';
  static const EdgeInsets badgePadding = EdgeInsets.fromLTRB(5, 2, 5, 2);

  /// A run's or game's kind tag (`KindTag`).
  static const double kindFont = 11;
  static const double kindTracking = 0.44;
  static const double kindLineHeight = 1.2;
  static const EdgeInsets kindPadding = EdgeInsets.fromLTRB(7, 2, 7, 2);
  static const Color muted = Color(0xFF7A766F);

  /// Pink for slower than even pace or a miss, green for ahead or right.
  static const Color behind = Palette.pinkDeep;
  static const Color ahead = Palette.landDeep;
}

/// History's run charts: the time graph and the bar charts.
abstract final class RunChartStyle {
  static const double timeGraphMinHeight = 180;
  static const double barChartHeight = 130;

  /// A training run's speed chart, shorter to leave room for its counts.
  static const double shortBarChartHeight = 84;
  static const double labelFont = 10.5;
  static const double valueFont = 9.5;
  static const double valueInset = 4;
  static const double labelGap = 4;
  static const double plotRightPad = 10;
  static const double plotBottomPad = 8;
  static const double lineStroke = 2.2;
  static const double referenceStroke = 1.2;
  static const Color reference = Color(0xFFBDB9B2);
  static const double missDot = 3.6;
  static const double endMark = 6;

  /// The run's end time, left of its mark on a paper halo.
  static const double endLabelGap = 4;
  static const double labelHalo = 4;
  static const double guideStroke = 2;

  /// Gridline steps to choose from: cards across, ms down, ms up a bar
  /// chart; the first that gives at most this many ticks.
  static const List<int> cardSteps = [5, 10, 25, 50, 100];
  static const int maxXTicks = 5;
  static const List<int> timeStepsMs = [15000, 30000, 60000, 120000, 300000, 600000];
  static const List<int> barStepsMs = [500, 1000, 2000, 5000, 10000];
  static const int maxYTicks = 5;

  /// Bars wider than this get a gap and an outline.
  static const double wideBar = 8;
  static const double barGapShare = 0.22;
  static const double legendBox = 11;
  static const double legendLine = 18;
}

/// History's filter sheet (D43).
abstract final class HistoryFilterStyle {
  static const Color barrier = Color(0x88000000);
  static const EdgeInsets padding = EdgeInsets.fromLTRB(Gaps.gutter, 12, Gaps.gutter, Gaps.gutter);
  static const double chipHeight = 34;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 10);
  static const double showHeight = 56;
}

/// The History list: the 7-day strip (D2), day headers (D4) and rows (D5).
abstract final class HistoryListStyle {
  /// The strip's panel, its bottom right corner cut in by [stripCut].
  static const double stripCut = 14;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(10, 8, 10 + stripCut, 7);
  static const double labelGap = 5;
  static const double dayBox = 24;
  static const double dayGap = 1;
  static const double dayDot = 7;
  static const double dayMarkFont = 13;
  static const double dayLetterFont = 9;

  /// Today's ring, [todayRingGap] outside its box; every day keeps the room.
  static const double todayRing = 2.5;
  static const double todayRingGap = 1.5;
  static const double streakFont = 34;
  static const Offset streakShadow = Offset(2.5, 2.5);
  static const double streakLabelFont = 10.5;
  static const double streakSubFont = 8;
  static const Color dayNone = Palette.paper;
  static const Color daySome = Palette.sun;
  static const Color dayDone = Palette.land;
  static const Color today = Palette.pink;
  static const Color todayText = Palette.pinkDeep;
  static const double legendGap = 6;
  static const double legendFont = 9.5;
  static const Color legendText = rowLineColor;
  static const double legendBox = 11;
  static const double headerMark = 14;

  /// A small day square's border thins with its size, down to this share.
  static const double markMinBorder = 0.6;
  static const double tabGap = 10;
  static const double dayHeaderFont = 15;
  static const double dayHeaderDateFont = 12.5;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(10, 4, 6, 4);
  static const double rowMinHeight = 40;
  static const double rowClockWidth = 44;
  static const double rowGap = 8;
  static const double rowClockFont = 13;
  static const double rowValueFont = 19;
  static const double captionGap = 2;
  static const double rowCaptionFont = 9.5;
  static const double rowLineFont = 11.5;
  static const double rowLineHeight = 1.2;
  static const Color rowLineColor = Color(0xFF56524B);
  static const double tagGap = 5;
  static const double lineGap = 2;
  static const double chevron = 14;
  static const double accent = 5;
  static const double bottomPad = 24;
}

/// History's 暗記練 game page: tier colours, the first-tap mix bars, the
/// replayed field, the tables and the score sum.
abstract final class AnkirenReviewStyle {
  /// Where a tap landed (by `TapProximity.index`, nearest first): fill and
  /// text.
  static const List<Color> tierFill = [
    Palette.land,
    Palette.sun,
    Palette.orange,
    Color(0xFFFFB8CF),
    Palette.pink,
    Palette.ink,
  ];
  static const List<Color> tierText = [Palette.ink, Palette.ink, Palette.ink, Palette.ink, Palette.ink, Palette.paper];

  static const Color customFill = Color(0xFFF1F0EE);
  static const Color muted = HistoryRunStyle.muted;

  /// The first-tap mix: a row's label column and type, its bar, the rules
  /// between the bar's parts and their counts.
  static const double mixLabelWidth = 96;
  static const double mixLabelFont = 12.5;
  static const double mixLabelHeight = 1.2;
  static const double mixSubFont = 10.5;
  static const double mixBarHeight = 22;
  static const double mixRule = 1.2;
  static const double mixCountFont = 10;
  static const double mixRowGap = 10;

  static const double chipFont = 10;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(4, 1, 4, 2);

  /// The memorise bar and its ticks.
  static const double memoBarHeight = 20;
  static const double memoTick = 2.5;
  static const double memoTickOut = 5;

  /// The replayed field: its band, card words, the highlight round the card
  /// asked, the arrows from wrong taps (later taps' dashed) and the taps'
  /// numbered markers, on the field and in their legend.
  static const double fieldBand = 18;
  static const double fieldBandFont = 10;
  static const double fieldCardFont = 11;
  static const double fieldCardBorder = 1.5;
  static const double fieldMaxCardW = 29;
  static const EdgeInsets fieldCardPadding = EdgeInsets.all(2);
  static const double highlight = 3;
  static const double arrowStroke = 2.2;
  static const double arrowHead = 7;

  /// Half the angle of an arrow's head, radians.
  static const double arrowSpread = 0.45;
  static const double arrowBend = 0.25;
  static const Color arrow = Palette.pinkDeep;
  static const List<double> laterTapDash = [5, 3.5];
  static const double marker = 16;
  static const double markerFontShare = 0.62;
  static const double markerRing = 1.6;
  static const double legendMarker = 13;

  /// A reviewed step's cards that its taps did not touch, faded back.
  static const double unrelatedOpacity = 0.35;
  static const Duration dimFade = Duration(milliseconds: 160);
  static const EdgeInsets showAllPadding = EdgeInsets.fromLTRB(8, 4, 10, 4);
  static const double showAllIcon = 12;
  static const Color fieldGround = Color(0xFFEFF5E6);
  static const double stepFont = 16;
  static const double stepGap = 6;
  static const double stepSubFont = 11.5;
  static const double stepSubHeight = 1.3;

  /// The find-time chart numbers every bar up to [allLabelsUpTo] cards,
  /// else every [labelEvery]th.
  static const int allLabelsUpTo = 16;
  static const int labelEvery = 5;

  /// The score sum: big values over small labels, the result boxed.
  static const double sumFont = 18;
  static const double sumLabelFont = 9.5;
  static const double sumSignFont = 16;
  static const EdgeInsets sumSignPadding = EdgeInsets.fromLTRB(2, 2, 2, 0);
  static const EdgeInsets termPadding = EdgeInsets.fromLTRB(2, 5, 2, 6);
  static const EdgeInsets resultPadding = EdgeInsets.fromLTRB(8, 5, 8, 6);
  static const double termGap = 4;
}

/// History's run page: the Speed, Rating and XP tabs' panels, lines, cells
/// and small charts.
abstract final class RunTabsStyle {
  static const double panelBorder = Strokes.label;
  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(10, 9, 10, 10);
  static const EdgeInsets tableCellPadding = EdgeInsets.fromLTRB(3, 6, 3, 6);
  static const Color rule = Color(0xFFC9C5BE);

  static const TextStyle lineStyle = TextStyle(fontWeight: Weights.black, fontSize: 12);
  static const TextStyle rowStyle = TextStyle(fontWeight: Weights.bold, fontSize: 12);
  static const TextStyle noteStyle =
      TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont, color: HistoryRunStyle.muted);
  static const TextStyle headStyle =
      TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont, letterSpacing: 0.6);
  static const TextStyle valueStyle = TextStyle(fontFamily: Fonts.display, fontSize: 12.5);
  static const TextStyle cellValueStyle = TextStyle(fontFamily: Fonts.display, fontSize: 19, height: 1.2);
  static const TextStyle chartLabelStyle = TextStyle(
      fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: RunChartStyle.labelFont, color: HistoryRunStyle.behind);

  /// The card strip: its height, how far the fastest stretch's box reaches
  /// past it, and that box's line.
  static const double stripHeight = 26;
  static const double stripBoxReach = 4;
  static const double stripBoxStroke = 2.2;
  static const Color paceFast = Palette.landDeep;
  static const Color paceUnderGoal = Palette.land;
  static const Color paceSlow = Color(0xFFFFB3CB);
  static const Color paceMiss = Palette.pink;
  static const Color paceUnplayed = Color(0xFFE6E3DE);

  /// The 決まり字 length rows: label and bar shares of the row, the bar,
  /// the value's width at text scale 1, and room past the longest bar.
  static const double lengthRowGap = 6;
  static const int lengthLabelFlex = 4;
  static const int lengthBarFlex = 6;
  static const double lengthBarHeight = 12;
  static const double lengthValueWidth = 48;
  static const double lengthHeadroom = 1.1;

  /// A "usual" or "before" tick across a bar.
  static const double tickReach = 3;
  static const double tickStroke = 2.5;

  /// Between the small cards of the gained and lost rows.
  static const double tileGap = 6;

  /// The ranked runs' rating chart and table.
  static const double ratingChartHeight = 120;
  static const double ratingChartPad = 0.12;
  static const double ratingPointInset = 12;
  static const double ratingLineStroke = 2.2;
  static const double ratingPoint = 4.5;
  static const double ratingMineMark = 7;
}

/// `SwipeTabs`: the tab row over swiped pages, as slanted chips (a run
/// page's tabs) or as two folder tabs (History's lists).
abstract final class SwipeTabsStyle {
  static const double rule = Strokes.panel;
  static const double lineHeight = 1.1;
  static const Color idle = Color(0xFF6A665E);
  static const double subFont = 8.5;
  static const double subTracking = 0.85;
  static const Color folderIdleFill = Color(0xFFF3F1EC);
  static const double folderBar = 4;

  /// How much lower an unpicked folder tab stands, so the picked one looks
  /// pulled up in front.
  static const double folderDrop = 4;
  static const EdgeInsets folderPadding = EdgeInsets.fromLTRB(4, 6, 4, 7);
  static const double folderFont = 15;
  static const double folderSubFont = 9.5;
  static const double folderSubTracking = 1.1;

  /// The slanted chip of a run's page: the row's least height, its label,
  /// and the chip's inset from its tab, its top and its border.
  static const double slantHeight = 30;
  static const double slantFont = 13;
  static const Color slantIdle = Color(0xFF3A3A3A);
  static const EdgeInsets slantPadding = EdgeInsets.fromLTRB(4, 3, 4, 6);
  static const double chipInset = 3;
  static const double chipTop = 1;
  static const double chipBorder = 2.5;
}
