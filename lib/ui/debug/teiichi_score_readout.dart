import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_placing.dart';
import '../../domain/teiichi_score.dart';
import 'ankiren_score_readout.dart';
import 'play_overlay.dart';

/// Dev mode's readout over a 定位置 game (the play overlay setting). While
/// the cards are laid out: the placing clock, the bonus it would give right
/// now and, in a timed game, the time left. From the flip on, 暗记練's
/// readout of the last call ([AnkirenScoreReadout]) with the game scored as
/// 定位置 scores it: the placing time, its halvings and the bonus they give,
/// and the score with the bonus applied.
///
/// [ticks] says when the placing clock has moved; [placingTime] reads it.
/// [split] lays the recall out as two tables side by side.
class TeiichiScoreReadout extends StatelessWidget {
  const TeiichiScoreReadout({
    super.key,
    required this.setup,
    required this.placing,
    required this.ticks,
    required this.placingTime,
    this.game,
    this.split = false,
  });

  final TeiichiSetup setup;
  final TeiichiPlacing placing;
  final Listenable ticks;
  final Duration Function() placingTime;

  /// Null while the cards are laid out.
  final AnkirenGame? game;
  final bool split;

  @override
  Widget build(BuildContext context) {
    final game = this.game;
    if (game == null) {
      return ListenableBuilder(listenable: ticks, builder: (context, _) => DebugTable([_placingRows()]));
    }
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final parts = AnkirenScoreReadout.parts(game, gameRows: _scored);
        return DebugTable(split ? parts : [[for (final part in parts) ...part]]);
      },
    );
  }

  List<DebugRow> _placingRows() {
    final time = placingTime();
    final limit = setup.limit;
    return [
      AnkirenScoreReadout.head('PLACING', '${placing.board.cards.length} / ${setup.cards} placed'),
      AnkirenScoreReadout.fact('clock', _seconds(time)),
      if (limit != null) AnkirenScoreReadout.fact('left', _seconds(limit - time)),
      ..._bonusRows(time),
    ];
  }

  /// The game's points and, with the placing bonus on the right first taps,
  /// its score as the results show it.
  static List<DebugRow> _scored(AnkirenGame game) {
    final placing = game.setup.memorise;
    final score = TeiichiScore(game.answers, placing: placing);
    return [
      AnkirenScoreReadout.head('GAME', '${score.recall} points'),
      AnkirenScoreReadout.fact('placing', _seconds(placing)),
      ..._bonusRows(placing),
      AnkirenScoreReadout.fact('applied', '× ${AnkirenScoreReadout.number(score.factor)} on ${score.firstRight} (right first taps)'),
      AnkirenScoreReadout.fact('score', '${score.recall} + ${score.bonus} = ${score.total}'),
    ];
  }

  /// How many times [placing] halves the halving clock, and the bonus
  /// percentage that gives.
  static List<DebugRow> _bonusRows(Duration placing) => [
        AnkirenScoreReadout.fact('halvings',
            '${AnkirenScoreReadout.number(TeiichiScore.halvings(placing))} of ${_seconds(TeiichiTuning.halvingClock)}'),
        AnkirenScoreReadout.fact('bonus', '+${TeiichiScore.bonusPercent(placing)}%'),
      ];

  static String _seconds(Duration d) => '${AnkirenScoreReadout.number(d.inMilliseconds / 1000, 1)} s';
}
