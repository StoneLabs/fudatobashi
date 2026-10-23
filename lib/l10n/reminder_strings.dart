import 'strings.dart';

/// Strings of the daily training reminders: the offer on Results, the
/// Settings switch, the note when notifications are blocked, and the
/// notification itself.
extension ReminderStrings on S {
  String get reminderOfferTitle => t('reminderOfferTitle');
  String get reminderOfferBody => t('reminderOfferBody');
  String get reminderOfferNote => t('reminderOfferNote');
  String get reminderOfferYes => t('reminderOfferYes');
  String get reminderOfferNo => t('reminderOfferNo');

  /// The player said yes, but the phone doesn't let the app notify.
  String get reminderBlockedTitle => t('reminderBlockedTitle');
  String get reminderBlockedBody => t('reminderBlockedBody');
  String get reminderBlockedOpen => t('reminderBlockedOpen');

  String get remindersSetting => t('remindersSetting');
  String get remindersSettingNote => t('remindersSettingNote');

  /// Under the switch while it is on but the phone doesn't let the app
  /// notify.
  String get remindersBlockedWarning => t('remindersBlockedWarning');

  String get reminderNoticeTitle => t('reminderNoticeTitle');
  String get reminderNoticeBody => t('reminderNoticeBody');

  /// The Android notification channel, as the phone's settings list it.
  String get reminderChannel => t('reminderChannel');
  String get reminderChannelNote => t('reminderChannelNote');
}
