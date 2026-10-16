// Tobi's tour of Home: on a stop with a spotlit target, a tap on his balloon
// ("tap here to continue") moves the tour on, as the target does; the exam
// intro's balloon still just closes it.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/tour_strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/tour/tour_anchor.dart';
import 'package:fudatobashi/ui/tour/tour_arrows.dart';
import 'package:fudatobashi/ui/tour/tour_overlay.dart';
import 'package:fudatobashi/ui/tour/tour_steps.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets("a tap on Tobi's balloon moves a stop with a target on, like the target", (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: false));
      await p.setLearningMode(LearningMode.journey);
    });
    for (final id in fudaSets['initial:${archipelago.islands.first.name}'].poemIds) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FudatobashiApp(progress: p));
    await tester.pump(const Duration(milliseconds: 500));
    const s = S('en');
    final steps = TourStep.of(LearningMode.journey, tabsLocked: false);
    Object? arrows() => tester.widget<TourArrows>(find.byType(TourArrows)).key;

    for (final (i, step) in steps.take(5).indexed) {
      await tester.pump(const Duration(milliseconds: 650));
      if (step.spot != null) {
        expect(find.byWidgetPredicate((w) => w is TourAnchor && w.spot == step.spot), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 6));
      final before = arrows();
      await tester.tap(find.text(s.tourTapHint));
      await tester.pump(const Duration(milliseconds: 50));
      expect(arrows(), isNot(before), reason: 'stop $i (${step.spot?.name ?? 'no target'}) moved on');
    }
    expect(find.byType(TourOverlay), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
