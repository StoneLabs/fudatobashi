import 'dart:ui';

import 'package:flutter/foundation.dart';

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
    required this.fontCentre,
    required this.numberFontFamily,
  });

  /// The blank card (`tool/card_backgrounds.py`), stretched over the card.
  final String background;
  final Color ink;

  /// The kimariji's colour, and a titled card's title's.
  final Color kimariji;
  final Color number;
  final String fontFamily;

  /// How far above its baseline [fontFamily]'s em box is centred, a share
  /// of its size (its OS/2 typo ascender and descender, halved).
  final double fontCentre;
  final String numberFontFamily;

  /// The competition reading cards of research/yomifuda.
  static const standard = YomifudaStyle(
    background: 'assets/graphics/cards/yomifuda/default.svg',
    ink: Color(0xFF141414),
    kimariji: Color(0xFFD21C22),
    number: Color(0xFF222222),
    fontFamily: 'YujiSyuku',
    fontCentre: 0.38,
    numberFontFamily: 'TorifudaNumber',
  );
}

/// Layout of a yomifuda (読み札), the competition reading card
/// (research/yomifuda: 52 × 75 mm), measured on the photos. Lengths across
/// the card are shares of its width, lengths down it shares of its height,
/// and lengths along a column in em, the pitch of its characters.
abstract final class YomifudaSpec {
  /// Height over width.
  static const double aspect = 75 / 52;

  /// The four columns' centres, right to left: verses 1–2, 3, 4 and 5.
  static const List<double> columnX = [0.792, 0.582, 0.372, 0.162];

  /// A titled card (the 序歌's) prints its title in red down a column of its
  /// own at [titleX]: a little smaller than the poem, not widened like it
  /// and thickened by [titleBold] (a share of its size), its first
  /// character's box starting [titleTop] down the card and each next one
  /// [titlePitch] em further. The poem's columns move left and closer
  /// together to make room.
  static const double titleX = 0.848;
  static const double titleTop = 0.19;
  static const double titleScale = 0.8;
  static const double titleWidth = 1;
  static const double titleBold = 0.03;
  static const double titlePitch = 3;
  static const List<double> titledColumnX = [0.657, 0.484, 0.312, 0.141];

  /// The first and third columns hang from [textTop]; the second and the
  /// fourth stand on [textBottom].
  static const double textTop = 0.086;
  static const double textBottom = 0.937;

  /// The characters' pitch down a column. A column too long for the card
  /// has its characters flattened to fit, as the printed cards do; its held
  /// sounds and closing stroke keep their length.
  static const double em = 0.1048;

  /// A character's glyph: its font size as a share of the em, and how much
  /// it is widened (the printed kana are rounder than the font's).
  static const double glyphScale = 1.0;
  static const double glyphWidth = 1.1;

  /// Furigana: their font size, the least pitch they pack to, how far right
  /// of the column's centre they sit, and how much they are thickened (a
  /// share of their size), as the printed ones are heavier than the text.
  static const double rubyScale = 0.46;
  static const double rubyOffset = 0.78;
  static const double rubyBold = 0.035;

  /// A held sound: a thin line about three quarters of a character long
  /// (ー) or half one (ｰ), running nearly the whole gap it fills, a little
  /// right of the column's centre.
  static const double longStretch = 0.77;
  static const double shortStretch = 0.53;
  static const double stretchWidth = 0.065;
  static const double stretchInset = 0.02;
  static const double stretchOffset = 0.045;

  /// The upper verse's last held sound, at the foot of the second column,
  /// is printed short whichever mark the reading gives it.
  static const double upperEndStretch = shortStretch;

  /// The closing stroke after the last column, its gap before it and its
  /// length.
  static const double endGap = 0.17;
  static const double endLength = 1.8;

  /// The card's number in the bottom right corner: its size, and the
  /// distance of its right edge and its baseline from the card's right and
  /// bottom edges, all shares of the width; and how much it is thickened,
  /// a share of its size.
  static const double numberFont = 0.053;
  static const double numberRight = 0.0715;
  static const double numberBottom = 0.068;
  static const double numberBold = 0.02;
}
