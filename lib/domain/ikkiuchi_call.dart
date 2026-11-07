import '../config/config.dart';

/// A card's call in a match (一騎打ち) as the reader reads it: the [sounds]
/// of its kimariji, one kana each, and [onsets], the ms into the call at
/// which each is heard. A recording of the reader gives when its sounds
/// start; the sounds it doesn't time, or all of them without one, follow
/// at the even pace of [IkkiuchiReaderTuning].
class IkkiuchiCall {
  IkkiuchiCall(this.card, List<String> sounds, {List<double> recorded = const []})
      : sounds = List.unmodifiable(sounds),
        onsets = List.unmodifiable(_timed(sounds.length, recorded));

  final int card;
  final List<String> sounds;
  final List<double> onsets;

  /// How many of the sounds are heard [ms] into the call.
  int heardAt(double ms) {
    var n = 0;
    while (n < onsets.length && onsets[n] <= ms) {
      n++;
    }
    return n;
  }

  /// When the last sound, the one that decides the card, is heard.
  double get decidedAt => onsets.isEmpty ? 0 : onsets.last;

  static List<double> _timed(int count, List<double> recorded) {
    final lead = _ms(IkkiuchiReaderTuning.lead), step = _ms(IkkiuchiReaderTuning.perSound);
    return [
      for (var i = 0; i < count; i++)
        if (i < recorded.length)
          recorded[i]
        else if (recorded.isEmpty)
          lead + i * step
        else
          recorded.last + (i - recorded.length + 1) * step,
    ];
  }

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
}
