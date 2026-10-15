import 'strings.dart';

/// Month abbreviations for `HistoryStrings.sessionDate` (no `intl` in this
/// project; the Japanese side just uses numerals).
const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Strings of the History screen (the list of past runs).
extension HistoryStrings on S {
  String get noRunsYet => t('noRunsYet');
  String get runEndedEarly => t('runEndedEarly');

  /// "{0} cards · {1} misses", the numbers set in display type by
  /// `NumberedText`.
  String get historyLineTemplate => t('historyLineTemplate');

  /// A side-trip game's score, "{0} pts", the number set in display type by
  /// `NumberedText`.
  String get historyScoreTemplate => t('historyScoreTemplate');

  /// A free-play side-trip game at a level preset.
  String historyFreeLevel(int level) => f('historyFreeLevel', [level]);

  /// The record strip's labels: how many runs are on show, their cards, the
  /// days they were played on, and a side trip's best score.
  String get historyRunsLabel => t('historyRunsLabel');
  String get historyCardsLabel => t('historyCardsLabel');
  String get historyDaysLabel => t('historyDaysLabel');
  String get historyBestLabel => t('historyBestLabel');

  /// A short "Mon D, HH:MM" (EN) / "M月D日 HH:MM" (JA) timestamp.
  String sessionDate(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return ja ? '${local.month}月${local.day}日 $hh:$mm' : '${_monthAbbr[local.month - 1]} ${local.day}, $hh:$mm';
  }

  /// The History list, its 7-day strip, rows and filter sheet.
  String get historyMainTab => t('historyMainTab');
  String get historyAnkirenTab => t('historyAnkirenTab');
  String get historyFilterLabel => t('historyFilterLabel');
  String get historyLast7 => t('historyLast7');
  String get historyStreak => t('historyStreak');
  String get historyNotActive => t('historyNotActive');
  String get historySomeActive => t('historySomeActive');
  String get historyDoneActive => t('historyDoneActive');
  String get historyDayDone => t('historyDayDone');
  String get historyDaySome => t('historyDaySome');
  String get historyDayAllKnown => t('historyDayAllKnown');
  String get historyDayPlayed => t('historyDayPlayed');
  String get historyToday => t('historyToday');
  String get historyScoredCaption => t('historyScoredCaption');
  String get historyTimeCaption => t('historyTimeCaption');
  String get historyPerCardCaption => t('historyPerCardCaption');
  String get historyYourTimeCaption => t('historyYourTimeCaption');
  String get historyPointsCaption => t('historyPointsCaption');
  String get historyFirstTapCaption => t('historyFirstTapCaption');
  String historyCards(Object a0) => f('historyCards', [a0]);
  String historyCardsOf(Object a0, Object a1) => f('historyCardsOf', [a0, a1]);
  String historyMissesShort(Object a0) => f('historyMissesShort', [a0]);
  String historyMissedShort(Object a0) => f('historyMissedShort', [a0]);
  String historyFirstRating(Object a0) => f('historyFirstRating', [a0]);
  String historyTobiTime(Object a0) => f('historyTobiTime', [a0]);
  String get historyPlaced => t('historyPlaced');
  String get historyForfeit => t('historyForfeit');
  String get historyBest => t('historyBest');
  String historyUpTo(Object a0) => f('historyUpTo', [a0]);
  String historyDownTo(Object a0) => f('historyDownTo', [a0]);
  String get historyAnkirenCustom => t('historyAnkirenCustom');
  String get historyNotScored => t('historyNotScored');
  String historyPerSide(Object a0, Object a1) => f('historyPerSide', [a0, a1]);
  String get historyNoMatch => t('historyNoMatch');
  String get filterTitle => t('filterTitle');
  String get filterReset => t('filterReset');
  String get filterKind => t('filterKind');
  String get filterWhen => t('filterWhen');
  String get filterMainNote => t('filterMainNote');
  String get filterAnkirenNote => t('filterAnkirenNote');
  String get filterToday => t('filterToday');
  String get filterWeek => t('filterWeek');
  String get filterMonth => t('filterMonth');
  String get filterAll => t('filterAll');
  String filterShow(Object a0) => f('filterShow', [a0]);
  String get filterShowOne => t('filterShowOne');
  String get filterAnkirenRanked => t('filterAnkirenRanked');
  String get filterAnkirenFree => t('filterAnkirenFree');

  /// A day header's date: "Thu 15 Oct" (EN) / "10月15日(木)" (JA).
  String historyDay(DateTime day) {
    final weekday = t('weekdayShort').split(' ')[day.weekday - 1];
    return ja ? '${day.month}月${day.day}日($weekday)' : '$weekday ${day.day} ${_monthAbbr[day.month - 1]}';
  }

  /// A 暗記練 row's short date: "Wed 14" (EN) / "14日(水)" (JA).
  String historyShortDay(DateTime day) {
    final weekday = t('weekdayShort').split(' ')[day.weekday - 1];
    return ja ? '${day.day}日($weekday)' : '$weekday ${day.day}';
  }

  /// The 7-day strip's mark on a day whose set was done.
  String get historyDayDoneMark => t('historyDayDoneMark');

  /// A time of day, HH:MM.
  String clockTime(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
