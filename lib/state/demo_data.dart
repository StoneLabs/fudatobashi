import '../config/config.dart';
import '../domain/synthetic_learner.dart';
import '../domain/trainer.dart';
import 'journey_simulator.dart';
import 'progress.dart';

/// Reports simulated-day progress while [seedDemoData] runs: the 1-indexed
/// day being simulated (oldest first), the total day count, and how far
/// through that day's runs it is (0..1).
typedef SeedProgress = void Function(int day, int totalDays, double fraction);

/// Replaces all progress with a journey player's last [days] days: training
/// rounds through the real path (unlocks, islands, FSRS, rating) at
/// realistic days (see [JourneySimulator.realisticDay]), plus the odd free-play run, so celebrations, due
/// cards and Stats have data during development. [learner], [pace], [days]
/// and [seed] default to the debug page's own Simulation defaults, so a
/// seeded device (and this file's own test) reliably reaches unlocks, due
/// cards and a completed island, not just "most of the time"; the
/// Simulation page instead passes its last run's own choices, so the seeded
/// progress matches the charts shown above its "Seed demo data" button.
Future<void> seedDemoData(
  Progress progress, {
  SeedProgress? onProgress,
  LearnerKind learner = LearnerKind.average,
  LearningPace pace = PaceTuning.defaultPace,
  int days = DemoDataTuning.days,
  int seed = DemoDataTuning.seed,
}) async {
  progress.simulating = true;
  try {
    await progress.resetProgress();
    await progress.updateTrainerConfig(
      progress.trainer.config.copyWith(learningMode: LearningMode.journey, pace: pace, reverseMode: ReverseMode.afterMastery),
    );
    final sim = JourneySimulator(progress, seed: seed, learner: learner);
    progress.trainer.fuzzing = false;
    await _simulate(progress, sim, DateTime.now(), pace, days, onProgress);
  } finally {
    progress.trainer.fuzzing = true;
    progress.simulating = false;
  }
  await progress.refreshToday();
  onProgress?.call(days, days, 1);
}

/// Replaces all progress with an all-known player's last [days] days:
/// [DemoDataTuning.rankedTrainingRounds] training rounds a day and a ranked
/// run every [DemoDataTuning.rankedEvery] days, through the real path, so
/// the rating has a history (Stats' rank page, History's ranked runs).
Future<void> seedRankedDemoData(
  Progress progress, {
  SeedProgress? onProgress,
  LearnerKind learner = LearnerKind.average,
  int days = DemoDataTuning.days,
  int seed = DemoDataTuning.seed,
}) async {
  progress.simulating = true;
  try {
    await progress.resetProgress();
    await progress.updateTrainerConfig(
      progress.trainer.config.copyWith(learningMode: LearningMode.allKnown, reverseMode: ReverseMode.mixed),
    );
    final sim = JourneySimulator(progress, seed: seed, learner: learner);
    progress.trainer.fuzzing = false;
    final today = DateTime.now();
    for (var d = 0; d < days; d++) {
      final date = DateTime(today.year, today.month, today.day - days + d);
      onProgress?.call(d + 1, days, 0);
      await sim.day(date, rounds: DemoDataTuning.rankedTrainingRounds);
      if (d % DemoDataTuning.rankedEvery == DemoDataTuning.rankedEvery - 1) {
        await sim.rankedRound(DateTime(date.year, date.month, date.day, SyntheticLearnerTuning.lastRoundHour));
      }
    }
  } finally {
    progress.trainer.fuzzing = true;
    progress.simulating = false;
  }
  onProgress?.call(days, days, 1);
}

Future<void> _simulate(
  Progress progress,
  JourneySimulator sim,
  DateTime today,
  LearningPace pace,
  int days,
  SeedProgress? onProgress,
) async {
  for (var d = 0; d < days; d++) {
    final date = DateTime(today.year, today.month, today.day - days + d);
    onProgress?.call(d + 1, days, 0);
    final runs = await sim.realisticDay(date, onRun: (run, done, cards) {
      onProgress?.call(d + 1, days, (run + done / cards) / SimulationTuning.runShares.length);
    });
    if (runs > 0 && d % DemoDataTuning.freeRunEvery == DemoDataTuning.freeRunEvery - 1) {
      await sim.freeRound(
        DateTime(date.year, date.month, date.day, SyntheticLearnerTuning.lastRoundHour),
        DemoDataTuning.freeCards,
      );
    }
  }
}
