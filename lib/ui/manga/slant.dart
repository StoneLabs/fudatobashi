import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'panel.dart';
import 'static_art.dart';

/// Lays [child] out [extra] taller than the room it takes, and paints it
/// [up] higher: a panel whose slanted top edge reaches above its place into
/// the gap over it, as the journey home's panels share their edges.
class Lifted extends SingleChildRenderObjectWidget {
  const Lifted({super.key, required this.extra, required this.up, required Widget super.child});

  final double extra, up;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderLifted(extra, up);

  @override
  void updateRenderObject(BuildContext context, RenderLifted renderObject) => renderObject
    ..extra = extra
    ..up = up;
}

/// [Lifted]'s render object.
class RenderLifted extends RenderShiftedBox {
  RenderLifted(this._extra, this._up) : super(null);

  double _extra, _up;

  set extra(double value) {
    if (value == _extra) return;
    _extra = value;
    markNeedsLayout();
  }

  set up(double value) {
    if (value == _up) return;
    _up = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) => c.copyWith(minHeight: c.minHeight + _extra, maxHeight: c.maxHeight + _extra);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(0, (child?.getMinIntrinsicHeight(width) ?? 0) - _extra);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(0, (child?.getMaxIntrinsicHeight(width) ?? 0) - _extra);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_inner(constraints));
    return constraints.constrain(Size(size.width, size.height - _extra));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width, child.size.height - _extra));
    (child.parentData! as BoxParentData).offset = Offset(0, -_up);
  }
}

/// Gives the [SlantPanel]s, [SlantRow]s and summary heroes under it [cut]
/// in place of their own; a cut of 0 makes them straight.
class SlantCut extends InheritedWidget {
  const SlantCut({super.key, required this.cut, required super.child});

  final double cut;

  /// The cut over [context], else [own].
  static double of(BuildContext context, double own) =>
      context.dependOnInheritedWidgetOfExactType<SlantCut>()?.cut ?? own;

  @override
  bool updateShouldNotify(SlantCut oldWidget) => cut != oldWidget.cut;
}

/// A panel in a stack of panels whose shared edges rise [cut] (or a
/// [SlantCut]'s) over its width: its top edge slanted ([slantTop]) or flat,
/// likewise its bottom. Its place is that of its left side; a slanted top
/// reaches above it.
class SlantPanel extends StatelessWidget {
  const SlantPanel({
    super.key,
    this.slantTop = true,
    this.slantBottom = true,
    this.cut = HomeLayout.mapCut,
    this.color = Palette.paper,
    this.art = const [],
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final bool slantTop, slantBottom;
  final double cut;
  final Color color;
  final List<ArtLayer> art;

  /// Inside the panel, from its left side's top.
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cut = SlantCut.of(context, this.cut);
    final top = slantTop ? cut : 0.0;
    return Lifted(
      extra: top,
      up: top,
      child: MangaPanel(
        shape: PanelShape(topLeft: Offset(0, top), bottomRight: Offset(0, slantBottom ? cut : 0)),
        color: color,
        art: art,
        padding: padding + EdgeInsets.only(top: top),
        child: child,
      ),
    );
  }
}

/// Panels side by side, slices of one band whose edges rise [cut] (or a
/// [SlantCut]'s) over the band's width, in [colors]; as tall as the
/// tallest.
class SlantRow extends StatelessWidget {
  const SlantRow({
    super.key,
    required this.children,
    required this.colors,
    this.cut = HomeLayout.mapCut,
    this.gap = Gaps.panel,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final List<Color> colors;
  final double cut, gap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final n = children.length;
        final tw = (w - gap * (n - 1)) / n;
        final slope = SlantCut.of(context, cut) / w;
        final lift = slope * tw;
        final row = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            SizedBox(
              width: tw,
              child: Lifted(
                extra: lift,
                up: slope * (i * (tw + gap) + tw),
                child: MangaPanel(
                  shape: PanelShape(topLeft: Offset(0, lift), bottomRight: Offset(0, lift)),
                  color: colors[i % colors.length],
                  padding: padding + EdgeInsets.only(top: lift),
                  child: child,
                ),
              ),
            ),
          ],
        ]);
        return IntrinsicHeight(child: row);
      });
}
