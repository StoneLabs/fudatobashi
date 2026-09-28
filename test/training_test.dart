import 'dart:io';

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

  group('trainer', () {
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
