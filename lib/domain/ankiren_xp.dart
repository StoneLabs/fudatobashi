import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_score.dart';
import 'play_session.dart';
import 'xp.dart';

/// One card of a recorded 暗記練 game: the wrong taps while it was asked,
/// the prompt → tap time when it was found (null when it never was), where
/// each tap that counts landed, and the first one's time (null when no card
/// was tapped).
typedef AnkirenXpAnswer = ({int wrongTaps, int? responseUs, List<TapProximity> taps, int? firstTapUs});

/// A recorded 暗記練 game, as experience sees it.
class AnkirenXpRun {
  const AnkirenXpRun({
    required this.runId,
    required this.startedAt,
    required this.ranked,
    required this.completed,
    required this.level,
    required this.score,
    required this.answers,
  });

  final int runId;
  final DateTime startedAt;
  final bool ranked;

  /// Every card was asked: the game was not ended early.
  final bool completed;

  /// The level preset played and the score; both null for a custom setup,
  /// which is not scored and earns nothing. Games at the same level race
  /// each other for a personal best.
  final int? level;
  final int? score;

  /// One per card, in the order they were asked.
  final List<AnkirenXpAnswer> answers;

  /// A ranked game left once its cards were face down: it earns nothing.
  bool get forfeit => ranked && !completed;
}

/// 暗記練's experience rules ([AnkirenXpTuning]), keeping what each game
/// needs from the games before it: the best score of each level and the
/// ranked games played. Each card earns the same share of a find's XP
/// (more at a higher level) as of its points (`AnkirenScore.share`): all of
/// it when the first tap found it, part when its taps landed near it; and
/// a find with the first tap a speed bonus for its time. A game played to
/// the end pays the cards that earned nothing for trying, adds a clear (and
/// a ranked one more), a personal best adds its bonus, and the ranked game
/// that finishes placement adds a one-off bonus. A forfeit and a custom
/// game earn nothing; a free game ended early earns only what its cards
/// earned.
class AnkirenXp {
  final _best = <int, int>{};
  int _rankedGames = 0;

  /// XP a first-tap find earns at [level].
  static int cardXp(int level) => AnkirenXpTuning.firstTap + AnkirenXpTuning.firstTapPerLevel * level;

  /// XP a first tap on the card [responseUs] after its prompt earns for
  /// speed.
  static int speedXp(int responseUs) => Attempt.isValidTime(responseUs)
      ? (AnkirenXpTuning.speedMax * AnkirenScore.speedShare(responseUs / 1000)).round()
      : 0;

  /// What [run], played after every game scored so far, earned.
  XpAward score(AnkirenXpRun run) {
    final placed = run.ranked && ++_rankedGames == AnkirenRatingModel.placementGames;
    final level = run.level, score = run.score;
    if (level == null || score == null) return const XpAward([]);
    final previous = _best[level];
    final best = run.completed && previous != null && score > previous;
    if (run.completed && (previous == null || score > previous)) _best[level] = score;
    if (run.forfeit) return const XpAward([]);

    final card = cardXp(level);
    var first = 0, near = 0, missed = 0, fast = 0;
    var firstXp = 0, nearXp = 0, speed = 0;
    for (final a in run.answers) {
      final share = AnkirenScore.share(a.taps);
      if (share == 0) {
        missed++;
        continue;
      }
      final xp = (card * share).round();
      if (a.taps.first == TapProximity.card) {
        first++;
        firstXp += xp;
      } else {
        near++;
        nearXp += xp;
      }
      final us = a.firstTapUs;
      final bonus = us == null ? 0 : (AnkirenScore.speedWeight(a.taps) * speedXp(us)).round();
      if (bonus > 0) fast++;
      speed += bonus;
    }
    final done = run.completed;
    return XpAward([
      for (final p in [
        XpPart(XpSource.firstTap, first, firstXp),
        XpPart(XpSource.nearMiss, near, nearXp),
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
