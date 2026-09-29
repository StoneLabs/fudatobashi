// Lays out onboarding and both Home modes in English and Japanese on a
// phone-sized surface and fails on any layout error. With RENDER_SCREENS=1 it
// also writes PNGs to build/screens/ for visual checks.
import 'dart:io';
import 'dart:math' as math;
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
import 'package:fudatobashi/domain/synthetic_learner.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/credits_strings.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/onboarding_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/settings_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/debug/simulation_page.dart';
import 'package:fudatobashi/ui/free/card_picker.dart';
import 'package:fudatobashi/ui/free/free_practice_sheet.dart';
import 'package:fudatobashi/ui/free/island_picker.dart';
import 'package:fudatobashi/ui/free/look_alike_picker.dart';
import 'package:fudatobashi/ui/home/learn_ahead_button.dart';
import 'package:fudatobashi/ui/home/training_hero.dart';
import 'package:fudatobashi/ui/islands/island_map.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/onboarding/onboarding_panels.dart';
import 'package:fudatobashi/ui/onboarding/welcome_sea.dart';
import 'package:fudatobashi/ui/play/kimariji_chip.dart';
import 'package:fudatobashi/ui/play/play_screen.dart';
import 'package:fudatobashi/ui/rank/rank_screen.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';
import 'package:fudatobashi/ui/results/island_complete_overlay.dart';
import 'package:fudatobashi/ui/results/new_card_overlay.dart';
import 'package:fudatobashi/ui/results/rank_up_overlay.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';
import 'package:fudatobashi/ui/settings/credits_screen.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/stats/card_detail_screen.dart';
import 'package:fudatobashi/ui/stats/card_list.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

void main() {
  loadTestVectorArt();
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

  test('every sound asset exists, and every file in assets/sounds is a sound in use', () {
    final used = {for (final sfx in Sfx.values) ...sfx.assets.map((a) => 'assets/$a')};
    final files = {for (final f in Directory('assets/sounds').listSync()) if (f.path.endsWith('.wav')) f.path};
    expect(files, used);
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

  // The user's phone: 384 × 832 at 2.8125 px per dp, with a 28 dp status bar
  // and a 48 dp navigation bar.
  Future<void> onPhone(WidgetTester tester, Progress p, {required double fontScale}) async {
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
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Taps [target] and pumps through the onboarding step swap frame by frame,
  // failing on any layout error; [probe] runs just after the new step starts
  // coming in.
  Future<void> swapStep(WidgetTester tester, Finder target, {void Function()? probe}) async {
    const frame = Duration(milliseconds: 20);
    final probeAt = OnboardingMotion.enterDelay + OnboardingMotion.stagger;
    var probed = false;
    await tester.tap(target);
    await tester.pump();
    for (var t = frame; t < OnboardingMotion.length + frame; t += frame) {
      await tester.pump(frame);
      expect(tester.takeException(), isNull);
      if (probe != null && !probed && t >= probeAt) {
        probed = true;
        probe();
      }
    }
    await tester.pump();
  }

  // No layout errors, nothing to scroll, and no text under a go button.
  void expectOnboardingFits(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final scroll in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      expect(scroll.position.maxScrollExtent, 0, reason: 'the step fits without scrolling');
    }
    final texts = find.byType(RichText);
    for (var i = 0; i < find.byType(GoButton).evaluate().length; i++) {
      final go = tester.getRect(find.byType(GoButton).at(i));
      for (var j = 0; j < texts.evaluate().length; j++) {
        final text = tester.getRect(texts.at(j));
        expect(go.overlaps(text), isFalse, reason: '"${tester.widget<RichText>(texts.at(j)).text.toPlainText()}" runs under a go button');
      }
    }
  }

  testWidgets('onboarding: the surf drifts and the boat rocks, and both hold still under reduced motion', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final reduced in [false, true]) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduced);
      await onPhone(tester, await open(tester), fontScale: 1.0);
      final surf = find.descendant(of: find.byType(WelcomeSeaFront), matching: find.byType(StaticArt));
      final boat = find.descendant(of: find.byType(WelcomeSeaFront), matching: find.byType(VectorArtBox));
      final before = [tester.getTopLeft(surf), tester.getTopLeft(boat)];
      await tester.pump(const Duration(milliseconds: 300));
      final after = [tester.getTopLeft(surf), tester.getTopLeft(boat)];
      for (var i = 0; i < before.length; i++) {
        expect(after[i] == before[i], reduced, reason: '${['surf', 'boat'][i]}, reduced motion: $reduced');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('onboarding: the pace step slides in from the right, and back slides the first step in from the left ($lang)',
        (tester) async {
      final p = await open(tester, ja: ja);
      await onPhone(tester, p, fontScale: 1.1);
      await swapStep(tester, find.text(S(ja).beginnerTitle), probe: () {
        expect(tester.getTopLeft(find.byType(WelcomePanel)).dx, lessThan(0), reason: 'step 1 leaves to the left');
        expect(tester.getTopLeft(find.byType(PaceHeader)).dx, greaterThan(Gaps.gutter), reason: 'step 2 comes from the right');
      });
      expect(find.byType(WelcomePanel), findsNothing);
      expect(find.byType(PaceChoice), findsNWidgets(2));
      await swapStep(tester, find.byType(InkIconButton), probe: () {
        expect(tester.getTopLeft(find.byType(PaceHeader)).dx, greaterThan(Gaps.gutter), reason: 'step 2 leaves to the right');
        expect(tester.getTopLeft(find.byType(WelcomePanel)).dx, lessThan(Gaps.gutter), reason: 'step 1 comes from the left');
      });
      expect(find.byType(PaceHeader), findsNothing);
      expect(find.text(S(ja).beginnerTitle), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarding: taps during the step swap do nothing ($lang)', (tester) async {
      final p = await open(tester, ja: ja);
      await onPhone(tester, p, fontScale: 1.1);
      final s = S(ja);
      await tester.tap(find.text(s.beginnerTitle));
      await tester.pump();
      await tester.pump(OnboardingMotion.stagger);
      await tester.tap(find.text(s.expertTitle), warnIfMissed: false);
      await tester.pump(OnboardingMotion.length - OnboardingMotion.stagger * 3);
      await tester.tap(find.text(s.sprintTitle).last, warnIfMissed: false);
      await tester.tap(find.byType(InkIconButton), warnIfMissed: false);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(OnboardingMotion.length);
      await tester.pump();
      expect(p.settings.onboarded, isFalse);
      expect(find.byType(PaceChoice), findsNWidgets(2), reason: 'the swap carried on to the pace step');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarding: under reduced motion the pace step just appears ($lang)', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await open(tester, ja: ja);
      await onPhone(tester, p, fontScale: 1.1);
      await tester.tap(find.text(S(ja).beginnerTitle));
      await tester.pump();
      expect(find.byType(WelcomePanel), findsNothing);
      expect(find.byType(PaceChoice), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarding: screen readers get the text without its line-break marks ($lang)', (tester) async {
      final semantics = tester.ensureSemantics();
      final p = await open(tester, ja: ja);
      await onPhone(tester, p, fontScale: 1.1);
      final marks = RegExp('[\u200B\u2060]');
      final spoken = find.bySemanticsLabel(RegExp('.'));
      void expectNoMarks() {
        expect(spoken, findsWidgets);
        for (var i = 0; i < spoken.evaluate().length; i++) {
          expect(tester.getSemantics(spoken.at(i)).label, isNot(contains(marks)));
        }
      }

      expectNoMarks();
      await swapStep(tester, find.text(S(ja).beginnerTitle));
      expectNoMarks();
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    for (final pace in LearningPace.values) {
      testWidgets('onboarding: the ${pace.name} choice starts the journey at that pace ($lang)', (tester) async {
        final p = await open(tester, ja: ja);
        await onPhone(tester, p, fontScale: 1.1);
        final s = S(ja);
        await swapStep(tester, find.text(s.beginnerTitle));
        final title = switch (pace) {
          LearningPace.month => s.relaxedTitle,
          LearningPace.sprint => s.sprintTitle,
        };
        await tester.runAsync(() async {
          await tester.tap(find.text(title).hitTestable());
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(p.settings.onboarded, isTrue);
        expect(p.trainer.config.learningMode, LearningMode.journey);
        expect(p.trainer.config.pace, pace);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final fontScale in [1.0, 1.1, 1.3]) {
      testWidgets('onboarding fits the phone, both steps, at font scale $fontScale ($lang)', (tester) async {
        final p = await open(tester, ja: ja);
        await onPhone(tester, p, fontScale: fontScale);
        expectOnboardingFits(tester);
        await _capture(tester, 'onboarding_${lang}_$fontScale');
        await swapStep(tester, find.text(S(ja).beginnerTitle));
        expect(find.byType(PaceChoice), findsNWidgets(2));
        expectOnboardingFits(tester);
        await _capture(tester, 'onboarding_pace_${lang}_$fontScale');
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('home, journey: Learn ahead is locked while cards are shaky, and a tap says why ($lang)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 3);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      final ahead = p.learnAhead();
      final unlocked = p.trainer.unlocked.length;
      expect(ahead.lock, LearnAheadLock.shaky);
      await tester.tap(find.byType(LearnAheadButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final why = S(ja).learnAheadShaky(ahead.shaky);
      expect(find.text(why), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'learn_ahead_locked_$lang');
      expect(p.trainer.unlocked.length, unlocked, reason: 'a locked tap unlocks nothing');
      await tester.pump(LearnAheadStyle.balloonLife);
      expect(find.text(why), findsNothing);
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

    testWidgets('home, journey: Learn ahead opens once every card is well remembered, and plays the next batch ($lang)',
        (tester) async {
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 12);
      final ids = [for (final s in p.trainer.unlocked) s.key.poemId];
      await tester.runAsync(() async {
        final session = PlaySession([for (var i = 0; i < StatsTuning.solidMinTimed; i++) ...ids.map(CardRef.new)]);
        var t = const Duration(seconds: 100);
        while (!session.finished) {
          session.revealed(t);
          t += const Duration(milliseconds: 700);
          session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
          t += const Duration(milliseconds: 100);
        }
        await p.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
      });
      expect(p.learnAhead().lock, LearnAheadLock.none, reason: 'all 12 well remembered, ahead of day 0\'s pace');
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await _capture(tester, 'learn_ahead_open_$lang');
      final next = p.trainer.nextBatch(poems, fudaSets);
      await tester.runAsync(() async {
        await tester.tap(find.byType(LearnAheadButton));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PlayScreen), findsOneWidget);
      expect(p.trainer.unlocked.where((s) => !s.key.inverted).length, 12 + next.length);
      expect(p.learnAhead().lock, LearnAheadLock.shaky, reason: 'the new batch still has to be learned');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('home, journey ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 27), 'journey_$lang');
    });

    testWidgets('home, all known ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.allKnown, ja: ja), 'known_$lang');
    });
  }

  // Home's dot backdrop (`Tones.home`) fills the whole screen behind Home's
  // panels and tab bar, in both modes, and no other tab.
  for (final mode in [LearningMode.journey, LearningMode.allKnown]) {
    testWidgets('home, ${mode.name}: the dot backdrop sits behind Home, and only Home', (tester) async {
      final p = await open(tester, mode: mode, journeyCards: 27);
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      final backdrop = find.byType(GradationBox);
      expect(backdrop, findsOneWidget);
      expect(tester.getRect(backdrop), Offset.zero & _phone);
      const s = S(false);
      await tester.tap(find.text(s.history));
      await tester.pump(const Duration(milliseconds: 300));
      expect(backdrop, findsNothing);
      await tester.tap(find.text(s.home));
      await tester.pump(const Duration(milliseconds: 300));
      expect(backdrop, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
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
      for (final setup in const [FreePracticeSetup(), FreePracticeSetup(cardIds: [1, 2]), FreePracticeSetup(maskLevel: 2)]) {
        await p.recordRun(session, setup.config, DateTime.now());
      }
    });
    expect(p.sessions, isNotEmpty);

    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));

    const s = S(false);
    await tester.tap(find.text(s.history));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    for (final label in ['100首', s.deckAllKnown, s.deckCustom, '${s.deckAllKnown} · 隠し字']) {
      expect(find.text('${s.freePlay} · $label'), findsOneWidget);
    }
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

  // A card with a long, mixed history (a slow start, a few "don't know"s,
  // an outlier) and look-alike cards: the chart's every mark, the memory
  // panel and the header must lay out at the phone's font scales.
  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';
    for (final fontScale in [1.0, 1.3]) {
      testWidgets('card detail: a long history renders cleanly ($lang, font scale $fontScale)', (tester) async {
        final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 40);
        final poemId = poems.all.firstWhere((poem) => fudaSets.tomofuda(poem.id).length >= 2).id;
        final card = CardRef(poemId, inverted: false, mask: CardMask.none);
        final random = math.Random(3);
        const attempts = 84;
        await tester.runAsync(() async {
          for (var i = 0; i < attempts; i++) {
            final session = PlaySession([card]);
            final ms = i == 30 ? 1320 : 1100 - 450 * math.min(1, i / 40) + random.nextInt(160) - 80;
            session.revealed(const Duration(seconds: 1));
            final response = Duration(seconds: 1, milliseconds: ms.round());
            session.commit(
                responseTs: response,
                commitTs: response + const Duration(milliseconds: 80),
                outcome: i % 29 == 11 ? Outcome.dontKnow : Outcome.known,
                at: DateTime.now().subtract(Duration(hours: attempts - i)));
            await p.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
          }
        });
        expect(p.attemptsOf(ItemKey(poemId, false)), hasLength(attempts));

        await onPhone(tester, p, fontScale: fontScale);
        tester.state<NavigatorState>(find.byType(Navigator).first).push(
            MangaRoute<void>(builder: (_) => CardDetailScreen(itemKey: ItemKey(poemId, false))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'card_detail_history_${lang}_$fontScale');

        final detail = find.byType(CardDetailScreen);
        // The whole poem and its poet, every kanji run with its reading.
        final poem = poems[poemId];
        for (final markup in [poem.kamiRuby, poem.shimoRuby, poem.authorRuby]) {
          for (final run in Ruby.phrases(markup).expand((phrase) => phrase)) {
            expect(find.descendant(of: detail, matching: find.text(run.base)), findsWidgets, reason: run.base);
            if (run.reading != null) {
              expect(find.descendant(of: detail, matching: find.text(run.reading!)), findsWidgets, reason: run.reading);
            }
          }
        }
        final texts = find.descendant(of: detail, matching: find.byType(RichText));
        for (final paragraph in tester.renderObjectList<RenderParagraph>(texts)) {
          expect(paragraph.didExceedMaxLines, isFalse, reason: paragraph.text.toPlainText());
        }

        // The speed strip sits on the grid of the stat tiles under the chart:
        // TOP SPEED over avg5 + avg10, attempts over avg50, don't know over p95.
        final s = S(ja);
        Rect strip(String label) => tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(SizedBox)).first);
        Rect tile(String label) =>
            tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(GestureDetector)).first);
        expect(strip(s.topSpeedLabel).left, moreOrLessEquals(tile('avg5').left, epsilon: 0.01));
        expect(strip(s.topSpeedLabel).right, moreOrLessEquals(tile('avg10').right, epsilon: 0.01));
        expect(strip(s.attemptsLabel).right, moreOrLessEquals(tile('avg50').right, epsilon: 0.01));
        expect(strip(s.dontKnowLabel).right, moreOrLessEquals(tile('p95').right, epsilon: 0.01));

        await tester.drag(find.descendant(of: detail, matching: find.byType(Scrollable)), const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        await _capture(tester, 'card_detail_history_memory_${lang}_$fontScale');

        // A look-alike chip opens that card's own page.
        final lookAlike = poems[fudaSets.tomofuda(poemId).first];
        await tester.drag(find.descendant(of: detail, matching: find.byType(Scrollable)), const Offset(0, 600));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text(lookAlike.kimariji));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.byWidgetPredicate((w) => w is CardDetailScreen && w.itemKey.poemId == lookAlike.id), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // Journey mode's "Play this island" (`_SlowestIslandPanel` in
  // stats_screen.dart) must not start a run through cards the island hasn't
  // uncovered yet: locked until every one of its cards is unlocked
  // (`Progress.isIslandPlayable`), open right away in all-known mode.
  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('stats: play this island is locked on a partly uncovered island, and a tap says why ($lang)',
        (tester) async {
      final s = S(ja);
      final p = await open(tester, mode: LearningMode.journey, ja: ja);
      final island0Ids = fudaSets['initial:${archipelago.islands[0].name}'].poemIds;
      // Trains every card of the island (whether or not the pace has
      // unlocked it yet — free swiping ahead of the dues is the reported
      // bug) so the trained ones clear `mapHollowMinTries` and get a real
      // median, then re-locks the last few: a card can be well-practised and
      // still not officially uncovered, and the button must stay locked.
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, island0Ids);
      }
      for (final id in island0Ids.skip(4)) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = false;
      }
      final island = p.islands[0];
      expect(island.unlocked, 4);
      expect(island.total, 7);
      expect(p.isIslandPlayable(island), isFalse);

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(s.playThisIsland));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final why = s.uncoverIslandToPlay(island.unlocked, island.total);
      expect(find.text(why), findsOneWidget);
      expect(find.byType(PlayScreen), findsNothing, reason: 'a locked tap starts no run');
      expect(tester.takeException(), isNull);
      await _capture(tester, 'island_play_locked_$lang');
      await tester.pump(StatsLayout.playButtonBalloonLife);
      expect(find.text(why), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stats: play this island plays once every card of it is uncovered ($lang)', (tester) async {
      final s = S(ja);
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 40);
      final island0Ids = fudaSets['initial:${archipelago.islands[0].name}'].poemIds;
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, island0Ids);
      }
      final island = p.islands[0];
      expect(island.unlocked, island.total);
      expect(p.isIslandPlayable(island), isTrue);

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.runAsync(() async {
        await tester.tap(find.text(s.playThisIsland));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PlayScreen), findsOneWidget);
      final played = tester.widget<PlayScreen>(find.byType(PlayScreen));
      expect(played.config.setIds, ['initial:${archipelago.islands[0].name}']);
      expect(played.cards.length, island.total);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stats: play this island is always open in all-known mode ($lang)', (tester) async {
      final s = S(ja);
      final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
      final island0Ids = fudaSets['initial:${archipelago.islands[0].name}'].poemIds;
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, island0Ids);
      }
      expect(p.isIslandPlayable(p.islands[0]), isTrue);

      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.runAsync(() async {
        await tester.tap(find.text(s.playThisIsland));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PlayScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // Reproduces "A RenderFlex overflowed by 1.00 pixels on the bottom" on
    // Home's own brand-title header (`BrandTitle` in `header.dart`, inside
    // `MangaHeader`'s fixed-height bar): its two-line logo doesn't fit that
    // guess at a 1.3 font scale, and any full-app render — not just this
    // screen — pumps through Home first. The fix must size the header to its
    // content instead of a fixed-height guess (`MangaHeader`), so every
    // screen's header, including this one's, holds at any font scale.
    testWidgets('stats: the locked play-this-island panel holds at font scale 1.3 ($lang)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final s = S(ja);
      final p = await open(tester, mode: LearningMode.journey, ja: ja);
      final island0Ids = fudaSets['initial:${archipelago.islands[0].name}'].poemIds;
      for (var i = 0; i < 6; i++) {
        await makeSomeDue(tester, p, island0Ids);
      }
      for (final id in island0Ids.skip(4)) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = false;
      }
      expect(p.islands[0].unlocked, lessThan(p.islands[0].total));
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'island_play_locked_scaled_$lang');
      await tester.pumpWidget(const SizedBox());
    });
  }

  // Free practice (始める): the journey lock, then the setup sheet and its
  // three pickers on the user's phone at scaled fonts.
  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('free practice: journey Home keeps 始める locked, and a tap says how many cards are left ($lang)',
        (tester) async {
      final s = S(ja);
      final p = await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 12);
      final access = p.freePractice();
      expect(access.open, isFalse);
      await onPhone(tester, p, fontScale: 1.1);
      expect(find.text(s.freeLockedSub(access.needed)), findsOneWidget);
      await tester.tap(find.text('始める'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(s.freeLockedWhy(access.needed)), findsOneWidget);
      expect(find.byType(FreePracticeSheet), findsNothing, reason: 'a locked tap opens nothing');
      expect(tester.takeException(), isNull);
      await _capture(tester, 'free_locked_$lang');
      await tester.pump(FreePracticeLayout.lockBalloonLife);
      await tester.pumpWidget(const SizedBox());
    });

    for (final fontScale in [1.1, 1.3]) {
      testWidgets('free practice: the sheet and its pickers fit, customising stops it counting, reset and start '
          '(font scale $fontScale, $lang)', (tester) async {
        final s = S(ja);
        final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
        await onPhone(tester, p, fontScale: fontScale);
        Finder inSheet(String text) => find.descendant(of: find.byType(FreePracticeSheet), matching: find.text(text));
        Future<void> tapAndSettle(Finder target) async {
          await tester.runAsync(() async {
            await tester.tap(target);
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }

        await tapAndSettle(find.text('始める'));
        expect(find.byType(FreePracticeSheet), findsOneWidget);
        expect(inSheet(s.countsTag), findsOneWidget);
        expect(find.text(s.allKnownIslands), findsOneWidget);
        await _capture(tester, 'free_sheet_${lang}_$fontScale');

        await tapAndSettle(find.text(s.cardsRow));
        expect(find.byType(CardPickerScreen), findsOneWidget);
        await _capture(tester, 'free_cards_${lang}_$fontScale');
        final first = poems[fudaSets['initial:${initialGroups[0]}'].poemIds.first];
        await tapAndSettle(find.text(first.kimariji));
        expect(find.text('99/100'), findsOneWidget);
        await tapAndSettle(find.text(s.done));
        expect(p.settings.freePractice.cardIds, isNot(contains(first.id)));
        expect(inSheet(s.customTag), findsOneWidget);
        final islands = archipelago.islands.length;
        expect(find.text(s.islandsOf(islands - 1, islands, partly: 1)), findsOneWidget);
        await _capture(tester, 'free_sheet_custom_${lang}_$fontScale');

        await tapAndSettle(find.text(s.islandsRow));
        expect(find.byType(IslandPickerScreen), findsOneWidget);
        await _capture(tester, 'free_islands_${lang}_$fontScale');
        await tapAndSettle(find.text(s.selectNone));
        expect(find.text('0/100'), findsOneWidget);
        await tapAndSettle(find.byType(InkIconButton));

        await tapAndSettle(find.text(s.lookAlikesRow));
        expect(find.byType(LookAlikePickerScreen), findsOneWidget);
        final set = fudaSets.ofKind(FudaSetKind.confusable).first;
        await tapAndSettle(find.text(poems[set.poemIds.first].kimariji));
        expect(find.text('${set.poemIds.length}/100'), findsOneWidget, reason: 'a set tap adds the whole set');
        await _capture(tester, 'free_look_alikes_${lang}_$fontScale');
        await tapAndSettle(find.text(s.done));
        expect(p.settings.freePractice.cardIds, set.poemIds);

        await tapAndSettle(find.text('3'));
        expect(p.settings.freePractice.maskLevel, 3);
        await tapAndSettle(find.text(s.resetToDefault));
        expect(p.settings.freePractice, const FreePracticeSetup());
        expect(inSheet(s.countsTag), findsOneWidget);

        await tapAndSettle(find.text(s.freeStart));
        final played = tester.widget<PlayScreen>(find.byType(PlayScreen));
        expect(played.cards.length, 100);
        expect(played.config.countsForSrs, isTrue);
        await tester.pumpWidget(const SizedBox());
      });
    }
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

  testWidgets('results: a customised free run says it only went to History; the default one does not',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const s = S(false);
    final p = await open(tester, mode: LearningMode.allKnown);
    final cards = [for (final id in [1, 2, 3]) CardRef(id)];
    for (final (setup, noted) in [(const FreePracticeSetup(cardIds: [1, 2, 3]), true), (const FreePracticeSetup(), false)]) {
      late SessionReport report;
      await tester.runAsync(() async {
        final session = PlaySession(cards);
        var t = const Duration(seconds: 100);
        for (final _ in cards) {
          session.revealed(t);
          t += const Duration(milliseconds: 600);
          session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
          t += const Duration(milliseconds: 100);
        }
        report = await p.recordRun(session, setup.config, DateTime.now());
      });
      await tester.binding.setSurfaceSize(_phone);
      await tester.pumpWidget(ProgressScope(
        progress: p,
        child: MaterialApp(home: ResultsScreen(report: report, config: setup.config)),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text(s.customRunNote), noted ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }
  });

  // Reproduces the toughest-card time badge's seconds overflowing its box and
  // wrapping mid-number ("0.953s" as "0.95"/"3s") at scale 1.1 on a real
  // phone (`_ToughCard` in `results_screen.dart`): the badge must stay one
  // line, shrinking to fit, at any font scale and however long the number.
  for (final scale in [1.1, 1.3]) {
    for (final ja in [false, true]) {
      testWidgets(
          'results: toughest-card time badges stay one line at font scale $scale (${ja ? 'ja' : 'en'})',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final p = await open(tester, mode: LearningMode.allKnown, ja: ja);
        final report = SessionReport(
          sessionId: null,
          total: const Duration(seconds: 30),
          attempts: [
            Attempt(
                index: 0, card: const CardRef(1), responseUs: 12345000, outcome: Outcome.known, at: DateTime(2026), deckSize: 3),
            Attempt(
                index: 1, card: const CardRef(2), responseUs: 1500000, outcome: Outcome.known, at: DateTime(2026), deckSize: 3),
            Attempt(
                index: 2, card: const CardRef(3), responseUs: 953000, outcome: Outcome.known, at: DateTime(2026), deckSize: 3),
          ],
          previousBest: const Duration(seconds: 10),
          ratingBefore: null,
          ratingAfter: null,
          goalRaised: false,
        );
        await tester.binding.setSurfaceSize(_phone);
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(
            progress: p,
            child: MaterialApp(home: ResultsScreen(report: report, config: const PlayConfig(mode: PlayMode.training))),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        for (final time in ['12.345s', '1.500s', '0.953s']) {
          final finder = find.text(time);
          expect(finder, findsOneWidget, reason: '$time badge');
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          // The badge shrinks the whole number+unit to fit instead of
          // wrapping, so its paragraph height must match a single,
          // unbroken line laid out at the same style and scale.
          final oneLine =
              (TextPainter(text: paragraph.text, textDirection: TextDirection.ltr, textScaler: paragraph.textScaler)..layout())
                  .height;
          expect(paragraph.size.height, closeTo(oneLine, 0.5), reason: '$time wrapped onto more than one line');
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('results (journey): no Learn ahead button, it lives on Home', (tester) async {
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
    expect(find.text(const S(false).learnAhead), findsNothing);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'results_journey');
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
      Finder panelOf(String label) => find.ancestor(of: find.text(label), matching: find.byType(MangaPanel)).first;
      expect(tester.getSize(panelOf(s.avgPerCardLabel)).height, tester.getSize(panelOf(s.rating.toUpperCase())).height,
          reason: 'the side-by-side stat panels match in height');
      expect(tester.getSize(find.text('0.620 s', findRichText: true)).height, lessThan(ResultsLayout.statBigFont * 1.3 * 1.5),
          reason: 'the average keeps its unit on the same row');
      await _capture(tester, 'results_pb_${ja ? 'ja' : 'en'}');
      await tester.pump(ResultsLayout.overlayStagger);
      await tester.pump();
      expect(find.byType(CelebrationSequence), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('settings: sounds are on by default, and the Sounds switch turns them off for good', (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    final p = await open(tester);
    expect(p.settings.sounds, isTrue);
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(ProgressScope(progress: p, child: const MaterialApp(home: SettingsScreen())));
    await tester.pump();
    const s = S(false);
    final row = find.ancestor(of: find.text(s.sounds), matching: find.byType(Row));
    await tester.runAsync(() async {
      await tester.tap(find.descendant(of: row.first, matching: find.byType(Switch)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(p.settings.sounds, isFalse);
    expect(AppSettings.fromJson(p.settings.toJson()).sounds, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('debug Simulation: a learner plays on a throwaway database, charted day by day; seeding lives here',
      (tester) async {
    final p = await open(tester, mode: LearningMode.journey);
    final unlocked = p.trainer.unlocked.length;
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(progress: p, child: const MaterialApp(home: SimulationPage())),
    ));
    await tester.tap(find.text(LearnerKind.quick.name));
    final slider = find.byType(Slider);
    await tester.tapAt(tester.getRect(slider).centerLeft);
    await tester.pump();
    await tester.tap(find.text('Simulate'));
    await tester.pump();
    expect(find.textContaining('Simulating'), findsOneWidget);
    for (var i = 0; i < 300 && find.text('Simulate').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    expect(find.text('Simulate'), findsOneWidget, reason: 'the run finished');
    expect(find.text('all 100 cards'), findsOneWidget);
    expect(find.text('Cards unlocked vs pace target'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(p.trainer.unlocked.length, unlocked, reason: "the player's own progress is untouched");
    expect(p.sessions, isEmpty);
    await _capture(tester, 'debug_simulation');
    await tester.scrollUntilVisible(find.text('Seed demo data'), 300);
    expect(find.text('Seed demo data'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // The credits screen lists five fonts plus several other sections in a
  // scrolling column, each row sized to its own content (no fixed heights),
  // so it must hold at a larger system font scale without overflowing.
  testWidgets('settings: Licenses & credits opens the credits screen and a license, at a larger font scale',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.15;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    final p = await open(tester);
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(ProgressScope(progress: p, child: const MaterialApp(home: SettingsScreen())));
    await tester.pump();
    const s = S(false);
    await tester.tap(find.text(s.credits));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CreditsScreen), findsOneWidget);
    expect(find.text(s.creditsFonts), findsOneWidget);
    expect(find.text('Dela Gothic One'), findsOneWidget);

    // Opening a font's full license text exercises the asset-loading path
    // (assets/fonts/*.txt must be declared in pubspec.yaml to be reachable).
    await tester.tap(find.text('Dela Gothic One'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LicenseTextScreen), findsOneWidget);
    expect(find.textContaining('SIL OPEN FONT LICENSE'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

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

      testWidgets('the rank-up stamp sounds as it lands, and never with sounds off ($lang)', (tester) async {
        final heard = _HeardSounds();
        sounds = heard;
        addTearDown(() => sounds = Sounds());
        final p = await open(tester, ja: ja);
        final page = CelebrationSequence(
          pages: [RankUpCelebration(Rating.bands[2], Rating.bands[3], null, Rating.bands[3].minRating)],
          onDone: () {},
        );
        await pumpPage(tester, p, page, RankUpMotion.impactAt - const Duration(milliseconds: 20));
        expect(heard.played, isEmpty);
        await tester.pump(const Duration(milliseconds: 40));
        expect(heard.played, [Sfx.stamp, Sfx.rankUp]);

        await tester.pumpWidget(const SizedBox());
        heard.played.clear();
        await tester.runAsync(() => p.updateSettings(p.settings.copyWith(sounds: false)));
        await pumpPage(tester, p, page, RankUpMotion.length);
        expect(heard.played, isEmpty);
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

/// Records the sounds asked for instead of playing them.
class _HeardSounds extends Sounds {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);
}
