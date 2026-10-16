import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../play/time_format.dart';
import '../rank/ranked_runs.dart';
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
    final forfeit = detail.run.forfeit;
    final scored = runTimeText(s, detail.run);
    return RunPanel(children: [
      TrackedLabel(s.rating, sub: s.sub?.rating),
      if (before == null) ...[
        RunBigValue('$after'),
        const SizedBox(height: Gaps.tight),
        Text('${s.runPlacementShout} ${forfeit ? s.runPlacementForfeitText(played) : s.runPlacementText(scored, played)}',
            style: RunTabsStyle.lineStyle),
        const SizedBox(height: Gaps.small),
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
      ],
      RunValueLine(s.runRatingBefore, before == null ? s.rankUnplaced : '$before'),
      RunValueLine(forfeit ? s.runColPlayedLike : s.runPlayedLike(scored), '$played'),
      RunValueLine(s.runNewRating, '$after'),
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
        ResultBadge(s.className(band), color: Palette.paper),
        Expanded(
          child: Text(
            next == null ? s.topClassNote : s.runClassGap((hi - rating).ceil(), next, hi.round()),
            textAlign: TextAlign.center,
            style: RunTabsStyle.noteStyle.copyWith(color: Palette.ink),
          ),
        ),
        if (next != null) ResultBadge(s.className(next), muted: true),
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

/// A forfeit: where it stopped, and why it plays like 0.
class _Forfeit extends StatelessWidget {
  const _Forfeit(this.run);
  final PastRun run;

  @override
  Widget build(BuildContext context) => RunPanel(color: Palette.pinkSoft, children: [
        Text(S.of(context).runForfeitText(run.cards), style: RunTabsStyle.lineStyle),
      ]);
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
          RatingChart([for (final (_, r) in runs) r.after], mine: runs.indexWhere((r) => r.$1.id == me.id)),
        RankedRunsTable(runs, highlight: me.id),
        if (verdict != null) ...[
          const SizedBox(height: Gaps.small),
          Text(verdict, style: RunTabsStyle.lineStyle),
        ],
      ]),
    );
  }

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
