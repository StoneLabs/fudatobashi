import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_placing.dart';
import '../../domain/teiichi_score.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import '../results/trip_summary.dart';

/// 定位置's results, on the run summary, upright: a ranked game's score, a
/// level cleared or failed, or else the cards found with the first tap out
/// of all; tiles for the placing time and the calls; the cards that were
/// slow, late, missed or never placed, how the からふだ went, a level
/// game's levels and what clearing opens; then Play again (back to the
/// 定位置 page) or Done (Home). A ranked game's rating plays over it first
/// ([TripResultsFrame]).
class TeiichiResultsScreen extends StatelessWidget {
  const TeiichiResultsScreen({
    super.key,
    required this.placing,
    required this.game,
    required this.player,
    required this.bestBefore,
    this.report,
  });

  final TeiichiPlacing placing;
  final AnkirenGame game;
  final AnkirenPlayer player;
  final Duration? bestBefore;

  /// What was recorded; null when nothing was (see [AnkirenPlayer]).
  final SideTripReport? report;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const trip = SideTrip.teiichi;
    final summary = _Game(s, this);
    final (hero, tiles, rows) = summary.content(context);
    return TripResultsFrame(
      trip: trip,
      report: report,
      child: RunSummary(
        title: s.tripName(trip),
        sub: [s.other.tripName(trip), ...summary.details()].join(' · ').toUpperCase(),
        untracked: !player.recorded,
        hero: hero,
        tiles: tiles,
        rows: rows,
        home: s.done,
        onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
        shout: s.teiichiPlayAgain.toUpperCase(),
        onShout: () => Navigator.of(context).pop(),
      ),
    );
  }
}

typedef _Content = (SummaryHero, List<SummaryTile>, List<Widget>);

/// What a 定位置 game's summary is made of.
class _Game extends TripSummary {
  _Game(S s, this.screen) : super(s, screen.game, unplaced: screen.placing.unplaced);

  final TeiichiResultsScreen screen;

  TeiichiPlacing get placing => screen.placing;
  TeiichiSetup get setup => placing.setup;
  Duration get placingTime => placing.placingTime!;
  bool get recorded => screen.player.recorded;

  /// The header's line after the trip: who played, and the setup.
  List<String> details() {
    final level = setup.level;
    return [
      if (!recorded) s.ankirenGuest,
      if (setup.ranked) s.sideTripRanked else if (level != null) s.ankirenLevelTag(level) else s.ankirenCustom,
      s.cardsCount(asked),
    ];
  }

  _Content content(BuildContext context) {
    final level = setup.level;
    final report = screen.report;
    if (setup.ranked) return _ranked(report);
    if (game.countsStrikes && level != null && report != null) return _level(context, level, report);
    return _found();
  }

  SummaryNote? get _unplacedNote => unplaced.isEmpty ? null : SummaryNote(s.teiichiUnplacedNote(unplaced.length));

  /// A ranked game: its points, with the placing time where 暗記練 says the
  /// top score, as this score has none; a forfeit counts as 0.
  _Content _ranked(SideTripReport? report) {
    final forfeit = !game.completed;
    final score = TeiichiScore(game.answers, placing: placingTime);
    final before = report?.ratingBefore, after = report?.ratingAfter;
    final finds = score.recall - score.karafuda;
    final balloon = after == null
        ? null
        : before == null
            ? s.summaryFirstRating
            : after >= before
                ? s.summaryRatingUp
                : s.summaryNextTime;
    final hero = forfeit
        ? SummaryHero(
            banner: s.ankirenScoreLabel,
            body: HeroWord(s.historyForfeit, sub: Text(s.teiichiCountsAsZero)),
            bar: foundBar(),
            labels: foundLabels(),
            pose: TobiPose.shocked,
            balloon: s.summaryNextTime,
          )
        : SummaryHero(
            banner: s.ankirenScoreLabel,
            body: HeroCount(groupDigits(score.total),
                label: s.summaryPoints, note: s.teiichiPlacedIn(formatMinutes(placingTime))),
            bar: score.total == 0
                ? [BarPart(Palette.paper, 1)]
                : [
                    BarPart(Palette.land, finds, done: true),
                    BarPart(Palette.sun, score.bonus, done: true),
                    if (hasKarafuda) BarPart(KarafudaStyle.bar, score.karafuda, done: true),
                  ],
            labels: [
              if (finds > 0) BarLabel(s.summaryFinds(groupDigits(finds))),
              if (score.bonus > 0) BarLabel(s.teiichiBonusBar(groupDigits(score.bonus)), part: 1),
              if (hasKarafuda && score.karafuda > 0) BarLabel(s.karafudaPoints(groupDigits(score.karafuda)), part: 2),
            ],
            balloon: balloon,
          );
    return (
      hero,
      [
        SummaryTile(
          label: s.teiichiPlacingLabel,
          big: TileFigure(formatMinutes(placingTime)),
          note: forfeit ? s.historyForfeit : s.teiichiBonusNote(TeiichiScore.bonusPercent(placingTime)),
        ),
        firstTapTile(),
        ratingTile(before, after),
      ],
      [
        ...shelfRows([
          CardShelf(s.summarySlowest, Palette.shallow, s.summarySlowestFinds, slowest()),
          CardShelf(s.summaryMissed, Palette.pink, s.summaryNotFound, notFound()),
        ]),
        ...karafudaRow(points: forfeit ? null : score.karafuda),
        ?_unplacedNote,
        SummaryNote(s.teiichiScoreNote),
      ],
    );
  }

  /// A level game of the owner's, whose strikes count.
  _Content _level(BuildContext context, int level, SideTripReport report) {
    final cleared = game.cleared;
    final before = report.ladderBefore, after = report.ladderAfter;
    final allKnown = ProgressScope.of(context).sideTripsHub()[SideTrip.teiichi].rankedLock?.allKnown ?? true;
    final note = cleared
        ? after.rankedReady && !before.rankedReady
            ? allKnown
                ? s.ankirenRankedOpened
                : s.ankirenRankedNeedsAllKnown
            : after.customOpen && !before.customOpen
                ? s.ankirenCustomOpened
                : after.rankedReady
                    ? null
                    : s.teiichiRankedNext(TeiichiTuning.rankedAfterLevel)
        : s.ankirenClearHow(AnkirenTuning.strikesOut);
    return (
      levelHero(level),
      [firstTapTile(), strikesTile(), levelRewardTile(level, report, top: TeiichiLevels.top)],
      [
        firstTapsRow(),
        ...karafudaRow(),
        levelsRow(level, after),
        ?_unplacedNote,
        if (note != null) SummaryNote(note),
      ],
    );
  }

  /// A custom game or a guest's: the cards found with the first tap, the
  /// placing time against the best before it, the wrong taps and the
  /// average find time; the slowest finds and the cards slowest to place.
  _Content _found() {
    final firstTaps = game.firstTries;
    final wrongTaps = game.answers.fold(0, (n, a) => n + a.wrongTaps);
    final wrongCards = game.cardAnswers.where((a) => a.wrongTaps > 0).length;
    final wrongKarafuda = game.karafudaAnswers.where((a) => a.wrongTaps > 0).length;
    final avg = game.averageFirstTryMs;
    return (
      SummaryHero(
        banner: game.completed ? s.ankirenFirstTryLabel : s.endedEarly.toUpperCase(),
        body: HeroCount('$firstTaps', label: s.teiichiRight, note: s.teiichiOfCards(asked)),
        bar: [
          BarPart(Palette.land, firstTaps, done: true),
          BarPart(Palette.sun, late, done: true),
          BarPart(Palette.pink, missed),
        ],
        labels: [
          BarLabel(s.teiichiFirstTapBar(firstTaps)),
          if (late > 0) BarLabel(s.summaryFoundLate(late), part: 1, end: true),
          if (missed > 0) BarLabel(s.summaryMissedCount(missed), part: 2, end: true),
        ],
        pose: missed == 0 ? TobiPose.cheering : TobiPose.standard,
        balloon: missed == 0 ? s.teiichiNiceLayout : s.summarySoClose,
      ),
      [
        _placingTile(),
        SummaryTile(
          label: s.teiichiWrongTaps,
          big: TileFigure('$wrongTaps'),
          note: wrongTaps == 0
              ? s.summaryNone
              : wrongKarafuda > 0
                  ? s.teiichiWrongOnKarafuda(wrongCards, wrongKarafuda)
                  : s.teiichiWrongOn(wrongCards),
        ),
        SummaryTile(
          label: s.teiichiAvgFind,
          big: avg == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(avg), unit: ' s'),
          note: s.ankirenAvgNote,
        ),
      ],
      [
        ...shelfRows([
          CardShelf(s.summarySlowest, Palette.shallow, s.summarySlowestFinds, _slowestFinds()),
          CardShelf(s.teiichiSlowestPlace, Palette.pink, s.teiichiSlowestPlaceNote, _slowestPlaced()),
        ]),
        ...karafudaRow(),
        ?_unplacedNote,
        if (!recorded) SummaryNote(s.teiichiGuestNote) else SummaryNote(s.teiichiCustomNote),
      ],
    );
  }

  SummaryTile _placingTile() => SummaryTile(
        label: s.teiichiPlacingLabel,
        big: TileFigure(formatMinutes(placingTime)),
        note: _bestNote(),
      );

  /// Against the best before this game: a new best, or what it is; for a
  /// guest's game, that it was not saved.
  String _bestNote() {
    if (!recorded) return s.summaryNotSaved;
    final best = screen.bestBefore;
    final counts = setup.full && game.completed && unplaced.isEmpty;
    if (counts && (best == null || placingTime < best)) return s.teiichiNewBest;
    return best == null ? s.teiichiNoBest : s.teiichiYourBest(formatMinutes(best));
  }

  List<SummaryCard> _slowestFinds() {
    final timed = [for (final a in game.cardAnswers) if (a.validTime) a]
      ..sort((a, b) => b.responseUs!.compareTo(a.responseUs!));
    return [
      for (final a in timed.take(SummaryPanelLayout.perLine))
        SummaryCard(a.poemId, ms: a.responseUs! / Duration.microsecondsPerMillisecond),
    ];
  }

  List<SummaryCard> _slowestPlaced() {
    final times = placing.placingTimes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in times.take(SummaryPanelLayout.perLine))
        SummaryCard(e.key, ms: e.value.inMicroseconds / Duration.microsecondsPerMillisecond),
    ];
  }
}
