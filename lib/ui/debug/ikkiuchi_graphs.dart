import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import 'debug_common.dart';
import 'ikkiuchi_values.dart';

/// [value]'s curve against Tobi's rating under its [graph]'s title: the
/// rating marked, his form's reach around it shaded, the curve's anchors
/// ringed. A chance per group also draws its share of games with any group
/// kept together, under a legend for the two lines.
class IkkiuchiCurveGraph extends StatelessWidget {
  const IkkiuchiCurveGraph(this.value, this.graph, this.rating, {super.key});

  final IkkiuchiValue value;
  final IkkiuchiGraph graph;
  final double rating;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GraphTitle(graph),
          if (value.anyInGame != null)
            const Wrap(spacing: IkkiuchiCurvesStyle.legendSpacing, children: [
              _LineKey(IkkiuchiCurvesStyle.line, ikkiuchiPerGroup),
              _LineKey(IkkiuchiCurvesStyle.anyLine, ikkiuchiAnyInGame),
            ]),
          SizedBox(
            height: IkkiuchiCurvesStyle.graphHeight,
            child: CustomPaint(painter: _CurvePainter(value, graph.floor, rating)),
          ),
        ],
      );
}

/// A line's colour and its name, in a graph's legend.
class _LineKey extends StatelessWidget {
  const _LineKey(this.color, this.name);

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: IkkiuchiCurvesStyle.legendLine, height: IkkiuchiCurvesStyle.lineStroke, color: color),
        const SizedBox(width: IkkiuchiToolsStyle.gap / 2),
        Text(name, style: const TextStyle(fontSize: IkkiuchiCurvesStyle.nameFont)),
      ]);
}

/// [shares], adding up to the whole at every rating, as bands stacked from
/// the first up, under the [graph]'s title and a legend: the rating marked
/// and each share there labelled beside it.
class IkkiuchiSharesGraph extends StatelessWidget {
  const IkkiuchiSharesGraph(this.shares, this.graph, this.rating, {super.key});

  final List<IkkiuchiValue> shares;
  final IkkiuchiGraph graph;
  final double rating;

  @override
  Widget build(BuildContext context) {
    const fills = IkkiuchiCurvesStyle.shareFills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GraphTitle(graph),
        const SizedBox(height: IkkiuchiToolsStyle.gap),
        Wrap(
          spacing: IkkiuchiCurvesStyle.legendSpacing,
          children: [
            for (final (i, share) in shares.indexed)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: IkkiuchiCurvesStyle.legendSwatch,
                  height: IkkiuchiCurvesStyle.legendSwatch,
                  color: fills[i % fills.length],
                ),
                const SizedBox(width: IkkiuchiToolsStyle.gap / 2),
                Text(share.name, style: const TextStyle(fontSize: IkkiuchiCurvesStyle.nameFont)),
              ]),
          ],
        ),
        SizedBox(
          height: IkkiuchiCurvesStyle.sharesHeight,
          child: CustomPaint(painter: _SharesPainter(shares, rating)),
        ),
      ],
    );
  }
}

class _GraphTitle extends StatelessWidget {
  const _GraphTitle(this.graph);

  final IkkiuchiGraph graph;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: IkkiuchiCurvesStyle.titleGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(graph.title,
                style: const TextStyle(fontSize: IkkiuchiCurvesStyle.titleFont, fontWeight: Weights.bold)),
            Text(graph.note,
                style: const TextStyle(fontSize: IkkiuchiCurvesStyle.smallFont, color: IkkiuchiToolsStyle.soft)),
          ],
        ),
      );
}

/// What both graphs share: the plot inside its margins over the curves'
/// ratings, its axes, labels and pills, and the marker at [rating].
abstract class _RatingPlot extends CustomPainter {
  _RatingPlot(this.rating);

  final double rating;

  static const min = IkkiuchiTuning.ratingMin, max = IkkiuchiTuning.ratingMax;
  static const _gap = IkkiuchiCurvesStyle.axisLabelGap;
  static final _label = debugMono.copyWith(fontSize: IkkiuchiCurvesStyle.axisFont, color: IkkiuchiToolsStyle.soft);

  static Rect plotIn(Size size) => IkkiuchiCurvesStyle.graphMargin.deflateRect(Offset.zero & size);

  static double xAt(Rect plot, double r) => plot.left + plot.width * (r - min) / (max - min);

  static TextPainter _laid(String s, TextStyle style) =>
      TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();

  /// [s] with its [align] point at [anchor].
  static void text(Canvas canvas, String s, Offset anchor, Alignment align) {
    final tp = _laid(s, _label);
    tp.paint(canvas, anchor - Offset(tp.width * (align.x + 1) / 2, tp.height * (align.y + 1) / 2));
    tp.dispose();
  }

  /// A label under the plot at each rating tick, and with [grid] a line up
  /// through the plot.
  static void ratingAxis(Canvas canvas, Rect plot, {Paint? grid}) {
    for (var r = min; r <= max; r += IkkiuchiToolsTuning.ratingTick) {
      final x = xAt(plot, r);
      if (grid != null) canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      text(canvas, '${r.round()}', Offset(x, plot.bottom + _gap), Alignment.topCenter);
    }
  }

  /// A label left of the plot at each division of 0 to [top], and with
  /// [grid] a line across the plot.
  static void valueAxis(Canvas canvas, Rect plot, double top, String Function(double) label, {Paint? grid}) {
    for (var i = 0; i <= IkkiuchiCurvesStyle.valueDivisions; i++) {
      final value = top * i / IkkiuchiCurvesStyle.valueDivisions;
      final y = plot.bottom - plot.height * i / IkkiuchiCurvesStyle.valueDivisions;
      if (grid != null) canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      text(canvas, label(value), Offset(plot.left - _gap, y), Alignment.centerRight);
    }
  }

  static Paint gridPaint(Color color) => Paint()
    ..color = color
    ..strokeWidth = IkkiuchiCurvesStyle.gridStroke;

  /// The marker's line at [x] down the plot, over a paper [halo] when
  /// given.
  static void markerLine(Canvas canvas, Rect plot, double x, {double? halo}) {
    final top = Offset(x, plot.top), bottom = Offset(x, plot.bottom);
    if (halo != null) {
      canvas.drawLine(top, bottom, Paint()
        ..color = Palette.paper
        ..strokeWidth = IkkiuchiCurvesStyle.markerStroke + 2 * halo);
    }
    canvas.drawLine(top, bottom, Paint()
      ..color = IkkiuchiCurvesStyle.marker
      ..strokeWidth = IkkiuchiCurvesStyle.markerStroke);
  }

  /// A dot of [color] at [at], ringed in paper.
  static void dot(Canvas canvas, Offset at, double radius, Color color) {
    canvas.drawCircle(at, radius + IkkiuchiCurvesStyle.markerRing, Paint()..color = Palette.paper);
    canvas.drawCircle(at, radius, Paint()..color = color);
  }

  /// The size of a pill holding [tp], and [lead] room before the text.
  static Size pillSize(TextPainter tp, {double lead = 0}) {
    const pad = IkkiuchiCurvesStyle.pillPadding;
    return Size(pad.horizontal + lead + tp.width, pad.vertical + tp.height);
  }

  /// [tp] on a rounded pill of [fill] filling [box], a [border] round it
  /// when given, [lead] room before the text.
  static void pill(Canvas canvas, TextPainter tp, Rect box, Color fill, {Color? border, double lead = 0}) {
    final r = RRect.fromRectAndRadius(box, const Radius.circular(IkkiuchiCurvesStyle.pillRadius));
    canvas.drawRRect(r, Paint()..color = fill);
    if (border != null) {
      canvas.drawRRect(r, Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = IkkiuchiCurvesStyle.gridStroke);
    }
    const pad = IkkiuchiCurvesStyle.pillPadding;
    tp.paint(canvas, Offset(box.left + pad.left + lead, box.top + pad.top));
  }

  static TextStyle pillStyle(Color color) =>
      debugMono.copyWith(fontSize: IkkiuchiCurvesStyle.numberFont, fontWeight: Weights.bold, color: color);
}

/// One value's curve: his form's reach shaded, grid and axes, a floor
/// dashed, the curve over a wash, its anchors ringed, and the marker with
/// the value on a pill above the plot.
class _CurvePainter extends _RatingPlot {
  _CurvePainter(this.value, this.floor, super.rating);

  final IkkiuchiValue value;
  final double? floor;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _RatingPlot.plotIn(size);
    final ratings = [for (var r = _RatingPlot.min; r <= _RatingPlot.max; r += IkkiuchiToolsTuning.curveStep) r];
    final points = [for (final r in ratings) (r, value.at(r))];
    final any = value.anyInGame;
    final anyPoints = [if (any != null) for (final r in ratings) (r, any.at(r))];
    final top = _axisTop(
        [for (final (_, v) in [...points, ...anyPoints, ...value.anchors]) v, ?floor].reduce(math.max));
    Offset at(double r, double v) => Offset(_RatingPlot.xAt(plot, r), plot.bottom - plot.height * v / top);

    final band = Paint()..color = IkkiuchiCurvesStyle.formBand;
    for (final sds in IkkiuchiToolsTuning.sigmas) {
      final reach = sds * IkkiuchiTuning.formSd;
      canvas.drawRect(
        Rect.fromLTRB(_RatingPlot.xAt(plot, math.max(_RatingPlot.min, rating - reach)), plot.top,
            _RatingPlot.xAt(plot, math.min(_RatingPlot.max, rating + reach)), plot.bottom),
        band,
      );
    }
    final grid = _RatingPlot.gridPaint(IkkiuchiCurvesStyle.grid);
    _RatingPlot.valueAxis(canvas, plot, top, value.unit.axis, grid: grid);
    _RatingPlot.ratingAxis(canvas, plot, grid: grid);

    if (floor case final floor?) {
      final y = at(_RatingPlot.min, floor).dy;
      final dash = Paint()
        ..color = IkkiuchiCurvesStyle.floor
        ..strokeWidth = IkkiuchiCurvesStyle.floorStroke;
      const step = IkkiuchiCurvesStyle.floorDash + IkkiuchiCurvesStyle.floorDashGap;
      for (var x = plot.left; x < plot.right; x += step) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + IkkiuchiCurvesStyle.floorDash, plot.right), y), dash);
      }
    }

    Path through(List<(double, double)> points) {
      final path = Path();
      for (final (i, (r, v)) in points.indexed) {
        final o = at(r, v);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      return path;
    }

    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiCurvesStyle.lineStroke
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final line = through(points);
    final wash = Path.from(line)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(wash, Paint()..color = IkkiuchiCurvesStyle.lineWash);
    if (any != null) canvas.drawPath(through(anyPoints), stroke(IkkiuchiCurvesStyle.anyLine));
    canvas.drawPath(line, stroke(IkkiuchiCurvesStyle.line));
    _anchors(canvas, [for (final (r, v) in value.anchors) at(r, v)]);

    final mark = at(rating, value.at(rating));
    _RatingPlot.markerLine(canvas, plot, mark.dx);
    if (any != null) {
      final anyMark = at(rating, any.at(rating));
      _RatingPlot.dot(canvas, anyMark, IkkiuchiCurvesStyle.markerRadius, IkkiuchiCurvesStyle.anyLine);
    }
    _RatingPlot.dot(canvas, mark, IkkiuchiCurvesStyle.markerRadius, IkkiuchiCurvesStyle.marker);
    final label = [
      value.unit.format(value.at(rating)),
      if (any != null) 'any ${any.unit.format(any.at(rating))}',
    ].join(' · ');
    final tp = _RatingPlot._laid(label, _RatingPlot.pillStyle(IkkiuchiCurvesStyle.pillText));
    final box = _RatingPlot.pillSize(tp);
    final cx = mark.dx.clamp(plot.left + box.width / 2, plot.right - box.width / 2);
    _RatingPlot.pill(
      canvas,
      tp,
      Rect.fromCenter(
          center: Offset(cx, plot.top - IkkiuchiCurvesStyle.axisLabelGap - box.height / 2),
          width: box.width,
          height: box.height),
      IkkiuchiCurvesStyle.pillFill,
    );
    tp.dispose();
  }

  /// The value axis's top: [max] rounded up to one of
  /// [IkkiuchiCurvesStyle.axisSteps] times a power of ten.
  static double _axisTop(double max) {
    if (max <= 0) return IkkiuchiCurvesStyle.axisSteps.first;
    final power = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
    return IkkiuchiCurvesStyle.axisSteps.map((s) => s * power).firstWhere((top) => top >= max);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.rating != rating || old.value != value || old.floor != floor;
}

/// Rings at a curve's anchors.
void _anchors(Canvas canvas, List<Offset> at) {
  final fill = Paint()..color = IkkiuchiCurvesStyle.anchorFill;
  final ring = Paint()
    ..color = IkkiuchiCurvesStyle.line
    ..style = PaintingStyle.stroke
    ..strokeWidth = IkkiuchiCurvesStyle.anchorStroke;
  for (final o in at) {
    canvas
      ..drawCircle(o, IkkiuchiCurvesStyle.anchorRadius, fill)
      ..drawCircle(o, IkkiuchiCurvesStyle.anchorRadius, ring);
  }
}

/// The shares stacked: a band for each over 0 to 100%, paper gaps between
/// them and paper grid lines over them, the anchors of a share's own curve
/// ringed on its band's top, and at the marker each share's value on a
/// pill beside it, tied to its band's middle.
class _SharesPainter extends _RatingPlot {
  _SharesPainter(this.shares, super.rating);

  final List<IkkiuchiValue> shares;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _RatingPlot.plotIn(size);
    const fills = IkkiuchiCurvesStyle.shareFills;
    final ratings = [
      for (var r = _RatingPlot.min; r <= _RatingPlot.max; r += IkkiuchiToolsTuning.curveStep) r,
    ];
    Offset at(double r, double v) => Offset(_RatingPlot.xAt(plot, r), plot.bottom - plot.height * v);
    double topOf(int share, double r) => shares.take(share + 1).fold(0.0, (sum, s) => sum + s.at(r));

    final tops = [
      for (var i = 0; i < shares.length; i++) [for (final r in ratings) at(r, topOf(i, r))],
    ];
    for (var i = 0; i < shares.length; i++) {
      final bottom = i == 0 ? [for (final r in ratings) at(r, 0)] : tops[i - 1];
      final band = Path()..addPolygon([...tops[i], ...bottom.reversed], true);
      canvas.drawPath(band, Paint()..color = fills[i % fills.length]);
    }
    final gap = Paint()
      ..color = Palette.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiCurvesStyle.shareGap;
    for (final edge in tops.take(shares.length - 1)) {
      canvas.drawPath(Path()..addPolygon(edge, false), gap);
    }
    final grid = _RatingPlot.gridPaint(IkkiuchiCurvesStyle.shareGrid);
    for (var i = 1; i < IkkiuchiCurvesStyle.valueDivisions; i++) {
      final y = plot.bottom - plot.height * i / IkkiuchiCurvesStyle.valueDivisions;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    _RatingPlot.valueAxis(canvas, plot, 1, IkkiuchiUnit.percent.axis);
    _RatingPlot.ratingAxis(canvas, plot);
    for (final (i, share) in shares.indexed) {
      _anchors(canvas, [for (final (r, _) in share.anchors) at(r, topOf(i, r))]);
    }

    final x = _RatingPlot.xAt(plot, rating);
    _RatingPlot.markerLine(canvas, plot, x, halo: IkkiuchiCurvesStyle.markerHalo);
    _labels(canvas, plot, x);
  }

  /// Each share's value at the marker on a paper pill with its swatch,
  /// beside the marker on the roomier side, as near its band's middle as
  /// the pills' spacing lets it be, a leader from the band to the pill.
  void _labels(Canvas canvas, Rect plot, double x) {
    const fills = IkkiuchiCurvesStyle.shareFills;
    const swatch = IkkiuchiCurvesStyle.shareSwatch;
    final lead = swatch + IkkiuchiCurvesStyle.pillPadding.left;
    final style = _RatingPlot.pillStyle(Palette.ink);
    final laid = [for (final s in shares) _RatingPlot._laid(s.unit.format(s.at(rating)), style)];
    final sizes = [for (final tp in laid) _RatingPlot.pillSize(tp, lead: lead)];
    final mids = <double>[];
    var below = 0.0;
    for (final s in shares) {
      final share = s.at(rating);
      mids.add(plot.bottom - plot.height * (below + share / 2));
      below += share;
    }

    // Centres from the bottom band up, pushed apart, then kept in the plot.
    final ys = [for (final (i, y) in mids.indexed) math.min(y, plot.bottom - sizes[i].height / 2)];
    for (var i = 1; i < ys.length; i++) {
      final apart = (sizes[i - 1].height + sizes[i].height) / 2 + IkkiuchiCurvesStyle.shareLabelSpacing;
      ys[i] = math.min(ys[i], ys[i - 1] - apart);
    }
    ys[ys.length - 1] = math.max(ys.last, plot.top + sizes.last.height / 2);
    for (var i = ys.length - 2; i >= 0; i--) {
      final apart = (sizes[i + 1].height + sizes[i].height) / 2 + IkkiuchiCurvesStyle.shareLabelSpacing;
      ys[i] = math.max(ys[i], ys[i + 1] + apart);
    }

    final right = x < plot.center.dx;
    final leader = Paint()
      ..color = IkkiuchiCurvesStyle.marker
      ..strokeWidth = IkkiuchiCurvesStyle.markerStroke;
    for (final (i, tp) in laid.indexed) {
      final size = sizes[i];
      final edge = x + (right ? 1 : -1) * IkkiuchiCurvesStyle.shareLabelOffset;
      final box = Rect.fromLTWH(right ? edge : edge - size.width, ys[i] - size.height / 2, size.width, size.height);
      canvas.drawLine(Offset(x, mids[i]), Offset(edge, ys[i]), leader);
      _RatingPlot.dot(canvas, Offset(x, mids[i]), IkkiuchiCurvesStyle.anchorRadius, IkkiuchiCurvesStyle.marker);
      _RatingPlot.pill(canvas, tp, box, IkkiuchiCurvesStyle.shareLabelFill,
          border: IkkiuchiCurvesStyle.shareLabelBorder, lead: lead);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(box.left + IkkiuchiCurvesStyle.pillPadding.left + swatch / 2, ys[i]),
            width: swatch,
            height: swatch),
        Paint()..color = fills[i % fills.length],
      );
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_SharesPainter old) => old.rating != rating || old.shares != shares;
}
