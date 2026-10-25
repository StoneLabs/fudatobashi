import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:fudatobashi/ui/history/run_overview_tab.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';

import 'test_ankiren.dart';
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

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    // The narrower phone is as tall as the user's: a large font scale leaves
    // History's header the least room there.
    for (final (phone, fontScale) in [(usersPhone, 1.0), (usersPhone, 1.3), (narrowTallPhone, 1.3)]) {
      final setup = '$lang, ${phone.name} dp, font scale $fontScale';

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
          await p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked(), wrongAt: {1}),
              startedAt: today.add(const Duration(hours: 3)));
          await p.recordAnkiren(playAnkiren(const AnkirenSetup.custom(perSide: 3, memorise: Duration(seconds: 30)), endAfter: 4),
              startedAt: today.add(const Duration(hours: 4)));
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(3), strikes: true, wrongAt: {1}, endAfter: 4),
              startedAt: today.add(const Duration(hours: 5)));
        });
        useScreen(tester, phone, fontScale: fontScale);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.history)));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        await captureScreen(tester, 'history_main', lang: lang);
        Finder kinds() => find.byType(RunKindTag);
        expect(kinds(), findsAtLeastNWidgets(3), reason: 'the list builds the rows on screen');
        expect(find.text(s.historyForfeit), findsOneWidget);
        expect(find.text(s.historyPlaced), findsOneWidget);
        expect(find.textContaining(s.historyToday, findRichText: true), findsWidgets);

        await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.historyFilterLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await captureScreen(tester, 'history_filter', lang: lang);
        await tester.tap(find.text(s.rankedRun).last);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(s.filterShow(2)), findsOneWidget);
        await tester.tap(find.text(s.filterShow(2)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(kinds(), findsNWidgets(2));
        expect(find.byType(CountBadge), findsOneWidget);

        await tester.tap(find.textContaining(s.historyAnkirenTab, findRichText: true).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await captureScreen(tester, 'history_ankiren', lang: lang);
        expect(find.byType(AnkirenKindTag), findsNWidgets(3));
        expect(find.text(s.historyFailed), findsOneWidget, reason: 'the free game ended short');
        expect(find.byType(CountBadge), findsNothing, reason: 'the 暗記練 tab has no kinds picked');
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowTallPhone, 1.3)]) {
      final shot = '${lang}_${phone.name}_${(fontScale * 10).round()}';

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
        useScreen(tester, phone, fontScale: fontScale);
        // Tobi idles for ever; with animations off the tabs settle.
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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
          await captureScreen(tester, 'run_list_${mode.name}', lang: lang);
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
          expect(find.text(s.runTabOverview), findsOneWidget);
          final tabLabels = [
            for (final t in mode == PlayMode.training ? RunPage.trainingTabs : RunPage.hundredTabs) t.label(s),
          ];
          for (var tab = 0; tab < tabs; tab++) {
            expect(tester.takeException(), isNull);
            await captureScreen(tester, 'run_${mode.name}', lang: lang, variant: 'tab$tab');
            if (tab == 0) {
              final overview = tester.state<ScrollableState>(
                  find.descendant(of: find.byType(RunOverviewTab), matching: find.byType(Scrollable)).first);
              final fits = overview.position.maxScrollExtent == 0;
              debugPrint('overview fit ${mode.name} $shot: ${fits ? 'fits' : 'scrolls ${overview.position.maxScrollExtent.round()}'}');
              if (phone == usersPhone && fontScale == 1.0) expect(fits, isTrue, reason: 'Overview is one screen tall');
            }
            if (tab == tabs - 1) break;
            if (tab.isEven) {
              await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
            } else {
              await tester.tap(find.text(tabLabels[tab + 1]));
            }
            await tester.pumpAndSettle();
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

    testWidgets('My Profile shows 暗記練\'s rank under the main one, unranked as a novice before its first game ($lang)',
        (tester) async {
      final s = S(ja ? 'ja' : 'en');
      final p = await open(tester, ja: ja);
      p.rating = Rating.bands[2].minRating;
      useScreen(tester, usersPhone, fontScale: 1.3);
      Future<void> showProfile() async {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(progress: p, child: const MaterialApp(home: ProfileScreen())),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }

      await showProfile();
      expect(find.text(s.tripName(SideTrip.ankiren)), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsOneWidget);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bands.first);

      await tester.runAsync(() => p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked()), startedAt: day));
      final rating = p.sideTrips.ratingOf(SideTrip.ankiren)!;
      await showProfile();
      final row = find.ancestor(of: find.byType(ClassBadge), matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: find.text('${rating.round()}')), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsNothing);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bandOf(rating));
      final badge = tester.getSize(find.byType(ClassBadge));
      final sticker = tester.getSize(find.byType(RankSticker));
      expect(badge.height, lessThan(sticker.height), reason: 'smaller than the main rank');
      await captureScreen(tester, 'profile_side_trips', lang: lang);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
