// A card face draws the same way from an SVG or a bitmap: stretched over
// the rect it is given, and not at all before it is loaded.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';

const _canvas = Size(50, 100);
const _rect = Rect.fromLTWH(10, 20, 30, 60);

Future<ByteData> _paint(String asset) async {
  final rec = ui.PictureRecorder();
  CardFaces.paint(Canvas(rec), _rect, asset);
  final image = await rec.endRecording().toImage(_canvas.width.toInt(), _canvas.height.toInt());
  return (await image.toByteData())!;
}

Color _pixel(ByteData pixels, double x, double y) {
  final i = (y.toInt() * _canvas.width.toInt() + x.toInt()) * 4;
  return Color.fromARGB(pixels.getUint8(i + 3), pixels.getUint8(i), pixels.getUint8(i + 1), pixels.getUint8(i + 2));
}

void main() {
  const faces = {
    'test/fixtures/svg/card_face.svg': Color(0xFF141414),
    'test/fixtures/card_face.png': Color(0xFF339966),
  };

  setUpAll(() => CardFaces.load(faces.keys, read: (asset) => File(asset).readAsBytes()));

  for (final MapEntry(key: asset, value: colour) in faces.entries) {
    test('$asset fills exactly the rect, though shaped differently', () async {
      final pixels = await _paint(asset);
      final inner = _rect.deflate(0.5);
      for (final corner in [inner.topLeft, inner.topRight, inner.bottomLeft, inner.bottomRight]) {
        expect(_pixel(pixels, corner.dx, corner.dy), colour, reason: '$corner');
      }
      final outer = _rect.inflate(0.5);
      for (final corner in [outer.topLeft, outer.topRight, outer.bottomLeft, outer.bottomRight]) {
        expect(_pixel(pixels, corner.dx, corner.dy).a, 0, reason: '$corner');
      }
    });
  }

  test('a face not loaded yet draws nothing', () async {
    final pixels = await _paint('test/fixtures/missing.svg');
    expect(_pixel(pixels, _rect.center.dx, _rect.center.dy).a, 0);
  });
}
