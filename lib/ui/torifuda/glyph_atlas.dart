import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Pre-rendered torifuda kana (see tool/render_glyphs_test.dart). When loaded,
/// the painter draws these images instead of live text, so the app can use
/// glyphs of a font it does not ship.
class GlyphAtlas {
  GlyphAtlas._(this.images, this.emPx, this.source);

  static GlyphAtlas? instance;

  final Map<String, ui.Image> images;

  /// Pixels per em in the images.
  final double emPx;
  final String source;

  static Future<GlyphAtlas?> load() async {
    try {
      final meta = jsonDecode(await rootBundle.loadString('assets/glyphs/meta.json')) as Map<String, dynamic>;
      final images = <String, ui.Image>{};
      for (final ch in (meta['chars'] as String).split('')) {
        final data = await rootBundle.load('assets/glyphs/${ch.codeUnitAt(0).toRadixString(16)}.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        images[ch] = (await codec.getNextFrame()).image;
      }
      return instance = GlyphAtlas._(
        images,
        (meta['emPx'] as num).toDouble(),
        meta['source'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
