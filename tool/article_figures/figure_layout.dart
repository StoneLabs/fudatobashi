import 'package:flutter/painting.dart';
import 'package:fudatobashi/config/design.dart';

/// The pictures as files: as wide as a guide's text on the user's phone
/// (384 dp less the gutters and the room for a panel's shadow), at this
/// many pixels per dp.
abstract final class FigureFile {
  static const double width = 348;
  static const double pixelRatio = 3;
}

/// The poems the karuta guide's pictures show, by id.
abstract final class KarutaGuideExamples {
  /// The poem split into its halves and shown as both kinds of card.
  static const int poem = 2;

  /// Two poems that share their first sounds: [readFirst] is read, and
  /// then [shortened] needs fewer.
  static const int readFirst = 2;
  static const int shortened = 67;

  /// The one-sound cards in the order players learn them.
  static const String oneSound = 'むすめふさほせ';
}

/// The karuta guide's own pictures.
abstract final class KarutaFigureLayout {
  /// The opening picture: a few cards fanned out.
  static const double fanCard = 58;
  static const List<int> fanPoems = [87, 2, 67, 77, 57];
  static const double fanStep = 34;
  static const double fanTurn = 0.13;
  static const double fanLift = 9;

  /// The poem in its two halves, each with a bar in its colour beside it.
  static const double poemFont = 17;
  static const double halfGap = 10;
  static const double halfBar = 6;
  static const double halfBarGap = 10;
  static const Color firstHalf = Palette.ink, secondHalf = Palette.pink;

  /// A reading card and a taking card side by side.
  static const double cardWidth = 92;
  static const double readingCardWidth = 124;
  static const double cardArrow = 26;
  static const double cardArrowGap = 8;

  /// The field: both sides' three rows of cards, the one just read in pink.
  static const List<int> fieldRows = [8, 8, 9];
  static const double fieldCardAspect = 0.72;
  static const double fieldCardGap = 0.18;
  static const double fieldMiddleGap = 1.4;
  static const double fieldRowGap = 0.22;
  static const double fieldCentre = 0.9;
  static const double fieldInset = 0.04;
  static const double fieldCardStroke = 1.2;
  static const double fieldLineStroke = 2;
  static const List<double> fieldLineDash = Strokes.dash;
  static const int fieldReadSide = 0, fieldReadRow = 2, fieldReadCard = 3;
}
