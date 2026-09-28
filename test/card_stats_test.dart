import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/state/play_config.dart';

AttemptRec _attempt(double ms, {bool miss = false}) => AttemptRec(
    at: DateTime(2026), us: (ms * 1000).round(), miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);

void main() {
  group('TOP SPEED', () {
    test('is null without a timed attempt', () {
      expect(CardStats.empty.topSpeedMs, isNull);
      expect(CardStats([_attempt(900, miss: true)]).topSpeedMs, isNull);
    });

    test('is the only time when there is one', () {
      expect(CardStats([_attempt(640)]).topSpeedMs, 640);
    });

    test('is the interpolated 5th percentile, not the single best time', () {
      // 21 times 400, 410 … 600 in shuffled order: rank 0.05 × 20 = 1 lands
      // exactly on the second fastest.
      final times = [for (var i = 0; i <= 20; i++) 400.0 + 10 * i]..shuffle(Random(7));
      final stats = CardStats([for (final ms in times) _attempt(ms)]);
      expect(stats.bestMs, 400);
      expect(stats.topSpeedMs, closeTo(410, 1e-9));
    });

    test('only looks at the last ${StatsTuning.topSpeedWindow} timed attempts, skipping misses', () {
      final old = [for (var i = 0; i < 50; i++) _attempt(300)];
      final recent = [
        for (var i = 0; i < StatsTuning.topSpeedWindow; i++) ...[_attempt(700), if (i.isEven) _attempt(200, miss: true)],
      ];
      expect(CardStats([...old, ...recent]).topSpeedMs, 700);
    });
  });
}
