import 'dart:ui';

/// A per-kana glyph correction, see [TorifudaSpec.glyphFit].
typedef GlyphFit = ({double dx, double dy, double scale});

/// Geometry and colours of a torifuda, in "card units": the card is exactly
/// 374 × 525 units (73 × 52 mm ratio), matching the original app's artwork,
/// which these values are fitted against.
abstract final class TorifudaSpec {
  static const double width = 374;
  static const double height = 525;
  static const double aspect = height / width;

  // Frame (the green backing paper folded over the edge).
  static const frameColor = Color(0xFF6A9354);

  /// Band just outside the paper edge, slightly darker than the frame.
  static const frameShade = Color(0xFF66904F);
  static const double frameShadeWidth = 1.56;

  // Paper.
  static const paper = Rect.fromLTRB(17.34, 19.65, 356.7, 505.44);
  static const paperColor = Color(0xFFEAEAEA);

  /// Band just inside the paper edge, slightly lighter than the paper.
  static const paperHighlight = Color(0xFFF2EFF4);
  static const double paperHighlightInset = 0.44;
  static const double paperHighlightWidth = 0.88;

  // Glyph grid. Three columns, right to left, split 5 / 5 / rest, all
  // starting at the top row. Each glyph's em box is centred on its cell,
  // corrected by [glyphFit].
  static const String fontFamily = 'Torifuda';
  static const inkColor = Color(0xFF262626);
  static const double fontSize = 78.0;

  /// Centre of each column's first cell, right to left.
  static const List<Offset> columnTop = [Offset(289.53, 81.64), Offset(188.64, 81.88), Offset(91.23, 81.73)];
  static const double rowPitch = 89.63;

  /// A column with more than five kana (only #21 has six) is spread evenly
  /// between these row centres, like the original cards.
  static const double longColumnFirstRowCenterY = 75.03;
  static const double longColumnLastRowCenterY = 440.08;

  /// Centre of cell ([column], [row]) for a column of [columnLength] kana.
  static Offset cellCenter(int column, int row, int columnLength) => Offset(
        columnTop[column].dx,
        columnLength <= 5
            ? columnTop[column].dy + row * rowPitch
            : longColumnFirstRowCenterY +
                row * (longColumnLastRowCenterY - longColumnFirstRowCenterY) / (columnLength - 1),
      );

  /// Per-kana correction of the glyph: shift of its em box from the cell
  /// centre, in em, and scale. The original cards place and size some kana
  /// slightly differently from the font version the atlas is rendered from.
  static const Map<String, GlyphFit> glyphFit = {
    'あ': (dx: 0.0045, dy: 0.0093, scale: 1.0026), 'い': (dx: -0.0047, dy: 0.0165, scale: 1.0069),
    'う': (dx: 0.0091, dy: -0.0079, scale: 0.9732), 'え': (dx: -0.0005, dy: 0.0054, scale: 1.0038),
    'お': (dx: -0.0032, dy: 0.0021, scale: 0.9983), 'か': (dx: -0.0134, dy: -0.0033, scale: 1.0040),
    'き': (dx: -0.0086, dy: 0.0055, scale: 0.9961), 'く': (dx: 0.0071, dy: -0.0002, scale: 0.9660),
    'け': (dx: 0.0031, dy: 0.0127, scale: 0.9801), 'こ': (dx: 0.0039, dy: 0.0025, scale: 0.9996),
    'さ': (dx: -0.0002, dy: 0.0022, scale: 1.0034), 'し': (dx: 0.0188, dy: -0.0010, scale: 1.0064),
    'す': (dx: 0.0189, dy: 0.0065, scale: 1.0026), 'せ': (dx: -0.0041, dy: -0.0059, scale: 1.0014),
    'そ': (dx: -0.0171, dy: 0.0012, scale: 1.0115), 'た': (dx: -0.0032, dy: 0.0001, scale: 0.9979),
    'ち': (dx: 0.0168, dy: -0.0014, scale: 1.0077), 'つ': (dx: 0.0023, dy: -0.0056, scale: 0.9964),
    'て': (dx: -0.0091, dy: 0.0064, scale: 1.0378), 'と': (dx: 0.0072, dy: 0.0029, scale: 1.0056),
    'な': (dx: 0.0115, dy: -0.0014, scale: 0.9899), 'に': (dx: 0.0122, dy: -0.0105, scale: 1.0014),
    'ぬ': (dx: -0.0026, dy: -0.0101, scale: 0.9998), 'ね': (dx: -0.0054, dy: 0.0002, scale: 1.0025),
    'の': (dx: -0.0072, dy: 0.0043, scale: 1.0036), 'は': (dx: 0.0062, dy: 0.0048, scale: 0.9805),
    'ひ': (dx: -0.0141, dy: -0.0102, scale: 1.0006), 'ふ': (dx: -0.0068, dy: -0.0111, scale: 0.9966),
    'へ': (dx: -0.0033, dy: 0.0053, scale: 1.0129), 'ほ': (dx: 0.0018, dy: 0.0052, scale: 0.9826),
    'ま': (dx: -0.0057, dy: 0.0004, scale: 0.9928), 'み': (dx: 0.0081, dy: -0.0155, scale: 0.9925),
    'む': (dx: 0.0137, dy: -0.0058, scale: 1.0012), 'め': (dx: 0.0040, dy: 0.0204, scale: 1.0052),
    'も': (dx: 0.0073, dy: -0.0015, scale: 0.9974), 'や': (dx: -0.0072, dy: 0.0059, scale: 1.0035),
    'ゆ': (dx: -0.0006, dy: -0.0041, scale: 0.9987), 'よ': (dx: 0.0030, dy: -0.0067, scale: 1.0007),
    'ら': (dx: -0.0178, dy: 0.0066, scale: 0.9887), 'り': (dx: -0.0024, dy: 0.0030, scale: 0.9964),
    'る': (dx: -0.0147, dy: 0.0061, scale: 1.0011), 'れ': (dx: -0.0159, dy: -0.0049, scale: 1.0098),
    'ろ': (dx: -0.0068, dy: -0.0040, scale: 0.9996), 'わ': (dx: 0.0022, dy: -0.0185, scale: 1.0043),
    'ゐ': (dx: -0.0037, dy: -0.0112, scale: 0.9991), 'ゑ': (dx: -0.0146, dy: -0.0019, scale: 1.0068),
    'を': (dx: 0.0105, dy: 0.0010, scale: 1.0002),
  };

  // Poem-number badge (bottom left).
  static const badgeCenter = Offset(44.3, 480.26);
  static const double badgeRadius = 16.54;
  static const badgeColor = Color(0xFF8A8A8A);
  static const badgeNumeralColor = Color(0xFF9E9E9E);
  static const double badgeStroke = 1.08;
  static const String badgeFontFamily = 'TorifudaNumber';
  static const double badgeFontSize = 20.6;

  /// Three-digit numbers (only 100) are set smaller to fit the circle.
  static const double badgeFontSizeThreeDigits = 15.7;

  /// Numeral baseline below [badgeCenter], as a fraction of the font size.
  static const double badgeBaselineDy = 0.34;
}
