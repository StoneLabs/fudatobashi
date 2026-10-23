import 'package:fudatobashi/state/reminders.dart';
import 'package:timezone/timezone.dart' as tz;

/// Records what the reminders ask of the platform; [granted] is the
/// player's answer to the permission question, and [allowed] whether the
/// app may notify right now.
class FakeReminderPlatform implements ReminderPlatform {
  FakeReminderPlatform(this.location);

  final tz.Location location;
  bool granted = true;
  bool allowed = true;
  int asked = 0, settingsOpened = 0;
  final scheduled = <List<tz.TZDateTime>>[];
  final texts = <ReminderText>[];

  @override
  Future<tz.Location> zone() async => location;

  @override
  Future<bool> askPermission() async {
    asked++;
    return allowed = granted;
  }

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> replace(List<tz.TZDateTime> times, ReminderText text) async {
    scheduled.add(times);
    texts.add(text);
  }
}
