import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../rank/rank_badges.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../run/run_launcher.dart';
import '../sound/sounds.dart';

/// 暗記練's results: the score on a sunburst (for a custom game, which is not
/// scored, the cards found and missed), the cards found with the first tap
/// and their average time, and for a ranked game how the rating moved
/// and the level the next one plays; then Again (the same way: ranked reads
/// its level afresh, free play replays the setup) or Done. A recorded game's
/// celebrations play over it first, each tap-anywhere-to-skip: the XP it
/// earned and any level it reached, then a ranked game's rating page.
class AnkirenResultsScreen extends StatefulWidget {
  const AnkirenResultsScreen({super.key, required this.game, required this.report, required this.tracked});

  final AnkirenGame game;

  /// What was recorded; null for the untracked test game.
  final AnkirenReport? report;
  final bool tracked;

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
      unawaited(SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]));
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

  static void _releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(const []));

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
    final game = widget.game;
    final setup = game.setup;
    final score = game.score;
    final report = widget.report;
    final avgMs = game.averageFirstTryMs;
    final found = game.answers.where((a) => a.found).length;
    final asked = game.prompts.length;
    final level = setup.level;
    final tag = [
      SideTrip.ankiren.label,
      if (!widget.tracked) s.untracked else if (setup.ranked) s.sideTripRanked else s.freePlay,
      level == null ? s.ankirenCustomTag(setup.perSide, formatMinutes(setup.memorise)) : s.ankirenLevelTag(level),
    ].join(' · ');

    return Scaffold(
      backgroundColor: Palette.paper,
      body: SoundCues(
        cues: const [(Sfx.results, Duration.zero)],
        child: Stack(children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: HeaderStyle.topGap),
                Row(children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(fit: BoxFit.scaleDown, child: InkTag(tag)),
                    ),
                  ),
                  const SizedBox(width: Gaps.panel),
                  InkIconButton(icon: IconArt.close, semanticLabel: s.done, onTap: _done),
                ]),
                const SizedBox(height: Gaps.section),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (score == null)
                        _SplashPanel(
                          label: game.completed ? s.ankirenFoundLabel : s.endedEarly,
                          big: found,
                          lines: [s.ankirenFoundOf(asked), s.ankirenMissed(asked - found)],
                          cheer: found == asked,
                        )
                      else
                        _SplashPanel(
                          label: game.completed ? s.ankirenScoreLabel : s.endedEarly,
                          big: score.total,
                          lines: [s.ankirenScoreOf(score.max), if (score.early > 0) s.ankirenEarlyBonus(score.early)],
                          cheer: score.fraction >= AnkirenRatingModel.par,
                        ),
                      const SizedBox(height: Gaps.panel),
                      IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(
                            child: _Stat(
                              label: s.ankirenFirstTryLabel,
                              big: '${game.firstTries}',
                              unit: '/ $asked',
                              note: s.ankirenWrongTaps(game.answers.fold(0, (n, a) => n + a.wrongTaps)),
                            ),
                          ),
                          const SizedBox(width: Gaps.panel),
                          Expanded(
                            child: _Stat(
                              label: s.ankirenAvgLabel,
                              big: avgMs == null ? missingTime : (avgMs / 1000).toStringAsFixed(2),
                              unit: avgMs == null ? null : 's',
                              note: s.ankirenAvgNote,
                            ),
                          ),
                        ]),
                      ),
                      if (report?.ratingAfter != null) ...[
                        const SizedBox(height: Gaps.panel),
                        _RatingPanel(before: report!.ratingBefore!, after: report.ratingAfter!),
                      ] else if (widget.tracked && !setup.ranked) ...[
                        const SizedBox(height: Gaps.panel),
                        DashedBox(
                          padding: ResultsLayout.notePadding,
                          child: Text.rich(Phrases.span(score == null ? s.ankirenCustomNote : s.ankirenFreeNote),
                              style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenResultsLayout.noteFont)),
                        ),
                      ],
                      const SizedBox(height: Gaps.section),
                    ]),
                  ),
                ),
                const SizedBox(height: Gaps.section),
                SizedBox(
                  height: ResultsLayout.actionRowHeight,
                  child: Row(children: [
                    Expanded(
                        child: ActionRowButton(icon: IconArt.home, label: s.done, sub: s.ankirenDoneSub, onTap: _done)),
                    const SizedBox(width: PlayLayout.buttonGap),
                    Expanded(
                      flex: 2,
                      child: ActionRowButton(
                        icon: IconArt.refresh,
                        label: s.again,
                        sub: s.ankirenAgainSub,
                        color: Palette.pink,
                        onTap: () => ankirenAgain(context, setup, tracked: widget.tracked),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Gaps.section),
              ]),
            ),
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

/// A [big] number on a sunburst, its [label] over it and its [lines] under
/// it, with Tobi cheering when [cheer]: a game at or above par, or a custom
/// game with every card found.
class _SplashPanel extends StatelessWidget {
  const _SplashPanel({required this.label, required this.big, required this.lines, required this.cheer});

  final String label;
  final int big;
  final List<String> lines;
  final bool cheer;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      MangaPanel(
        shape: const PanelShape(bottomRight: Offset(0, ResultsLayout.splashCut)),
        art: const [
          RadialLayer(center: Backdrops.skyCenter, colors: Backdrops.skyColors, stops: Backdrops.skyStops),
          BurstLayer(ResultsLayout.splashBurst),
        ],
        padding: AnkirenResultsLayout.splashPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AnkirenResultsLayout.splashMinHeight),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: ResultsLayout.splashLabelFont,
                      letterSpacing: ResultsLayout.splashLabelTracking * ResultsLayout.splashLabelFont)),
              const SizedBox(height: Gaps.small),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedText('$big',
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenResultsLayout.scoreFont, height: 1),
                    outlineWidth: AnkirenResultsLayout.scoreOutline),
              ),
              const SizedBox(height: Gaps.tight),
              for (final (i, line) in lines.indexed)
                Text(line,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: i == 0 ? Weights.black : Weights.bold, fontSize: AnkirenResultsLayout.scoreOfFont)),
            ]),
          ),
        ),
      ),
      Positioned(
        right: Gaps.inner,
        bottom: Gaps.inner,
        width: AnkirenResultsLayout.tobi.width,
        height: AnkirenResultsLayout.tobi.height,
        child: Tobi(pose: cheer ? TobiPose.cheering : TobiPose.tryHard),
      ),
    ]);
  }
}

/// A number with its label over it and a note under it.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.big, required this.unit, required this.note});
  final String label, big, note;
  final String? unit;

  @override
  Widget build(BuildContext context) => MangaPanel(
        color: Palette.seaSoft,
        tone: Tones.sea,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.panelWide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OneLine(Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: ResultsLayout.statLabelFont,
                    letterSpacing: ResultsLayout.statLabelTracking * ResultsLayout.statLabelFont))),
            _OneLine(Text.rich(TextSpan(children: [
              TextSpan(
                  text: big,
                  style: const TextStyle(
                      fontFamily: Fonts.display, fontSize: ResultsLayout.statBigFont, height: TypeScale.displayLineHeight)),
              if (unit != null)
                TextSpan(
                    text: ' $unit',
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.statBigUnitFont, height: 1)),
            ]))),
            _OneLine(Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.statNoteFont))),
          ],
        ),
      );
}

/// A ranked game's rating change, its class on the main rank's ladder, and
/// what comes next: a placement game, and the level of the next one.
class _RatingPanel extends StatelessWidget {
  const _RatingPanel({required this.before, required this.after});
  final double before, after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final delta = (after - before).round();
    final band = Rating.bandOf(after);
    final rung = rungStyle(band.id);
    final games = progress.sideTrips.rankedGames(SideTrip.ankiren);
    final next = progress.sideTripsHub()[SideTrip.ankiren].rankedLevel;
    const noteStyle = TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.statNoteFont);
    return MangaPanel(
      color: Palette.pinkSoft,
      tone: Tones.pink,
      padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.panelWide),
      child: Row(children: [
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _OneLine(Text(s.ratingLabel,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: ResultsLayout.statLabelFont,
                    letterSpacing: ResultsLayout.statLabelTracking * ResultsLayout.statLabelFont))),
            _OneLine(Text(
              delta >= 0 ? '+$delta' : '$delta',
              style: const TextStyle(
                  fontFamily: Fonts.display, fontSize: ResultsLayout.statBigFont, height: TypeScale.displayLineHeight),
            )),
            _OneLine(Text('${before.round()} → ${after.round()} · ${band.label}', style: noteStyle)),
            if (games <= AnkirenRatingModel.placementGames)
              _OneLine(Text(s.ankirenPlacement(games, AnkirenRatingModel.placementGames), style: noteStyle)),
            if (next != null) _OneLine(Text(s.ankirenNextLevel(next), style: noteStyle)),
          ]),
        ),
        const SizedBox(width: Gaps.panel),
        ClassBadge(band, color: rung.color, textColor: rung.text),
      ]),
    );
  }
}

/// One line that shrinks rather than wraps.
class _OneLine extends StatelessWidget {
  const _OneLine(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
}
