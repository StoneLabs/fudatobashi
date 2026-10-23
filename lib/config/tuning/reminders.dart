part of '../config.dart';

/// The daily training reminders (Settings › Learning, and the offer on
/// Results after the first day's set): one-off notifications, one a day.
abstract final class ReminderTuning {
  /// The local time each reminder goes off. Android may deliver it a few
  /// minutes either side, as its alarms are inexact.
  static const int hour = 12;
  static const int minute = 0;

  /// How many reminders are scheduled ahead: a player who stops opening the
  /// app is reminded on this many days, then no more.
  static const int days = 14;

  /// The first reminder's notification id; the others follow on, one per
  /// day. Clear of the match timer's notification (id 1).
  static const int firstId = 1000;

  /// The Android notification channel the reminders post on.
  static const String channelId = 'training_reminders';

  /// Android's small notification icon, a drawable resource made by
  /// `scripts/icon.sh` from `assets/icon/tobi_notification.svg`.
  static const String androidIcon = 'ic_notification';
}
