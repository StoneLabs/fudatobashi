part of '../design.dart';

/// 定位置's page (`teiichi_page.dart`), on 暗記練's page's frame
/// ([AnkirenPageLayout]): the banner, ranked, the guide's card and the next
/// level to clear.
abstract final class TeiichiPageLayout {
  /// The next level's preview of its side of the field: its rows at most
  /// this tall, this far inside its frame.
  static const double previewHeight = 54;
  static const double previewInset = 6;

  /// On a screen with room to spare, ranked takes this share of it.
  static const double rankedShare = 1;

  /// The guide's card, one short row, [learnTop] under ranked: its title,
  /// [learnGap] before the button.
  static const double learnTop = 4;
  static const EdgeInsets learnPadding = EdgeInsets.fromLTRB(14, 4, 8, 4);
  static const double learnTitleFont = 16;
  static const double learnGap = 8;
  static const double buttonFont = 13;
  static const double buttonIcon = 14;
  static const double buttonIconGap = 5;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
}

/// 定位置's level sheet (`teiichi_sheet.dart`), on 暗記練's sheet frame
/// ([AnkirenSheetLayout]): the level keys, [keysPerRow] a row; then for a
/// custom game the card count's keys, the rows' keys, each its count over
/// what it holds, and the notes under them.
abstract final class TeiichiSheetLayout {
  static const int keysPerRow = 5;
  static const double cardKeyFont = 19;
  static const double rowKeyHeight = 54;
  static const double rowKeyFont = 18;
  static const double rowKeySubFont = 10.5;
  static const double rowKeyLock = 11;
  static const double rowKeyLockGap = 3;
  static const double noteFont = 12.5;

  /// The note that the rows went up, marked like a highlighter.
  static const Color wentUpMark = Palette.sun;
}

/// 定位置's play screen (`teiichi_screen.dart`) on 暗記練's landscape field
/// ([AnkirenPlayLayout]): the own side alone, the stack where the other
/// player's side would be, and the dashed spots a card can go.
abstract final class TeiichiPlayLayout {
  /// The room above the band never gets shorter than this, for the stack.
  static const double roomAbove = 118;

  /// A game with からふだ: once Done is pressed the band rises into the room
  /// above, to [karafudaBandLandscape] tall in landscape and as tall as
  /// 暗記練's band with strikes in portrait, for "don't know" over the
  /// からふだ button. A level without any rises so in portrait alone, for
  /// the strikes over End.
  static const double karafudaBandLandscape = 80;
  static const double karafudaBandPortrait = AnkirenPlayLayout.bandPortraitStrikes;

  /// The stack: its top card as tall as the room above the band allows,
  /// up to [stackCardH] (so larger in portrait, with room to spare),
  /// [stackDepth] cards' edges peeking out under it [stackStep] apart, over
  /// its count on an ink tag that overlaps the card's foot by
  /// [stackTagOverlap].
  static const double stackCardH = 180;
  static const double stackMargin = 6;
  static const int stackDepth = 3;
  static const double stackStep = 2.5;
  static const double stackTagOverlap = 4;
  static const double stackTagRoom = 20;
  static const double stackTagFont = 13;
  static const EdgeInsets stackTagPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);

  /// The hint left of the stack, and the note right of it once every card
  /// is placed: paper boxes, [noteGap] from the stack, at most [noteWidth]
  /// wide; above the stack when there is less than [noteMinWidth] beside
  /// it.
  static const double noteGap = 18;
  static const double noteWidth = 330;
  static const double noteMinWidth = 200;
  static const double noteFont = 12.5;
  static const double noteIcon = 16;
  static const EdgeInsets notePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 7);

  /// A dashed spot on the tatami, and the open middle's label in it.
  static const Color spotInk = Color(0xEEFFFFFF);
  static const Color spotFill = Color(0x14FFFFFF);
  static const double spotBorder = Strokes.label;
  static const double middleLabelFont = 10;
  static const double middleLabelTracking = 0.16;

  /// The open middle shows its name only in a stretch clear of cards at
  /// least this wide.
  static const double middleLabelRoom = 60;

  /// Where a dragged card would land: sun over its spot, outlined in ink,
  /// with its name on an ink tag above it.
  static const Color landingFill = Color(0x99FFD53D);
  static const double landingBorder = 2.5;
  static const double landingTagFont = 11.5;
  static const double landingTagGap = 4;
  static const double landingTagRoom = 26;

  /// A dragged card rides above the finger, its foot [dragLift] of its
  /// height up so the finger never hides it, [dragScale] times its size
  /// and at least [dragLeastWidth] wide, with an ink outline.
  static const double dragLift = 0.55;
  static const double dragScale = 1.1;
  static const double dragLeastWidth = 48;
  static const double dragBorder = 2.5;

  /// Cards opening a gap, closing one, or taking a new place.
  static const Duration move = Duration(milliseconds: 180);

  /// After Done the field grows for play (`TeiichiZoom`), over [zoomTime],
  /// until a row without middle cards has only [zoomGap] card widths left
  /// between its clusters, or a row with middle cards [zoomMiddleGap]
  /// between a cluster and its middle cards, or the band reaches the top.
  static const Duration zoomTime = Duration(milliseconds: 400);
  static const Curve zoomCurve = Curves.easeInOut;
  static const double zoomGap = 2.5;
  static const double zoomMiddleGap = 1.25;
}

/// 定位置's rules: its steps' pictures, drawn as 暗記練's are, and the
/// placing times the scoring's bonus table prices, slowest first.
abstract final class TeiichiRulesLayout {
  static const String place = 'assets/graphics/sidetrips/teiichi/howto-place.webp';
  static const String flip = 'assets/graphics/sidetrips/teiichi/howto-flip.webp';
  static const String take = 'assets/graphics/sidetrips/teiichi/howto-take.webp';
  static const List<Duration> bonusTimes = [
    Duration(minutes: 15),
    Duration(minutes: 7, seconds: 30),
    Duration(minutes: 3),
    Duration(minutes: 1, seconds: 30),
    Duration(minutes: 1),
    Duration(seconds: 30),
  ];
}
