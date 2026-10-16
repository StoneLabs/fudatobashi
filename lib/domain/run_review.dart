import 'dart:math' as math;

import '../config/config.dart';
import 'play_session.dart';

/// One swipe of a recorded run, as History's run page reads it.
class RunSwipe {
  const RunSwipe({
    required this.poemId,
    required this.inverted,
    required this.us,
    required this.miss,
    required this.clean,
    required this.at,
    this.undone = false,
    this.graded = false,
  });

  final int poemId;
  final bool inverted;

  /// Reveal → response, µs.
  final int us;
  final bool miss;

  /// Its time is a clean measurement (see `AttemptRec.clean`).
  final bool clean;
  final DateTime at;

  /// Taken back with ひとつ前: it took time and counts as a miss, but the
  /// card was swiped again after it.
  final bool undone;

  /// FSRS graded it: a due review, or a miss.
  final bool graded;

  double get ms => us / 1000;

  /// Right, clean and a valid time: it counts for speed.
  bool get timed => !miss && clean && Attempt.isValidTime(us);
}

/// A run's time into the run after each card: [ms] holds 0 and then the
/// time as each card went, so card i ends at `ms[i]`. The clock is shared
/// out among the cards by their swipe times (the moments between cards
/// included), and a scored run adds each miss's penalty where it happened.
class RunTimeline {
  const RunTimeline(this.ms, {this.missCards = const []});

  /// The timeline of [swipes] in the order made, stretched to [clockMs].
  /// Each miss adds [penaltyMs] at its card (an undone swipe at the card
  /// swiped again after it).
  factory RunTimeline.of(List<RunSwipe> swipes, {required double clockMs, int penaltyMs = 0}) {
    final swipeMs = swipes.fold<double>(0, (sum, s) => sum + math.max(0, s.ms));
    final stretch = swipeMs > 0 ? clockMs / swipeMs : 0.0;
    final ms = <double>[0];
    final missCards = <int>[];
    var at = 0.0;
    var missed = false;
    for (final s in swipes) {
      at += math.max(0, s.ms) * stretch;
      if (s.miss) at += penaltyMs;
      missed |= s.miss;
      if (s.undone) continue;
      if (missed) missCards.add(ms.length);
      missed = false;
      ms.add(at);
    }
    return RunTimeline(ms, missCards: missCards);
  }

  final List<double> ms;

  /// Cards (1-based) that were misses.
  final List<int> missCards;

  int get cards => ms.length - 1;
  double get endMs => ms.last;

  /// Where an even pace to the same end would be after [card] cards.
  double evenAt(int card) => cards == 0 ? 0 : endMs * card / cards;

  /// The time graph's bottom: the slowest of [references] (earlier runs of
  /// the same kind), but never past [RunReviewTuning.graphReach] times
  /// this run, so its line fills at least that share of the height. With
  /// no references, this run's own end.
  double bottomWith(Iterable<RunTimeline> references) {
    final slowest = references.fold(endMs, (m, r) => math.max(m, r.endMs));
    return math.min(slowest, endMs * RunReviewTuning.graphReach);
  }
}

/// The cards of a run to show by their time: the slowest and fastest of its
/// right swipes, and its misses in the order made.
class RunCards {
  RunCards(List<RunSwipe> swipes)
      : misses = [for (final s in swipes) if (s.miss && !s.undone) s],
        _byTime = [for (final s in swipes) if (s.timed) s]..sort((a, b) => a.us.compareTo(b.us));

  final List<RunSwipe> misses;
  final List<RunSwipe> _byTime;

  List<RunSwipe> get slowest => _byTime.reversed.take(RunReviewTuning.shownCards).toList();
  List<RunSwipe> get fastest => _byTime.take(RunReviewTuning.shownCards).toList();

  /// Cards worth another go: every miss, then the slowest, each once.
  List<int> get practise => {for (final s in misses) s.poemId, for (final s in slowest) s.poemId}.toList();
}
