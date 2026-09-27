import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
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

  group('trainer simulation', () {
    test('a steadily improving learner unlocks cards at a sensible pace', () {
      final trainer = Trainer(config: const TrainerConfig(), items: Trainer.freshItems());
      final log = <ItemKey, List<AttemptRec>>{};
      final rng = math.Random(7);
      var now = DateTime.utc(2026, 9, 1, 9);
      CardStats statsOf(ItemKey k) => CardStats(log[k] ?? const []);
      Map<ItemKey, CardStats> allStats() => {for (final k in trainer.items.keys) k: statsOf(k)};

      final unlockedPerDay = <int>[];
      for (var day = 0; day < 14; day++) {
        for (var session = 0; session < 3; session++) {
          trainer.unlockEarned(p, sets, allStats(), now);
          final picks = trainer.planSession(allStats(), now, rng);
          expect(picks, isNotEmpty);
          for (final pick in picks) {
            final seen = log[pick.key]?.length ?? 0;
            // Synthetic learner: starts ~4 s, speeds up with practice, rarely misses.
            final ms = 4000 * math.pow(0.8, seen) + 700 + rng.nextInt(300);
            final miss = seen < 2 && rng.nextDouble() < 0.3;
            final a = AttemptRec(
                at: now, us: (ms * 1000).round(), miss: miss, clean: true, deckSize: picks.length, mode: PlayMode.training);
            (log[pick.key] ??= []).add(a);
            trainer.review(pick.key, a);
            now = now.add(const Duration(seconds: 2));
          }
          now = now.add(const Duration(hours: 3));
        }
        unlockedPerDay.add(trainer.unlocked.where((s) => !s.key.inverted).length);
        now = DateTime.utc(2026, 9, 2 + day, 9);
      }
      // Unlocking is monotonic and neither stalls nor floods.
      for (var i = 1; i < unlockedPerDay.length; i++) {
        expect(unlockedPerDay[i], greaterThanOrEqualTo(unlockedPerDay[i - 1]));
      }
      expect(unlockedPerDay.first, inInclusiveRange(3, 30));
      expect(unlockedPerDay.last, greaterThan(unlockedPerDay.first));
      expect(trainer.items.values.where((s) => s.card.state == fsrs.State.review), isNotEmpty);
      // ignore: avoid_print
      print('upright cards unlocked per day: $unlockedPerDay');
    });

    test('grades follow time relative to the goal', () {
      final t = Trainer(config: const TrainerConfig(), items: Trainer.freshItems());
      AttemptRec a(int ms, {bool miss = false}) => AttemptRec(
          at: DateTime.utc(2026), us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);
      expect(t.gradeFor(a(2000)), fsrs.Rating.easy); // goal 3 s: ≤ 2.25 s
      expect(t.gradeFor(a(4000)), fsrs.Rating.good); // ≤ 4.5 s
      expect(t.gradeFor(a(5000)), fsrs.Rating.hard);
      expect(t.gradeFor(a(900, miss: true)), fsrs.Rating.again);
    });
  });
}
