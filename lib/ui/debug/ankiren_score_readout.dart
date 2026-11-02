import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_score.dart';
import '../../domain/play_session.dart';
import 'play_overlay.dart';

/// Dev mode's readout over a 暗記練 game (the play overlay setting): how the
/// last card answered scored, tap by tap with the tuning each step used,
/// and the game's points so far. [split] lays it out as two tables side by
/// side, the card and its first tap beside the rest, to keep it short.
/// Another game's scoring replaces the game's own rows through [parts].
class AnkirenScoreReadout extends StatelessWidget {
  const AnkirenScoreReadout({super.key, required this.game, this.split = false});

  final AnkirenGame game;
  final bool split;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: game,
        builder: (context, _) => DebugTable(split ? parts(game) : [rows(game)]),
      );

  /// The readout for [game] as it stands, one fact a row.
  static List<DebugRow> rows(AnkirenGame game) => [for (final part in parts(game)) ...part];

  /// The readout in two parts: the last card answered and its first tap;
  /// then its later taps, their sum, and the game, as [gameRows] gives them
  /// when the game is scored another way.
  static List<List<DebugRow>> parts(AnkirenGame game, {List<DebugRow> Function(AnkirenGame game)? gameRows}) {
    final scored = gameRows ?? _game;
    final a = game.answers.lastOrNull;
    if (a == null) return [[head('CARD', 'none answered yet')], scored(game)];
    const base = AnkirenTuning.cardPoints, weights = AnkirenTuning.tapWeights;
    final card = <DebugRow>[
      head('CARD', '#${a.poemId} ${poems[a.poemId].kimariji}'),
      fact('result', _outcome(game, a)),
    ];
    final rest = <DebugRow>[];
    final values = <double>[];
    for (var i = 0; i < weights.length; i++) {
      final rows = i == 0 ? card : rest;
      final place = a.taps.elementAtOrNull(i);
      rows.add(head('TAP ${i + 1}', place?.name ?? 'none'));
      if (place == null) {
        values.add(0);
        continue;
      }
      final tier = AnkirenTuning.tapShare[place]!;
      rows.add(fact('tier', number(tier)));
      final (speedRows, bonus) = i == 0 ? _speed(a) : (const <DebugRow>[], null);
      final points = tier * base + (bonus ?? 0);
      rows
        ..addAll(speedRows)
        ..add(fact('points', '${number(tier)} × $base${bonus == null ? '' : ' + $bonus'} = ${number(points)}'));
      values.add(points);
    }
    final later = a.wrongTaps + (a.found ? 1 : 0) - a.taps.length;
    if (later > 0) rest.add(fact('later', '$later tap${later == 1 ? '' : 's'}, not counted'));
    final terms = [for (final (i, v) in values.indexed) weights[i] == 1 ? number(v) : '${number(weights[i])} × ${number(v)}'];
    rest
      ..add(head('SUM', '${terms.join(' + ')} = ${AnkirenScore.points(a)}'))
      ..addAll(scored(game));
    return [card, rest];
  }

  /// A row that heads a part of the readout, and a fact under it.
  static DebugRow head(String label, String value) => (label: label, value: value, head: true);
  static DebugRow fact(String label, String value) => (label: label, value: value, head: false);

  /// The first tap's time and what it earned for speed, with the curve's
  /// inputs (the time against the curve's centre, the steepness, and the
  /// times of the full bonus and of none); the bonus is null when it earned
  /// none, missing the card or with no valid time.
  static (List<DebugRow>, int?) _speed(AnkirenAnswer a) {
    final us = a.firstTapUs ?? 0;
    final time = fact('time', '${number(us / 1000, 0)} ms');
    if (AnkirenScore.speedWeight(a.taps) == 0) return ([time, fact('speed', '0, not the card')], null);
    if (!Attempt.isValidTime(us)) return ([time, fact('speed', '0, no valid time')], null);
    final bonus = AnkirenScore.speedBonus(us);
    return (
      [
        time,
        fact('curve', '(${number(us / 1000, 0)} / ${AnkirenTuning.speedMidpoint.inMilliseconds}) ^ '
            '${number(AnkirenTuning.speedSteepness)}'),
        fact('range', '${AnkirenTuning.speedFull.inMilliseconds} → ${AnkirenTuning.speedNone.inMilliseconds} ms'),
        fact('speed', '${number(AnkirenScore.speedShare(us / 1000))} × ${AnkirenTuning.speedMax} = $bonus'),
      ],
      bonus,
    );
  }

  static String _outcome(AnkirenGame game, AnkirenAnswer a) {
    final taps = a.wrongTaps + (a.found ? 1 : 0);
    if (a.found) return a.revealed ? 'found on tap $taps, shown' : 'found on tap $taps';
    final how = game.isGivenUp(a.poemId) ? 'given up' : 'never found';
    return taps == 0 ? '$how, no tap' : '$how after ${taps == 1 ? '1 tap' : '$taps taps'}';
  }

  /// The game's points so far, out of the most, and the factor that turns
  /// the right first taps' points into part of its score.
  static List<DebugRow> _game(AnkirenGame game) {
    final score = game.score;
    if (score == null) return [head('GAME', 'not ranked, no score')];
    return [
      head('GAME', '${score.recall} / ${score.maxRecall}'),
      fact('early', '× ${number(1 + AnkirenTuning.earlyBonus * score.timeLeft)} on ${score.firstRight} (right first taps)'),
      fact('score', '${score.total}'),
    ];
  }

  /// [x] to at most [decimals] places, without trailing zeros.
  static String number(num x, [int decimals = 2]) {
    final fixed = x.toStringAsFixed(decimals);
    return fixed.contains('.') ? fixed.replaceFirst(RegExp(r'\.?0+$'), '') : fixed;
  }
}
