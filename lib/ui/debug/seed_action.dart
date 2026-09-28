import 'dart:async';

import 'package:flutter/material.dart';

import '../../state/demo_data.dart';
import '../../state/scope.dart';

/// Confirms, then replaces all progress with synthetic history (several days
/// of training and free-play runs) through the real recording path.
Future<void> confirmSeedDemoData(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Seed demo data?'),
      content: const Text('Replaces all progress with several days of synthetic training and free-play runs.'),
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
  await seedDemoData(
    progress,
    onProgress: (day, totalDays, fraction) => status.value = 'Seeding…\nDay $day/$totalDays: ${(fraction * 100).round()}%',
  );
  status.dispose();
  if (context.mounted) Navigator.of(context).pop();
}
