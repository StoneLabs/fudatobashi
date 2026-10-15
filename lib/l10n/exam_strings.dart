import 'strings.dart';

/// Strings of the graduation exam's run (卒業試験): its start and leave
/// sheets, the race against Tobi, and the page when Tobi wins.
extension ExamStrings on S {
  /// The exam's tag: Latin capitals in every language, like the other tags.
  String get examTag => 'GRADUATION EXAM';
  String get examStartTitle => t('examStartTitle');
  String get examRuleCards => t('examRuleCards');
  String get examRuleBeat => t('examRuleBeat');
  String examRulePenalty(int seconds) => f('examRulePenalty', [seconds]);
  String get examRuleTry => t('examRuleTry');
  String get examStart => t('examStart');
  String get examNotNow => t('examNotNow');
  String get examLeaveTitle => t('examLeaveTitle');
  String get examLeaveBody => t('examLeaveBody');
  String get examLeaveYes => t('examLeaveYes');
  String get examLeaveNo => t('examLeaveNo');
  String get examGreetingSub => t('examGreetingSub');
  String get examTobi => t('examTobi');
  String get examYou => t('examYou');
  String examPenaltyPop(int seconds) => f('examPenaltyPop', [seconds]);
  String get examWinShout => t('examWinShout');
  String get examTimeUpShout => t('examTimeUpShout');
  String get examTobiWinsShout => t('examTobiWinsShout');
  String get examWaiting => t('examWaiting');
  String get examTobiThinking => t('examTobiThinking');
  String get examLostTitle => t('examLostTitle');
  String get examTobiTime => t('examTobiTime');
  String get examYourTime => t('examYourTime');
  String examMissesLine(int misses, int seconds) =>
      f(misses == 1 ? 'examMissesLineOne' : 'examMissesLine', [misses, seconds]);
  String examCardsLine(int done, int total) => f('examCardsLine', [done, total]);
  String get examXpEarned => t('examXpEarned');
  String get examNextTry => t('examNextTry');
  String get examReady => t('examReady');
}
