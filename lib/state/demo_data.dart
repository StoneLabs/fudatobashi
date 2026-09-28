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
/// [pace]'s daily routine, plus the odd free-play run, so celebrations, due
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
  await progress.resetProgress();
  await progress.updateTrainerConfig(
    progress.trainer.config.copyWith(learningMode: LearningMode.journey, pace: pace, reverseMode: ReverseMode.afterMastery),
  );
  final sim = JourneySimulator(progress, seed: seed, learner: learner);
  final today = DateTime.now();
  for (var d = 0; d < days; d++) {
    final rounds = pace.profile.dailyRounds;
    final freeRounds = d % DemoDataTuning.freeRunEvery == DemoDataTuning.freeRunEvery - 1 ? 1 : 0;
    final runs = rounds + freeRounds;
    onProgress?.call(d + 1, days, 0);
    await sim.day(
      DateTime(today.year, today.month, today.day - days + d),
      rounds: rounds,
      freeRounds: freeRounds,
      freeCards: DemoDataTuning.freeCards,
      onRound: (round, done, cards) => onProgress?.call(d + 1, days, (round + done / cards) / runs),
    );
  }
  onProgress?.call(days, days, 1);
}
