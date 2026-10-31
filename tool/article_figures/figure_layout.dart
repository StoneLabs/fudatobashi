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

  /// The 定位置 guide's two games, and a side's rows from the centre line
  /// down.
  static const games = {
    'en': ['Game 1', 'Game 2'],
    'ja': ['1試合目', '2試合目'],
  };
  static const rows = {
    'en': ['Top', 'Middle', 'Bottom'],
    'ja': ['上段', '中段', '下段'],
  };
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

  /// Your side in two games, dealt different cards, the ones in [fixed]
  /// in the same places in both: 上段's second from the right, 中段's
  /// second from the left, 下段's first from the left and third from the
  /// right.
  static const List<(List<int>, List<int>, List<int>)> gameOne = [
    ([1, 2, 3], [], [4, 5, 43, 6]),
    ([8, 74, 9, 10], [], [12, 13, 14, 16]),
    ([87, 18, 20, 21, 23], [], [24, 25, 81, 26, 27]),
  ];
  static const List<(List<int>, List<int>, List<int>)> gameTwo = [
    ([30, 32, 33, 34], [], [35, 43, 36]),
    ([37, 74, 38], [], [39, 40, 41, 42, 44]),
    ([87, 45, 46, 47], [], [48, 49, 51, 81, 52, 54]),
  ];
  static const List<int> fixed = [43, 74, 87, 81];

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
  static const List<double> spotDash = Strokes.fineDash;

  /// Kana on a card: one as large as this share of its width, a column
  /// of them sharing this share of its height, and two columns this share
  /// of its width. Romaji goes across it, at most [cardRomajiFont] and
  /// inside [cardRomajiInset].
  static const double kanaShare = 0.62;
  static const double kanaColumnShare = 0.9;
  static const double kanaTwoColumnShare = 0.84;
  static const double cardRomajiFont = 11;
  static const double cardRomajiInset = 1.5;
  static const Color oneSound = Palette.alarm, oneSoundKana = Palette.paper;
  static const Color lookAlike = Palette.pink, lookAlikeKana = Palette.ink;
  static const Color sixSound = Palette.sea, sixSoundKana = Palette.paper;
  static const Color moved = Palette.sun;

  /// The cards in `TeiichiGuideExamples.fixed`, each in its own colour,
  /// its kimariji on it in the second.
  static const List<(Color, Color)> fixed = [
    (Palette.pink, Palette.ink),
    (Palette.sea, Palette.paper),
    (Palette.sun, Palette.ink),
    (Palette.violet, Palette.paper),
  ];

  /// The rows' names down the open middle of a side, and a game's name in
  /// an ink tag above it.
  static const double rowFont = 11;
  static const double gameFont = 11;
  static const EdgeInsets gamePadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
  static const double gameGap = 2;

  /// Romaji under 下段's marked cards, at least [romajiSpace] apart.
  static const double romajiGap = 3;
  static const double romajiSpace = 6;

  /// Kimariji too long to go under their cards: in a box at the side's
  /// right edge, [calloutGap] under the side and its romaji, its tail up
  /// to the cards, which it shows as chips laid out as the cards lie.
  static const double calloutGap = 12;
  static const double calloutFont = 11.5;
  static const EdgeInsets calloutPadding = EdgeInsets.all(6);
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(7, 3, 7, 4);
  static const double chipGap = 4;
  static const double calloutStroke = Strokes.label;
  static const double calloutTail = 14;
  static const double calloutTip = 2;

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

  /// Memorising time: the sides at this share of the width, and beside
  /// each the same 15-minute timer, its minutes ticked round the dial, a
  /// longer tick every [longTickEvery]. The minutes spent on that side
  /// are filled: [yourMinutes] first, the rest for theirs.
  static const double timeFieldShare = 0.74;
  static const double timeCentre = 0.9;
  static const double timerSize = 62;
  static const double timerStroke = 2.5;
  static const double tickStroke = 1.8;
  static const int timerMinutes = 15;
  static const int yourMinutes = 1;
  static const int longTickEvery = 5;
  static const double tick = 0.16, longTick = 0.27;
  static const double centreDot = 3;

  /// The timer, in its radii: its crown, and its button turned
  /// [timerButtonTurn] round from it.
  static const Rect timerCrown = Rect.fromLTRB(-0.24, -1.3, 0.24, -0.9);
  static const Rect timerButton = Rect.fromLTRB(-0.16, -1.22, 0.16, -0.88);
  static const double timerButtonTurn = 0.115;
}
