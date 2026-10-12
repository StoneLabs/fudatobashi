import '../config/config.dart';
import 'ankiren_field.dart';
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
  /// (see [Attempt.isValidTime]); null when it was never found (the game
  /// ended first).
  final int? responseUs;

  /// When it was found, or when the game ended without it.
  final DateTime at;

  bool get found => responseUs != null;
  bool get validTime => responseUs != null && Attempt.isValidTime(responseUs!);
  bool get firstTry => found && wrongTaps == 0;

  /// The card had to be shown ([AnkirenTuning.revealAfterWrong] wrong taps).
  bool get revealed => wrongTaps >= AnkirenTuning.revealAfterWrong;
}

/// A 暗記練 game's points. Every field card is asked once, and earns:
/// - found with the first tap: [AnkirenTuning.firstTry] plus a speed bonus
///   of `speedMax × clamp((slowMs − t) / (slowMs − fastMs), 0, 1)` for a
///   response time of t ms ([AnkirenTuning.speedMax], [AnkirenTuning.fastMs],
///   [AnkirenTuning.slowMs]), rounded; a time that is no measurement (see
///   [Attempt.isValidTime]) earns no bonus;
/// - found after one wrong tap: [AnkirenTuning.secondTry];
/// - shown after [AnkirenTuning.revealAfterWrong] wrong taps, or never found:
///   nothing.
///
/// The best possible game ([max]) finds every card first try at full speed;
/// [fraction] is the share of it reached, which drives the rating.
class AnkirenScore {
  AnkirenScore(List<AnkirenAnswer> answers, {required int prompts})
      : total = answers.fold(0, (sum, a) => sum + points(a)),
        max = maxFor(prompts),
        firstTries = answers.where((a) => a.firstTry).length,
        averageFirstTryMs = _averageMs(answers.where((a) => a.firstTry && a.validTime));

  final int total;
  final int max;

  /// Cards found with the first tap.
  final int firstTries;

  /// Mean response time of the first-try finds with a valid time, ms; null
  /// when there are none.
  final double? averageFirstTryMs;

  double get fraction => max == 0 ? 0 : total / max;

  static int maxFor(int prompts) => prompts * (AnkirenTuning.firstTry + AnkirenTuning.speedMax);

  static int points(AnkirenAnswer a) {
    if (!a.found || a.revealed) return 0;
    if (a.wrongTaps > 0) return AnkirenTuning.secondTry;
    return AnkirenTuning.firstTry + speedBonus(a.responseUs!);
  }

  static int speedBonus(int responseUs) {
    if (!Attempt.isValidTime(responseUs)) return 0;
    final share = (AnkirenTuning.slowMs - responseUs / 1000) / (AnkirenTuning.slowMs - AnkirenTuning.fastMs);
    return (AnkirenTuning.speedMax * share.clamp(0.0, 1.0)).round();
  }

  static double? _averageMs(Iterable<AnkirenAnswer> timed) =>
      timed.isEmpty ? null : timed.fold(0.0, (sum, a) => sum + a.responseUs! / 1000) / timed.length;
}
