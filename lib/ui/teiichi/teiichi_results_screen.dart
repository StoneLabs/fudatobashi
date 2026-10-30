import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi_placing.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import '../sound/sounds.dart';

/// 定位置's results, on the run summary, upright: the cards found with the
/// first tap out of all; the placing time against the best before it
/// ([bestBefore], the usual game's), the wrong taps and the average find
/// time; the slowest finds and the cards slowest to place; then Play again
/// (back to the 定位置 page) or Done (Home). No score, no rating.
class TeiichiResultsScreen extends StatefulWidget {
  const TeiichiResultsScreen({
    super.key,
    required this.placing,
    required this.game,
    required this.player,
    required this.bestBefore,
  });

  final TeiichiPlacing placing;
  final AnkirenGame game;
  final AnkirenPlayer player;
  final Duration? bestBefore;

  @override
  State<TeiichiResultsScreen> createState() => _TeiichiResultsScreenState();
}

class _TeiichiResultsScreenState extends State<TeiichiResultsScreen> {
  @override
  void initState() {
    super.initState();
    music.enterMenu();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = widget.game;
    final placing = widget.placing;
    final cards = game.prompts.length;
    final firstTaps = game.firstTries;
    final found = game.answers.where((a) => a.found).length;
    final late = found - firstTaps;
    final missed = cards - found;
    final wrongTaps = game.answers.fold(0, (n, a) => n + a.wrongTaps);
    final wrongCards = game.answers.where((a) => a.wrongTaps > 0).length;
    final avg = game.averageFirstTryMs;
    const trip = SideTrip.teiichi;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: SoundCues(
        cues: const [(Sfx.results, Duration.zero)],
        child: RunSummary(
          title: s.tripName(trip),
          sub: [
            s.other.tripName(trip),
            widget.player.recorded ? s.teiichiPractice : s.ankirenGuest,
            s.cardsCount(cards),
          ].join(' · ').toUpperCase(),
          untracked: !widget.player.recorded,
          hero: SummaryHero(
            banner: game.completed ? s.ankirenFirstTryLabel : s.endedEarly.toUpperCase(),
            body: HeroCount('$firstTaps', label: s.teiichiRight, note: s.teiichiOfCards(cards)),
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
          tiles: [
            SummaryTile(
              label: s.teiichiPlacingLabel,
              big: TileFigure(formatMinutes(placing.placingTime!)),
              note: _bestNote(s),
            ),
            SummaryTile(
              label: s.teiichiWrongTaps,
              big: TileFigure('$wrongTaps'),
              note: wrongTaps == 0 ? s.summaryNone : s.teiichiWrongOn(wrongCards),
            ),
            SummaryTile(
              label: s.teiichiAvgFind,
              big: avg == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(avg), unit: ' s'),
              note: s.ankirenAvgNote,
            ),
          ],
          rows: [
            ...shelfRows([
              CardShelf(s.summarySlowest, Palette.shallow, s.summarySlowestFinds, _slowestFinds()),
              CardShelf(s.teiichiSlowestPlace, Palette.pink, s.teiichiSlowestPlaceNote, _slowestPlaced()),
            ]),
            if (!widget.player.recorded) SummaryNote(s.teiichiGuestNote),
          ],
          home: s.done,
          onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
          shout: s.teiichiPlayAgain.toUpperCase(),
          onShout: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Against the best before this game: a new best, or what it is; for a
  /// guest's game, that it was not saved.
  String _bestNote(S s) {
    if (!widget.player.recorded) return s.summaryNotSaved;
    final best = widget.bestBefore;
    final placing = widget.placing;
    final counts = placing.setup.full && widget.game.completed;
    if (counts && (best == null || placing.placingTime! < best)) return s.teiichiNewBest;
    return best == null ? s.teiichiNoBest : s.teiichiYourBest(formatMinutes(best));
  }

  List<SummaryCard> _slowestFinds() {
    final timed = [for (final a in widget.game.answers) if (a.validTime) a]
      ..sort((a, b) => b.responseUs!.compareTo(a.responseUs!));
    return [
      for (final a in timed.take(SummaryPanelLayout.perLine))
        SummaryCard(a.poemId, ms: a.responseUs! / Duration.microsecondsPerMillisecond),
    ];
  }

  List<SummaryCard> _slowestPlaced() {
    final times = widget.placing.placingTimes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in times.take(SummaryPanelLayout.perLine))
        SummaryCard(e.key, ms: e.value.inMicroseconds / Duration.microsecondsPerMillisecond),
    ];
  }
}
