import '../config/config.dart';
import 'ankiren_score.dart';
import 'play_session.dart';
import 'xp.dart';

/// One card of a recorded 暗記練 game: the wrong taps while it was asked,
/// and the prompt → tap time when it was found (null when it never was).
typedef AnkirenXpAnswer = ({int wrongTaps, int? responseUs});

/// A recorded 暗記練 game, as experience sees it.
class AnkirenXpRun {
  const AnkirenXpRun({
    required this.runId,
    required this.startedAt,
    required this.ranked,
    required this.completed,
    required this.level,
    required this.setup,
    required this.score,
    required this.answers,
  });

  final int runId;
  final DateTime startedAt;
  final bool ranked;

  /// Every card was asked: the game was not ended early.
  final bool completed;

  /// The level the game scores as (`AnkirenSetup.scoredLevel`).
  final int level;

  /// Games with the same setup race each other for a personal best.
  final String setup;
  final int score;

  /// One per card, in the order they were asked.
  final List<AnkirenXpAnswer> answers;

  /// A ranked game left once its cards were face down: it earns nothing.
  bool get forfeit => ranked && !completed;
}

/// 暗記練's experience rules ([AnkirenXpTuning]), keeping what each game
/// needs from the games before it: the best score of each setup and the
/// ranked games played. Every card found earns XP, more with the first tap
/// and at a higher level, plus a speed bonus; a game played to the end adds
/// a clear (and a ranked one more), a personal best adds its bonus, and
/// the ranked game that finishes placement adds a one-off bonus. A forfeit
/// earns nothing; a free game ended early earns only its finds.
class AnkirenXp {
  final _best = <String, int>{};
  int _rankedGames = 0;

  /// XP a first-tap find earns at [level].
  static int cardXp(int level) => AnkirenXpTuning.firstTap + AnkirenXpTuning.firstTapPerLevel * level;

  /// XP a first-tap find [responseUs] after its prompt earns for speed.
  static int speedXp(int responseUs) => Attempt.isValidTime(responseUs)
      ? (AnkirenXpTuning.speedMax * AnkirenScore.speedShare(responseUs / 1000)).round()
      : 0;

  /// What [run], played after every game scored so far, earned.
  XpAward score(AnkirenXpRun run) {
    final placed = run.ranked && ++_rankedGames == AnkirenRatingModel.placementGames;
    final previous = _best[run.setup];
    final best = run.completed && previous != null && run.score > previous;
    if (run.completed && (previous == null || run.score > previous)) _best[run.setup] = run.score;
    if (run.forfeit) return const XpAward([]);

    var first = 0, second = 0, missed = 0, fast = 0, speed = 0;
    for (final a in run.answers) {
      final us = a.responseUs;
      if (us != null && a.wrongTaps == 0) {
        first++;
        final bonus = speedXp(us);
        if (bonus > 0) fast++;
        speed += bonus;
      } else if (us != null && a.wrongTaps < AnkirenTuning.revealAfterWrong) {
        second++;
      } else {
        missed++;
      }
    }
    final card = cardXp(run.level);
    final done = run.completed;
    return XpAward([
      for (final p in [
        XpPart(XpSource.firstTap, first, first * card),
        XpPart(XpSource.secondTap, second, second * (card * AnkirenXpTuning.secondTapShare).round()),
        XpPart(XpSource.missed, missed, done ? missed * AnkirenXpTuning.perMiss : 0),
        XpPart(XpSource.speed, fast, speed),
        XpPart(XpSource.clear, 1, done ? AnkirenXpTuning.clear : 0),
        XpPart(XpSource.ranked, 1, done && run.ranked ? AnkirenXpTuning.ranked : 0),
        XpPart(XpSource.best, 1, best ? AnkirenXpTuning.personalBest : 0),
        XpPart(XpSource.placement, 1, placed ? AnkirenXpTuning.placement : 0),
      ])
        if (p.xp > 0) p,
    ]);
  }
}
