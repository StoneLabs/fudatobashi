import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'history_widgets.dart';
import 'run_charts.dart';

/// A run page's Overview, one screen tall: the headline (D12, or D29 for
/// the training view) and the time graph (D13), which takes the height
/// left over.
class RunOverviewTab extends StatelessWidget {
  const RunOverviewTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final run = detail.run;
    const padding = EdgeInsets.fromLTRB(Gaps.gutter, Gaps.section, Gaps.gutter, 0);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - padding.vertical),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (run.mode == PlayMode.exam)
                _ExamHeadline(detail)
              else if (run.view == RunView.hundred)
                _HundredHeadline(detail)
              else
                _TrainingHeadline(detail),
              const SizedBox(height: Gaps.section),
              Expanded(child: RunTimeSection(detail)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The headline's sun-toned panel.
class _HeadlinePanel extends StatelessWidget {
  const _HeadlinePanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      HeadlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
}

/// The big number with its label, and a stamp or Tobi on the right.
class _BigTime extends StatelessWidget {
  const _BigTime({required this.label, required this.value, this.unit, this.badge});
  final String label, value;
  final String? unit;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrackedLabel(label),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: value, style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryRunStyle.bigFont, height: 1.1)),
                    if (unit != null)
                      TextSpan(text: ' $unit', style: const TextStyle(fontFamily: Fonts.display, fontSize: TypeScale.title)),
                  ])),
                ),
              ],
            ),
          ),
          ?badge,
        ],
      );
}

/// The line under a headline: small facts in a row.
class _FactLine extends StatelessWidget {
  const _FactLine(this.parts);
  final List<String> parts;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Gaps.small),
        child: Text(parts.join('   '),
            style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.small)),
      );
}

/// D12: ranked or 100-card free play.
class _HundredHeadline extends StatelessWidget {
  const _HundredHeadline(this.detail);
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final rating = detail.rating;
    final misses = run.scoredMisses ?? detail.cards.misses.length;
    final clock = run.clock;
    final avg = clock == null || run.cards == 0 ? null : clock.inMilliseconds / run.cards;
    final facts = [
      Fact(avg == null ? missingTime : '${formatSeconds(avg)}s', s.runAvgCard),
      Fact('$misses', s.runMisses),
      if (rating != null)
        Fact(rating.before == null ? '${rating.after.round()}' : ratingChangeText(rating.after - rating.before!), s.runRatingFact),
      Fact(detail.xp == null ? missingTime : '+${detail.xp!.award.total}', s.runXpFact),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _HeadlinePanel(children: [
        _BigTime(
          label: run.scored ? s.runScoredTime : s.runTimeLabel,
          value: runTimeText(run),
          badge: _hundredCheer(context),
        ),
        if (run.forfeit) ...[
          const SizedBox(height: Gaps.tight),
          ResultBadge(s.runForfeitLine(run.cards, run.planned), muted: true),
        ],
        const SizedBox(height: Gaps.small),
        FactGrid(facts, perRow: facts.length),
      ]),
      _FactLine([
        if (run.scored && clock != null) s.runClockLine(formatTenths(clock), misses),
        if (rating != null)
          '${rating.before == null ? '' : '${rating.before!.round()} → '}${rating.after.round()} · ${Rating.bandOf(rating.after).label}',
      ]),
    ]);
  }

  /// Tobi's reaction: a stamp and a cheer for a placement, a class up or
  /// a best, shock at a forfeit, at ease otherwise.
  Widget _hundredCheer(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final change = ProgressScope.of(context).classChangeOf(run);
    final up = change != null && change.$2.minRating > change.$1.minRating;
    final (text, sub) = run.placement
        ? (s.historyPlaced, s.sub?.historyPlaced)
        : up
            ? (s.historyUpTo(change.$2.label), s.sub?.historyUpTo(change.$2.label))
            : detail.best
                ? (s.runFastestKind, s.sub?.runFastestKind)
                : (null, null);
    return HeadlineCheer(
      stamp: text == null ? null : RunStamp(text, sub: sub),
      pose: text != null
          ? TobiPose.cheering
          : run.forfeit
              ? TobiPose.shocked
              : TobiPose.relaxed,
    );
  }
}

/// D12 for the exam: you against Tobi.
class _ExamHeadline extends StatelessWidget {
  const _ExamHeadline(this.detail);
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final mine = run.time, tobi = run.tobi;
    final gap = mine == null || tobi == null ? null : (tobi - mine).abs();
    Widget box(String label, Duration? t, Color fill, Color border) => Expanded(
          child: Container(
            padding: HistoryRunStyle.factPadding,
            decoration: BoxDecoration(color: fill, border: Border.all(color: border, width: Strokes.control)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TrackedLabel(label),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t == null ? missingTime : formatTenths(t),
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryRunStyle.examTimeFont)),
              ),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _HeadlinePanel(children: [
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: run.passed ? s.runExamWon : s.runExamLost,
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryRunStyle.bigFont, height: 1.1)),
                if (gap != null)
                  TextSpan(
                      text: '  ${s.runExamBy(formatSeconds(gap.inMilliseconds.toDouble(), 1))}',
                      style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body)),
              ])),
            ),
          ),
          HeadlineCheer(pose: run.passed ? TobiPose.shocked : TobiPose.fired),
        ]),
        const SizedBox(height: Gaps.small),
        Row(children: [
          box(s.runTobiTime, tobi, Palette.sun, Palette.ink),
          const SizedBox(width: Gaps.small),
          box(s.runYourTime, mine, Palette.paper, run.passed ? Palette.pink : Palette.ink),
        ]),
        const SizedBox(height: Gaps.small),
        FactGrid([
          Fact(
              run.clock == null || run.cards == 0 ? missingTime : '${formatSeconds(run.clock!.inMilliseconds / run.cards)}s',
              s.runAvgCard),
          Fact('${run.scoredMisses ?? detail.cards.misses.length}', s.runMisses),
          Fact(detail.xp == null ? missingTime : '+${detail.xp!.award.total}', s.runXpFact),
        ], perRow: 3),
      ]),
      _FactLine([
        if (run.clock case final clock?) s.runClockLine(formatTenths(clock), run.scoredMisses ?? 0),
      ]),
    ]);
  }
}

/// D29: the training view's light headline.
class _TrainingHeadline extends StatelessWidget {
  const _TrainingHeadline(this.detail);
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final clock = run.clock;
    final misses = detail.cards.misses.length;
    final right = run.cards == 0 ? 0 : (100 * (run.cards - misses) / run.cards).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _HeadlinePanel(children: [
        _BigTime(
          label: s.runPerCard,
          value: clock == null || run.cards == 0 ? missingTime : formatSeconds(clock.inMilliseconds / run.cards),
          unit: 's',
          badge: run.dayDone
              ? HeadlineCheer(stamp: RunStamp(s.historyDayDone, sub: s.sub?.historyDayDone), pose: TobiPose.cheering)
              : const HeadlineCheer(pose: TobiPose.relaxed),
        ),
        const SizedBox(height: Gaps.small),
        FactGrid([
          Fact('$misses', s.runMisses),
          Fact('$right%', s.runRightShare),
          Fact(detail.xp == null ? missingTime : '+${detail.xp!.award.total}', s.runXpFact),
        ], perRow: 3),
      ]),
      _FactLine([
        if (clock != null) s.runTotalLine(formatTenths(clock)),
      ]),
    ]);
  }
}

/// D13: the time graph with its legend.
class RunTimeSection extends StatelessWidget {
  const RunTimeSection(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final t = detail.timeline;
    final refs = run.view == RunView.hundred ? detail.references : const <Never>[];
    final bottom = detail.graphBottom;
    final tobi = detail.tobi;
    return HistorySection(
      title: s.runGraphTitle,
      sub: s.sub?.runGraphTitle,
      note: s.runGraphCards,
      fill: true,
      child: MangaPanel(
        padding: HistoryRunStyle.chartPadding,
        shadow: HistoryRunStyle.panelShadow,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: RunTimeGraph(run: t, bottomMs: bottom, references: refs, tobi: tobi)),
          ChartLegend([
            (const LegendMark.line(Palette.ink), s.legendThisRun),
            (const LegendMark.line(Palette.ink, dashed: true), s.legendEvenPace),
            if (tobi != null) (const LegendMark.line(Palette.seaDeep), s.legendTobi),
            if (refs.isNotEmpty) (const LegendMark.line(RunChartStyle.reference), s.legendLastRuns(refs.length)),
            if (t.missCards.isNotEmpty) (const LegendMark.box(Palette.pink), run.scored ? s.legendMissPenalty : s.legendMiss),
            (const LegendMark.box(Palette.pinkSoft), s.legendBehind),
            (const LegendMark.box(Palette.landSoft), s.legendAhead),
          ]),
        ]),
      ),
    );
  }
}
