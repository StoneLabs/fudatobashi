import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/config.dart';

/// The words of the ongoing notification Android shows while the timer runs.
typedef MatchTimerNotice = ({String title, String text, String channel});

/// What [MatchTimerAlerts] asks of the platform; tests fake it. Each call is
/// sent at once, in order, and never throws: a platform without the feature
/// just goes without.
abstract interface class MatchTimerPlatform {
  void keepScreenOn(bool on);

  /// Keeps the app awake in the background, with [notice] counting down to
  /// [endsAt], until it is stopped or [releaseAt] passes.
  void keepAlive({required DateTime endsAt, required DateTime releaseAt, required MatchTimerNotice notice});

  void letGo();

  /// Whether the notification needs a permission not yet granted.
  Future<bool> needsNotificationPermission();

  Future<void> askNotificationPermission();
}

/// Keeps a running match timer on screen and audible: the screen stays on
/// while it runs and, on Android, a foreground service keeps the app awake
/// (its own ticks play the sounds) when the player switches apps or locks
/// the phone. Time itself comes from the wall clock, so it is right whenever
/// the app looks again.
class MatchTimerAlerts {
  MatchTimerAlerts({MatchTimerPlatform? platform, this.now = DateTime.now}) : _platform = platform ?? _Device();

  final MatchTimerPlatform _platform;
  final DateTime Function() now;
  bool _running = false;

  /// Started or resumed with [left] to go.
  void run(Duration left, MatchTimerNotice notice) {
    final endsAt = now().add(left);
    _running = true;
    _platform.keepScreenOn(true);
    _platform.keepAlive(endsAt: endsAt, releaseAt: endsAt.add(MatchTimerTuning.backgroundLinger), notice: notice);
  }

  /// Reached zero: the screen may sleep, and the background service lets go
  /// by itself once the end sound has had time to play.
  void finish() {
    if (!_running) return;
    _running = false;
    _platform.keepScreenOn(false);
  }

  /// Paused, stopped, or the screen closed.
  void release() {
    if (!_running) return;
    _running = false;
    _platform.keepScreenOn(false);
    _platform.letGo();
  }

  Future<bool> needsNotificationPermission() => _platform.needsNotificationPermission();

  Future<void> askNotificationPermission() => _platform.askNotificationPermission();
}

/// The real platform: wakelock_plus everywhere, and on Android the
/// `MatchTimerService` behind `MainActivity.kt`'s channel.
class _Device implements MatchTimerPlatform {
  static const _channel = MethodChannel('fudatobashi/match_timer');

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void keepScreenOn(bool on) => _quietly(WakelockPlus.toggle(enable: on));

  @override
  void keepAlive({required DateTime endsAt, required DateTime releaseAt, required MatchTimerNotice notice}) {
    if (!_android) return;
    _quietly(_channel.invokeMethod<void>('start', {
      'endsAt': endsAt.millisecondsSinceEpoch,
      'releaseAt': releaseAt.millisecondsSinceEpoch,
      'title': notice.title,
      'text': notice.text,
      'channel': notice.channel,
    }));
  }

  @override
  void letGo() {
    if (_android) _quietly(_channel.invokeMethod<void>('stop'));
  }

  @override
  Future<bool> needsNotificationPermission() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('needsNotificationPermission') ?? false;
    } catch (e) {
      debugPrint('MatchTimerAlerts: $e');
      return false;
    }
  }

  @override
  Future<void> askNotificationPermission() async {
    try {
      await _channel.invokeMethod<bool>('askNotificationPermission');
    } catch (e) {
      debugPrint('MatchTimerAlerts: $e');
    }
  }

  static void _quietly(Future<void> call) =>
      unawaited(call.catchError((Object e) => debugPrint('MatchTimerAlerts: $e')));
}
