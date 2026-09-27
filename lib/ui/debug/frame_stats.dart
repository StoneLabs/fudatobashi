import 'package:flutter/scheduler.dart';

/// Collects recent frame timings for the debug page.
class FrameStats {
  FrameStats._();
  static final instance = FrameStats._();

  final _timings = <FrameTiming>[];
  bool _listening = false;

  void start() {
    if (_listening) return;
    _listening = true;
    SchedulerBinding.instance.addTimingsCallback((t) {
      _timings.addAll(t);
      if (_timings.length > 600) _timings.removeRange(0, _timings.length - 600);
    });
  }

  List<FrameTiming> get timings => List.unmodifiable(_timings);

  /// Summary over the recorded frames: count, average and worst build/raster
  /// times, and the share of frames over the budget of [targetHz].
  ({int frames, double avgBuildMs, double avgRasterMs, double worstTotalMs, double jankPct}) summary(
      {double targetHz = 120}) {
    if (_timings.isEmpty) return (frames: 0, avgBuildMs: 0, avgRasterMs: 0, worstTotalMs: 0, jankPct: 0);
    final budget = 1000 / targetHz;
    var b = 0.0, r = 0.0, worst = 0.0;
    var jank = 0;
    for (final t in _timings) {
      final bm = t.buildDuration.inMicroseconds / 1000;
      final rm = t.rasterDuration.inMicroseconds / 1000;
      b += bm;
      r += rm;
      final total = t.totalSpan.inMicroseconds / 1000;
      if (total > worst) worst = total;
      if (bm > budget || rm > budget) jank++;
    }
    final n = _timings.length;
    return (frames: n, avgBuildMs: b / n, avgRasterMs: r / n, worstTotalMs: worst, jankPct: 100 * jank / n);
  }
}
