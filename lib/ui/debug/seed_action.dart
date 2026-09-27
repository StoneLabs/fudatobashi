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
  if (ok != true) return;
  if (context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 64,
          child: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Seeding…'),
          ]),
        ),
      ),
    );
  }
  await seedDemoData(progress);
  if (context.mounted) Navigator.of(context).pop();
}
