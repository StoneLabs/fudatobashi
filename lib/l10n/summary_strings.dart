import 'results_strings.dart';
import 'strings.dart';

/// Strings of the run summary every game ends on.
extension SummaryStrings on S {
  // The header: the mode, in this language as the title and in the other
  // language on the line under it.
  String get summaryTraining => t('summaryTraining');
  String get summaryFree => t('summaryFree');
  String get summaryWeak => t('summaryWeak');
  String get summaryGuest => t('summaryGuest');
  String get summaryRanked => t('summaryRanked');
  String get summaryPlacement => t('summaryPlacement');
  String get summaryExam => t('summaryExam');
  String summaryCardsOf(int played, int cards) => f('summaryCardsOf', [played, cards]);

  // The hero's banners.
  String get summaryTodaysSet => t('summaryTodaysSet');
  String get summaryThisRun => t('summaryThisRun');
  String get summaryDueToday => t('summaryDueToday');
  String get summaryVsTobi => t('summaryVsTobi');
  String summaryLevel(int level) => f('summaryLevel', [level]);

  // The hero's answers.
  String summaryCardsLeft(int n) => t(countKey('summaryCardsLeft', n));
  String summaryOfSet(int looks) => f('summaryOfSet', [looks]);
  String get summaryRight => t('summaryRight');
  String summaryOfCards(int cards) => f('summaryOfCards', [cards]);
  String summaryWeakLeft(int n) => t(countKey('summaryWeakLeft', n));
  String summaryDueLeft(int n) => t(countKey('summaryDueLeft', n));
  String summaryReviewedToday(int n) => f('summaryReviewedToday', [n]);
  String get summaryPoints => t('summaryPoints');
  String summaryFound(int n) => t(countKey('summaryFound', n));
  String summaryFoundOf(int cards, int missed) =>
      missed == 0 ? f('summaryFoundOfAll', [cards]) : f('summaryFoundOf', [cards, missed]);
  String get summaryDone => t('summaryDone');
  String get summaryClear => t('summaryClear');
  String get summaryPassed => t('summaryPassed');
  String get summaryFailed => t('summaryFailed');
  String get summaryNotCleared => t('summaryNotCleared');
  String get summaryCountsAsZero => t('summaryCountsAsZero');
  String summaryStrikesOut(int strikes) => f('summaryStrikesOut', [strikes]);
  String summaryTobiTime(String time) => f('summaryTobiTime', [time]);

  // The bar's labels.
  String summaryDoneOf(int done, int total) => f('summaryDoneOf', [done, total]);
  String summaryThisRunPlus(int looks) => f('summaryThisRunPlus', [looks]);
  String summaryRightCount(int n) => f('summaryRightCount', [n]);
  String summaryMissedCount(int n) => f('summaryMissedCount', [n]);
  String summaryClearedOf(int cleared, int of) => f('summaryClearedOf', [cleared, of]);
  String summaryCleared(int n) => f('summaryCleared', [n]);
  String summaryStillWeak(int n) => f('summaryStillWeak', [n]);
  String summaryReviewedOf(int done, int total) => f('summaryReviewedOf', [done, total]);
  String summaryClock(String time) => f('summaryClock', [time]);
  String summaryMisses(int misses, int seconds) => f(countKey('summaryMisses', misses), [misses, seconds]);
  String summaryPlayed(int n) => f('summaryPlayed', [n]);
  String summaryLeft(int n) => f('summaryLeft', [n]);
  String summaryFinds(String points) => f('summaryFinds', [points]);
  String summaryEarly(String points) => f('summaryEarly', [points]);
  String summaryFoundCount(int found, int of) => f('summaryFoundCount', [found, of]);

  // Tobi's balloon.
  String get summaryAlmostThere => t('summaryAlmostThere');
  String get summaryNiceRun => t('summaryNiceRun');
  String get summaryGettingThere => t('summaryGettingThere');
  String summaryStreakBalloon(int days) => f('summaryStreakBalloon', [days]);
  String get summaryRatingUp => t('summaryRatingUp');
  String get summaryFirstRating => t('summaryFirstRating');
  String get summaryNextTime => t('summaryNextTime');
  String summaryAgainIn(int minutes) => f('summaryAgainIn', [minutes]);
  String get summarySoClose => t('summarySoClose');
  String get summaryNice => t('summaryNice');

  // The tiles.
  String get summaryCardsLabel => t('summaryCardsLabel');
  String get summaryThisRunNote => t('summaryThisRunNote');
  String get summaryAllKnownNote => t('summaryAllKnownNote');
  String get summaryThisDrill => t('summaryThisDrill');
  String get summaryRightLabel => t('summaryRightLabel');
  String get summaryNoMisses => t('summaryNoMisses');
  String summaryMissedPenalty(int misses, int seconds) =>
      f(countKey('summaryMissedPenalty', misses), [misses, seconds]);
  String summaryXpToLevel(String xp, int level) => f('summaryXpToLevel', [xp, level]);

  /// "LV {0}" around where a level's number goes: the text before it and
  /// after it.
  (String, String) get summaryLevelAround {
    final parts = t('levelShort').split('{0}');
    return (parts.first, parts.length > 1 ? parts[1] : '');
  }
  String summaryXpGained(String xp) => f('summaryXpGained', [xp]);
  String get summaryNotSaved => t('summaryNotSaved');
  String get summaryTodayLabel => t('summaryTodayLabel');
  String get summaryLeftInSet => t('summaryLeftInSet');
  String get summarySetDone => t('summarySetDone');
  String get summarySpeedLabel => t('summarySpeedLabel');
  String get summaryAvgPerCard => t('summaryAvgPerCard');
  String get summaryNextTryLabel => t('summaryNextTryLabel');
  String get summaryNow => t('summaryNow');
  String summaryXpEarned(String xp) => f('summaryXpEarned', [xp]);
  String summaryFoundLate(int n) => f('summaryFoundLate', [n]);
  String get summaryAllFirstTry => t('summaryAllFirstTry');
  String summaryStrikesOf(int strikes, int of) => f('summaryStrikesOf', [strikes, of]);
  String get summaryNone => t('summaryNone');
  String get summaryOpenedLabel => t('summaryOpenedLabel');
  String summaryLevelClosed(int level) => f('summaryLevelClosed', [level]);

  // The card panel's rows.
  String get summaryNewCards => t('summaryNewCards');
  String get summaryNewCardsNote => t('summaryNewCardsNote');
  String get summaryMissed => t('summaryMissed');
  String get summaryBackLater => t('summaryBackLater');
  String get summaryNewToday => t('summaryNewToday');
  String summaryNewTodayNote(int n) => f(countKey('summaryNewTodayNote', n), [n]);
  String get summaryStreak => t('summaryStreak');
  String summaryStreakNote(int days) => f(countKey('summaryStreakNote', days), [days]);
  String get summarySecondLook => t('summarySecondLook');
  String get summarySlowest => t('summarySlowest');
  String get summaryClearedNote => t('summaryClearedNote');
  String get summaryNotYetNote => t('summaryNotYetNote');
  String get summaryNoWeakLeft => t('summaryNoWeakLeft');
  String get summaryDueSoon => t('summaryDueSoon');
  String summaryPenaltyEach(int seconds) => f('summaryPenaltyEach', [seconds]);
  String get summaryBeforeStop => t('summaryBeforeStop');
  String get summarySlowestFinds => t('summarySlowestFinds');
  String get summaryNotFound => t('summaryNotFound');
  String get summaryNotFirstTap => t('summaryNotFirstTap');
  String summaryLateMissed(int late, int missed) => f('summaryLateMissed', [late, missed]);

  /// The tag of a card found with tap [n] (the 2nd tap, the 3rd …).
  String summaryTapTag(int n) => ja ? f('summaryTapTag', [n]) : f('summaryTapTag', [ResultsStrings.ordinal(n)]);
  String get summaryMissedTag => t('summaryMissedTag');
  String get summaryLevels => t('summaryLevels');
  String summaryLevelOpen(int level) => f('summaryLevelOpen', [level]);
  String summaryRankedNext(int level) => f('summaryRankedNext', [level]);
  String summaryAllCards(int n) => f('summaryAllCards', [n]);
  String summaryMore(int n) => f('summaryMore', [n]);
}
