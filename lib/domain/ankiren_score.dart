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
    this.firstTap,
    this.firstTapUs,
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

  /// Where the first tap while it was asked landed, and that tap's time
  /// after the prompt in microseconds, as measured; null when no card was
  /// tapped.
  final TapProximity? firstTap;
  final int? firstTapUs;

  bool get found => responseUs != null;
  bool get validTime => responseUs != null && Attempt.isValidTime(responseUs!);
  bool get firstTry => found && wrongTaps == 0;

  /// The card had to be shown ([AnkirenTuning.revealAfterWrong] wrong taps).
  bool get revealed => wrongTaps >= AnkirenTuning.revealAfterWrong;

  /// See [AnkirenScore.credit].
  double get credit => AnkirenScore.credit(found: found, wrongTaps: wrongTaps, firstTap: firstTap);
}

/// A 暗記練 game's score; custom games are not scored. Every field card is
/// asked once, and earns [AnkirenTuning.firstTry] points plus a speed bonus
/// of up to [AnkirenTuning.speedMax] ([speedBonus]) for the time of the
/// prompt's first tap, times its [credit]: all of them when the first
/// tap finds it, a share by how near the first tap landed when the next one
/// finds it, and nothing when it had to be shown, was given up ("don't
/// know") or was never found. A time that is no measurement (see
/// [Attempt.isValidTime]) earns no bonus.
///
/// These [recall] points, out of [maxRecall] (every card first try at full
/// speed), make the [fraction] that drives the rating. The score shown is
/// them times 1 + [AnkirenTuning.earlyBonus] × the share of the memorise
/// time left unused, times the level's [factorFor]; [max] is the best one
/// without being ready early, and [early] what being ready early added.
class AnkirenScore {
  AnkirenScore(List<AnkirenAnswer> answers, {required int prompts, this.timeLeft = 0, this.factor = 1})
      : recall = answers.fold(0, (sum, a) => sum + points(a)),
        maxRecall = maxFor(prompts);

  final int recall;
  final int maxRecall;

  /// The share of the memorise time left unused, and the level's
  /// [factorFor].
  final double timeLeft;
  final double factor;

  double get fraction => maxRecall == 0 ? 0 : recall / maxRecall;

  int get total => totalOf(recall, timeLeft, factor);
  int get max => (maxRecall * factor).round();
  int get early => total - (recall * factor).round();

  /// How much a game at [level] counts: [AnkirenTuning.levelFactor] once for
  /// every level below the top.
  static double factorFor(int level) => math.pow(AnkirenTuning.levelFactor, AnkirenLevels.top - level).toDouble();

  /// The score of [recall] points with [timeLeft] of the memorise time unused
  /// (as a share) at a level [factor].
  static int totalOf(int recall, double timeLeft, double factor) =>
      (recall * (1 + AnkirenTuning.earlyBonus * timeLeft) * factor).round();

  /// A game at [level] where every card is found with its first tap
  /// [responseMs] after its prompt, and the player was ready with [timeLeft]
  /// of the memorise time to spare (at most all of it).
  static int firstTryTotal(int level, {required double responseMs, required Duration timeLeft}) {
    final setup = AnkirenLevels.of(level);
    final share = (timeLeft.inMicroseconds / setup.memorise.inMicroseconds).clamp(0.0, 1.0);
    final perCard = AnkirenTuning.firstTry + speedBonus((responseMs * 1000).round());
    return totalOf(setup.cards * perCard, share, factorFor(level));
  }

  static int maxFor(int prompts) => prompts * (AnkirenTuning.firstTry + AnkirenTuning.speedMax);

  /// The share of a first-tap find's points a card earns when it was
  /// [found] before it was shown: by where the first tap while it was asked
  /// landed ([AnkirenTuning.firstTapCredit]), plus
  /// [AnkirenTuning.secondTapShare] when it took a second tap. Else nothing.
  static double credit({required bool found, required int wrongTaps, required TapProximity? firstTap}) =>
      found && wrongTaps < AnkirenTuning.revealAfterWrong
          ? (AnkirenTuning.firstTapCredit[firstTap] ?? 0) + (wrongTaps > 0 ? AnkirenTuning.secondTapShare : 0)
          : 0;

  static int points(AnkirenAnswer a) {
    final credit = a.credit;
    return credit == 0 ? 0 : ((AnkirenTuning.firstTry + speedBonus(a.firstTapUs!)) * credit).round();
  }

  /// The bonus for a first tap [responseUs] after its prompt, rounded
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
}
