import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/card_mask.dart';
import 'glyph_atlas.dart';

/// A torifuda drawn from vectors at any size.
class TorifudaCard extends StatelessWidget {
  const TorifudaCard({
    super.key,
    required this.poem,
    this.inverted = false,
    this.showText = true,
    this.showNumber = true,
    this.mask = CardMask.none,
    this.style = TorifudaStyle.standard,
  });

  final Poem poem;
  final bool inverted;

  /// False draws a blank card (used for the card underneath the top card, so
  /// nothing can be read before it is revealed).
  final bool showText;
  final bool showNumber;
  final CardMask mask;
  final TorifudaStyle style;

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
            style: style,
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
    this.style = TorifudaStyle.standard,
    this.devicePixelRatio = 1,
  });

  final Poem poem;
  final bool inverted;
  final bool showText;
  final bool showNumber;
  final CardMask mask;
  final TorifudaStyle style;
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
    _paintFrame(canvas, style);
    canvas.restore();
    if (showText) {
      // Glyphs are recorded at the final pixel scale so text stays crisp.
      final pictureScale = s * devicePixelRatio;
      canvas.save();
      canvas.scale(1 / devicePixelRatio);
      canvas.drawPicture(TorifudaGlyphs.picture(poem, mask, pictureScale, showNumber, style));
      canvas.restore();
    }
    canvas.restore();
  }

  static void _paintFrame(Canvas canvas, TorifudaStyle style) {
    const paper = TorifudaSpec.paper;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, TorifudaSpec.width, TorifudaSpec.height),
      Paint()..color = style.frame,
    );
    canvas.drawRect(
      paper.inflate(TorifudaSpec.frameShadeWidth / 2),
      Paint()
        ..color = style.frameShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = TorifudaSpec.frameShadeWidth,
    );
    canvas.drawRect(paper, Paint()..color = style.paper);
    canvas.drawRect(
      paper.deflate(TorifudaSpec.paperHighlightInset + TorifudaSpec.paperHighlightWidth / 2),
      Paint()
        ..color = style.paperHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = TorifudaSpec.paperHighlightWidth,
    );
  }

  @override
  bool shouldRepaint(TorifudaPainter old) =>
      old.poem.id != poem.id ||
      old.inverted != inverted ||
      old.showText != showText ||
      old.showNumber != showNumber ||
      old.mask.key != mask.key ||
      old.style != style ||
      old.devicePixelRatio != devicePixelRatio;
}

/// Records and caches the glyph layer of a card as a [ui.Picture].
abstract final class TorifudaGlyphs {
  static final _cache = <String, ui.Picture>{};

  /// Column / row of the i-th kana of [columns].
  static (int, int) cellOf(int i, List<String> columns) {
    var rest = i;
    for (var c = 0; c < columns.length; c++) {
      if (rest < columns[c].length) return (c, rest);
      rest -= columns[c].length;
    }
    throw RangeError.index(i, columns.join());
  }

  static ui.Picture picture(Poem poem, CardMask mask, double scale, bool showNumber,
      [TorifudaStyle style = TorifudaStyle.standard]) {
    final key = '${poem.id}|${mask.key}|${scale.toStringAsFixed(4)}|$showNumber|${identityHashCode(style)}';
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    final pic = _record(poem, mask, scale, showNumber, style);
    _cache[key] = pic;
    if (_cache.length > CacheLimits.torifudaGlyphs) _cache.remove(_cache.keys.first)?.dispose();
    return pic;
  }

  static ui.Picture _record(Poem poem, CardMask mask, double s, bool showNumber, TorifudaStyle style) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final cols = poem.columns;
    final rng = math.Random(mask.seed * MaskingTuning.scrambleSeedMix + poem.id);
    var i = 0;
    for (var c = 0; c < cols.length; c++) {
      for (var r = 0; r < cols[c].length; r++, i++) {
        final center = TorifudaSpec.cellCenter(c, r, cols[c].length) * s;
        if (!mask.hidden.contains(i)) {
          _drawGlyph(canvas, cols[c][r], center, s, style);
        } else {
          switch (mask.style) {
            case MaskStyle.blank:
              break;
            case MaskStyle.scramble:
            case MaskStyle.shape:
              _drawScrambled(canvas, cols[c][r], center, s, rng, style);
          }
        }
      }
    }
    if (showNumber) _drawBadge(canvas, poem.id, s, style);
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

  static const GlyphFit _noFit = (dx: 0, dy: 0, scale: 1);

  static void _drawGlyph(Canvas canvas, String ch, Offset center, double s, TorifudaStyle style) {
    final fit = TorifudaSpec.glyphFit[ch] ?? _noFit;
    final em = TorifudaSpec.fontSize * s;
    final c = center + Offset(fit.dx, fit.dy) * em;
    final fs = em * fit.scale;
    final atlas = GlyphAtlas.instance;
    final img = atlas?.images[ch];
    if (img != null) {
      // Pre-rendered glyph: its em box sits centred in the image.
      final side = fs * img.width / atlas!.emPx;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: c, width: side, height: side),
        Paint()
          ..filterQuality = FilterQuality.high
          ..colorFilter = ColorFilter.mode(style.ink, BlendMode.srcIn),
      );
      return;
    }
    final tp = _layout(ch, fs, style.fontFamily, style.ink);
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    tp.dispose();
  }

  /// Draws [ch] cut into a 3×3 grid of tiles, shuffled and rotated in place.
  static void _drawScrambled(Canvas canvas, String ch, Offset center, double s, math.Random rng, TorifudaStyle style) {
    final box = (TorifudaSpec.fontSize * s * MaskingTuning.scrambleBoxPad).ceilToDouble();
    final rec = ui.PictureRecorder();
    _drawGlyph(Canvas(rec), ch, Offset(box / 2, box / 2), s, style);
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

  static void _drawBadge(Canvas canvas, int number, double s, TorifudaStyle style) {
    final c = TorifudaSpec.badgeCenter * s;
    canvas.drawCircle(
      c,
      TorifudaSpec.badgeRadius * s,
      Paint()
        ..color = style.badge
        ..style = PaintingStyle.stroke
        ..strokeWidth = TorifudaSpec.badgeStroke * s,
    );
    final text = '$number';
    final fs = (text.length > 2 ? TorifudaSpec.badgeFontSizeThreeDigits : TorifudaSpec.badgeFontSize) * s;
    final tp = _layout(text, fs, style.badgeFontFamily, style.badgeNumeral);
    final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, c + Offset(-tp.width / 2, TorifudaSpec.badgeBaselineDy * fs - baseline));
    tp.dispose();
  }
}
