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
