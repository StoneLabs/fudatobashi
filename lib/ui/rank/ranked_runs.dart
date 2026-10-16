import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../history/history_widgets.dart';

/// The rating after each ranked run as a line, with a dashed line at each
/// class threshold in reach; run [mine], if any, is a pink diamond.
class RatingChart extends StatelessWidget {
  const RatingChart(this.ratings, {super.key, this.mine});
  final List<double> ratings;
  final int? mine;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: RunTabsStyle.ratingChartHeight,
        child: CustomPaint(
          size: Size.infinite,
          painter: _RatingChartPainter(ratings, mine, S.of(context).className, MediaQuery.textScalerOf(context)),
        ),
      );
}

/// The latest ranked runs, newest first: the date, the scored time, what
/// the run played like, the rating after it and its change. Run [highlight]
/// is tinted; a row opens its run with [onOpen].
class RankedRunsTable extends StatelessWidget {
  const RankedRunsTable(this.runs, {super.key, this.highlight, this.onOpen});

  /// Oldest first, as `RunHistory.rankedHistory` gives them.
  final List<(PastRun, RunRating)> runs;
  final int? highlight;
  final ValueChanged<PastRun>? onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    TableRow row(PastRun run, RunRating rating) {
      final style = run.id == highlight ? RunTabsStyle.lineStyle : RunTabsStyle.rowStyle;
      final change = rating.before == null ? '' : ratingChangeText(rating.after - rating.before!);
      final tag = rating.before == null ? s.runTagPlaced : null;
      final cells = [
        Padding(
          padding: RunTabsStyle.tableCellPadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.shortDate(run.startedAt), style: style),
            if (tag != null) Text(tag, style: RunTabsStyle.noteStyle),
          ]),
        ),
        for (final v in [runTimeText(s, run), '${rating.performance.round()}', '${rating.after.round()}'])
          _cell(v, style),
        _cell(change, style.copyWith(color: _changeColor(rating))),
      ];
      return TableRow(
        decoration: BoxDecoration(
          color: run.id == highlight ? Palette.sunSoft : null,
          border: const Border(bottom: BorderSide(color: RunTabsStyle.rule)),
        ),
        children: [
          for (final c in cells)
            onOpen == null
                ? c
                : TableRowInkWell(onTap: () => onOpen!(run), child: c),
        ],
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(RunTabsStyle.runColumnFlex)},
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: Strokes.label))),
          children: [
            for (final (i, h) in [s.runColRun, s.runColScored, s.runColPlayedLike, s.runColRating, s.runColChange].indexed)
              Padding(
                padding: RunTabsStyle.tableCellPadding,
                child: Text(h.toUpperCase(), textAlign: i > 0 ? TextAlign.right : TextAlign.left, style: RunTabsStyle.headStyle),
              ),
          ],
        ),
        for (final (run, rating) in runs.reversed.take(RunRatingTuning.tableRuns)) row(run, rating),
      ],
    );
  }

  static Color? _changeColor(RunRating r) {
    if (r.before == null) return null;
    final change = (r.after - r.before!).round();
    return change > 0 ? HistoryRunStyle.ahead : change < 0 ? HistoryRunStyle.behind : null;
  }

  static Widget _cell(String text, TextStyle style) => Padding(
        padding: RunTabsStyle.tableCellPadding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(text, maxLines: 1, style: style),
        ),
      );
}

class _RatingChartPainter extends CustomPainter {
  _RatingChartPainter(this.ratings, this.mine, this.name, this.scaler);
  final List<double> ratings;
  final int? mine;
  final String Function(RankBand band) name;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.length < 2) return;
    var lo = ratings.reduce(math.min), hi = ratings.reduce(math.max);
    if (Rating.bandOf(lo).minRating case final m when m.isFinite) lo = m;
    if (Rating.nextBand(hi) case final next?) hi = next.minRating;
    final pad = math.max(1.0, hi - lo) * RunTabsStyle.ratingChartPad;
    lo -= pad;
    hi += pad;
    const inset = RunTabsStyle.ratingPointInset;
    Offset at(int i, double r) => Offset(
          inset + (size.width - 2 * inset) * i / (ratings.length - 1),
          size.height * (hi - r) / (hi - lo),
        );
    final classLine = Paint()
      ..color = HistoryRunStyle.behind
      ..strokeWidth = Strokes.hairline;
    for (final band in Rating.bands) {
      final r = band.minRating;
      if (!r.isFinite || r < lo || r > hi) continue;
      final y = at(0, r).dy;
      for (var x = 0.0; x < size.width; x += Strokes.dash[0] + Strokes.dash[1]) {
        canvas.drawLine(Offset(x, y), Offset(math.min(size.width, x + Strokes.dash[0]), y), classLine);
      }
      final label = TextPainter(
        text: TextSpan(text: '${name(band)} ${r.round()}', style: RunTabsStyle.chartLabelStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height));
    }
    final line = Path()..moveTo(at(0, ratings[0]).dx, at(0, ratings[0]).dy);
    for (var i = 1; i < ratings.length; i++) {
      line.lineTo(at(i, ratings[i]).dx, at(i, ratings[i]).dy);
    }
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = RunTabsStyle.ratingLineStroke);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.hairline;
    for (final (i, r) in ratings.indexed) {
      final p = at(i, r);
      if (i == mine) {
        const d = RunTabsStyle.ratingMineMark;
        final diamond = Path()
          ..moveTo(p.dx, p.dy - d)
          ..lineTo(p.dx + d, p.dy)
          ..lineTo(p.dx, p.dy + d)
          ..lineTo(p.dx - d, p.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = Palette.pink);
        canvas.drawPath(diamond, ring);
      } else {
        canvas.drawCircle(p, RunTabsStyle.ratingPoint, Paint()..color = Palette.paper);
        canvas.drawCircle(p, RunTabsStyle.ratingPoint, ring);
      }
    }
  }

  @override
  bool shouldRepaint(_RatingChartPainter old) => old.ratings != ratings || old.mine != mine || old.scaler != scaler;
}
