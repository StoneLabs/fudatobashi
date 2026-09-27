import 'dart:math' as math;

import '../config/config.dart';
import '../domain/play_session.dart';
import 'play_config.dart';
import 'progress.dart';

/// Generates several days of synthetic training and free-play history
/// through the real [Progress.recordRun] path (misses, gradual improvement),
/// so Stats and History have data to show during development. Wipes existing
/// progress first.
Future<void> seedDemoData(Progress progress) async {
  await progress.resetProgress();
  final rng = math.Random();
  final today = DateTime.now();

  for (var day = DemoDataTuning.days - 1; day >= 0; day--) {
    final t = 1 - day / (DemoDataTuning.days - 1);
    final targetMs = _lerp(DemoDataTuning.startTargetMs, DemoDataTuning.endTargetMs, t);
    final missRate = _lerp(DemoDataTuning.startMissRate, DemoDataTuning.endMissRate, t);
    final dayStart = DateTime(today.year, today.month, today.day).subtract(Duration(days: day));
    var wall = dayStart.add(Duration(hours: 8 + rng.nextInt(11), minutes: rng.nextInt(60)));

    final sessionCount = DemoDataTuning.minSessionsPerDay +
        rng.nextInt(DemoDataTuning.maxSessionsPerDay - DemoDataTuning.minSessionsPerDay + 1);
    for (var s = 0; s < sessionCount; s++) {
      final planned = await progress.planTraining(rng: rng);
      final cards = planned.cards.take(DemoDataTuning.trainingCards).toList();
      if (cards.isNotEmpty) {
        wall = await _playSimulated(
          progress,
          cards,
          wall,
          const PlayConfig(mode: PlayMode.training),
          targetMs,
          missRate,
          rng,
        );
      }
      wall = wall.add(const Duration(hours: 1));
    }

    if (day % DemoDataTuning.freeRunEvery == 0) {
      const config = PlayConfig(mode: PlayMode.free);
      final deck = progress.freeDeck(config, rng: rng).take(DemoDataTuning.freeCards).toList();
      if (deck.isNotEmpty) {
        await _playSimulated(progress, deck, wall, config, targetMs * 1.1, missRate, rng);
      }
    }
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);

/// Plays [cards] through a real [PlaySession] with plausible timings, then
/// records it starting at [startedAt]. Returns the wall-clock time reached.
Future<DateTime> _playSimulated(
  Progress progress,
  List<CardRef> cards,
  DateTime startedAt,
  PlayConfig config,
  double targetMs,
  double missRate,
  math.Random rng,
) async {
  final session = PlaySession(cards);
  var engine = Duration.zero;
  var wall = startedAt;
  for (var i = 0; i < cards.length; i++) {
    session.revealed(engine);
    final miss = rng.nextDouble() < missRate;
    final spread =
        DemoDataTuning.sampleSpreadLow + rng.nextDouble() * (DemoDataTuning.sampleSpreadHigh - DemoDataTuning.sampleSpreadLow);
    final ms = math.max(150.0, targetMs * spread);
    final responseTs = engine + Duration(microseconds: (ms * 1000).round());
    wall = wall.add(Duration(milliseconds: ms.round())).add(DemoDataTuning.cardGap);
    session.commit(
      responseTs: responseTs,
      commitTs: responseTs + const Duration(milliseconds: 80),
      outcome: miss ? Outcome.dontKnow : Outcome.known,
      at: wall,
    );
    engine = responseTs + DemoDataTuning.betweenCommitAndNextReveal;
  }
  await progress.recordRun(session, config, startedAt);
  return wall;
}
