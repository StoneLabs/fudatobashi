// Home's journey map follows the progress a simulation writes while Home
// is open, the way Stats does.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/journey_state.dart';
import 'package:fudatobashi/ui/islands/island_map.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Home shows the islands a simulation unlocked while it was open', (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.journey);
    });
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FudatobashiApp(progress: p));
    await tester.pump(const Duration(milliseconds: 500));
    final before = tester.widget<IslandMap>(find.byType(IslandMap)).boat;

    await tester.runAsync(() => seedDemoData(p));
    await tester.pump(const Duration(milliseconds: 500));

    final journey = JourneyState.of(p);
    expect(journey.current, greaterThan(0), reason: 'the simulation moved the journey on');
    final map = tester.widget<IslandMap>(find.byType(IslandMap));
    expect(map.boat, journey.boat);
    expect(map.boat, isNot(before));
    expect(find.textContaining('${journey.current + 1}'), findsWidgets);
  });

  test('with every card unlocked the boat is at the last island, as Stats shows', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await seedDemoData(p, days: 30);
    expect(p.islands.every((i) => i.unlocked == i.total), isTrue);
    expect(JourneyState.of(p).current, archipelago.islands.length - 1);
  });
}
