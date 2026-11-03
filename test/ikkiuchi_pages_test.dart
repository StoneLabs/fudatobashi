// 一騎打ち's developer pages, Tobi's curves and Tobi's layout, opened from
// Settings' developer section. With RENDER_SCREENS=1 it writes their PNGs to
// build/screens/ikkiuchi/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_curves_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_layout_page.dart';
import 'package:fudatobashi/ui/history/ankiren_field_tab.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await loadRenderMonoFont();
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  // A player in developer mode who reads kimariji in hiragana.
  Future<Progress> open(WidgetTester tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(
          language: 'en',
          languagePicked: true,
          toured: true,
          debugMode: true,
          kimarijiScript: KimarijiScript.hiragana));
    });
    return p;
  }

  // [page] afresh, its state and scrolling new.
  Future<void> show(WidgetTester tester, Progress p, Widget page) async {
    useScreen(tester, usersPhone);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildMangaTheme(), home: page),
      ),
    ));
    await tester.pump();
  }

  // Scrolls the page's list down a screen at a time, rendering each stop as
  // [name]_1, _2, … until its end.
  Future<void> captureDown(WidgetTester tester, String name) async {
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var i = 1;; i++) {
      await captureScreen(tester, '${name}_$i');
      if (list.pixels >= list.maxScrollExtent) break;
      list.jumpTo((list.pixels + list.viewportDimension * 0.9).clamp(0, list.maxScrollExtent));
      await tester.pump();
    }
  }

  testWidgets("Settings' developer section opens Tobi's curves and his layout", (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    final p = await open(tester);
    await tester.binding.setSurfaceSize(usersPhone.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        ProgressScope(progress: p, child: MaterialApp(theme: buildMangaTheme(), home: const SettingsScreen())));
    for (final (label, page) in [
      ("Comp - Tobi's curves", IkkiuchiCurvesPage),
      ("Comp - Tobi's layout", IkkiuchiLayoutPage),
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      expect(find.byType(page), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(page))).pop();
      await tester.pump();
      await tester.pump(Motion.route * 2);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's curves: his values at the slider's rating and a graph of each", (tester) async {
    final p = await open(tester);
    for (final rating in [0.0, 1600.0, 3600.0]) {
      await show(tester, p, IkkiuchiCurvesPage(rating: rating));
      expect(tester.takeException(), isNull);
      final r = rating.round();
      expect(find.text('rating $r'), findsOneWidget);
      expect(find.text('at $r'), findsOneWidget);
      final takeMs = IkkiuchiTobi(rating).takeMs;
      final take = takeMs >= 1000 ? '${(takeMs / 1000).toStringAsFixed(2)} s' : '${takeMs.round()} ms';
      expect(find.text(take), findsWidgets, reason: 'take time at $r');
      await captureDown(tester, 'ikkiuchi/curves_$r');
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Layout grouping: chance a first-sound group stays together'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's layout: his side by rating, the player's cards' homes, and the controls", (tester) async {
    final p = await open(tester);
    Finder page() => find.byType(Scrollable).first;
    Future<void> toTop() async {
      tester.state<ScrollableState>(page()).position.jumpTo(0);
      await tester.pump();
    }

    // The cards on the page's field, scrolled into sight with the row
    // counts under it.
    Future<Set<int>> fieldCards() async {
      await toTop();
      await tester.scrollUntilVisible(find.text('homes L'), 200, scrollable: page());
      return tester.widgetList<FieldWordCard>(find.byType(FieldWordCard)).map((c) => c.poemId).toSet();
    }

    for (final rating in [0.0, 1600.0, 2800.0, 3600.0]) {
      await show(tester, p, IkkiuchiLayoutPage(rating: rating, seed: 3));
      expect(tester.takeException(), isNull);
      expect(find.text('seed 3'), findsOneWidget);
      await captureDown(tester, 'ikkiuchi/layout_${rating.round()}');
      expect(await fieldCards(), hasLength(IkkiuchiToolsTuning.perSideStart), reason: 'his side alone');
      expect(find.text(IkkiuchiTobi(rating).grouping.toStringAsFixed(2)), findsOneWidget);
    }

    await show(tester, p, const IkkiuchiLayoutPage(rating: 1600, seed: 3, showAway: true));
    await captureScreen(tester, 'ikkiuchi/layout_1600_homes');
    expect(await fieldCards(), hasLength(2 * IkkiuchiToolsTuning.perSideStart), reason: 'every card dealt');
    await toTop();
    final fieldScroll = find.ancestor(of: find.byType(FieldWordCard).first, matching: find.byType(Scrollable)).first;
    final field = tester.state<ScrollableState>(fieldScroll).position;
    field.jumpTo(field.maxScrollExtent);
    await tester.pump();
    await captureScreen(tester, 'ikkiuchi/layout_1600_homes_right');

    await show(tester, p, const IkkiuchiLayoutPage(rating: 1600, seed: 3));
    Future<void> tapChip(String label) async {
      await toTop();
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
    }

    ChoiceChip rows(int n) => tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '$n'));
    expect(rows(1).onSelected, isNull, reason: '25 cards are too many for 1 row');
    expect(rows(2).onSelected, isNull, reason: '25 cards are too many for 2 rows');
    await tapChip('${IkkiuchiLayoutTuning.oneRowUpTo}');
    expect(await fieldCards(), hasLength(IkkiuchiLayoutTuning.oneRowUpTo));
    await tapChip('1');
    expect(rows(1).selected, isTrue);
    await captureScreen(tester, 'ikkiuchi/layout_1600_one_row');
    await tapChip('25');
    expect(rows(IkkiuchiLayoutTuning.rows).selected, isTrue, reason: 'back to the rows 25 cards may take');
    await tester.tap(find.text('Reroll'));
    await tester.pump();
    expect(find.text('seed 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
