import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_score.dart';
import 'play_overlay.dart';

/// Dev mode's readout over a 暗記練 game (the play overlay setting): how the
/// last card answered scored, from where its first tap landed, and the
/// game's points so far.
class AnkirenScoreReadout extends StatelessWidget {
  const AnkirenScoreReadout({super.key, required this.game});

  final AnkirenGame game;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: game,
        builder: (context, _) => DebugReadout(lines(game)),
      );

  /// The readout's lines for [game] as it stands.
  static List<String> lines(AnkirenGame game) {
    final a = game.answers.lastOrNull;
    final score = game.score;
    final total = score == null
        ? 'custom: not scored'
        : 'so far ${score.recall} / ${score.maxRecall}  ×${score.factor.toStringAsFixed(2)}';
    if (a == null) return ['no card answered yet', total];
    final outcome = !a.found
        ? (a.wrongTaps > 0 ? 'given up after ${a.wrongTaps} wrong' : 'not found')
        : a.revealed
            ? 'found once shown'
            : a.firstTry
                ? 'found with the first tap'
                : 'found with the second tap';
    final firstTap = a.firstTap;
    final firstTapUs = a.firstTapUs;
    final bonus = firstTapUs == null ? 0 : AnkirenScore.speedBonus(firstTapUs);
    return [
      '#${a.poemId} ${poems[a.poemId].kimariji}: $outcome',
      firstTap == null || firstTapUs == null
          ? 'no tap'
          : 'first tap ${firstTap.name} at ${(firstTapUs / 1000).toStringAsFixed(0)} ms',
      '(${AnkirenTuning.firstTry} + $bonus speed) × ${a.credit.toStringAsFixed(2)} = ${AnkirenScore.points(a)} pt',
      total,
    ];
  }
}
