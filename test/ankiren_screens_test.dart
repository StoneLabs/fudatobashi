// Plays 暗記練 through its screens on a phone-sized surface: its settings
// page, the hub's buttons, whole games driven by taps, the layouts, and
// Results. With RENDER_SCREENS=1 it also writes PNGs to build/screens/.
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
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_geometry.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/settings_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_band.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_card.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_field_view.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_results_screen.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_screen.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/debug/ankiren_debug_game.dart';
import 'package:fudatobashi/ui/debug/ankiren_debug_overlay.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/rank/rank_badges.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:fudatobashi/ui/settings/side_trip_settings_screen.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_free_sheet.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

const _phone = Size(384, 832);
const _landscapePhone = Size(832, 384);
const _home = 'home page';

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
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const s = S('en');
  final allCards = [for (final p in poems.all) p.id];

  // Every test hears the sounds asked for instead of playing them (the
  // voice clips would need the audio plugin).
  late _HeardSounds heard;
  final real = sounds;
  setUp(() => sounds = heard = _HeardSounds());
  tearDown(() => sounds = real);

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

  // An all-known player who has taken the tour, with [ankiren] options.
  Future<Progress> open(WidgetTester tester,
      {AnkirenSettings ankiren = const AnkirenSettings(), bool accessibilityMode = false, String language = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(
          p.settings.copyWith(
              language: language,
              languagePicked: true,
              toured: true,
              ankiren: ankiren,
              accessibilityMode: accessibilityMode));
    });
    return p;
  }

  // The user's phone, 384 × 832 at 2.8125 px per dp with its system bars,
  // turned to [size].
  void phone(WidgetTester tester, {Size size = _phone, double fontScale = 1}) {
    const dpr = 2.8125;
    final bars = size.width < size.height
        ? const FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr)
        : const FakeViewPadding(left: 28 * dpr, right: 48 * dpr);
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = size * dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  // A game of [setup] on [p]'s settings, straight on screen.
  Future<void> play(WidgetTester tester, Progress p, AnkirenSetup setup,
      {Size size = _phone, double fontScale = 1, bool tracked = true, int seed = 1}) async {
    phone(tester, size: size, fontScale: fontScale);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(
        progress: p,
        child: MaterialApp(navigatorKey: navigator, home: const Scaffold(body: Text(_home))),
      ),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => AnkirenScreen(setup: setup, known: allCards, tracked: tracked, seed: seed)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }

  Finder cardOf(int poemId) => find.byWidgetPredicate((w) => w is AnkirenCard && w.poemId == poemId);
  AnkirenCard card(WidgetTester tester, int poemId) => tester.widget<AnkirenCard>(cardOf(poemId));
  List<AnkirenCard> cards(WidgetTester tester) => tester.widgetList<AnkirenCard>(find.byType(AnkirenCard)).toList();

  // The card the band asks for.
  int asked(WidgetTester tester) {
    final text = tester.widget<PromptText>(find.byType(PromptText)).text;
    return poems.all.firstWhere((p) => s.kimariji(p.id) == text || p.kimariji == text).id;
  }

  // Ready: the field turns face down and the first prompt shows.
  Future<void> ready(WidgetTester tester) async {
    await tester.tap(find.text(s.ankirenReady));
    await tester.pump();
    await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  Future<void> take(WidgetTester tester, int poemId) async {
    await tester.tap(cardOf(poemId), warnIfMissed: false);
    await tester.pump();
  }

  // Waits out the pause before the next prompt.
  Future<void> next(WidgetTester tester) async {
    await tester.pump(AnkirenPlayTuning.promptPause);
    await tester.pump();
  }

  // The last card is found: the game is recorded and Results come in.
  Future<void> toResults(WidgetTester tester) async {
    await tester.pump(AnkirenPlayTuning.finishPause);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(tester.takeException(), isNull);
  }

  group('Settings', () {
    for (final fontScale in [1.1, 1.3]) {
      testWidgets('the 寄り道 section opens 暗記練\'s page, whose choices stick (font scale $fontScale)',
          (tester) async {
        PackageInfo.setMockInitialValues(
            appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
        final p = await open(tester);
        phone(tester, fontScale: fontScale);
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(progress: p, child: const MaterialApp(home: SettingsScreen())),
        ));
        await tester.pump();
        await tester.scrollUntilVisible(find.text(s.ankirenName), 200);
        expect(find.text(s.sideTrips.toUpperCase()), findsOneWidget, reason: 'the section header');
        await tester.tap(find.text(s.ankirenName));
        await tester.pump();
        await tester.pump(Motion.route);
        expect(find.byType(AnkirenSettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        final page = find.descendant(of: find.byType(AnkirenSettingsScreen), matching: find.byType(Scrollable));
        for (final note in [s.ankirenLayoutNote, s.ankirenPromptNote]) {
          await tester.scrollUntilVisible(find.text(note), 100, scrollable: page);
          expect(find.text(note), findsOneWidget);
        }
        await _capture(tester, 'ankiren_settings_$fontScale');

        Future<void> choose(String label) async {
          await tester.scrollUntilVisible(find.text(label), 100, scrollable: page);
          await tester.runAsync(() async {
            await tester.tap(find.text(label));
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump();
        }

        await choose(s.ankirenLandscape);
        await choose(s.ankirenPromptText);
        final a = p.settings.ankiren;
        expect([a.layout, a.prompt], [AnkirenLayout.landscape, AnkirenPrompt.textOnly]);
        expect(find.descendant(of: find.byType(AnkirenSettingsScreen), matching: find.text(s.accessibilityMode)),
            findsNothing,
            reason: 'accessibility is app-wide, not 暗記練\'s');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Accessibility mode is its own top-level section, and its switch sticks (font scale $fontScale)',
          (tester) async {
        PackageInfo.setMockInitialValues(
            appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
        final p = await open(tester);
        phone(tester, fontScale: fontScale);
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(progress: p, child: const MaterialApp(home: SettingsScreen())),
        ));
        await tester.pump();
        await tester.scrollUntilVisible(find.text(s.accessibilityModeNote), 200);
        await tester.ensureVisible(find.text(s.sectionAccessibility.toUpperCase()));
        await tester.pump();
        expect(p.settings.accessibilityMode, isFalse);
        await tester.runAsync(() async {
          await tester.tap(find.text(s.accessibilityMode));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(p.settings.accessibilityMode, isTrue);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'settings_accessibility_$fontScale');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Side Trips hub', () {
    Future<void> openHub(WidgetTester tester, Progress p) async {
      phone(tester, fontScale: 1.1);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.sideTrips)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('ranked starts a level-0 game at 入門, portrait', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      final p = await open(tester);
      await openHub(tester, p);
      await tester.tap(find.text(s.sideTripRankedSub));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenScreen), findsOneWidget);
      expect(find.byType(AnkirenCard), findsNWidgets(AnkirenLevels.of(0).cards));
      expect(find.text(formatMinutes(AnkirenLevels.of(0).memorise)), findsOneWidget);
      final orientations = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations');
      expect(orientations.last.arguments, ['DeviceOrientation.portraitUp'], reason: 'portrait is held while playing');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('free play opens its sheet, whose custom setup sticks and starts', (tester) async {
      final p = await open(tester);
      await openHub(tester, p);
      await tester.tap(find.text(s.freePlay));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(AnkirenFreeSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'ankiren_free_sheet');

      await tester.runAsync(() async {
        await tester.tap(find.text(s.ankirenCustom));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() async {
          await tester.tap(find.text('+').first);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();
      }
      expect(p.settings.ankiren.freeSetup,
          AnkirenSetup.custom(perSide: DefaultSettings.ankirenCustomPerSide + 3, memorise: DefaultSettings.ankirenCustomMemorise));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(s.freeStart));
      await tester.pump();
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenScreen), findsOneWidget);
      expect(find.byType(AnkirenCard), findsNWidgets(2 * (DefaultSettings.ankirenCustomPerSide + 3)));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('A game', () {
    testWidgets('level 0, by taps: memorise, ready, every card found, recorded, then Results', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      expect(cards(tester).every((c) => c.faceUp), isTrue, reason: 'memorise: the field is face up');
      expect(cards(tester).where((c) => c.inverted).length, AnkirenLevels.of(0).perSide,
          reason: "the opponent's cards are upside down");
      await _capture(tester, 'ankiren_memorise');

      await tester.pump(const Duration(seconds: 3));
      final left = AnkirenLevels.of(0).memorise - const Duration(seconds: 3);
      expect(find.text(formatMinutes(left)), findsOneWidget, reason: 'the clock counts down');
      await ready(tester);
      expect(cards(tester).any((c) => c.faceUp), isFalse, reason: 'recall: every card face down');
      expect(heard.played, containsAllInOrder([Sfx.ankirenFlip, Sfx.ankirenRecall]),
          reason: 'the field turns over, then recall starts');
      await _capture(tester, 'ankiren_recall');

      final total = AnkirenLevels.of(0).cards;
      for (var i = 0; i < total; i++) {
        final id = asked(tester);
        expect(card(tester, id).faceUp, isFalse);
        await take(tester, id);
        expect(card(tester, id).faceUp, isTrue, reason: 'a right tap turns the card up');
        expect(card(tester, id).flash?.kind, CardFeedback.right);
        if (i < total - 1) await next(tester);
      }
      expect(heard.played.where((x) => x == Sfx.ankirenTake).length, total);
      expect(heard.played.where((x) => x == Sfx.ankirenRecall).length, 1);
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(p.sideTrips.rankedGames(SideTrip.ankiren), 1, reason: 'the ranked game was recorded');
      expect(find.text(s.ankirenWrongTaps(0)), findsOneWidget);
      expect(find.byType(ClassBadge), findsOneWidget, reason: "a ranked game shows the rating's class");
      expect(find.text(s.ankirenPlacement(1, AnkirenRatingModel.placementGames)), findsOneWidget);
      expect(find.text(s.ankirenNextLevel(p.sideTripsHub()[SideTrip.ankiren].rankedLevel!)), findsOneWidget);
      expect(find.text(s.again), findsOneWidget);
      await _capture(tester, 'ankiren_results');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wrong tap turns nothing over; two reveal the card, which still has to be taken', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), tracked: false);
      await ready(tester);
      final id = asked(tester);
      final others = cards(tester).map((c) => c.poemId).where((x) => x != id).toList();

      await take(tester, others[0]);
      expect(card(tester, others[0]).faceUp, isFalse, reason: 'a wrong tap shows nothing');
      expect(card(tester, others[0]).flash?.kind, CardFeedback.wrong);
      expect(card(tester, id).revealed, isFalse);
      expect(heard.played, contains(Sfx.ankirenWrong));
      await tester.pump(AnkirenMotion.wrongFlash ~/ 3);
      await _capture(tester, 'ankiren_wrong');
      await tester.pump(AnkirenMotion.wrongFlash);

      await take(tester, others[1]);
      expect(card(tester, id).revealed, isTrue, reason: 'two wrong taps reveal the card asked for');
      expect(card(tester, id).faceUp, isFalse);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      await take(tester, id);
      expect(card(tester, id).faceUp, isTrue);
      expect(card(tester, id).revealed, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ending in memorise leaves without recording; ending in recall records and shows Results',
        (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      await tester.tap(find.text(s.end));
      await tester.pump();
      await tester.pump(Motion.routeReverse);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(find.text(_home), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.pumpWidget(const SizedBox());

      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      await ready(tester);
      await take(tester, asked(tester));
      await tester.tap(find.text(s.end));
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(find.text(s.endedEarly), findsOneWidget);
      expect(p.sideTrips.runs.single.completed, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the back gesture records a game once recall has begun, and leaves Home in place', (tester) async {
      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        expect(find.byType(AnkirenScreen), findsNothing);
        expect(find.byType(AnkirenResultsScreen), findsNothing);
        expect(find.text(_home), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      await ready(tester);
      await take(tester, asked(tester));
      await back();
      expect(p.sideTrips.runs.single.completed, isFalse, reason: 'left mid-game: the rest count as missed');
      await tester.pumpWidget(const SizedBox());

      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      await ready(tester);
      final total = AnkirenLevels.of(0).cards;
      for (var i = 0; i < total; i++) {
        await take(tester, asked(tester));
        if (i < total - 1) await next(tester);
      }
      await back();
      expect(p.sideTrips.runs, hasLength(2), reason: 'left in the pause before Results');
      expect(p.sideTrips.runs.last.completed, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the test game records nothing, and Results offer it again', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), tracked: false);
      await ready(tester);
      for (var i = 0; i < AnkirenLevels.of(0).cards; i++) {
        await take(tester, asked(tester));
        await next(tester);
      }
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.tap(find.text(s.again));
      await tester.pump();
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("don't know shows the card like the wrong taps do, turns it up for nothing, and moves on",
        (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      final giveUp = find.widgetWithText(BandButton, s.ankirenForgot);
      expect(giveUp, findsNothing, reason: 'memorise has Ready there instead');
      await ready(tester);
      expect(giveUp, findsOneWidget);

      final id = asked(tester);
      await tester.tap(giveUp);
      await tester.pump();
      expect(card(tester, id).revealed, isTrue, reason: 'shown as after two wrong taps');
      expect(card(tester, id).faceUp, isFalse);
      final prompt = tester.widget<PromptText>(find.byType(PromptText));
      expect((prompt.state, prompt.done), (PromptState.givenUp, 1));
      expect(tester.widget<BandButton>(giveUp).onTap, isNull, reason: 'nothing asked until the next prompt');
      await tester.tap(cardOf(id), warnIfMissed: false);
      await tester.pump();
      expect(heard.played, isNot(contains(Sfx.ankirenTake)), reason: 'a card given up cannot be taken');

      await tester.pump(AnkirenPlayTuning.givenUpReveal);
      expect((card(tester, id).faceUp, card(tester, id).revealed), (true, false), reason: 'then it turns up');
      await next(tester);
      expect(asked(tester), isNot(id));
      expect(tester.widget<PromptText>(find.byType(PromptText)).state, PromptState.asked);

      for (var i = 1; i < AnkirenLevels.of(0).cards; i++) {
        await take(tester, asked(tester));
        await next(tester);
      }
      await toResults(tester);
      final run = p.sideTrips.runs.single;
      expect(run.completed, isTrue, reason: 'giving up a card still finishes the game');
      final answers = await tester.runAsync(() => p.db.select(p.db.sideTripAnswers).get());
      final given = answers!.singleWhere((a) => a.poemId == id);
      expect((given.responseUs, given.wrongTaps), (null, 0), reason: 'the card given up earns nothing');
      expect(p.sideTrips.missesIn(run), 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the debug game: its bar switches the level and reseeds at once; its layers toggle', (tester) async {
      final p = await open(tester);
      phone(tester);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(progress: p, child: MaterialApp(home: AnkirenDebugGame(known: allCards))),
      ));
      await tester.pump();
      expect(cards(tester), hasLength(AnkirenLevels.of(0).cards));
      expect(find.byType(AnkirenDebugOverlay), findsOneWidget);

      Future<void> tapBar(String label) async {
        await tester.tap(find.descendant(of: find.byType(AnkirenDebugGame), matching: find.text(label)).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await tapBar('7');
      expect(cards(tester), hasLength(AnkirenLevels.of(7).cards), reason: 'a new field at once');
      await _capture(tester, 'ankiren_debug_l7');
      final dealt = {for (final c in cards(tester)) c.poemId};
      await tapBar('reseed');
      expect({for (final c in cards(tester)) c.poemId}, isNot(dealt));
      await ready(tester);
      expect(cards(tester).any((c) => c.faceUp), isFalse, reason: 'it plays like a real game');

      for (final layer in AnkirenDebugLayer.values) {
        await tapBar(layer.name);
      }
      expect(find.byType(AnkirenDebugOverlay), findsNothing);
      expect(p.sideTrips.runs, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('opponent cards are always upside down; text-only prompts play no voice', (tester) async {
      final p = await open(tester, ankiren: const AnkirenSettings(prompt: AnkirenPrompt.textOnly));
      await play(tester, p, AnkirenSetup.forLevel(0), tracked: false);
      expect(cards(tester).where((c) => c.inverted).length, AnkirenLevels.of(0).perSide);
      await ready(tester);
      expect(find.byType(KimarijiSpeakerButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Layouts', () {
    // Every card inside the screen (or, panning, inside the field) and no
    // two overlapping.
    void expectLaidOut(WidgetTester tester, Size size) {
      expect(tester.takeException(), isNull);
      final rects = [for (final c in find.byType(AnkirenCard).evaluate()) tester.getRect(find.byWidget(c.widget))];
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j].deflate(0.5)), isFalse, reason: 'cards $i and $j overlap');
        }
      }
      final band = tester.getRect(find.byType(AnkirenBand));
      for (final r in rects) {
        expect(r.overlaps(band.deflate(1)), isFalse, reason: 'no card under the band');
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(size.height));
      }
    }

    for (final fontScale in [1.1, 1.3]) {
      testWidgets('portrait, level 10, memorise and recall, font scale $fontScale', (tester) async {
        final p = await open(tester);
        await play(tester, p, AnkirenSetup.forLevel(AnkirenLevels.top), fontScale: fontScale, tracked: false);
        expectLaidOut(tester, _phone);
        for (final c in find.byType(AnkirenCard).evaluate()) {
          expect(tester.getSize(find.byWidget(c.widget)).width, lessThanOrEqualTo(AnkirenPlayLayout.maxCardW + 0.01));
        }
        await _capture(tester, 'ankiren_portrait_l10_$fontScale');
        await ready(tester);
        expectLaidOut(tester, _phone);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a small folded field still spans the screen: its middles open up',
        (tester) async {
      final p = await open(tester);
      for (final level in [0, 3, 5]) {
        await play(tester, p, AnkirenSetup.forLevel(level), tracked: false, seed: level);
        expectLaidOut(tester, _phone);
        final rects = [for (final c in find.byType(AnkirenCard).evaluate()) tester.getRect(find.byWidget(c.widget))];
        final left = rects.map((r) => r.left).reduce(math.min), right = rects.map((r) => r.right).reduce(math.max);
        if (level == 0) {
          expect(left, greaterThan(AnkirenPlayLayout.padding + 1), reason: "a beginner's row is spread evenly");
        } else {
          expect(left, moreOrLessEquals(AnkirenPlayLayout.padding, epsilon: 0.5), reason: 'level $level');
          expect(right, moreOrLessEquals(_phone.width - AnkirenPlayLayout.padding, epsilon: 0.5), reason: 'level $level');
        }
        expect(rects.first.width, lessThanOrEqualTo(AnkirenPlayLayout.maxCardW + 0.01));
        await _capture(tester, 'ankiren_spread_l$level');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('accessibility mode zooms portrait: cards stay tappable, the field pans, starting centred',
        (tester) async {
      final p = await open(tester, accessibilityMode: true);
      await play(tester, p, AnkirenSetup.forLevel(AnkirenLevels.top), tracked: false);
      expect(tester.takeException(), isNull);
      for (final c in find.byType(AnkirenCard).evaluate()) {
        expect(tester.getSize(find.byWidget(c.widget)).width,
            greaterThanOrEqualTo(AnkirenPlayLayout.minTapCardW - 0.01));
      }
      final pan = tester.widget<SingleChildScrollView>(find.descendant(
          of: find.byType(AnkirenFieldView), matching: find.byType(SingleChildScrollView)));
      final position = pan.controller!.position;
      expect(position.pixels, moreOrLessEquals(position.maxScrollExtent / 2, epsilon: 1), reason: 'starts centred');
      await _capture(tester, 'ankiren_zoom');

      // A drag pans the field and takes no card.
      await ready(tester);
      final id = asked(tester);
      final before = position.pixels;
      final onScreen = find.byType(AnkirenCard).evaluate().map((c) => tester.getRect(find.byWidget(c.widget)));
      final from = onScreen.firstWhere((r) => r.left > 0 && r.right < _phone.width).center;
      await tester.dragFrom(from, const Offset(-120, 0));
      await tester.pump();
      expect(position.pixels, isNot(before));
      expect(cards(tester).any((c) => c.flash != null), isFalse, reason: 'a drag is no tap');
      expect(card(tester, id).faceUp, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    for (final level in [0, AnkirenLevels.top]) {
      testWidgets('landscape true-scale field, level $level, holds landscape and lets go after', (tester) async {
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
        final p = await open(tester, ankiren: const AnkirenSettings(layout: AnkirenLayout.landscape));
        await play(tester, p, AnkirenSetup.forLevel(level), size: _landscapePhone, fontScale: 1.3, tracked: false);
        expectLaidOut(tester, _landscapePhone);
        await _capture(tester, 'ankiren_landscape_l$level');
        await ready(tester);
        expectLaidOut(tester, _landscapePhone);
        final orientations = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').toList();
        expect(orientations.first.arguments, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
        await tester.pumpWidget(const SizedBox());
        final after = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').last;
        expect(after.arguments, isEmpty, reason: 'leaving lets the app turn freely again');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
    }

    testWidgets('scale: portrait cards are at most maxCardW wide, landscape fits the true field', (tester) async {
      final field = AnkirenDealer.ofPoems().deal(allCards, AnkirenLevels.of(0).perSide, math.Random(3));
      final folded = FieldGeometry.of(field, folded: true);
      const roomy = Size(2000, 3000);
      final s = AnkirenFieldView.scaleFor(folded, roomy, landscape: false, zoom: false);
      expect(s * AnkirenFieldSize.cardW, moreOrLessEquals(AnkirenPlayLayout.maxCardW));
      final trueScale = FieldGeometry.of(field, folded: false);
      final wide = AnkirenFieldView.scaleFor(trueScale, roomy, landscape: true, zoom: true);
      expect(wide, moreOrLessEquals(roomy.width / AnkirenFieldSize.territoryW), reason: 'landscape fills the width');
    });
  });

  group('Font scale 1.3', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('the free-play sheet and a ranked game\'s Results fit ($lang)', (tester) async {
        final t = S(lang);
        final p = await open(tester, language: lang);
        phone(tester, fontScale: 1.3);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(t.sideTrips)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(t.freePlay));
        await tester.pump();
        await tester.tap(find.text(t.freePlay));
        await tester.pump();
        await tester.pump(Motion.sheet);
        expect(find.byType(AnkirenFreeSheet), findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(find.text(t.ankirenCustom));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        await _capture(tester, 'ankiren_free_sheet_${lang}_1.3');
        await tester.pumpWidget(const SizedBox());

        await play(tester, p, AnkirenSetup.forLevel(0, ranked: true), fontScale: 1.3);
        await tester.tap(find.text(t.ankirenReady));
        await tester.pump();
        await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
        await tester.pump();
        final total = AnkirenLevels.of(0).cards;
        for (var i = 0; i < total; i++) {
          await take(tester, asked(tester));
          if (i < total - 1) await next(tester);
        }
        await toResults(tester);
        expect(find.byType(AnkirenResultsScreen), findsOneWidget);
        expect(find.byType(ClassBadge), findsOneWidget);
        await _capture(tester, 'ankiren_results_${lang}_1.3');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Reduced motion', () {
    testWidgets('no turn or shake: cards change face at once, a revealed card gets a steady outline', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), tracked: false);
      await tester.tap(find.text(s.ankirenReady));
      await tester.pump();
      await tester.pump(AnkirenPlayTuning.promptPause);
      await tester.pump();
      final id = asked(tester);
      final others = cards(tester).map((c) => c.poemId).where((x) => x != id).toList();
      await take(tester, others[0]);
      await take(tester, others[1]);
      expect(card(tester, id).revealed, isTrue);
      expect(find.descendant(of: cardOf(id), matching: find.byType(Shake)), findsNothing);
      await tester.pump(AnkirenMotion.wrongFlash);
      expect(tester.hasRunningAnimations, isFalse, reason: 'nothing moves once the tint is gone');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// Records the sounds asked for instead of playing them.
class _HeardSounds extends Sounds {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}
