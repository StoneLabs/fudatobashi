import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/ui/stats/stats_charts.dart';

AttemptRec _attempt(double ms, {bool miss = false}) => AttemptRec(
    at: DateTime(2026), us: (ms * 1000).round(), miss: miss, clean: true, deckSize: 10, mode: PlayMode.training);

void main() {
  test('rolling percentiles run over the last window of timed attempts', () {
    final stats = CardStats([for (final ms in const [500.0, 900.0, 700.0, 600.0]) _attempt(ms)]);
    expect(stats.rollingPercentile(2, 0), [500, 500, 700, 600]);
    expect(stats.rollingPercentile(3, 50), [500, 700, 700, 700]);
  });

  group('attempt chart data', () {
    test('each average starts once its window is full, skipping misses', () {
      final attempts = [
        for (var i = 0; i < 12; i++) _attempt(600 + 10.0 * i, miss: i == 2),
      ];
      final data = AttemptChartData(attempts);
      final short = data.averages[ChartSeries.shortAverage]!;
      // The fifth timed attempt is attempt 5 (attempt 2 is a miss).
      expect(short.first.x, 5);
      expect(short.first.ms, closeTo((600 + 610 + 630 + 640 + 650) / 5, 1e-9));
      expect(short.map((p) => p.x), isNot(contains(2)));
      expect(data.averages[ChartSeries.midAverage]!.map((p) => p.x), [10, 11]);
      expect(data.averages[ChartSeries.longAverage], isEmpty);
      expect(data.latest(ChartSeries.longAverage), isNull);
    });

    test('the band starts at its minimum count and moves with recent times', () {
      final slow = [for (var i = 0; i < AttemptChartTuning.bandWindow; i++) _attempt(1000)];
      final fast = [for (var i = 0; i < AttemptChartTuning.bandWindow; i++) _attempt(500)];
      final data = AttemptChartData([...slow, ...fast]);
      expect(data.bandHigh.first.x, AttemptChartTuning.bandMinCount - 1);
      expect(data.bandHigh.first.ms, 1000);
      expect(data.bandLow.last.ms, 500);
      expect(data.latest(ChartSeries.band), 500);
    });

    test('the TOP SPEED star sits on the latest attempt nearest to it', () {
      final data = AttemptChartData([_attempt(700), _attempt(500), _attempt(900), _attempt(500), _attempt(800)]);
      expect(data.stats.topSpeedMs, 500);
      expect(data.topSpeedX, 3);
    });

    test('has no axis when every attempt is a miss', () {
      expect(AttemptChartData([_attempt(3000, miss: true)]).axis, isNull);
    });
  });

  group('ms axis', () {
    test('rounds out to the smallest step with few enough gridlines', () {
      final axis = ChartAxis.fit(590, 1320);
      expect((axis.lo, axis.hi, axis.step), (400, 1400, 200));
      expect(axis.ticks, [600, 800, 1000, 1200, 1400]);
    });

    test('never goes below zero, and widens its step past the largest', () {
      expect(ChartAxis.fit(20, 80).lo, 0);
      final wide = ChartAxis.fit(100, 60000);
      expect(wide.ticks.length, lessThanOrEqualTo(AttemptChartTuning.maxGridLines));
      expect(wide.hi, greaterThanOrEqualTo(60000));
    });
  });
}
