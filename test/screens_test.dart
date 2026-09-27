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
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/training_hero.dart';
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
