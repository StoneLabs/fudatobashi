import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import '../manga/svg_art.dart';
import '../manga/vector.dart';

/// The blank card faces the card renderers print their text on (one file
/// per skin: a PNG for the yomifuda, an SVG for the torifuda), decoded once
/// before they are drawn (see [load]) so a card paints in a single frame.
abstract final class CardFaces {
  static final _images = <String, ui.Image>{};
  static final _vectors = <String, VectorArt>{};

  /// The decoded PNG face at [asset], or null before [load] has read it.
  static ui.Image? of(String asset) => _images[asset];

  /// The SVG face at [asset], or null before [load] has read it.
  static VectorArt? vectorOf(String asset) => _vectors[asset];

  /// Decodes each of [assets], read from the asset bundle unless [read] is
  /// given (tests read the files from disk).
  static Future<void> load(Iterable<String> assets, {Future<Uint8List> Function(String asset)? read}) async {
    for (final asset in assets) {
      if (_images.containsKey(asset) || _vectors.containsKey(asset)) continue;
      final bytes = read != null ? await read(asset) : (await rootBundle.load(asset)).buffer.asUint8List();
      if (asset.endsWith('.svg')) {
        _vectors[asset] = SvgArt.parse(String.fromCharCodes(bytes), debugName: asset);
      } else {
        final codec = await ui.instantiateImageCodec(bytes);
        _images[asset] = (await codec.getNextFrame()).image;
      }
    }
  }
}
