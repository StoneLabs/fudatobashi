import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'vector.dart';

/// Vector art the app shows as a pre-rendered image, `assets/art/<name>.png`
/// (made from [art] by tool/render_art_test.dart). The vector stays the
/// source, and is drawn instead until the images are loaded (and in tests).
@immutable
class ArtImage {
  const ArtImage(this.name, this.art);
  final String name;
  final VectorArt art;

  String get asset => 'assets/art/$name.png';
}

/// The loaded [ArtImage]s.
abstract final class ArtImages {
  static final _images = <String, ui.Image>{};

  /// Loads [all] at startup; a missing image falls back to its vector.
  static Future<void> load(List<ArtImage> all) async {
    for (final a in all) {
      try {
        final data = await rootBundle.load(a.asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        _images[a.name] = (await codec.getNextFrame()).image;
      } on FlutterError {
        continue;
      }
    }
  }

  /// Draws [a] fitted into [dst] and centred, as [VectorPainter.paint] would.
  static void paint(Canvas canvas, ArtImage a, Rect dst, {double pixelRatio = 1}) {
    final image = _images[a.name];
    if (image == null) {
      VectorPainter.paint(canvas, a.art, dst, pixelRatio: pixelRatio);
      return;
    }
    final fitted = applyBoxFit(BoxFit.contain, a.art.box, dst.size).destination;
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Alignment.center.inscribe(fitted, dst),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}

/// An [ArtImage] of [size], or as large as its box allows.
class ArtImageBox extends StatelessWidget {
  const ArtImageBox(this.art, {super.key, this.size});

  final ArtImage art;
  final Size? size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: size ?? art.art.box,
        child: CustomPaint(painter: _ArtImagePainter(art, MediaQuery.devicePixelRatioOf(context))),
      );
}

class _ArtImagePainter extends CustomPainter {
  _ArtImagePainter(this.art, this.pixelRatio);
  final ArtImage art;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) => ArtImages.paint(canvas, art, Offset.zero & size, pixelRatio: pixelRatio);

  @override
  bool shouldRepaint(_ArtImagePainter old) => old.art != art || old.pixelRatio != pixelRatio;
}
