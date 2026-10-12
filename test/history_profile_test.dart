import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/side_trips.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/profile/profile_screen.dart';
import 'package:fudatobashi/ui/rank/rank_badges.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

const _phone = Size(384, 832);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['RENDER_SCREENS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// History with side-trip games beside the runs, and My Profile's side-trip
/// ranks, on the user's phone at a large font scale.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  final day = DateTime(2026, 10, 1, 9);

  // An all-known player with every tab open.
  Future<Progress> open(WidgetTester tester, {required bool ja}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.allKnown);
    });
    return p;
  }

  PlaySession swipes(List<int> ids) {
    final session = PlaySession([for (final id in ids) CardRef(id)]);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += const Duration(milliseconds: 700);
      session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  // The user's phone: 384 × 832 at 2.8125 px per dp, with a 28 dp status bar
  // and a 48 dp navigation bar.
  void onPhone(WidgetTester tester, {required double fontScale}) {
    const dpr = 2.8125;
    const bars = FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr);
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = _phone * dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('History lists runs and 暗記練 games newest first, and its filter narrows them ($lang)', (tester) async {
      final s = S(ja ? 'ja' : 'en');
      final p = await open(tester, ja: ja);
      late AnkirenReport ranked, custom;
      await tester.runAsync(() async {
        await p.recordRun(swipes([1, 2, 3]), const PlayConfig(mode: PlayMode.training), day);
        await p.recordRun(swipes([4, 5]), const FreePracticeSetup().config, day.add(const Duration(hours: 1)));
        ranked = await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true), wrongAt: {1}),
            startedAt: day.add(const Duration(hours: 2)));
        custom = await p.recordAnkiren(
            playAnkiren(const AnkirenSetup.custom(perSide: 3, memorise: Duration(seconds: 30)), endAfter: 4),
            startedAt: day.add(const Duration(hours: 3)));
      });
      onPhone(tester, fontScale: 1.3);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.history)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      Finder tags() => find.descendant(of: find.byType(ListView), matching: find.byType(InkTag));
      Finder chip(String label) => find.descendant(of: find.byType(Wrap).first, matching: find.text(label));
      Future<void> filter(String label) async {
        await tester.tap(chip(label));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      final rankedTag = '暗記練 · ${s.sideTripRankedLevel(0)}';
      final customTag = '暗記練 · ${s.freePlay} · ${s.deckCustom}';
      expect([for (final e in tester.widgetList<InkTag>(tags())) e.text],
          [customTag, rankedTag, '${s.freePlay} · ${s.deckAllKnown}', s.training]);
      String line(int cards, int misses) =>
          s.historyLineTemplate.replaceAll('{0}', '$cards').replaceAll('{1}', '$misses');
      String score(int points) => s.historyScoreTemplate.replaceAll('{0}', '$points');
      expect(find.text(line(AnkirenLevels.of(0).cards, 1)), findsOneWidget, reason: 'one card found after a wrong tap');
      expect(find.text(line(6, 2)), findsOneWidget, reason: 'ended with two cards never found');
      expect(find.text(score(ranked.score)), findsOneWidget);
      expect(find.text(score(custom.score)), findsOneWidget);

      for (final label in [s.allTab, s.training, s.freePlay, s.weakCards, SideTrip.ankiren.label]) {
        final rect = tester.getRect(chip(label));
        expect(rect.left, greaterThanOrEqualTo(Gaps.gutter));
        expect(rect.right, lessThanOrEqualTo(_phone.width - Gaps.gutter), reason: 'the filter row wraps');
      }

      await _capture(tester, 'history_filter_$lang');
      await filter(SideTrip.ankiren.label);
      await _capture(tester, 'history_ankiren_$lang');
      expect([for (final e in tester.widgetList<InkTag>(tags())) e.text], [customTag, rankedTag]);
      await filter(s.training);
      expect([for (final e in tester.widgetList<InkTag>(tags())) e.text], [s.training]);
      await filter(s.weakCards);
      expect(tags(), findsNothing);
      expect(find.text(s.noRunsYet), findsOneWidget);
      await filter(s.allTab);
      expect(tags(), findsNWidgets(4));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('My Profile shows 暗記練\'s rank under the main one, unranked at 入門 before its first game ($lang)',
        (tester) async {
      final s = S(ja ? 'ja' : 'en');
      final p = await open(tester, ja: ja);
      onPhone(tester, fontScale: 1.3);
      Future<void> showProfile() async {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(progress: p, child: const MaterialApp(home: ProfileScreen())),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }

      await showProfile();
      expect(find.text(SideTrip.ankiren.label), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsOneWidget);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bands.first);

      await tester.runAsync(() => p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true)), startedAt: day));
      final rating = p.sideTrips.ratingOf(SideTrip.ankiren)!;
      await showProfile();
      final row = find.ancestor(of: find.byType(ClassBadge), matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: find.text('${rating.round()}')), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsNothing);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bandOf(rating));
      final badge = tester.getSize(find.byType(ClassBadge));
      final sticker = tester.getSize(find.byType(RankSticker));
      expect(badge.height, lessThan(sticker.height), reason: 'smaller than the main rank');
      await _capture(tester, 'profile_side_trips_$lang');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
