import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The training reminders (flutter_local_notifications) show and open the
    // app through the delegate FlutterAppDelegate passes on to plugins.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let clock = FlutterMethodChannel(
      name: "fudatobashi/clock", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    clock.setMethodCallHandler { call, result in
      if call.method == "sleepOffsetUs" {
        result(sleepOffsetUs())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Touches are stamped with mach_absolute_time (CLOCK_UPTIME_RAW), which
/// stops while the device sleeps; Flutter's frame times come from the Dart
/// VM's CLOCK_MONOTONIC_RAW, which keeps counting. Their gap in µs, read back
/// to back.
private func sleepOffsetUs() -> Int {
  let monotonic = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
  let uptime = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
  return (Int(monotonic) - Int(uptime)) / 1000
}
