import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/card_stats.dart';
import '../play/time_format.dart';

/// A plain polyline of recent response times, no axes or labels (the island
/// list's per-card sparkline).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.valuesMs, this.color = Palette.sea});

  final List<double> valuesMs;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ChartStyle.sparklineWidth,
        height: ChartStyle.sparklineHeight,
        child: CustomPaint(painter: _SparklinePainter(valuesMs, color)),
      );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), ChartStyle.dotRadius, Paint()..color = color);
      return;
    }
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = hi - lo < 1e-6 ? 1.0 : hi - lo;
    double x(int i) => size.width * i / (values.length - 1);
    double y(double v) => size.height - (v - lo) / span * size.height;
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => !listEquals(old.values, values) || old.color != color;
}

/// The series a viewer can toggle on the card detail screen: three rolling
/// averages and the percentile band.
enum ChartSeries {
  shortAverage(AttemptChartTuning.shortAverage),
  midAverage(AttemptChartTuning.midAverage),
  longAverage(AttemptChartTuning.longAverage),
  band(AttemptChartTuning.bandWindow);

  const ChartSeries(this.window);

  /// Timed attempts each point is taken over.
  final int window;

  /// Timed attempts the series needs before it starts.
  int get minCount => this == band ? AttemptChartTuning.bandMinCount : window;

  static const averages = [shortAverage, midAverage, longAverage];
}

/// A point of a chart series: the index of its attempt, and its time.
typedef ChartPoint = ({int x, double ms});

/// A card's attempts, ready to chart: every attempt on one chronological X
/// axis (a miss has no time, so it gets a marker instead of a dot), the
/// series over the timed ones, TOP SPEED and the ms axis. Build it once per
/// attempt list: the painted geometry is cached on it.
class AttemptChartData {
  AttemptChartData(List<AttemptRec> attempts)
      : attempts = List.unmodifiable(attempts),
        stats = CardStats(attempts);

  final List<AttemptRec> attempts;
  final CardStats stats;

  /// Index into [attempts] of each entry of `stats.timed`.
  late final List<int> timedXs = [for (final (i, a) in attempts.indexed) if (a.timed) i];

  /// The rolling averages, each from the attempt that fills its window.
  late final Map<ChartSeries, List<ChartPoint>> averages = {
    for (final series in ChartSeries.averages) series: _points(stats.rollingMean(series.window), series.minCount),
  };

  /// The band's edges.
  late final List<ChartPoint> bandLow = _band(AttemptChartTuning.bandLow);
  late final List<ChartPoint> bandHigh = _band(AttemptChartTuning.bandHigh);

  List<ChartPoint> _band(double p) =>
      _points(stats.rollingPercentile(ChartSeries.band.window, p), ChartSeries.band.minCount);

  List<ChartPoint> _points(List<double> values, int minCount) =>
      [for (var j = minCount - 1; j < values.length; j++) (x: timedXs[j], ms: values[j])];

  /// The latest value of [series] (the band's is its high edge), null
  /// before the series starts.
  double? latest(ChartSeries series) {
    final points = series == ChartSeries.band ? bandHigh : averages[series]!;
    return points.isEmpty ? null : points.last.ms;
  }

  /// The attempt the TOP SPEED star sits on: of the timed attempts TOP SPEED
  /// is taken over, the one nearest to it (the latest on a tie).
  late final int? topSpeedX = () {
    final top = stats.topSpeedMs;
    if (top == null) return null;
    final timed = stats.timed;
    var nearest = timed.length - 1;
    for (var j = math.max(0, timed.length - StatsTuning.topSpeedWindow); j < timed.length; j++) {
      if ((timed[j] - top).abs() <= (timed[nearest] - top).abs()) nearest = j;
    }
    return timedXs[nearest];
  }();

  /// The ms axis around every dot, null when every attempt is a miss.
  late final ChartAxis? axis = () {
    final times = [for (final a in attempts) if (!a.miss) a.ms];
    return times.isEmpty ? null : ChartAxis.fit(times.reduce(math.min), times.reduce(math.max));
  }();

  _AttemptChartGeometry? _geometry;

  _AttemptChartGeometry _geometryFor(Size size, _ChartText text) {
    final cached = _geometry;
    if (cached != null && cached.size == size && cached.text == text) return cached;
    return _geometry = _AttemptChartGeometry(this, size, text);
  }
}

/// The ms axis of an [AttemptChart]: [lo] at the bottom of the plot, [hi] at
/// its top, and a labelled gridline every [step] above [lo].
class ChartAxis {
  const ChartAxis(this.lo, this.hi, this.step);

  /// The axis for times from [minMs] to [maxMs] (see
  /// [AttemptChartTuning.axisSteps]).
  factory ChartAxis.fit(double minMs, double maxMs) {
    ChartAxis around(int step) => ChartAxis(
          math.max(0, ((minMs - AttemptChartTuning.axisPadBelowMs) / step).floor() * step),
          ((maxMs + AttemptChartTuning.axisPadAboveMs) / step).ceil() * step,
          step,
        );
    const steps = AttemptChartTuning.axisSteps;
    var axis = around(steps.first);
    for (var i = 1; axis.ticks.length > AttemptChartTuning.maxGridLines; i++) {
      axis = around(i < steps.length ? steps[i] : axis.step * 2);
    }
    return axis;
  }

  final int lo;
  final int hi;
  final int step;

  /// The labelled gridlines' values, bottom up.
  List<int> get ticks => [for (var v = lo + step; v <= hi; v += step) v];
}

/// Every attempt as a dot in ms, a ▽ for each "don't know", the percentile
/// band, the rolling averages, TOP SPEED as a dashed line and a star, and a
/// ring on the latest attempt, over ms gridlines and an attempts axis (spec
/// phone 8).
class AttemptChart extends StatelessWidget {
  const AttemptChart({
    super.key,
    required this.data,
    required this.visible,
    required this.attemptsLabel,
    required this.topSpeedLabel,
  });

  final AttemptChartData data;
  final Set<ChartSeries> visible;

  /// The x axis caption, and the word before the time on the TOP SPEED line.
  final String attemptsLabel;
  final String topSpeedLabel;

  @override
  Widget build(BuildContext context) {
    final text = _ChartText(MediaQuery.textScalerOf(context), attemptsLabel, topSpeedLabel);
    return SizedBox(
      height: ChartStyle.plotHeight + text.topMargin + text.bottomMargin,
      child: RepaintBoundary(child: CustomPaint(painter: _AttemptChartPainter(data, visible, text))),
    );
  }
}

/// The attempt chart's label type and words; the label rows around the plot
/// are sized from it.
@immutable
class _ChartText {
  const _ChartText(this.scaler, this.attempts, this.topSpeed);

  final TextScaler scaler;
  final String attempts;
  final String topSpeed;

  double get lineHeight => scaler.scale(ChartStyle.labelFont);

  /// The top row (the "ms" caption and the ▽ markers), then half a label so
  /// the top gridline's label clears it.
  double get topMargin => lineHeight * 1.5 + ChartStyle.plotTopGap;

  double get bottomMargin => lineHeight + ChartStyle.xLabelGap;

  TextPainter label(String text, {Color color = Palette.ink}) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: ChartStyle.labelFont, height: 1, color: color),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

  @override
  bool operator ==(Object other) =>
      other is _ChartText && other.scaler == scaler && other.attempts == attempts && other.topSpeed == topSpeed;

  @override
  int get hashCode => Object.hash(scaler, attempts, topSpeed);
}

/// An [AttemptChart]'s marks for one size, built once and replayed on every
/// paint.
class _AttemptChartGeometry {
  _AttemptChartGeometry(AttemptChartData data, this.size, this.text) {
    final attempts = data.attempts;
    final axis = data.axis;
    final ticks = axis?.ticks ?? const <int>[];
    final unit = text.label('ms');
    final tickLabels = [for (final v in ticks) text.label('$v')];
    final labelWidth = tickLabels.fold(unit.width, (w, l) => math.max(w, l.width));
    final plot = Rect.fromLTRB(labelWidth + ChartStyle.tickLabelGap, text.topMargin,
        size.width - ChartStyle.plotRightPad, size.height - text.bottomMargin);
    final n = attempts.length;
    final markerY = text.lineHeight / 2;
    double x(int i) => n <= 1 ? plot.left : plot.left + plot.width * i / (n - 1);
    double y(double ms) => plot.top + (axis!.hi - ms) / (axis.hi - axis.lo) * plot.height;
    Offset at(ChartPoint p) => Offset(x(p.x), y(p.ms));

    final labelRight = plot.left - ChartStyle.tickLabelGap;
    labels.add((unit, Offset(labelRight - unit.width, 0)));
    for (final (i, v) in ticks.indexed) {
      final ty = y(v.toDouble());
      grid
        ..moveTo(plot.left, ty)
        ..lineTo(plot.right, ty);
      labels.add((tickLabels[i], Offset(labelRight - tickLabels[i].width, ty - tickLabels[i].height / 2)));
    }
    final axisY = size.height - text.lineHeight;
    final caption = text.label(text.attempts);
    labels
      ..add((text.label('1'), Offset(plot.left, axisY)))
      ..add((caption, Offset(plot.center.dx - caption.width / 2, axisY)));
    if (n > 1) {
      final last = text.label('$n');
      labels.add((last, Offset(plot.right - last.width, axisY)));
    }

    if (data.bandHigh.isNotEmpty) {
      _polyline(band, data.bandHigh.map(at));
      for (final p in data.bandLow.reversed) {
        band.lineTo(x(p.x), y(p.ms));
      }
      band.close();
      _polyline(bandEdges, data.bandHigh.map(at));
      _polyline(bandEdges, data.bandLow.map(at));
    }
    for (final series in ChartSeries.averages) {
      averages[series] = _polyline(Path(), data.averages[series]!.map(at));
    }

    const marker = ChartStyle.missMarker;
    for (final (i, a) in attempts.indexed) {
      if (a.miss) {
        misses
          ..moveTo(x(i) - marker.width / 2, markerY - marker.height / 2)
          ..relativeLineTo(marker.width, 0)
          ..relativeLineTo(-marker.width / 2, marker.height)
          ..close();
      } else {
        dots.addOval(Rect.fromCircle(center: Offset(x(i), y(a.ms)), radius: ChartStyle.attemptDotRadius));
      }
    }
    if (n > 0) latest = Offset(x(n - 1), attempts.last.miss ? markerY : y(attempts.last.ms));

    final top = data.stats.topSpeedMs;
    if (top != null) {
      final topY = y(top);
      for (var dx = plot.left; dx < plot.right; dx += ChartStyle.topSpeedDash * 2) {
        topSpeedLine
          ..moveTo(dx, topY)
          ..lineTo(math.min(dx + ChartStyle.topSpeedDash, plot.right), topY);
      }
      final starAt = Offset(x(data.topSpeedX!), topY);
      star = _star(starAt);
      final label = text.label('${text.topSpeed} ${formatChipSeconds(top)}', color: ChartStyle.topSpeedText);
      final onRight = starAt.dx <= plot.center.dx;
      final lx = onRight ? starAt.dx + ChartStyle.starLabelGap : starAt.dx - ChartStyle.starLabelGap - label.width;
      final below = topY + ChartStyle.starLabelDrop;
      final ly = below + label.height <= plot.bottom ? below : topY - ChartStyle.starLabelDrop - label.height;
      topSpeedLabel = (label, Offset(lx.clamp(0, math.max(0, size.width - label.width)), ly));
    }
  }

  final Size size;
  final _ChartText text;

  final grid = Path();
  final labels = <(TextPainter, Offset)>[];
  final band = Path();
  final bandEdges = Path();
  final averages = <ChartSeries, Path>{};
  final dots = Path();
  final misses = Path();
  final topSpeedLine = Path();
  Path? star;
  (TextPainter, Offset)? topSpeedLabel;
  Offset? latest;

  static Path _polyline(Path path, Iterable<Offset> points) {
    var first = true;
    for (final p in points) {
      first ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      first = false;
    }
    return path;
  }

  static Path _star(Offset c) => _polyline(Path(), [
        for (var i = 0; i < 10; i++)
          c +
              Offset.fromDirection(-math.pi / 2 + i * math.pi / 5,
                  i.isEven ? ChartStyle.starRadius : ChartStyle.starRadius * ChartStyle.starInnerRatio),
      ])
        ..close();
}

class _AttemptChartPainter extends CustomPainter {
  _AttemptChartPainter(this.data, this.visible, this.text);
  final AttemptChartData data;
  final Set<ChartSeries> visible;
  final _ChartText text;

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.attempts.isEmpty) return;
    final g = data._geometryFor(size, text);
    canvas.drawPath(g.grid, _stroke(ChartStyle.grid, ChartStyle.gridStroke));
    for (final (label, at) in g.labels) {
      label.paint(canvas, at);
    }
    if (visible.contains(ChartSeries.band)) {
      canvas
        ..drawPath(g.band, _fill(ChartStyle.bandFill))
        ..drawPath(g.bandEdges, _stroke(ChartStyle.bandEdge, ChartStyle.bandEdgeStroke));
    }
    canvas
      ..drawPath(g.topSpeedLine, _stroke(ChartStyle.topSpeedLine, ChartStyle.topSpeedStroke)..strokeCap = StrokeCap.butt)
      ..drawPath(g.dots, _fill(Palette.sea))
      ..drawPath(g.dots, _stroke(Palette.paper, ChartStyle.attemptDotRim))
      ..drawPath(g.misses, _fill(Palette.paper))
      ..drawPath(g.misses, _stroke(Palette.ink, ChartStyle.missMarkerStroke));
    if (visible.contains(ChartSeries.longAverage)) {
      final line = g.averages[ChartSeries.longAverage]!;
      canvas
        ..drawPath(line, _stroke(Palette.paper, ChartStyle.longAverageHalo))
        ..drawPath(line, _stroke(ChartStyle.longAverage, ChartStyle.longAverageStroke));
    }
    if (visible.contains(ChartSeries.midAverage)) {
      canvas.drawPath(g.averages[ChartSeries.midAverage]!, _stroke(ChartStyle.midAverage, ChartStyle.midAverageStroke));
    }
    if (visible.contains(ChartSeries.shortAverage)) {
      canvas.drawPath(
          g.averages[ChartSeries.shortAverage]!, _stroke(ChartStyle.shortAverage, ChartStyle.shortAverageStroke));
    }
    final star = g.star;
    if (star != null) {
      canvas
        ..drawPath(star, _fill(Palette.sun))
        ..drawPath(star, _stroke(Palette.ink, ChartStyle.starStroke));
    }
    final topSpeedLabel = g.topSpeedLabel;
    if (topSpeedLabel != null) topSpeedLabel.$1.paint(canvas, topSpeedLabel.$2);
    final latest = g.latest;
    if (latest != null) {
      canvas.drawCircle(latest, ChartStyle.latestRingRadius, _stroke(ChartStyle.latestRing, ChartStyle.latestRingStroke));
    }
  }

  @override
  bool shouldRepaint(_AttemptChartPainter old) =>
      !identical(old.data, data) || !setEquals(old.visible, visible) || old.text != text;
}

/// A small line sampling FSRS retrievability over time (the forgetting curve).
class ForgettingCurve extends StatelessWidget {
  const ForgettingCurve({super.key, required this.samples, required this.retentionGoal});

  /// Retrievability (0..1) sampled at even time steps.
  final List<double> samples;
  final double retentionGoal;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ForgettingCurvePainter(samples, retentionGoal));
}

class _ForgettingCurvePainter extends CustomPainter {
  _ForgettingCurvePainter(this.samples, this.retentionGoal);
  final List<double> samples;
  final double retentionGoal;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    double x(int i) => size.width * i / (samples.length - 1);
    double y(double v) => size.height * (1 - v.clamp(0, 1));

    final goalY = y(retentionGoal);
    canvas.drawLine(
      Offset(0, goalY),
      Offset(size.width, goalY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.desk,
    );

    final path = Path()..moveTo(x(0), y(samples[0]));
    for (var i = 1; i < samples.length; i++) {
      path.lineTo(x(i), y(samples[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..color = Palette.seaDeep,
    );
  }

  @override
  bool shouldRepaint(_ForgettingCurvePainter old) =>
      !listEquals(old.samples, samples) || old.retentionGoal != retentionGoal;
}

/// One series of a [DailyChart]: a value per day (NaN for none), drawn as a
/// line, a dashed line or bars.
class DailySeries {
  const DailySeries(this.label, this.values, this.color, {this.bars = false, this.dashed = false});

  final String label;
  final List<double> values;
  final Color color;
  final bool bars;
  final bool dashed;

  /// The largest value, 0 for none.
  double get peak => values.where((v) => v.isFinite).fold(0, math.max);
}

/// Values per day on one scale from zero to [top] (by default the largest
/// value), for the debug Simulation.
class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.series, this.top});

  final List<DailySeries> series;
  final double? top;

  /// The value at the chart's top edge.
  double get scaleTop => top ?? math.max(1, series.fold(0.0, (m, s) => math.max(m, s.peak)));

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DailyChartPainter(series, scaleTop));
}

class _DailyChartPainter extends CustomPainter {
  _DailyChartPainter(this.series, this.top);
  final List<DailySeries> series;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final days = series.fold(0, (n, s) => math.max(n, s.values.length));
    if (days == 0) return;
    final step = size.width / days;
    double x(int i) => step * (i + 0.5);
    double y(double v) => size.height * (1 - (v / top).clamp(0, 1));
    final grid = Paint()
      ..strokeWidth = ChartStyle.gridStroke
      ..color = Palette.desk;
    canvas
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), grid)
      ..drawLine(Offset.zero, Offset(size.width, 0), grid);

    for (final s in series.where((s) => s.bars)) {
      final paint = Paint()..color = s.color;
      final half = step * ChartStyle.dailyBarShare / 2;
      for (final (i, v) in s.values.indexed) {
        if (v.isFinite && v > 0) canvas.drawRect(Rect.fromLTRB(x(i) - half, y(v), x(i) + half, size.height), paint);
      }
    }
    for (final s in series.where((s) => !s.bars)) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..color = s.color;
      Offset? last;
      for (final (i, v) in s.values.indexed) {
        final p = v.isFinite ? Offset(x(i), y(v)) : null;
        if (last != null && p != null) s.dashed ? _dash(canvas, last, p, paint) : canvas.drawLine(last, p, paint);
        last = p;
      }
    }
  }

  static void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    for (var t = 0.0; t < length; t += ChartStyle.dash * 2) {
      canvas.drawLine(Offset.lerp(a, b, t / length)!, Offset.lerp(a, b, math.min(1, (t + ChartStyle.dash) / length))!, paint);
    }
  }

  @override
  bool shouldRepaint(_DailyChartPainter old) => old.series != series || old.top != top;
}
