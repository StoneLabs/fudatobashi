import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_score.dart';
import '../ankiren/ankiren_band.dart';
import '../stats/stats_charts.dart';

const _mono = TextStyle(fontFamily: 'monospace', fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]);

/// The debug page's 暗記練 tab: the level table, the speed bonus's curve,
/// and the scoring, rating and middle-card tuning, all read from config.
class AnkirenConfigTab extends StatelessWidget {
  const AnkirenConfigTab({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Levels', style: title),
        const SizedBox(height: 8),
        const _LevelTable(),
        const Divider(height: 32),
        Text('Speed bonus (first try)', style: title),
        const SizedBox(height: 8),
        const _BonusChart(),
        const SizedBox(height: 8),
        for (final MapEntry(key: ms, value: target) in AnkirenTuning.speedTargets.entries)
          _line('${(ms / 1000).toStringAsFixed(1)} s', '${AnkirenScore.speedBonus(ms * 1000)}  (target $target)'),
        _line(
          'curve',
          'logistic over ln t, centre ${AnkirenTuning.speedMidpoint.inMilliseconds} ms,'
              ' steepness ${AnkirenTuning.speedSteepness}, 100 at ≤ ${AnkirenTuning.speedFull.inMilliseconds} ms,'
              ' 0 at ≥ ${AnkirenTuning.speedNone.inMilliseconds} ms',
        ),
        const Divider(height: 32),
        Text('Points per card', style: title),
        _line('first try', '${AnkirenTuning.firstTry} + up to ${AnkirenTuning.speedMax} speed bonus'),
        _line('after 1 wrong tap', '${AnkirenTuning.secondTry}'),
        _line('shown, given up, missed', '0 (shown after ${AnkirenTuning.revealAfterWrong} wrong taps)'),
        _line('ready early', '× up to ${1 + AnkirenTuning.earlyBonus}, by the share of time left'),
        _line('level', '× ${AnkirenTuning.levelFactor} per level below ${AnkirenLevels.top}'),
        _line('rating par', '${(AnkirenRatingModel.par * 100).round()}% of the best score'),
        _line(
          'placement',
          '${AnkirenRatingModel.placementGames} games, stretch ×${AnkirenRatingModel.placementStretch}',
        ),
        const Divider(height: 32),
        Text('Middle cards', style: title),
        _line('who', 'a side with a 友札 pair, splitting it'),
        _line('chance per side', '${(AnkirenTuning.middleChancePerSide * 100).toStringAsFixed(1)}%'),
        _line(
          'cards',
          '${AnkirenTuning.middleMin}–${AnkirenTuning.middleMax},'
              ' keeping ≥ ${AnkirenTuning.middleMinClustered} in the clusters',
        ),
        _line('row', AnkirenTuning.middleRow.name),
        _line('row width', '≤ ${AnkirenTuning.rowMax} cards, middle cards counted'),
      ],
    );
  }

  static Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: SimulationStyle.labelWidth,
              child: Text(k, style: _mono.copyWith(color: Palette.mute)),
            ),
            Expanded(child: Text(v, style: _mono)),
          ],
        ),
      );
}

class _LevelTable extends StatelessWidget {
  const _LevelTable();

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(c, style: head ? _mono.copyWith(fontWeight: Weights.black) : _mono),
              ),
          ],
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        columnWidths: const {0: FixedColumnWidth(28)},
        children: [
          row(['L', '/side ', 'cards ', 'time  ', 's/card ', 'middle ', 'score× ', 'rating'], head: true),
          for (final (i, l) in AnkirenLevels.all.indexed)
            row([
              '$i',
              '${l.perSide}',
              '${l.cards}',
              formatMinutes(l.memorise),
              (l.memorise.inMilliseconds / 1000 / l.cards).toStringAsFixed(1),
              l.allInMiddle
                  ? 'all'
                  : AnkirenDealer.mayHaveMiddle(l.perSide)
                      ? '≤ ${AnkirenDealer.maxMiddle(l.perSide)}'
                      : '—',
              AnkirenScore.factorFor(AnkirenSetup.forLevel(i)).toStringAsFixed(3),
              AnkirenRatingModel.levelRatings[i].toStringAsFixed(0),
            ]),
        ],
      ),
    );
  }
}

/// The bonus over 0 to [_until], with the fitted targets as thin bars.
class _BonusChart extends StatelessWidget {
  const _BonusChart();

  static const _step = 25;
  static const _until = 6000;

  @override
  Widget build(BuildContext context) {
    final times = [for (var t = 0; t <= _until; t += _step) t];
    final chart = DailyChart(
      top: AnkirenTuning.speedMax.toDouble(),
      series: [
        DailySeries(
          'target',
          [for (final t in times) AnkirenTuning.speedTargets[t]?.toDouble() ?? double.nan],
          Palette.pink,
          bars: true,
        ),
        DailySeries(
            'bonus',
            [
              for (final t in times) AnkirenTuning.speedMax * AnkirenScore.speedShare(t.toDouble()),
            ],
            Palette.seaDeep),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${AnkirenTuning.speedMax}', style: _mono),
        SizedBox(height: SimulationStyle.chartHeight, child: chart),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (var s = 0; s <= _until ~/ 1000; s++) Text('$s s', style: _mono)],
        ),
      ],
    );
  }
}
