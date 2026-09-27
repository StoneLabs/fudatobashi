import '../../data/fuda_sets.dart';
import '../../domain/card_stats.dart';
import '../../domain/rating.dart';
import '../../state/progress.dart';

/// One post-run celebration overlay's data. [celebrationsFor] orders them:
/// new cards, island completions, a rank-up, then a new speed goal.
sealed class Celebration {
  const Celebration();
}

class NewCardCelebration extends Celebration {
  const NewCardCelebration(this.poemId, this.twins);
  final int poemId;

  /// Confusable siblings (友札), for naming the twin the player must now tell
  /// this card apart from.
  final List<int> twins;
}

/// A newly unlocked card shares a 決まり字 confusable set with card(s) the
/// player already knows: a heads-up to tell them apart, shown right after
/// that card's [NewCardCelebration].
class ConfusableWarningCelebration extends Celebration {
  const ConfusableWarningCelebration(this.poemId, this.knownSiblings);
  final int poemId;

  /// Already-unlocked confusable siblings (excludes cards unlocked in this
  /// same run).
  final List<int> knownSiblings;
}

class IslandCompleteCelebration extends Celebration {
  const IslandCompleteCelebration(this.islandIndex);
  final int islandIndex;
}

class RankUpCelebration extends Celebration {
  const RankUpCelebration(this.before, this.after, this.ratingBefore, this.ratingAfter);
  final RankBand before;
  final RankBand after;
  final double ratingBefore;
  final double ratingAfter;
}

class GoalUpCelebration extends Celebration {
  const GoalUpCelebration();
}

List<Celebration> celebrationsFor(SessionReport report, Progress progress) {
  final list = <Celebration>[];
  final seenPoems = <int>{};
  final freshPoemIds = {for (final k in report.unlocked) k.poemId};
  for (final k in report.unlocked) {
    if (!seenPoems.add(k.poemId)) continue;
    list.add(NewCardCelebration(k.poemId, fudaSets.tomofuda(k.poemId)));
    final knownSiblings = fudaSets
        .tomofuda(k.poemId)
        .where((id) => !freshPoemIds.contains(id) && progress.trainer.items[ItemKey(id, false)]?.unlocked == true)
        .toList();
    if (knownSiblings.isNotEmpty) list.add(ConfusableWarningCelebration(k.poemId, knownSiblings));
  }
  for (final i in report.islandsCompleted) {
    list.add(IslandCompleteCelebration(i));
  }
  if (report.ratingAfter != null) {
    final before = report.ratingBefore == null ? Rating.bands.first : Rating.bandOf(report.ratingBefore!);
    final after = Rating.bandOf(report.ratingAfter!);
    if (Rating.bands.indexOf(after) > Rating.bands.indexOf(before)) {
      list.add(RankUpCelebration(before, after, report.ratingBefore ?? report.ratingAfter!, report.ratingAfter!));
    }
  }
  if (report.goalRaised) list.add(const GoalUpCelebration());
  return list;
}
