import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../results/run_summary.dart';
import '../sound/sounds.dart';
import 'ankiren_strikes.dart';

/// 暗記練's results, on the run summary: a ranked game's score, a free-play
/// level cleared or failed, or else the cards found; the first-tap finds,
/// the strikes (or a ranked game's average time) and the reward; the cards
/// that were slow, late or missed, a level game's levels and what clearing
/// opens; then Back to the AnkiRen page or Done (Home). A recorded game's
/// celebrations play over it first, each tap-anywhere-to-skip: the XP it
/// earned and any level it reached, then a ranked game's rating page.
class AnkirenResultsScreen extends StatefulWidget {
  const AnkirenResultsScreen({super.key, required this.game, required this.report, required this.player});

  final AnkirenGame game;

  /// What was recorded; null when nothing was (see [AnkirenPlayer]).
  final AnkirenReport? report;
  final AnkirenPlayer player;

  @override
  State<AnkirenResultsScreen> createState() => _AnkirenResultsScreenState();
}

class _AnkirenResultsScreenState extends State<AnkirenResultsScreen> {
  late final List<Celebration> _celebrations;
  bool _celebrating = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _celebrations = report == null ? const [] : ankirenCelebrationsFor(report, placementScores: _placementScores(report));
    if (_celebrations.isNotEmpty) {
      // Kept silent (the game already faded the music out) until the
      // celebration, which has its own jingles, is done; and upright, as
      // its pages are laid out for, after a game played in landscape too.
      music.leaveMenu();
      unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));
      _timer = Timer(ResultsLayout.overlayStagger, () {
        if (mounted) setState(() => _celebrating = true);
      });
    } else {
      music.enterMenu();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_celebrations.isNotEmpty && !_celebrated) _releaseOrientation();
    super.dispose();
  }

  /// The celebration has played to its end.
  bool _celebrated = false;

  static void _releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));

  /// The placement games' scores so far, when [report]'s game is one of
  /// them.
  List<int> _placementScores(AnkirenReport report) {
    if (report.rankedGames > AnkirenRatingModel.placementGames) return const [];
    final results = ProgressScope.read(context).sideTripsHub()[SideTrip.ankiren].results;
    return [for (final r in results.take(report.rankedGames)) r.score];
  }

  void _done() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = _Game(s, widget.game, widget.report, widget.player);
    final (hero, tiles, rows) = game.content(context);
    return Scaffold(
      backgroundColor: Palette.paper,
      body: SoundCues(
        cues: const [(Sfx.results, Duration.zero)],
        child: Stack(children: [
          RunSummary(
            title: s.tripName(SideTrip.ankiren),
            sub: [s.other.tripName(SideTrip.ankiren), ...game.details()].join(' · ').toUpperCase(),
            untracked: !widget.player.recorded,
            hero: hero,
            tiles: tiles,
            rows: rows,
            home: s.done,
            onHome: _done,
            shout: s.ankirenBackToPage.toUpperCase(),
            onShout: () => Navigator.of(context).pop(),
          ),
          if (_celebrating)
            Positioned.fill(
              child: CelebrationSequence(
                pages: _celebrations,
                onDone: () {
                  setState(() {
                    _celebrating = false;
                    _celebrated = true;
                  });
                  music.enterMenu();
                  _releaseOrientation();
                },
              ),
            ),
        ]),
      ),
    );
  }
}

typedef _Content = (SummaryHero, List<SummaryTile>, List<Widget>);

/// What a 暗記練 game's summary is made of.
class _Game {
  _Game(this.s, this.game, this.report, this.player);

  final S s;
  final AnkirenGame game;
  final AnkirenReport? report;
  final AnkirenPlayer player;

  AnkirenSetup get setup => game.setup;
  int get asked => game.prompts.length;
  int get found => game.answers.where((a) => a.found).length;
  int get missed => asked - found;

  /// Found, but not with the first tap.
  int get late => game.answers.where((a) => a.found && !a.firstTry).length;

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
          BarPart(Palette.land, score.recall, done: true),
          BarPart(Palette.sun, score.early, done: true),
          BarPart(Palette.paper, math.max(0, score.max - score.total)),
        ],
        labels: [
          BarLabel(s.summaryFinds(groupDigits(score.recall))),
          if (score.early > 0) BarLabel(s.summaryEarly(groupDigits(score.early)), part: 1),
        ],
        balloon: after == null
            ? null
            : before == null
                ? s.summaryFirstRating
                : after >= before
                    ? s.summaryRatingUp
                    : s.summaryNextTime,
      ),
      [_firstTapTile(), _avgTile(), _ratingTile(before, after)],
      shelfRows([
        CardShelf(s.summarySlowest, Palette.shallow, s.summarySlowestFinds, _slowest()),
        CardShelf(s.summaryMissed, Palette.pink, s.summaryNotFound, _notFound()),
      ]),
    );
  }

  /// A free-play level game of the owner's, whose strikes count.
  _Content _level(BuildContext context, int level, AnkirenReport report) {
    final cleared = game.cleared;
    final before = report.ladderBefore, after = report.ladderAfter;
    final opened = !after.allCleared && after.open > before.open;
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
    final xp = report.xp;
    final next = level + 1;
    final SummaryTile reward = opened
        ? SummaryTile(
            label: s.summaryOpenedLabel,
            big: levelFigure(s, after.open),
            note: s.summaryXpGained(groupDigits(xp?.award.total ?? 0)),
          )
        : !cleared && xp != null && xp.levelsGained == 0 && next <= AnkirenLevels.top && !after.isOpen(next)
            ? SummaryTile(label: s.xpUnit, big: TileFigure('+${groupDigits(xp.award.total)}'), note: s.summaryLevelClosed(next))
            : rewardTile(s, xp);
    final notFirst = [
      for (final a in game.answers)
        if (!a.firstTry)
          a.found
              ? SummaryCard(a.poemId, tag: s.summaryTapTag(a.wrongTaps + 1))
              : SummaryCard(a.poemId, tag: s.summaryMissedTag, tagColor: Palette.pink),
    ];
    return (
      SummaryHero(
        banner: s.summaryLevel(level),
        body: cleared
            ? HeroWord(s.summaryClear, outlined: true)
            : game.completed
                ? HeroWord(s.summaryFailed, sub: Text(s.summaryStrikesOut(out)))
                : HeroWord(s.summaryNotCleared, sub: Text(s.endedEarly)),
        bar: _foundBar(),
        labels: _foundLabels(),
        pose: cleared ? TobiPose.cheering : TobiPose.tryHard,
        balloon: cleared
            ? null
            : game.completed
                ? s.summarySoClose
                : s.summaryNextTime,
        burst: cleared ? SummaryHeroLayout.burst : null,
      ),
      [_firstTapTile(), _strikesTile(), reward],
      [
        notFirst.isEmpty
            ? SummaryRow(
                heading: s.ankirenFoundFact,
                accent: Palette.land,
                note: s.summaryAllCards(found),
                child: SummaryCards(_foundCards()),
              )
            : SummaryRow(
                heading: s.summaryNotFirstTap,
                accent: Palette.pink,
                note: s.summaryLateMissed(late, missed),
                child: SummaryCards(notFirst),
              ),
        SummaryRow(
          heading: s.summaryLevels,
          accent: Palette.sun,
          note: cleared
              ? after.allCleared
                  ? s.ankirenAllCleared
                  : s.summaryLevelOpen(after.open)
              : s.ankirenLevelNotCleared(level),
          centered: true,
          child: _Levels(ladder: after, level: level, failed: !cleared),
        ),
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
        bar: _foundBar(),
        labels: _foundLabels(),
        pose: missed == 0 ? TobiPose.cheering : TobiPose.standard,
        balloon: missed == 0 ? s.summaryNice : s.summarySoClose,
      ),
      [_firstTapTile(), _strikesTile(), rewardTile(s, report?.xp)],
      [
        ...shelfRows([
          CardShelf(s.ankirenFoundFact, Palette.land, s.summaryAllCards(found), _foundCards()),
          CardShelf(s.summaryMissed, Palette.pink, s.summaryNotFound, _notFound()),
        ]),
        if (note != null) SummaryNote(note),
      ],
    );
  }

  List<BarPart> _foundBar() => [BarPart(Palette.land, found, done: true), BarPart(Palette.pink, missed)];

  List<BarLabel> _foundLabels() => [
        BarLabel(s.summaryFoundCount(found, asked)),
        if (missed > 0) BarLabel(s.summaryMissedCount(missed), end: true),
      ];

  SummaryTile _firstTapTile() => SummaryTile(
        label: s.ankirenFirstTryLabel,
        big: TileFigure('${game.firstTries}', unit: '/$asked'),
        note: late > 0
            ? s.summaryFoundLate(late)
            : missed > 0
                ? s.summaryMissedCount(missed)
                : s.summaryAllFirstTry,
      );

  SummaryTile _strikesTile() {
    const out = AnkirenTuning.strikesOut;
    return SummaryTile(
      label: s.ankirenStrikesFact.toUpperCase(),
      big: AnkirenStrikes(strikes: game.strikes, cardHeight: SummaryTileLayout.strikeCard),
      note: game.strikes == 0 ? s.summaryNone : s.summaryStrikesOf(math.min(game.strikes, out), out),
    );
  }

  SummaryTile _avgTile() {
    final avg = game.averageFirstTryMs;
    return SummaryTile(
      label: s.ankirenAvgLabel,
      big: avg == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(avg), unit: ' s'),
      note: s.ankirenAvgNote,
    );
  }

  SummaryTile _ratingTile(double? before, double? after) {
    if (after == null) return SummaryTile(label: s.ratingLabel, big: const TileFigure(missingTime), note: s.summaryNotSaved);
    final band = s.className(Rating.bandOf(after));
    if (before == null) {
      return SummaryTile(label: s.ratingLabel, big: TileFigure(groupDigits(after.round())), note: '${s.ratingFirst} · $band');
    }
    final delta = (after - before).round();
    return SummaryTile(
      label: s.ratingLabel,
      big: TileFigure(delta >= 0 ? '+$delta' : groupDigits(delta)),
      note: '${groupDigits(before.round())} → ${groupDigits(after.round())} · $band',
    );
  }

  List<SummaryCard> _foundCards() => [for (final a in game.answers) if (a.found) SummaryCard(a.poemId)];

  /// The cards never found, given up or not reached before the game ended.
  List<SummaryCard> _notFound() {
    final found = {for (final a in game.answers) if (a.found) a.poemId};
    return [for (final id in game.prompts) if (!found.contains(id)) SummaryCard(id)];
  }

  List<SummaryCard> _slowest() {
    final timed = [for (final a in game.answers) if (a.validTime) a]..sort((a, b) => b.responseUs!.compareTo(a.responseUs!));
    return [
      for (final a in timed.take(SummaryPanelLayout.perLine))
        SummaryCard(a.poemId, ms: a.responseUs! / Duration.microsecondsPerMillisecond),
    ];
  }
}

/// 暗記練's levels as squares: cleared in green, the open one in sun, the
/// one just failed in pink and those still shut dashed and faint.
class _Levels extends StatelessWidget {
  const _Levels({required this.ladder, required this.level, required this.failed});

  final AnkirenLadder ladder;
  final int level;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    Widget square(int i) {
      final number = Text('$i',
          style: const TextStyle(fontFamily: Fonts.display, fontSize: SummaryPanelLayout.levelFont, height: 1));
      final fill = ladder.isCleared(i)
          ? Palette.land
          : i == level && failed
              ? Palette.pinkSoft
              : ladder.isOpen(i)
                  ? Palette.sun
                  : null;
      return SizedBox.square(
        dimension: SummaryPanelLayout.level,
        child: fill == null
            ? Opacity(
                opacity: SummaryPanelLayout.shutOpacity,
                child: DashedBox(
                  border: SummaryPanelLayout.levelBorder,
                  dash: Strokes.fineDash,
                  child: Center(child: number),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                    color: fill, border: Border.all(color: Palette.ink, width: SummaryPanelLayout.levelBorder)),
                child: Center(child: number),
              ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i <= AnkirenLevels.top; i++) ...[
          if (i > 0) const SizedBox(width: SummaryPanelLayout.levelGap),
          square(i),
        ],
      ]),
    );
  }
}
