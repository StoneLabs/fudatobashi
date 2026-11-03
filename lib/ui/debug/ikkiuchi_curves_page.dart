import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../play/time_format.dart';
import 'debug_common.dart';

/// The developer's view of Tobi's curves (一騎打ち): a table of every value
/// he plays with at the rating the slider picks, then a graph of each
/// against his rating, its anchors dotted and that rating marked.
class IkkiuchiCurvesPage extends StatefulWidget {
  const IkkiuchiCurvesPage({super.key, this.rating = IkkiuchiToolsTuning.ratingStart});

  /// The rating the page opens at.
  final double rating;

  @override
  State<IkkiuchiCurvesPage> createState() => _IkkiuchiCurvesPageState();
}

class _IkkiuchiCurvesPageState extends State<IkkiuchiCurvesPage> {
  late double _rating = widget.rating;

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    final tobi = IkkiuchiTobi(_rating);
    final moves = tobi.moves;
    const fixed = IkkiuchiTuning.wildMoves;
    return DebugScaffold(
      title: "Tobi's curves",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: IkkiuchiToolsStyle.padding.copyWith(bottom: 0),
            child: DebugSlider(
              label: 'rating ${_rating.round()}',
              value: _rating,
              min: IkkiuchiTuning.ratingMin,
              max: IkkiuchiTuning.ratingMax,
              divisions: (IkkiuchiTuning.ratingMax - IkkiuchiTuning.ratingMin) ~/ IkkiuchiToolsTuning.ratingStep,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: IkkiuchiToolsStyle.padding,
              children: [
                Text('At ${_rating.round()}', style: title),
                const SizedBox(height: IkkiuchiToolsStyle.gap),
                DebugGrid([
                  ['value', 'at ${_rating.round()}'],
                  for (final c in _curves) [c.name, c.format(c.value(tobi))],
                  ['whip', _percent(moves.whip)],
                  ['coil and lunge', _percent(moves.coilLunge)],
                  ['smear', _percent(moves.smear)],
                ]),
                const SizedBox(height: IkkiuchiToolsStyle.gap),
                Text('Fixed values', style: title),
                DebugKV('search spread', '${IkkiuchiTuning.searchSpread} (sd of log)'),
                DebugKV('stray touch', '${_percent(IkkiuchiTuning.strayShare)} of the pull'),
                DebugKV('correction', '${IkkiuchiTuning.correction.inMilliseconds} ms after a wrong touch'),
                DebugKV('arm by distance', 'swing × (1 + ${IkkiuchiTuning.armDistanceWeight} × (d / mean − 1))'),
                DebugKV('reach floor', _ms(IkkiuchiTuning.reachFloorMs)),
                DebugKV('wild moves', 'whip ${_percent(fixed.whip)} · coil and lunge ${_percent(fixed.coilLunge)} · '
                    'smear ${_percent(fixed.smear)} of what the sweep leaves'),
                DebugKV('form', 'sd ${IkkiuchiTuning.formSd.round()} rating points a match'),
                for (final c in _curves) ...[
                  const Divider(height: IkkiuchiToolsStyle.sectionGap),
                  Text(c.title, style: title),
                  const SizedBox(height: IkkiuchiToolsStyle.gap),
                  SizedBox(
                    height: IkkiuchiToolsStyle.graphHeight,
                    child: CustomPaint(painter: _CurveGraph(c, _rating)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of Tobi's curves: its [name] in the table and [title] over its
/// graph, its [anchors], its value at a rating, how its values read, and
/// a [floor] no value goes under.
class _Curve {
  const _Curve(this.name, this.title, this.anchors, this.value, this.format, {this.floor});

  final String name;
  final String title;
  final List<(double, double)> anchors;
  final double Function(IkkiuchiTobi tobi) value;
  final String Function(double value) format;
  final double? floor;
}

final _curves = [
  _Curve('take time (median)', 'Take time, median (log scale)', IkkiuchiTuning.takeMs.anchors, (t) => t.takeMs, _ms),
  _Curve('take spread', 'Take spread, sd of the log', IkkiuchiTuning.takeSpread.anchors, (t) => t.takeSpread,
      _plain),
  _Curve('blank chance', 'Blank chance per card read', IkkiuchiTuning.blankChance.anchors, (t) => t.blankChance,
      _percent),
  _Curve('search time (median)', 'Search time after a blank, median (log scale)', IkkiuchiTuning.searchMs.anchors,
      (t) => t.searchMs, _ms),
  _Curve('look-alike pull', 'Look-alike pull per call', IkkiuchiTuning.lookAlikePull.anchors,
      (t) => t.lookAlikePull, _percent),
  _Curve(
      'stray touch',
      'Stray touch on a からふだ with no look-alike (a share of the pull)',
      [for (final (r, v) in IkkiuchiTuning.lookAlikePull.anchors) (r, v * IkkiuchiTuning.strayShare)],
      (t) => t.strayChance,
      _percent),
  _Curve('arm swing', 'Arm swing at the average distance (log scale)', IkkiuchiTuning.armMs.anchors,
      (t) => t.armMs, _ms),
  _Curve('reach to hit', 'Reach to hit, the take animation (red: floor)', IkkiuchiTuning.reachMs.anchors,
      (t) => t.reachMs, _ms,
      floor: IkkiuchiTuning.reachFloorMs),
  _Curve('smart send', 'Smart send: a 送り札 that splits look-alikes', IkkiuchiTuning.smartSend.anchors,
      (t) => t.smartSend, _percent),
  _Curve('placing time', 'Time to lay out his side (log scale)', IkkiuchiTuning.placingSeconds.anchors,
      (t) => t.placingSeconds, _minutes),
  _Curve('sound grouping', 'Sound grouping: chance a match keeps first-sound groups together',
      IkkiuchiLayoutTuning.soundGrouping.anchors, (t) => t.soundGrouping, _percent),
  _Curve('友札 together', '友札 together: chance a match keeps look-alikes side by side',
      IkkiuchiLayoutTuning.tomofudaGrouping.anchors, (t) => t.tomofudaGrouping, _percent),
  _Curve('sweep', 'Sweep (払い) share of his arm moves; the wild moves split the rest',
      IkkiuchiTuning.sweepShare.anchors, (t) => t.moves.sweep, _percent),
];

String _ms(double ms) => ms >= Duration.millisecondsPerSecond
    ? '${(ms / Duration.millisecondsPerSecond).toStringAsFixed(2)} s'
    : '${ms.round()} ms';

String _percent(double share) {
  final percent = share * 100;
  return '${percent.toStringAsFixed(percent > 0 && percent < 10 ? 1 : 0)}%';
}

String _plain(double value) => value.toStringAsFixed(2);

String _minutes(double seconds) =>
    formatMinutes(Duration(milliseconds: (seconds * Duration.millisecondsPerSecond).round()));

/// [curve] against the rating: grid lines with their values, the curve,
/// its anchors, its floor dashed, and the [rating] marked with its value.
class _CurveGraph extends CustomPainter {
  _CurveGraph(this.curve, this.rating);

  final _Curve curve;
  final double rating;

  static const _min = IkkiuchiTuning.ratingMin, _max = IkkiuchiTuning.ratingMax;

  @override
  void paint(Canvas canvas, Size size) {
    const style = IkkiuchiToolsStyle.graphMargin;
    final plot = style.deflateRect(Offset.zero & size);
    final points = [
      for (var r = _min; r <= _max; r += IkkiuchiToolsTuning.curveStep) Offset(r, curve.value(IkkiuchiTobi(r))),
    ];
    final top = _axisTop([for (final p in points) p.dy, for (final (_, v) in curve.anchors) v].reduce(math.max));
    Offset at(Offset p) =>
        Offset(plot.left + plot.width * (p.dx - _min) / (_max - _min), plot.bottom - plot.height * p.dy / top);
    final label = debugMono.copyWith(fontSize: IkkiuchiToolsStyle.axisFont, color: Palette.mute);
    void text(String s, Offset anchor, Alignment align, {TextStyle? style}) {
      final span = TextSpan(text: s, style: style ?? label);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, anchor - Offset(tp.width * (align.x + 1) / 2, tp.height * (align.y + 1) / 2));
    }

    final grid = Paint()..color = IkkiuchiToolsStyle.grid;
    const gap = IkkiuchiToolsStyle.axisLabelGap;
    for (var i = 0; i <= IkkiuchiToolsStyle.valueDivisions; i++) {
      final value = top * i / IkkiuchiToolsStyle.valueDivisions;
      final y = at(Offset(_min, value)).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      text(curve.format(value), Offset(plot.left - gap, y), Alignment.centerRight);
    }
    for (var r = _min; r <= _max; r += IkkiuchiToolsTuning.ratingTick) {
      final x = at(Offset(r, 0)).dx;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      text('${r.round()}', Offset(x, plot.bottom + gap), Alignment.topCenter);
    }

    if (curve.floor case final floor?) {
      final y = at(Offset(_min, floor)).dy;
      final dash = Paint()
        ..color = IkkiuchiToolsStyle.floor
        ..strokeWidth = IkkiuchiToolsStyle.markerStroke;
      for (var x = plot.left; x < plot.right; x += IkkiuchiToolsStyle.floorDash + IkkiuchiToolsStyle.floorDashGap) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + IkkiuchiToolsStyle.floorDash, plot.right), y), dash);
      }
    }

    final path = Path();
    for (final (i, p) in points.indexed) {
      final o = at(p);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = IkkiuchiToolsStyle.lineStroke
        ..color = IkkiuchiToolsStyle.line,
    );
    final dot = Paint()..color = IkkiuchiToolsStyle.anchor;
    for (final (r, v) in curve.anchors) {
      canvas.drawCircle(at(Offset(r, v)), IkkiuchiToolsStyle.anchorRadius, dot);
    }

    final value = curve.value(IkkiuchiTobi(rating));
    final mark = at(Offset(rating, value));
    final marker = Paint()
      ..color = IkkiuchiToolsStyle.marker
      ..strokeWidth = IkkiuchiToolsStyle.markerStroke;
    canvas.drawLine(Offset(mark.dx, plot.top), Offset(mark.dx, plot.bottom), marker);
    canvas.drawCircle(mark, IkkiuchiToolsStyle.markerRadius, marker);
    final rightHalf = mark.dx > plot.center.dx;
    text(curve.format(value), Offset(mark.dx + (rightHalf ? -gap : gap), plot.top),
        rightHalf ? Alignment.topRight : Alignment.topLeft,
        style: label.copyWith(color: IkkiuchiToolsStyle.marker, fontWeight: Weights.bold));
  }

  /// The value axis's top: [max] rounded up to one of
  /// [IkkiuchiToolsStyle.axisSteps] times a power of ten.
  static double _axisTop(double max) {
    if (max <= 0) return IkkiuchiToolsStyle.axisSteps.first;
    final power = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
    return IkkiuchiToolsStyle.axisSteps.map((s) => s * power).firstWhere((top) => top >= max);
  }

  @override
  bool shouldRepaint(_CurveGraph old) => old.rating != rating || old.curve != curve;
}
