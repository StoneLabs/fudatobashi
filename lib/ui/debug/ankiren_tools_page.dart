import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/ankiren_tomofuda.dart';
import '../../state/scope.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_debug_game.dart';
import 'ankiren_graphs.dart';
import 'debug_common.dart';

/// The developer's 暗記練 tools: the level table, a live points calculator,
/// total-points graphs across the levels and a middle-card simulator.
class AnkirenToolsPage extends StatelessWidget {
  const AnkirenToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    return DebugScaffold(
      title: 'AnkiRen',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Levels', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _LevelTable(),
          const Divider(height: 32),
          Text('Points', style: title),
          const _PointsCalculator(),
          const Divider(height: 32),
          Text('Total by time used', style: title),
          const AnkirenTimeUsedGraph(),
          const Divider(height: 32),
          Text('Total by card time', style: title),
          const AnkirenCardTimeGraph(),
          const Divider(height: 32),
          Text('Middle cards', style: title),
          const _MiddleSimulator(),
        ],
      ),
    );
  }
}

class _PointsCalculator extends StatefulWidget {
  const _PointsCalculator();

  @override
  State<_PointsCalculator> createState() => _PointsCalculatorState();
}

class _PointsCalculatorState extends State<_PointsCalculator> {
  int _level = AnkirenLevels.top;
  double _responseMs = AnkirenToolsTuning.responseStart.inMilliseconds.toDouble();
  int _wrongTaps = 0;
  double _timeLeft = 0;

  static const _wrongLabels = ['0', '1', 'shown'];

  int get _memoriseSeconds => AnkirenLevels.of(_level).memorise.inSeconds;

  @override
  Widget build(BuildContext context) {
    final answer = AnkirenAnswer(
      poemId: 0,
      side: FieldSide.own,
      wrongTaps: _wrongTaps == 2 ? AnkirenTuning.revealAfterWrong : _wrongTaps,
      responseUs: (_responseMs * 1000).round(),
      at: DateTime.now(),
    );
    final share = _timeLeft.clamp(0, _memoriseSeconds) / _memoriseSeconds;
    final early = 1 + AnkirenTuning.earlyBonus * share;
    final factor = AnkirenScore.factorFor(AnkirenSetup.forLevel(_level));
    final points = AnkirenScore.points(answer);
    final firstTry = _wrongTaps == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugLevelChips(level: _level, onChanged: (l) => setState(() => _level = l)),
        DebugSlider(
          label: 'response ${(_responseMs / 1000).toStringAsFixed(1)} s',
          value: _responseMs,
          min: AnkirenToolsTuning.responseMin.inMilliseconds.toDouble(),
          max: AnkirenToolsTuning.responseMax.inMilliseconds.toDouble(),
          divisions:
              (AnkirenToolsTuning.responseMax - AnkirenToolsTuning.responseMin).inMilliseconds ~/
              AnkirenToolsTuning.responseStep.inMilliseconds,
          onChanged: (v) => setState(() => _responseMs = v),
        ),
        Row(
          children: [
            Text('wrong taps ', style: debugMono),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [for (final (i, l) in _wrongLabels.indexed) ButtonSegment(value: i, label: Text(l))],
              selected: {_wrongTaps},
              onSelectionChanged: (s) => setState(() => _wrongTaps = s.first),
            ),
          ],
        ),
        DebugSlider(
          label:
              'time left ${formatMinutes(Duration(seconds: _timeLeft.round()))}'
              ' of ${formatMinutes(AnkirenLevels.of(_level).memorise)}  (${(share * 100).round()}%)',
          value: _timeLeft.clamp(0, _memoriseSeconds).toDouble(),
          min: 0,
          max: _memoriseSeconds.toDouble(),
          onChanged: (v) => setState(() => _timeLeft = v),
        ),
        const SizedBox(height: AnkirenToolsStyle.gap),
        SizedBox(
          height: AnkirenToolsStyle.chartHeight,
          child: CustomPaint(painter: _BonusPainter(_responseMs, firstTry)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var s = 0; s <= AnkirenToolsTuning.responseMax.inSeconds; s++) Text('$s s', style: debugMono),
          ],
        ),
        const SizedBox(height: AnkirenToolsStyle.gap),
        DebugKV(
          'speed bonus',
          firstTry ? '${AnkirenScore.speedBonus(answer.responseUs!)} / ${AnkirenTuning.speedMax}' : '—',
        ),
        DebugKV('per card', '$points'),
        DebugKV('early ×', early.toStringAsFixed(3)),
        DebugKV('level ×', factor.toStringAsFixed(3)),
        DebugKV('scored', '${(points * early * factor).round()}'),
      ],
    );
  }
}

/// The speed bonus over the response time, the fitted targets as dots and a
/// marker at the chosen time.
class _BonusPainter extends CustomPainter {
  _BonusPainter(this.responseMs, this.marked);

  final double responseMs;
  final bool marked;

  @override
  void paint(Canvas canvas, Size size) {
    final until = AnkirenToolsTuning.responseMax.inMilliseconds.toDouble();
    Offset at(double ms, double share) => Offset(size.width * ms / until, size.height * (1 - share));
    final curve = Path()..moveTo(0, size.height * (1 - AnkirenScore.speedShare(0)));
    for (var t = AnkirenToolsTuning.curveStepMs; t <= until; t += AnkirenToolsTuning.curveStepMs) {
      final p = at(t.toDouble(), AnkirenScore.speedShare(t.toDouble()));
      curve.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AnkirenToolsStyle.curveStroke
        ..color = Palette.seaDeep,
    );
    for (final MapEntry(key: ms, value: bonus) in AnkirenTuning.speedTargets.entries) {
      canvas.drawCircle(
        at(ms.toDouble(), bonus / AnkirenTuning.speedMax),
        AnkirenToolsStyle.targetRadius,
        Paint()..color = Palette.pink,
      );
    }
    final x = size.width * responseMs / until;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..strokeWidth = AnkirenToolsStyle.markerStroke
        ..color = marked ? Palette.ink : Palette.mute,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Palette.desk,
    );
  }

  @override
  bool shouldRepaint(_BonusPainter old) => old.responseMs != responseMs || old.marked != marked;
}

/// A simulation's tally of the middle cards: per side, per game, and by the
/// 友札 family a middle card splits (once per side).
class _MiddleResult {
  _MiddleResult(this.games, this.sides, this.gamesWithMiddle, this.sidesWithMiddle, this.byFamily);

  final int games;
  final int sides;
  final int gamesWithMiddle;
  final int sidesWithMiddle;
  final Map<String, int> byFamily;
}

class _MiddleSimulator extends StatefulWidget {
  const _MiddleSimulator();

  @override
  State<_MiddleSimulator> createState() => _MiddleSimulatorState();
}

class _MiddleSimulatorState extends State<_MiddleSimulator> {
  int _level = AnkirenLevels.top;
  int _games = AnkirenToolsTuning.simulationGamesStart;
  _MiddleResult? _result;
  int? _resultLevel;
  bool _running = false;

  List<int> get _deck => AnkirenDebugGame.deckFor(ProgressScope.read(context).knownCards.toList(), _level);

  Future<void> _run() async {
    final level = _level;
    final deck = _deck;
    setState(() => _running = true);
    await Future<void>.delayed(Duration.zero);
    final tomofuda = AnkirenTomofuda(poems);
    final families = tomofuda.families;
    final familyOf = {
      for (final f in families)
        for (final id in f) id: f,
    };
    final dealer = AnkirenDealer(tomofuda: tomofuda.of, kimarijiLength: (id) => poems[id].kimariji.length);
    final setup = AnkirenSetup.forLevel(level);
    final rng = math.Random();
    var gamesWith = 0, sidesWith = 0;
    final byFamily = <String, int>{};
    for (var g = 0; g < _games; g++) {
      final field = dealer.deal(deck, setup.perSide, rng, allInMiddle: setup.allInMiddle);
      var any = false;
      for (final side in FieldSide.values) {
        final middle = field.half(side).middleCards;
        if (middle.isEmpty) continue;
        any = true;
        sidesWith++;
        for (final f in {for (final c in middle) familyOf[c]}.nonNulls) {
          final name = _familyName(f);
          byFamily[name] = (byFamily[name] ?? 0) + 1;
        }
      }
      if (any) gamesWith++;
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _resultLevel = level;
      _result = _MiddleResult(_games, 2 * _games, gamesWith, sidesWith, byFamily);
    });
  }

  static String _familyName(List<int> family) {
    final names = [for (final id in family) poems[id].kimariji];
    var prefix = names.first;
    for (final n in names) {
      var i = 0;
      while (i < prefix.length && i < n.length && prefix[i] == n[i]) {
        i++;
      }
      prefix = prefix.substring(0, i);
    }
    return '$prefix  ${names.join(' ')}';
  }

  void _openGame() {
    final deck = _deck;
    final setup = AnkirenSetup.forLevel(_level);
    final dealer = AnkirenDealer.ofPoems();
    final start = math.Random().nextInt(1 << 30);
    int? found;
    for (var i = 0; i < AnkirenToolsTuning.seedSearchLimit && found == null; i++) {
      final f = dealer.deal(deck, setup.perSide, math.Random(start + i), allInMiddle: setup.allInMiddle);
      if (f.own.middleCards.isNotEmpty || f.opponent.middleCards.isNotEmpty) found = start + i;
    }
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No seed with middle cards')));
      return;
    }
    startAnkirenTest(context, level: _level, seed: found);
  }

  String _pct(int n, int of) => '${(100 * n / of).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final rules =
        'chance ${(AnkirenTuning.middleChancePerSide * 100).round()}%/side'
        '  ${AnkirenTuning.middleMin}–${AnkirenTuning.middleMax} cards'
        '  ≥ ${AnkirenTuning.middleMinPerSide}/side  row ${AnkirenTuning.middleRow.name}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rules, style: debugMono.copyWith(color: Palette.mute)),
        const SizedBox(height: AnkirenToolsStyle.gap),
        DebugLevelChips(level: _level, onChanged: (l) => setState(() => _level = l)),
        Row(
          children: [
            for (final n in AnkirenToolsTuning.simulationGames)
              Padding(
                padding: const EdgeInsets.only(right: AnkirenToolsStyle.gap),
                child: ChoiceChip(
                  label: Text('$n', style: debugMono),
                  selected: n == _games,
                  onSelected: (_) => setState(() => _games = n),
                ),
              ),
            FilledButton(onPressed: _running ? null : _run, child: Text(_running ? '…' : 'Run L$_level')),
          ],
        ),
        if (result != null) ...[
          const SizedBox(height: AnkirenToolsStyle.gap),
          DebugKV('level / games', 'L$_resultLevel × ${result.games}'),
          DebugKV('sides with middle', '${_pct(result.sidesWithMiddle, result.sides)}  (${result.sidesWithMiddle})'),
          DebugKV('games with middle', '${_pct(result.gamesWithMiddle, result.games)}  (${result.gamesWithMiddle})'),
          const SizedBox(height: AnkirenToolsStyle.gap),
          for (final e in (result.byFamily.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
            Text('${e.value.toString().padLeft(5)}  ${_pct(e.value, result.sides)}  ${e.key}', style: debugMono),
        ],
        const SizedBox(height: AnkirenToolsStyle.gap),
        OutlinedButton(onPressed: _openGame, child: Text('Open L$_level game with middle cards')),
      ],
    );
  }
}

class _LevelTable extends StatelessWidget {
  const _LevelTable();

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
            child: Text(c, style: head ? debugMono.copyWith(fontWeight: Weights.black) : debugMono),
          ),
      ],
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          row(['L', '/side', 'time', 's/card', 'mid', '×lvl', 'rate'], head: true),
          for (final (i, l) in AnkirenLevels.all.indexed)
            row([
              '$i',
              '${l.perSide}',
              formatMinutes(l.memorise),
              (l.memorise.inMilliseconds / 1000 / l.cards).toStringAsFixed(1),
              l.allInMiddle
                  ? 'all'
                  : AnkirenDealer.mayHaveMiddle(l.perSide)
                  ? '≤${AnkirenDealer.maxMiddle(l.perSide)}'
                  : '—',
              AnkirenScore.factorFor(AnkirenSetup.forLevel(i)).toStringAsFixed(3),
              AnkirenRatingModel.levelRatings[i].toStringAsFixed(0),
            ]),
        ],
      ),
    );
  }
}
