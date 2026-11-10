import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/level_ladder.dart';
import '../../domain/rank_ladder.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_score.dart';
import '../../domain/trip_rating.dart';
import '../play/time_format.dart';
import 'ankiren_graphs.dart';
import 'debug_common.dart';
import 'tap_points_table.dart';

/// The developer's 定位置 tools: the level table (with the custom games as C
/// and ranked as R), the tap points it shares with 暗記練, the placing
/// bonus, a live points calculator for ranked, ranked's classes by placing
/// time and the rating by score.
class TeiichiToolsPage extends StatelessWidget {
  const TeiichiToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    return DebugScaffold(
      title: 'Teiichi',
      child: ListView(
        padding: AnkirenToolsStyle.padding,
        children: [
          Text('Levels', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _LevelTable(),
          const Divider(height: AnkirenToolsStyle.sectionGap),
          Text('Tap points', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const TapPointsTable(),
          const Divider(height: AnkirenToolsStyle.sectionGap),
          Text('Placing bonus', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _BonusTable(),
          const Divider(height: AnkirenToolsStyle.sectionGap),
          Text('Ranked points', style: title),
          const _PointsCalculator(),
          const Divider(height: AnkirenToolsStyle.sectionGap),
          Text('Ranked classes by placing time', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          const _ClassTable(),
          const Divider(height: AnkirenToolsStyle.sectionGap),
          Text('Rating by score', style: title),
          const SizedBox(height: AnkirenToolsStyle.gap),
          TripRatingGraph(
            rating: TripRating.teiichi,
            xMax: TeiichiToolsTuning.ratingXMax,
            xTick: TeiichiToolsTuning.ratingXTick,
            dots: [
              for (final d in TeiichiToolsTuning.ratingDots)
                (
                  '${formatMinutes(d.placing)} ${_seconds(d.tap)}',
                  TeiichiScore.firstTryTotal(_ranked.calls, responseMs: _ms(d.tap), placing: d.placing),
                ),
            ],
            dotsAre: 'placing m:ss, every call right with the first tap at n s',
          ),
        ],
      ),
    );
  }
}

/// [d] in seconds to a tenth, e.g. 0.6 s.
String _seconds(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';

double _ms(Duration d) => d.inMicroseconds / 1000;

const _ranked = TeiichiSetup.ranked();

final _note = debugMono.copyWith(color: Palette.mute);

/// Each level's setup and what clearing it opens, then the custom games'
/// range and ranked's one setup.
class _LevelTable extends StatelessWidget {
  const _LevelTable();

  static const _rules = LadderRules.teiichi;

  static String _opens(int level) {
    final opens = [
      if (level < _rules.top) 'L${level + 1}',
      if (level == _rules.rankedAfter) 'ranked',
      if (level == _rules.customAfter) 'custom',
    ];
    return opens.isEmpty ? '—' : opens.join(' + ');
  }

  static List<String> _row(String name, TeiichiSetup setup, String opens) => [
        name,
        '${setup.cards}',
        '${setup.rows}',
        formatMinutes(setup.limit!),
        (setup.limit!.inMilliseconds / 1000 / setup.cards).toStringAsFixed(1),
        '${setup.karafuda}',
        opens,
      ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DebugGrid([
            ['L', 'cards', 'rows', 'time', 's/card', 'からふだ', 'opens'],
            for (var level = _rules.first; level <= _rules.top; level++)
              _row('$level', TeiichiSetup.forLevel(level), _opens(level)),
            [
              'C',
              '${TeiichiTuning.minCards}–${TeiichiTuning.cards}',
              '1–${TeiichiTuning.rows}',
              'none',
              '—',
              '≤ cards',
              '—',
            ],
            _row('R', _ranked, '—'),
          ]),
          const SizedBox(height: AnkirenToolsStyle.gap),
          Text(
            'time: the most placing time. C: custom, its からふだ also no more than the known cards left over. '
            'R: ranked, open in all-known mode only.',
            style: _note,
          ),
        ],
      );
}

/// The placing bonus at each of [TeiichiToolsTuning.bonusTimes]: the
/// halvings of the clock, the bonus on the right first taps' points, and
/// what one right first tap [TeiichiToolsTuning.bonusTap] after its prompt
/// earns with it.
class _BonusTable extends StatelessWidget {
  const _BonusTable();

  @override
  Widget build(BuildContext context) {
    const tap = TeiichiToolsTuning.bonusTap;
    final plain = AnkirenTuning.cardPoints + AnkirenScore.speedBonus(tap.inMicroseconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DebugGrid([
          ['placing', 'halvings', 'bonus', '1st tap ${_seconds(tap)}'],
          for (final placing in TeiichiToolsTuning.bonusTimes)
            [
              formatMinutes(placing),
              TeiichiScore.halvings(placing).toStringAsFixed(2),
              '+${TeiichiScore.bonusPercent(placing)}%',
              () {
                final earned = TeiichiScore.firstTryTotal(1, responseMs: _ms(tap), placing: placing);
                return '$earned (+${earned - plain})';
              }(),
            ],
        ]),
        const SizedBox(height: AnkirenToolsStyle.gap),
        Text(
          'Right first taps only: × (1 + ${TeiichiTuning.bonusPerHalving} per halving of '
          '${formatMinutes(TeiichiTuning.halvingClock)}). A right first tap at ${_seconds(tap)} is $plain points.',
          style: _note,
        ),
      ],
    );
  }
}

/// A ranked game's score, performance and class for a placing time, the
/// time of every right first tap, and how many calls were right first.
class _PointsCalculator extends StatefulWidget {
  const _PointsCalculator();

  @override
  State<_PointsCalculator> createState() => _PointsCalculatorState();
}

class _PointsCalculatorState extends State<_PointsCalculator> {
  double _placing = TeiichiToolsTuning.placingStart.inSeconds.toDouble();
  double _responseMs = AnkirenToolsTuning.responseStart.inMilliseconds.toDouble();
  double _right = _ranked.calls.toDouble();

  @override
  Widget build(BuildContext context) {
    final limit = _ranked.limit!;
    final step = TeiichiToolsTuning.placingStep.inSeconds;
    final placing = Duration(seconds: _placing.round());
    final right = _right.round();
    final total = TeiichiScore.firstTryTotal(right, responseMs: _responseMs, placing: placing);
    final performance = TripRating.teiichi.performance(total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugSlider(
          label: 'placing ${formatMinutes(placing)} of ${formatMinutes(limit)}',
          value: _placing,
          min: step.toDouble(),
          max: limit.inSeconds.toDouble(),
          divisions: (limit.inSeconds - step) ~/ step,
          onChanged: (v) => setState(() => _placing = v),
        ),
        DebugResponseSlider(label: 'first taps', ms: _responseMs, onChanged: (v) => setState(() => _responseMs = v)),
        DebugSlider(
          label: 'right first taps $right of ${_ranked.calls} (${_ranked.karafuda} からふだ); the rest earn nothing here',
          value: _right,
          min: 0,
          max: _ranked.calls.toDouble(),
          divisions: _ranked.calls,
          onChanged: (v) => setState(() => _right = v),
        ),
        DebugKV('per right first tap', '${AnkirenTuning.cardPoints + AnkirenScore.speedBonus((_responseMs * 1000).round())}'),
        DebugKV('halvings', TeiichiScore.halvings(placing).toStringAsFixed(2)),
        DebugKV('placing ×', TeiichiScore.factorOf(placing).toStringAsFixed(3)),
        DebugKV('score', '$total'),
        DebugKV('performance', '${performance.round()}'),
        DebugKV('class', RankLadder.bandOf(performance).labelEn),
      ],
    );
  }
}

/// 定位置's ranked classes by placing time: for each class line
/// (`RankLadder.bands`), the score it needs and, with every call right with
/// the first tap at each of [TeiichiToolsTuning.classTapTimes], the slowest
/// placing time that reaches it: "any" when the whole limit does, "—" when
/// not even [TeiichiToolsTuning.classPlacingStep] does.
class _ClassTable extends StatelessWidget {
  const _ClassTable();


  static String _slowest(double rating, Duration tap) {
    const step = TeiichiToolsTuning.classPlacingStep;
    bool reaches(int steps) =>
        TripRating.teiichi.performance(
            TeiichiScore.firstTryTotal(_ranked.calls, responseMs: _ms(tap), placing: step * steps)) >=
        rating;
    var slow = _ranked.limit!.inMicroseconds ~/ step.inMicroseconds;
    if (reaches(slow)) return 'any';
    var fast = 1;
    if (!reaches(fast)) return '—';
    while (slow - fast > 1) {
      final mid = (fast + slow) ~/ 2;
      if (reaches(mid)) {
        fast = mid;
      } else {
        slow = mid;
      }
    }
    return formatMinutes(step * fast);
  }

  @override
  Widget build(BuildContext context) {
    const taps = TeiichiToolsTuning.classTapTimes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All ${_ranked.calls} calls (${_ranked.karafuda} からふだ) right with the first tap at the time heading '
          'each column: the slowest placing that reaches the class, "any" even at ${formatMinutes(_ranked.limit!)}. '
          'P = F × ${TeiichiRatingModel.anchorRating} / ${TeiichiRatingModel.anchorScore}.',
          style: _note,
        ),
        const SizedBox(height: AnkirenToolsStyle.gap),
        DebugGrid([
          ['class', 'line', 'score', for (final t in taps) _seconds(t)],
          for (final b in RankLadder.bands.skip(1))
            [
              b.labelEn,
              '${b.minRating.round()}',
              '${TripRating.teiichi.scoreFor(b.minRating).round()}',
              for (final t in taps) _slowest(b.minRating, t),
            ],
        ]),
      ],
    );
  }
}
