import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/run_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/profile/profile_screen.dart';
import 'package:fudatobashi/ui/rank/rank_badges.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/history/history_widgets.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

const _phone = Size(384, 832);

/// A narrower phone as tall as the user's, where a large font scale leaves
/// History's header the least room.
const _narrowPhone = Size(360, 832);

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

  // Swipes [ids] in turn, "don't know" at the indexes in [misses], and
  // stops after [stopAfter] cards when given.
  PlaySession swipes(List<int> ids, {Set<int> misses = const {}, int? stopAfter}) {
    final session = PlaySession([for (final id in ids) CardRef(id)]);
    var t = const Duration(seconds: 100);
    while (!session.finished && session.index < (stopAfter ?? ids.length)) {
      session.revealed(t);
      t += Duration(milliseconds: 700 + 13 * (session.index % 7));
      session.commit(
          responseTs: t,
          commitTs: t + const Duration(milliseconds: 80),
          outcome: misses.contains(session.index) ? Outcome.dontKnow : Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  // The user's phone: 384 × 832 at 2.8125 px per dp, with a 28 dp status bar
  // and a 48 dp navigation bar.
  void onPhone(WidgetTester tester, {required double fontScale, Size size = _phone}) {
    const dpr = 2.8125;
    const bars = FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr);
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = size * dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    for (final (phone, fontScale) in [(_phone, 1.0), (_phone, 1.3), (_narrowPhone, 1.3)]) {
      final setup = '$lang, ${phone.width.round()} dp, font scale $fontScale';
      final shot = '${lang}_${phone.width.round()}_${(fontScale * 10).round()}';

      testWidgets('History lists runs by day with their kinds, 暗記練 on its own tab, and the filter narrows them ($setup)',
          (tester) async {
        final s = S(ja ? 'ja' : 'en');
        final p = await open(tester, ja: ja);
        final today = p.dayAt().date.add(const Duration(hours: 10));
        await tester.runAsync(() async {
          await p.recordRun(swipes([1, 2, 3]), const PlayConfig(mode: PlayMode.training), today.subtract(const Duration(days: 1)));
          await p.recordRun(swipes([for (var i = 1; i <= 100; i++) i], misses: {4, 40}), const PlayConfig(mode: PlayMode.ranked),
              today);
          await p.recordRun(swipes([for (var i = 1; i <= 100; i++) i], stopAfter: 30), const PlayConfig(mode: PlayMode.ranked),
              today.add(const Duration(hours: 1)));
          await p.recordRun(swipes([4, 5]), const FreePracticeSetup().config, today.add(const Duration(hours: 2)));
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true), wrongAt: {1}),
              startedAt: today.add(const Duration(hours: 3)));
          await p.recordAnkiren(playAnkiren(const AnkirenSetup.custom(perSide: 3, memorise: Duration(seconds: 30)), endAfter: 4),
              startedAt: today.add(const Duration(hours: 4)));
        });
        onPhone(tester, fontScale: fontScale, size: phone);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.history)));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        await _capture(tester, 'history_main_$shot');
        Finder kinds() => find.byType(RunKindTag);
        expect(kinds(), findsAtLeastNWidgets(3), reason: 'the list builds the rows on screen');
        expect(find.text(s.historyForfeit), findsOneWidget);
        expect(find.text(s.historyPlaced), findsOneWidget);
        expect(find.textContaining(s.historyToday, findRichText: true), findsWidgets);

        await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.historyFilterLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await _capture(tester, 'history_filter_$shot');
        await tester.tap(find.text(s.rankedRun).last);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(s.filterShow(2)), findsOneWidget);
        await tester.tap(find.text(s.filterShow(2)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(kinds(), findsNWidgets(2));
        expect(find.byType(CountBadge), findsOneWidget);

        await tester.tap(find.text(s.historyAnkirenTab).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'history_ankiren_$shot');
        expect(find.byType(AnkirenKindTag), findsNWidgets(2));
        expect(find.text(s.historyNotScored), findsOneWidget);
        expect(find.byType(CountBadge), findsNothing, reason: 'the 暗記練 tab has no kinds picked');
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final (phone, fontScale) in [(_phone, 1.0), (_narrowPhone, 1.3)]) {
      final shot = '${lang}_${phone.width.round()}_${(fontScale * 10).round()}';

      testWidgets('Each run kind opens its run page, and its tabs page through ($shot)', (tester) async {
        final s = S(ja ? 'ja' : 'en');
        final p = await open(tester, ja: ja);
        final start = p.dayAt().date.add(const Duration(hours: 8));
        final all = [for (var i = 1; i <= 100; i++) i];
        final tobi = [for (var i = 1; i <= 100; i++) Duration(milliseconds: 2900 * i)];
        await tester.runAsync(() async {
          await p.recordRun(swipes(all, misses: {9, 50}), const PlayConfig(mode: PlayMode.ranked), start);
          await p.recordRun(swipes(all, misses: {70}), const PlayConfig(mode: PlayMode.ranked),
              start.add(const Duration(hours: 1)));
          await p.recordRun(swipes(all, misses: {3}), const FreePracticeSetup().config, start.add(const Duration(hours: 2)));
          await p.recordRun(swipes(all), const PlayConfig(mode: PlayMode.exam), start.add(const Duration(hours: 3)),
              tobi: tobi.last, tobiLine: tobi);
          await p.recordRun(swipes([1, 2, 3, 4, 5, 6], misses: {2}), const PlayConfig(mode: PlayMode.training),
              start.add(const Duration(hours: 4)));
        });
        onPhone(tester, fontScale: fontScale, size: phone);
        for (final mode in [PlayMode.ranked, PlayMode.free, PlayMode.exam, PlayMode.training]) {
          await tester.pumpWidget(RepaintBoundary(
            key: const ValueKey('screen'),
            child: ProgressScope(
              progress: p,
              child: MaterialApp(
                  key: ValueKey(mode),
                  theme: buildMangaTheme(),
                  debugShowCheckedModeBanner: false,
                  home: const Scaffold(body: HistoryScreen())),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 300));
          await _capture(tester, 'run_list_${mode.name}_$shot');
          final row = find.byWidgetPredicate((w) => w is RunKindTag && w.mode == mode).first;
          await tester.dragUntilVisible(row, find.byType(ListView).first, const Offset(0, -200));
          await tester.pump();
          await tester.tap(row);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(RunPage), findsOneWidget);
          expect(find.text(s.runLoading), findsNothing);
          final tabs = mode == PlayMode.training ? RunPage.trainingTabs.length : RunPage.hundredTabs.length;
          expect(find.text(s.pagerPosition.replaceAll('{0}', '1').replaceAll('{1}', '$tabs').toUpperCase()), findsOneWidget);
          for (var tab = 0; tab < tabs; tab++) {
            expect(tester.takeException(), isNull);
            await _capture(tester, 'run_${mode.name}_${tab}_$shot');
            if (tab == tabs - 1) break;
            await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.pagerNext));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
          }
          if (mode == PlayMode.exam) {
            await tester.tap(find.text(s.runTabOverview));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            expect(find.text(s.legendTobi), findsOneWidget);
          }
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('My Profile shows 暗記練\'s rank under the main one, unranked at 入門 before its first game ($lang)',
        (tester) async {
      final s = S(ja ? 'ja' : 'en');
      final p = await open(tester, ja: ja);
      p.rating = Rating.bands[2].minRating;
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
