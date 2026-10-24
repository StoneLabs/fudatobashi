import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/run_review.dart';
import '../play/time_format.dart';

/// Time into a run, card by card: x = cards, y = time with 0 at the top
/// down to [bottomMs]. The run's line starts in the top-left corner; a
/// dashed line runs straight to where it ended (even pace), with the gap
/// shaded pink where the run was behind it and green where ahead. Earlier
/// runs ([references]) are faint lines; an exam's [tobi] a blue one. The
/// bottom and the run's end are labelled with their times unless
/// [showTotal] is false.
class RunTimeGraph extends StatelessWidget {
  const RunTimeGraph({
    super.key,
    required this.run,
    required this.bottomMs,
    this.references = const [],
    this.tobi,
    this.showTotal = true,
  });

  final RunTimeline run;
  final double bottomMs;
  final List<RunTimeline> references;
  final RunTimeline? tobi;
  final bool showTotal;

  /// Takes the height it is given, at least
  /// [RunChartStyle.timeGraphMinHeight].
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RunChartStyle.timeGraphMinHeight),
        child: CustomPaint(size: Size.infinite, painter: _TimeGraphPainter(this, MediaQuery.textScalerOf(context))),
      );
}

class _TimeGraphPainter extends CustomPainter {
  _TimeGraphPainter(this.graph, this.scaler);
  final RunTimeGraph graph;
  final TextScaler scaler;

  /// A label in [color], or with [halo] the paper outline drawn under it.
  TextPainter _label(String text, {Color color = Palette.ink, bool halo = false}) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: Fonts.ui,
              fontSize: RunChartStyle.labelFont,
              fontWeight: Weights.black,
              color: halo ? null : color,
              foreground: halo
                  ? (Paint()
                    ..color = Palette.paper
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = RunChartStyle.labelHalo)
                  : null,
            )),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final run = graph.run;
    final cards = math.max(1, [run.cards, for (final r in graph.references) r.cards].reduce(math.max));
    final bottom = math.max(1.0, graph.bottomMs);
    final yLabel = _label(formatMinutes(Duration(milliseconds: (graph.showTotal ? bottom : bottom - 1).round())));
    final left = yLabel.width + RunChartStyle.labelGap;
    final top = _label('0').height + RunChartStyle.labelGap;
    final plot = Rect.fromLTRB(left, top, size.width - RunChartStyle.plotRightPad, size.height - RunChartStyle.plotBottomPad);
    Offset at(int card, double ms) =>
        Offset(plot.left + plot.width * card / cards, plot.top + plot.height * ms / bottom);

    final grid = Paint()
      ..color = ChartStyle.grid
      ..strokeWidth = 1;
    final xStep = RunChartStyle.cardSteps.firstWhere((s) => cards / s <= RunChartStyle.maxXTicks, orElse: () => 25);
    for (var c = 0; c <= cards; c += xStep) {
      final x = at(c, 0).dx;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      final l = _label('$c');
      l.paint(canvas, Offset(x - l.width / 2, 0));
    }
    final yStep = RunChartStyle.timeStepsMs.firstWhere((s) => bottom / s <= RunChartStyle.maxYTicks,
        orElse: () => RunChartStyle.timeStepsMs.last);
    for (var ms = 0; ms < bottom - (graph.showTotal ? yStep / 3 : 0); ms += yStep) {
      final y = at(0, ms.toDouble()).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final l = _label(formatMinutes(Duration(milliseconds: ms)));
      l.paint(canvas, Offset(left - RunChartStyle.labelGap - l.width, y - l.height / 2));
    }
    // The bottom: a pink dashed rule with its time.
    final bottomPaint = Paint()
      ..color = HistoryRunStyle.behind
      ..strokeWidth = Strokes.hairline;
    _dashed(canvas, Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), bottomPaint);
    if (graph.showTotal) {
      final bl = _label(formatMinutes(Duration(milliseconds: bottom.round())), color: HistoryRunStyle.behind);
      bl.paint(canvas, Offset(left - RunChartStyle.labelGap - bl.width, plot.bottom - bl.height / 2));
    }
    canvas.drawLine(plot.topLeft, plot.bottomLeft, Paint()..strokeWidth = Strokes.label);
    canvas.drawLine(plot.topLeft, plot.topRight, Paint()..strokeWidth = Strokes.label);

    canvas.save();
    canvas.clipRect(plot.inflate(RunChartStyle.endMark).intersect(Offset.zero & size));
    for (final r in graph.references) {
      _line(canvas, r, at, Paint()
        ..color = RunChartStyle.reference
        ..strokeWidth = RunChartStyle.referenceStroke
        ..style = PaintingStyle.stroke);
    }

    // Behind / ahead of even pace, between the line and the dashed one.
    for (var i = 0; i < run.cards; i++) {
      final gapA = run.ms[i] - run.evenAt(i), gapB = run.ms[i + 1] - run.evenAt(i + 1);
      if (gapA == 0 && gapB == 0) continue;
      final path = Path()
        ..moveTo(at(i, run.ms[i]).dx, at(i, run.ms[i]).dy)
        ..lineTo(at(i + 1, run.ms[i + 1]).dx, at(i + 1, run.ms[i + 1]).dy)
        ..lineTo(at(i + 1, run.evenAt(i + 1)).dx, at(i + 1, run.evenAt(i + 1)).dy)
        ..lineTo(at(i, run.evenAt(i)).dx, at(i, run.evenAt(i)).dy)
        ..close();
      final behind = gapA + gapB > 0;
      canvas.drawPath(path, Paint()..color = (behind ? Palette.pinkSoft : Palette.landSoft));
    }
    final end = at(run.cards, run.endMs);
    _dashed(canvas, plot.topLeft, end, Paint()
      ..color = Palette.ink
      ..strokeWidth = Strokes.hairline);
    if (graph.tobi case final tobi?) {
      _line(canvas, tobi, at, Paint()
        ..color = Palette.seaDeep
        ..strokeWidth = RunChartStyle.lineStroke
        ..style = PaintingStyle.stroke);
    }
    _line(canvas, run, at, Paint()
      ..color = Palette.ink
      ..strokeWidth = RunChartStyle.lineStroke
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round);
    for (final c in run.missCards) {
      final p = at(c, run.ms[c]);
      canvas.drawCircle(p, RunChartStyle.missDot, Paint()..color = Palette.pink);
      canvas.drawCircle(p, RunChartStyle.missDot, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
    final diamond = Path()
      ..moveTo(end.dx, end.dy - RunChartStyle.endMark)
      ..lineTo(end.dx + RunChartStyle.endMark, end.dy)
      ..lineTo(end.dx, end.dy + RunChartStyle.endMark)
      ..lineTo(end.dx - RunChartStyle.endMark, end.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = Palette.pink);
    canvas.drawPath(diamond, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.hairline);
    canvas.restore();
    if (!graph.showTotal) return;
    final text = formatTenths(Duration(milliseconds: run.endMs.round()));
    final halo = _label(text, halo: true);
    final endLabel = _label(text);
    final where = Offset(end.dx - RunChartStyle.endMark - RunChartStyle.endLabelGap - endLabel.width,
        end.dy - RunChartStyle.endMark - endLabel.height / 2);
    halo.paint(canvas, where);
    endLabel.paint(canvas, where);
  }

  void _line(Canvas canvas, RunTimeline t, Offset Function(int, double) at, Paint paint) {
    final path = Path()..moveTo(at(0, 0).dx, at(0, 0).dy);
    for (var i = 1; i <= t.cards; i++) {
      final p = at(i, t.ms[i]);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    if (length == 0) return;
    final dir = (b - a) / length;
    const dash = Strokes.dash;
    for (var d = 0.0; d < length; d += dash[0] + dash[1]) {
      canvas.drawLine(a + dir * d, a + dir * math.min(length, d + dash[0]), paint);
    }
  }

  @override
  bool shouldRepaint(_TimeGraphPainter old) => old.graph != graph || old.scaler != scaler;
}

/// One bar of a [BarChart].
class ChartBar {
  const ChartBar(this.value, {this.color = Palette.ink, this.label});
  final double value;
  final Color color;

  /// Written over the bar.
  final String? label;
}

/// Bars over a value axis from 0, with a dashed [guide] line across (a goal
/// or an average) and labels under some bars ([xLabels], by index).
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.bars,
    this.guide,
    this.guideColor = Palette.sun,
    this.xLabels = const {},
    this.height = RunChartStyle.barChartHeight,
    this.format = _seconds,
    this.steps = RunChartStyle.barStepsMs,
  });

  final List<ChartBar> bars;
  final double? guide;
  final Color guideColor;
  final Map<int, String> xLabels;
  final double height;

  /// Writes an axis value.
  final String Function(double value) format;

  /// Gridline steps to choose from, in [format]'s unit.
  final List<int> steps;

  static String _seconds(double ms) => formatSeconds(ms, 0);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(size: Size.infinite, painter: _BarPainter(this, MediaQuery.textScalerOf(context))),
      );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.chart, this.scaler);
  final BarChart chart;
  final TextScaler scaler;

  TextPainter _label(String text, [double size = RunChartStyle.labelFont]) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontFamily: Fonts.ui, fontSize: size, fontWeight: Weights.black, color: Palette.ink)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final bars = chart.bars;
    if (bars.isEmpty) return;
    final top = [for (final b in bars) b.value, chart.guide ?? 0].reduce(math.max);
    final step = chart.steps.firstWhere((s) => top / s <= RunChartStyle.maxYTicks, orElse: () => chart.steps.last);
    final hi = ((top / step).ceil() * step).toDouble();
    final widest = _label(chart.format(hi));
    final xRow = chart.xLabels.isEmpty ? 0.0 : _label('0').height + RunChartStyle.labelGap;
    final valueRow = bars.any((b) => b.label != null) ? _label('0', RunChartStyle.valueFont).height : 0.0;
    final plot = Rect.fromLTRB(
        widest.width + RunChartStyle.labelGap, RunChartStyle.labelGap + valueRow, size.width, size.height - xRow);
    double y(double v) => plot.bottom - plot.height * v / hi;
    final grid = Paint()
      ..color = ChartStyle.grid
      ..strokeWidth = 1;
    for (var v = step.toDouble(); v <= hi; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      final l = _label(chart.format(v));
      l.paint(canvas, Offset(plot.left - RunChartStyle.labelGap - l.width, y(v) - l.height / 2));
    }
    final slot = plot.width / bars.length;
    final gap = slot > RunChartStyle.wideBar ? slot * RunChartStyle.barGapShare : 1.0;
    for (final (i, b) in bars.indexed) {
      final rect = Rect.fromLTRB(plot.left + i * slot + gap / 2, y(b.value), plot.left + (i + 1) * slot - gap / 2, plot.bottom);
      canvas.drawRect(rect, Paint()..color = b.color);
      if (slot > RunChartStyle.wideBar) {
        canvas.drawRect(rect, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.hairline);
      }
      if (b.label case final text?) {
        final l = _label(text, RunChartStyle.valueFont);
        l.paint(canvas, Offset(rect.center.dx - l.width / 2, rect.top - l.height));
      }
      if (chart.xLabels[i] case final text?) {
        final l = _label(text);
        l.paint(canvas, Offset((rect.center.dx - l.width / 2).clamp(0, size.width - l.width), plot.bottom + RunChartStyle.labelGap));
      }
    }
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, Paint()..strokeWidth = Strokes.label);
    if (chart.guide case final g?) {
      final guide = Paint()
        ..color = chart.guideColor
        ..strokeWidth = RunChartStyle.guideStroke;
      final under = Paint()
        ..color = Palette.ink
        ..strokeWidth = RunChartStyle.guideStroke + 2;
      for (var x = plot.left; x < plot.right; x += Strokes.dash[0] + Strokes.dash[1]) {
        final a = Offset(x, y(g)), b = Offset(math.min(plot.right, x + Strokes.dash[0]), y(g));
        canvas.drawLine(a, b, under);
        canvas.drawLine(a, b, guide);
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.chart != chart || old.scaler != scaler;
}

/// A chart's key: each mark and what it means, wrapped.
class ChartLegend extends StatelessWidget {
  const ChartLegend(this.items, {super.key});
  final List<(Widget mark, String label)> items;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Gaps.small),
        child: Wrap(
          spacing: Gaps.section,
          runSpacing: Gaps.tight,
          children: [
            for (final (mark, label) in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  mark,
                  const SizedBox(width: Gaps.tight),
                  Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: RunChartStyle.labelFont)),
                ],
              ),
          ],
        ),
      );
}

/// A legend mark: a filled square, or a short line (dashed with [dashed]).
class LegendMark extends StatelessWidget {
  const LegendMark.box(this.color, {super.key})
      : line = false,
        dashed = false,
        background = null;
  const LegendMark.line(this.color, {super.key, this.dashed = false, this.background}) : line = true;

  final Color color;

  /// A fill behind a line mark.
  final Color? background;
  final bool line, dashed;

  @override
  Widget build(BuildContext context) => line
      ? SizedBox(
          width: RunChartStyle.legendLine,
          height: RunChartStyle.legendBox,
          child: DecoratedBox(
            decoration: BoxDecoration(color: background),
            child: CustomPaint(painter: _LegendLinePainter(color, dashed)),
          ),
        )
      : Container(
          width: RunChartStyle.legendBox,
          height: RunChartStyle.legendBox,
          decoration: BoxDecoration(color: color, border: Border.all(color: Palette.ink, width: 1)),
        );
}

class _LegendLinePainter extends CustomPainter {
  _LegendLinePainter(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = RunChartStyle.lineStroke;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (var x = 0.0; x < size.width; x += Strokes.fineDash[0] * 2 + Strokes.fineDash[1] * 2) {
      canvas.drawLine(Offset(x, y), Offset(math.min(size.width, x + Strokes.fineDash[0] * 2), y), paint);
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) => old.color != color || old.dashed != dashed;
}
