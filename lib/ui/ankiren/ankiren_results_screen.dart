import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import '../results/trip_summary.dart';

/// 暗記練's results, on the run summary: a ranked game's score, a free-play
/// level cleared or failed, or else the cards found; the first-tap finds,
/// the strikes (or a ranked game's average time) and the reward; the cards
/// that were slow, late or missed, how the からふだ went, a level game's
/// levels and what clearing opens; then Back to the AnkiRen page or Done
/// (Home). A recorded game's celebrations play over it first
/// ([TripResultsFrame]).
class AnkirenResultsScreen extends StatelessWidget {
  const AnkirenResultsScreen({super.key, required this.game, required this.report, required this.player});

  final AnkirenGame game;

  /// What was recorded; null when nothing was (see [AnkirenPlayer]).
  final SideTripReport? report;
  final AnkirenPlayer player;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final summary = _Game(s, game, report, player);
    final (hero, tiles, rows) = summary.content(context);
    return TripResultsFrame(
      trip: SideTrip.ankiren,
      report: report,
      child: RunSummary(
        title: s.tripName(SideTrip.ankiren),
        sub: [s.other.tripName(SideTrip.ankiren), ...summary.details()].join(' · ').toUpperCase(),
        untracked: !player.recorded,
        hero: hero,
        tiles: tiles,
        rows: rows,
        home: s.done,
        onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
        shout: s.ankirenBackToPage.toUpperCase(),
        onShout: () => Navigator.of(context).pop(),
      ),
    );
  }
}

typedef _Content = (SummaryHero, List<SummaryTile>, List<Widget>);

/// What a 暗記練 game's summary is made of.
class _Game extends TripSummary {
  _Game(super.s, super.game, this.report, this.player);

  final SideTripReport? report;
  final AnkirenPlayer player;

  AnkirenSetup get setup => game.setup;

  /// The header's line after the trip: who played, and the setup.
  List<String> details() {
    final level = setup.level;
    return [
      switch (player) {
        AnkirenPlayer.developer => s.untracked,
        AnkirenPlayer.guest => s.ankirenGuest,
        AnkirenPlayer.owner => setup.ranked ? s.sideTripRanked : s.freePlay,
      },
      if (level != null)
        s.ankirenLevelTag(level)
      else if (setup.custom)
        s.ankirenCustomTag(setup.perSide, formatMinutes(setup.memorise))
      else
        s.cardsCount(asked),
    ];
  }

  _Content content(BuildContext context) {
    final level = setup.level;
    final score = game.score;
    if (setup.ranked && score != null) return _ranked(score);
    if (game.countsStrikes && level != null && report != null) return _level(context, level, report!);
    return _found();
  }

  _Content _ranked(AnkirenScore score) {
    final before = report?.ratingBefore, after = report?.ratingAfter;
    return (
      SummaryHero(
        banner: game.completed ? s.ankirenScoreLabel : s.endedEarly.toUpperCase(),
        body: HeroCount(groupDigits(score.total), label: s.summaryPoints, note: s.ankirenScoreOf(groupDigits(score.max))),
        bar: [
          BarPart(Palette.land, score.recall - score.karafuda, done: true),
          BarPart(Palette.sun, score.early, done: true),
          // Last of the points, so their label may run on into the rest.
          if (hasKarafuda) BarPart(KarafudaStyle.bar, score.karafuda, done: true),
          BarPart(Palette.paper, math.max(0, score.max - score.total)),
        ],
        labels: [
          BarLabel(s.summaryFinds(groupDigits(score.recall - score.karafuda))),
          if (score.early > 0) BarLabel(s.summaryEarly(groupDigits(score.early)), part: 1),
          if (hasKarafuda && score.karafuda > 0) BarLabel(s.karafudaPoints(groupDigits(score.karafuda)), part: 2),
        ],
        balloon: after == null
            ? null
            : before == null
                ? s.summaryFirstRating
                : after >= before
                    ? s.summaryRatingUp
                    : s.summaryNextTime,
      ),
      [firstTapTile(), avgTile(), ratingTile(before, after)],
      [
        ...shelfRows([
          CardShelf(s.summarySlowest, Palette.shallow, s.summarySlowestFinds, slowest()),
          CardShelf(s.summaryMissed, Palette.pink, s.summaryNotFound, notFound()),
        ]),
        ...karafudaRow(points: score.karafuda),
      ],
    );
  }

  /// A free-play level game of the owner's, whose strikes count.
  _Content _level(BuildContext context, int level, SideTripReport report) {
    final cleared = game.cleared;
    final before = report.ladderBefore, after = report.ladderAfter;
    final allKnown = ProgressScope.of(context).sideTripsHub()[SideTrip.ankiren].rankedLock?.allKnown ?? true;
    const out = AnkirenTuning.strikesOut;
    final note = cleared
        ? after.rankedReady && !before.rankedReady
            ? allKnown
                ? s.ankirenRankedOpened
                : s.ankirenRankedNeedsAllKnown
            : after.customOpen && !before.customOpen
                ? s.ankirenCustomOpened
                : after.rankedReady
                    ? null
                    : s.summaryRankedNext(AnkirenTuning.rankedAfterLevel)
        : s.ankirenClearHow(out);
    return (
      levelHero(level),
      [firstTapTile(), strikesTile(), levelRewardTile(level, report, top: AnkirenLevels.top)],
      [
        firstTapsRow(),
        ...karafudaRow(points: game.score?.karafuda),
        levelsRow(level, after),
        if (note != null) SummaryNote(note),
      ],
    );
  }

  /// A game whose only count is the cards found: a guest's, a custom setup
  /// or the developer's test game.
  _Content _found() {
    final report = this.report;
    final note = switch (player) {
      AnkirenPlayer.guest => s.ankirenGuestNote,
      AnkirenPlayer.owner when setup.custom => s.ankirenCustomNote,
      _ => null,
    };
    return (
      SummaryHero(
        banner: game.completed ? s.ankirenFoundLabel : s.endedEarly.toUpperCase(),
        body: HeroCount('$found', label: s.summaryFound(found), note: s.summaryFoundOf(asked, missed)),
        bar: foundBar(),
        labels: foundLabels(),
        pose: missed == 0 ? TobiPose.cheering : TobiPose.standard,
        balloon: missed == 0 ? s.summaryNice : s.summarySoClose,
      ),
      [firstTapTile(), strikesTile(), rewardTile(s, report?.xp)],
      [
        ...shelfRows([
          CardShelf(s.ankirenFoundFact, Palette.land, s.summaryAllCards(found), foundCards()),
          CardShelf(s.summaryMissed, Palette.pink, s.summaryNotFound, notFound()),
        ]),
        ...karafudaRow(points: game.score?.karafuda),
        if (note != null) SummaryNote(note),
      ],
    );
  }
}
