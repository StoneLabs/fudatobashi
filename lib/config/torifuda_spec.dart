import 'dart:ui';

/// Geometry and colours of a torifuda, in "card units": the card is exactly
/// 374 × 525 units (73 × 52 mm ratio), matching the original app's artwork,
/// which these values are calibrated against (see tool/calibrate/).
abstract final class TorifudaSpec {
  static const double width = 374;
  static const double height = 525;
  static const double aspect = height / width;

  // Frame (the green backing paper folded over the edge).
  static const frameColor = Color(0xFF6A9354);

  /// Hairline just outside the paper, slightly darker than the frame.
  static const frameShade = Color(0xFF628D4B);

  // Paper.
  static const paper = Rect.fromLTRB(17.35, 19.55, 356.6, 505.45);
  static const paperColor = Color(0xFFEAEAEA);

  /// Hairline just inside the paper edge, slightly lighter than the paper.
  static const paperHighlight = Color(0xFFF0EFF0);

  // Glyph grid. Three columns, right to left, split 5 / 5 / rest,
  // all starting at the top row.
  static const String fontFamily = 'Torifuda';
  static const inkColor = Color(0xFF222222);
  static const double fontSize = 75.5;
  static const List<double> columnCenterX = [289.1, 187.9, 90.0];
  static const double row0CenterY = 79.4;
  static const double rowPitch = 89.7;

  /// A column with more than five kana (only #21 has six) keeps the first and
  /// last row centres and tightens the pitch, like the original cards.
  static const double lastRowCenterY = 438.2;

  static double rowCenterY(int row, int columnLength) => columnLength <= 5
      ? row0CenterY + row * rowPitch
      : row0CenterY + row * (lastRowCenterY - row0CenterY) / (columnLength - 1);

  /// Vertical offset of the glyph em box relative to the cell centre,
  /// as a fraction of [fontSize] (font dependent; fitted by calibration).
  static const double glyphDy = 0;

  // Poem-number badge (bottom left).
  static const badgeCenter = Offset(44, 480);
  static const double badgeRadius = 17;
  static const badgeColor = Color(0xFF9A9A9A);
  static const double badgeStroke = 1.1;
  static const String badgeFontFamily = 'TorifudaNumber';
  static const double badgeFontSize = 15;
}
