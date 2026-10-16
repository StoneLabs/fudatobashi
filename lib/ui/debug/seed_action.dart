import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/learning_pace.dart';
import '../../domain/synthetic_learner.dart';
import '../../state/demo_data.dart';
import '../../state/scope.dart';

/// Confirms, then replaces all progress with synthetic history through the
/// real recording path: the Simulation page's last journey run, or with
/// [ranked] an all-known player's ranked, Weak cards and free-play runs.
Future<void> confirmSeedDemoData(
  BuildContext context, {
  required LearnerKind learner,
  required LearningPace pace,
  required int days,
  bool ranked = false,
}) async {
  final progress = ProgressScope.read(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(ranked ? 'Seed ranked demo data?' : 'Seed demo data?'),
      content: Text(ranked
          ? 'Replaces all progress with $days days of an all-known player (${learner.name} learner): '
              '1 to 3 ranked runs on most days, with some Weak cards and free-play runs.'
          : 'Replaces all progress with the $days-day journey shown above (${learner.name} learner, '
              '${pace.name} pace): training rounds, unlocks, islands and a few free-play runs.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Seed')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final status = ValueNotifier('Seeding…');
  // Not awaited: this dialog is only dismissed by the `pop()` below, once
  // seeding actually finishes. Awaiting it here would deadlock (nothing else
  // would ever pop it), which is exactly what used to happen.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: SizedBox(
        height: 64,
        child: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: ValueListenableBuilder(valueListenable: status, builder: (_, text, _) => Text(text))),
        ]),
      ),
    ),
  ));
  void onProgress(int day, int totalDays, double fraction) =>
      status.value = 'Seeding…\nDay $day/$totalDays: ${(fraction * 100).round()}%';
  if (ranked) {
    await seedRankedDemoData(progress, learner: learner, days: days, onProgress: onProgress);
  } else {
    await seedDemoData(progress, learner: learner, pace: pace, days: days, onProgress: onProgress);
  }
  status.dispose();
  if (context.mounted) Navigator.of(context).pop();
}
