import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../manga/svg_art.dart';
import '../manga/vector.dart';

/// The blank card faces the card renderers print their text on, one file
/// per skin: an `.svg` for flat geometric faces, which stay sharp at every
/// size, or a bitmap such as a `.png` for painted or textured ones. Each is
/// decoded once before it is drawn (see [load]) so a card paints in a
/// single frame.
abstract final class CardFaces {
  static final _faces = <String, _Face>{};

  /// Paints the face at [asset] stretched over [rect], or nothing before
  /// [load] has read it. [pixelRatio] is the canvas's device pixels per
  /// logical pixel, which an SVG face's screentones are sized by.
  static void paint(Canvas canvas, Rect rect, String asset, {double pixelRatio = 1}) =>
      _faces[asset]?.paint(canvas, rect, pixelRatio);

  /// Decodes each of [assets], read from the asset bundle unless [read] is
  /// given (tests read the files from disk).
  static Future<void> load(Iterable<String> assets, {Future<Uint8List> Function(String asset)? read}) async {
    for (final asset in assets) {
      if (_faces.containsKey(asset)) continue;
      final bytes = read != null ? await read(asset) : (await rootBundle.load(asset)).buffer.asUint8List();
      if (asset.endsWith('.svg')) {
        _faces[asset] = _VectorFace(SvgArt.parse(String.fromCharCodes(bytes), debugName: asset));
      } else {
        final codec = await ui.instantiateImageCodec(bytes);
        _faces[asset] = _ImageFace((await codec.getNextFrame()).image);
      }
    }
  }
}

sealed class _Face {
  void paint(Canvas canvas, Rect rect, double pixelRatio);
}

final class _VectorFace implements _Face {
  _VectorFace(this.art);

  final VectorArt art;

  @override
  void paint(Canvas canvas, Rect rect, double pixelRatio) {
    final sx = rect.width / art.box.width;
    final sy = rect.height / art.box.height;
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(sx, sy);
    VectorPainter.paint(canvas, art, Offset.zero & art.box, pixelRatio: pixelRatio * math.min(sx, sy));
    canvas.restore();
  }
}

final class _ImageFace implements _Face {
  _ImageFace(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Rect rect, double pixelRatio) => canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
}
