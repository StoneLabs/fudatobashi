import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';

void main() {
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final sets = FudaSets(p);

  group('rating', () {
    test('anchors map onto the original ranks', () {
      expect(Rating.bandOf(Rating.fromSeconds(39)).label, 'A級');
      expect(Rating.bandOf(Rating.fromSeconds(47)).label, 'B級');
      expect(Rating.bandOf(Rating.fromSeconds(51)).label, 'B級');
      expect(Rating.bandOf(Rating.fromSeconds(55)).label, 'C級');
      expect(Rating.bandOf(Rating.fromSeconds(59.9)).label, 'C級');
      expect(Rating.bandOf(Rating.fromSeconds(89)).label, 'D級');
      expect(Rating.bandOf(Rating.fromSeconds(149)).label, 'E下級');
      expect(Rating.bandOf(Rating.fromSeconds(399)).label, 'F下級');
      expect(Rating.bandOf(Rating.fromSeconds(600)).label, '入門');
    });

    test('50 cards at 2 s plus 50 unseen projects to 400 s', () {
      AttemptRec a(int ms) =>
          AttemptRec(at: DateTime(2026), us: ms * 1000, miss: false, clean: true, deckSize: 50, mode: PlayMode.training);
      final fast = CardStats([for (var i = 0; i < 5; i++) a(2000)]);
      // Both orientations practised for 50 cards: 50 × 2 s + 50 × 6 s.
      expect(Rating.projectedMs((k) => k.poemId <= 50 ? fast : CardStats.empty) / 1000, closeTo(400, 0.01));
      // Inverted never practised: its prior is upright × 1.25 → 50 × 2.25 + 300.
      expect(
        Rating.projectedMs((k) => k.poemId <= 50 && !k.inverted ? fast : CardStats.empty) / 1000,
        closeTo(412.5, 0.01),
      );
    });
  });

  group('learning batches', () {
    test('cover all 100 cards once and keep kimariji families together', () {
      final batches = Trainer.learningBatches(p, sets, 3);
      final flat = batches.expand((b) => b).toList();
      expect(flat.toSet().length, 100);
      expect(flat.length, 100);
      expect(batches.first.map((id) => p[id].kimariji), ['む', 'す', 'め']);
      final asa = batches.firstWhere((b) => b.contains(p.byKimariji('あさぼらけあ').id));
      expect(asa, contains(p.byKimariji('あさぼらけう').id));
    });
  });

  group('trainer', () {
    test('grades Easy at a fixed time, Good and Hard relative to the goal', () {
      final t = Trainer(config: const TrainerConfig(), items: Trainer.freshItems());
      AttemptRec a(int ms, {bool miss = false}) => AttemptRec(
          at: DateTime.utc(2026), us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);
      expect(t.gradeFor(a(TrainingTuning.defaultEasyMs)), fsrs.Rating.easy);
      expect(t.gradeFor(a(TrainingTuning.defaultEasyMs + 1)), fsrs.Rating.good);
      expect(t.gradeFor(a(2000)), fsrs.Rating.good); // goal 3 s: ≤ 4.5 s
      expect(t.gradeFor(a(4000)), fsrs.Rating.good);
      expect(t.gradeFor(a(5000)), fsrs.Rating.hard);
      expect(t.gradeFor(a(900, miss: true)), fsrs.Rating.again);
    });

    test('well remembered forgives one old slip, not a fresh miss, two slips, slowness or a due review', () {
      final t = Trainer(config: const TrainerConfig(), items: Trainer.freshItems());
      const key = ItemKey(1, false);
      final now = DateTime.utc(2026, 9, 1, 12);
      AttemptRec a(int ms, {bool miss = false}) =>
          AttemptRec(at: now, us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);
      bool well(List<AttemptRec> attempts, [DateTime? at]) => t.wellRemembered(key, CardStats(attempts), at ?? now);
      final slipped = [a(900), a(900, miss: true), a(900), a(900), a(900)];

      expect(well([a(900), a(900), a(900)]), isTrue);
      expect(well([a(900), a(900)]), isFalse, reason: 'too few timed attempts');
      expect(well(slipped), isTrue, reason: 'one slip among the last five');
      expect(CardStats(slipped).solid(t.goalMs), isFalse, reason: 'solid is stricter');
      expect(well([a(900), a(900), a(900), a(900, miss: true)]), isFalse, reason: 'the latest answer missed');
      expect(well([a(900), a(900, miss: true), a(900), a(900, miss: true), a(900)]), isFalse, reason: 'two slips');
      expect(well([a(3500), a(3500), a(3500)]), isFalse, reason: 'slower than 3 s on average');
      expect(well([a(1000), a(1000), a(7500)]), isFalse, reason: 'the mean of the last three, not their median');
      expect(well([a(9000), a(9000), a(1000), a(1000), a(1000)]), isTrue, reason: 'only the last three count');
      expect(t.remembered(key, CardStats([a(3500), a(3500), a(3500)]), now), isTrue, reason: 'slow, yet remembered');

      t.review(key, a(900));
      expect(well(slipped), isTrue, reason: 'reviewed, its learning step not up yet');
      expect(well(slipped, now.add(const Duration(minutes: 11))), isFalse, reason: 'its learning step is up');
      expect(well(slipped, now.add(const Duration(days: 60))), isFalse, reason: 'its review is due');
    });

    group('learning steps (journey grading by the day)', () {
      const key = ItemKey(1, false);
      final start = DateTime.utc(2026, 9, 1, 9);
      final dayEnd = DateTime.utc(2026, 9, 2, 4);
      AttemptRec a(DateTime at, {int ms = 900, bool miss = false}) =>
          AttemptRec(at: at, us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);
      Trainer fresh() => Trainer(config: const TrainerConfig(), items: Trainer.freshItems())..fuzzing = false;
      String state(Trainer t) {
        final c = t.items[key]!.card;
        return '${c.state.name} ${c.step} ${c.due.toIso8601String()} ${c.stability} ${c.difficulty}';
      }

      test('an answer before the step is up changes nothing; the next after it graduates the card on Good', () {
        final t = fresh();
        expect(t.review(key, a(start), dayEnd: dayEnd), fsrs.Rating.good, reason: 'a new card is always graded');
        expect(t.items[key]!.card.state, fsrs.State.learning);
        final waiting = state(t);
        final early = start.add(const Duration(minutes: 5));
        expect(t.review(key, a(early), dayEnd: dayEnd, firstToday: false), isNull);
        expect(state(t), waiting, reason: 'FSRS never saw it');
        final late = start.add(const Duration(minutes: 11));
        expect(t.review(key, a(late), dayEnd: dayEnd, firstToday: false), fsrs.Rating.good);
        expect(t.items[key]!.card.state, fsrs.State.review, reason: 'graduated the same day');
        expect(t.isDue(key, late), isFalse);
      });

      test('a missed review relearns, and graduates once its step is up', () {
        final t = fresh();
        t.review(key, a(start), dayEnd: dayEnd);
        t.review(key, a(start.add(const Duration(minutes: 11))), dayEnd: dayEnd, firstToday: false);
        final review = t.items[key]!.card.due;
        final day = review.add(const Duration(hours: 1));
        final end = day.add(const Duration(hours: 12));
        expect(t.review(key, a(day, miss: true), dayEnd: end), fsrs.Rating.again);
        expect(t.items[key]!.card.state, fsrs.State.relearning);
        expect(t.review(key, a(day.add(const Duration(minutes: 2))), dayEnd: end, firstToday: false), isNull);
        expect(t.review(key, a(day.add(const Duration(minutes: 12))), dayEnd: end, firstToday: false),
            fsrs.Rating.good);
        expect(t.items[key]!.card.state, fsrs.State.review);
      });

      test('a review is graded by its day only once, and a Hard step waits again', () {
        final t = fresh();
        t.review(key, a(start), dayEnd: dayEnd);
        t.review(key, a(start.add(const Duration(minutes: 11))), dayEnd: dayEnd, firstToday: false);
        final day = t.items[key]!.card.due.subtract(const Duration(hours: 2));
        final end = day.add(const Duration(hours: 12));
        expect(t.review(key, a(day), dayEnd: end), fsrs.Rating.good, reason: 'due before the day ends');
        final after = state(t);
        expect(t.review(key, a(day.add(const Duration(hours: 3))), dayEnd: end, firstToday: false), isNull);
        expect(state(t), after);

        final slow = fresh();
        slow.review(key, a(start, ms: 6000), dayEnd: dayEnd);
        final step = slow.items[key]!.card;
        expect((step.state, step.step), (fsrs.State.learning, 0), reason: 'Hard keeps the step');
        expect(slow.review(key, a(step.due, ms: 6000), dayEnd: dayEnd, firstToday: false), fsrs.Rating.hard);
        expect(slow.items[key]!.card.state, fsrs.State.learning);
      });
    });

    group('Learn ahead', () {
      final now = DateTime(2026, 9, 1, 12);
      final ids = Trainer.learningBatches(p, sets, 3).expand((b) => b).toList();
      AttemptRec a(int ms, {bool miss = false}) =>
          AttemptRec(at: now, us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);
      CardStats quick() => CardStats([a(900), a(900), a(900)]);
      CardStats slow() => CardStats([a(900), a(900), a(9000)]);

      /// A trainer with [n] cards unlocked before today, and their stats.
      (Trainer, Map<ItemKey, CardStats>) deck(int n, {DateTime? unlockedAt}) {
        final t = Trainer(config: const TrainerConfig(), items: Trainer.freshItems());
        for (final id in ids.take(n)) {
          t.items[ItemKey(id, false)]!
            ..unlocked = true
            ..unlockedAt = unlockedAt;
        }
        return (t, {for (final id in ids.take(n)) ItemKey(id, false): quick()});
      }

      test('lets a tenth of the cards be slow, as long as every card is remembered', () {
        final (t, stats) = deck(20);
        LearnAhead ahead() => t.learnAhead(p, sets, stats, now, newPending: false);
        expect(ahead().lock, LearnAheadLock.none);
        stats[ItemKey(ids[0], false)] = slow();
        stats[ItemKey(ids[1], false)] = slow();
        expect((ahead().lock, ahead().shaky), (LearnAheadLock.none, 0), reason: '2 of 20 slow: 90% quick');
        stats[ItemKey(ids[2], false)] = slow();
        expect((ahead().lock, ahead().shaky), (LearnAheadLock.shaky, 1), reason: 'one slow card too many');
        stats[ItemKey(ids[2], false)] = CardStats([a(900), a(900), a(900), a(900, miss: true)]);
        expect((ahead().lock, ahead().shaky), (LearnAheadLock.shaky, 1), reason: 'every card must be remembered');
        expect(t.wellRememberedCount(stats, now), 17);
      });
    });
  });
}
