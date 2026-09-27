import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'geometry.dart';
import 'lines.dart';
import 'screentone.dart';

/// One layer of a static background (gradient, focus lines, tone …).
/// Layers compare by value so a rendered background can be reused.
@immutable
abstract class ArtLayer {
  const ArtLayer();

  List<Object?> get props;

  void paint(Canvas canvas, Size size, double pixelRatio);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType && _listEquals((other as ArtLayer).props, props);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(props));

  static bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x is List && y is List) {
        if (!_listEquals(x.cast(), y.cast())) return false;
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }
}

class FillLayer extends ArtLayer {
  const FillLayer(this.color);
  final Color color;

  @override
  List<Object?> get props => [color];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) => canvas.drawRect(Offset.zero & size, Paint()..color = color);
}

/// CSS `radial-gradient(circle at <center>, …)`.
class RadialLayer extends ArtLayer {
  const RadialLayer({required this.center, required this.colors, required this.stops});
  final Alignment center;
  final List<Color> colors;
  final List<double> stops;

  @override
  List<Object?> get props => [center, colors, stops];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) {
    final rect = Offset.zero & size;
    final c = center.withinRect(rect);
    canvas.drawRect(
        rect, Paint()..shader = ui.Gradient.radial(c, CssGradient.farthestCorner(rect, c), colors, stops));
  }
}

/// CSS `linear-gradient(<angle>deg, …)`.
class LinearLayer extends ArtLayer {
  const LinearLayer({required this.angle, required this.colors, required this.stops});
  final double angle;
  final List<Color> colors;
  final List<double> stops;

  @override
  List<Object?> get props => [angle, colors, stops];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) {
    final rect = Offset.zero & size;
    final (a, b) = CssGradient.linear(rect, angle);
    canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(a, b, colors, stops));
  }
}

class BurstLayer extends ArtLayer {
  const BurstLayer(this.spec);
  final BurstSpec spec;

  @override
  List<Object?> get props => [spec];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) => FocusLinesPainter(spec).paint(canvas, size);
}

class SpeedLinesLayer extends ArtLayer {
  const SpeedLinesLayer(this.spec);
  final SpeedLinesSpec spec;

  @override
  List<Object?> get props => [spec];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) => SpeedLinesPainter(spec).paint(canvas, size);
}

/// A screentone, optionally faded in along a CSS linear-gradient mask from
/// transparent at `fadeStops[0]` to opaque at `fadeStops[1]`.
class ToneLayer extends ArtLayer {
  const ToneLayer(this.spec, {this.fadeAngle, this.fadeStops});
  final ToneSpec spec;
  final double? fadeAngle;
  final List<double>? fadeStops;

  @override
  List<Object?> get props => [spec, fadeAngle, fadeStops];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) {
    final rect = Offset.zero & size;
    if (fadeAngle == null) {
      canvas.drawRect(rect, Screentone.paint(spec, pixelRatio));
      return;
    }
    final (a, b) = CssGradient.linear(rect, fadeAngle!);
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Screentone.paint(spec, pixelRatio));
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(a, b, const [Color(0x00000000), Color(0xFF000000)], fadeStops),
    );
    canvas.restore();
  }
}

/// A background composed of [layers], rendered once into an image per size
/// and pixel density and then drawn as a single bitmap each frame.
class StaticArt extends StatelessWidget {
  const StaticArt(this.layers, {super.key});

  final List<ArtLayer> layers;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _StaticArtPainter(layers, MediaQuery.devicePixelRatioOf(context)),
        ),
      );
}

class _StaticArtPainter extends CustomPainter {
  _StaticArtPainter(this.layers, this.pixelRatio);
  final List<ArtLayer> layers;
  final double pixelRatio;

  static final _images = <_ArtKey, ui.Image>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final key = _ArtKey(layers, size, pixelRatio);
    var image = _images.remove(key);
    image ??= _render(size);
    _images[key] = image;
    while (_images.length > CacheLimits.staticArt) {
      _images.remove(_images.keys.first)?.dispose();
    }
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render(Size size) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(pixelRatio);
    for (final l in layers) {
      l.paint(canvas, size, pixelRatio);
    }
    return rec.endRecording().toImageSync((size.width * pixelRatio).ceil(), (size.height * pixelRatio).ceil());
  }

  @override
  bool shouldRepaint(_StaticArtPainter old) =>
      old.pixelRatio != pixelRatio || !ArtLayer._listEquals(old.layers, layers);
}

class _ArtKey {
  _ArtKey(this.layers, this.size, this.pixelRatio);
  final List<ArtLayer> layers;
  final Size size;
  final double pixelRatio;

  @override
  bool operator ==(Object other) =>
      other is _ArtKey &&
      other.size == size &&
      other.pixelRatio == pixelRatio &&
      ArtLayer._listEquals(other.layers, layers);

  @override
  int get hashCode => Object.hash(Object.hashAll(layers), size, pixelRatio);
}
