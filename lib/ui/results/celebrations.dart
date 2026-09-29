import '../../config/config.dart';
import '../../data/fuda_sets.dart';
import '../../domain/rating.dart';
import '../../domain/xp.dart';
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

  /// Null on the first rated run.
  final double? ratingBefore;
  final double ratingAfter;
}

class GoalUpCelebration extends Celebration {
  const GoalUpCelebration();
}

/// The journey is over: all 100 cards learned (once ever).
class GraduationCelebration extends Celebration {
  const GraduationCelebration();
}

/// A tracked run raised the rating: it climbs its class's track, breaking
/// through into the next class when the run [ranksUp] (the rank-up page
/// follows).
class RatingCelebration extends Celebration {
  const RatingCelebration(this.before, this.after);
  final double before;
  final double after;

  bool get ranksUp => Rating.bands.indexOf(Rating.bandOf(after)) > Rating.bands.indexOf(Rating.bandOf(before));
}

/// The XP a tracked run earned, source by source.
class XpCelebration extends Celebration {
  const XpCelebration(this.gain);
  final XpGain gain;
}

/// The XP of a run reached a new level (or several).
class LevelUpCelebration extends Celebration {
  const LevelUpCelebration(this.gain);
  final XpGain gain;
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

/// The pages after a run, in order: island completions, a new speed goal,
/// graduation, the XP earned and any level it reached, then the rating when
/// it rose and a rank-up when it reached a new class.
List<Celebration> celebrationsFor(SessionReport report) {
  final list = <Celebration>[
    for (final i in report.islandsCompleted) IslandCompleteCelebration(i),
    if (report.goalRaised) const GoalUpCelebration(),
    if (report.graduated) const GraduationCelebration(),
  ];
  final xp = report.xp;
  if (xp != null && xp.award.total > 0) {
    list.add(XpCelebration(xp));
    if (xp.levelsGained > 0) list.add(LevelUpCelebration(xp));
  }
  final (ratingBefore, ratingAfter) = (report.ratingBefore, report.ratingAfter);
  if (ratingAfter != null) {
    if (ratingBefore != null && ratingAfter.round() - ratingBefore.round() >= RatingScreenTuning.minGain) {
      list.add(RatingCelebration(ratingBefore, ratingAfter));
    }
    final before = ratingBefore == null ? Rating.bands.first : Rating.bandOf(ratingBefore);
    final after = Rating.bandOf(ratingAfter);
    if (Rating.bands.indexOf(after) > Rating.bands.indexOf(before)) {
      list.add(RankUpCelebration(before, after, ratingBefore, ratingAfter));
    }
  }
  return list;
}
