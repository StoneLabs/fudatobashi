// The dev-tools simulation: some days skipped, the rest finish today's set
// in 1 to 4 runs.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/journey_simulator.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('days are skipped, split into runs and finished by the configured shares', () async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await progress.updateTrainerConfig(progress.trainer.config.copyWith(learningMode: LearningMode.journey));
    final sim = JourneySimulator(progress, seed: 7);
    const days = 150;
    final start = DateTime(2026, 1, 1);
    final runsPerDay = <int>[];
    for (var d = 0; d < days; d++) {
      final date = DateTime(start.year, start.month, start.day + d);
      progress.simulating = true;
      final runs = await sim.realisticDay(date);
      progress.simulating = false;
      runsPerDay.add(runs);
      if (runs > 0) {
        final set = progress.todaySet(date.add(const Duration(hours: SimulationTuning.setCheckHour)));
        expect(set?.done, isTrue, reason: 'day $d: the set is finished');
      }
    }
    final played = runsPerDay.where((r) => r > 0).toList();
    expect(runsPerDay.length - played.length, closeTo(days * SimulationTuning.skipDayShare, days * 0.08));
    for (var n = 1; n <= SimulationTuning.runShares.length; n++) {
      final share = played.where((r) => r == n).length / played.length;
      expect(share, closeTo(SimulationTuning.runShares[n - 1], 0.12), reason: '$n-run days');
    }
    expect(progress.runs.length, played.fold<int>(0, (a, b) => a + b), reason: 'every run is a session');
  });

  test('a seed replays the same days', () async {
    Future<List<int>> run() async {
      final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
      progress.trainer.fuzzing = false;
      final sim = JourneySimulator(progress, seed: 3);
      return [for (var d = 0; d < 10; d++) await sim.realisticDay(DateTime(2026, 1, 1 + d))];
    }

    expect(await run(), await run());
  });
}
