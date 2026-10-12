import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_level.dart';
import 'play_session.dart';

/// One prompt of a 暗記練 game and how it was answered.
class AnkirenAnswer {
  const AnkirenAnswer({
    required this.poemId,
    required this.side,
    required this.wrongTaps,
    required this.responseUs,
    required this.at,
  });

  final int poemId;
  final FieldSide side;

  /// Other cards tapped while this one was asked.
  final int wrongTaps;

  /// The prompt's reveal → the tap on its card, in microseconds, as measured
  /// (see [Attempt.isValidTime]); null when it was never found: given up, or
  /// the game ended first.
  final int? responseUs;

  /// When it was found or given up, or when the game ended without it.
  final DateTime at;

  bool get found => responseUs != null;
  bool get validTime => responseUs != null && Attempt.isValidTime(responseUs!);
  bool get firstTry => found && wrongTaps == 0;

  /// The card had to be shown ([AnkirenTuning.revealAfterWrong] wrong taps).
  bool get revealed => wrongTaps >= AnkirenTuning.revealAfterWrong;
}

/// A 暗記練 game's score. Every field card is asked once, and earns:
/// - found with the first tap: [AnkirenTuning.firstTry] plus a speed bonus
///   of up to [AnkirenTuning.speedMax] ([speedBonus]); a time that is no
///   measurement (see [Attempt.isValidTime]) earns no bonus;
/// - found after one wrong tap: [AnkirenTuning.secondTry], no bonus;
/// - shown after [AnkirenTuning.revealAfterWrong] wrong taps, given up
///   ("don't know"), or never found: nothing.
///
/// These [recall] points, out of [maxRecall] (every card first try at full
/// speed), make the [fraction] that drives the rating. The score shown is
/// them times 1 + [AnkirenTuning.earlyBonus] × the share of the memorise
/// time left unused, times the level's [factorFor]; [max] is the best one
/// without being ready early, and [early] what being ready early added.
class AnkirenScore {
  AnkirenScore(List<AnkirenAnswer> answers, {required int prompts, this.timeLeft = 0, this.factor = 1})
      : recall = answers.fold(0, (sum, a) => sum + points(a)),
        maxRecall = maxFor(prompts),
        firstTries = answers.where((a) => a.firstTry).length,
        averageFirstTryMs = _averageMs(answers.where((a) => a.firstTry && a.validTime));

  final int recall;
  final int maxRecall;

  /// The share of the memorise time left unused, and the level's
  /// [factorFor].
  final double timeLeft;
  final double factor;

  /// Cards found with the first tap.
  final int firstTries;

  /// Mean response time of the first-try finds with a valid time, ms; null
  /// when there are none.
  final double? averageFirstTryMs;

  double get fraction => maxRecall == 0 ? 0 : recall / maxRecall;

  int get total => (recall * (1 + AnkirenTuning.earlyBonus * timeLeft) * factor).round();
  int get max => (maxRecall * factor).round();
  int get early => total - (recall * factor).round();

  /// How much a game of [setup] counts: [AnkirenTuning.levelFactor] once for
  /// every level below the top. A custom setup counts like the hardest level
  /// it is at least as hard as (as many cards a side or more, as long to
  /// memorise or less), or level 0.
  static double factorFor(AnkirenSetup setup) {
    final level = setup.level ??
        AnkirenLevels.all.lastIndexWhere((l) => setup.perSide >= l.perSide && setup.memorise <= l.memorise);
    return math.pow(AnkirenTuning.levelFactor, AnkirenLevels.top - math.max(0, level)).toDouble();
  }

  static int maxFor(int prompts) => prompts * (AnkirenTuning.firstTry + AnkirenTuning.speedMax);

  static int points(AnkirenAnswer a) {
    if (!a.found || a.revealed) return 0;
    if (a.wrongTaps > 0) return AnkirenTuning.secondTry;
    return AnkirenTuning.firstTry + speedBonus(a.responseUs!);
  }

  /// The bonus for a first-try find [responseUs] after its prompt, rounded
  /// [speedShare] of [AnkirenTuning.speedMax].
  static int speedBonus(int responseUs) =>
      Attempt.isValidTime(responseUs) ? (AnkirenTuning.speedMax * speedShare(responseUs / 1000)).round() : 0;

  /// The share of the speed bonus a find [ms] after its prompt earns: 1 up
  /// to [AnkirenTuning.speedFull], then falling along a logistic curve over
  /// ln t (centred on [AnkirenTuning.speedMidpoint], as steep as
  /// [AnkirenTuning.speedSteepness]), stretched to reach 0 at
  /// [AnkirenTuning.speedNone] and staying there.
  static double speedShare(double ms) {
    double logistic(double t) =>
        1 / (1 + math.pow(t / AnkirenTuning.speedMidpoint.inMilliseconds, AnkirenTuning.speedSteepness));
    final top = logistic(AnkirenTuning.speedFull.inMilliseconds.toDouble());
    final bottom = logistic(AnkirenTuning.speedNone.inMilliseconds.toDouble());
    return ((logistic(ms) - bottom) / (top - bottom)).clamp(0.0, 1.0);
  }

  static double? _averageMs(Iterable<AnkirenAnswer> timed) =>
      timed.isEmpty ? null : timed.fold(0.0, (sum, a) => sum + a.responseUs! / 1000) / timed.length;
}
