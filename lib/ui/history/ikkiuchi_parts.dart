import '../play/time_format.dart';

/// A time on a 一騎打ち match's page in ms, as the charts and cards take it.
double msOf(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

/// A time as seconds to the hundredth, a minus before one ahead of the
/// deciding sound: 0.88, −0.04.
String secondsOf(Duration d) => '${d.isNegative ? '−' : ''}${formatSeconds(msOf(d).abs())}';

/// [d] to the hundredth of a second, as [secondsOf] shows it, so that a gap
/// between two times shown is the gap of what they show.
Duration shownTime(Duration d) =>
    Duration(milliseconds: (double.parse(formatSeconds(msOf(d))) * Duration.millisecondsPerSecond).round());
