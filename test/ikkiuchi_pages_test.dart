// 一騎打ち's developer pages, Tobi's curves and Tobi's layout, opened from
// Settings' developer section. With RENDER_SCREENS=1 it writes their PNGs to
// build/screens/ikkiuchi/.
import 'dart:io';
import 'dart:math' as math;

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
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_curves_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_graphs.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_layout_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_values.dart';
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

  testWidgets("Tobi's curves: his values and their ranges at the slider's rating, and a graph of each",
      (tester) async {
    final p = await open(tester);
    final take = ikkiuchiValueGroups.expand((g) => g.rows).firstWhere((v) => v.name == 'take time');
    for (final rating in [0.0, 1700.0, 3600.0]) {
      await show(tester, p, IkkiuchiCurvesPage(rating: rating));
      expect(tester.takeException(), isNull);
      final r = rating.round();
      expect(find.text('rating $r'), findsOneWidget);
      expect(find.text('at $r'), findsOneWidget);
      expect(find.text(take.unit.format(IkkiuchiTobi(rating).takeMs)), findsWidgets, reason: 'take time at $r');
      for (final s in IkkiuchiToolsTuning.sigmas) {
        expect(find.text(take.matchRangeText(rating, s)), findsWidgets, reason: 'take time per match, $s sd');
        expect(find.text(take.cardRangeText(rating, s)), findsWidgets, reason: 'take time per card, $s sd');
      }
      expect(find.text(ikkiuchiNoRange), findsWidgets, reason: 'fixed values');
      await captureDown(tester, 'ikkiuchi/curves_$r');
      expect(tester.takeException(), isNull);
      expect(find.byType(IkkiuchiSharesGraph), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's layout: his side by rating, the full layout, and the controls", (tester) async {
    final p = await open(tester);
    const perSide = IkkiuchiToolsTuning.perSideStart;
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

    // The field's sideways scrolling.
    ScrollPosition field() => tester
        .state<ScrollableState>(
            find.ancestor(of: find.byType(FieldWordCard).first, matching: find.byType(Scrollable)).first)
        .position;

    for (final rating in [0.0, 1700.0, 2600.0, 3000.0, 3600.0]) {
      final r = rating.round();
      final deck = [for (final poem in poems.all) poem.id]..shuffle(math.Random(3));
      final homes = IkkiuchiLayout.ofPoems().generate(
          rating: rating, own: deck.sublist(0, perSide), others: deck.sublist(perSide, 2 * perSide), rows: 3, seed: 3);

      await show(tester, p, IkkiuchiLayoutPage(rating: rating, seed: 3));
      expect(tester.takeException(), isNull);
      expect(find.text('seed 3'), findsOneWidget);
      expect(find.text('sound grouping ${homes.soundGrouped ? 'on' : 'off'}'), findsOneWidget, reason: '$r');
      expect(find.text('友札 together ${homes.tomofudaGrouped ? 'on' : 'off'}'), findsOneWidget, reason: '$r');
      await captureDown(tester, 'ikkiuchi/layout_$r');
      expect(await fieldCards(), hasLength(perSide), reason: 'his side alone');

      await show(tester, p, IkkiuchiLayoutPage(rating: rating, seed: 3, full: true));
      expect(tester.takeException(), isNull);
      await captureDown(tester, 'ikkiuchi/layout_${r}_full');
      expect(await fieldCards(), hasLength(2 * perSide), reason: 'every card dealt');
      expect(field().maxScrollExtent, 0, reason: 'the full layout fits the phone at $r');
    }

    await show(tester, p, const IkkiuchiLayoutPage(rating: 1600, seed: 3));
    await tester.tap(find.text('Full teiichi'));
    await tester.pump();
    expect(await fieldCards(), hasLength(2 * perSide), reason: 'Full teiichi shows every card dealt');

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
