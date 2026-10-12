import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_score.dart';
import '../ankiren/ankiren_band.dart';
import 'debug_common.dart';

/// One line per level: total points over the time left when the player was
/// ready, with every card found by its first tap at the chosen card time. A
/// level's line ends at its memorise time.
class AnkirenTimeLeftGraph extends StatefulWidget {
  const AnkirenTimeLeftGraph({super.key});

  @override
  State<AnkirenTimeLeftGraph> createState() => _AnkirenTimeLeftGraphState();
}

class _AnkirenTimeLeftGraphState extends State<AnkirenTimeLeftGraph> {
  double _responseMs = AnkirenToolsTuning.responseStart.inMilliseconds.toDouble();

  @override
  Widget build(BuildContext context) {
    final step = AnkirenToolsTuning.timeLeftStep.inSeconds;
    final lines = [
      for (var l = 0; l <= AnkirenLevels.top; l++)
        _Line(l, [
          for (var s = 0; s <= AnkirenLevels.of(l).memorise.inSeconds; s += step)
            Offset(
              s.toDouble(),
              AnkirenScore.firstTryTotal(
                AnkirenSetup.forLevel(l),
                responseMs: _responseMs,
                timeLeft: Duration(seconds: s),
              ).toDouble(),
            ),
        ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugSlider(
          label: 'card time ${(_responseMs / 1000).toStringAsFixed(1)} s',
          value: _responseMs,
          min: AnkirenToolsTuning.responseMin.inMilliseconds.toDouble(),
          max: AnkirenToolsTuning.responseMax.inMilliseconds.toDouble(),
          divisions: _responseDivisions,
          onChanged: (v) => setState(() => _responseMs = v),
        ),
        _LinesChart(
          lines: lines,
          xMax: AnkirenLevels.all.map((l) => l.memorise.inSeconds).reduce(math.max).toDouble(),
          xTick: AnkirenToolsTuning.timeLeftTick.inSeconds.toDouble(),
          xLabel: (s) => formatMinutes(Duration(seconds: s.round())),
        ),
        Text('x: time left when ready · y: points · line: level', style: debugMono),
      ],
    );
  }
}

/// One line per level: total points over the card time, when the player was
/// ready with a set time left (levels with less memorise time have no line).
class AnkirenCardTimeGraph extends StatefulWidget {
  const AnkirenCardTimeGraph({super.key});

  @override
  State<AnkirenCardTimeGraph> createState() => _AnkirenCardTimeGraphState();
}

class _AnkirenCardTimeGraphState extends State<AnkirenCardTimeGraph> {
  double _timeLeft = 0;

  @override
  Widget build(BuildContext context) {
    final timeLeft = Duration(seconds: _timeLeft.round());
    final lines = [
      for (var l = 0; l <= AnkirenLevels.top; l++)
        if (timeLeft <= AnkirenLevels.of(l).memorise)
          _Line(l, [
            for (
              var ms = AnkirenToolsTuning.responseMin.inMilliseconds;
              ms <= AnkirenToolsTuning.responseMax.inMilliseconds;
              ms += AnkirenToolsTuning.curveStepMs
            )
              Offset(
                ms / 1000,
                AnkirenScore.firstTryTotal(
                  AnkirenSetup.forLevel(l),
                  responseMs: ms.toDouble(),
                  timeLeft: timeLeft,
                ).toDouble(),
              ),
          ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugSlider(
          label: 'time left ${formatMinutes(timeLeft)}',
          value: _timeLeft,
          min: 0,
          max: AnkirenLevels.all.map((l) => l.memorise.inSeconds).reduce(math.max).toDouble(),
          divisions:
              AnkirenLevels.all.map((l) => l.memorise.inSeconds).reduce(math.max) ~/
              AnkirenToolsTuning.timeLeftStep.inSeconds,
          onChanged: (v) => setState(() => _timeLeft = v),
        ),
        _LinesChart(
          lines: lines,
          xMax: AnkirenToolsTuning.responseMax.inSeconds.toDouble(),
          xTick: AnkirenToolsTuning.responseTick.inSeconds.toDouble(),
          xLabel: (s) => '${s.round()} s',
        ),
        Text('x: card time · y: points · line: level', style: debugMono),
      ],
    );
  }
}

int get _responseDivisions =>
    (AnkirenToolsTuning.responseMax - AnkirenToolsTuning.responseMin).inMilliseconds ~/
    AnkirenToolsTuning.responseStep.inMilliseconds;

Color _levelColor(int level) => HSLColor.fromAHSL(
  1,
  AnkirenToolsStyle.hueStart + (AnkirenToolsStyle.hueEnd - AnkirenToolsStyle.hueStart) * level / AnkirenLevels.top,
  AnkirenToolsStyle.lineSaturation,
  AnkirenToolsStyle.lineLightness,
).toColor();

class _Line {
  const _Line(this.level, this.points);

  final int level;
  final List<Offset> points;
}

class _LinesChart extends StatelessWidget {
  const _LinesChart({required this.lines, required this.xMax, required this.xTick, required this.xLabel});

  final List<_Line> lines;
  final double xMax;
  final double xTick;
  final String Function(double) xLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AnkirenToolsStyle.graphHeight,
    child: CustomPaint(painter: _LinesPainter(lines, xMax, xTick, xLabel)),
  );
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.lines, this.xMax, this.xTick, this.xLabel);

  final List<_Line> lines;
  final double xMax;
  final double xTick;
  final String Function(double) xLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = AnkirenToolsStyle.graphMargin.deflateRect(Offset.zero & size);
    final top = lines.fold(0.0, (m, l) => l.points.fold(m, (m, p) => math.max(m, p.dy)));
    final yMax = top == 0 ? 1.0 : top;
    Offset at(Offset p) => Offset(plot.left + plot.width * p.dx / xMax, plot.bottom - plot.height * p.dy / yMax);
    final grid = Paint()..color = Palette.desk;
    const label = TextStyle(fontSize: AnkirenToolsStyle.axisFont, color: Palette.mute, fontFamily: 'monospace');

    void text(String s, Offset anchor, {required Alignment align, TextStyle style = label}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, anchor - Offset(tp.width * (align.x + 1) / 2, tp.height * (align.y + 1) / 2));
    }

    for (var i = 0; i <= AnkirenToolsTuning.yDivisions; i++) {
      final y = plot.bottom - plot.height * i / AnkirenToolsTuning.yDivisions;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      text(
        '${(yMax * i / AnkirenToolsTuning.yDivisions).round()}',
        Offset(plot.left - 4, y),
        align: Alignment.centerRight,
      );
    }
    for (var x = 0.0; x <= xMax; x += xTick) {
      final px = at(Offset(x, 0)).dx;
      canvas.drawLine(Offset(px, plot.top), Offset(px, plot.bottom), grid);
      text(xLabel(x), Offset(px, plot.bottom + 2), align: Alignment.topCenter);
    }

    for (final line in lines) {
      final color = _levelColor(line.level);
      final path = Path();
      for (final (i, p) in line.points.indexed) {
        final o = at(p);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AnkirenToolsStyle.lineStroke
          ..color = color,
      );
      text(
        '${line.level}',
        at(line.points.last) + const Offset(3, 0),
        align: Alignment.centerLeft,
        style: label.copyWith(color: color, fontWeight: Weights.black),
      );
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => true;
}
