// Lays out onboarding and both Home modes in English and Japanese on a
// phone-sized surface and fails on any layout error. With RENDER_SCREENS=1 it
// also writes PNGs to build/screens/ for visual checks.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_mask.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/training_hero.dart';
import 'package:fudatobashi/ui/islands/island_map.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/kimariji_chip.dart';
import 'package:fudatobashi/ui/play/play_screen.dart';
import 'package:fudatobashi/ui/rank/rank_screen.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';
import 'package:fudatobashi/ui/results/island_complete_overlay.dart';
import 'package:fudatobashi/ui/results/new_card_overlay.dart';
import 'package:fudatobashi/ui/results/rank_up_overlay.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';
import 'package:fudatobashi/ui/run/learn_next_button.dart';
import 'package:fudatobashi/ui/stats/card_list.dart';

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

void main() {
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

  test('every pre-rendered art image exists at its vector box size (run tool/render_art_test.dart)', () {
    for (final a in PrerenderedArt.all) {
      final png = File(a.asset).readAsBytesSync();
      final header = ByteData.sublistView(png, 16, 24);
      final expected = a.art.box * ArtRender.scale;
      expect([header.getUint32(0), header.getUint32(4)], [expected.width.ceil(), expected.height.ceil()], reason: a.name);
    }
  });

  test('the island data matches the initial-kana groups', () {
    expect(archipelago.islands.map((i) => i.name), initialGroups);
    for (final isl in archipelago.islands) {
      expect({for (final s in isl.sites) s.poemId}, {...fudaSets['initial:${isl.name}'].poemIds});
    }
  });

  Future<Progress> open(WidgetTester tester, {LearningMode? mode, bool ja = false, int journeyCards = 0}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: ja ? AppLanguage.ja : AppLanguage.en));
      if (mode != null) await p.setLearningMode(mode);
    });
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    for (final id in ids.take(journeyCards)) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    return p;
  }

  Future<void> show(WidgetTester tester, Progress p, String name) async {
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await _capture(tester, name);
    await tester.pumpWidget(const SizedBox());
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('onboarding ($lang)', (tester) async {
      await show(tester, await open(tester, ja: ja), 'onboarding_$lang');
    });

    testWidgets('onboarding, pace step ($lang)', (tester) async {
      final p = await open(tester, ja: ja);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(ja ? 'はじめて' : "I'm new"));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(ja ? '約15日' : 'About 15 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'onboarding_pace_$lang');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('results, journey: Learn next warns while cards are shaky ($lang)', (tester) async {
      final p = await open(tester, mode: LearningMode.journey, ja: ja);
      await tester.binding.setSurfaceSize(_phone);
      final report = SessionReport(
        sessionId: null,
        total: null,
        attempts: const [],
        previousBest: null,
        ratingBefore: null,
        ratingAfter: null,
        goalRaised: false,
      );
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(
          progress: p,
          child: MaterialApp(home: ResultsScreen(report: report, config: const PlayConfig(mode: PlayMode.training))),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(LearnNextButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final warning = ja ? 'まだ3枚あやふやだよ。いいの？' : '3 cards are still shaky. Sure?';
      expect(find.text(warning), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'learn_next_shaky_$lang');
      await tester.tap(find.ancestor(of: find.text(ja ? '練習を続ける' : 'Keep practising'), matching: find.byType(ShoutButton)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(warning), findsNothing);
      expect(p.trainer.unlocked.length, 3);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the unbuilt Help tab pops a coming-soon balloon and stays on Home ($lang)', (tester) async {
      final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(ja ? '解説' : 'Help'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(ja ? '準備中' : 'Coming soon'), findsOneWidget);
      expect(find.byType(TrainingHero), findsOneWidget, reason: 'still on Home');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('home, journey: no Learn next button ($lang)', (tester) async {
      final p = await open(tester, mode: LearningMode.journey, ja: ja);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LearnNextButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('home, journey ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 27), 'journey_$lang');
    });

    testWidgets('home, all known ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.allKnown, ja: ja), 'known_$lang');
    });
  }

  // Plays a quick, fast, all-correct training run on the given poems (upright
  // only), then forces their FSRS due dates into the past: the simplest way
  // to get real due reviews (and a real known-card speed) without waiting on
  // the scheduler's own interval, which may not fall due on the same day.
  Future<void> makeSomeDue(WidgetTester tester, Progress p, List<int> poemIds) async {
    final cards = [for (final id in poemIds) CardRef(id, inverted: false, mask: CardMask.none)];
    await tester.runAsync(() async {
      final session = PlaySession(cards);
      var t = const Duration(seconds: 100);
      for (final _ in cards) {
        session.revealed(t);
        t += const Duration(milliseconds: 500);
        session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 100);
      }
      await p.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
    });
    for (final id in poemIds) {
      p.trainer.items[ItemKey(id, false)]!.card.due = DateTime.now().subtract(const Duration(days: 1));
    }
  }

  // Neither of the existing journey/known tests above ever makes a card due
  // (`progress.dueCount()` stays 0), so the "{0} reviews · {1} new cards" /
  // "{0} reviews due" narration branches — and the known-card speed panel,
  // which needs a timed training attempt — were never exercised at all.
  testWidgets('home, journey (en): due reviews and known speed render cleanly', (tester) async {
    final p = await open(tester, mode: LearningMode.journey, journeyCards: 27);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    await makeSomeDue(tester, p, ids.take(10).toList());
    expect(p.dueCount(), greaterThan(0));
    expect(p.freshCount, greaterThan(0));
    expect(p.knownCardSpeedMs, isNotNull);
    await show(tester, p, 'journey_due_en');
  });

  // Reproduces "BOTTOM OVERFLOWED BY 4.0 PIXELS" on the journey island
  // progress panel (`_IslandProgress` in `journey_home.dart`): the on-device
  // repro used a system font scale of 1.1 (a common, not even large,
  // accessibility setting), which the default test scale of 1.0 never
  // exercises. The fix must size the panel to its own content instead of a
  // fixed-height guess, so it holds at any font scale.
  testWidgets('home, journey (en): island progress panel holds at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.journey, journeyCards: 27);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    await makeSomeDue(tester, p, ids.take(10).toList());
    expect(p.knownCardSpeedMs, isNotNull);
    await show(tester, p, 'journey_due_scaled_en');
  });

  testWidgets('home, all known (en): due reviews and known speed render cleanly', (tester) async {
    final p = await open(tester, mode: LearningMode.allKnown);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    await makeSomeDue(tester, p, ids.take(10).toList());
    expect(p.dueCount(), greaterThan(0));
    expect(p.knownCardSpeedMs, isNotNull);
    await show(tester, p, 'known_due_en');
  });

  // Reproduces "BOTTOM OVERFLOWED BY 3.8 PIXELS" on the Home rating panel
  // (`_RankRow` in `known_home.dart`), found on the same device and for the
  // same reason as the journey progress panel above: a fixed-height guess
  // sized before the known-speed row existed, too short once the system font
  // scale is bumped.
  testWidgets('home, all known (en): rating panel holds at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.allKnown);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    await makeSomeDue(tester, p, ids.take(10).toList());
    expect(p.knownCardSpeedMs, isNotNull);
    await show(tester, p, 'known_due_scaled_en');
  });

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('stats: islands with real dots and medians, then all cards ($lang)', (tester) async {
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 40);
      final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];

      // A handful of unlocked cards played enough times to clear
      // `StatsTuning.mapHollowMinTries`, so some dots render in a real speed
      // colour (not just hollow/locked) and the overall/island medians and
      // the slowest-island panel have something to show.
      final trained = ids.take(8).toList();
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, trained);
      }
      expect(p.dueCount(), greaterThan(0));
      for (final id in trained) {
        expect(p.stats(ItemKey(id, false)).count, greaterThanOrEqualTo(5));
      }

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      final s = S(ja);
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'stats_islands_$lang');

      // The "All" tab lists every card of every island in one sortable list,
      // the same rows as an island page.
      await tester.tap(find.text(s.allTab));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(CardTile), findsWidgets);
      await _capture(tester, 'stats_all_$lang');

      await tester.pumpWidget(const SizedBox());
    });
  }

  // Reproduces the same class of overflow as the island page's card rows
  // (`CardTile` in `card_list.dart`, shared by the island page and the Stats
  // "All" tab): the on-device font scale (1.1) that the default test scale
  // of 1.0 never exercises.
  testWidgets('stats All tab: card rows hold at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.journey, journeyCards: 40);
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    const s = S(false);
    await tester.tap(find.text(s.stats));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(s.allTab));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(CardTile), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  // The History tab (`history_screen.dart`): every run's mode, timestamp,
  // card/miss count and total time, at the same on-device font scale.
  testWidgets('history: run rows render clearly and hold at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.journey, journeyCards: 10);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];

    await tester.runAsync(() async {
      final freeCards = [for (final id in ids.take(5)) CardRef(id, inverted: false, mask: CardMask.none)];
      final session = PlaySession(freeCards);
      var t = const Duration(seconds: 200);
      for (final _ in freeCards) {
        session.revealed(t);
        t += const Duration(milliseconds: 700);
        session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 100);
      }
      await p.recordRun(session, const PlayConfig(mode: PlayMode.free, setIds: ['all']), DateTime.now());
    });
    expect(p.sessions, isNotEmpty);

    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));

    const s = S(false);
    await tester.tap(find.text(s.history));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text(s.freePlay), findsWidgets);
    await _capture(tester, 'history_scaled_en');
    await tester.pumpWidget(const SizedBox());
  });

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('island and card detail: tap through, toggle orientation and mode filter ($lang)', (tester) async {
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 40);

      // Every card of island 0 gets both training attempts (`makeSomeDue`)
      // and free-play attempts, so whichever row the list renders first has
      // real, multi-mode history for the mode filter and orientation toggle
      // to actually have something to show.
      final island0Ids = fudaSets['initial:${archipelago.islands[0].name}'].poemIds;
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, island0Ids);
      }
      await tester.runAsync(() async {
        final freeCards = [for (final id in island0Ids) CardRef(id, inverted: false, mask: CardMask.none)];
        final session = PlaySession(freeCards);
        var t = const Duration(seconds: 900);
        for (final _ in freeCards) {
          session.revealed(t);
          t += const Duration(milliseconds: 600);
          session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
          t += const Duration(milliseconds: 100);
        }
        await p.recordRun(session, const PlayConfig(mode: PlayMode.free, setIds: ['all']), DateTime.now());
      });
      for (final id in island0Ids) {
        final modes = p.attemptsOf(ItemKey(id, false)).map((a) => a.mode).toSet();
        expect(modes, containsAll(const [PlayMode.training, PlayMode.free]));
      }

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      final s = S(ja);
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      // Drive the map's real (wired) tap callback rather than guessing pixel
      // coordinates on a custom-painted map: island 0 is fully trained above.
      // A pushed route's page needs two pump cycles before it shows up in the
      // tree (the first only flushes the navigator's history update).
      final islandMap = tester.widget<IslandMap>(find.byType(IslandMap));
      islandMap.onIslandTap!(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'island_$lang');

      // Tap the first rendered card row (every row in this island has real,
      // multi-mode history, so whichever one is first is a valid target).
      await tester.tap(find.byType(CardTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'card_detail_$lang');

      // The memory panel's "last review" text (`_MemoryPanel` in
      // `card_detail_screen.dart`) shared its row's flexible space evenly
      // with a `Spacer`, so it ellipsized even with room to spare; must
      // render in full now.
      final memoryPanel = find.byWidgetPredicate((w) => '${w.runtimeType}' == '_MemoryPanel');
      for (final paragraph
          in tester.renderObjectList<RenderParagraph>(find.descendant(of: memoryPanel, matching: find.byType(Text)))) {
        expect(paragraph.didExceedMaxLines, isFalse);
      }

      // Toggling to 逆さま before it was ever unlocked is an expected, common
      // case (an empty chart, dashes instead of numbers) that must not crash.
      await tester.tap(find.text(s.invertedLabel));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'card_detail_inverted_$lang');

      await tester.tap(find.text(s.uprightLabel));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      for (final modeLabel in [s.training, s.freePlay, s.allModes]) {
        await tester.tap(find.text(modeLabel));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const SizedBox());
    });
  }

  // Reproduces "BOTTOM OVERFLOWED BY 3.0 PIXELS" on the island page's top bar
  // (`_TopBar` in `island_screen.dart`): its two-line title+subtitle Column
  // was squeezed into another fixed-height guess, same root cause and same
  // on-device font scale (1.1) as the Home overflows above.
  testWidgets('island page: top bar holds at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.journey, journeyCards: 40);
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    const s = S(false);
    await tester.tap(find.text(s.stats));
    await tester.pump(const Duration(milliseconds: 500));
    final islandMap = tester.widget<IslandMap>(find.byType(IslandMap));
    islandMap.onIslandTap!(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('rank ladder: open from Stats, a mid-ladder rating shows you/next/clear, preview rank-up ($lang)',
        (tester) async {
      final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
      // A little into D級 (index 5 of 9): a few classes cleared below it, C級
      // as the next threshold, and B/A above with no marker — real coverage
      // of every rung state in one shot.
      p.rating = Rating.bands[5].minRating + 5;

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      final s = S(ja);
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      // A pushed route's page needs two pump cycles before it shows up in
      // the tree (the first only flushes the navigator's history update).
      await tester.tap(find.text(s.rank));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(RankScreen), findsOneWidget);
      await _capture(tester, 'rank_ladder_$lang');

      await tester.tap(find.text(s.previewRankUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(RankUpOverlay), findsOneWidget);
      // A mangled-encoding regression: the rating line ("1234 → 1235") once
      // read "1234 β†’ 1235" (mojibake for the arrow), silently wrong on every
      // device regardless of font scale.
      expect(find.textContaining('→'), findsWidgets);
      expect(find.textContaining('β†'), findsNothing);
      await _capture(tester, 'rank_up_preview_$lang');

      // Tap-anywhere-to-skip dismisses the preview cleanly.
      await tester.tapAt(const Offset(40, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }

  // Reproduces the same class of overflow as the island page's top bar
  // above, this time on the rank ladder's `_TopBar` (`rank_screen.dart`):
  // its two-line rating-number Column, squeezed into a fixed-height guess.
  testWidgets('rank ladder: top bar holds at a larger font scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final p = await open(tester, mode: LearningMode.allKnown);
    p.rating = Rating.bands[5].minRating + 5;
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    const s = S(false);
    await tester.tap(find.text(s.stats));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(s.rank));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(RankScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rank ladder: open from the Home rating panel', (tester) async {
    final p = await open(tester, mode: LearningMode.allKnown);
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    final s = S(false);
    await tester.tap(find.text(s.ratingLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(RankScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  // Reproduces "BOTTOM OVERFLOWED" on the Results splash's stat/rating/
  // toughest-cards panels (`_StatPanel`/`_RatingPanel`/`_ToughestPanel` in
  // `results_screen.dart`): each squeezed into a fixed height, although their
  // shared parent is a `SingleChildScrollView` with no reason to cap any of
  // them at all — on-device this overflowed even at the default font scale.
  testWidgets('results: stat, rating and toughest-cards panels render cleanly', (tester) async {
    final p = await open(tester, mode: LearningMode.allKnown);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    const config = PlayConfig(mode: PlayMode.training);
    late SessionReport report;
    await tester.runAsync(() async {
      final cards = [for (final id in ids.take(5)) CardRef(id, inverted: false, mask: CardMask.none)];
      final session = PlaySession(cards);
      var t = const Duration(seconds: 100);
      for (final _ in cards) {
        session.revealed(t);
        t += const Duration(milliseconds: 500);
        session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 700);
      }
      report = await p.recordRun(session, config, DateTime.now());
    });
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(home: ResultsScreen(report: report, config: config)),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('results (journey): Learn next cards sits above the action row', (tester) async {
    final p = await open(tester, mode: LearningMode.journey);
    const config = PlayConfig(mode: PlayMode.training);
    late SessionReport report;
    await tester.runAsync(() async {
      final planned = await p.planTraining();
      final session = PlaySession(planned.cards.take(4).toList());
      var t = const Duration(seconds: 100);
      for (var i = 0; i < 4; i++) {
        session.revealed(t);
        t += const Duration(milliseconds: 900);
        session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 300);
      }
      report = await p.recordRun(session, config, DateTime.now());
    });
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(progress: p, child: MaterialApp(home: ResultsScreen(report: report, config: config))),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LearnNextButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'results_learn_next');
    await tester.pumpWidget(const SizedBox());
  });

  // A personal best plays out on the Results splash before any celebration
  // page covers it, and the panel (no longer a fixed height) holds the
  // sticker, the previous best and the time saved at a large font scale.
  for (final ja in [false, true]) {
    testWidgets('results: a personal best stamps on before the celebrations, at a large font scale (${ja ? 'ja' : 'en'})',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
      final report = SessionReport(
        sessionId: null,
        total: const Duration(milliseconds: 14906),
        attempts: [
          for (var i = 0; i < 5; i++)
            Attempt(
                index: i,
                card: CardRef(i + 1),
                responseUs: 600000 + i * 10000,
                outcome: Outcome.known,
                at: DateTime(2026),
                deckSize: 5),
        ],
        previousBest: const Duration(milliseconds: 15380),
        ratingBefore: null,
        ratingAfter: null,
        goalRaised: false,
        islandsCompleted: const [2],
      );
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(
          progress: p,
          child: MaterialApp(home: ResultsScreen(report: report, config: const PlayConfig(mode: PlayMode.training))),
        ),
      ));
      await tester.pump(PersonalBestMotion.length);
      expect(tester.takeException(), isNull);
      final s = S(ja);
      expect(find.text(s.personalBest.toUpperCase()), findsOneWidget);
      expect(find.text('00:14.906'), findsWidgets, reason: 'the time has ticked down to the new best');
      expect(find.text(s.timeSaved('0.474')), findsOneWidget);
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'the island waits for the personal best');
      await _capture(tester, 'results_pb_${ja ? 'ja' : 'en'}');
      await tester.pump(ResultsLayout.overlayStagger);
      await tester.pump();
      expect(find.byType(CelebrationSequence), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  group('Rank ladder edge cases', () {
    Widget pumped(Progress p) => ProgressScope(progress: p, child: const MaterialApp(home: RankScreen()));

    testWidgets('already at A: no NEXT tag and no preview entry, TOP CLASS still shown', (tester) async {
      final p = await open(tester);
      p.rating = Rating.bands.last.minRating + 50;
      await tester.pumpWidget(pumped(p));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      const s = S(false);
      expect(find.text(s.previewRankUp), findsNothing);
      expect(find.text(s.nextChip), findsNothing);
      expect(find.text(s.topClassNote), findsOneWidget);
      expect(find.text(s.youTag), findsOneWidget);
    });

    testWidgets('opens scrolled to your rung, with every class ahead locked', (tester) async {
      final p = await open(tester);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(pumped(p));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(tester.widget<ListView>(find.byType(ListView)).controller!.offset, greaterThan(0),
          reason: '入門 is the bottom rung');
      expect(tester.getRect(find.text(const S(false).youTag)).bottom, lessThan(_phone.height));
      final locks = find.byWidgetPredicate((w) => w is MangaIcon && w.art == IconArt.lock);
      expect(locks, findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('fresh player: 入門-only ladder renders cleanly', (tester) async {
      final p = await open(tester);
      await tester.pumpWidget(pumped(p));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      const s = S(false);
      expect(find.text(s.youTag), findsOneWidget);
    });
  });

  // Reproduces "BOTTOM OVERFLOWED BY 13 PIXELS" on the Training banner
  // directly on `TrainingHero`: a long narration (however it got long — many
  // due reviews and new cards, a long locale string, ...) wraps to two lines,
  // and the journey panel's fixed-height `SizedBox` (206, see
  // `HomeLayout.journeyHeroHeight`) has no slack for that, since only the
  // title shrinks (`Expanded`) while the narration and shout button are
  // fixed/intrinsic size. The fix must hold for arbitrarily long narration,
  // not just realistic due/fresh counts, hence the deliberately huge numbers.
  group('TrainingHero narration overflow', () {
    Widget pumped(Progress p, HeroSize size, double height, Widget narration) => ProgressScope(
          progress: p,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 352,
                  height: height,
                  child: TrainingHero(size: size, narration: narration, balloon: 'balloon'),
                ),
              ),
            ),
          ),
        );

    // Pathologically long (not just realistic two-digit counts): the fix
    // must hold for arbitrarily long narration, in any language.
    final longNarration = Text('${List.filled(20, "reviews").join(' ')} · ${List.filled(20, "new cards").join(' ')}');

    testWidgets('compact (journey): a very long narration clips to one line, no overflow', (tester) async {
      final p = await open(tester);
      await tester.pumpWidget(pumped(p, HeroSize.compact, HomeLayout.journeyHeroHeight, longNarration));
      expect(tester.takeException(), isNull);
      final paragraph = tester
          .renderObject<RenderParagraph>(find.descendant(of: find.byType(NarrationBox), matching: find.byType(Text)));
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
    });

    testWidgets('full (known): a two-line narration is allowed and still does not overflow', (tester) async {
      const twoLineNarration = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('12 reviews due'), Text('34 slow cards to beat')],
      );
      // The full hero sizes itself around its content in known_home.dart (a
      // computed-height Positioned, not a hardcoded literal); a tall SizedBox
      // here stands in for that slack.
      final p = await open(tester);
      await tester.pumpWidget(pumped(p, HeroSize.full, 420, twoLineNarration));
      expect(tester.takeException(), isNull);
      final textFinder = find.descendant(of: find.byType(NarrationBox), matching: find.byType(Text));
      expect(textFinder, findsNWidgets(2));
      // Unlike the compact case, nothing here constrains maxLines: both
      // lines render at their own height, stacked, well inside the tall box.
      for (final e in textFinder.evaluate()) {
        expect((e.renderObject! as RenderParagraph).maxLines, isNull);
      }
    });
  });

  group('Play chrome', () {
    Future<void> pumpPlay(WidgetTester tester, Progress p) async {
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(leadIn: false)));
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(
          progress: p,
          child: const MaterialApp(
            home: PlayScreen(cards: [CardRef(1), CardRef(2), CardRef(3)], config: PlayConfig(mode: PlayMode.free)),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the kimariji chip stays clear of the counter at a large font scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final p = await open(tester, mode: LearningMode.allKnown);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(leadIn: false)));
      await tester.binding.setSurfaceSize(_phone);
      final long = poems.byKimariji('きみがためは').id;
      await tester.pumpWidget(ProgressScope(
        progress: p,
        child: MaterialApp(
          home: PlayScreen(
              cards: [CardRef(long), const CardRef(2), const CardRef(3)], config: const PlayConfig(mode: PlayMode.free)),
        ),
      ));
      await tester.pump();
      await tester.pump();
      final g = await tester.startGesture(const Offset(192, 360));
      for (var i = 0; i < 4; i++) {
        await g.moveBy(const Offset(40, 0));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      final chip = tester.getRect(find.byType(KimarijiChip));
      final counter = tester.getRect(find.text('/ 3'));
      expect(chip.right, lessThan(counter.left));
      await tester.pumpWidget(const SizedBox());
    });

    for (final ja in [false, true]) {
      testWidgets('the don\'t-remember button fits at a large font scale (${ja ? 'ja' : 'en'})', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
        await tester.runAsync(() => p.updateSettings(p.settings.copyWith(dontKnowInput: DontKnowInput.button)));
        await pumpPlay(tester, p);
        await tester.tap(find.text(ja ? '覚えてない' : "Don't remember"));
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'play_button_${ja ? 'ja' : 'en'}');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('holding a swipe down shows the filling don\'t-know mark', (tester) async {
      final p = await open(tester);
      await pumpPlay(tester, p);
      final g = await tester.startGesture(const Offset(192, 360));
      for (var i = 0; i < 4; i++) {
        await g.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await tester.pump(SwipeTuning.dontKnowHoldDwell ~/ 2);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'play_hold');
      await g.up();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Celebration pages', () {
    Future<void> pumpPage(WidgetTester tester, Progress p, Widget page, Duration settle) async {
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(progress: p, child: MaterialApp(home: Scaffold(body: page))),
      ));
      await tester.pump(settle);
      expect(tester.takeException(), isNull);
    }

    for (final ja in [false, true]) {
      final lang = ja ? 'ja' : 'en';

      testWidgets('a new card appears, at a large font scale ($lang)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final p = await open(tester, ja: ja);
        final card = poems.byKimariji('きみがためは').id;
        var advanced = false;
        await pumpPage(
          tester,
          p,
          NewCardOverlay(data: NewCardCelebration(card, fudaSets.tomofuda(card)), onNext: () => advanced = true),
          const Duration(milliseconds: 1300),
        );
        await _capture(tester, 'new_card_$lang');
        await tester.tap(find.text(ja ? '受けて立つ' : 'BRING IT ON!'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(advanced, isTrue, reason: 'the accept flick hands over to the next page');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('island complete, at a large font scale ($lang)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final p = await open(tester, ja: ja);
        await pumpPage(
          tester,
          p,
          IslandCompleteOverlay(islandIndex: 2, islandsDone: 3, cardsUnlocked: 29, onNext: () {}),
          const Duration(milliseconds: 2300),
        );
        await _capture(tester, 'island_complete_$lang');
        await tester.pumpWidget(const SizedBox());
      });

      // Every step of the ladder, at a large font scale: the spread's halves,
      // the counting rating and the next class's panel must fit, and the top
      // class shows the summit instead of a next target.
      for (final (from, to) in [(0, 1), (2, 3), (7, 8)]) {
        testWidgets('rank up ${Rating.bands[from].id} → ${Rating.bands[to].id}, at a large font scale ($lang)',
            (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final p = await open(tester, ja: ja);
          final after = Rating.bands[to].minRating + 12;
          final before = from == 0 ? null : Rating.bands[from].minRating + 40;
          var advanced = false;
          await pumpPage(
            tester,
            p,
            RankUpOverlay(
              data: RankUpCelebration(Rating.bands[from], Rating.bands[to], before, after),
              onNext: () => advanced = true,
            ),
            RankUpMotion.length + const Duration(milliseconds: 100),
          );
          expect(find.text('${after.round()}'), findsWidgets, reason: 'the rating has counted up to its new value');
          await _capture(tester, 'rank_up_${Rating.bands[to].id}_$lang');
          await tester.tap(find.text(ja ? '次へ' : 'ONWARD!'));
          expect(advanced, isTrue);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
