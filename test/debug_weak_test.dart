import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/debug/debug_page.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('debug: the Weak tab shows the pool, the drill and the totals', (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await seedRankedDemoData(p, days: 6);
    });
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProgressScope(progress: p, child: const MaterialApp(home: DebugPage())));
    await tester.ensureVisible(find.text('Weak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weak'));
    await tester.pumpAndSettle();
    expect(find.text('Weak drill breakdown'), findsOneWidget);
    expect(find.text('Re-roll'), findsOneWidget);
    expect(find.text('Totals'), findsOneWidget);
    expect(find.text('Chosen drill'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pool'), 500, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).last);
    expect(find.text('Pool'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
