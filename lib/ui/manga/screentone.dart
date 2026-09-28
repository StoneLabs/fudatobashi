import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// Screentone fills. Each pattern is rasterised once per pixel density into a
/// tiny tile and repeated by an image shader, so a toned area costs one draw.
abstract final class Screentone {
  static final _tiles = <(ToneSpec, int), ui.Image>{};

  static ui.Image tile(ToneSpec spec, double pixelRatio) {
    final density = (pixelRatio * Tones.densitySteps).round();
    return _tiles[(spec, density)] ??= _render(spec, density / Tones.densitySteps);
  }

  static ui.Image _render(ToneSpec spec, double pixelRatio) {
    final n = (spec.spacing * pixelRatio).round().clamp(Tones.minTilePx, Tones.maxTilePx);
    final unit = n / spec.spacing;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    if (spec.background != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, n.toDouble(), n.toDouble()), Paint()..color = spec.background!);
    }
    final dot = Paint()
      ..color = spec.dot
      ..isAntiAlias = true;
    final r = (spec.radius + Tones.softEdge) * unit;
    for (final phase in [spec.phase, spec.phase + 0.5]) {
      final c = (phase % 1) * n;
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          canvas.drawCircle(Offset(c + dx * n, c + dy * n), r, dot);
        }
      }
    }
    return rec.endRecording().toImageSync(n, n);
  }

  /// A paint that fills with [spec] in logical coordinates, for a canvas that
  /// ends up [pixelRatio] device pixels per logical pixel.
  static Paint paint(ToneSpec spec, double pixelRatio, {double opacity = 1}) {
    final image = tile(spec, pixelRatio);
    final scale = spec.spacing / image.width;
    final matrix = Matrix4.diagonal3Values(scale, scale, 1).storage;
    final p = Paint()
      ..shader = ui.ImageShader(image, TileMode.repeated, TileMode.repeated, matrix,
          filterQuality: FilterQuality.medium);
    if (opacity < 1) p.color = Color.fromRGBO(0, 0, 0, opacity);
    return p;
  }
}

/// Fills its box with a screentone.
class ToneBox extends StatelessWidget {
  const ToneBox(this.spec, {super.key, this.opacity = 1, this.child});

  final ToneSpec spec;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _TonePainter(spec, opacity, MediaQuery.devicePixelRatioOf(context)),
        child: child,
      );
}

class _TonePainter extends CustomPainter {
  _TonePainter(this.spec, this.opacity, this.pixelRatio);
  final ToneSpec spec;
  final double opacity;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.drawRect(Offset.zero & size, Screentone.paint(spec, pixelRatio, opacity: opacity));
  }

  @override
  bool shouldRepaint(_TonePainter old) => old.spec != spec || old.opacity != opacity || old.pixelRatio != pixelRatio;
}

/// Gradation tones, rasterised once per box size and pixel density into an
/// image of just the toned part, so painting one is a single image draw.
abstract final class Gradation {
  static final _images = <(GradationSpec, Size, double), (ui.Image, Offset)>{};

  /// The toned part of [spec] over a box of [size], and where it sits in it.
  static (ui.Image, Offset) image(GradationSpec spec, Size size, double pixelRatio) {
    final key = (spec, size, pixelRatio);
    final cached = _images[key];
    if (cached != null) return cached;
    if (_images.length >= Tones.gradationCacheSize) _images.remove(_images.keys.first)!.$1.dispose();
    return _images[key] = _render(spec, size, pixelRatio);
  }

  static (ui.Image, Offset) _render(GradationSpec spec, Size size, double pixelRatio) {
    final box = Offset.zero & size;
    final begin = spec.begin.withinRect(box);
    final axis = spec.end.withinRect(box) - begin;
    final dots = <(Offset, double)>[];
    var toned = Rect.zero;
    for (var y = -1.0; y * spec.spacing < size.height + spec.spacing; y++) {
      for (var x = -1.0; x * spec.spacing < size.width + spec.spacing; x++) {
        for (final phase in [spec.phase, spec.phase + 0.5]) {
          final c = Offset((x + phase) * spec.spacing, (y + phase) * spec.spacing);
          final d = c - begin;
          final t = (d.dx * axis.dx + d.dy * axis.dy) / axis.distanceSquared;
          final r = spec.radiusAt(t);
          if (r < Tones.gradationMinRadius) continue;
          final dot = Rect.fromCircle(center: c, radius: r + Tones.softEdge);
          toned = toned.isEmpty ? dot : toned.expandToInclude(dot);
          dots.add((c, r + Tones.softEdge));
        }
      }
    }
    toned = toned.intersect(box);
    final origin = Offset((toned.left * pixelRatio).floorToDouble(), (toned.top * pixelRatio).floorToDouble());
    final width = math.max(1, (toned.right * pixelRatio).ceil() - origin.dx.toInt());
    final height = math.max(1, (toned.bottom * pixelRatio).ceil() - origin.dy.toInt());
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)
      ..translate(-origin.dx, -origin.dy)
      ..scale(pixelRatio);
    final paint = Paint()
      ..color = spec.dot
      ..isAntiAlias = true;
    for (final (c, r) in dots) {
      canvas.drawCircle(c, r, paint);
    }
    final picture = rec.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return (image, origin / pixelRatio);
  }
}

/// Fills its box with a gradation tone. Its own layer: the image is drawn
/// once and never repaints with what sits on top of it.
class GradationBox extends StatelessWidget {
  const GradationBox(this.spec, {super.key});

  final GradationSpec spec;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _GradationPainter(spec, MediaQuery.devicePixelRatioOf(context)),
          size: Size.infinite,
        ),
      );
}

class _GradationPainter extends CustomPainter {
  _GradationPainter(this.spec, this.pixelRatio);
  final GradationSpec spec;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final (image, origin) = Gradation.image(spec, size, pixelRatio);
    final source = Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, source, origin & source.size / pixelRatio, Paint());
  }

  @override
  bool shouldRepaint(_GradationPainter old) => old.spec != spec || old.pixelRatio != pixelRatio;
}
