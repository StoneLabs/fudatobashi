import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let clock = FlutterMethodChannel(
      name: "fudatobashi/clock",
      binaryMessenger: flutterViewController.registrar(forPlugin: "PointerClock").messenger)
    clock.setMethodCallHandler { call, result in
      if call.method == "sleepOffsetUs" {
        result(sleepOffsetUs())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

/// Mouse and trackpad events are stamped with mach_absolute_time
/// (CLOCK_UPTIME_RAW), which stops while the Mac sleeps; Flutter's frame
/// times come from the Dart VM's CLOCK_MONOTONIC_RAW, which keeps counting.
/// Their gap in µs, read back to back.
private func sleepOffsetUs() -> Int {
  let monotonic = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
  let uptime = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
  return (Int(monotonic) - Int(uptime)) / 1000
}
