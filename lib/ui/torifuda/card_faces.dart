import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// The blank card faces the card renderers print their text on (one image
/// per skin), decoded once before they are drawn (see [load]) so a card
/// paints in a single frame.
abstract final class CardFaces {
  static final _images = <String, ui.Image>{};

  /// The decoded face at [asset], or null before [load] has read it.
  static ui.Image? of(String asset) => _images[asset];

  /// Decodes each of [assets], read from the asset bundle unless [read] is
  /// given (tests read the files from disk).
  static Future<void> load(Iterable<String> assets, {Future<Uint8List> Function(String asset)? read}) async {
    for (final asset in assets) {
      if (_images.containsKey(asset)) continue;
      final bytes = read != null ? await read(asset) : (await rootBundle.load(asset)).buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      _images[asset] = (await codec.getNextFrame()).image;
    }
  }
}
