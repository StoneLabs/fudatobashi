import 'strings.dart';

/// Month abbreviations for `StatsStrings.shortDate` (no `intl` in this
/// project; the Japanese side just uses numerals).
const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Strings of the Stats screen (the archipelago and the all-cards list).
extension StatsStrings on S {
  String get islandsTab => t('islandsTab');
  String get allTab => t('allTab');

  String get summaryLine => t('summaryLine');

  String get legendHeading => t('legendHeading');
  String legendUnder(String upperS) => f('legendUnder', [upperS]);
  String legendRange(String lowerS, String upperS) => f('legendRange', [lowerS, upperS]);
  String legendOver(String lowerS) => f('legendOver', [lowerS]);
  String legendFewTries(int n) => f('legendFewTries', [n]);

  String get slowestIslandTag => t('slowestIslandTag');
  String get islandLineTemplate => t('islandLineTemplate');
  String get tapAnIsland => t('tapAnIsland');
  String get playThisIsland => t('playThisIsland');
  String get playThisIslandLocked => t('playThisIslandLocked');
  String uncoverIslandToPlay(int unlocked, int total) => f('uncoverIslandToPlay', [unlocked, total]);
  String get noIslandToPractise => t('noIslandToPractise');

  /// A short "Mon D" (EN) / "M月D日" (JA) date, no time (island/card detail's
  /// due dates).
  String shortDate(DateTime at) {
    final local = at.toLocal();
    return ja ? '${local.month}月${local.day}日' : '${_monthAbbr[local.month - 1]} ${local.day}';
  }

  // ---------------------------------------------------------- Island detail

  String islandSubtitle(int number, int cardCount) => f('islandSubtitle', [number, cardCount]);
  String get islandMedianLabel => t('islandMedianLabel');

  /// "{0} due today", the number set in display type by `NumberedText`.
  String get dueTodayLine => t('dueTodayLine');

  String get sortLabel => t('sortLabel');
  String get sortOrder => t('sortOrder');
  String get sortSlow => t('sortSlow');
  String get sortDue => t('sortDue');

  String get notLearnedYet => t('notLearnedYet');
  String get neverReviewed => t('neverReviewed');
  String get dueTodayShort => t('dueTodayShort');
  String dueInDays(int n) => f('dueInDays', [n]);

  // ------------------------------------------------------------ Card detail

  String islandCrumb(String islandName) => f('islandCrumb', [islandName]);
  String get kimarijiCaption => t('kimarijiCaption');
  String get topSpeedLabel => t('topSpeedLabel');
  String get attemptsLabel => t('attemptsLabel');
  String get dontKnowLabel => t('dontKnowLabel');

  /// After a count of attempts ("57 回"); English needs none.
  String? get timesSuffix => ja ? t('timesSuffix') : null;
  String get lookAlikesLabel => t('lookAlikesLabel');
  String get topSpeedChartLabel => t('topSpeedChartLabel');
  String get attemptsAxis => t('attemptsAxis');
  String get noAttemptsYet => t('noAttemptsYet');
  String get uprightLabel => t('uprightLabel');
  String get invertedLabel => t('invertedLabel');
  String get allModes => t('allModes');

  String get memoryTag => t('memoryTag');
  String lastReviewedOn(String date) => f('lastReviewedOn', [date]);
  String get stabilityLabel => t('stabilityLabel');
  String get difficultyLabel => t('difficultyLabel');
  String get retrievabilityLabel => t('retrievabilityLabel');
  String get nextDueLabel => t('nextDueLabel');
  String get stabilityUnit => t('stabilityUnit');
  String outOf(int max) => f('outOf', [max]);
  String get retrievabilityNow => t('retrievabilityNow');
  String get dueTodayValue => t('dueTodayValue');
  String get dueTomorrow => t('dueTomorrow');
  String dueInDaysSuffix(int n) => f('dueInDaysSuffix', [n]);
  String get notScheduled => t('notScheduled');
  String seeYouOn(String date) => f('seeYouOn', [date]);

  // ------------------------------------------------------------ Rank ladder

  String get youTag => t('youTag');
  String get topClassNote => t('topClassNote');
  String get clearStamp => t('clearStamp');
  String get toGoTemplate => t('toGoTemplate');
  String get previewRankUp => t('previewRankUp');
}
