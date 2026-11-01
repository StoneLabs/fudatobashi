import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/level_ladder.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../ankiren/ankiren_strikes.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../sound/sounds.dart';
import 'celebration_sequence.dart';
import 'celebrations.dart';
import 'karafuda_summary.dart';
import 'run_summary.dart';

/// A side trip's results screen around its summary ([child]). A recorded
/// game's celebrations ([ankirenCelebrationsFor]) play over it first, each
/// tap-anywhere-to-skip: the XP it earned and any level it reached, then a
/// ranked game's rating page.
class TripResultsFrame extends StatefulWidget {
  const TripResultsFrame({super.key, required this.trip, required this.report, required this.child});

  final SideTrip trip;

  /// What was recorded; null when nothing was.
  final SideTripReport? report;
  final Widget child;

  @override
  State<TripResultsFrame> createState() => _TripResultsFrameState();
}

class _TripResultsFrameState extends State<TripResultsFrame> {
  late final List<Celebration> _celebrations;
  bool _celebrating = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _celebrations = report == null
        ? const []
        : ankirenCelebrationsFor(report, placementScores: _placementScores(report), trip: widget.trip);
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
  List<int> _placementScores(SideTripReport report) {
    if (report.rankedGames > AnkirenRatingModel.placementGames) return const [];
    final results = ProgressScope.read(context).sideTripsHub()[widget.trip].results;
    return [for (final r in results.take(report.rankedGames)) r.score];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.paper,
        body: SoundCues(
          cues: const [(Sfx.results, Duration.zero)],
          child: Stack(children: [
            widget.child,
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

/// What a side trip's summary is made of, of a [game] of calls: the field's
/// cards counted apart from the からふだ, which only their own row and their
/// part of the score show, so a game without any shows as it always did.
/// [unplaced] are 定位置's cards never placed, which were not called and
/// count as missed.
class TripSummary {
  TripSummary(this.s, this.game, {this.unplaced = const []});

  final S s;
  final AnkirenGame game;
  final List<int> unplaced;

  /// The field's cards, found and missed, the からふだ left out.
  int get asked => game.prompts.length - game.karafuda.length + unplaced.length;
  int get found => game.cardAnswers.where((a) => a.found).length;
  int get missed => asked - found;

  /// Found, but not with the first tap.
  int get late => game.cardAnswers.where((a) => a.found && !a.firstTry).length;

  bool get hasKarafuda => game.karafuda.isNotEmpty;

  /// The からふだ row, for a game that called any.
  List<Widget> karafudaRow({int? points}) => [
        if (hasKarafuda)
          KarafudaSummary.row(
            s,
            game.karafudaTally,
            [for (final a in game.karafudaAnswers) (poemId: a.poemId, found: a.found, wrongTaps: a.wrongTaps)],
            points: points,
          ),
      ];

  List<BarPart> foundBar() => [BarPart(Palette.land, found, done: true), BarPart(Palette.pink, missed)];

  List<BarLabel> foundLabels() => [
        BarLabel(s.summaryFoundCount(found, asked)),
        if (missed > 0) BarLabel(s.summaryMissedCount(missed), end: true),
      ];

  /// A level game's hero: the level over cleared, failed or left, with the
  /// cards found along the bar.
  SummaryHero levelHero(int level) {
    final cleared = game.cleared;
    return SummaryHero(
      banner: s.summaryLevel(level),
      body: cleared
          ? HeroWord(s.summaryClear, outlined: true)
          : game.completed
              ? HeroWord(s.summaryFailed, sub: Text(s.summaryStrikesOut(AnkirenTuning.strikesOut)))
              : HeroWord(s.summaryNotCleared, sub: Text(s.endedEarly)),
      bar: foundBar(),
      labels: foundLabels(),
      pose: cleared ? TobiPose.cheering : TobiPose.tryHard,
      balloon: cleared
          ? null
          : game.completed
              ? s.summarySoClose
              : s.summaryNextTime,
      burst: cleared ? SummaryHeroLayout.burst : null,
    );
  }

  /// A level game's reward tile: the level it opened, else the XP it
  /// earned, saying the next level (at most [top]) is still closed when a
  /// failed game left it so.
  SummaryTile levelRewardTile(int level, SideTripReport report, {required int top}) {
    final xp = report.xp, after = report.ladderAfter;
    final next = level + 1;
    if (!after.allCleared && after.open > report.ladderBefore.open) {
      return SummaryTile(
        label: s.summaryOpenedLabel,
        big: levelFigure(s, after.open),
        note: s.summaryXpGained(groupDigits(xp?.award.total ?? 0)),
      );
    }
    if (!game.cleared && xp != null && xp.levelsGained == 0 && next <= top && !after.isOpen(next)) {
      return SummaryTile(label: s.xpUnit, big: TileFigure('+${groupDigits(xp.award.total)}'), note: s.summaryLevelClosed(next));
    }
    return rewardTile(s, xp);
  }

  SummaryTile firstTapTile() => SummaryTile(
        label: s.ankirenFirstTryLabel,
        big: TileFigure('${game.firstTries}', unit: '/$asked'),
        note: late > 0
            ? s.summaryFoundLate(late)
            : missed > 0
                ? s.summaryMissedCount(missed)
                : s.summaryAllFirstTry,
      );

  SummaryTile strikesTile() {
    const out = AnkirenTuning.strikesOut;
    return SummaryTile(
      label: s.ankirenStrikesFact.toUpperCase(),
      big: AnkirenStrikes(strikes: game.strikes, cardHeight: SummaryTileLayout.strikeCard),
      note: game.strikes == 0 ? s.summaryNone : s.summaryStrikesOf(math.min(game.strikes, out), out),
    );
  }

  SummaryTile avgTile() {
    final avg = game.averageFirstTryMs;
    return SummaryTile(
      label: s.ankirenAvgLabel,
      big: avg == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(avg), unit: ' s'),
      note: s.ankirenAvgNote,
    );
  }

  SummaryTile ratingTile(double? before, double? after) {
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

  /// The cards found, or those not found with the first tap, each saying
  /// how it went.
  SummaryRow firstTapsRow() {
    final notFirst = [
      for (final a in game.cardAnswers)
        if (!a.firstTry)
          a.found
              ? SummaryCard(a.poemId, tag: s.summaryTapTag(a.wrongTaps + 1))
              : SummaryCard(a.poemId, tag: s.summaryMissedTag, tagColor: Palette.pink),
      ..._unplacedCards(),
    ];
    return notFirst.isEmpty
        ? SummaryRow(
            heading: s.ankirenFoundFact,
            accent: Palette.land,
            note: s.summaryAllCards(found),
            child: SummaryCards(foundCards()),
          )
        : SummaryRow(
            heading: s.summaryNotFirstTap,
            accent: Palette.pink,
            note: s.summaryLateMissed(late, missed),
            child: SummaryCards(notFirst),
          );
  }

  /// The levels as [after] leaves them, with [level] just played.
  SummaryRow levelsRow(int level, LevelLadder after) => SummaryRow(
        heading: s.summaryLevels,
        accent: Palette.sun,
        note: game.cleared
            ? after.allCleared
                ? s.ankirenAllCleared
                : s.summaryLevelOpen(after.open)
            : s.ankirenLevelNotCleared(level),
        centered: true,
        child: LevelSquares(ladder: after, level: level, failed: !game.cleared),
      );

  List<SummaryCard> foundCards() => [for (final a in game.cardAnswers) if (a.found) SummaryCard(a.poemId)];

  /// The cards never found, given up or not reached before the game ended,
  /// and those never placed.
  List<SummaryCard> notFound() {
    final found = {for (final a in game.answers) if (a.found) a.poemId};
    return [
      for (final id in game.prompts)
        if (!found.contains(id) && !game.isKarafuda(id)) SummaryCard(id),
      ..._unplacedCards(),
    ];
  }

  List<SummaryCard> _unplacedCards() => [
        for (final id in unplaced) SummaryCard(id, tag: s.teiichiUnplacedTag, tagColor: Palette.pink),
      ];

  List<SummaryCard> slowest() {
    final timed = [for (final a in game.cardAnswers) if (a.validTime) a]..sort((a, b) => b.responseUs!.compareTo(a.responseUs!));
    return [
      for (final a in timed.take(SummaryPanelLayout.perLine))
        SummaryCard(a.poemId, ms: a.responseUs! / Duration.microsecondsPerMillisecond),
    ];
  }
}

/// A side trip's levels as squares: cleared in green, the open one in sun,
/// the one just failed in pink and those still shut dashed and faint.
class LevelSquares extends StatelessWidget {
  const LevelSquares({super.key, required this.ladder, required this.level, required this.failed});

  final LevelLadder ladder;
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

    final rules = ladder.rules;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = rules.first; i <= rules.top; i++) ...[
          if (i > rules.first) const SizedBox(width: SummaryPanelLayout.levelGap),
          square(i),
        ],
      ]),
    );
  }
}
