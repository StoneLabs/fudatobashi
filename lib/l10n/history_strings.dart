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

  /// A short "Mon D, HH:MM" (EN) / "M月D日 HH:MM" (JA) timestamp.
  String sessionDate(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return ja ? '${local.month}月${local.day}日 $hh:$mm' : '${_monthAbbr[local.month - 1]} ${local.day}, $hh:$mm';
  }
}
