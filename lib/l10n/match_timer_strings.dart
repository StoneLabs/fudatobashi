import 'strings.dart';

/// Strings of the match timer.
extension MatchTimerStrings on S {
  String get matchTimerTitle => t('matchTimerTitle');
  String get matchTimerNote => t('matchTimerNote');
  String get timerPlay => t('timerPlay');
  String get timerPause => t('timerPause');
  String get timerResume => t('timerResume');
  String get timerStop => t('timerStop');
  String get timerSetTitle => t('timerSetTitle');
  String get timerMinutes => t('timerMinutes');
  String get timerSeconds => t('timerSeconds');
  String get timerEdit => t('timerEdit');

  /// The ongoing notification while the timer runs (Android), naming the
  /// minutes left at the warning.
  String timerNoticeText(int warnMinutes) => f('timerNoticeText', [warnMinutes]);

  /// Why the timer asks to show a notification, before Android asks.
  String get timerNotifyTitle => t('timerNotifyTitle');
  String get timerNotifyReason => t('timerNotifyReason');
  String get timerNotifyContinue => t('timerNotifyContinue');
}
