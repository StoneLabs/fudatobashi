import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Puts a frame's vsync time on the clock that stamps pointer events, so a
/// card's reveal and the touch answering it can be subtracted.
///
/// The engine takes the two from different clocks on some platforms:
/// * iOS and macOS stamp a touch with UIKit's / AppKit's event time,
///   mach_absolute_time (CLOCK_UPTIME_RAW), which stops while the device
///   sleeps, but a frame with the Dart VM's CLOCK_MONOTONIC_RAW, which keeps
///   counting. They drift apart by all the sleep since boot. The runner
///   reads both clocks back to back and reports the gap, which is cached
///   here and read again whenever the device may have slept since (app
///   start, resume, a run's start), so nothing on the swipe path waits.
/// * Linux (GTK) passes on the compositor's 32-bit millisecond event time
///   (CLOCK_MONOTONIC), which wraps every 2³² ms (49.7 days of uptime),
///   while frames carry the full CLOCK_MONOTONIC.
/// * Android and Windows stamp both from one clock.
abstract final class PointerClock {
  static const _channel = MethodChannel('fudatobashi/clock');
  static const _gtkWrapUs = (1 << 32) * Duration.microsecondsPerMillisecond;

  static Duration? _sleep;
  static AppLifecycleListener? _resumes;

  static TargetPlatform? get _platform => kIsWeb ? null : defaultTargetPlatform;

  /// The pointer clock falls behind the frame clock while the device sleeps.
  static bool get stopsInSleep => _platform == TargetPlatform.iOS || _platform == TargetPlatform.macOS;

  /// [frameTs], a frame's vsync time, on the pointer-event clock.
  static Duration fromFrame(Duration frameTs) => frameTs - _offsetAt(frameTs);

  static Duration _offsetAt(Duration frameTs) => switch (_platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => _sleep ?? Duration.zero,
        TargetPlatform.linux => Duration(microseconds: frameTs.inMicroseconds - frameTs.inMicroseconds % _gtkWrapUs),
        _ => Duration.zero,
      };

  /// Frame clock minus pointer clock now, for the developer read-out; null
  /// while the runner has not reported the sleep gap yet.
  static Duration? get offset =>
      stopsInSleep ? _sleep : _offsetAt(SchedulerBinding.instance.currentSystemFrameTimeStamp);

  /// Reads the sleep gap now and again on every return to the foreground.
  static void start() {
    if (!stopsInSleep) return;
    _resumes ??= AppLifecycleListener(onResume: () => unawaited(sync()));
    unawaited(sync());
  }

  /// Reads the sleep gap again, where there is one. A reveal meanwhile uses
  /// the last value read.
  static Future<void> sync() async {
    if (!stopsInSleep) return;
    try {
      final us = await _channel.invokeMethod<int>('sleepOffsetUs');
      if (us != null) _sleep = Duration(microseconds: us);
    } on Exception {
      // A runner without the channel: times stay unconverted, and the
      // impossible ones are kept out of every statistic (see
      // `Attempt.isValidTime`).
    }
  }
}
