import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/ankiren_tomofuda.dart';
import '../../domain/rating.dart';
import '../../state/scope.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_debug_game.dart';
import 'ankiren_graphs.dart';
import 'debug_common.dart';

/// The developer's 暗記練 tools: the level table (with ranked's setup as
/// R), a live points calculator for ranked, ranked's classes as times per
/// card, a ranked total-points graph and a middle-card simulator.
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
          Text('Tap points', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _TapPointsTable(),
          const Divider(height: 32),
          Text('Ranked points', style: title),
          const _PointsCalculator(),
          const Divider(height: 32),
          Text('Ranked classes by time per card', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _ClassTable(),
          const Divider(height: 32),
          Text('Ranked total by card time', style: title),
          const AnkirenRankedGraph(),
          const Divider(height: 32),
          Text('Middle cards', style: title),
          const _MiddleSimulator(),
        ],
      ),
    );
  }
}

/// What a tap earns by where it lands, as the first and as the second tap
/// (weighted), and a first tap there followed by the right card.
class _TapPointsTable extends StatelessWidget {
  const _TapPointsTable();

  static const _names = {
    TapProximity.card: 'Spot on',
    TapProximity.neighbour: 'Neighbour',
    TapProximity.row: 'Same row',
    TapProximity.quadrant: 'Same quadrant',
    TapProximity.side: 'Same side',
    TapProximity.otherSide: 'Other side',
  };

  static String _points(TapProximity place, int tap) =>
      _n(AnkirenTuning.cardPoints * AnkirenTuning.tapShare[place]! * AnkirenTuning.tapWeights[tap]);

  static String _n(double x) => x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

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
          row(['tap on', '1st tap', '2nd tap', '1st+right'], head: true),
          for (final place in TapProximity.values)
            row([
              _names[place]!,
              place == TapProximity.card
                  ? '${AnkirenTuning.cardPoints} + 0–${AnkirenTuning.speedMax} speed'
                  : _points(place, 0),
              _points(place, 1),
              place == TapProximity.card
                  ? '—'
                  : _n(AnkirenScore.pointsOf([place, TapProximity.card], null).toDouble()),
            ]),
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
  static const _setup = AnkirenSetup.ranked();
  double _responseMs = AnkirenToolsTuning.responseStart.inMilliseconds.toDouble();

  /// Where the first and second taps landed; null for no tap.
  TapProximity? _first = TapProximity.card;
  TapProximity? _second;
  double _timeLeft = 0;

  int get _memoriseSeconds => _setup.memorise.inSeconds;

  @override
  Widget build(BuildContext context) {
    final first = _first;
    final taps = first == null ? const <TapProximity>[] : [first, if (first != TapProximity.card) ?_second];
    final tapUs = (_responseMs * 1000).round();
    final share = _timeLeft.clamp(0, _memoriseSeconds) / _memoriseSeconds;
    final early = 1 + AnkirenTuning.earlyBonus * share;
    final points = AnkirenScore.pointsOf(taps, first == null ? null : tapUs);
    final multiplied = AnkirenScore.foundFirst(taps) ? points : 0;
    final timed = AnkirenScore.speedWeight(taps) > 0;
    Widget picker(String label, TapProximity? selected, ValueChanged<TapProximity?>? onChanged) => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$label ', style: debugMono),
            SegmentedButton<TapProximity?>(
              showSelectedIcon: false,
              segments: [
                for (final p in TapProximity.values) ButtonSegment(value: p, label: Text(p.name)),
                const ButtonSegment(value: null, label: Text('none')),
              ],
              selected: {selected},
              onSelectionChanged: onChanged == null ? null : (s) => onChanged(s.first),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugResponseSlider(label: 'first tap', ms: _responseMs, onChanged: (v) => setState(() => _responseMs = v)),
        picker('tap 1 on', first, (p) => setState(() => _first = p)),
        picker('tap 2 on', taps.length > 1 ? _second : null,
            first == null || first == TapProximity.card ? null : (p) => setState(() => _second = p)),
        DebugSlider(
          label:
              'time left ${formatMinutes(Duration(seconds: _timeLeft.round()))}'
              ' of ${formatMinutes(_setup.memorise)}  (${(share * 100).round()}%)',
          value: _timeLeft.clamp(0, _memoriseSeconds).toDouble(),
          min: 0,
          max: _memoriseSeconds.toDouble(),
          onChanged: (v) => setState(() => _timeLeft = v),
        ),
        const SizedBox(height: AnkirenToolsStyle.gap),
        SizedBox(
          height: AnkirenToolsStyle.chartHeight,
          child: CustomPaint(painter: _BonusPainter(_responseMs, timed)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var s = 0; s <= AnkirenToolsTuning.responseMax.inSeconds; s++) Text('$s s', style: debugMono),
          ],
        ),
        const SizedBox(height: AnkirenToolsStyle.gap),
        DebugKV('speed bonus', '${timed ? AnkirenScore.speedBonus(tapUs) : 0} / ${AnkirenTuning.speedMax}'),
        DebugKV('tap share', AnkirenScore.share(taps).toStringAsFixed(2)),
        DebugKV('per card', '$points'),
        DebugKV('early × (right first tap only)', early.toStringAsFixed(3)),
        DebugKV('per card with early', '${points - multiplied + (multiplied * early).round()}'),
        DebugKV('${_setup.cards} cards, all first taps at this time',
            '${AnkirenScore.firstTryTotal(_setup, responseMs: _responseMs, timeLeft: Duration(seconds: _timeLeft.round()))}'),
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
    for (final MapEntry(key: ms, value: share) in AnkirenTuning.speedTargets.entries) {
      canvas.drawCircle(
        at(ms.toDouble(), share),
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
        Wrap(
          spacing: AnkirenToolsStyle.gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final n in AnkirenToolsTuning.simulationGames)
              ChoiceChip(
                label: Text('$n', style: debugMono),
                selected: n == _games,
                onSelected: (_) => setState(() => _games = n),
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
          row(['L', '/side', 'time', 's/card', 'mid'], head: true),
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
            ]),
          row([
            'R',
            '${AnkirenTuning.rankedPerSide}',
            formatMinutes(AnkirenTuning.rankedMemorise),
            (AnkirenTuning.rankedMemorise.inMilliseconds / 1000 / (2 * AnkirenTuning.rankedPerSide)).toStringAsFixed(1),
            AnkirenDealer.mayHaveMiddle(AnkirenTuning.rankedPerSide)
                ? '≤${AnkirenDealer.maxMiddle(AnkirenTuning.rankedPerSide)}'
                : '—',
          ]),
        ],
      ),
    );
  }
}

/// 暗記練's ranked classes as average first-tap times: for each class line
/// (`Rating.bands`), the time per card at which a ranked game with all
/// its cards right with the first tap reaches it, played to the end of the
/// memorise time and ready early at [AnkirenToolsTuning.classTableReadyAt].
/// A class reached even at the slowest timed find shows the first-tap finds
/// it needs at that time instead. Each class runs from its own line (the
/// slower bound) to the next one's (the faster).
class _ClassTable extends StatelessWidget {
  const _ClassTable();

  static const _setup = AnkirenSetup.ranked();

  /// What reaches [rating] with [timeLeft] to spare: the slowest first-tap
  /// time in ms, or the first-tap finds at the slowest timed find.
  static ({int? ms, int finds}) _reach(double rating, Duration timeLeft) {
    bool reaches(double ms) =>
        AnkirenRating.performance(AnkirenScore.firstTryTotal(_setup, responseMs: ms, timeLeft: timeLeft)) >= rating;
    final slowest = AnkirenTuning.speedNone.inMilliseconds.toDouble();
    if (reaches(slowest)) {
      final share = timeLeft.inMicroseconds / _setup.memorise.inMicroseconds;
      var finds = 0;
      while (finds < _setup.cards &&
          AnkirenRating.performance(AnkirenScore.totalOf(finds * AnkirenTuning.cardPoints, finds * AnkirenTuning.cardPoints, share)) < rating) {
        finds++;
      }
      return (ms: null, finds: finds);
    }
    var fast = AnkirenTuning.speedFull.inMilliseconds, slow = slowest.round();
    while (slow - fast > 1) {
      final mid = (fast + slow) ~/ 2;
      if (reaches(mid.toDouble())) {
        fast = mid;
      } else {
        slow = mid;
      }
    }
    return (ms: fast, finds: _setup.cards);
  }

  static String _range(({int? ms, int finds}) from, ({int? ms, int finds})? to) {
    if (from.ms == null) {
      final most = to == null || to.ms != null ? _setup.cards : to.finds - 1;
      return most == from.finds ? '$most finds' : '${from.finds}–$most finds';
    }
    final slower = (from.ms! / 1000).toStringAsFixed(2);
    if (to == null) return '≤ $slower s';
    return '$slower–${((to.ms! + 1) / 1000).toStringAsFixed(2)} s';
  }

  @override
  Widget build(BuildContext context) {
    final early = _setup.memorise - AnkirenToolsTuning.classTableReadyAt;
    final bands = Rating.bands.skip(1).toList();
    final full = [for (final b in bands) _reach(b.minRating, Duration.zero)];
    final ready = [for (final b in bands) _reach(b.minRating, early)];
    String cell(String text, int width) => text.padRight(width);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'All ${_setup.cards} right with the first tap at one time each; '
        'P = ${AnkirenRating.slope.toStringAsFixed(4)}·(F − ${AnkirenRating.zero.toStringAsFixed(1)}). '
        'A class reached even at ${AnkirenTuning.speedNone.inSeconds} s shows the finds it needs there.',
        style: debugMono.copyWith(color: Colors.grey),
      ),
      const SizedBox(height: 4),
      Text('${cell('class', 6)}${cell('line', 6)}${cell('score', 7)}${cell('${formatMinutes(_setup.memorise)} used', 14)}'
          'ready ${formatMinutes(AnkirenToolsTuning.classTableReadyAt)}',
          style: debugMono.copyWith(fontWeight: Weights.black)),
      for (final (i, b) in bands.indexed)
        Text(
          '${cell(b.labelEn, 6)}${cell(b.minRating.round().toString(), 6)}'
          '${cell(AnkirenRating.scoreFor(b.minRating).round().toString(), 7)}'
          '${cell(_range(full[i], full.elementAtOrNull(i + 1)), 14)}'
          '${_range(ready[i], ready.elementAtOrNull(i + 1))}',
          style: debugMono,
        ),
    ]);
  }
}
