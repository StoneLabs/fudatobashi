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
    this.gaveUp = false,
    this.taps = const [],
    this.tapped = const [],
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

  /// The player gave it up ("don't know"); never found and not given up,
  /// the game ended first.
  final bool gaveUp;

  /// Where each tap that counts ([AnkirenTuning.tapWeights]) landed, in
  /// order; empty when no card was tapped.
  final List<TapProximity> taps;

  /// The card each of [taps] hit, in the same order.
  final List<int> tapped;

  /// The first tap's time after the prompt in microseconds, as measured;
  /// null when no card was tapped.
  final int? firstTapUs;

  bool get found => responseUs != null;
  bool get validTime => responseUs != null && Attempt.isValidTime(responseUs!);
  bool get firstTry => found && wrongTaps == 0;

  /// The card had to be shown ([AnkirenTuning.revealAfterWrong] wrong taps).
  bool get revealed => wrongTaps >= AnkirenTuning.revealAfterWrong;
}

/// A 暗記練 game's score, which only ranked games show. Every field card is
/// asked once and earns [points] for the taps made while it was asked,
/// however its prompt ended (found, given up or the game ended).
///
/// These [recall] points are out of [maxRecall] (every card first try at
/// full speed). The [firstRight] part of them, from the cards found with the
/// first tap, is multiplied by 1 + [AnkirenTuning.earlyBonus] × the share of
/// the memorise time left unused; the rest never is. [max] is the best score
/// without being ready early, and [early] what being ready early added.
class AnkirenScore {
  AnkirenScore(List<AnkirenAnswer> answers, {required int prompts, this.timeLeft = 0})
      : recall = answers.fold(0, (sum, a) => sum + points(a)),
        firstRight = answers.fold(0, (sum, a) => sum + (foundFirst(a.taps) ? points(a) : 0)),
        maxRecall = maxFor(prompts);

  final int recall;
  final int firstRight;
  final int maxRecall;

  /// The share of the memorise time left unused.
  final double timeLeft;

  double get fraction => maxRecall == 0 ? 0 : recall / maxRecall;

  int get total => totalOf(recall, firstRight, timeLeft);
  int get max => maxRecall;
  int get early => total - recall;

  /// Whether a card with these [taps] was found with the first tap, the only
  /// kind whose points the early finish multiplies.
  static bool foundFirst(List<TapProximity> taps) => taps.firstOrNull == TapProximity.card;

  /// The score of [recall] points, [firstRight] of them from cards found
  /// with the first tap, with [timeLeft] of the memorise time unused (as a
  /// share).
  static int totalOf(int recall, int firstRight, double timeLeft) =>
      recall - firstRight + (firstRight * (1 + AnkirenTuning.earlyBonus * timeLeft)).round();

  /// A game with [setup] where every card is found with its first tap
  /// [responseMs] after its prompt, and the player was ready with [timeLeft]
  /// of the memorise time to spare (at most all of it).
  static int firstTryTotal(AnkirenSetup setup, {required double responseMs, Duration timeLeft = Duration.zero}) {
    final share = (timeLeft.inMicroseconds / setup.memorise.inMicroseconds).clamp(0.0, 1.0);
    final perCard = AnkirenTuning.cardPoints + speedBonus((responseMs * 1000).round());
    return totalOf(setup.cards * perCard, setup.cards * perCard, share);
  }

  static int maxFor(int prompts) => prompts * (AnkirenTuning.cardPoints + AnkirenTuning.speedMax);

  static int points(AnkirenAnswer a) => pointsOf(a.taps, a.firstTapUs);

  /// A card's points for its [taps], the first [firstTapUs] after its
  /// prompt: [share] of [AnkirenTuning.cardPoints], plus the first tap's
  /// [speedBonus] times [speedWeight].
  static int pointsOf(List<TapProximity> taps, int? firstTapUs) {
    final speed = firstTapUs == null ? 0 : speedWeight(taps) * speedBonus(firstTapUs);
    return (AnkirenTuning.cardPoints * share(taps) + speed).round();
  }

  /// The share of [AnkirenTuning.cardPoints] a card's [taps] earn: for each
  /// tap that counts, its weight ([AnkirenTuning.tapWeights]) times the
  /// share where it landed earns ([AnkirenTuning.tapShare]).
  static double share(List<TapProximity> taps) {
    var sum = 0.0;
    for (final (i, place) in taps.take(AnkirenTuning.tapWeights.length).indexed) {
      sum += AnkirenTuning.tapWeights[i] * AnkirenTuning.tapShare[place]!;
    }
    return sum;
  }

  /// How much a card's speed bonus counts: as much as its first tap when
  /// that found the card, else not at all.
  static double speedWeight(List<TapProximity> taps) =>
      foundFirst(taps) ? AnkirenTuning.tapWeights.first : 0;

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
