import 'dart:io';
import 'dart:math';
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
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/history/ankiren_game_page.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/history/history_widgets.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

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
    File('build/screens/history_look/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// History after a seeded journey with ranked, exam and free runs and
/// 暗記練 games: the list, then every tab of a ranked run, a training run
/// and a 暗記練 game, on a phone and on a tall screen that shows each tab's
/// whole contents.
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

  PlaySession swipes(int seed, int baseMs, {Set<int> misses = const {}}) {
    final rng = Random(seed);
    final ids = [for (var i = 1; i <= 100; i++) i]..shuffle(rng);
    final session = PlaySession([for (final id in ids) CardRef(id)]);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += Duration(milliseconds: baseMs + rng.nextInt(baseMs));
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
    for (final (height, tall) in [(832.0, ''), (1900.0, '_tall')]) {
      testWidgets('History looks right after a seeded journey ($lang$tall)', (tester) async {
        late Progress p;
        await tester.runAsync(() async {
          p = await Progress.open(AppDatabase(NativeDatabase.memory()));
          p.tabsAlwaysOpen = true;
          await seedDemoData(p, days: 10);
          await p.updateSettings(
              p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true, onboarded: true));
          final today = p.dayAt().date;
          final yesterday = today.subtract(const Duration(days: 1));
          await p.recordRun(swipes(1, 1600, misses: {9, 50, 77}), const PlayConfig(mode: PlayMode.ranked),
              yesterday.add(const Duration(hours: 7)));
          await p.recordRun(swipes(2, 1500, misses: {3, 61}), const PlayConfig(mode: PlayMode.exam),
              yesterday.add(const Duration(hours: 9)),
              tobi: const Duration(seconds: 300),
              tobiLine: [for (var i = 1; i <= 100; i++) Duration(milliseconds: 3000 * i)]);
          await p.recordRun(swipes(3, 1300, misses: {20}), const FreePracticeSetup().config,
              today.add(const Duration(hours: 5)));
          await p.recordRun(swipes(4, 1200, misses: {5, 70}), const PlayConfig(mode: PlayMode.ranked),
              today.add(const Duration(hours: 9)));
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(3, ranked: true), seed: 2, ms: 1400, wrongAt: {0, 2}),
              startedAt: yesterday.add(const Duration(hours: 8)));
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(3, ranked: true), seed: 3, ms: 900, wrongAt: {1}),
              startedAt: today.add(const Duration(hours: 6)));
          await p.recordAnkiren(
              playAnkiren(const AnkirenSetup.custom(perSide: 3, memorise: Duration(seconds: 30)), seed: 4),
              startedAt: today.add(const Duration(hours: 7)));
        });
        const dpr = 2.8125;
        const bars = FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr);
        tester.view
          ..devicePixelRatio = dpr
          ..physicalSize = Size(384, height) * dpr
          ..padding = bars
          ..viewPadding = bars;
        addTearDown(tester.view.reset);

        Future<void> show(Widget home) async {
          await tester.pumpWidget(RepaintBoundary(
            key: const ValueKey('screen'),
            child: ProgressScope(
              progress: p,
              child: MaterialApp(
                  key: UniqueKey(),
                  theme: buildMangaTheme(),
                  debugShowCheckedModeBanner: false,
                  home: Scaffold(body: SafeArea(child: home))),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 600));
        }

        Future<void> settle() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
        }

        Future<void> pageThrough(String name, int tabs) async {
          for (var tab = 0; tab < tabs; tab++) {
            expect(tester.takeException(), isNull);
            await _capture(tester, '${name}_${tab}_$lang$tall');
            if (tab == tabs - 1) break;
            await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
            await tester.pumpAndSettle();
          }
        }

        final s = S(lang);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.history)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 1));
        await _capture(tester, 'list_main_$lang$tall');
        await tester.tap(find.textContaining(s.historyAnkirenTab, findRichText: true).first);
        await settle();
        await _capture(tester, 'list_ankiren_$lang$tall');

        for (final (mode, name, tabs) in [
          (PlayMode.ranked, 'ranked', RunPage.hundredTabs.length),
          (PlayMode.training, 'training', RunPage.trainingTabs.length),
        ]) {
          await show(const HistoryScreen());
          final row = find.byWidgetPredicate((w) => w is RunKindTag && w.mode == mode).first;
          await tester.dragUntilVisible(row, find.byType(ListView).first, const Offset(0, -200));
          await tester.pump();
          await tester.tap(row);
          await settle();
          expect(find.byType(RunPage), findsOneWidget);
          await pageThrough(name, tabs);
        }

        await show(const HistoryScreen());
        await tester.tap(find.textContaining(s.historyAnkirenTab, findRichText: true).first);
        await settle();
        await tester.tap(find.byType(AnkirenKindTag).at(1));
        await settle();
        expect(find.byType(AnkirenGamePage), findsOneWidget);
        await pageThrough('ankiren', AnkirenGamePage.scoredTabs.length);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
