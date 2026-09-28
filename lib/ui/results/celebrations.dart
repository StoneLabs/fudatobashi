import '../../data/fuda_sets.dart';
import '../../domain/rating.dart';
import '../../state/progress.dart';

/// One celebration page's data. A new card is introduced during the run
/// ([introductionOf]); the rest follow it ([celebrationsFor]).
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

/// A new card shares a 決まり字 confusable set with card(s) the player
/// already knows: a heads-up to tell them apart, shown right after that
/// card's [NewCardCelebration].
class ConfusableWarningCelebration extends Celebration {
  const ConfusableWarningCelebration(this.poemId, this.knownSiblings);
  final int poemId;

  /// Confusable siblings the player already knows.
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

/// The pages introducing new card [poemId] right before it first appears:
/// the card itself, then a look-alike warning if the player [knows] one of
/// its confusable siblings.
List<Celebration> introductionOf(int poemId, {required bool Function(int poemId) knows}) {
  final twins = fudaSets.tomofuda(poemId);
  final knownSiblings = twins.where(knows).toList();
  return [
    NewCardCelebration(poemId, twins),
    if (knownSiblings.isNotEmpty) ConfusableWarningCelebration(poemId, knownSiblings),
  ];
}

/// The pages after a run, in order: island completions, a rank-up, then a
/// new speed goal.
List<Celebration> celebrationsFor(SessionReport report) {
  final list = <Celebration>[
    for (final i in report.islandsCompleted) IslandCompleteCelebration(i),
  ];
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
