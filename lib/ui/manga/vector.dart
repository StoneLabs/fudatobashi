import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'geometry.dart';
import 'screentone.dart';
import 'svg_path.dart';

/// Stands for the colour the art is drawn in (SVG `currentColor`).
const currentInk = Color(0x01020304);

/// Turns off an inherited fill or stroke (SVG `none`).
const noInk = Color(0x00000000);

/// Presentation attributes of a shape; unset values inherit from the parent
/// group, as in SVG.
@immutable
class VStyle {
  const VStyle({this.fill, this.stroke, this.width, this.cap, this.join, this.dash, this.opacity, this.tone});

  static const none = VStyle();

  final Color? fill;
  final Color? stroke;
  final double? width;
  final StrokeCap? cap;
  final StrokeJoin? join;
  final List<double>? dash;
  final double? opacity;

  /// Fills with a screentone pattern instead of [fill].
  final ToneSpec? tone;

  VStyle over(VStyle parent) => VStyle(
        fill: fill ?? parent.fill,
        stroke: stroke ?? parent.stroke,
        width: width ?? parent.width,
        cap: cap ?? parent.cap,
        join: join ?? parent.join,
        dash: dash ?? parent.dash,
        opacity: opacity ?? parent.opacity,
        tone: tone ?? parent.tone,
      );
}

/// A tag that lets a painter animate part of the art (Tobi's eyes blink).
enum VTag { eye }

sealed class VShape {
  const VShape(this.style, this.tag);
  final VStyle style;
  final VTag? tag;
}

class VPath extends VShape {
  const VPath(this.d, [VStyle style = VStyle.none, VTag? tag]) : super(style, tag);
  final String d;
}

class VRect extends VShape {
  const VRect(this.rect, {this.radius = 0, VStyle style = VStyle.none, VTag? tag}) : super(style, tag);
  final Rect rect;
  final double radius;
}

class VEllipse extends VShape {
  const VEllipse(this.center, this.rx, this.ry, [VStyle style = VStyle.none, VTag? tag]) : super(style, tag);
  const VEllipse.circle(this.center, double r, [VStyle style = VStyle.none, VTag? tag])
      : rx = r,
        ry = r,
        super(style, tag);
  final Offset center;
  final double rx, ry;
}

class VText extends VShape {
  const VText(this.text, this.baseline, {required this.size, required this.family, required this.color})
      : super(VStyle.none, null);

  /// Centre of the text's baseline.
  final Offset baseline;
  final String text;
  final double size;
  final String family;
  final Color color;
}

class VGroup extends VShape {
  const VGroup(this.children,
      {VStyle style = VStyle.none, this.rotate = 0, this.pivot = Offset.zero, this.transform, VTag? tag})
      : super(style, tag);
  final List<VShape> children;

  /// Rotation in degrees about [pivot] (SVG `rotate(a cx cy)`).
  final double rotate;
  final Offset pivot;

  /// A general affine transform applied about the origin, after [rotate]
  /// (SVG `transform`), or null for none.
  final Matrix4? transform;
}

/// Another piece of art fitted into [rect] (SVG `<use>` of a symbol).
class VUse extends VShape {
  const VUse(this.art, this.rect) : super(VStyle.none, null);
  final VectorArt art;
  final Rect rect;
}

/// A piece of vector art in its own coordinate box (SVG viewBox).
@immutable
class VectorArt {
  const VectorArt(this.box, this.shapes, {this.origin = Offset.zero});
  final Size box;
  final Offset origin;
  final List<VShape> shapes;

  VectorArt operator +(VectorArt other) => VectorArt(box, [...shapes, ...other.shapes], origin: origin);
}

/// Draws [VectorArt].
abstract final class VectorPainter {
  /// Paints [art] scaled uniformly and centred into [dst]. [eyeOpen] squashes
  /// shapes tagged [VTag.eye] vertically about their own centre.
  static void paint(
    Canvas canvas,
    VectorArt art,
    Rect dst, {
    Color color = Palette.ink,
    VStyle base = VStyle.none,
    double pixelRatio = 1,
    double eyeOpen = 1,
  }) {
    final s = math.min(dst.width / art.box.width, dst.height / art.box.height);
    canvas.save();
    canvas.translate(dst.left + (dst.width - art.box.width * s) / 2, dst.top + (dst.height - art.box.height * s) / 2);
    canvas.scale(s);
    canvas.translate(-art.origin.dx, -art.origin.dy);
    final ctx = _Ctx(color, pixelRatio * s, eyeOpen);
    for (final shape in art.shapes) {
      _draw(canvas, shape, base, ctx);
    }
    canvas.restore();
  }

  static void _draw(Canvas canvas, VShape shape, VStyle parent, _Ctx ctx) {
    final style = shape.style.over(parent);
    switch (shape) {
      case VGroup():
        canvas.save();
        if (shape.tag == VTag.eye && ctx.eyeOpen < 1) _squash(canvas, _bounds(shape).center, ctx.eyeOpen);
        if (shape.rotate != 0) {
          canvas.translate(shape.pivot.dx, shape.pivot.dy);
          canvas.rotate(shape.rotate * math.pi / 180);
          canvas.translate(-shape.pivot.dx, -shape.pivot.dy);
        }
        if (shape.transform != null) canvas.transform(shape.transform!.storage);
        for (final child in shape.children) {
          _draw(canvas, child, style, ctx);
        }
        canvas.restore();
      case VText():
        final tp = TextPainter(
          text: TextSpan(
            text: shape.text,
            style: TextStyle(fontFamily: shape.family, fontSize: shape.size, color: shape.color, height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final metrics = tp.computeLineMetrics();
        final ascent = metrics.isEmpty ? shape.size : metrics.first.ascent;
        tp.paint(canvas, shape.baseline - Offset(tp.width / 2, ascent));
      case VUse():
        final a = shape.art;
        final k = math.min(shape.rect.width / a.box.width, shape.rect.height / a.box.height);
        canvas.save();
        canvas.translate(shape.rect.left + (shape.rect.width - a.box.width * k) / 2,
            shape.rect.top + (shape.rect.height - a.box.height * k) / 2);
        canvas.scale(k);
        canvas.translate(-a.origin.dx, -a.origin.dy);
        final inner = _Ctx(ctx.current, ctx.pixelRatio * k, ctx.eyeOpen);
        for (final child in a.shapes) {
          _draw(canvas, child, VStyle.none, inner);
        }
        canvas.restore();
      case VPath():
        _fillStroke(canvas, SvgPath.parse(shape.d), style, ctx, shape.tag);
      case VRect():
        final path = Path()..addRRect(RRect.fromRectAndRadius(shape.rect, Radius.circular(shape.radius)));
        _fillStroke(canvas, path, style, ctx, shape.tag);
      case VEllipse():
        final path = Path()
          ..addOval(Rect.fromCenter(center: shape.center, width: shape.rx * 2, height: shape.ry * 2));
        _fillStroke(canvas, path, style, ctx, shape.tag);
    }
  }

  static void _squash(Canvas canvas, Offset c, double open) {
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, open);
    canvas.translate(-c.dx, -c.dy);
  }

  static Rect _bounds(VShape shape) => switch (shape) {
        VPath() => SvgPath.parse(shape.d).getBounds(),
        VRect() => shape.rect,
        VEllipse() => Rect.fromCenter(center: shape.center, width: shape.rx * 2, height: shape.ry * 2),
        VUse() => shape.rect,
        VText() => Rect.fromCenter(center: shape.baseline, width: 0, height: 0),
        VGroup() => shape.children.map(_bounds).reduce((a, b) => a.expandToInclude(b)),
      };

  static void _fillStroke(Canvas canvas, Path path, VStyle style, _Ctx ctx, VTag? tag) {
    final squash = tag == VTag.eye && ctx.eyeOpen < 1;
    if (squash) {
      canvas.save();
      _squash(canvas, path.getBounds().center, ctx.eyeOpen);
    }
    final alpha = style.opacity ?? 1;
    if (style.tone != null) {
      canvas.drawPath(path, Screentone.paint(style.tone!, ctx.pixelRatio));
    } else if (style.fill != null && style.fill != noInk) {
      canvas.drawPath(path, Paint()..color = ctx.resolve(style.fill!).withValues(alpha: alpha));
    }
    if (style.stroke != null && style.stroke != noInk) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = ctx.resolve(style.stroke!).withValues(alpha: alpha)
        ..strokeWidth = style.width ?? 1
        ..strokeCap = style.cap ?? StrokeCap.butt
        ..strokeJoin = style.join ?? StrokeJoin.miter;
      canvas.drawPath(style.dash == null ? path : Dashes.of(path, style.dash!), paint);
    }
    if (squash) canvas.restore();
  }
}

class _Ctx {
  _Ctx(this.current, this.pixelRatio, this.eyeOpen);
  final Color current;
  final double pixelRatio;
  final double eyeOpen;

  Color resolve(Color c) => c == currentInk ? current : c;
}

/// A [VectorArt] as a widget of the given [size] (the art's own box size when
/// null), drawn in [color] wherever the art uses [currentInk].
class VectorArtBox extends StatelessWidget {
  const VectorArtBox(this.art, {super.key, this.size, this.color = Palette.ink, this.base = VStyle.none});

  final VectorArt art;
  final Size? size;
  final Color color;
  final VStyle base;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size ?? art.box,
      child: CustomPaint(
        painter: _VectorArtPainter(art, color, base, MediaQuery.devicePixelRatioOf(context)),
      ),
    );
  }
}

class _VectorArtPainter extends CustomPainter {
  _VectorArtPainter(this.art, this.color, this.base, this.pixelRatio);
  final VectorArt art;
  final Color color;
  final VStyle base;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) =>
      VectorPainter.paint(canvas, art, Offset.zero & size, color: color, base: base, pixelRatio: pixelRatio);

  @override
  bool shouldRepaint(_VectorArtPainter old) =>
      old.art != art || old.color != color || old.base != base || old.pixelRatio != pixelRatio;
}
