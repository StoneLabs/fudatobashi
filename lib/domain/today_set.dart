import 'dart:math' as math;

import '../config/config.dart';
import 'card_stats.dart';
import 'day_window.dart';
import 'step_plan.dart';

/// Today's numbers in looks, as Home's bar draws them: each part's looks in
/// all and those already taken.
class SetBar {
  const SetBar({
    required this.reviews,
    required this.reviewsDone,
    required this.fresh,
    required this.freshDone,
    required this.extra,
    required this.extraDone,
    required this.extraKnown,
  });

  /// Due reviews' and new cards' base looks.
  final int reviews, reviewsDone, fresh, freshDone;

  /// Looks that misses add: so far, or the morning's guess while it is
  /// larger and the day is not done.
  final int extra, extraDone;

  /// Looks that the misses so far add, without the guess.
  final int extraKnown;

  int get total => reviews + fresh + extra;
  int get done => reviewsDone + freshDone + extraDone;

  /// Looks still to come if every answer left is right (what a run of the
  /// rest of the set counts).
  int get left => reviews + fresh + extraKnown - done;
}

/// Journey mode's daily set: the due reviews and new cards of one day, each
/// needing a few looks (see [CardSteps]). The day is done once every card
/// is settled. Its progress is replayed from the day's training swipes.
class TodaySet {
  TodaySet({
    required this.window,
    required this.kinds,
    required this.steps,
    required this.missGuess,
    this.newPaused = false,
    this.pauseAsked = false,
    this.doneAt,
  });

  /// Replays [looks] (each card's training swipes in [window], misses as
  /// true, oldest first) over the set's cards [kinds].
  factory TodaySet.replay({
    required DayWindow window,
    required Map<ItemKey, StepKind> kinds,
    required Map<ItemKey, List<bool>> looks,
    required int missGuess,
    bool newPaused = false,
    bool pauseAsked = false,
    DateTime? doneAt,
  }) {
    final steps = <ItemKey, CardSteps>{};
    for (final e in kinds.entries) {
      final s = steps[e.key] = CardSteps.forSet(e.value);
      for (final miss in looks[e.key] ?? const <bool>[]) {
        s.record(miss: miss);
      }
    }
    return TodaySet(
      window: window,
      kinds: kinds,
      steps: steps,
      missGuess: missGuess,
      newPaused: newPaused,
      pauseAsked: pauseAsked,
      doneAt: doneAt,
    );
  }

  /// The morning's guess at the extra looks for [baseLooks], from the miss
  /// rate of [recent] training swipes (true for a miss).
  static int guessMisses(int baseLooks, Iterable<bool> recent) {
    if (baseLooks == 0) return 0;
    final n = recent.length;
    final rate = n == 0 ? TodaySetTuning.missGuessDefault : recent.where((m) => m).length / n;
    return math.max(TodaySetTuning.missGuessMin, (baseLooks * rate).round());
  }

  final DayWindow window;
  final Map<ItemKey, StepKind> kinds;
  final Map<ItemKey, CardSteps> steps;
  final int missGuess;

  /// The player paused today's new cards, and was asked whether to.
  final bool newPaused, pauseAsked;

  /// When every card was settled (or, for an empty set, the day's first
  /// training run ended); null while the day is not done.
  final DateTime? doneAt;

  bool get done => doneAt != null;

  /// Every card is settled (an empty set never is: its day is done by a run).
  bool get settled => steps.isNotEmpty && steps.values.every((s) => s.done);

  int get reviews => kinds.values.where((k) => k == StepKind.review).length;
  int get newCards => kinds.values.where((k) => k == StepKind.newCard).length;

  /// Cards settled for today.
  Set<ItemKey> get doneKeys => {for (final e in steps.entries) if (e.value.done) e.key};

  /// New cards not settled yet.
  bool get newPending => steps.entries.any((e) => e.value.kind == StepKind.newCard && !e.value.done);

  /// Misses on the set's cards before they were settled.
  int get misses => steps.values.fold(0, (n, s) => n + s.looks - s.correct);

  SetBar get bar {
    var reviews = 0, reviewsDone = 0, fresh = 0, freshDone = 0, extra = 0, extraDone = 0;
    for (final s in steps.values) {
      if (s.kind == StepKind.newCard) {
        fresh += s.base;
        freshDone += s.baseLooks;
      } else {
        reviews += s.base;
        reviewsDone += s.baseLooks;
      }
      extra += s.extra;
      extraDone += s.extraLooks;
    }
    return SetBar(
      reviews: reviews,
      reviewsDone: reviewsDone,
      fresh: fresh,
      freshDone: freshDone,
      extra: done ? extra : math.max(extra, missGuess),
      extraDone: extraDone,
      extraKnown: extra,
    );
  }
}
