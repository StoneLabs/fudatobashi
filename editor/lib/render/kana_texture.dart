import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../config.dart';

class _KanaAssets {
  static Map<String, ui.Image>? _glyphs;
  static double _emPx = 256;
  static Map<String, List<String>>? _poems;

  static Future<void> ensure() async {
    if (_glyphs != null) return;
    final meta = jsonDecode(await rootBundle.loadString('assets/glyphs/meta.json')) as Map<String, dynamic>;
    _emPx = (meta['emPx'] as num).toDouble();
    final glyphs = <String, ui.Image>{};
    for (final ch in (meta['chars'] as String).split('')) {
      final data = await rootBundle.load('assets/glyphs/${ch.codeUnitAt(0).toRadixString(16)}.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      glyphs[ch] = (await codec.getNextFrame()).image;
    }
    final poems = jsonDecode(await rootBundle.loadString('assets/data/torifuda.json')) as Map<String, dynamic>;
    _poems = {for (final e in poems.entries) e.key: (e.value as List).cast<String>()};
    _glyphs = glyphs;
  }
}

/// The kana layer of a card: R is the ink glyphs, G the halo (blurred
/// glyphs). Opaque black elsewhere.
Future<ui.Image> buildKanaTexture(int poem) async {
  await _KanaAssets.ensure();
  final columns = _KanaAssets._poems!['$poem'] ?? _KanaAssets._poems!['${Cfg.defaultPoem}']!;
  const k = Cfg.kanaScale;
  final w = (Cfg.cardWidth * k).round(), h = (Cfg.cardHeight * k).round();
  final bounds = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, bounds)
    ..drawColor(const Color(0xFF000000), BlendMode.src)
    ..scale(k);
  final addPaint = Paint()..blendMode = BlendMode.plus;

  void glyphs(Color color) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    for (var c = 0; c < columns.length; c++) {
      for (var r = 0; r < columns[c].length; r++) {
        final ch = columns[c][r];
        final img = _KanaAssets._glyphs![ch];
        if (img == null) continue;
        final fit = Torifuda.glyphFit[ch] ?? (dx: 0.0, dy: 0.0, scale: 1.0);
        final em = Torifuda.fontSize;
        final center = Torifuda.cellCenter(c, r, columns[c].length) + Offset(fit.dx, fit.dy) * em;
        final side = em * fit.scale * img.width / _KanaAssets._emPx;
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: center, width: side, height: side),
          paint,
        );
      }
    }
  }

  canvas.saveLayer(null, addPaint);
  glyphs(const Color(0xFFFF0000));
  canvas.restore();

  const gain = Cfg.haloGain;
  canvas.saveLayer(
    null,
    Paint()
      ..blendMode = BlendMode.plus
      ..colorFilter = const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 0, //
        0, 0, 0, gain, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 255,
      ]),
  );
  canvas.saveLayer(null, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: Cfg.haloBlur, sigmaY: Cfg.haloBlur));
  glyphs(const Color(0xFFFFFFFF));
  canvas.restore();
  canvas.restore();

  return rec.endRecording().toImage(w, h);
}

/// The poem-number badge of a card centred at [center]: R is the ring, G the number. Opaque black elsewhere.
Future<ui.Image> buildBadgeTexture(int poem, Offset center) async {
  const k = Cfg.kanaScale;
  final w = (Cfg.cardWidth * k).round(), h = (Cfg.cardHeight * k).round();
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()))
    ..drawColor(const Color(0xFF000000), BlendMode.src)
    ..scale(k);
  final addPaint = Paint()..blendMode = BlendMode.plus;
  canvas.saveLayer(null, addPaint);
  canvas.drawCircle(
    center,
    Torifuda.badgeRadius,
    Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Torifuda.badgeStroke,
  );
  final text = '$poem';
  final fs = text.length > 2 ? Torifuda.badgeFontSizeThreeDigits : Torifuda.badgeFontSize;
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: Torifuda.badgeFontFamily, fontSize: fs, height: 1.0, color: const Color(0xFF00FF00)),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(canvas, center + Offset(-tp.width / 2, Torifuda.badgeBaselineDy * fs - baseline));
  tp.dispose();
  canvas.restore();

  return rec.endRecording().toImage(w, h);
}
