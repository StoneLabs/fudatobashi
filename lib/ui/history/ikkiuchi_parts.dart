import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/tobi.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';

/// A time on a 一騎打ち match's page in ms, as the charts and cards take it.
double msOf(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

/// A time as seconds to the hundredth, a minus before one ahead of the
/// deciding sound: 0.88, −0.04.
String secondsOf(Duration d) => '${d.isNegative ? '−' : ''}${formatSeconds(msOf(d).abs())}';

/// [d] to the hundredth of a second, as [secondsOf] shows it, so that a gap
/// between two times shown is the gap of what they show.
Duration shownTime(Duration d) =>
    Duration(milliseconds: (double.parse(formatSeconds(msOf(d))) * Duration.millisecondsPerSecond).round());

/// [match]'s takes as a hero's bar: the player's, then Tobi's, and for a
/// match given up the cards left, each part labelled.
({List<BarPart> bar, List<BarLabel> labels}) ikkiuchiTakesBar(S s, IkkiuchiMatchRecord match) {
  final you = match.takenBy(IkkiuchiSide.player), tobi = match.takenBy(IkkiuchiSide.opponent);
  final left = match.playerLeft + match.opponentLeft;
  return (
    bar: [
      BarPart(Palette.land, you, done: true),
      BarPart(Palette.pink, tobi, done: true),
      if (!match.completed) BarPart(Palette.paper, left),
    ],
    labels: match.completed
        ? [BarLabel(s.ikkiuchiTookCount(you)), BarLabel(s.ikkiuchiTobiTookCount(tobi), part: 1, end: true)]
        : [
            BarLabel(s.ikkiuchiTakesBoth(you, tobi), runOn: true),
            BarLabel(s.ikkiuchiLeftCount(left), part: 2, end: true),
          ],
  );
}

/// Tobi as a match's [result] leaves him: shocked by the player's win,
/// fired up by his own, standing by for a match given up.
TobiPose ikkiuchiPoseFor(IkkiuchiResult result) => switch (result) {
      IkkiuchiResult.won => TobiPose.shocked,
      IkkiuchiResult.lost => TobiPose.fired,
      IkkiuchiResult.gaveUp => TobiPose.standard,
    };
