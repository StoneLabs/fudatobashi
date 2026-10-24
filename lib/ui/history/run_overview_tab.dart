import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../home/today_box.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'history_widgets.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A run page's Overview, the run's summary reopened: a hero answering how
/// it went, three tiles, and the time graph down to the floor.
class RunOverviewTab extends StatelessWidget {
  const RunOverviewTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final (hero, tiles) = _Overview(S.of(context), ProgressScope.of(context), detail).content();
    return ReviewColumn(
      fill: RunTimeSection(detail),
      children: [
        ReviewHero(hero),
        TileBand(tiles, spec: ReviewTileLayout.spec, minHeight: ReviewLayout.tileHeight),
      ],
    );
  }
}

/// What a run's Overview shows above its time graph.
class _Overview {
  _Overview(this.s, this.progress, this.detail);

  final S s;
  final Progress progress;
  final RunDetail detail;

  PastRun get run => detail.run;
  int get cards => run.cards;

  /// The misses its time counts: a timed run's cards left unswiped too.
  int get missed => run.scoredMisses ?? detail.cards.misses.length;
  int get right => cards - detail.cards.misses.length;

  (SummaryHero, List<SummaryTile>) content() => switch (run) {
        PastRun(mode: PlayMode.exam) => (_exam(), [_speedTile(note: _clockNote()), _rightTile(), xpTile(s, detail.xp)]),
        PastRun(forfeit: true) => (_forfeit(), [_speedTile(note: s.reviewAvgOver(cards)), _ratingTile(), xpTile(s, detail.xp)]),
        PastRun(mode: PlayMode.ranked) => (_ranked(), [_speedTile(), _ratingTile(), xpTile(s, detail.xp)]),
        PastRun(view: RunView.hundred) => (_free(), [_speedTile(), _rightTile(), xpTile(s, detail.xp)]),
        _ => (_practice(), [_perCardTile(), _rightShareTile(), xpTile(s, detail.xp)]),
      };

  // ------------------------------------------------------------- heroes

  /// A practice run: the cards it had, right and missed; the run that
  /// finished the day's set is done.
  SummaryHero _practice() {
    final miss = cards - right;
    final done = run.dayDone;
    return SummaryHero(
      banner: s.summaryThisRun,
      body: done
          ? HeroWord(s.summaryDone, outlined: true, metrics: ReviewHeroLayout.metrics)
          : HeroCount('$cards',
              label: s.reviewCardsWord(cards),
              note: run.mode == PlayMode.nigate ? s.reviewSwipedDrill : s.reviewSwipedRun,
              metrics: ReviewHeroLayout.metrics),
      bar: [BarPart(Palette.land, right, done: true), BarPart(Palette.pink, miss)],
      labels: [
        BarLabel(s.reviewRightOf(right, cards)),
        if (miss > 0) BarLabel(s.summaryMissedCount(miss), end: true),
      ],
      pose: done ? TobiPose.cheering : TobiPose.relaxed,
      burst: done ? ReviewHeroLayout.burst : null,
      stamp: done ? const DayDoneStamp(fontSize: SummaryHeroLayout.stampFont) : null,
    );
  }

  /// A ranked run: its scored time, the bar its clock and the time its
  /// misses added; a placement, a class up or a best stamped.
  SummaryHero _ranked() {
    final change = progress.classChangeOf(run);
    final up = change != null && change.$2.minRating > change.$1.minRating;
    final stamp = run.placement
        ? RunStamp(s.historyPlaced, sub: s.sub?.historyPlaced, fontSize: RunStampStyle.heroFont)
        : up
            ? RunStamp(s.historyUpTo(change.$2), sub: s.sub?.historyUpTo(change.$2), fontSize: RunStampStyle.heroFont)
            : detail.best
                ? RunStamp(s.runFastestKind, sub: s.sub?.runFastestKind, fontSize: RunStampStyle.heroFont)
                : null;
    return SummaryHero(
      banner: s.rankedScoredTime.toUpperCase(),
      body: _time(),
      bar: _clockBar(Palette.paper),
      labels: _clockLabels(),
      pose: stamp == null ? TobiPose.standard : TobiPose.cheering,
      stamp: stamp,
      stampOnTop: true,
    );
  }

  /// A ranked run given up: how far it got.
  SummaryHero _forfeit() => SummaryHero(
        banner: s.rankedScoredTime.toUpperCase(),
        body: HeroWord(s.historyForfeit, metrics: ReviewHeroLayout.metrics),
        bar: [BarPart(Palette.paper, cards, done: true), BarPart(RunTabsStyle.paceUnplayed, run.planned - cards)],
        labels: [BarLabel(s.historyMissesShort(missed)), BarLabel(s.runForfeitLine(cards, run.planned), part: 1)],
        pose: TobiPose.shocked,
      );

  /// 100-card free play: its time, the bar a race against the last one.
  SummaryHero _free() {
    final mine = run.time, last = detail.references.firstOrNull?.endMs;
    final race = mine == null || last == null
        ? null
        : _race(mine.inMilliseconds.toDouble(), last, mine: Palette.land, other: Palette.sun, otherRest: Palette.paper);
    return SummaryHero(
      banner: s.runTimeLabel.toUpperCase(),
      body: _time(),
      bar: race ?? const [BarPart(Palette.land, 1, done: true)],
      labels: [
        if (mine != null)
          BarLabel(last == null
              ? s.reviewThisRunTime(formatTenths(mine))
              : s.reviewVsLast(formatTenths(mine), formatTenths(_duration(last)))),
      ],
      pose: TobiPose.relaxed,
    );
  }

  /// The graduation exam: who won, the bar the race against Tobi.
  SummaryHero _exam() {
    final mine = run.time, tobi = run.tobi;
    final passed = run.passed;
    final gap = mine == null || tobi == null ? null : s.runExamBy(formatSeconds((tobi - mine).inMilliseconds.abs().toDouble(), 1));
    const subStyle = TextStyle(fontWeight: Weights.black, fontSize: ReviewHeroLayout.examSubFont);
    final sub = gap == null
        ? null
        : passed
            ? OutlinedText(gap, style: subStyle, outlineWidth: ReviewHeroLayout.examSubOutline)
            : Text(gap, style: subStyle);
    return SummaryHero(
      banner: s.examRun.toUpperCase(),
      body: passed
          ? HeroWord(s.runExamWon.toUpperCase(), outlined: true, sub: sub, metrics: ReviewHeroLayout.examMetrics)
          : HeroWord(s.runExamLost, sub: sub, metrics: ReviewHeroLayout.examMetrics),
      bar: mine == null || tobi == null
          ? const [BarPart(Palette.paper, 1)]
          : _race(mine.inMilliseconds.toDouble(), tobi.inMilliseconds.toDouble(),
              mine: Palette.land, other: Palette.sun, otherRest: Palette.sunSoft),
      labels: [
        if ((mine, tobi) case (final mine?, final tobi?))
          BarLabel(passed
              ? s.reviewYouTobi(formatTenths(mine), formatTenths(tobi))
              : s.reviewTobiYou(formatTenths(tobi), formatTenths(mine))),
      ],
      pose: passed ? TobiPose.shocked : TobiPose.fired,
      burst: passed ? ReviewHeroLayout.burstWithSub : null,
    );
  }

  /// The race of [mineMs] against [otherMs]: the whole bar the slower one,
  /// the faster one's share in its colour, [mine] when it was this run.
  static List<BarPart> _race(double mineMs, double otherMs,
          {required Color mine, required Color other, required Color otherRest}) =>
      mineMs <= otherMs
          ? [BarPart(mine, mineMs, done: true), BarPart(otherRest, otherMs - mineMs, marked: true)]
          : [BarPart(other, otherMs, done: true), BarPart(Palette.paper, mineMs - otherMs, marked: true)];

  Widget _time() => switch (run.time) {
        final t? => HeroTime(t, tenths: true, metrics: ReviewHeroLayout.metrics),
        null => HeroWord(missingTime, metrics: ReviewHeroLayout.metrics),
      };

  /// The penalty its misses added to the clock.
  double get _penaltyMs => switch ((run.time, run.clock)) {
        (final t?, final c?) => (t - c).inMilliseconds.toDouble(),
        _ => 0,
      };

  List<BarPart> _clockBar(Color clock) => [
        BarPart(clock, run.clock?.inMilliseconds ?? 0, done: true),
        BarPart(Palette.pink, _penaltyMs, done: true),
      ];

  List<BarLabel> _clockLabels() => [
        if (run.clock case final clock?) BarLabel(s.summaryClock(formatTenths(clock))),
        if (missed > 0)
          BarLabel(s.summaryMisses(missed, _penaltyMs ~/ Duration.millisecondsPerSecond), end: true),
      ];

  // -------------------------------------------------------------- tiles

  double? get _perCardMs => switch (run.clock) {
        final c? when cards > 0 => c.inMilliseconds / cards,
        _ => null,
      };

  TileFigure _seconds(double? ms) =>
      ms == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(ms), unit: ' s');

  SummaryTile _perCardTile() =>
      SummaryTile(label: s.runPerCard.toUpperCase(), big: _seconds(_perCardMs), note: s.summaryAvgPerCard);

  SummaryTile _speedTile({String? note}) =>
      SummaryTile(label: s.summarySpeedLabel, big: _seconds(_perCardMs), note: note ?? s.summaryAvgPerCard);

  String _clockNote() => run.clock == null ? '' : s.reviewClock(formatTenths(run.clock!));

  SummaryTile _rightShareTile() {
    final miss = cards - right;
    return SummaryTile(
      label: s.summaryRightLabel,
      big: TileFigure(cards == 0 ? missingTime : '${(100 * right / cards).round()}', unit: '%'),
      note: miss == 0 ? s.summaryNoMisses : s.summaryMissedCount(miss),
    );
  }

  SummaryTile _rightTile() {
    final penalty = run.penaltyMs ~/ Duration.millisecondsPerSecond;
    return SummaryTile(
      label: s.summaryRightLabel,
      big: TileFigure('${run.planned - missed}', unit: '/${run.planned}'),
      note: missed == 0
          ? s.summaryNoMisses
          : penalty > 0
              ? s.summaryMissedPenalty(missed, missed * penalty)
              : s.summaryMissedCount(missed),
    );
  }

  SummaryTile _ratingTile() {
    final rating = detail.rating;
    if (rating == null) {
      return SummaryTile(label: s.ratingLabel, big: const TileFigure(missingTime), note: '', color: Palette.pinkSoft);
    }
    final after = rating.after, before = rating.before;
    final band = s.className(Rating.bandOf(after));
    if (before == null) {
      return SummaryTile(
          label: s.ratingLabel,
          big: TileFigure('${after.round()}'),
          note: '${s.ratingFirst} · $band',
          color: Palette.pinkSoft);
    }
    final delta = (after - before).round();
    return SummaryTile(
      label: s.ratingLabel,
      big: TileFigure(signedPoints(delta)),
      note: '${before.round()} → ${after.round()} · $band',
      color: Palette.pinkSoft,
    );
  }

  static Duration _duration(double ms) => Duration(milliseconds: ms.round());
}

/// The time graph down to the floor, with its legend; a practice run's
/// without its total time, as those runs vary in length.
class RunTimeSection extends StatelessWidget {
  const RunTimeSection(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final t = detail.timeline;
    final hundred = run.view == RunView.hundred;
    final refs = hundred ? detail.references : const <Never>[];
    final tobi = detail.tobi;
    return ReviewSlab(
      title: s.runGraphTitle,
      sub: s.sub?.runGraphTitle,
      note: s.runGraphCards,
      flatBottom: true,
      expands: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: RunTimeGraph(run: t, bottomMs: detail.graphBottom, references: refs, tobi: tobi, showTotal: hundred),
        ),
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
    );
  }
}
