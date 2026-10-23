import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/config.dart';
import '../domain/reminder_schedule.dart';
import '../domain/trainer.dart';
import '../l10n/localization.dart';
import '../l10n/reminder_strings.dart';
import '../l10n/strings.dart';
import 'play_config.dart';
import 'progress.dart';

/// The words of a reminder and of its Android channel, in the player's
/// language.
typedef ReminderText = ({String title, String body, String channel, String channelNote});

/// What [Reminders] asks of the platform; tests fake it.
abstract interface class ReminderPlatform {
  /// The device's time zone.
  Future<tz.Location> zone();

  /// Whether the app may notify, asking the player first where the system
  /// still lets it ask.
  Future<bool> askPermission();

  /// Whether the app may notify now, without asking.
  Future<bool> permitted();

  /// Opens the system's notification settings for the app.
  Future<void> openSettings();

  /// Replaces every scheduled reminder with one at each of [times].
  Future<void> replace(List<tz.TZDateTime> times, ReminderText text);
}

/// The daily training reminders: while they are on, in journey mode, a
/// notification at [ReminderTuning.hour] on each of the next
/// [ReminderTuning.days] days whose set is not done yet (see
/// [reminderTimes]). [attach] keeps them in step with the player's
/// progress and settings and with the clock, each time the app comes back
/// to the foreground.
class Reminders with WidgetsBindingObserver {
  Reminders({ReminderPlatform? platform, this.now = DateTime.now})
      : _platform = platform ?? (_mobile ? _Device() : const _Desktop());

  final ReminderPlatform _platform;
  final DateTime Function() now;

  static bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Progress? _progress;
  Future<void> _queue = Future.value();
  Future<tz.Location>? _zone;

  /// The times and words last handed to the platform.
  String? _scheduled;

  /// Whether the phone lets the app notify, as last seen: checked as the
  /// app starts and each time it comes back to the foreground, since the
  /// player may change it in the phone's settings meanwhile.
  final notificationsAllowed = ValueNotifier(true);

  /// Follows [progress], instead of any other, until it is detached.
  void attach(Progress progress) {
    _progress?.removeListener(_onChange);
    _progress = progress..addListener(_onChange);
    WidgetsBinding.instance
      ..removeObserver(this)
      ..addObserver(this);
    _onChange();
    unawaited(_checkPermission());
  }

  /// Stops following [progress], if it still is.
  void detach(Progress progress) {
    if (_progress != progress) return;
    progress.removeListener(_onChange);
    _progress = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Back in the foreground, perhaps a day later or in another time zone.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _zone = null;
    _onChange();
    unawaited(_checkPermission());
  }

  Future<void> _checkPermission() async {
    try {
      notificationsAllowed.value = await _platform.permitted();
    } catch (e) {
      debugPrint('Reminders: $e');
    }
  }

  void _onChange() {
    final progress = _progress;
    if (progress != null) unawaited(sync(progress));
  }

  /// Completes once every update asked for so far has reached the platform.
  Future<void> get idle => _queue;

  /// Brings the scheduled reminders in line with [progress] as it is now.
  Future<void> sync(Progress progress) => _queue = _queue.then((_) => _sync(progress)).catchError((Object e) {
        debugPrint('Reminders: $e');
      });

  Future<void> _sync(Progress progress) async {
    final settings = progress.settings;
    final mode = progress.trainer.config.learningMode;
    final at = now();
    // Times go unused while reminders are off, so any zone does.
    final zone = settings.reminders && mode == LearningMode.journey ? await (_zone ??= _platform.zone()) : tz.UTC;
    final times = reminderTimes(
      now: tz.TZDateTime.from(at, zone),
      mode: mode,
      enabled: settings.reminders,
      todayDone: progress.todaySet(at)?.done ?? false,
      dayEnd: progress.dayAt(at).end,
    );
    final s = S(Localization.resolve(settings.language, PlatformDispatcher.instance.locale.languageCode));
    final text = (
      title: s.reminderNoticeTitle,
      body: s.reminderNoticeBody,
      channel: s.reminderChannel,
      channelNote: s.reminderChannelNote,
    );
    final plan = [for (final t in times) t.millisecondsSinceEpoch, text].join(' ');
    if (plan == _scheduled) return;
    await _platform.replace(times, text);
    _scheduled = plan;
  }

  /// Turns the reminders on once the system lets the app notify, asking
  /// the player for that first if it may: true. False leaves them off.
  Future<bool> turnOn(Progress progress) async {
    final allowed = notificationsAllowed.value = await _platform.askPermission();
    if (!allowed) return false;
    await progress.updateSettings(progress.settings.copyWith(reminders: true));
    return true;
  }

  Future<void> turnOff(Progress progress) => progress.updateSettings(progress.settings.copyWith(reminders: false));

  /// Opens the system's notification settings for the app, for a player
  /// who blocked them.
  Future<void> openSettings() => _platform.openSettings();
}

/// The app's reminders; tests swap in one with a fake platform.
Reminders reminders = Reminders();

/// Whether Results should offer the reminders, once ever, after [report]:
/// in journey mode, with them still off, after the run that finished the
/// first day's set, or, for a player who finished one before the offer
/// existed, after their next training run.
bool remindersOfferDue(Progress progress, SessionReport report) {
  final settings = progress.settings;
  if (settings.remindersOffered || settings.reminders || report.runId == null) return false;
  if (progress.trainer.config.learningMode != LearningMode.journey) return false;
  return report.dayDone != null || report.mode == PlayMode.training && progress.runs.any((r) => r.dayDone);
}

/// The phone: flutter_local_notifications, its times in the device's time
/// zone from flutter_timezone.
class _Device implements ReminderPlatform {
  final _plugin = FlutterLocalNotificationsPlugin();
  tz.Location? _location;
  late final Future<void> _ready = _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(ReminderTuning.androidIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  @override
  Future<tz.Location> zone() async {
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      if (_location case final known? when known.name == name) return known;
      // The database takes a while to read: away from the UI thread.
      final location = await Isolate.run(() {
        tz_data.initializeTimeZones();
        return tz.getLocation(name);
      });
      return _location = location;
    } catch (e) {
      debugPrint('Reminders: $e');
      // The offset in force now, for every day ahead.
      return tz.Location('', const [], const [],
          [tz.TimeZone(DateTime.now().timeZoneOffset, isDst: false, abbreviation: '')]);
    }
  }

  @override
  Future<bool> askPermission() async {
    await _ready;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  @override
  Future<bool> permitted() async {
    await _ready;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    final options =
        await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  @override
  Future<void> openSettings() async {
    await _ready;
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> replace(List<tz.TZDateTime> times, ReminderText text) async {
    await _ready;
    await _plugin.cancelAllPendingNotifications();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        ReminderTuning.channelId,
        text.channel,
        channelDescription: text.channelNote,
        styleInformation: BigTextStyleInformation(text.body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    // Each reminder goes off once, so its instant is all that counts: in UTC,
    // the native side never has to know the zone it was worked out in.
    for (final (i, at) in times.indexed) {
      await _plugin.zonedSchedule(
        id: ReminderTuning.firstId + i,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: text.title,
        body: text.body,
      );
    }
  }
}

/// Desktop and web builds: no notifications, and nothing in the way of
/// turning the setting on.
class _Desktop implements ReminderPlatform {
  const _Desktop();

  @override
  Future<tz.Location> zone() async => tz.UTC;

  @override
  Future<bool> askPermission() async => true;

  @override
  Future<bool> permitted() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> replace(List<tz.TZDateTime> times, ReminderText text) async {}
}
