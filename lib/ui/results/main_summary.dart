import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/card_stats.dart';
import '../../domain/play_session.dart';
import '../../domain/ranked.dart';
import '../../domain/rating.dart';
import '../../domain/step_plan.dart';
import '../../domain/today_set.dart';
import '../../domain/trainer.dart';
import '../../domain/weak_cards.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../home/today_box.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_labels.dart';
import '../run/run_launcher.dart';
import 'run_summary.dart';

/// The summary of a main-game run: of a 修行 run, what is left of today's
/// set (or, the run that finished it, the day done); of other practice
/// runs, what was right or the weak cards left;
/// of a ranked run its scored time, and of an exam try how it went against
/// Tobi.
class MainRunSummary extends StatelessWidget {
  const MainRunSummary({super.key, required this.report, required this.config});

  final SessionReport report;
  final PlayConfig config;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = _Run(s, ProgressScope.of(context), report, config);
    final (hero, tiles, rows) = run.content();
    final ranked = config.mode == PlayMode.ranked;
    return RunSummary(
      title: run.title(s),
      sub: [run.title(s.other, sub: true), ...run.details()].join(' · ').toUpperCase(),
      untracked: !config.tracked,
      hero: hero,
      tiles: tiles,
      rows: rows,
      home: s.home,
      onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
      shout: (ranked ? s.rankedAgain : s.keepGoing).toUpperCase(),
      onShout: () =>
          keepGoing(context, config.mode == PlayMode.exam ? const PlayConfig(mode: PlayMode.training) : config),
    );
  }
}

typedef _Content = (SummaryHero, List<SummaryTile>, List<Widget>);

/// What a run's summary is made of.
class _Run {
  _Run(this.s, this.progress, this.report, this.config);

  final S s;
  final Progress progress;
  final SessionReport report;
  final PlayConfig config;

  List<Attempt> get attempts => report.attempts;
  int get played => attempts.length;
  int get missed => attempts.where((a) => a.isMiss).length;
  int get right => played - missed;
  bool get journey => progress.trainer.config.learningMode == LearningMode.journey;

  /// The header's mode, in [t]'s language: on the [sub] line a placement
  /// is a ranked run like any other.
  String title(S t, {bool sub = false}) =>
      config.mode == PlayMode.ranked && report.placement && !sub ? t.summaryPlacement : modeTitle(t, config.mode);

  /// The header's line after the mode: the deck and the cards played.
  List<String> details() {
    final cards = played + (report.score?.cardsLeft ?? 0);
    return [
      if (config.mode == PlayMode.free) ...freeDeckLabels(s, config),
      cards > played ? s.summaryCardsOf(played, cards) : s.cardsCount(played),
    ];
  }

  _Content content() {
    final set = progress.todaySet();
    return switch (config.mode) {
      PlayMode.ranked => _ranked(),
      PlayMode.exam => _exam(),
      PlayMode.nigate => _weak(),
      PlayMode.training when report.dayDone != null => _dayDone(),
      PlayMode.training when journey && set != null && !set.done => _todaysSet(set),
      _ => _thisRun(),
    };
  }

  // ------------------------------------------------------------- practice

  _Content _todaysSet(TodaySet set) {
    final bar = set.bar;
    final runId = report.runId;
    final before = (runId == null ? null : progress.todaySetBefore(runId))?.bar.done ?? bar.done;
    final now = math.max(0, bar.done - before);
    final rest = math.max(0, bar.total - bar.done);
    final doneLabel = BarLabel(s.summaryDoneOf(bar.done, bar.total));
    final runLabel = BarLabel(s.summaryThisRunPlus(now), part: 1);
    return (
      SummaryHero(
        banner: s.summaryTodaysSet,
        body: HeroCount('${bar.left}', label: s.summaryCardsLeft(bar.left), note: s.summaryOfSet(bar.total)),
        bar: before > 0
            ? [
                BarPart(Palette.land, before, done: true),
                BarPart(Palette.land, now, done: true, marked: true),
                BarPart(Palette.paper, rest),
              ]
            : [BarPart(Palette.land, now, done: true), BarPart(Palette.paper, rest)],
        labels: before > 0
            ? [doneLabel, if (now > 0) runLabel]
            : [BarLabel(runLabel.text), BarLabel(doneLabel.text, part: 1)],
        pose: TobiPose.fired,
        balloon: bar.left <= bar.total * SummaryHeroLayout.almostThere ? s.summaryAlmostThere : s.heroKeepItUp,
      ),
      [_cardsTile(s.summaryThisRunNote), _rightTile(), rewardTile(s, report.xp)],
      shelfRows([_newShelf(), _missedShelf(s.summaryBackLater), if (report.newCards.isEmpty && missed == 0) _slowShelf()]),
    );
  }

  _Content _dayDone() {
    final done = report.dayDone!;
    final fresh = [
      for (final e in progress.todaySet()?.kinds.entries ?? const <MapEntry<ItemKey, StepKind>>[])
        if (e.value == StepKind.newCard) SummaryCard(e.key.poemId, inverted: e.key.inverted),
    ];
    return (
      SummaryHero(
        banner: s.summaryTodaysSet,
        body: HeroWord(s.summaryDone, outlined: true),
        bar: const [BarPart(Palette.land, 1, done: true)],
        labels: [BarLabel(s.summaryDoneOf(done.looks, done.looks))],
        pose: TobiPose.cheering,
        burst: SummaryHeroLayout.burst,
        stamp: const DayDoneStamp(fontSize: SummaryHeroLayout.stampFont),
      ),
      [_cardsTile(s.summaryThisRunNote), _rightTile(), rewardTile(s, report.xp)],
      [
        ...shelfRows([CardShelf(s.summaryNewToday, Palette.sun, s.summaryNewTodayNote(done.newCards), fresh)]),
        SummaryRow(
          heading: s.summaryStreak,
          accent: Palette.land,
          note: s.summaryStreakNote(done.goalStreak),
          centered: true,
          child: SummaryWeek(progress.weekStamps()),
        ),
      ],
    );
  }

  /// A practice run judged by itself: how many were right.
  _Content _thisRun() {
    final set = journey ? progress.todaySet() : null;
    return (
      SummaryHero(
        banner: s.summaryThisRun,
        body: HeroCount('$right', label: s.summaryRight, note: s.summaryOfCards(played)),
        bar: [BarPart(Palette.land, right, done: true), BarPart(Palette.pink, missed)],
        labels: [
          BarLabel(s.summaryRightCount(right)),
          if (missed > 0) BarLabel(s.summaryMissedCount(missed), end: true),
        ],
        balloon: s.summaryNiceRun,
      ),
      [
        _cardsTile(s.summaryThisRunNote),
        journey ? _todayTile(set) : _streakTile(),
        config.tracked ? rewardTile(s, report.xp) : rewardTile(s, null),
      ],
      [
        ...shelfRows([_missedShelf(s.summarySecondLook), _slowShelf()]),
        ..._unsavedNote(),
      ],
    );
  }

  /// A 苦手 drill: the weak cards left of those at its start, the ones it
  /// took off the weak list and those still on it. A side fast twice in a
  /// row only counts as cleared once it is off the list too.
  _Content _weak() {
    final drill = WeakCards.drill(
        attempts, {for (final id in config.targets) ItemKey.fromId(id)}, config.goalMs?.toDouble() ?? double.infinity);
    final start = report.weakSidesBefore ?? {for (final d in drill) d.key};
    final now = report.weakSidesAfter ?? {for (final d in drill) if (!d.cleared) d.key};
    SummaryCard card(WeakSide side) => SummaryCard(side.key.poemId, inverted: side.key.inverted);
    final clearedCards = [
      for (final d in drill)
        if (d.cleared && start.contains(d.key) && !now.contains(d.key)) card(d),
    ];
    final stillCards = [for (final d in drill) if (now.contains(d.key)) card(d)];
    final startIds = {for (final k in start) k.poemId};
    final nowIds = {for (final k in now) k.poemId};
    final before = startIds.length;
    final left = nowIds.length;
    final cleared = startIds.difference(nowIds).length;
    final still = before - cleared;
    final tiles = [_cardsTile(s.summaryThisDrill), _rightTile(), rewardTile(s, report.xp)];
    if (left == 0) {
      return (
        SummaryHero(
          banner: s.weakLeftLabel,
          body: HeroWord(s.summaryClear, outlined: true),
          bar: const [BarPart(Palette.land, 1, done: true)],
          labels: [BarLabel(s.summaryClearedOf(cleared, before))],
          pose: TobiPose.cheering,
          burst: SummaryHeroLayout.burst,
        ),
        tiles,
        shelfRows([
          CardShelf(s.weakClearedHeading, Palette.land, s.summaryClearedNote, clearedCards, tail: s.summaryNoWeakLeft),
        ]),
      );
    }
    return (
      SummaryHero(
        banner: s.weakLeftLabel,
        body: HeroCount('$left', label: s.summaryWeakLeft(left), note: s.weakLeftWas(before)),
        bar: [BarPart(Palette.land, cleared, done: true), BarPart(Palette.pink, still)],
        labels: [
          if (cleared > 0) BarLabel(s.summaryCleared(cleared)),
          if (still > 0) BarLabel(s.summaryStillWeak(still), part: 1),
        ],
        pose: TobiPose.fired,
        balloon: cleared > 0 ? s.summaryGettingThere : s.heroKeepItUp,
      ),
      tiles,
      shelfRows([
        CardShelf(s.weakClearedHeading, Palette.land, s.summaryClearedNote, clearedCards),
        CardShelf(s.weakStillHeading, Palette.pink, s.summaryNotYetNote, stillCards),
      ]),
    );
  }

  // ---------------------------------------------------------------- timed

  _Content _ranked() {
    final score = report.score!;
    final rows = shelfRows([
      _slowShelf(note: report.forfeit ? s.summaryBeforeStop : s.toughestNote, timed: true),
      _missedShelf(s.summaryPenaltyEach(score.penaltyMs ~/ Duration.millisecondsPerSecond)),
    ]);
    final tiles = [_speedTile(), _rightTile(), _ratingTile()];
    if (report.forfeit) {
      return (
        SummaryHero(
          banner: s.rankedScoredTime.toUpperCase(),
          body: HeroWord(s.historyForfeit, sub: Text(s.summaryCountsAsZero)),
          bar: [BarPart(Palette.sun, played, done: true), BarPart(Palette.desk, score.cardsLeft)],
          labels: [BarLabel(s.summaryPlayed(played)), BarLabel(s.summaryLeft(score.cardsLeft), part: 1)],
          pose: TobiPose.shocked,
          balloon: s.summaryNextTime,
        ),
        tiles,
        rows,
      );
    }
    final before = report.ratingBefore, after = report.ratingAfter;
    return (
      SummaryHero(
        banner: s.rankedScoredTime.toUpperCase(),
        body: HeroTime(score.scored),
        bar: _clockBar(score),
        labels: _clockLabels(score),
        balloon: report.placement
            ? s.summaryFirstRating
            : before != null && after != null && after >= before
                ? s.summaryRatingUp
                : s.summaryNextTime,
      ),
      tiles,
      rows,
    );
  }

  _Content _exam() {
    final score = report.score!;
    final tobi = report.tobi;
    final passed = report.passed;
    final cooldown = progress.exam().cooldown;
    final cards = played + score.cardsLeft;
    final times = Text.rich(TextSpan(children: [
      report.completed
          ? TextSpan(
              text: formatRunTime(score.scored),
              style: const TextStyle(
                  fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: SummaryHeroLayout.subTimeFont),
            )
          : TextSpan(text: s.summaryCardsOf(played, cards)),
      if (tobi != null) TextSpan(text: '  ${s.summaryTobiTime(formatRunTime(tobi))}'),
    ]));
    final penaltySeconds = score.penaltyMs ~/ Duration.millisecondsPerSecond;
    return (
      SummaryHero(
        banner: s.summaryVsTobi,
        body: passed ? HeroWord(s.summaryPassed, outlined: true, sub: times) : HeroWord(s.examLostTitle, sub: times),
        bar: _clockBar(score),
        labels: _clockLabels(score),
        pose: TobiPose.cheering,
        balloon: passed
            ? null
            : cooldown == null
                ? s.summaryNextTime
                : s.summaryAgainIn(cooldown.inMinutes + 1),
        burst: passed ? SummaryHeroLayout.burstWithSub : null,
      ),
      [
        _speedTile(),
        _rightTile(
            note: score.misses == 0 ? null : s.summaryMissedPenalty(score.misses, score.misses * penaltySeconds)),
        passed
            ? rewardTile(s, report.xp)
            : SummaryTile(
                label: s.summaryNextTryLabel,
                big: TileFigure(cooldown == null ? s.summaryNow : formatMinutes(cooldown)),
                note: s.summaryXpEarned(groupDigits(report.xp?.award.total ?? 0)),
              ),
      ],
      shelfRows([_slowShelf(timed: true), _missedShelf(s.summaryPenaltyEach(penaltySeconds))]),
    );
  }

  /// A timed run's bar: its clock in sun, then the time its misses added.
  static List<BarPart> _clockBar(RankedScore score) => [
        BarPart(Palette.sun, score.clock.inMilliseconds, done: true),
        BarPart(Palette.pink, score.misses * score.penaltyMs, done: true),
      ];

  List<BarLabel> _clockLabels(RankedScore score) => [
        BarLabel(s.summaryClock(formatRunTime(score.clock))),
        if (score.misses > 0)
          BarLabel(s.summaryMisses(score.misses, score.misses * score.penaltyMs ~/ Duration.millisecondsPerSecond),
              end: true),
      ];

  // ---------------------------------------------------------------- tiles

  SummaryTile _cardsTile(String note) =>
      SummaryTile(label: s.summaryCardsLabel, big: TileFigure('$played'), note: note);

  SummaryTile _rightTile({String? note}) => SummaryTile(
        label: s.summaryRightLabel,
        big: TileFigure('$right', unit: '/$played'),
        note: note ?? (missed == 0 ? s.summaryNoMisses : s.summaryMissedCount(missed)),
      );

  /// How much of today's set is left, or that it is done.
  SummaryTile _todayTile(TodaySet? set) => SummaryTile(
        label: s.summaryTodayLabel,
        big: TileFigure(set == null ? missingTime : set.done ? s.done : '${set.bar.left}'),
        note: set != null && set.done ? s.summarySetDone : s.summaryLeftInSet,
      );

  SummaryTile _streakTile() {
    final days = progress.streak;
    return SummaryTile(label: s.summaryStreakLabel, big: TileFigure('$days'), note: s.historyStreak(days));
  }

  SummaryTile _speedTile() {
    final timed = [for (final a in attempts) if (a.validTime) a.cardUs / Duration.microsecondsPerMillisecond];
    final avg = timed.isEmpty ? null : timed.reduce((a, b) => a + b) / timed.length;
    return SummaryTile(
      label: s.summarySpeedLabel,
      big: avg == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(avg), unit: ' s'),
      note: s.summaryAvgPerCard,
    );
  }

  SummaryTile _ratingTile() {
    final before = report.ratingBefore, after = report.ratingAfter;
    if (after == null) return SummaryTile(label: s.ratingLabel, big: const TileFigure(missingTime), note: '');
    final band = s.className(Rating.bandOf(after));
    if (before == null) {
      return SummaryTile(label: s.ratingLabel, big: TileFigure('${after.round()}'), note: '${s.ratingFirst} · $band');
    }
    final delta = (after - before).round();
    return SummaryTile(
      label: s.ratingLabel,
      big: TileFigure(delta >= 0 ? '+$delta' : groupDigits(delta)),
      note: '${before.round()} → ${after.round()} · $band',
    );
  }

  // --------------------------------------------------------------- shelves

  /// Each card once, in the order first met.
  static List<SummaryCard> _cards(Iterable<Attempt> from, {bool timed = false}) {
    final seen = <(int, bool)>{};
    return [
      for (final a in from)
        if (seen.add((a.card.poemId, a.card.inverted)))
          SummaryCard(a.card.poemId,
              inverted: a.card.inverted, ms: timed ? a.cardUs / Duration.microsecondsPerMillisecond : null),
    ];
  }

  CardShelf _newShelf() => CardShelf(
      s.summaryNewCards, Palette.sun, s.summaryNewCardsNote, [for (final id in report.newCards) SummaryCard(id)]);

  CardShelf _missedShelf(String note) =>
      CardShelf(s.summaryMissed, Palette.pink, note, _cards(attempts.where((a) => a.isMiss)));

  /// The slowest right answers with a clean time; with their times when
  /// [timed].
  CardShelf _slowShelf({String? note, bool timed = false}) {
    final slow = [for (final a in attempts) if (a.validTime && !a.tainted && !a.isMiss) a]
      ..sort((a, b) => b.cardUs.compareTo(a.cardUs));
    return CardShelf(s.summarySlowest, Palette.shallow, note ?? s.toughestNote,
        _cards(slow, timed: timed).take(SummaryPanelLayout.perLine).toList());
  }

  /// The dashed note of a run that saved nothing, or only to History.
  List<Widget> _unsavedNote() => [
        if (!config.tracked)
          SummaryNote(s.guestNotRecorded)
        else if (config.mode == PlayMode.free && !config.countsForSrs)
          SummaryNote(s.customRunNote),
      ];
}
