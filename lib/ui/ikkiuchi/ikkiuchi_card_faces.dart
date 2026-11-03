import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/card_mask.dart';
import '../torifuda/card_faces.dart';
import '../torifuda/torifuda_painter.dart';

/// Each card's face drawn once as an image, at the width it is shown.
class IkkiuchiCardFaces {
  IkkiuchiCardFaces({required this.showNumber});

  final bool showNumber;
  final _images = <(int, int), ui.Image>{};

  /// Card [poemId]'s face [width] device pixels wide.
  ui.Image of(int poemId, int width) => _images[(poemId, width)] ??= () {
        final height = (width * TorifudaSpec.height / TorifudaSpec.width).round();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const style = TorifudaStyle.standard;
        CardFaces.paint(canvas, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), style.background);
        canvas.drawPicture(
            TorifudaGlyphs.picture(poems[poemId], CardMask.none, width / TorifudaSpec.width, showNumber, style));
        return recorder.endRecording().toImageSync(width, height);
      }();

  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}
