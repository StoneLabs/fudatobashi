import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';

/// 暗記練's field on screen: the opponent's half above the centre [band],
/// the own half below it, every card where [geometry] puts it, at the scale
/// [scaleFor] picks. A field too wide for the screen (zoom) pans sideways
/// as one, starting centred, while the band stays put.
class AnkirenFieldView extends StatefulWidget {
  const AnkirenFieldView({
    super.key,
    required this.geometry,
    required this.landscape,
    required this.zoom,
    required this.card,
    required this.band,
  });

  final FieldGeometry geometry;

  /// The true-scale field across a landscape screen; else the folded one,
  /// portrait.
  final bool landscape;

  /// Portrait only: never smaller than [AnkirenPlayLayout.minTapCardW].
  final bool zoom;

  /// The card for each poem, sized and placed by the view.
  final Widget Function(int poemId, FieldSide side) card;
  final Widget band;

  static double bandHeight({required bool landscape}) =>
      landscape ? AnkirenPlayLayout.bandLandscape : AnkirenPlayLayout.bandPortrait;

  /// Dp per centimetre for [geometry] in [area] (the space inside the
  /// padding), as the layout mock scales it: the field and its band fill
  /// the area, a portrait card is at most [AnkirenPlayLayout.maxCardW] wide
  /// and, with [zoom], at least [AnkirenPlayLayout.minTapCardW], however
  /// wide the field then gets. It always fits the height.
  static double scaleFor(FieldGeometry geometry, Size area, {required bool landscape, required bool zoom}) {
    final fitHeight = (area.height - bandHeight(landscape: landscape)) / (2 * geometry.height);
    var s = math.min(area.width / geometry.width, fitHeight);
    if (landscape) return s;
    s = math.min(s, AnkirenPlayLayout.maxCardW / AnkirenFieldSize.cardW);
    if (zoom) s = math.max(s, AnkirenPlayLayout.minTapCardW / AnkirenFieldSize.cardW);
    return math.min(s, fitHeight);
  }

  @override
  State<AnkirenFieldView> createState() => _AnkirenFieldViewState();
}

class _AnkirenFieldViewState extends State<AnkirenFieldView> {
  ScrollController? _pan;

  @override
  void dispose() {
    _pan?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const pad = AnkirenPlayLayout.padding;
        final g = widget.geometry;
        final bandH = AnkirenFieldView.bandHeight(landscape: widget.landscape);
        final area = Size(box.maxWidth - 2 * pad, box.maxHeight - 2 * pad);
        final s = AnkirenFieldView.scaleFor(g, area, landscape: widget.landscape, zoom: widget.zoom);
        final width = g.width * s;
        final halfH = g.height * s;
        final height = 2 * halfH + bandH;
        final top = pad + math.max(0.0, (area.height - height) / 2);

        Iterable<Widget> half(FieldSide side, double dy) => [
              for (final MapEntry(key: id, value: r) in g.half(side).entries)
                Positioned(
                  left: r.x * s,
                  top: dy + r.y * s,
                  width: r.w * s,
                  height: r.h * s,
                  child: widget.card(id, side),
                ),
            ];
        final field = SizedBox(
          width: width,
          height: height,
          child: Stack(children: [
            ...half(FieldSide.opponent, 0),
            ...half(FieldSide.own, halfH + bandH),
          ]),
        );

        final Widget placed;
        if (width > area.width) {
          final pan = _pan ??= ScrollController(initialScrollOffset: (width + 2 * pad - box.maxWidth) / 2);
          placed = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: pan,
            padding: const EdgeInsets.symmetric(horizontal: pad),
            child: field,
          );
        } else {
          placed = Center(child: field);
        }
        return Stack(children: [
          Positioned(left: 0, right: 0, top: top, height: height, child: placed),
          Positioned(left: 0, right: 0, top: top + halfH, height: bandH, child: widget.band),
        ]);
      });
}
