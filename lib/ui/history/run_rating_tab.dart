import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../play/time_format.dart';
import 'history_widgets.dart';
import 'run_xp_tab.dart';

/// The 100-card view's Rating and XP tab: how a ranked run moved the
/// rating and where it sits among the ranked runs (or why the exam and free
/// play don't move it), then the run's experience.
class RunRatingTab extends StatelessWidget {
  const RunRatingTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final rating = detail.rating;
    return RunTabList(children: [
      if (rating != null) ...[
        _RatingPanel(detail, rating),
        if (detail.run.forfeit) _Forfeit(detail.run),
        _RankedRuns(detail),
      ] else
        _NoRank(detail.run),
      XpPanel(detail.xp),
    ]);
  }
}

/// D24: the rating before and after, the sum that moved it, and the class
/// bar.
class _RatingPanel extends StatelessWidget {
  const _RatingPanel(this.detail, this.rating);
  final RunDetail detail;
  final RunRating rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final before = rating.before?.round(), after = rating.after.round(), played = rating.performance.round();
    final scored = runTimeText(detail.run);
    final ratedBefore = detail.rankedRuns.indexWhere((r) => r.$1.id == detail.run.id);
    final share = Rating.share(math.max(0, ratedBefore));
    return RunPanel(children: [
      TrackedLabel(s.rating, sub: s.sub?.rating),
      if (before == null) ...[
        RunBigValue('$after'),
        const SizedBox(height: Gaps.tight),
        Text('${s.runPlacementShout} ${s.runPlacementText(scored, played)}', style: RunTabsStyle.lineStyle),
      ] else ...[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Gaps.panel,
          children: [
            RunBigValue('$before → $after'),
            ResultBadge(
              ratingChangeText(after - before),
              color: after >= before ? Palette.land : Palette.pink,
            ),
          ],
        ),
        const SizedBox(height: Gaps.small),
        RunValueLine(s.runPlayedLike(scored), '$played'),
        RunValueLine(s.runShareOfWay, switch (share) {
          RatingModel.provisionalK => s.runShareHalf,
          RatingModel.establishedK => s.runShareQuarter,
          _ => '$share',
        }),
        RunValueLine('$before + $share × ($played − $before)', '$after'),
        if (share == RatingModel.provisionalK) HistoryCaption(s.runShareNote(RatingModel.provisionalSessions)),
      ],
      const SizedBox(height: Gaps.section),
      _ClassBar(rating.after, before: rating.before),
    ]);
  }
}

/// The class the rating is in, as a bar filling toward the next class,
/// with the rating before marked, and the points still to go.
class _ClassBar extends StatelessWidget {
  const _ClassBar(this.rating, {this.before});
  final double rating;
  final double? before;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final band = Rating.bandOf(rating), next = Rating.nextBand(rating);
    final lo = band.minRating.isFinite ? band.minRating : next!.minRating - RunRatingTuning.openSpan;
    final hi = next?.minRating ?? lo + RunRatingTuning.openSpan;
    double at(double r) => ((r - lo) / (hi - lo)).clamp(0.0, 1.0);
    final was = before;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: RunTabsStyle.classBarHeight,
        child: CustomPaint(painter: _ClassBarPainter(at(rating), was == null || was < lo || was > hi ? null : at(was))),
      ),
      const SizedBox(height: Gaps.small),
      Row(children: [
        ResultBadge(band.label, color: Palette.paper),
        Expanded(
          child: Text(
            next == null ? s.topClassNote : s.runClassGap((hi - rating).ceil(), next.label, hi.round()),
            textAlign: TextAlign.center,
            style: RunTabsStyle.noteStyle.copyWith(color: Palette.ink),
          ),
        ),
        if (next != null) ResultBadge(next.label, muted: true),
      ]),
    ]);
  }
}

class _ClassBarPainter extends CustomPainter {
  _ClassBarPainter(this.fill, this.before);
  final double fill;
  final double? before;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Palette.paper);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * fill, size.height), Paint()..color = Palette.sea);
    canvas.drawRect(
        rect.deflate(Strokes.label / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.label);
    if (before case final b?) {
      final x = size.width * b;
      canvas.drawLine(Offset(x, -RunTabsStyle.tickReach), Offset(x, size.height + RunTabsStyle.tickReach),
          Paint()..strokeWidth = RunTabsStyle.tickStroke);
    }
  }

  @override
  bool shouldRepaint(_ClassBarPainter old) => old.fill != fill || old.before != before;
}

/// A forfeit's scored time as a sum: the clock, a penalty for each miss
/// (the cards left included) and a slow card for each card left.
class _Forfeit extends StatelessWidget {
  const _Forfeit(this.run);
  final PastRun run;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final clock = run.clock ?? Duration.zero, scored = run.scoredTime ?? Duration.zero;
    final misses = run.scoredMisses ?? 0, left = run.planned - run.cards;
    final perCardMs =
        left == 0 ? 0.0 : (scored - clock).inMilliseconds.toDouble() / left - misses * run.penaltyMs / left;
    return RunPanel(color: Palette.pinkSoft, children: [
      Text(
        s.runForfeitSum(formatTenths(clock), misses, run.penaltyMs ~/ 1000, left, formatSeconds(perCardMs, 1),
            formatTenths(scored)),
        style: RunTabsStyle.valueStyle,
      ),
      const SizedBox(height: Gaps.small),
      Text(s.runForfeitText(run.cards, formatSeconds(perCardMs, 1)), style: RunTabsStyle.lineStyle),
    ]);
  }
}

/// D25: the rating over the ranked runs with the class lines, the latest
/// runs in a table with this one marked, and what stands out about it.
class _RankedRuns extends StatelessWidget {
  const _RankedRuns(this.detail);
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final runs = detail.rankedRuns;
    final me = detail.run;
    final verdict = _verdict(s);
    return HistorySection(
      title: s.runRankedTitle,
      sub: s.sub?.runRankedTitle,
      note: s.runSoFar(runs.length),
      child: RunPanel(gap: false, children: [
        if (runs.length > 1)
          SizedBox(
            height: RunTabsStyle.ratingChartHeight,
            child: CustomPaint(
              painter: _RatingChartPainter(
                [for (final (_, r) in runs) r.after],
                runs.indexWhere((r) => r.$1.id == me.id),
                MediaQuery.textScalerOf(context),
              ),
            ),
          ),
        Table(
          columnWidths: const {0: FlexColumnWidth(RunTabsStyle.runColumnFlex)},
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: Strokes.label))),
              children: [
                for (final (i, h) in [s.runColRun, s.runColScored, s.runColPlayedLike, s.runColRating].indexed)
                  _cell(h.toUpperCase(), RunTabsStyle.headStyle, right: i > 0),
              ],
            ),
            for (final (run, rating) in runs.reversed.take(RunRatingTuning.tableRuns))
              TableRow(
                decoration: BoxDecoration(
                  color: run.id == me.id ? Palette.sunSoft : null,
                  border: const Border(bottom: BorderSide(color: RunTabsStyle.rule)),
                ),
                children: [
                  _cell(
                    [
                      s.sessionDate(run.startedAt),
                      if (run.forfeit) s.runTagForfeit else if (rating.before == null) s.runTagPlaced,
                    ].join(' · '),
                    run.id == me.id ? RunTabsStyle.lineStyle : RunTabsStyle.rowStyle,
                  ),
                  for (final v in [runTimeText(run), '${rating.performance.round()}', '${rating.after.round()}'])
                    _cell(v, run.id == me.id ? RunTabsStyle.lineStyle : RunTabsStyle.rowStyle, right: true),
                ],
              ),
          ],
        ),
        if (verdict != null) ...[
          const SizedBox(height: Gaps.small),
          Text(verdict, style: RunTabsStyle.lineStyle),
        ],
      ]),
    );
  }

  static Widget _cell(String text, TextStyle style, {bool right = false}) => Padding(
        padding: RunTabsStyle.tableCellPadding,
        child: Text(text, textAlign: right ? TextAlign.right : TextAlign.left, style: style),
      );

  /// The run's fastest-yet or highest-rating-yet line, when it is either.
  String? _verdict(S s) {
    final earlier = [for (final r in detail.rankedRuns) if (r.$1.id != detail.run.id) r];
    final time = detail.run.time, after = detail.rating!.after;
    if (earlier.isEmpty) return null;
    if (time != null && earlier.every((r) => r.$1.time == null || r.$1.time! > time)) return s.runFastestRanked;
    if (earlier.every((r) => r.$2.after < after)) return s.runBestRating;
    return null;
  }
}

/// The rating after each ranked run as a line, with a dashed line at each
/// class threshold in reach; this run is a pink diamond.
class _RatingChartPainter extends CustomPainter {
  _RatingChartPainter(this.ratings, this.mine, this.scaler);
  final List<double> ratings;
  final int mine;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
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
        text: TextSpan(text: '${band.label} ${r.round()}', style: RunTabsStyle.chartLabelStyle),
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

/// D26: the exam and 100-card free play don't move the rating; the exam
/// says who won.
class _NoRank extends StatelessWidget {
  const _NoRank(this.run);
  final PastRun run;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final exam = run.mode == PlayMode.exam;
    final String text;
    if (exam && run.tobi != null && run.time != null) {
      final gap = formatSeconds((run.tobi! - run.time!).inMilliseconds.abs().toDouble(), 1);
      text = run.passed ? '${s.runExamBeat(gap)} ${s.runExamWonText}' : '${s.runExamBeaten(gap)} ${s.runExamLostText}';
    } else {
      text = s.runFreeNoRank;
    }
    return RunPanel(color: exam ? Palette.paper : Palette.seaSoft, children: [
      TrackedLabel(exam ? s.examRun : s.freePlay, sub: exam ? s.sub?.examRun : s.sub?.freePlay),
      Text(s.notForRank, style: RunTabsStyle.headlineStyle),
      const SizedBox(height: Gaps.tight),
      Text(text, style: RunTabsStyle.lineStyle),
    ]);
  }
}
