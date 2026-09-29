import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../../domain/rating.dart';
import '../../domain/xp.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../results/results_screen.dart';

/// Plays every celebration in a row without touching any progress: a new
/// card with its look-alike warning when one applies, then Results for a
/// personal best that earns the mock's island complete, a rank-up, a new
/// goal, graduation, its XP and two new levels.
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

/// The mock run's XP: every source, reaching two new levels.
XpGain previewXpGain() => XpGain(
      before: XpCurve.reach(CelebrationPreviewTuning.level) + CelebrationPreviewTuning.levelInto,
      award: XpAward([for (final (source, count, xp) in CelebrationPreviewTuning.xp) XpPart(source, count, xp)]),
    );

SessionReport _report(int newCard) {
  final after = Rating.bands[CelebrationPreviewTuning.rankFrom + 1];
  final now = DateTime.now();
  return SessionReport(
    sessionId: null,
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
    ratingBefore: after.minRating - CelebrationPreviewTuning.rankGain / 2,
    ratingAfter: after.minRating + CelebrationPreviewTuning.rankGain / 2,
    goalRaised: true,
    newCards: [newCard],
    islandsCompleted: const [CelebrationPreviewTuning.island],
    graduated: true,
    xp: previewXpGain(),
  );
}
