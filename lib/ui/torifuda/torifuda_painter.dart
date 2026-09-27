import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../data/poem.dart';
import '../../domain/card_mask.dart';
import 'glyph_atlas.dart';
import 'torifuda_spec.dart';

/// A torifuda drawn from vectors at any size.
class TorifudaCard extends StatelessWidget {
  const TorifudaCard({
    super.key,
    required this.poem,
    this.inverted = false,
    this.showText = true,
    this.showNumber = true,
    this.mask = CardMask.none,
  });

  final Poem poem;
  final bool inverted;

  /// False draws a blank card (used for the card underneath the top card, so
  /// nothing can be read before it is revealed).
  final bool showText;
  final bool showNumber;
  final CardMask mask;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: TorifudaSpec.width / TorifudaSpec.height,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TorifudaPainter(
            poem: poem,
            inverted: inverted,
            showText: showText,
            showNumber: showNumber,
            mask: mask,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          ),
        ),
      ),
    );
  }
}

class TorifudaPainter extends CustomPainter {
  TorifudaPainter({
    required this.poem,
    this.inverted = false,
    this.showText = true,
    this.showNumber = true,
    this.mask = CardMask.none,
    this.devicePixelRatio = 1,
  });

  final Poem poem;
  final bool inverted;
  final bool showText;
  final bool showNumber;
  final CardMask mask;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / TorifudaSpec.width;
    canvas.save();
    if (inverted) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    canvas.save();
    canvas.scale(s);
    _paintFrame(canvas);
    canvas.restore();
    if (showText) {
      // Glyphs are recorded at the final pixel scale so text stays crisp.
      final pictureScale = s * devicePixelRatio;
      canvas.save();
      canvas.scale(1 / devicePixelRatio);
      canvas.drawPicture(TorifudaGlyphs.picture(poem, mask, pictureScale, showNumber));
      canvas.restore();
    }
    canvas.restore();
  }

  static void _paintFrame(Canvas canvas) {
    const spec = TorifudaSpec.paper;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, TorifudaSpec.width, TorifudaSpec.height),
      Paint()..color = TorifudaSpec.frameColor,
    );
    canvas.drawRect(
      spec.inflate(0.6),
      Paint()
        ..color = TorifudaSpec.frameShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRect(spec, Paint()..color = TorifudaSpec.paperColor);
    canvas.drawRect(
      spec.deflate(0.9),
      Paint()
        ..color = TorifudaSpec.paperHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(TorifudaPainter old) =>
      old.poem.id != poem.id ||
      old.inverted != inverted ||
      old.showText != showText ||
      old.showNumber != showNumber ||
      old.mask.key != mask.key ||
      old.devicePixelRatio != devicePixelRatio;
}

/// Records and caches the glyph layer of a card as a [ui.Picture].
abstract final class TorifudaGlyphs {
  static final _cache = <String, ui.Picture>{};
  static const _maxEntries = 48;

  /// Column / row of the i-th kana of [columns].
  static (int, int) cellOf(int i, List<String> columns) {
    var rest = i;
    for (var c = 0; c < columns.length; c++) {
      if (rest < columns[c].length) return (c, rest);
      rest -= columns[c].length;
    }
    throw RangeError.index(i, columns.join());
  }

  /// Centre of cell ([col], [row]) in card units, for a column of [length] kana.
  static Offset cellCenter(int col, int row, int length) => Offset(
        TorifudaSpec.columnCenterX[col],
        TorifudaSpec.rowCenterY(row, length),
      );

  static ui.Picture picture(Poem poem, CardMask mask, double scale, bool showNumber) {
    final key = '${poem.id}|${mask.key}|${scale.toStringAsFixed(4)}|$showNumber';
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    final pic = _record(poem, mask, scale, showNumber);
    _cache[key] = pic;
    if (_cache.length > _maxEntries) _cache.remove(_cache.keys.first)?.dispose();
    return pic;
  }

  static ui.Picture _record(Poem poem, CardMask mask, double s, bool showNumber) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final cols = poem.columns;
    final rng = math.Random(mask.seed * 131 + poem.id);
    var i = 0;
    for (var c = 0; c < cols.length; c++) {
      for (var r = 0; r < cols[c].length; r++, i++) {
        final center = cellCenter(c, r, cols[c].length) * s;
        if (!mask.hidden.contains(i)) {
          _drawGlyph(canvas, cols[c][r], center, s);
        } else {
          switch (mask.style) {
            case MaskStyle.blank:
              break;
            case MaskStyle.scramble:
            case MaskStyle.shape: // TODO(masking): ink-matched shapes.
              _drawScrambled(canvas, cols[c][r], center, s, rng);
          }
        }
      }
    }
    if (showNumber) _drawBadge(canvas, poem.id, s);
    return rec.endRecording();
  }

  static TextPainter _layout(String text, double fontSize, String family, Color color) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: family,
            fontSize: fontSize,
            height: 1.0,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  static void _drawGlyph(Canvas canvas, String ch, Offset center, double s) {
    final fs = TorifudaSpec.fontSize * s;
    final c = center + Offset(0, TorifudaSpec.glyphDy * fs);
    final atlas = GlyphAtlas.instance;
    final img = atlas?.images[ch];
    if (img != null) {
      // Pre-rendered glyph: its em box sits centred in the image.
      final side = fs * atlas!.pad;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: c, width: side, height: side),
        _glyphPaint,
      );
      return;
    }
    final tp = _layout(ch, fs, TorifudaSpec.fontFamily, TorifudaSpec.inkColor);
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    tp.dispose();
  }

  static final _glyphPaint = Paint()
    ..filterQuality = FilterQuality.high
    ..colorFilter = const ColorFilter.mode(TorifudaSpec.inkColor, BlendMode.srcIn);

  /// Draws [ch] cut into a 3×3 grid of tiles, shuffled and rotated in place.
  static void _drawScrambled(Canvas canvas, String ch, Offset center, double s, math.Random rng) {
    final box = (TorifudaSpec.fontSize * s * 1.1).ceilToDouble();
    final rec = ui.PictureRecorder();
    _drawGlyph(Canvas(rec), ch, Offset(box / 2, box / 2), s);
    final img = rec.endRecording().toImageSync(box.toInt(), box.toInt());
    final tile = box / 3;
    final order = List<int>.generate(9, (k) => k)..shuffle(rng);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final origin = center - Offset(box / 2, box / 2);
    for (var k = 0; k < 9; k++) {
      final src = Rect.fromLTWH((k % 3) * tile, (k ~/ 3) * tile, tile, tile);
      final d = order[k];
      final dstCenter = origin + Offset((d % 3 + 0.5) * tile, (d ~/ 3 + 0.5) * tile);
      canvas.save();
      canvas.translate(dstCenter.dx, dstCenter.dy);
      canvas.rotate(rng.nextInt(4) * math.pi / 2);
      canvas.drawImageRect(img, src, Rect.fromCenter(center: Offset.zero, width: tile, height: tile), paint);
      canvas.restore();
    }
    img.dispose();
  }

  static void _drawBadge(Canvas canvas, int number, double s) {
    final c = TorifudaSpec.badgeCenter * s;
    canvas.drawCircle(
      c,
      TorifudaSpec.badgeRadius * s,
      Paint()
        ..color = TorifudaSpec.badgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = TorifudaSpec.badgeStroke * s,
    );
    final tp = _layout(
      '$number',
      TorifudaSpec.badgeFontSize * s,
      TorifudaSpec.badgeFontFamily,
      TorifudaSpec.badgeColor,
    );
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }
}
