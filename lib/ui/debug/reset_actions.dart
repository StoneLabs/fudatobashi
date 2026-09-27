import 'package:flutter/material.dart';

import '../../state/scope.dart';

/// Confirms, then deletes every run, attempt, FSRS state and rating.
/// Settings (including dev mode) are kept.
Future<void> confirmResetProgress(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Reset all progress?'),
      content: const Text('Deletes every run, attempt, FSRS state and the rating. Settings stay.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
      ],
    ),
  );
  if (ok == true) await progress.resetProgress();
}

/// Confirms, then shows the first-launch journey / all-known choice again.
Future<void> confirmResetOnboarding(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Reset onboarding?'),
      content: const Text('Shows the first-launch journey / all-known choice again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
      ],
    ),
  );
  if (ok == true) await progress.updateSettings(progress.settings.copyWith(onboarded: false));
}
