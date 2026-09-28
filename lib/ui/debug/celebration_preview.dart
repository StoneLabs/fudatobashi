import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/rating.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';

/// The mock's island for the island-complete page.
const _previewIsland = 2;

/// The mock's rank-up: F上級 to E下級, gaining this many points.
const _previewRankFrom = 2;
const _previewRankGain = 26;

/// Plays every celebration page in a row (a new card with its look-alike
/// warning when one applies, the mock's island complete, a rank-up and a new
/// goal), without touching any progress.
void previewCelebrations(BuildContext context) {
  final progress = ProgressScope.read(context);
  final withKnownTwin = poems.all.where((p) => !progress.knows(p.id) && fudaSets.tomofuda(p.id).any(progress.knows));
  final card = withKnownTwin.isEmpty ? poems.all.first : withKnownTwin.first;
  final before = Rating.bands[_previewRankFrom], after = Rating.bands[_previewRankFrom + 1];
  final pages = [
    ...introductionOf(card.id, knows: progress.knows),
    const IslandCompleteCelebration(_previewIsland),
    RankUpCelebration(before, after, after.minRating - _previewRankGain / 2, after.minRating + _previewRankGain / 2),
    const GoalUpCelebration(),
  ];
  Navigator.push(
    context,
    MangaRoute<void>(
      builder: (context) => ColoredBox(
        color: Palette.paper,
        child: CelebrationSequence(pages: pages, onDone: () => Navigator.pop(context)),
      ),
    ),
  );
}
