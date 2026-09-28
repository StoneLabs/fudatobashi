import 'dart:math' as math;

import '../config/config.dart';
import '../domain/trainer.dart';
import 'journey_simulator.dart';
import 'progress.dart';

/// Reports simulated-day progress while [seedDemoData] runs: the 1-indexed
/// day being simulated (oldest first), the total day count, and how far
/// through that day's runs it is (0..1).
typedef SeedProgress = void Function(int day, int totalDays, double fraction);

/// Replaces all progress with a journey player's last [DemoDataTuning.days]
/// days: training rounds through the real path (unlocks, islands, FSRS,
/// rating) plus the odd free-play run, so celebrations, due cards and Stats
/// have data during development.
Future<void> seedDemoData(Progress progress, {SeedProgress? onProgress}) async {
  await progress.resetProgress();
  await progress.updateTrainerConfig(
    progress.trainer.config.copyWith(learningMode: LearningMode.journey, reverseMode: ReverseMode.afterMastery),
  );
  final seed = DateTime.now().millisecondsSinceEpoch;
  final sim = JourneySimulator(progress, seed: seed);
  final rng = math.Random(seed);
  final today = DateTime.now();
  const total = DemoDataTuning.days;
  for (var d = 0; d < total; d++) {
    final rounds =
        DemoDataTuning.minRoundsPerDay + rng.nextInt(DemoDataTuning.maxRoundsPerDay - DemoDataTuning.minRoundsPerDay + 1);
    final freeRounds = d % DemoDataTuning.freeRunEvery == DemoDataTuning.freeRunEvery - 1 ? 1 : 0;
    final runs = rounds + freeRounds;
    onProgress?.call(d + 1, total, 0);
    await sim.day(
      DateTime(today.year, today.month, today.day - total + d),
      rounds: rounds,
      freeRounds: freeRounds,
      freeCards: DemoDataTuning.freeCards,
      onRound: (round, done, cards) => onProgress?.call(d + 1, total, (round + done / cards) / runs),
    );
  }
  onProgress?.call(total, total, 1);
}
