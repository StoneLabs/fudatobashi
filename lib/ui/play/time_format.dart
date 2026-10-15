/// Stands in for a time that is missing or no measurement.
const missingTime = '—';

/// Formats a duration like the original app: mm:ss.mmm
String formatRunTime(Duration d) {
  final ms = d.inMilliseconds;
  final m = ms ~/ 60000;
  final s = (ms ~/ 1000) % 60;
  final r = ms % 1000;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${r.toString().padLeft(3, '0')}';
}

/// Formats a response time like the previous-card chip: truncated (not
/// rounded) to hundredths of a second, e.g. 583 ms -> "0.58".
String formatChipSeconds(double ms) => ((ms / 10).floor() / 100).toStringAsFixed(2);

/// [d] as m:ss, e.g. 1:05.
String formatMinutes(Duration d) {
  final seconds = d.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// [d] as m:ss.d, e.g. 3:58.4; mm:ss.d with [padMinutes].
String formatTenths(Duration d, {bool padMinutes = false}) {
  final tenths = d.inMilliseconds ~/ 100;
  final m = tenths ~/ 600;
  final sec = tenths ~/ 10 % 60;
  return '${padMinutes ? m.toString().padLeft(2, '0') : m}:${sec.toString().padLeft(2, '0')}.${tenths % 10}';
}

/// [ms] as seconds with [digits] decimals, e.g. "2.95".
String formatSeconds(double ms, [int digits = 2]) => (ms / 1000).toStringAsFixed(digits);

/// [ms] as signed seconds, e.g. "+0.43" or "−1.96".
String formatSignedSeconds(double ms, [int digits = 2]) => '${ms < 0 ? '−' : '+'}${formatSeconds(ms.abs(), digits)}';
