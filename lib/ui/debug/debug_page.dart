import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/rating.dart';
import '../../domain/trainer.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import 'debug_common.dart';
import 'reset_actions.dart';

const _mono = debugMono;

String _ms(double? v) => v == null ? '—' : v.toStringAsFixed(0);

bool _sameLocalDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Training rounds started today, and attempts recorded across all of them.
(int rounds, int attempts) _today(Progress p, DateTime now) {
  final rounds = p.sessions.where((s) => _sameLocalDay(s.startedAt.toLocal(), now)).length;
  var attempts = 0;
  for (final k in p.trainer.items.keys) {
    attempts += p.attemptsOf(k).where((a) => _sameLocalDay(a.at.toLocal(), now)).length;
  }
  return (rounds, attempts);
}

/// Everything the scheduler, FSRS and the timing code know. For nerds.
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Palette.paper,
        appBar: AppBar(
          backgroundColor: Palette.paper,
          foregroundColor: Palette.ink,
          title: const Text('SRS Debug Info', style: TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular)),
          bottom: const TabBar(isScrollable: true, indicatorColor: Palette.pink, tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Items'),
            Tab(text: 'Scheduler'),
            Tab(text: 'Rating'),
          ]),
        ),
        // Edge-to-edge system UI means the bottom system bar/gesture strip
        // would otherwise sit over the last row of every tab's list.
        body: const SafeArea(
          child: TabBarView(children: [
            _Overview(),
            _Items(),
            _Scheduler(),
            _RatingTab(),
          ]),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final t = p.trainer;
    final c = t.config;
    final stats = p.allStats;
    final unlocked = t.unlocked.toList();
    final solid = unlocked.where((s) => stats[s.key]!.solid(t.goalMs)).length;
    final now = DateTime.now();
    final due = unlocked.where((s) => t.isDue(s.key, now)).length;
    final next = t.nextBatch(poems, fudaSets);
    final status = p.paceStatus(now);
    final readiness = status.readiness;
    final ahead = p.learnAhead(now);
    final (roundsToday, attemptsToday) = _today(p, now);
    return ListView(padding: const EdgeInsets.all(16), children: [
      DebugKV('goal level', '${t.goalLevel}  (${t.goalMs.toStringAsFixed(0)} ms)'),
      DebugKV('goal ladder', c.goalsMs.join(' → ')),
      DebugKV('unlocked items', '${unlocked.length} (${unlocked.where((s) => s.key.inverted).length} inverted)'),
      DebugKV('solid at goal', '$solid / ${unlocked.length}'),
      DebugKV('all solid', '${t.allSolid(stats)}'),
      DebugKV('next batch', next.map((id) => poems[id].kimariji).join(' ')),
      DebugKV('due now', '$due'),
      DebugKV('attempts stored', '${stats.values.fold<int>(0, (a, s) => a + s.count)}'),
      DebugKV('sessions', '${p.sessions.length}'),
      DebugKV('streak', '${p.streak} days'),
      const Divider(height: 32),
      Text('Journey pace', style: Theme.of(context).textTheme.titleMedium),
      DebugKV('learning mode / pace', '${c.learningMode.name} / ${c.pace.name}'
          ' (${c.pace.profile.daysToAll}d, cap ${c.pace.profile.dailyAutoCap}/day,'
          ' routine ${c.pace.profile.dailyRounds} rounds/day)'),
      DebugKV('journey day', '${status.day}'),
      DebugKV('unlocked / target / total', '${status.unlocked} / ${status.target} / ${status.total}'),
      DebugKV('readiness',
          '${(readiness.solidFraction * 100).toStringAsFixed(0)}% solid (${readiness.solid}/${readiness.unlocked})'
          ', ${readiness.underPractised.length} under-practised, ready=${readiness.ready}'),
      DebugKV('hold', status.hold.name),
      DebugKV('next auto-unlock',
          status.nextPaceDay == null ? '—' : 'day ${status.nextPaceDay} (${status.nextPaceDay! - status.day}d away)'),
      DebugKV('new today', '${status.newToday}'),
      DebugKV('Home Learn ahead', '${ahead.lock.name}, ${ahead.unlocked - ahead.shaky}/${ahead.unlocked} well remembered'),
      DebugKV('rounds / attempts today', '$roundsToday / $attemptsToday'),
      const SizedBox(height: 4),
      const Text('day  target', style: _mono),
      for (var d = status.day; d <= status.day + PaceTuning.debugLookaheadDays; d++)
        Text(
          '${d.toString().padLeft(3)}  ${c.pace.targetUnlocked(d, status.total).toString().padLeft(3)}'
          '${d == status.day ? '   (now: ${status.unlocked})' : ''}',
          style: _mono,
        ),
      const Divider(height: 32),
      Text('Knobs', style: Theme.of(context).textTheme.titleMedium),
      _Stepper('unlock batch size', c.batchSize, 1, 8, (v) => p.updateTrainerConfig(c.copyWith(batchSize: v))),
      _Stepper('session length', c.sessionLength, 10, 100,
          (v) => p.updateTrainerConfig(c.copyWith(sessionLengthOverride: v)), step: 5),
      _Stepper('easy ≤ ms', c.easyMs, TrainingTuning.easyMsMin, TrainingTuning.easyMsMax,
          (v) => p.updateTrainerConfig(c.copyWith(easyMs: v)), step: TrainingTuning.easyMsStep),
      _Slider('good ≤ goal ×', c.goodRatio, 1.0, 3.0, (v) => p.updateTrainerConfig(c.copyWith(goodRatio: v))),
      _Slider('desired retention', c.desiredRetention, 0.7, 0.99,
          (v) => p.updateTrainerConfig(c.copyWith(desiredRetention: v))),
      const SizedBox(height: 8),
      SegmentedButton<ReverseMode>(
        segments: const [
          ButtonSegment(value: ReverseMode.afterMastery, label: Text('逆さま after mastery')),
          ButtonSegment(value: ReverseMode.mixed, label: Text('mixed')),
          ButtonSegment(value: ReverseMode.uprightOnly, label: Text('upright only')),
        ],
        selected: {c.reverseMode},
        onSelectionChanged: (s) => p.updateTrainerConfig(c.copyWith(reverseMode: s.first)),
      ),
      const Divider(height: 32),
      Row(children: [
        OutlinedButton(
          onPressed: () => confirmResetOnboarding(context),
          child: const Text('Reset onboarding'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => confirmResetProgress(context),
          child: const Text('Reset progress'),
        ),
      ]),
    ]);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(this.label, this.value, this.min, this.max, this.onChanged, {this.step = 1});
  final String label;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label)),
        IconButton(onPressed: value > min ? () => onChanged(value - step) : null, icon: const Icon(Icons.remove)),
        Text('$value', style: _mono),
        IconButton(onPressed: value < max ? () => onChanged(value + step) : null, icon: const Icon(Icons.add)),
      ]);
}

class _Slider extends StatefulWidget {
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged);
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  late double _v = widget.value;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: 140, child: Text(widget.label)),
        Expanded(
          child: Slider(
            value: _v,
            min: widget.min,
            max: widget.max,
            onChanged: (v) => setState(() => _v = v),
            onChangeEnd: widget.onChanged,
          ),
        ),
        SizedBox(width: 44, child: Text(_v.toStringAsFixed(2), style: _mono)),
      ]);
}

enum _Sort { id, ewma, retrievability, due, miss, attempts }

class _Items extends StatefulWidget {
  const _Items();

  @override
  State<_Items> createState() => _ItemsState();
}

class _ItemsState extends State<_Items> {
  _Sort _sort = _Sort.id;
  bool _unlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final t = p.trainer;
    final now = DateTime.now();
    var keys = t.items.keys.toList();
    if (_unlockedOnly) keys = keys.where((k) => t.items[k]!.unlocked).toList();
    double sortVal(ItemKey k) => switch (_sort) {
          _Sort.id => k.id.toDouble(),
          _Sort.ewma => -(p.stats(k).ewmaMs ?? -1),
          _Sort.retrievability => t.items[k]!.reviewed ? t.retrievability(k, now) : 9,
          _Sort.due => t.items[k]!.reviewed ? t.items[k]!.card.due.millisecondsSinceEpoch.toDouble() : double.maxFinite,
          _Sort.miss => -p.stats(k).missRate(),
          _Sort.attempts => -p.stats(k).count.toDouble(),
        };
    keys.sort((a, b) => sortVal(a).compareTo(sortVal(b)));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          DropdownButton<_Sort>(
            value: _sort,
            items: [for (final s in _Sort.values) DropdownMenuItem(value: s, child: Text('sort: ${s.name}'))],
            onChanged: (s) => setState(() => _sort = s!),
          ),
          const Spacer(),
          const Text('unlocked only'),
          Switch(value: _unlockedOnly, onChanged: (v) => setState(() => _unlockedOnly = v)),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('item  kimariji   st  S(d)   D     R    n  ewma  med5  p95  miss', style: _mono),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final k = keys[i];
            final s = t.items[k]!;
            final st = p.stats(k);
            final c = s.card;
            final state = !s.unlocked ? '··' : (!s.reviewed ? 'new' : switch (c.state) {
                fsrs.State.learning => 'L${c.step}',
                fsrs.State.review => 'R',
                fsrs.State.relearning => 'RL',
              });
            final line = '${k.toString().padRight(5)} ${poems[k.poemId].kimariji.padRight(7, '　')}'
                ' ${state.padRight(3)}'
                ' ${(c.stability ?? 0).toStringAsFixed(2).padLeft(6)}'
                ' ${(c.difficulty ?? 0).toStringAsFixed(1).padLeft(4)}'
                ' ${s.reviewed ? t.retrievability(k, now).toStringAsFixed(2) : ' —  '}'
                ' ${st.count.toString().padLeft(3)}'
                ' ${_ms(st.ewmaMs).padLeft(5)} ${_ms(st.median(5)).padLeft(5)} ${_ms(st.percentile(50, 95)).padLeft(5)}'
                ' ${(st.missRate() * 100).toStringAsFixed(0).padLeft(3)}%';
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDebugPage(k))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Text(line,
                    style: _mono.copyWith(
                      color: st.solid(t.goalMs) ? Colors.green.shade700 : (s.unlocked ? null : Colors.grey),
                    )),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// Raw data of one item.
class ItemDebugPage extends StatelessWidget {
  const ItemDebugPage(this.itemKey, {super.key});
  final ItemKey itemKey;

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final t = p.trainer;
    final s = t.items[itemKey]!;
    final st = p.stats(itemKey);
    final poem = poems[itemKey.poemId];
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text('${poem.kimariji}  #${poem.id}${itemKey.inverted ? ' 逆さま' : ''}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${poem.kami}\n${poem.shimo}'),
        const SizedBox(height: 12),
        DebugKV('torifuda', poem.columns.join(' / ')),
        DebugKV('unlocked', '${s.unlocked} ${s.unlockedAt ?? ''}'),
        DebugKV('fsrs state', '${s.card.state.name} step=${s.card.step}'),
        DebugKV('stability', '${s.card.stability?.toStringAsFixed(3) ?? '—'} days'),
        DebugKV('difficulty', s.card.difficulty?.toStringAsFixed(3) ?? '—'),
        DebugKV('retrievability', s.reviewed ? t.retrievability(itemKey, now).toStringAsFixed(4) : '—'),
        DebugKV('due', s.reviewed ? '${s.card.due.toLocal()}' : '—'),
        DebugKV('last review', '${s.card.lastReview?.toLocal() ?? '—'}'),
        DebugKV('attempts / timed', '${st.count} / ${st.timed.length}'),
        DebugKV('ewma (geo, hl=5)', _ms(st.ewmaMs)),
        for (final n in [5, 10, 50, 100])
          DebugKV('last $n  mean/med/p95', '${_ms(st.mean(n))} / ${_ms(st.median(n))} / ${_ms(st.percentile(n, 95))}'),
        DebugKV('best', _ms(st.bestMs)),
        DebugKV('miss rate (10)', '${(st.missRate() * 100).toStringAsFixed(1)}%'),
        DebugKV('expected ms', st.expectedMs().toStringAsFixed(0)),
        DebugKV('solid @ goal', '${st.solid(t.goalMs)}'),
        DebugKV('mastered', '${t.mastered(itemKey, st)}'),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: CustomPaint(painter: _ScatterPainter(st))),
        const SizedBox(height: 12),
        const Text('when                 ms      grade flags', style: _mono),
        for (final a in st.all.reversed)
          Text(
            '${a.at.toLocal().toString().substring(0, 19)} ${a.ms.toStringAsFixed(1).padLeft(8)}'
            '  ${a.grade == null ? '-' : fsrs.Rating.values.firstWhere((r) => r.value == a.grade).name.padRight(5)}'
            ' ${a.miss ? 'MISS ' : ''}${a.clean ? '' : 'tainted '}${a.maskLevel > 0 ? 'mask${a.maskLevel} ' : ''}deck${a.deckSize}',
            style: _mono,
          ),
      ]),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter(this.st);
  final CardStats st;

  @override
  void paint(Canvas canvas, Size size) {
    final v = st.timed;
    final axis = Paint()..color = Colors.grey.withValues(alpha: 0.4);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    if (v.isEmpty) return;
    final maxV = v.reduce(math.max) * 1.1;
    Offset pt(int i, double ms) =>
        Offset(v.length == 1 ? size.width / 2 : i / (v.length - 1) * size.width, size.height * (1 - ms / maxV));
    final dot = Paint()..color = Colors.blueGrey;
    for (var i = 0; i < v.length; i++) {
      canvas.drawCircle(pt(i, v[i]), 2.5, dot);
    }
    for (final (w, color) in [(5, Colors.orange), (10, Colors.red), (50, Colors.purple)]) {
      final r = st.rollingMean(w);
      final path = Path()..moveTo(pt(0, r[0]).dx, pt(0, r[0]).dy);
      for (var i = 1; i < r.length; i++) {
        path.lineTo(pt(i, r[i]).dx, pt(i, r[i]).dy);
      }
      canvas.drawPath(path, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_ScatterPainter old) => old.st != st;
}

class _Scheduler extends StatefulWidget {
  const _Scheduler();

  @override
  State<_Scheduler> createState() => _SchedulerState();
}

class _SchedulerState extends State<_Scheduler> {
  int _seed = 1;

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final now = DateTime.now();
    final scheduler = p.trainer.scheduler;
    final config = p.trainer.config;
    final picks = p.trainer.planSession(p.allStats, now, math.Random(_seed));
    final counts = <PickReason, int>{};
    for (final x in picks) {
      counts[x.reason] = (counts[x.reason] ?? 0) + 1;
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Text('Preview of the next training session (dry run, seed $_seed)')),
        IconButton(onPressed: () => setState(() => _seed++), icon: const Icon(Icons.casino)),
      ]),
      DebugKV('pick-reason mix', counts.entries.map((e) => '${e.key.name}:${e.value}').join('  ')),
      const SizedBox(height: 8),
      for (final (i, x) in picks.indexed)
        Text(
          '${(i + 1).toString().padLeft(2)}. ${x.key.toString().padRight(5)} ${poems[x.key.poemId].kimariji.padRight(7, '　')}'
          ' ${x.reason.name.padRight(11)} w=${x.weight.toStringAsFixed(2)}',
          style: _mono,
        ),
      const Divider(height: 32),
      Text('FSRS', style: Theme.of(context).textTheme.titleMedium),
      DebugKV('desired retention', scheduler.desiredRetention.toStringAsFixed(2)),
      DebugKV('parameters', scheduler.parameters.map((v) => v.toStringAsFixed(3)).join(', ')),
      DebugKV('due now / +1d / +3d',
          '${p.dueCount(now)} / ${p.dueCount(now.add(const Duration(days: 1)))} / ${p.dueCount(now.add(const Duration(days: 3)))}'),
      const Divider(height: 32),
      Text('TrainerConfig', style: Theme.of(context).textTheme.titleMedium),
      for (final e in config.toJson().entries) DebugKV(e.key, '${e.value}'),
      const Divider(height: 32),
      Text('Scheduler tuning', style: Theme.of(context).textTheme.titleMedium),
      DebugKV('dueShare / freshWeight', '${TrainingTuning.dueShare} / ${TrainingTuning.freshWeight}'),
      DebugKV('newCardMinTimed / newCardMaxShare', '${TrainingTuning.newCardMinTimed} / ${TrainingTuning.newCardMaxShare}'),
      DebugKV('slowness clamp', '${TrainingTuning.slownessClampMin}–${TrainingTuning.slownessClampMax}'),
      DebugKV('missWeightFactor / recencyCapDays', '${TrainingTuning.missWeightFactor} / ${TrainingTuning.recencyCapDays}'),
      DebugKV('unsolid× / maintenance×',
          '${TrainingTuning.unsolidWeightMultiplier} / ${TrainingTuning.maintenanceWeightMultiplier}'),
      DebugKV('recentRepeatWindow', '${TrainingTuning.recentRepeatWindow}'),
      DebugKV('requeue gap / cap growth', '${TrainingTuning.requeueGap} / ${TrainingTuning.requeueCapGrowth}'),
      DebugKV('pace readySolidFraction', '${PaceTuning.readySolidFraction}'),
      DebugKV('pace curve', PaceTuning.curve.map((k) => '(${k.$1},${k.$2})').join(' ')),
    ]);
  }
}

class _RatingTab extends StatelessWidget {
  const _RatingTab();

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final projected = p.projectedMs;
    final perf = Rating.performance(projected);
    final rows = [
      for (var id = 1; id <= 100; id++)
        (id, Rating.cardExpectedMs(p.stats(ItemKey(id, false)), p.stats(ItemKey(id, true)))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return ListView(padding: const EdgeInsets.all(16), children: [
      DebugKV('projected 100 (s)', (projected / 1000).toStringAsFixed(2)),
      DebugKV('performance P', perf.toStringAsFixed(1)),
      DebugKV('rating R', p.rating?.toStringAsFixed(1) ?? '— (no runs yet)'),
      DebugKV('band', Rating.bandOf(p.rating ?? perf).label),
      DebugKV('next band', Rating.nextBand(p.rating ?? perf)?.label ?? '—'),
      DebugKV('formula', 'P = 600·log2(1000 s / T), R += K(P−R)'),
      DebugKV('rating points', '${p.ratingPoints.length}'),
      const Divider(height: 24),
      const Text('Card contributions to T (worst first)', style: _mono),
      for (final (id, ms) in rows)
        Text('${id.toString().padLeft(3)} ${poems[id].kimariji.padRight(7, '　')} ${(ms / 1000).toStringAsFixed(3).padLeft(7)} s',
            style: _mono),
    ]);
  }
}
