import '../db/database.dart';
import '../domain/ankiren_level.dart';
import '../domain/ankiren_xp.dart';
import '../domain/card_stats.dart';
import '../domain/side_trips.dart';
import '../domain/weak_cards.dart';
import '../domain/xp.dart';
import 'play_config.dart';
import 'progress.dart';
import 'side_trips.dart';

/// Experience read off the recorded history: runs with their attempts and
/// milestones (islands completed, graduation, today's set done), and
/// 暗記練's games with their answers.
abstract final class XpHistory {
  /// What every recorded game of [progress] earned: the main game's runs and
  /// 暗記練's games, each by its id.
  static ({Map<int, XpGain> runs, Map<int, XpGain> ankiren}) gainsOf(Progress progress) {
    final runGains = <int, XpGain>{}, gameGains = <int, XpGain>{};
    ledgerOf(progress, ({required ankiren, required id, required gain}) => (ankiren ? gameGains : runGains)[id] = gain);
    return (runs: runGains, ankiren: gameGains);
  }

  /// Every recorded game of [progress], oldest first.
  static XpLedger ledgerOf(Progress progress,
      [void Function({required bool ankiren, required int id, required XpGain gain})? onGain]) {
    final byRun = <int, List<(ItemKey, AttemptRec)>>{};
    for (final k in progress.trainer.items.keys) {
      for (final a in progress.attemptsOf(k)) {
        if (a.runId != null) (byRun[a.runId!] ??= []).add((k, a));
      }
    }
    final trips = progress.sideTrips;
    return XpLedger.of(
      [for (final r in progress.runs) runOf(progress, r, byRun[r.id] ?? const [])],
      [for (final r in trips.runsOf(SideTrip.ankiren)) ankirenRunOf(trips, r)],
      onGain,
    );
  }

  /// 暗記練 game [run] of [trips].
  static AnkirenXpRun ankirenRunOf(SideTrips trips, SideTripRun run) => AnkirenXpRun(
        runId: run.id,
        startedAt: run.startedAt,
        ranked: run.ranked,
        completed: run.completed,
        level: run.level?.clamp(0, AnkirenLevels.top),
        score: run.score,
        answers: trips.answersOf(run),
      );

  /// Run [r] of [progress] with its attempts, looked up at the end of each
  /// card's log (for a run just recorded).
  static XpRun latestRunOf(Progress progress, RunRow r) {
    final attempts = <(ItemKey, AttemptRec)>[];
    for (final k in progress.trainer.items.keys) {
      final log = progress.attemptsOf(k);
      var from = log.length;
      while (from > 0 && log[from - 1].runId == r.id) {
        from--;
      }
      attempts.addAll([for (final a in log.skip(from)) (k, a)]);
    }
    return runOf(progress, r, attempts);
  }

  /// [attempts] hold each card's in the order played.
  static XpRun runOf(Progress progress, RunRow r, List<(ItemKey, AttemptRec)> attempts) => XpRun(
        runId: r.id,
        startedAt: r.startedAt,
        setup: progress.configOf(r).historyKey,
        completed: r.completed,
        total: Progress.totalOf(r),
        goalMs: r.goalMs.toDouble(),
        counts: attempts.any((e) => e.$2.countsForSrs),
        swipes: [
          for (final (_, (k, a)) in [...attempts.indexed]..sort((x, y) {
              final byTime = x.$2.$2.at.compareTo(y.$2.$2.at);
              return byTime != 0 ? byTime : x.$1.compareTo(y.$1);
            }))
            XpSwipe(poemId: k.poemId, correct: !a.miss, clean: a.clean, us: a.us, graded: a.grade != null),
        ],
        islands: progress.islandsCompletedBy(r.id).length,
        graduated: r.graduated,
        day: progress.dayOf(r),
        dayDone: r.dayDone,
        ranked: r.mode == PlayMode.ranked,
        placement: progress.isPlacement(r),
        exam: r.mode == PlayMode.exam,
        weak: r.mode == PlayMode.nigate,
        weakCleared: r.mode == PlayMode.nigate ? _cleared(attempts, r.goalMs.toDouble()) : 0,
      );

  /// The sides a 苦手 drill cleared: its last looks fast under [lineMs].
  static int _cleared(List<(ItemKey, AttemptRec)> attempts, double lineMs) {
    final looks = <ItemKey, List<bool>>{};
    for (final (k, a) in attempts) {
      (looks[k] ??= []).add(WeakCards.fast(miss: a.miss, clean: a.clean, us: a.us, lineMs: lineMs));
    }
    return looks.values.where(WeakCards.cleared).length;
  }
}
