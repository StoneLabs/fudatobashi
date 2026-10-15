import 'strings.dart';

/// Strings of History's run pages.
extension RunStrings on S {
  String get runTitle => t('runTitle');

  /// The run page's tabs.
  String get runTabOverview => t('runTabOverview');
  String get runTabCards => t('runTabCards');
  String get runTabSpeed => t('runTabSpeed');
  String get runTabRating => t('runTabRating');
  String get runTabXp => t('runTabXp');
  String get runTabSwipes => t('runTabSwipes');
  String get runTabGame => t('runTabGame');

  /// The line under the Rating and Score tabs.
  String get tabAndXp => t('tabAndXp');

  /// The exam's kind tag.
  String get runExamTag => t('runExamTag');
  String runCardsLine(int cards) => f('runCardsLine', [cards]);
  String get runLoading => t('runLoading');

  /// The Overview tab: headline facts, the time graph and its legend, the
  /// speed chart.
  String get runScoredTime => t('runScoredTime');
  String get runTimeLabel => t('runTimeLabel');
  String get runPerCard => t('runPerCard');
  String get runAvgCard => t('runAvgCard');
  String get runMisses => t('runMisses');
  String get runRatingFact => t('runRatingFact');
  String get runXpFact => t('runXpFact');
  String get runRightShare => t('runRightShare');
  String runClockLine(Object a0, Object a1) => f('runClockLine', [a0, a1]);
  String runUpsideDown(Object a0) => f('runUpsideDown', [a0]);
  String runTotalLine(Object a0) => f('runTotalLine', [a0]);
  String get runFastestKind => t('runFastestKind');
  String get runSetDone => t('runSetDone');
  String get runExamWon => t('runExamWon');
  String get runExamLost => t('runExamLost');
  String runExamBy(Object a0) => f('runExamBy', [a0]);
  String get runTobiTime => t('runTobiTime');
  String get runYourTime => t('runYourTime');
  String runForfeitLine(Object a0, Object a1) => f('runForfeitLine', [a0, a1]);
  String get runGraphTitle => t('runGraphTitle');
  String get runGraphCards => t('runGraphCards');
  String runGraphBehind(Object a0, Object a1) => f('runGraphBehind', [a0, a1]);
  String runGraphAhead(Object a0, Object a1) => f('runGraphAhead', [a0, a1]);
  String get runGraphEven => t('runGraphEven');
  String runGraphTobi(Object a0, Object a1) => f('runGraphTobi', [a0, a1]);
  String runGraphBottomRef(Object a0, Object a1) => f('runGraphBottomRef', [a0, a1]);
  String runGraphBottomCap(Object a0, Object a1) => f('runGraphBottomCap', [a0, a1]);
  String get runGraphBottomOwn => t('runGraphBottomOwn');
  String get legendThisRun => t('legendThisRun');
  String get legendEvenPace => t('legendEvenPace');
  String legendLastRuns(Object a0) => f('legendLastRuns', [a0]);
  String get legendMissPenalty => t('legendMissPenalty');
  String get legendMiss => t('legendMiss');
  String get legendBehind => t('legendBehind');
  String get legendAhead => t('legendAhead');
  String get legendTobi => t('legendTobi');
  String get legendRight => t('legendRight');
  String legendGoal(Object a0) => f('legendGoal', [a0]);
  String get runSpeedTitle => t('runSpeedTitle');
  String get runSpeedNote => t('runSpeedNote');
  String get runSwipesFact => t('runSwipesFact');
  String get runDifferentCards => t('runDifferentCards');
  String get runCameBack => t('runCameBack');
  String get runDueReviews => t('runDueReviews');
  String get runTrainingNote => t('runTrainingNote');

  /// The Cards and Every swipe tabs.
  String get runSlowest => t('runSlowest');
  String get runFastest => t('runFastest');
  String get runMissesTitle => t('runMissesTitle');
  String runMissesCount(Object a0, Object a1) => f('runMissesCount', [a0, a1]);
  String get runNoMisses => t('runNoMisses');
  String runPractise(Object a0) => f('runPractise', [a0]);
  String get runPractiseSub => t('runPractiseSub');
  String get runPractiseNote => t('runPractiseNote');
  String get runSwipesTitle => t('runSwipesTitle');
  String runSwipesCount(Object a0) => f('runSwipesCount', [a0]);
  String get colCard => t('colCard');
  String get colTime => t('colTime');
  String get colUsual => t('colUsual');
  String get colDiff => t('colDiff');
  String get colAt => t('colAt');
}
