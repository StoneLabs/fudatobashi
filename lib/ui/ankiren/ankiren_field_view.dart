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
/// over the field and pans with it, without taking taps; with
/// [overlayOverBand] the band goes under the field so the overlay crosses
/// it too. A [foreground] is laid over the field and takes its touches,
/// but not the band's; an [underlay] lies under its cards.
///
/// With a [roomAbove] (landscape only) the field is the own half alone:
/// the room above the band, where the opponent's half would be, is only as
/// tall as it needs to be, at least [roomAbove], and the own half takes the
/// rest of the height. With [move], cards that change place glide there.
/// With a [growth], once [grown] the true-scale field grows evenly to its
/// limit: the own half stays on the bottom edge and the clusters on the
/// sides, so the cards grow upward and inward, the band with them.
class AnkirenFieldView extends StatefulWidget {
  const AnkirenFieldView({
    super.key,
    required this.field,
    required this.landscape,
    required this.zoom,
    required this.card,
    required this.band,
    this.overlay,
    this.overlayOverBand = false,
    this.foreground,
    this.aboveBand,
    this.underlay,
    this.bandExtent,
    this.trueSlots,
    this.roomAbove,
    this.move,
    this.growth,
    this.grown = false,
  }) : assert(roomAbove == null || landscape, 'only a true-scale field has a room above');

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

  /// Only for a band that takes no taps: the field would cover it.
  final bool overlayOverBand;
  final Widget Function(FieldPlacement placement)? foreground;

  /// Laid over the field and the band, taking no touches, where the field
  /// is (a true-scale field that does not pan): what must paint above the
  /// band, as a card carried across it.
  final Widget Function(FieldPlacement placement)? aboveBand;
  final Widget Function(FieldPlacement placement)? underlay;

  /// The [band]'s height when not the play screen's ([bandHeight]).
  final double? bandExtent;

  /// The card pitches a true-scale row spans, when not the territory's
  /// (see [FieldGeometry.of]).
  final double? trueSlots;
  final double? roomAbove;
  final Duration? move;
  final FieldGrowth? growth;
  final bool grown;

  static double bandHeight({required bool landscape}) =>
      landscape ? AnkirenPlayLayout.bandLandscape : AnkirenPlayLayout.bandPortrait;

  /// Dp per centimetre for [geometry] in [area] (the space inside the
  /// padding), as the layout mock scales it: the field and its band fill
  /// the area, a portrait card is at most [AnkirenPlayLayout.maxCardW] wide
  /// and, with [zoom], at least [AnkirenPlayLayout.minTapCardW], however
  /// wide the field then gets. It always fits the height, [band] (the
  /// play screen's by default) included, and the [roomAbove] the own half
  /// alone leaves above it instead of the opponent's half.
  static double scaleFor(FieldGeometry geometry, Size area,
      {required bool landscape, required bool zoom, double? band, double? roomAbove}) {
    final room = area.height - (band ?? bandHeight(landscape: landscape));
    final fitHeight = roomAbove == null ? room / (2 * geometry.height) : (room - roomAbove) / geometry.height;
    var s = math.min(area.width / geometry.width, fitHeight);
    if (landscape) return s;
    s = math.min(s, AnkirenPlayLayout.maxCardW / AnkirenFieldSize.cardW);
    if (zoom) s = math.max(s, AnkirenPlayLayout.minTapCardW / AnkirenFieldSize.cardW);
    return math.min(s, fitHeight);
  }

  @override
  State<AnkirenFieldView> createState() => _AnkirenFieldViewState();
}

/// How a true-scale field grows (see [AnkirenFieldView.growth]).
class FieldGrowth {
  const FieldGrowth({required this.limit, required this.duration, required this.curve});

  /// The factor the field grows by, at least 1, in an area (inside the
  /// padding) with a band [band] tall.
  final double Function(AnkirenField field, Size area, double band) limit;
  final Duration duration;
  final Curve curve;
}

class _AnkirenFieldViewState extends State<AnkirenFieldView> {
  ScrollController? _pan;
  late FieldGeometry _natural = _layOut();
  FieldGeometry? _widened;

  FieldGeometry _layOut() => FieldGeometry.of(widget.field, folded: !widget.landscape, trueSlots: widget.trueSlots);

  @override
  void didUpdateWidget(AnkirenFieldView old) {
    super.didUpdateWidget(old);
    if (widget.field != old.field || widget.trueSlots != old.trueSlots || widget.landscape != old.landscape) {
      _natural = _layOut();
      _widened = null;
    }
  }

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
        final roomAbove = widget.roomAbove;
        final fit = AnkirenFieldView.scaleFor(_natural, area,
            landscape: widget.landscape, zoom: widget.zoom, band: bandH, roomAbove: roomAbove);
        final growth = widget.growth;
        if (growth == null) return _fieldAt(box, area, bandH, fit, 1);
        return TweenAnimationBuilder<double>(
          tween: Tween(end: widget.grown ? growth.limit(widget.field, area, bandH) : 1),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : growth.duration,
          curve: growth.curve,
          builder: (context, grow, _) => _fieldAt(box, area, bandH, fit, grow),
        );
      });

  /// The field laid out in [area] at the scale [fit] picked, grown by
  /// [grow]: the same cards, the row's width held, so its gaps close.
  Widget _fieldAt(BoxConstraints box, Size area, double bandH, double fit, double grow) {
    const pad = AnkirenPlayLayout.padding;
    final roomAbove = widget.roomAbove;
    final s = fit * grow;
    final g = grow != 1
        ? FieldGeometry.of(widget.field,
            folded: false, trueSlots: FieldGeometry.slotsAcross(_natural.width / grow))
        : widget.landscape || _natural.width * s >= area.width
            ? _natural
            : _widenedTo(area.width / s);
    final width = g.width * s;
    final halfH = g.height * s;
    final aboveH = roomAbove == null ? halfH : area.height - bandH - halfH;
    final height = aboveH + bandH + halfH;
    final top = pad + math.max(0.0, (area.height - height) / 2);
    final placement = FieldPlacement(geometry: g, scale: s, ownTop: aboveH + bandH, bandTop: aboveH);
    final move = widget.move;

    Iterable<Widget> half(FieldSide side) => [
          for (final MapEntry(key: id, value: r) in g.half(side).entries)
            if (move == null)
              Positioned.fromRect(rect: placement.rectOf(side, r), child: widget.card(id, side))
            else
              AnimatedPositioned.fromRect(
                key: ValueKey(id),
                rect: placement.rectOf(side, r),
                duration: move,
                curve: AnkirenMotion.moveCurve,
                child: widget.card(id, side),
              ),
        ];
    final overlay = widget.overlay;
    final foreground = widget.foreground;
    final underlay = widget.underlay;
    final field = SizedBox(
      width: width,
      height: height,
      child: Stack(children: [
        if (underlay != null) Positioned.fill(child: IgnorePointer(child: underlay(placement))),
        if (roomAbove == null) ...half(FieldSide.opponent),
        ...half(FieldSide.own),
        if (overlay != null) Positioned.fill(child: IgnorePointer(child: overlay(placement))),
        if (foreground != null) Positioned.fill(child: foreground(placement)),
      ]),
    );

    final Widget placed;
    if (width > area.width + _widthTolerance) {
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
    final fieldLayer = Positioned(left: 0, right: 0, top: top, height: height, child: placed);
    final bandLayer = Positioned(left: 0, right: 0, top: top + aboveH, height: bandH, child: widget.band);
    final aboveBand = widget.aboveBand;
    final risen = aboveBand == null
        ? null
        : Positioned(
            left: 0,
            right: 0,
            top: top,
            height: height,
            child: IgnorePointer(
              child: Center(child: SizedBox(width: width, height: height, child: aboveBand(placement))),
            ),
          );
    return Stack(children: [...(widget.overlayOverBand ? [bandLayer, fieldLayer] : [fieldLayer, bandLayer]), ?risen]);
  }
}

/// Where an [AnkirenFieldView] draws its field: [scale] dp per centimetre,
/// the opponent's half (or the room above the band) at the top, the band
/// from [bandTop] and the own half from [ownTop] down.
class FieldPlacement {
  const FieldPlacement({required this.geometry, required this.scale, required this.ownTop, required this.bandTop});

  final FieldGeometry geometry;
  final double scale;
  final double ownTop;
  final double bandTop;

  double topOf(FieldSide side) => side == FieldSide.own ? ownTop : 0;

  /// [r], a rectangle of [side]'s half, on screen.
  Rect rectOf(FieldSide side, FieldRect r) =>
      Rect.fromLTWH(r.x * scale, topOf(side) + r.y * scale, r.w * scale, r.h * scale);

  /// [side]'s whole half on screen.
  Rect halfRect(FieldSide side) =>
      rectOf(side, FieldRect(0, 0, geometry.width, geometry.height));

  /// The room above the band, where the opponent's half is when it shows.
  Rect get roomAbove => Rect.fromLTWH(0, 0, geometry.width * scale, bandTop);

  /// A point on screen as a point of the own half, in centimetres.
  (double, double) onOwnHalf(Offset p) => (p.dx / scale, (p.dy - ownTop) / scale);

  /// The card of [poemId] on screen, or null when it is not on the field.
  Rect? cardRect(int poemId) {
    for (final side in FieldSide.values) {
      if (geometry.half(side)[poemId] case final r?) return rectOf(side, r);
    }
    return null;
  }
}
