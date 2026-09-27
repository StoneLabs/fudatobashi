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
