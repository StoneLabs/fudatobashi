import '../config/config.dart';
import 'trainer.dart';

/// The tabs that open as a new player gets going.
enum LockedTab { history, stats }

/// What opens a locked tab.
enum TabUnlock {
  /// Playing rounds (any recorded run, finished or ended early).
  rounds,

  /// Playing rounds through to the last card.
  finishedRounds,

  /// Finishing the journey's first island.
  firstIsland,
}

/// Why a tab is still locked: what opens it and, for rounds, how many are
/// [left].
class TabLock {
  const TabLock(this.needs, [this.left = 0]);

  final TabUnlock needs;
  final int left;

  /// What keeps [tab] locked, or null once it is open. Worked out from the
  /// player's history, so a player who already qualifies never sees a lock:
  /// History opens after [TabLockTuning.historyRounds] rounds; Stats once the
  /// first island is finished, or in all-known mode (no islands) after
  /// [TabLockTuning.statsFinishedRounds] finished rounds.
  static TabLock? of(
    LockedTab tab, {
    required LearningMode mode,
    required int rounds,
    required int finishedRounds,
    required bool islandFinished,
  }) =>
      switch (tab) {
        LockedTab.history => _rounds(TabUnlock.rounds, rounds, TabLockTuning.historyRounds),
        LockedTab.stats when mode == LearningMode.allKnown =>
          _rounds(TabUnlock.finishedRounds, finishedRounds, TabLockTuning.statsFinishedRounds),
        LockedTab.stats => islandFinished ? null : const TabLock(TabUnlock.firstIsland),
      };

  static TabLock? _rounds(TabUnlock needs, int played, int required) =>
      played >= required ? null : TabLock(needs, required - played);
}
