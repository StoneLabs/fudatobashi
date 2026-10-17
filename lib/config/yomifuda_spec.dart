import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'design.dart';

/// What a yomifuda skin swaps: the blank card it is printed on and the
/// colours and fonts of its text.
@immutable
class YomifudaStyle {
  const YomifudaStyle({
    required this.background,
    required this.ink,
    required this.kimariji,
    required this.number,
    required this.fontFamily,
    required this.numberFontFamily,
  });

  /// The blank card (`tool/card_backgrounds.py`), stretched over the card.
  final String background;
  final Color ink;

  /// The kimariji's colour.
  final Color kimariji;
  final Color number;
  final String fontFamily;
  final String numberFontFamily;

  /// The competition reading cards of research/yomifuda.
  static const standard = YomifudaStyle(
    background: 'assets/cards/yomifuda/default.png',
    ink: Color(0xFF161616),
    kimariji: Color(0xFFCC1C24),
    number: Color(0xFF2A2A2A),
    fontFamily: 'Yomifuda',
    numberFontFamily: Fonts.ui,
  );
}

/// Layout of a yomifuda (読み札), the competition reading card
/// (research/yomifuda: 52 × 75 mm), measured on the photos. Lengths across
/// the card are shares of its width, lengths down it shares of its height,
/// and lengths along a column in em, the size of its characters.
abstract final class YomifudaSpec {
  /// Height over width.
  static const double aspect = 75 / 52;

  /// The four columns' centres, right to left: verses 1–2, 3, 4 and 5.
  static const List<double> columnX = [0.793, 0.582, 0.370, 0.163];

  /// The first and third columns hang from [textTop]; the second and the
  /// fourth stand on [textBottom].
  static const double textTop = 0.088;
  static const double textBottom = 0.934;

  /// The characters' size, unless the longest column needs them smaller to
  /// fit between [textTop] and [textBottom].
  static const double em = 0.089;

  /// A character's glyph drawn at this share of its em, centred in it.
  static const double glyphScale = 1.06;

  /// Furigana: their size, and how far right of the column's centre they
  /// sit.
  static const double rubyScale = 0.34;
  static const double rubyOffset = 0.74;

  /// A held sound: a thin line as long as a character (ー) or about half
  /// one (ｰ), set in from both ends.
  static const double longStretch = 1.1;
  static const double shortStretch = 0.62;
  static const double stretchWidth = 0.055;
  static const double stretchInset = 0.1;

  /// The closing stroke after the last column, its gap before it and its
  /// length.
  static const double endGap = 0.35;
  static const double endLength = 2.1;

  /// The card's number in the bottom right corner: its size, and its right
  /// and bottom edges' distance from the card's, all shares of the width.
  static const double numberFont = 0.047;
  static const double numberRight = 0.062;
  static const double numberBottom = 0.07;
}
