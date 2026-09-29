import '../domain/tab_locks.dart';
import 'strings.dart';

/// Strings of the first-run tour, its practice round and the locked tabs.
extension TourStrings on S {
  String get coachStartCard => t('coachStartCard');
  String coachKnowIt(String kana) => f('coachKnowIt', [kana]);
  String get coachDontKnowHold => t('coachDontKnowHold');
  String get coachDontKnowButton => t('coachDontKnowButton');
  String get coachDontKnowOff => t('coachDontKnowOff');
  String get coachFast => t('coachFast');
  String get coachDone => t('coachDone');
  String get coachRetryKnow => t('coachRetryKnow');
  String get coachRetryHold => t('coachRetryHold');
  String get coachRetryButton => t('coachRetryButton');

  /// Tobi's word on the locked tab [tab] (its label): what opens it.
  String lockReason(String tab, TabLock lock) => switch (lock.needs) {
        TabUnlock.rounds => lock.left == 1 ? f('lockRoundsOne', [tab]) : f('lockRoundsOther', [lock.left, tab]),
        TabUnlock.finishedRounds =>
          lock.left == 1 ? f('lockFinishedOne', [tab]) : f('lockFinishedOther', [lock.left, tab]),
        TabUnlock.firstIsland => f('lockFirstIsland', [tab]),
      };
  String tabUnlocked(String tab) => f('tabUnlocked', [tab]);
}
