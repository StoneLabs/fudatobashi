import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/synthetic_learner.dart';
import '../../domain/trainer.dart';
import '../../state/pace_simulation.dart';
import '../../state/scope.dart';
import '../stats/stats_charts.dart';
import 'seed_action.dart';

const _mono = TextStyle(fontFamily: 'monospace', fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]);

/// Settings › Developer › Simulation: how a quick, average or slow learner
/// gets on with a pace, day by day, through the real trainer on a throwaway
/// database (`simulatePace`). Also home to "Seed demo data", which does write
/// the player's progress.
class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  var _learner = LearnerKind.average;
  LearningPace? _pace;
  var _days = SimulationTuning.defaultDays;
  var _result = <SimulatedDay>[];
  var _running = false;
  Object? _error;

  /// The learner, pace and days behind [_result], for "Seed demo data" to
  /// reproduce exactly (not whatever is currently selected, if it has since
  /// changed without being re-run).
  ({LearnerKind learner, LearningPace pace, int days})? _lastRun;

  Future<void> _simulate(LearningPace pace) async {
    setState(() {
      _running = true;
      _result = [];
      _error = null;
    });
    try {
      await simulatePace(
        learner: _learner,
        pace: pace,
        days: _days,
        onDay: (d) {
          if (mounted) setState(() => _result = [..._result, d]);
        },
      );
      _lastRun = (learner: _learner, pace: pace, days: _days);
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _running = false);
  }

  /// Seeds real progress with the run shown above (running one first, with
  /// the current choices, if none has happened yet).
  Future<void> _seedDemoData(LearningPace pace) async {
    if (_lastRun == null) await _simulate(pace);
    final run = _lastRun;
    if (run == null || !mounted) return;
    await confirmSeedDemoData(context, learner: run.learner, pace: run.pace, days: run.days);
  }

  @override
  Widget build(BuildContext context) {
    final pace = _pace ?? ProgressScope.of(context).trainer.config.pace;
    final title = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      backgroundColor: Palette.paper,
      appBar: AppBar(
        backgroundColor: Palette.paper,
        foregroundColor: Palette.ink,
        title: const Text('Simulation', style: TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular)),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Learner', style: title),
          const SizedBox(height: 6),
          SegmentedButton<LearnerKind>(
            segments: [for (final k in LearnerKind.values) ButtonSegment(value: k, label: Text(k.name))],
            selected: {_learner},
            onSelectionChanged: _running ? null : (s) => setState(() => _learner = s.single),
          ),
          const SizedBox(height: 12),
          Text('Pace', style: title),
          const SizedBox(height: 6),
          SegmentedButton<LearningPace>(
            segments: [
              for (final p in LearningPace.values)
                ButtonSegment(value: p, label: Text('${p.name} · ${p.profile.dailyRounds}/day')),
            ],
            selected: {pace},
            onSelectionChanged: _running ? null : (s) => setState(() => _pace = s.single),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text('Days', style: title),
            Expanded(
              child: Slider(
                value: _days.toDouble(),
                min: SimulationTuning.minDays.toDouble(),
                max: SimulationTuning.maxDays.toDouble(),
                divisions: SimulationTuning.maxDays - SimulationTuning.minDays,
                label: '$_days',
                onChanged: _running ? null : (v) => setState(() => _days = v.round()),
              ),
            ),
            SizedBox(width: 32, child: Text('$_days', style: _mono, textAlign: TextAlign.end)),
          ]),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _running ? null : () => _simulate(pace),
            child: Text(_running ? 'Simulating… day ${_result.length} / $_days' : 'Simulate'),
          ),
          const Text('Runs on a throwaway database: your progress is untouched.', style: _mono),
          if (_running) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _result.length / _days),
          ],
          if (_error != null) Text('$_error', style: _mono.copyWith(color: Palette.pinkDeep)),
          if (_result.isNotEmpty) ...[
            const Divider(height: 32),
            _Summary(_result, pace),
            const SizedBox(height: 16),
            ..._charts(_result),
          ],
          const Divider(height: 32),
          Text('Demo data', style: title),
          const Text(
            'Seeds your progress with the run above (runs one first if none yet): for celebrations, due cards and Stats.',
            style: _mono,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _running ? null : () => _seedDemoData(pace),
            child: const Text('Seed demo data'),
          ),
        ]),
      ),
    );
  }

  static List<Widget> _charts(List<SimulatedDay> days) {
    List<double> of(num? Function(SimulatedDay d) f) => [for (final d in days) f(d)?.toDouble() ?? double.nan];
    return [
      _Chart('Cards unlocked vs pace target', top: days.first.total.toDouble(), [
        DailySeries('target', of((d) => d.target), Palette.mute, dashed: true),
        DailySeries('unlocked', of((d) => d.unlocked), Palette.seaDeep),
      ]),
      _Chart('New cards', [DailySeries('new', of((d) => d.newCards), Palette.pink, bars: true)]),
      _Chart('Swipes and FSRS reviews', [
        DailySeries('swipes', of((d) => d.swipes), Palette.shallow, bars: true),
        DailySeries('reviews', of((d) => d.reviews), Palette.ink),
      ]),
      _Chart('Recall (share of swipes known)', top: 1, [DailySeries('recall', of((d) => d.recall), Palette.landDeep)]),
      _Chart('Due at the start of the day', [DailySeries('due', of((d) => d.dueAtStart), Palette.violet, bars: true)]),
      _Chart('Rating', [DailySeries('rating', of((d) => d.rating), Palette.pinkDeep)]),
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.days, this.pace);
  final List<SimulatedDay> days;
  final LearningPace pace;

  @override
  Widget build(BuildContext context) {
    final reached = days.where((d) => d.unlocked == d.total);
    final last = days.last;
    final swipes = days.fold(0, (n, d) => n + d.swipes);
    final misses = days.fold(0, (n, d) => n + d.misses);
    Widget line(String k, String v) => Row(children: [
          SizedBox(width: SimulationStyle.labelWidth, child: Text(k, style: _mono.copyWith(color: Palette.mute))),
          Expanded(child: Text(v, style: _mono)),
        ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line('all ${last.total} cards', reached.isEmpty
          ? 'not yet: ${last.unlocked} on day ${last.day}'
          : 'day ${reached.first.day} (pace: day ${pace.profile.daysToAll})'),
      line('swipes', '$swipes (${(swipes / days.length).round()} a day)'),
      line('FSRS reviews', '${days.fold(0, (n, d) => n + d.reviews)}'),
      line('recall', '${(100 * (1 - misses / swipes)).toStringAsFixed(1)}%'),
      line('rating', last.rating?.toStringAsFixed(0) ?? '—'),
    ]);
  }
}

class _Chart extends StatelessWidget {
  const _Chart(this.title, this.series, {this.top});
  final String title;
  final List<DailySeries> series;
  final double? top;

  @override
  Widget build(BuildContext context) {
    final chart = DailyChart(series: series, top: top);
    final days = series.first.values.length;
    final topLabel = chart.scaleTop <= 1 ? '${(chart.scaleTop * 100).round()}%' : chart.scaleTop.round().toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: SimulationStyle.chartGap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: SimulationStyle.legendGap, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(title, style: const TextStyle(fontWeight: Weights.black)),
          for (final s in series)
            Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox.square(dimension: SimulationStyle.swatch, child: ColoredBox(color: s.color)),
              const SizedBox(width: 4),
              Text(s.label, style: _mono),
            ]),
        ]),
        const SizedBox(height: 4),
        Text(topLabel, style: _mono),
        SizedBox(height: SimulationStyle.chartHeight, child: chart),
        Row(children: [
          const Text('day 1', style: _mono),
          const Spacer(),
          Text('day $days', style: _mono),
        ]),
      ]),
    );
  }
}
