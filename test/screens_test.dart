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
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_mask.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
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

  testWidgets('home, all known (en): due reviews and known speed render cleanly', (tester) async {
    final p = await open(tester, mode: LearningMode.allKnown);
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    await makeSomeDue(tester, p, ids.take(10).toList());
    expect(p.dueCount(), greaterThan(0));
    expect(p.knownCardSpeedMs, isNotNull);
    await show(tester, p, 'known_due_en');
  });

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('stats: islands with real dots and medians, then runs ($lang)', (tester) async {
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

      // A free-play run too, so the Runs tab has something to list.
      await tester.runAsync(() async {
        final freeCards = [for (final id in ids.take(5)) CardRef(id, inverted: false, mask: CardMask.none)];
        final session = PlaySession(freeCards);
        var t = const Duration(seconds: 500);
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
      expect(tester.takeException(), isNull);

      final s = S(ja);
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'stats_islands_$lang');

      await tester.tap(find.text(s.runsTab));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'stats_runs_$lang');

      await tester.pumpWidget(const SizedBox());
    });
  }

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
      await tester.tap(find.byWidgetPredicate((w) => '${w.runtimeType}' == '_CardTile').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'card_detail_$lang');

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
}
