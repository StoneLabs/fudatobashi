import 'package:flutter/widgets.dart';

import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/rating.dart';
import '../../domain/trainer.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../results/results_screen.dart';

/// Opens the results screen with every celebration queued (a new card with
/// its look-alike warning when one applies, an island complete, a rank-up
/// and a new goal), without touching any progress.
void previewCelebrations(BuildContext context) {
  final progress = ProgressScope.read(context);
  bool unlocked(int id) => progress.trainer.items[ItemKey(id, false)]?.unlocked == true;
  final withKnownTwin = poems.all.where((p) => !unlocked(p.id) && fudaSets.tomofuda(p.id).any(unlocked));
  final card = withKnownTwin.isEmpty ? poems.all.first : withKnownTwin.first;
  final band = Rating.bands[1];
  final report = SessionReport(
    sessionId: null,
    total: null,
    attempts: const [],
    previousBest: null,
    ratingBefore: band.minRating - 1,
    ratingAfter: band.minRating + 1,
    unlocked: [ItemKey(card.id, false)],
    goalRaised: true,
    islandsCompleted: [Trainer.islandOf(card)],
  );
  Navigator.push(
    context,
    MangaRoute<void>(builder: (_) => ResultsScreen(report: report, config: const PlayConfig(mode: PlayMode.training))),
  );
}
