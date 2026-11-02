import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_score.dart';

/// A ranked 定位置 game's score. Every call earns its 暗記練 points
/// ([recall]; see [AnkirenScore.pointsOf]), and the [firstRight] part of
/// them, the calls answered with the first tap, is multiplied by [factor]:
/// 1 + [TeiichiTuning.bonusPerHalving] for each [halvings] of
/// [TeiichiTuning.halvingClock] the cards were placed in. The time spent on
/// the calls plays no part. Cards never placed earn nothing, and the score
/// has no fixed top.
class TeiichiScore {
  TeiichiScore(List<AnkirenAnswer> answers, {required this.placing})
      : _calls = AnkirenScore(answers, prompts: answers.length);

  final AnkirenScore _calls;

  /// From the deal to the flip.
  final Duration placing;

  int get recall => _calls.recall;
  int get firstRight => _calls.firstRight;

  /// The part of [recall] from the からふだ calls.
  int get karafuda => _calls.karafuda;
  double get factor => factorOf(placing);

  int get total => AnkirenScore.multiplied(recall, firstRight, factor);

  /// What the placing time added.
  int get bonus => total - recall;

  /// How many times [placing] halves [TeiichiTuning.halvingClock], in
  /// fractions too: none for a slower time, or for no time at all.
  static double halvings(Duration placing) => placing <= Duration.zero
      ? 0
      : math.max(0, math.log(TeiichiTuning.halvingClock.inMicroseconds / placing.inMicroseconds) / math.ln2);

  /// What [placing] multiplies the first-tap points by.
  static double factorOf(Duration placing) => 1 + TeiichiTuning.bonusPerHalving * halvings(placing);

  /// What [placing] adds to the first-tap points, as a whole percentage.
  static int bonusPercent(Duration placing) => ((factorOf(placing) - 1) * 100).round();

  /// A ranked game placed in [placing] where [calls] calls are answered
  /// with the first tap [responseMs] after their prompt, and any other
  /// earns nothing.
  static int firstTryTotal(int calls, {required double responseMs, required Duration placing}) {
    final points = calls * (AnkirenTuning.cardPoints + AnkirenScore.speedBonus((responseMs * 1000).round()));
    return AnkirenScore.multiplied(points, points, factorOf(placing));
  }
}
