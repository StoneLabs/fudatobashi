part of '../design.dart';

/// The card browser (`CardBrowserScreen`, Help › Tools): a search field
/// over a ruled table of the cards, each row's 五色 colour on a strip down
/// its left edge, what the search matched marked (`TextMarkStyle`).
abstract final class CardBrowserLayout {
  /// The search field: an ink box with the magnifier, the text and a round
  /// clear button; a sun shadow while typing.
  static const double searchHeight = 52;
  static const double searchBorder = Strokes.button;
  static const EdgeInsets searchPadding = EdgeInsets.fromLTRB(12, 0, 8, 0);
  static const double searchGap = 10;
  static const double searchFont = 17;
  static const Color searchHint = Color(0xFF8B8984);
  static const double searchFocusShadow = 4;
  static const double clearSize = 34;
  static const double clearIcon = 16;
  static const double clearStroke = 2.6;

  /// The line over the table: how many cards show, and what a tap does.
  static const EdgeInsets countPadding = EdgeInsets.fromLTRB(0, 14, 0, 8);
  static const double countFont = TypeScale.tiny;
  static const double hintFont = TypeScale.small;
  static const Color hintColor = Color(0xFF5C5A56);

  /// The table: an ink border and header band, rows split by hairlines.
  static const double tableBorder = Strokes.button;
  static const double rowRule = Strokes.hairline;
  static const double headerHeight = 30;
  static const double headerFont = 11;
  static const double headerTracking = 0.14;

  /// The columns: the number (as wide as the text is scaled), the kimariji
  /// (taking the rest) and a small torifuda before the chevron.
  static const double numberColumn = 52;
  static const double cardColumn = 70;
  static const double rowLeftPad = 14;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(rowLeftPad, 7, 4, 7);
  static const double rowMinHeight = 80;
  static const double strip = 5;
  static const double numberFont = 22;
  static const double kimarijiFont = 21;
  static const double kimarijiLineHeight = 1.2;
  static const double subFont = TypeScale.small;
  static const double subLineHeight = 1.3;
  static const Color subColor = Color(0xFF55534F);
  static const double subGap = 1;
  static const double tagFont = 10;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(4, 0, 4, 1);
  static const double tagGap = 5;
  static const double card = 46;
  static const double cardGap = 8;
  static const Offset cardShadow = Offset(1.5, 2);
  static const Color cardShadowColor = Color(0x40141414);
  static const double chevron = 16;
  static const double chevronColumn = 22;

  /// No match: a blank card with a question mark, a line on what to try
  /// and a button that clears the search.
  static const EdgeInsets emptyPadding = EdgeInsets.fromLTRB(18, 46, 18, 30);
  static const double emptyCard = 96;
  static const double emptyCardTurn = -6;
  static const double emptyMarkFont = 46;
  static const double emptyCardGap = 16;
  static const double emptyTitleFont = 19;
  static const double emptyTitleLineHeight = 1.3;
  static const double emptyTextGap = 8;
  static const double emptyTextFont = TypeScale.body;
  static const double emptyTextLineHeight = 1.5;
  static const double emptyButtonGap = 16;
  static const double emptyButtonHeight = 44;
  static const EdgeInsets emptyButtonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
  static const double emptyButtonFont = TypeScale.button;
  static const double emptyButtonIcon = 18;
  static const double emptyButtonIconGap = 8;
}
