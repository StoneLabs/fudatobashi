import '../config/config.dart';

/// One practice day: from the day start hour (local time) to the next one,
/// named by the calendar [date] it began on. Practice after midnight but
/// before the day start counts for the day before.
class DayWindow {
  const DayWindow(this.date, this.start, this.end);

  /// The day's date, as a UTC midnight.
  final DateTime date;
  final DateTime start, end;

  /// The day [t] falls in, with days starting at [hour].
  factory DayWindow.at(DateTime t, int hour) {
    final l = t.toLocal();
    var start = DateTime(l.year, l.month, l.day, hour);
    if (start.isAfter(l)) start = DateTime(l.year, l.month, l.day - 1, hour);
    return DayWindow(
      DateTime.utc(start.year, start.month, start.day),
      start,
      DateTime(start.year, start.month, start.day + 1, hour),
    );
  }

  /// The day [now] falls in, following [previous] (which ended at or before
  /// [now]). A day start moved later never cuts into [previous], and the
  /// day after it lasts at least [TodaySetTuning.shortestDay], so a change
  /// takes effect from the next day start and no day is lost or repeated.
  factory DayWindow.after(DayWindow previous, DateTime now, int hour) {
    final plain = DayWindow.at(now, hour);
    if (!plain.start.isBefore(previous.end)) return plain;
    final start = previous.end;
    var end = plain.end;
    if (end.difference(start) < TodaySetTuning.shortestDay) {
      end = DateTime(end.year, end.month, end.day + 1, end.hour);
    }
    final last = DateTime(end.year, end.month, end.day - 1);
    return DayWindow(DateTime.utc(last.year, last.month, last.day), start, end);
  }

  /// [date] as yyyymmdd, the day's stored id.
  int get number => numberOf(date);

  static int numberOf(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  static DateTime dateOf(int number) => DateTime.utc(number ~/ 10000, number ~/ 100 % 100, number % 100);

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DayWindow && other.date == date && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(date, start, end);

  @override
  String toString() => 'DayWindow($number, $start – $end)';
}
