part of '../design.dart';

/// 定位置's page (`teiichi_page.dart`), on 暗記練's page's frame
/// ([AnkirenPageLayout]): ranked, still to come, and the guide's card.
abstract final class TeiichiPageLayout {
  /// Ranked's chained-up inside is at least this tall, as 暗記練's, its row
  /// in the middle.
  static const double rankedHeight = 112;

  /// On a screen with room to spare, ranked and the guide's card take
  /// these shares of it.
  static const double rankedShare = 0.4;
  static const double learnShare = 0.6;

  /// The guide's card: its title, line and button at most [learnMeasure]
  /// wide at the type's size, the same lines on every phone, and Tobi in
  /// the room beside them, at most [learnTobi] and, with large type, at
  /// least [learnTobiLeast] wide.
  static const EdgeInsets learnPadding = EdgeInsets.all(16);
  static const double learnMeasure = 180;
  static const Size learnTobi = Size(126, 150);
  static const double learnTobiLeast = 64;
  static const double learnTobiGap = 20;
  static const double learnTitleFont = 22;
  static const double learnLineFont = 13.5;
  static const double learnLineHeight = 1.5;
  static const double learnLineGap = 6;
  static const double buttonTop = 12;
  static const double buttonFont = 15;
  static const double buttonIcon = 16;
  static const double buttonIconGap = 8;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);

  /// The guide still to come: its line under the header.
  static const double guideLineFont = 15;
}

/// 定位置's custom game sheet (`teiichi_sheet.dart`), on 暗記練's sheet frame
/// ([AnkirenSheetLayout]): the card count's keys, then the rows' keys, each
/// its count over what it holds, and the notes under them.
abstract final class TeiichiSheetLayout {
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

  /// The stack: its top card at most [stackCardH] tall, [stackDepth] cards'
  /// edges peeking out under it [stackStep] apart, over its count on an ink
  /// tag that overlaps the card's foot by [stackTagOverlap].
  static const double stackCardH = 100;
  static const double stackMargin = 6;
  static const int stackDepth = 3;
  static const double stackStep = 2.5;
  static const double stackTagOverlap = 4;
  static const double stackTagRoom = 20;
  static const double stackTagFont = 13;
  static const EdgeInsets stackTagPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);

  /// The hint left of the stack, and the note right of it once every card
  /// is placed: paper boxes, [noteGap] from the stack, at most [noteWidth]
  /// wide.
  static const double noteGap = 18;
  static const double noteWidth = 330;
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
  static const EdgeInsets landingTagPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);

  /// A dragged card rides above the finger, [dragLift] of a card's height
  /// up so the finger never hides it, [dragScale] times its size, with an
  /// ink outline.
  static const double dragLift = 0.6;
  static const double dragScale = 1.1;
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

/// 定位置's rules: the placing step's picture, a stand-in until its art is
/// drawn.
abstract final class TeiichiRulesLayout {
  static const String place = 'assets/graphics/sidetrips/teiichi/howto-place.webp';
}
