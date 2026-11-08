import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// How a page's field preview looks ([FieldPreview]): [margin] around it;
/// shown from [minHeight] (always, and asking for that much, when it
/// [keepsMinHeight]); its [ground] under the [tatami] tile at
/// [tatamiScale]× density, in an ink frame [border] wide, the cards laid
/// out [padding] inside it; the band across it [band] tall in [bandColor],
/// its ink rules [bandRule] wide; every card face down in [backFill] with a
/// [backBorderWidth] edge in [backBorder].
class FieldPreviewSpec {
  const FieldPreviewSpec({
    required this.margin,
    required this.minHeight,
    this.keepsMinHeight = false,
    required this.ground,
    required this.tatami,
    required this.tatamiScale,
    required this.border,
    required this.padding,
    required this.band,
    required this.bandColor,
    required this.bandRule,
    required this.backFill,
    required this.backBorder,
    required this.backBorderWidth,
  });

  final EdgeInsets margin;
  final double minHeight;
  final bool keepsMinHeight;
  final Color ground;
  final String tatami;
  final double tatamiScale, border, padding, band;
  final Color bandColor;
  final double bandRule;
  final Color backFill, backBorder;
  final double backBorderWidth;
}

/// Where a preview's band and cards lie ([FieldPreview.layOut]): the band's
/// top, and each card's box.
typedef FieldPreviewLayout = ({double bandTop, List<Rect> cards});

/// A field's shape as it will lie, face down on its play screen's tatami,
/// for a trip's page ([spec]): the band across the frame at the top
/// [layOut] gives it and the cards where it puts them, in the room inside
/// the frame's padding. It fills the room it is given inside the margin,
/// asks for none (or for its least height when it keeps it), and shows
/// nothing when that is less than its least height.
class FieldPreview extends StatelessWidget {
  const FieldPreview({super.key, required this.spec, required this.semanticLabel, required this.layOut});

  final FieldPreviewSpec spec;
  final String semanticLabel;

  /// Where the band and cards lie in an area of that size and place.
  final FieldPreviewLayout Function(Rect area) layOut;

  @override
  Widget build(BuildContext context) {
    final spec = this.spec;
    return _AsksFor(
      height: spec.keepsMinHeight ? spec.minHeight + spec.margin.vertical : 0,
      child: LayoutBuilder(builder: (context, box) {
        final frame = spec.margin.deflateSize(box.biggest);
        if (!spec.keepsMinHeight && frame.height < spec.minHeight) return const SizedBox.shrink();
        return Semantics(
          image: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: Padding(
            padding: spec.margin,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: spec.ground,
                image: DecorationImage(
                  image: AssetImage(spec.tatami),
                  repeat: ImageRepeat.repeat,
                  scale: spec.tatamiScale,
                ),
                border: Border.all(color: Palette.ink, width: spec.border),
              ),
              child: Stack(children: _laidOut(frame)),
            ),
          ),
        );
      }),
    );
  }

  /// The band and every card in a frame of size [frame].
  List<Widget> _laidOut(Size frame) {
    final inside = (Offset.zero & frame).deflate(spec.border);
    final placed = layOut(inside.deflate(spec.padding));
    final rule = BorderSide(color: Palette.ink, width: spec.bandRule);
    final back = BorderSide(color: spec.backBorder, width: spec.backBorderWidth);
    return [
      Positioned(
        left: inside.left,
        top: placed.bandTop,
        width: inside.width,
        height: spec.band,
        child: DecoratedBox(
          decoration: BoxDecoration(color: spec.bandColor, border: Border(top: rule, bottom: rule)),
        ),
      ),
      for (final card in placed.cards)
        Positioned.fromRect(
          rect: card,
          child: DecoratedBox(decoration: BoxDecoration(color: spec.backFill, border: Border.fromBorderSide(back))),
        ),
    ];
  }
}

/// [child] as it lays out, but asking for no width and [height] when its
/// intrinsic size is measured, so a column that measures its children
/// leaves it only the room that is left over, and at least [height].
class _AsksFor extends SingleChildRenderObjectWidget {
  const _AsksFor({required this.height, required super.child});

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAsksFor(height);

  @override
  void updateRenderObject(BuildContext context, _RenderAsksFor renderObject) => renderObject.height = height;
}

class _RenderAsksFor extends RenderProxyBox {
  _RenderAsksFor(this._height);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;
}
