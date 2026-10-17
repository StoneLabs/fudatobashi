// MatchTimerAlerts on a fake platform: when the background service is told
// the timer ends, and that pause, stop and the end let go.
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/state/match_timer_alerts.dart';

class _FakePlatform implements MatchTimerPlatform {
  final calls = <String>[];
  DateTime? endsAt, releaseAt;

  @override
  void keepScreenOn(bool on) => calls.add(on ? 'screen on' : 'screen off');

  @override
  void keepAlive({required DateTime endsAt, required DateTime releaseAt, required MatchTimerNotice notice}) {
    calls.add('keep alive');
    this.endsAt = endsAt;
    this.releaseAt = releaseAt;
  }

  @override
  void letGo() => calls.add('let go');

  @override
  Future<bool> needsNotificationPermission() async => false;

  @override
  Future<void> askNotificationPermission() async {}
}

void main() {
  const notice = (title: 'Match timer', text: 'Counting down.', channel: 'Match timer');
  final start = DateTime(2026, 10, 18, 9);
  late _FakePlatform platform;
  late DateTime now;
  late MatchTimerAlerts alerts;

  setUp(() {
    platform = _FakePlatform();
    now = start;
    alerts = MatchTimerAlerts(platform: platform, now: () => now);
  });

  test('run keeps the screen on and the app alive until the end, plus the linger', () {
    alerts.run(const Duration(minutes: 15), notice);
    expect(platform.calls, ['screen on', 'keep alive']);
    expect(platform.endsAt, start.add(const Duration(minutes: 15)));
    expect(platform.releaseAt, start.add(const Duration(minutes: 15) + MatchTimerTuning.backgroundLinger));
  });

  test('pause lets go; resume reschedules from the time left', () {
    alerts.run(const Duration(minutes: 15), notice);
    now = start.add(const Duration(minutes: 4));
    alerts.release();
    expect(platform.calls, ['screen on', 'keep alive', 'screen off', 'let go']);

    now = start.add(const Duration(minutes: 9));
    alerts.run(const Duration(minutes: 11), notice);
    expect(platform.endsAt, start.add(const Duration(minutes: 20)));
  });

  test('stop after pause, or with nothing running, does nothing more', () {
    alerts.release();
    expect(platform.calls, isEmpty);
    alerts.run(const Duration(minutes: 2), notice);
    alerts.release();
    alerts.release();
    expect(platform.calls, ['screen on', 'keep alive', 'screen off', 'let go']);
  });

  test('the end lets the screen sleep but leaves the service to finish by itself', () {
    alerts.run(const Duration(minutes: 1), notice);
    alerts.finish();
    alerts.release();
    expect(platform.calls, ['screen on', 'keep alive', 'screen off']);
  });
}
