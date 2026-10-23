import 'package:timezone/timezone.dart' as tz;

import '../config/config.dart';

/// When the daily training reminders go off: at [hour]:[minute] in [now]'s
/// time zone on each of the next [days] days that still need training. None
/// while reminders are off.
///
/// A time already past is left out, and so is any that falls before
/// [dayEnd], the end of the practice day [now] is in, once that day's set
/// is done ([todayDone]): the player has trained that day.
List<tz.TZDateTime> reminderTimes({
  required tz.TZDateTime now,
  required bool enabled,
  required bool todayDone,
  required DateTime dayEnd,
  int days = ReminderTuning.days,
  int hour = ReminderTuning.hour,
  int minute = ReminderTuning.minute,
}) {
  if (!enabled) return const [];
  final times = <tz.TZDateTime>[];
  for (var offset = 0; times.length < days; offset++) {
    final at = tz.TZDateTime(now.location, now.year, now.month, now.day + offset, hour, minute);
    if (!at.isAfter(now) || todayDone && at.isBefore(dayEnd)) continue;
    times.add(at);
  }
  return times;
}
