// Tobi's tour of Home: a tap anywhere (scrim, balloon or target) moves the
// tour on and never reaches the screen underneath; Skip still skips, and the
// practice stop still starts the tutorial round.
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
import 'package:fudatobashi/ui/home/home_screen.dart';
import 'package:fudatobashi/ui/manga/tab_bar.dart';
import 'package:fudatobashi/ui/play/play_screen.dart';
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

  Future<Progress> openTour(WidgetTester tester) async {
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
    return p;
  }

  Object? arrowsKey(WidgetTester tester) => tester.widget<TourArrows>(find.byType(TourArrows)).key;

  Future<void> typeOut(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(seconds: 6));
  }

  testWidgets('a tap on an empty scrim area moves the tour on', (tester) async {
    await openTour(tester);
    await typeOut(tester);
    final before = arrowsKey(tester);
    await tester.tapAt(const Offset(5, 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(arrowsKey(tester), isNot(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap over a nav tab moves the tour on without switching tabs', (tester) async {
    await openTour(tester);
    await typeOut(tester);
    final before = arrowsKey(tester);
    await tester.tapAt(tester.getCenter(find.byType(MangaTabBar)) + Offset(tester.getSize(find.byType(MangaTabBar)).width * 0.125, 0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(arrowsKey(tester), isNot(before));
    await tester.tap(find.text(const S('en').tourSkip));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(TourOverlay), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.widget<MangaTabBar>(find.byType(MangaTabBar)).current, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Skip skips the tour rather than moving it on', (tester) async {
    await openTour(tester);
    await typeOut(tester);
    await tester.tap(find.text(const S('en').tourSkip));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(TourOverlay), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap anywhere on the practice stop starts the tutorial round', (tester) async {
    await openTour(tester);
    final steps = TourStep.of(LearningMode.journey, tabsLocked: false);
    for (final step in steps) {
      await typeOut(tester);
      if (step.practice) break;
      await tester.tapAt(const Offset(5, 400));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tapAt(const Offset(5, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(PlayScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

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
