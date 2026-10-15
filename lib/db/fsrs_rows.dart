import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../domain/card_stats.dart';
import '../domain/trainer.dart';
import 'database.dart';

/// A training item as [Items] stores it.
extension ItemStateRow on ItemState {
  ItemsCompanion get row {
    final c = reviewed ? card : null;
    return ItemsCompanion.insert(
      poemId: key.poemId,
      inverted: key.inverted,
      unlocked: Value(unlocked),
      unlockedAt: Value(unlockedAt),
      fsrsState: Value(c?.state),
      fsrsStep: Value(c?.step),
      fsrsStability: Value(c?.stability),
      fsrsDifficulty: Value(c?.difficulty),
      fsrsDue: Value(c?.due),
      fsrsLastReview: Value(c?.lastReview),
    );
  }

  static ItemState of(ItemRow r) {
    final key = ItemKey(r.poemId, r.inverted);
    final state = r.fsrsState, due = r.fsrsDue;
    return ItemState(
      key,
      unlocked: r.unlocked,
      unlockedAt: r.unlockedAt,
      card: state == null || due == null
          ? null
          : fsrs.Card(
              cardId: key.id,
              state: state,
              step: r.fsrsStep,
              stability: r.fsrsStability,
              difficulty: r.fsrsDifficulty,
              due: due.toUtc(),
              lastReview: r.fsrsLastReview?.toUtc(),
            ),
    );
  }
}

/// An attempt's review columns (see [Attempts.grade]).
extension AttemptReview on AttemptsCompanion {
  /// These columns with [grade]'s review: the chance of recall just before
  /// it and the [card] after it. A null [grade] clears them.
  AttemptsCompanion withReview(fsrs.Rating? grade, {double? recall, fsrs.Card? card}) {
    final c = grade == null ? null : card;
    return copyWith(
      grade: Value(grade?.value),
      fsrsRecall: Value(grade == null ? null : recall),
      fsrsState: Value(c?.state),
      fsrsStep: Value(c?.step),
      fsrsStability: Value(c?.stability),
      fsrsDifficulty: Value(c?.difficulty),
      fsrsDue: Value(c?.due),
    );
  }
}
