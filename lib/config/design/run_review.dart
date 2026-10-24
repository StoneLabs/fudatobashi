part of '../design.dart';

/// History's run review (`RunPageFrame` and its tabs), in the summary's
/// family: its header, a tab row whose open tab is a slanted chip in the
/// run kind's colour, then heroes, tilted tiles and panels stacked like the
/// journey home's, every shared edge rising [cut] over the column. Every
/// Overview is the summary's skeleton: a hero, three tiles, then the rest
/// down to the floor.
abstract final class ReviewLayout {
  static const double cut = HomeLayout.mapCut;
  static const double gap = Gaps.panel;
  static const double headerGap = SummaryLayout.headerGap;

  /// Between the tab row's rule and a tab's first panel, and under its
  /// last.
  static const double topGap = 8;
  static const double bottomGap = Gaps.panel;
  static const double heroHeight = 188;
  static const double tileHeight = 88;

  /// The panel that fills an Overview to the floor is never shorter than
  /// this; on a screen too short for it the whole Overview scrolls.
  static const double minFillHeight = 230;

  /// The largest font scale the page follows: the heroes and tiles have
  /// fixed sizes.
  static const double maxTextScale = SummaryLayout.maxTextScale;

  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(14, 12, 14, 14);

  /// A panel's heading and the room under it.
  static const double headingFont = 15;
  static const double headingGap = 10;

  /// A panel's prose, and a caption under a panel.
  static const double textFont = 12.5;
  static const double textHeight = 1.45;
  static const double captionFont = 11.5;
  static const double captionHeight = 1.4;

  /// The loud button of a tab (Practice these, Start review).
  static const double shoutHeight = 56;
  static const double shoutFont = 19;
  static const double shoutInset = 24;

  /// A warning in a pink box, and the ink rule between a panel's halves.
  static const EdgeInsets warningPadding = EdgeInsets.fromLTRB(8, 6, 8, 7);
  static const double dividerGap = 12;

  /// A label tracked in capitals over a shelf of cards.
  static const double shelfLabelFont = 11;
  static const double shelfLabelTracking = 0.14;
  static const double shelfGap = 8;
}

/// The run review's heroes (`HeroPanel` with [metrics]): the Overview's,
/// the rating's, 暗記練's rating and the experience.
abstract final class ReviewHeroLayout {
  static const metrics = HeroMetrics(
    countTop: 52,
    countFont: 80,
    wordTop: 54,
    plainWordTop: 66,
    plainWordFont: 52,
    wordWidth: 236,
    subTop: 108,
    timeTop: 66,
    timeFont: 66,
    tobi: Size(80, 95),
    stampAt: Offset(122, 122),
    topStampInset: Offset(14, 16),
  );

  /// The experience hero, its Tobi smaller.
  static const xpMetrics = HeroMetrics(
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
    topStampInset: Offset(22, 48),
  );

  /// 暗記練's rating hero: its lines across the whole panel.
  static const ankirenRatingMetrics = HeroMetrics(
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

  /// A figure as the answer (`HeroFigure`): a number at a top in a size,
  /// with a small word after it, a badge or a quiet line.
  static const double figureTop = 56;
  static const double figureFont = 52;
  static const double pointsTop = 64;
  static const double pointsFont = 60;
  static const double xpTop = 54;
  static const double xpFont = 46;
  static const double figureUnitFont = 17;
  static const double figureLineFont = 12.5;
  static const double figureGap = 10;

  /// A forfeit's word.
  static const double forfeitFont = 52;

  static const double ratingHeight = 166;
  static const double xpHeight = 150;
  static const double ankirenRatingHeight = 194;
  static const double ankirenLinesTop = 44;

  /// The exam's word and the line under it.
  static const double examWordFont = 40;
  static const double examSubFont = 17;
  static const double examSubOutline = 7;

  /// The focus lines of a goal reached, kept off the word (and the line
  /// under it).
  static const burst = BurstSpec(
      box: Size(352, 188),
      center: Offset(292, 96),
      count: 104,
      innerMin: 62,
      innerMax: 92,
      width: 3,
      seed: 3,
      clear: Rect.fromLTWH(6, 48, 250, 68));
  static const burstWithSub = BurstSpec(
      box: Size(352, 188),
      center: Offset(300, 92),
      count: 96,
      innerMin: 60,
      innerMax: 88,
      width: 3,
      seed: 9,
      clear: Rect.fromLTWH(6, 48, 236, 86));
}

/// The run review's tiles (`TileBand`): the Overview's three, and the
/// smaller ones of the Speed, Rating and Field tabs.
abstract final class ReviewTileLayout {
  static const spec = TileSpec(padding: EdgeInsets.fromLTRB(14, 12, 8, 13));
  static const small = TileSpec(
    padding: EdgeInsets.fromLTRB(11, 12, 8, 12),
    labelFont: 10,
    labelTracking: 0.1,
    noteFont: 11,
    lines: 2,
  );
  static const double smallFont = 24;
  static const double thirdsHeight = 96;
  static const double sidesHeight = 84;
  static const double ratingHeight = 80;

  /// The training view's four counts (`CountTiles`): the number with an
  /// icon beside it, over a label of up to two lines.
  static const double countHeight = 66;
  static const EdgeInsets countPadding = EdgeInsets.fromLTRB(10, 9, 8, 8);
  static const double countFont = 24;
  static const double countIcon = 15;
  static const double countIconStroke = 2.6;
  static const double countLabelFont = 9.5;
  static const double countLabelTracking = 0.1;
  static const double countLabelHeight = 1.2;
}

/// The run review's stamp (`RunStamp`): tilted, with a double ring, in
/// pink or muted grey.
abstract final class RunStampStyle {
  static const double tilt = -6;
  static const double maxScale = 1.15;
  static const Color paper = Color(0xE6FFFFFF);
  static const double border = 3;
  static const double ringGap = 2;
  static const double ring = 1.6;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(10, 5, 10, 6);
  static const double font = 15;
  static const double subFont = 10;
  static const double subTracking = 1.2;
  static const double subGap = 3;
}

/// The run review's lines of a label and its value (`ValueLine`): dotted
/// rules between them, the total under an ink rule with a bigger value.
abstract final class ValueLineStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(0, 7, 0, 6);
  static const EdgeInsets totalPadding = EdgeInsets.fromLTRB(0, 8, 0, 2);
  static const double font = 13;
  static const double valueFont = 15;
  static const double totalFont = 20;
  static const Color rule = Color(0xFF9A958D);
  static const List<double> dots = [1.5, 2];
}

/// The run review's cards (`SwipeCard`): a torifuda with its time in a
/// chip, its kimariji and its place in the run.
abstract final class ReviewCardStyle {
  static const double width = 40;
  static const double gap = 10;

  /// The slowest and fastest cards, side by side in two tilted panels.
  static const EdgeInsets shelfPadding = EdgeInsets.fromLTRB(12, 12, 12, 12);
  static const double shelfCardGap = 8;
  static const double chipGap = 5;
  static const double chipFont = 10.5;
  static const double chipBorder = 2;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(4, 2, 4, 3);
  static const double nameGap = 4;
  static const double nameFont = 11;
  static const double numberGap = 3;
  static const double numberFont = 10.5;
  static const double missRing = 2.5;
}

/// The run review's tables (`ReviewTable`): a head row in small tracked
/// capitals over an ink rule, rows on grey rules, a marked row tinted.
abstract final class ReviewTableStyle {
  static const double headFont = 9.5;
  static const double headTracking = 0.95;
  static const double cellFont = 11.5;
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 5);
  static const EdgeInsets headPadding = EdgeInsets.fromLTRB(4, 0, 4, 5);
  static const double rule = 1;
  static const double heavyRule = Strokes.label;

  /// A table that is a whole panel: the heading over it, its rows' inset
  /// from the panel's sides, and the room under the last row.
  static const EdgeInsets panelHeadPadding = EdgeInsets.fromLTRB(14, 12, 14, 10);
  static const EdgeInsets panelInset = EdgeInsets.symmetric(horizontal: 9);
  static const double panelFoot = 12;
}

/// The run review's text inside panels: captions, a stretch's facts, the
/// rows of a breakdown and a warning.
abstract final class ReviewTextStyle {
  static const TextStyle caption = TextStyle(
      fontWeight: Weights.bold,
      fontSize: ReviewLayout.captionFont,
      height: ReviewLayout.captionHeight,
      color: Palette.inkSoft);
  static const TextStyle factLabel = TextStyle(fontWeight: Weights.black, fontSize: 10, letterSpacing: 1.4, height: 1);
  static const TextStyle factValue = TextStyle(fontFamily: Fonts.display, fontSize: 22, height: 1);
  static const TextStyle factNote = TextStyle(fontWeight: Weights.bold, fontSize: 11, color: Palette.inkSoft);
  static const TextStyle rowLabel = TextStyle(fontWeight: Weights.black, fontSize: 12.5, height: 1.15);
  static const TextStyle rowNote = TextStyle(fontWeight: Weights.bold, fontSize: 10.5, color: Palette.inkSoft);
  static const TextStyle rowValue = TextStyle(fontFamily: Fonts.display, fontSize: 14, height: 1);
  static const TextStyle warning = TextStyle(fontWeight: Weights.black, fontSize: 12, height: 1.35);
  static const TextStyle strong =
      TextStyle(fontWeight: Weights.black, fontSize: ReviewLayout.textFont, height: ReviewLayout.textHeight);
  static const TextStyle headline = TextStyle(fontFamily: Fonts.display, fontSize: 24, height: 1.1);
}
