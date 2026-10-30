import '../config/config.dart';
import 'side_trips.dart';
import 'trainer.dart';

/// The tabs that open as a new player gets going.
enum LockedTab { history, stats, sideTrips }

/// What opens a locked tab.
enum TabUnlock {
  /// Playing rounds (any recorded run, finished or ended early, side-trip
  /// games included).
  rounds,

  /// Playing rounds through to the last card.
  finishedRounds,

  /// Finishing the journey's first island.
  firstIsland,

  /// Remembering cards well (see [SideTripUnlocks]).
  rememberedCards,
}

/// Why a tab is still locked: what opens it and, for rounds or cards, how
/// many are [left].
class TabLock {
  const TabLock(this.needs, [this.left = 0]);

  final TabUnlock needs;
  final int left;

  /// What keeps [tab] locked, or null once it is open. Worked out from the
  /// player's history, so a player who already qualifies never sees a lock:
  /// History opens after [TabLockTuning.historyRounds] rounds; Stats once the
  /// first island is finished, or in all-known mode (no islands) after
  /// [TabLockTuning.statsFinishedRounds] finished rounds; Side Trips once
  /// enough cards are [remembered] well at once, and for good once it has
  /// ([sideTripsLatched]).
  static TabLock? of(
    LockedTab tab, {
    required LearningMode mode,
    required int rounds,
    required int finishedRounds,
    required bool islandFinished,
    required int remembered,
    required bool sideTripsLatched,
  }) =>
      switch (tab) {
        LockedTab.history => _count(TabUnlock.rounds, rounds, TabLockTuning.historyRounds),
        LockedTab.stats when mode == LearningMode.allKnown =>
          _count(TabUnlock.finishedRounds, finishedRounds, TabLockTuning.statsFinishedRounds),
        LockedTab.stats => islandFinished ? null : const TabLock(TabUnlock.firstIsland),
        LockedTab.sideTrips => switch (SideTripUnlocks.tabLock(
              allKnown: mode == LearningMode.allKnown, remembered: remembered, latched: sideTripsLatched)) {
            null => null,
            final lock => TabLock(TabUnlock.rememberedCards, lock.needed),
          },
      };

  static TabLock? _count(TabUnlock needs, int done, int required) =>
      done >= required ? null : TabLock(needs, required - done);
}
