part of '../design.dart';

/// Results' celebration overlays, which play over the run summary.
abstract final class ResultsLayout {
  /// The confusable-siblings heads-up (a 決まり字 look-alike warning).
  static const int confusableMaxSiblings = 2;
  static const double confusableTitleFont = 26;
  static const double confusableCardWidth = 96;
  static const double confusableKimarijiFont = 15;
  static const Placement confusableTobi = Placement(right: 18, bottom: tobiAboveCta, size: Size(70, 86));

  static const double goalTitleFont = 30;
  static const double goalNoteFont = 14;
  static const Placement goalTobi = Placement(right: 18, bottom: tobiAboveCta, size: Size(70, 86));

  /// Tobi stands just above a celebration's pinned CTA.
  static const double tobiAboveCta = PlayLayout.buttonRowHeight + Gaps.section * 2;

  /// A celebration's colour covers its art under the status bar, then fades
  /// out over this much, so the clock and icons stay readable.
  static const double statusScrimFade = 18;

  static const Duration overlayFade = Duration(milliseconds: 220);
  static const Duration overlayStagger = Duration(milliseconds: 500);
}

/// The run summary every game ends on (`run_summary.dart`): a header, the
/// hero whose bottom edge is a bar, three tilted tiles, the card panel and
/// the action row, on Home's dotted ground. Like the journey home's panels,
/// every shared edge rises [cut] over the column.
abstract final class SummaryLayout {
  static const double cut = HomeLayout.mapCut;
  static const double gap = Gaps.panel;
  static const double headerGap = 6;
  static const double heroHeight = 244;
  static const double tileHeight = 104;

  /// The card panel is never shorter than this, room for a line of cards; on
  /// a screen too short for it (a phone turned on its side) the hero, the
  /// tiles and the panel scroll.
  static const double minCardsHeight = 150;
  static const double actionGap = Gaps.panel;
  static const double bottomGap = HeaderStyle.topGap;

  /// The largest font scale its text follows: the hero and the tiles have
  /// fixed sizes.
  static const double maxTextScale = 1.3;
  static const EdgeInsets untrackedPadding = EdgeInsets.fromLTRB(7, 4, 7, 5);
}

/// Where a hero's answer, Tobi and stamp sit (`HeroPanel` and its bodies):
/// the summary's, or the run review's shorter hero's.
@immutable
class HeroMetrics {
  const HeroMetrics({
    required this.countTop,
    required this.countFont,
    required this.wordTop,
    required this.plainWordTop,
    required this.plainWordFont,
    required this.wordWidth,
    required this.subTop,
    required this.timeTop,
    required this.timeFont,
    required this.tobi,
    required this.stampAt,
    this.topStampInset = Offset.zero,
    this.bodyWidth = SummaryHeroLayout.bodyWidth,
  });

  final double countTop, countFont;

  /// A word's top, outlined or plain, the plain one's size, the width it
  /// fits, and the line under it.
  final double wordTop, plainWordTop, plainWordFont, wordWidth, subTop;
  final double timeTop, timeFont;

  /// Tobi's box, at his 84:100 aspect.
  final Size tobi;

  /// A stamp's top left over the bar, or how far one at the top right keeps
  /// from that corner.
  final Offset stampAt, topStampInset;

  /// The width the answer takes, left of Tobi.
  final double bodyWidth;
}

/// The summary's hero (`SummaryHero`): the banner, the big answer, the bar
/// along its slanted bottom edge, and Tobi standing on the bar.
abstract final class SummaryHeroLayout {
  static const Offset bannerAt = Offset(14, 14);
  static const double bannerFont = 14;

  /// The bar over the bottom border: its height, the ink rule along its top,
  /// the rules between its parts (this run's share of the day dashed), and
  /// its labels, the first this far from the hero's left edge and the rest
  /// [labelInset] from their part's edge.
  static const double bar = 34;
  static const double rule = 3;
  static const double split = Strokes.hairline;
  static const List<double> markedSplit = [3, 2.5];
  static const double labelFont = 12.5;
  static const double labelStart = 14;
  static const double labelInset = 8;

  /// Where the answer, Tobi and the stamp sit in the summary's hero.
  static const metrics = HeroMetrics(
    countTop: 72,
    countFont: 96,
    wordTop: 62,
    plainWordTop: 70,
    plainWordFont: 48,
    wordWidth: 256,
    subTop: 126,
    timeTop: 76,
    timeFont: 46,
    tobi: Size(84, 100),
    stampAt: Offset(124, 170),
  );

  /// The big answer, kept left of Tobi: a count with its label and note
  /// beside it (which take at most [countLabelShare] of the width), a word,
  /// or a time.
  static const double bodyLeft = 11;
  static const double bodyWidth = 240;
  static const double countTracking = -0.01;
  static const double countGap = 14;
  static const double countLabelShare = 0.6;
  static const double countLabelFont = 19;
  static const double countNoteFont = 13.5;
  static const double countNoteGap = 4;

  /// A word: outlined for a goal reached, plain and smaller otherwise; as
  /// big as fits the metrics' width up to its font size, with a line under
  /// it.
  static const double wordInset = 4;
  static const double wordFont = 57;
  static const double wordOutline = 11;
  static const double subFont = 13.5;
  static const double subTimeFont = 17;

  /// The milliseconds' size, as a share of the time's.
  static const double timeFractionShare = 0.5;

  /// Marks across the bar (an earlier rating): their line, reaching this
  /// far above the bar.
  static const double tick = 3;
  static const double tickReach = 5;

  /// Tobi stands on the bar where its done part ends, but never left of
  /// [tobiMinFront] of its length, so he never walks into the big number,
  /// and never closer than [tobiRightInset] to the right edge. His feet end
  /// [tobiFeet] of the way down his box.
  static const double tobiMinFront = 0.81;
  static const double tobiRightInset = Strokes.panel + 12;
  static const double tobiFeet = 0.93;

  /// His balloon, its left edge this far from his middle.
  static const double balloonLeft = -85;
  static const double balloonTop = 30;
  static const Size balloon = Size(90, 48);
  static const Alignment balloonSpeaker = Alignment(1.15, 1.75);
  static const double balloonFont = 13.5;

  /// Tobi says the day is almost done once at most this share of today's
  /// set is left.
  static const double almostThere = 0.25;

  /// The 本日完了 stamp of the run that finished the day's set.
  static const double stampFont = 23;

  /// Focus lines for a goal reached, left out where they would cross the
  /// word (and, with [burstWithSub], the line under it).
  static const burst = BurstSpec(
      box: Size(352, 244),
      center: Offset(292, 120),
      count: 104,
      innerMin: 62,
      innerMax: 92,
      width: 3,
      seed: 3,
      clear: Rect.fromLTWH(6, 54, 262, 80));
  static const burstWithSub = BurstSpec(
      box: Size(352, 244),
      center: Offset(292, 120),
      count: 104,
      innerMin: 62,
      innerMax: 92,
      width: 3,
      seed: 3,
      clear: Rect.fromLTWH(6, 54, 248, 106));
}

/// The summary's three tiles (`SummaryTile`): how much was played, how much
/// was right, and the reward, each a slice of one band rising with the
/// panels' edges.
abstract final class SummaryTileLayout {
  static const List<Color> colors = [Palette.seaSoft, Palette.landSoft, Palette.sunSoft];
  static const spec = TileSpec(padding: EdgeInsets.fromLTRB(14, 14, 10, 20));
  static const double bigFont = 28;
  static const double bigSmallFont = 15;
  static const double strikeCard = 28;

  /// The least room between a tile's lines, and their line height when a
  /// label or note may wrap.
  static const double rowGap = 4;
  static const double lineHeight = 1.1;
}

/// A band of tilted tiles (`TileBand`): the room inside each tile, its
/// label's and note's type and how many lines each may take.
@immutable
class TileSpec {
  const TileSpec({
    required this.padding,
    this.labelFont = 11,
    this.labelTracking = 0.14,
    this.noteFont = 12,
    this.lines = 1,
  });

  final EdgeInsets padding;
  final double labelFont, labelTracking, noteFont;
  final int lines;
}

/// The summary's card panel (`SummaryRow`): rows of a marker heading with a
/// note beside cards, the week's stamps, the levels or a dashed note,
/// spread out to fill the panel with dotted rules between them.
abstract final class SummaryPanelLayout {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 31, 20, 19);
  static const double headWidth = 90;
  static const double headGap = 8;
  static const double headFont = 15;
  static const double noteFont = 11.5;
  static const double noteGap = 4;
  static const double rowGap = 12;
  static const double dot = 2;
  static const double dotStep = 4;
  static const Color dotColor = Color(0x47141414);

  /// Cards: [perLine] a line, or with more of them [densePerLine] smaller
  /// ones; past what the row's lines hold, the last place says how many
  /// more.
  static const double card = 49;
  static const double denseCard = 40;
  static const double cardGap = 8;
  static const double denseCardGap = 5;
  static const double cardRunGap = 6;
  static const int perLine = 4;
  static const int densePerLine = 5;
  static const double moreFont = 13;
  static const double kimarijiFont = 11.5;
  static const double kimarijiGap = 5;
  static const double badgeGap = 4;
  static const double badgeFont = 10.5;
  static const double tagFont = 10;
  static const EdgeInsets badgePadding = EdgeInsets.fromLTRB(4, 2, 4, 3);
  static const double badgeBorder = 2;
  static const double tailGap = 6;
  static const double tailFont = 12;
  static const double noteBoxFont = 12;
  static const EdgeInsets noteBoxPadding = EdgeInsets.fromLTRB(10, 8, 10, 9);

  /// The week's stamps of the streak row.
  static const double stamp = 18;
  static const double stampGap = 9;

  /// 暗記練's levels: a square each, cleared, open, failed or still shut.
  static const double level = 18;
  static const double levelGap = 2.2;
  static const double levelFont = 9.5;
  static const double levelBorder = 2;
  static const double shutOpacity = 0.5;
}

/// The summary's action row: Home (or Done) and the shout.
abstract final class SummaryActionLayout {
  static const double height = 64;
  static const Size home = Size(64, 56);
  static const double homeIcon = 22;
  static const double homeFont = 12.5;
  static const double homeGap = 3;
  static const double gap = 12;
  static const ShoutSpec shout = HomeLayout.journeyShout;
  static const double shoutFont = 19;

  /// How far the shout's lettering keeps off its sides, clear of the spikes.
  static const double shoutInset = 24;
}
