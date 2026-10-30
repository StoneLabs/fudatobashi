import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/tab_locks.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/debug/celebration_preview.dart';
import 'package:fudatobashi/ui/shell/tab_chains.dart';
import 'package:fudatobashi/ui/side_trips/dojo_scene.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(
    File('assets/data/poems.json').readAsStringSync(),
  );
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(
    File('assets/data/islands.json').readAsStringSync(),
  );
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Progress> show(
    WidgetTester tester,
    void Function(BuildContext) preview,
  ) async {
    late Progress p;
    await tester.runAsync(
      () async => p = await Progress.open(AppDatabase(NativeDatabase.memory())),
    );
    await tester.pumpWidget(
      ProgressScope(
        progress: p,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => preview(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return p;
  }

  List<Object?> latches(Progress p) => [
    p.sideTripsSeenLocked.toList(),
    p.tabsSeenLocked.toList(),
    p.tabLock(LockedTab.sideTrips) == null,
    p.sideTripsHub()[SideTrip.ankiren].open,
  ];

  testWidgets(
    'the AnkiRen preview opens the gate and leaves the latches alone',
    (tester) async {
      final p = await show(tester, previewAnkirenUnlock);
      final before = latches(p);

      expect(
        tester.widget<DojoScene>(find.byType(DojoScene)).gates[SideTrip.ankiren],
        GateState.opening,
      );
      await tester.pump(const Duration(seconds: 5));

      expect(latches(p), before);
    },
  );

  testWidgets(
    'the tab preview breaks the chains and leaves the latches alone',
    (tester) async {
      final p = await show(tester, previewSideTripsTabUnlock);
      final before = latches(p);

      expect(tester.widget<TabChains>(find.byType(TabChains)).breaking, isTrue);
      await tester.pump(const Duration(seconds: 5));

      expect(latches(p), before);
    },
  );
}
