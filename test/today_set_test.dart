import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/day_window.dart';
import 'package:fudatobashi/domain/step_plan.dart';
import 'package:fudatobashi/domain/today_set.dart';

ItemKey k(int id) => ItemKey(id, false);

/// Looks a card takes for [answers] ('x' a miss, 'o' right), and whether it
/// is settled after them.
(int, bool) stepsOf(StepKind kind, String answers) {
  final s = CardSteps.forSet(kind);
  for (final c in answers.split('')) {
    s.record(miss: c == 'x');
  }
  return (s.total, s.done);
}

/// Plays [plan] answering right except at [missAt] positions; returns the
/// swipes.
List<(ItemKey, bool)> play(StepPlan plan, {Set<int> missAt = const {}}) {
  final swipes = <(ItemKey, bool)>[];
  var rest = plan.cards;
  while (rest.isNotEmpty) {
    swipes.add((rest.first, missAt.contains(swipes.length)));
    rest = plan.upcoming(swipes);
  }
  return swipes;
}

StepPlan setPlan({List<int> reviews = const [], List<int> fresh = const [], List<int> fillers = const []}) =>
    StepPlan.forSet(
      start: {
        for (final id in reviews) k(id): CardSteps.forSet(StepKind.review),
        for (final id in fresh) k(id): CardSteps.forSet(StepKind.newCard),
      },
      reviews: [for (final id in reviews) k(id)],
      newCards: [for (final id in fresh) k(id)],
      fillers: [for (final id in fillers) k(id)],
      knownBefore: {2, ...reviews, ...fillers},
      twinsOf: (id) => id == 1 ? const [2] : const [],
    );

void main() {
  group('card steps', () {
    test('a review needs two looks even when the first is right', () {
      expect(stepsOf(StepKind.review, 'o'), (2, false));
      expect(stepsOf(StepKind.review, 'oo'), (2, true));
    });

    test('a miss needs two right in a row, never a fixed +1', () {
      expect(stepsOf(StepKind.review, 'xoo'), (3, true));
      expect(stepsOf(StepKind.review, 'oxoo'), (4, true));
      expect(stepsOf(StepKind.review, 'xoxoo'), (5, true));
      expect(stepsOf(StepKind.newCard, 'oooo'), (4, true));
      expect(stepsOf(StepKind.newCard, 'xoooo'), (5, true));
      expect(stepsOf(StepKind.newCard, 'ooxoo'), (5, true));
    });

    test('a settled card ignores later looks', () {
      final s = CardSteps.forSet(StepKind.review)
        ..record(miss: false)
        ..record(miss: false)
        ..record(miss: true);
      expect((s.looks, s.done, s.remaining), (2, true, 0));
    });

    test('gaps follow the learning and relearning steps', () {
      final n = CardSteps.forSet(StepKind.newCard);
      final gaps = <int>[];
      for (final miss in [false, false, false]) {
        n.record(miss: miss);
        gaps.add(n.gapAfter(miss: miss));
      }
      expect(gaps, TodaySetTuning.newGaps);
      n.record(miss: true);
      expect(n.gapAfter(miss: true), TodaySetTuning.relearnGaps.first);
      n.record(miss: false);
      expect(n.gapAfter(miss: false), TodaySetTuning.relearnGaps[1]);
    });
  });

  group('step plan', () {
    test('every card gets its looks and the run ends', () {
      final plan = setPlan(reviews: [1, 3, 4, 5, 6, 7, 8], fresh: [20, 21]);
      final swipes = play(plan);
      final per = <ItemKey, int>{};
      for (final (key, _) in swipes) {
        per[key] = (per[key] ?? 0) + 1;
      }
      expect(per[k(1)], TodaySetTuning.reviewLooks);
      expect(per[k(20)], TodaySetTuning.newLooks);
      expect(swipes, hasLength(7 * TodaySetTuning.reviewLooks + 2 * TodaySetTuning.newLooks));
      for (var i = 1; i < swipes.length; i++) {
        expect(swipes[i].$1, isNot(swipes[i - 1].$1), reason: 'no card twice in a row');
      }
    });

    test('the run opens with reviews before a new card', () {
      final cards = setPlan(reviews: [1, 3, 4, 5, 6, 7, 8], fresh: [20, 21]).cards;
      expect(cards.take(TrainingTuning.newCardHoldBack).every((c) => c.poemId < 20), isTrue);
    });

    test('right answers never change the plan', () {
      final plan = setPlan(reviews: [1, 3, 4, 5, 6], fresh: [20, 21, 22]);
      final first = plan.cards;
      expect(play(plan).map((s) => s.$1).toList(), first);
    });

    test('a miss brings the card back after a gap, with a 友札 after it', () {
      final plan = setPlan(reviews: [1, 3, 4, 5, 6, 7, 8, 9]);
      final first = plan.cards.first;
      expect(first, k(1));
      final after = plan.upcoming([(first, true)]);
      final back = after.indexOf(k(1));
      expect(back, TodaySetTuning.relearnGaps.first);
      expect(after[back + 1], k(2), reason: 'its 友札 right after it');
      final swipes = play(plan, missAt: {0});
      expect(swipes.where((s) => s.$1 == k(1)), hasLength(1 + TodaySetTuning.reviewLooks));
    });

    test('a filler sits between two looks of the last card', () {
      final plan = setPlan(fresh: [20], fillers: [50]);
      final cards = plan.cards;
      expect(cards.where((c) => c == k(20)), hasLength(TodaySetTuning.newLooks));
      for (var i = 1; i < cards.length; i++) {
        expect(cards[i], isNot(cards[i - 1]));
      }
      expect(cards, contains(k(50)));
    });

    test('a batch repeats each card as often as it was picked', () {
      final plan = StepPlan.forBatch(
        picks: [k(1), k(3), k(1), k(4), k(5), k(6), k(1)],
        knownBefore: const {},
        twinsOf: (_) => const [],
      );
      final swipes = play(plan, missAt: {1});
      expect(swipes.where((s) => s.$1 == k(1)), hasLength(3));
      expect(swipes.where((s) => s.$1 == k(3)), hasLength(1 + TodaySetTuning.relearnLooks));
    });

    test('the plan continues after an undo with the redo on screen', () {
      final plan = setPlan(reviews: [1, 3, 4, 5, 6, 7]);
      final cards = plan.cards;
      final rest = plan.upcoming([(cards[0], false), (cards[1], true)], next: cards[1]);
      expect(rest, isNot(contains(null)));
      expect(rest.first, isNot(cards[1]));
    });
  });

  group('today set', () {
    test('replays the day and draws the bar in looks', () {
      final set = TodaySet.replay(
        window: DayWindow.at(DateTime(2026, 10, 14, 12), 4),
        kinds: {k(1): StepKind.review, k(3): StepKind.review, k(20): StepKind.newCard},
        looks: {
          k(1): [false, false],
          k(3): [true, false],
          k(20): [false],
        },
        missGuess: 3,
      );
      expect(set.settled, isFalse);
      expect(set.doneKeys, {k(1)});
      expect(set.misses, 1);
      final bar = set.bar;
      expect((bar.reviews, bar.reviewsDone, bar.fresh, bar.freshDone), (4, 4, 4, 1));
      expect((bar.extra, bar.extraDone), (3, 0), reason: "the morning's guess holds the space; the extra look is to come");
      expect((bar.total, bar.done), (11, 5));
      expect((bar.extraKnown, bar.left), (1, 4), reason: 'what is left counts the real misses, not the guess');
    });

    test('guesses misses from the recent miss rate', () {
      expect(TodaySet.guessMisses(0, const []), 0);
      expect(TodaySet.guessMisses(24, const []), 2);
      expect(TodaySet.guessMisses(40, [for (var i = 0; i < 100; i++) i < 25]), 10);
      expect(TodaySet.guessMisses(4, [for (var i = 0; i < 100; i++) false]), TodaySetTuning.missGuessMin);
    });
  });

  group('day window', () {
    test('the day starts at the hour; the night counts for the day before', () {
      final w = DayWindow.at(DateTime(2026, 10, 14, 2), 4);
      expect(w.number, 20261013);
      expect(w.start, DateTime(2026, 10, 13, 4));
      expect(w.end, DateTime(2026, 10, 14, 4));
      expect(DayWindow.at(DateTime(2026, 10, 14, 4), 4).number, 20261014);
      expect(DayWindow.at(DateTime(2026, 10, 14, 0, 30), 0).number, 20261014);
      expect(DayWindow.at(DateTime(2026, 10, 14, 8), 9).number, 20261013);
    });

    test('changing the hour takes effect from the next day start', () {
      for (final (from, to) in [(4, 6), (6, 4), (9, 0), (0, 9)]) {
        final today = DayWindow.at(DateTime(2026, 10, 14, 12), from);
        var now = today.end;
        final next = DayWindow.after(today, now, to);
        expect(next.start, today.end, reason: '$from → $to');
        expect(next.number, 20261015, reason: '$from → $to');
        expect(next.end.difference(next.start) >= TodaySetTuning.shortestDay, isTrue, reason: '$from → $to');
        now = next.end;
        final after = DayWindow.after(next, now, to);
        expect(after.number, 20261016, reason: '$from → $to');
        expect(after.start.hour, to);
      }
    });

    test('a day after a gap is the plain day', () {
      final old = DayWindow.at(DateTime(2026, 10, 1, 12), 4);
      expect(DayWindow.after(old, DateTime(2026, 10, 14, 12), 6), DayWindow.at(DateTime(2026, 10, 14, 12), 6));
    });
  });
}
