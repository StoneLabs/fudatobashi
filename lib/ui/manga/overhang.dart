import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Room for what of [child] lies below its top [rise], as wide as the
/// child, showing nothing: what a tag drawn over a panel's top edge takes
/// of the panel under it.
class Overhang extends SingleChildRenderObjectWidget {
  const Overhang({super.key, required this.rise, required super.child});

  final double rise;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderOverhang(rise);

  @override
  void updateRenderObject(BuildContext context, RenderOverhang renderObject) => renderObject.rise = rise;
}

class RenderOverhang extends RenderProxyBox {
  RenderOverhang(this._rise);

  double _rise;
  set rise(double value) {
    if (value == _rise) return;
    _rise = value;
    markNeedsLayout();
  }

  double _below(double height) => math.max(0, height - _rise);

  @override
  double computeMinIntrinsicHeight(double width) => _below(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) => _below(super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = super.computeDryLayout(constraints.loosen());
    return constraints.constrain(Size(child.width, _below(child.height)));
  }

  @override
  void performLayout() {
    final child = this.child!..layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width, _below(child.size.height)));
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}
