import 'dart:math' as math;

import '../../config/config.dart';
import '../../domain/ranked.dart';

/// Mean and standard deviation, in milliseconds.
typedef MeanSd = ({double mean, double sd});

/// Tobi's card-to-card times, sampled from `TobiPace.draw`, one card's time
/// over every card of every draw.
abstract final class TobiExamStats {
  /// Computed once, on first use.
  static final MeanSd perCard = sample();

  static MeanSd sample({int draws = DebugTuning.tobiSamples, int seed = DebugTuning.tobiSeed}) {
    final rng = math.Random(seed);
    final cards = <double>[];
    for (var i = 0; i < draws; i++) {
      final pace = TobiPace.draw(rng);
      for (var c = 0; c < pace.cardEnds.length; c++) {
        cards.add((pace.cardEnds[c] - pace.startOf(c)).inMicroseconds / 1000);
      }
    }
    final mean = cards.fold<double>(0, (a, x) => a + x) / cards.length;
    final variance = cards.fold<double>(0, (a, x) => a + (x - mean) * (x - mean)) / cards.length;
    return (mean: mean, sd: math.sqrt(variance));
  }
}
