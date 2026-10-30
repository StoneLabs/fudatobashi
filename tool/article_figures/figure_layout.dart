import 'package:flutter/painting.dart';
import 'package:fudatobashi/config/design.dart';

/// The pictures as files: as wide as a guide's text on the user's phone
/// (384 dp less the gutters and the room for a panel's shadow), at this
/// many pixels per dp.
abstract final class FigureFile {
  static const double width = 348;
  static const double pixelRatio = 3;

  /// Room enough for the tallest picture.
  static const double maxHeight = 2000;

  /// The space inside a picture's panel.
  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(12, 14, 12, 12);
}

/// The words a picture holds, by language: the stamp on a card that has
/// been read.
abstract final class FigureWords {
  static const read = {'en': 'Read', 'ja': '読まれた'};
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

/// The cards the kimariji guide's pictures show, by id.
abstract final class FirstSoundsExamples {
  /// The card whose stairs the guide walks down. Its kimariji shares all
  /// but its last kana with exactly one other card.
  static const int card = 1;

  /// A card whose top step ends on a consonant because the one other card
  /// that starts the same way goes on with a vowel.
  static const int consonant = 15;
}

/// Kimariji pictures: kana tiles, an arrow, the card they mean.
abstract final class KimarijiFigureLayout {
  static const double tile = 34;
  static const double tileFont = 20;
  static const double tileGap = 4;
  static const double tileBorder = Strokes.label;
  static const double romajiFont = 10.5;
  static const double romajiGap = 2;
  static const double card = 66;
  static const double arrow = 24;
  static const double arrowGap = 10;
  static const double rowGap = 14;
  static const double readOpacity = 0.35;
  static const double stampFont = 13;
  static const double stampTurn = -0.22;
  static const double stampBorder = 2.5;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
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

/// The sides the 定位置 guide's pictures lay out, by poem id: each row as
/// its left cluster from the edge in, its middle cards and its right
/// cluster from the inside out, 上段 (by the centre line) first.
abstract final class TeiichiGuideExamples {
  /// A side with the fewest cards on top, the なげ pair side by side in
  /// 下段.
  static const List<(List<int>, List<int>, List<int>)> base = [
    ([1, 2, 3], [], [4, 5, 76, 11]),
    ([8, 9, 10, 12], [], [31, 64, 15, 50]),
    ([87, 18, 53, 86, 57], [], [22, 70, 19, 81, 77]),
  ];

  /// The cards outlined in the first picture.
  static const List<int> outlined = [2, 50, 87, 22];

  /// The one-sound cards over both clusters of 下段, and the six-sound
  /// cards at the right's outer end of 中段 and 下段, each pair one above
  /// the other.
  static const List<(List<int>, List<int>, List<int>)> firstCards = [
    ([1, 2, 3], [], [4, 5, 6, 7]),
    ([8, 9, 10, 12], [], [13, 31, 15, 76]),
    ([87, 18, 57, 22], [], [70, 81, 77, 64, 50, 11]),
  ];
  static const List<int> sixSound = [31, 64, 15, 50, 76, 11];

  /// The base side with the なげ pair split, one in each cluster.
  static const List<(List<int>, List<int>, List<int>)> lookAlikeSplit = [
    ([1, 2, 3], [], [4, 5, 76, 11]),
    ([8, 9, 10, 12], [], [31, 64, 15, 50]),
    ([87, 18, 53, 19, 57], [], [22, 70, 86, 81, 77]),
  ];

  static const List<int> lookAlikes = [53, 86];

  /// The rows' clusters as blocks, toned by how full they usually are,
  /// and one card alone in the middle of 上段.
  static const List<(List<int>, List<int>, List<int>)> fullness = [
    ([1, 2, 3], [4], [5, 6, 7]),
    ([8, 9, 10, 12], [], [13, 14, 16, 17]),
    ([87, 18, 53, 86, 57], [], [22, 70, 19, 81, 77]),
  ];

  /// The base side after [gone] were taken, with its gaps closed: the
  /// cards in [moved] came down a row or across from where they lay.
  static const List<int> gone = [53, 86, 19];
  static const List<(List<int>, List<int>, List<int>)> closed = [
    ([1, 2, 3, 4], [], [5, 76, 11]),
    ([8, 9], [], [64, 15, 50]),
    ([87, 18, 10, 12, 57], [], [22, 70, 31, 81, 77]),
  ];
  static const List<int> moved = [10, 12, 31, 4];

  /// The other player's side, new every game.
  static const List<(List<int>, List<int>, List<int>)> theirs = [
    ([20, 21, 24, 26], [], [27, 28, 29, 32]),
    ([34, 35, 36, 37], [], [38, 39, 41, 43]),
    ([44, 46, 47, 48, 49], [], [51, 52, 54, 55]),
  ];
}

/// The 定位置 guide's pictures: sides as the game lays them out once it
/// has grown for play, the open middle of the widest row closed to
/// `TeiichiPlayLayout.zoomGap`.
abstract final class TeiichiFigureLayout {
  /// `TeiichiZoom`'s limit with no screen to fit, so the rows alone bound it.
  static const Size zoomArea = Size(1, 1e9);

  /// The dashed centre line above a side, this many card heights over 上段.
  static const double centreLine = 0.42;
  static const double lineStroke = KarutaFigureLayout.fieldLineStroke;

  /// A card is drawn this far inside its place, so that neighbours that
  /// all but touch, as on the tatami, still read as cards.
  static const double cardInset = 0.7;
  static const double cardStroke = KarutaFigureLayout.fieldCardStroke;
  static const double outlineStroke = 2.5;
  static const List<double> spotDash = Strokes.fineDash;

  /// Kana on a card: one as large as this share of its width, a column
  /// of them sharing this share of its height, and two columns this share
  /// of its width.
  static const double kanaShare = 0.62;
  static const double kanaColumnShare = 0.9;
  static const double kanaTwoColumnShare = 0.84;
  static const Color oneSound = Palette.alarm, oneSoundKana = Palette.paper;
  static const Color lookAlike = Palette.pink, lookAlikeKana = Palette.ink;
  static const Color sixSound = Palette.sea, sixSoundKana = Palette.paper;
  static const Color moved = Palette.sun;

  /// Romaji under 下段's marked cards, at least [romajiSpace] apart.
  static const double romajiGap = 3;
  static const double romajiSpace = 6;

  /// A kimariji longer than this goes down the card in two columns.
  static const int kanaColumn = 3;

  /// Two versions of a side, one panel above the other; three as two
  /// small panels side by side above a full one.
  static const double panelGap = 10;

  /// A move's arrow: ink on a paper halo, from the middle of where the
  /// card lay to the edge of where it lies now, its head [arrowHead] long
  /// and [arrowHeadWidth] of that wide.
  static const double arrowStroke = 2;
  static const double arrowHalo = 3.5;
  static const double arrowHead = 6;
  static const double arrowHeadWidth = 1.1;

  /// A row's clusters as blocks in a screentone of these dot radii, by
  /// how full they usually are: 上段 first, left then right.
  static const double toneSpacing = 5;
  static const List<(double, double)> fullness = [(0.5, 0.72), (0.88, 1.08), (1.22, 1.42)];

  /// Placing time: the sides at this share of the width, a large clock
  /// beside theirs and a small stopwatch beside yours.
  static const double timeFieldShare = 0.74;
  static const double timeCentre = 0.9;
  static const double clockSize = 70;
  static const double watchSize = 34;
  static const double clockStroke = 2.5;
  static const double watchStroke = 2;
  static const int clockTicks = 12;
  static const double clockTick = 0.16, clockQuarterTick = 0.26;
  static const double matchMinutes = 15, clockMinutes = 60;
  static const double placingTurn = 0.86;

  /// The stopwatch, in its radii: its crown, its button turned
  /// [watchButtonTurn] round from it, and its time shaded over
  /// [watchDial] of its face.
  static const Rect watchCrown = Rect.fromLTRB(-0.3, -1.42, 0.3, -0.9);
  static const Rect watchButton = Rect.fromLTRB(-0.2, -1.3, 0.2, -0.85);
  static const double watchButtonTurn = 0.115;
  static const double watchDial = 0.78;
  static const double handStroke = 2;
  static const double handDot = 2.4;
}
