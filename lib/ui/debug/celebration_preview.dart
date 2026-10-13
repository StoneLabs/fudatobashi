import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/play_session.dart';
import '../../domain/rating.dart';
import '../../domain/xp.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/side_trips.dart';
import '../manga/manga.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../results/results_screen.dart';
import '../shell/tab_chains.dart';
import '../side_trips/dojo_scene.dart';

/// Plays every celebration in a row without touching any progress: a new
/// card with its look-alike warning when one applies, then Results for a
/// personal best that earns the mock's island complete, a new goal,
/// graduation, its XP and two new levels, and a rating breaking through
/// into a rank-up.
void previewCelebrations(BuildContext context) {
  final progress = ProgressScope.read(context);
  final withKnownTwin = poems.all.where((p) => !progress.knows(p.id) && fudaSets.tomofuda(p.id).any(progress.knows));
  final card = withKnownTwin.isEmpty ? poems.all.first : withKnownTwin.first;
  Navigator.push(
    context,
    MangaRoute<void>(
      builder: (context) => Scaffold(
        backgroundColor: Palette.paper,
        body: CelebrationSequence(
          pages: introductionOf(card.id, knows: progress.knows),
          onDone: () => Navigator.pushReplacement(
            context,
            MangaRoute<void>(
              builder: (_) => ResultsScreen(report: _report(card.id), config: const PlayConfig(mode: PlayMode.training)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The XP page for a typical round, reaching no new level.
void previewXp(BuildContext context) => _previewPages(context, [XpCelebration(previewXpGain(levelUp: false))]);

/// The XP page crossing two new levels, then the level-up.
void previewXpLevelUp(BuildContext context) {
  final gain = previewXpGain();
  _previewPages(context, [XpCelebration(gain), LevelUpCelebration(gain)]);
}

/// The rating page for a run that raised the rating within its class.
void previewRating(BuildContext context) {
  final before = Rating.bands[CelebrationPreviewTuning.rankFrom].minRating + CelebrationPreviewTuning.ratingInto;
  _previewPages(context, [RatingCelebration(before, before + CelebrationPreviewTuning.ratingGain)]);
}

/// The rating breaking through into the next class, then the rank-up.
void previewRatingRankUp(BuildContext context) {
  final (before, after) = _rankUpRatings;
  _previewPages(context, [
    RatingCelebration(before, after),
    RankUpCelebration(Rating.bandOf(before), Rating.bandOf(after), before, after),
  ]);
}

/// Ratings either side of the threshold above `Rating.bands[rankFrom]`.
(double, double) get _rankUpRatings {
  final threshold = Rating.bands[CelebrationPreviewTuning.rankFrom + 1].minRating;
  return (threshold - CelebrationPreviewTuning.rankBelow, threshold + CelebrationPreviewTuning.rankAbove);
}

void previewGraduation(BuildContext context) => _previewPages(context, const [GraduationCelebration()]);

/// 暗記練's XP page for a ranked game, reaching no new level, or with
/// [levelUp] reaching one, then the level-up.
void previewAnkirenXp(BuildContext context, {bool levelUp = false}) {
  final gain = XpGain(
    before: XpCurve.reach(CelebrationPreviewTuning.ankirenLevel) +
        (levelUp ? CelebrationPreviewTuning.ankirenLevelInto : CelebrationPreviewTuning.ankirenRoundInto),
    award: XpAward([for (final (source, count, xp) in CelebrationPreviewTuning.ankirenXp) XpPart(source, count, xp)]),
  );
  _previewPages(context, xpCelebrations(gain));
}

/// 暗記練's rating page after a ranked game in [moment], then 暗記練's own
/// rank-up after a breakthrough.
void previewAnkirenRating(BuildContext context, AnkirenRatingMoment moment) {
  final floor = Rating.bands[CelebrationPreviewTuning.ankirenClass].minRating;
  final into = floor + CelebrationPreviewTuning.ankirenInto;
  const move = CelebrationPreviewTuning.ankirenMove, cross = CelebrationPreviewTuning.ankirenCross;
  const scores = CelebrationPreviewTuning.ankirenPlacementScores;
  final (before, after, game) = switch (moment) {
    AnkirenRatingMoment.placing => (AnkirenRating.start, CelebrationPreviewTuning.ankirenPlacing, 1),
    AnkirenRatingMoment.placed => (
        CelebrationPreviewTuning.ankirenPlacing,
        CelebrationPreviewTuning.ankirenPlaced,
        AnkirenRatingModel.placementGames,
      ),
    AnkirenRatingMoment.up => (into, into + move, CelebrationPreviewTuning.ankirenGame),
    AnkirenRatingMoment.held => (into, into, CelebrationPreviewTuning.ankirenGame),
    AnkirenRatingMoment.down => (into + move, into, CelebrationPreviewTuning.ankirenGame),
    AnkirenRatingMoment.rankUp => (floor - cross, floor + cross, CelebrationPreviewTuning.ankirenGame),
    AnkirenRatingMoment.rankDown => (floor + cross, floor - cross, CelebrationPreviewTuning.ankirenGame),
  };
  final report = AnkirenReport(ratingBefore: before, ratingAfter: after, rankedGames: game);
  _previewPages(context, ankirenCelebrationsFor(report, placementScores: scores.take(game).toList()));
}

/// 暗記練's first opening on the Side Trips hub: its torii rattles, the
/// chains break and the gate snaps open, with the sound, buzz and toast.
/// The hub's latch is not read or changed.
void previewAnkirenUnlock(BuildContext context) => Navigator.push(
      context,
      MangaRoute<void>(
        builder: (_) => const Scaffold(
          backgroundColor: Palette.paper,
          body: DojoScene(
            turn: kAlwaysDismissedAnimation,
            fade: kAlwaysCompleteAnimation,
            fadeFrom: 0,
            gate: GateState.opening,
          ),
        ),
      ),
    );

/// The Side Trips tab's chains breaking on a tab bar, with the unlock
/// toast. The tab latch is not read or changed.
void previewSideTripsTabUnlock(BuildContext context) {
  final s = S.of(context);
  Navigator.push(
    context,
    MangaRoute<void>(
      builder: (context) => Scaffold(
        backgroundColor: Palette.paper,
        body: const SizedBox.expand(),
        bottomNavigationBar: MangaTabBar(
          current: 0,
          onSelect: (_) {},
          tabs: [
            MangaTab(icon: IconArt.sideTrips, label: s.sideTrips, cover: const TabChains(breaking: true)),
          ],
        ),
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) MangaToast.show(context, s.tabUnlocked(s.sideTrips));
  });
}

/// Plays [pages] as after a run, then comes back.
void _previewPages(BuildContext context, List<Celebration> pages) => Navigator.push(
      context,
      MangaRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Palette.paper,
          body: CelebrationSequence(pages: pages, onDone: () => Navigator.pop(context)),
        ),
      ),
    );

/// A mock run's XP: every source, reaching two new levels, or with
/// [levelUp] false a typical round that reaches none.
XpGain previewXpGain({bool levelUp = true}) {
  final (lines, into) = levelUp
      ? (CelebrationPreviewTuning.xp, CelebrationPreviewTuning.levelInto)
      : (CelebrationPreviewTuning.xpRound, CelebrationPreviewTuning.roundInto);
  return XpGain(
    before: XpCurve.reach(CelebrationPreviewTuning.level) + into,
    award: XpAward([for (final (source, count, xp) in lines) XpPart(source, count, xp)]),
  );
}

SessionReport _report(int newCard) {
  final (ratingBefore, ratingAfter) = _rankUpRatings;
  final now = DateTime.now();
  return SessionReport(
    sessionId: null,
    completed: true,
    total: CelebrationPreviewTuning.total,
    attempts: [
      for (final (i, poem) in poems.all.take(CelebrationPreviewTuning.cards).indexed)
        Attempt(
          index: i,
          card: CardRef(poem.id),
          responseUs: CelebrationPreviewTuning.averageUs + ((2 * i + 1 - CelebrationPreviewTuning.cards) * CelebrationPreviewTuning.spreadUs) ~/ 2,
          outcome: Outcome.known,
          at: now,
          deckSize: CelebrationPreviewTuning.cards,
        ),
    ],
    previousBest: CelebrationPreviewTuning.previousBest,
    ratingBefore: ratingBefore,
    ratingAfter: ratingAfter,
    goalRaised: true,
    newCards: [newCard],
    islandsCompleted: const [CelebrationPreviewTuning.island],
    graduated: true,
    xp: previewXpGain(),
  );
}
