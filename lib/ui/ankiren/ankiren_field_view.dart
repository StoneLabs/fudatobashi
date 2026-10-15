import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';

/// 暗記練's field on screen: the opponent's half above the centre [band],
/// the own half below it, every card where its [FieldGeometry] puts it, at
/// the scale [scaleFor] picks. A folded field narrower than the screen opens
/// its middles up to span it; one too wide for it (zoom) pans sideways as
/// one, starting centred, while the band stays put. An [overlay] is laid
/// over the field and pans with it, without taking taps.
class AnkirenFieldView extends StatefulWidget {
  const AnkirenFieldView({
    super.key,
    required this.field,
    required this.landscape,
    required this.zoom,
    required this.card,
    required this.band,
    this.overlay,
    this.bandExtent,
  });

  final AnkirenField field;

  /// The true-scale field across a landscape screen; else the folded one,
  /// portrait.
  final bool landscape;

  /// Portrait only: never smaller than [AnkirenPlayLayout.minTapCardW].
  final bool zoom;

  /// The card for each poem, sized and placed by the view.
  final Widget Function(int poemId, FieldSide side) card;
  final Widget band;
  final Widget Function(FieldPlacement placement)? overlay;

  /// The [band]'s height when not the play screen's ([bandHeight]).
  final double? bandExtent;

  static double bandHeight({required bool landscape}) =>
      landscape ? AnkirenPlayLayout.bandLandscape : AnkirenPlayLayout.bandPortrait;

  /// Dp per centimetre for [geometry] in [area] (the space inside the
  /// padding), as the layout mock scales it: the field and its band fill
  /// the area, a portrait card is at most [AnkirenPlayLayout.maxCardW] wide
  /// and, with [zoom], at least [AnkirenPlayLayout.minTapCardW], however
  /// wide the field then gets. It always fits the height, [band] (the
  /// play screen's by default) included.
  static double scaleFor(FieldGeometry geometry, Size area,
      {required bool landscape, required bool zoom, double? band}) {
    final fitHeight = (area.height - (band ?? bandHeight(landscape: landscape))) / (2 * geometry.height);
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
  late final FieldGeometry _natural = FieldGeometry.of(widget.field, folded: !widget.landscape);
  FieldGeometry? _widened;

  /// The folded field opened up to [width] cm, kept while the width holds.
  FieldGeometry _widenedTo(double width) {
    final widened = _widened;
    if (widened != null && (widened.width - width).abs() < _widthTolerance) return widened;
    return _widened = FieldGeometry.of(widget.field, folded: true, minWidth: width);
  }

  static const _widthTolerance = 1e-6;

  @override
  void dispose() {
    _pan?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const pad = AnkirenPlayLayout.padding;
        final bandH = widget.bandExtent ?? AnkirenFieldView.bandHeight(landscape: widget.landscape);
        final area = Size(box.maxWidth - 2 * pad, box.maxHeight - 2 * pad);
        final s =
            AnkirenFieldView.scaleFor(_natural, area, landscape: widget.landscape, zoom: widget.zoom, band: bandH);
        final g = widget.landscape || _natural.width * s >= area.width ? _natural : _widenedTo(area.width / s);
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
        final overlay = widget.overlay;
        final field = SizedBox(
          width: width,
          height: height,
          child: Stack(children: [
            ...half(FieldSide.opponent, 0),
            ...half(FieldSide.own, halfH + bandH),
            if (overlay != null)
              Positioned.fill(
                child: IgnorePointer(child: overlay(FieldPlacement(geometry: g, scale: s, ownTop: halfH + bandH))),
              ),
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

/// Where an [AnkirenFieldView] draws its field: [scale] dp per centimetre,
/// the opponent's half at the top, the own half from [ownTop] down.
class FieldPlacement {
  const FieldPlacement({required this.geometry, required this.scale, required this.ownTop});

  final FieldGeometry geometry;
  final double scale;
  final double ownTop;

  double topOf(FieldSide side) => side == FieldSide.own ? ownTop : 0;

  /// [r], a rectangle of [side]'s half, on screen.
  Rect rectOf(FieldSide side, FieldRect r) =>
      Rect.fromLTWH(r.x * scale, topOf(side) + r.y * scale, r.w * scale, r.h * scale);

  /// [side]'s whole half on screen.
  Rect halfRect(FieldSide side) =>
      rectOf(side, FieldRect(0, 0, geometry.width, geometry.height));

  /// The card of [poemId] on screen, or null when it is not on the field.
  Rect? cardRect(int poemId) {
    for (final side in FieldSide.values) {
      if (geometry.half(side)[poemId] case final r?) return rectOf(side, r);
    }
    return null;
  }
}
