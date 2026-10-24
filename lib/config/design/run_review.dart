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

  /// An Overview's panels under its tiles are never shorter than this
  /// together; on a screen too short for them the whole Overview scrolls.
  static const double minRestHeight = 230;

  /// The largest font scale the heroes and tiles follow.
  static const double maxTextScale = SummaryLayout.maxTextScale;

  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(14, 12, 16, 14);

  /// A panel's heading row and the room under it.
  static const double headingFont = 15;
  static const double headingNoteFont = 11.5;
  static const double headingGap = 10;

  /// A panel's prose and the caption under a panel.
  static const double textFont = 12.5;
  static const double textHeight = 1.45;
  static const double captionFont = 11.5;
  static const double captionGap = 6;
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

  /// The smaller Tobi of the experience hero.
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

  /// A figure as the answer (`HeroFigure`): a number at [figureTop] in
  /// [figureFont], with a small word after it, a badge or a quiet line.
  static const double figureTop = 56;
  static const double figureFont = 52;
  static const double pointsTop = 64;
  static const double pointsFont = 60;
  static const double xpTop = 54;
  static const double xpFont = 46;
  static const double figureUnitFont = 17;
  static const double figureLineFont = 12.5;
  static const double figureGap = 10;

  static const double ratingHeight = 166;
  static const double xpHeight = 150;
  static const double ankirenRatingHeight = 194;

  /// The exam's word and the line under it.
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
/// smaller ones of the Speed and Rating tabs.
abstract final class ReviewTileLayout {
  static const spec = TileSpec(padding: EdgeInsets.fromLTRB(14, 12, 10, 13), lines: 2);
  static const small = TileSpec(
    padding: EdgeInsets.fromLTRB(11, 12, 8, 12),
    labelFont: 10,
    labelTracking: 0.1,
    noteFont: 11,
    lines: 2,
  );
  static const double smallFont = 24;
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
