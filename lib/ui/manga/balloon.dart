import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// An oval speech balloon whose tail points at [speaker]: a spot relative to
/// the balloon's box (-1..1 spans the box; the speaker usually sits
/// outside it, e.g. `Alignment(1.8, 0.4)` for someone to the right).
///
/// The text keeps inside the oval. Given a fixed size, the balloon wraps its
/// child to the oval's inner width and scales it down if it is still too
/// tall. Given a free height, it grows around the wrapped child instead.
class SpeechBalloon extends StatelessWidget {
  const SpeechBalloon({
    super.key,
    required this.child,
    required this.speaker,
    this.padding = EdgeInsets.zero,
    this.color = Palette.paper,
    this.border = Strokes.control,
  });

  final Widget child;
  final Alignment speaker;

  /// Extra room inside the oval's text area.
  final EdgeInsets padding;
  final Color color;
  final double border;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BalloonPainter(speaker, color, border),
      child: _BalloonText(
        padding: padding,
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: Weights.black, height: BalloonStyle.lineHeight, color: Palette.ink),
          child: child,
        ),
      ),
    );
  }
}

/// Lays the child out in the oval's inscribed text area (see
/// [BalloonStyle.textWidth]).
class _BalloonText extends SingleChildRenderObjectWidget {
  const _BalloonText({required this.padding, required super.child});
  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBalloonText(padding);

  @override
  void updateRenderObject(BuildContext context, _RenderBalloonText renderObject) => renderObject.padding = padding;
}

class _RenderBalloonText extends RenderProxyBox {
  _RenderBalloonText(this._padding);

  EdgeInsets _padding;
  set padding(EdgeInsets v) {
    if (v == _padding) return;
    _padding = v;
    markNeedsLayout();
  }

  double _scale = 1;
  Offset _offset = Offset.zero;

  static const _fw = BalloonStyle.textWidth, _fh = BalloonStyle.textHeight;

  BoxConstraints _childConstraints(BoxConstraints c) => BoxConstraints(
      maxWidth: c.hasBoundedWidth ? math.max(0, c.maxWidth * _fw - _padding.horizontal) : double.infinity);

  Size _sizeFor(BoxConstraints c, Size natural) => c.constrain(Size(
        c.hasBoundedWidth ? c.maxWidth : (natural.width + _padding.horizontal) / _fw,
        c.hasTightHeight ? c.maxHeight : (natural.height + _padding.vertical) / _fh,
      ));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sizeFor(constraints, child.getDryLayout(_childConstraints(constraints)));
  }

  @override
  void performLayout() {
    final c = constraints;
    final child = this.child;
    if (child == null) {
      size = c.smallest;
      return;
    }
    child.layout(_childConstraints(c), parentUsesSize: true);
    final natural = child.size;
    size = _sizeFor(c, natural);
    final inner = _padding.deflateRect(
        Rect.fromCenter(center: size.center(Offset.zero), width: size.width * _fw, height: size.height * _fh));
    final fit = math.min(inner.width / natural.width, inner.height / natural.height);
    _scale = fit.isFinite && fit > 0 ? math.min(1, fit) : 1;
    _offset = inner.center - (natural * _scale).center(Offset.zero);
  }

  Matrix4 get _transform => Matrix4.identity()
    ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
    ..scaleByDouble(_scale, _scale, 1, 1);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.pushTransform(
        needsCompositing, offset, _transform, (context, offset) => context.paintChild(child!, offset));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child!.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      ((child?.getMaxIntrinsicWidth(double.infinity) ?? 0) + _padding.horizontal) / _fw;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      ((child?.getMaxIntrinsicHeight(width * _fw) ?? 0) + _padding.vertical) / _fh;

}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter(this.speaker, this.color, this.border);
  final Alignment speaker;
  final Color color;
  final double border;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = (Offset.zero & size).deflate(border / 2);
    final shape = Path.combine(PathOperation.union, Path()..addOval(oval), _tail(oval, speaker.withinRect(oval)));
    canvas.drawPath(shape, Paint()..color = color);
    canvas.drawPath(
      shape,
      Paint()
        ..color = Palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = border
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// A curved wedge from the oval's edge toward [target].
  static Path _tail(Rect oval, Offset target) {
    final c = oval.center;
    final a = oval.width / 2, b = oval.height / 2;
    final theta = math.atan2((target.dy - c.dy) / b, (target.dx - c.dx) / a);
    Offset edge(double t) => c + Offset(a * math.cos(t), b * math.sin(t));
    final root = edge(theta);
    final toTarget = target - root;
    final length = math.min(toTarget.distance, BalloonStyle.tailLength);
    if (length <= 0) return Path();
    final dir = toTarget / toTarget.distance;
    final tip = root + dir * length;
    final radius = math.sqrt(math.pow(a * math.sin(theta), 2) + math.pow(b * math.cos(theta), 2));
    final spread = BalloonStyle.tailBase / 2 / radius;
    final (left, right) = (edge(theta - spread), edge(theta + spread));
    // Both sides bow the same way, so the tail curls like a brush stroke.
    final bend = Offset(-dir.dy, dir.dx) * length * BalloonStyle.tailBend;
    final inward = c - root;
    final inset = inward / inward.distance * BalloonStyle.tailInset;
    return Path()
      ..moveTo(left.dx + inset.dx, left.dy + inset.dy)
      ..lineTo(left.dx, left.dy)
      ..quadraticBezierTo((left + tip).dx / 2 + bend.dx, (left + tip).dy / 2 + bend.dy, tip.dx, tip.dy)
      ..quadraticBezierTo((right + tip).dx / 2 + bend.dx, (right + tip).dy / 2 + bend.dy, right.dx, right.dy)
      ..lineTo(right.dx + inset.dx, right.dy + inset.dy)
      ..close();
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.speaker != speaker || old.color != color || old.border != border;
}
