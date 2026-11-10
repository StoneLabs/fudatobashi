import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child], one line, at its own size or scaled down to the width it is
/// given; nothing, taking no room, where that would take it under
/// [minScale]. Measured, it is as tall as the line at its own size.
class GiveWay extends StatelessWidget {
  const GiveWay({super.key, required this.minScale, required this.child});

  final double minScale;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _Dropped(minScale: minScale, child: FittedBox(fit: BoxFit.scaleDown, child: child));
}

class _Dropped extends SingleChildRenderObjectWidget {
  const _Dropped({required this.minScale, required super.child});

  final double minScale;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDropped(minScale);

  @override
  void updateRenderObject(BuildContext context, _RenderDropped renderObject) => renderObject.minScale = minScale;
}

class _RenderDropped extends RenderProxyBox {
  _RenderDropped(this._minScale);

  double _minScale;
  set minScale(double value) {
    if (value == _minScale) return;
    _minScale = value;
    markNeedsLayout();
  }

  bool _shown = true;

  bool _fits(BoxConstraints constraints) =>
      child!.getMaxIntrinsicWidth(double.infinity) * _minScale <= constraints.maxWidth;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => super.computeMinIntrinsicHeight(double.infinity);

  @override
  double computeMaxIntrinsicHeight(double width) => super.computeMaxIntrinsicHeight(double.infinity);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _fits(constraints) ? super.computeDryLayout(constraints) : constraints.smallest;

  @override
  void performLayout() {
    _shown = _fits(constraints);
    child!.layout(constraints, parentUsesSize: true);
    size = _shown ? child!.size : constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_shown) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _shown && super.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_shown) super.visitChildrenForSemantics(visitor);
  }
}
