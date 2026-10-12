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
}
