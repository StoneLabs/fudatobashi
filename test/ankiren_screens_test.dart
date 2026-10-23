// Plays 暗記練 through its screens on a phone-sized surface: its settings
// page, the hub's buttons, whole games driven by taps, the layouts, and
// Results. With RENDER_SCREENS=1 it also writes PNGs to build/screens/.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_geometry.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/rating.dart';
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
import 'package:fudatobashi/ui/ankiren/ankiren_strikes.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/debug/ankiren_debug_game.dart';
import 'package:fudatobashi/ui/debug/ankiren_debug_overlay.dart';
import 'package:fudatobashi/ui/debug/ankiren_score_readout.dart';
import 'package:fudatobashi/ui/debug/ankiren_tools_page.dart';
import 'package:fudatobashi/ui/debug/ankiren_graphs.dart';
import 'package:fudatobashi/ui/debug/debug_common.dart';
import 'package:fudatobashi/ui/debug/play_overlay.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/rank/rank_badges.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:fudatobashi/ui/settings/side_trip_settings_screen.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_free_sheet.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'db_snapshot.dart';
import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

const _home = 'home page';

/// How long a card takes to find in the games that render Results with times.
const _findTime = Duration(milliseconds: 800);

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
  const s = S('en');
  final allCards = [for (final p in poems.all) p.id];

  // Every test hears the sounds asked for instead of playing them (the
  // voice clips would need the audio plugin).
  late _HeardSounds heard;
  final real = sounds;
  setUp(() => sounds = heard = _HeardSounds());
  tearDown(() => sounds = real);

  setUpAll(() async {
    await loadRenderMonoFont();
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

  // Records a cleared game at every level up to [level] for [p].
  Future<void> clearUpTo(WidgetTester tester, Progress p, int level) => tester.runAsync(() async {
        for (var l = 0; l <= level; l++) {
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(l), strikes: true), startedAt: DateTime.now());
        }
      });

  // A game of [setup] on [p]'s settings, straight on screen.
  Future<void> play(WidgetTester tester, Progress p, AnkirenSetup setup,
      {Screen screen = usersPhone, double fontScale = 1, AnkirenPlayer player = AnkirenPlayer.owner, int seed = 1}) async {
    useScreen(tester, screen, fontScale: fontScale);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(
        progress: p,
        child: MaterialApp(navigatorKey: navigator, theme: buildMangaTheme(), home: const Scaffold(body: Text(_home))),
      ),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => AnkirenScreen(setup: setup, known: allCards, player: player, seed: seed)));
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

  Future<void> take(WidgetTester tester, int poemId, {Duration think = Duration.zero}) async {
    if (think > Duration.zero) await tester.pump(think);
    // Stamped at the current frame, as a finger down after the prompt's reveal.
    final gesture = await tester.createGesture();
    await gesture.down(tester.getCenter(cardOf(poemId)), timeStamp: SchedulerBinding.instance.currentSystemFrameTimeStamp);
    await gesture.up();
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
        useScreen(tester, usersPhone, fontScale: fontScale);
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
        await captureScreen(tester, 'ankiren_settings');

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
        useScreen(tester, usersPhone, fontScale: fontScale);
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
        await captureScreen(tester, 'settings_accessibility');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Side Trips hub', () {
    Future<void> openHub(WidgetTester tester, Progress p) async {
      useScreen(tester, usersPhone, fontScale: 1.1);
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.sideTrips)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('ranked starts its one setup, a real match\'s field, in portrait once it opens', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      final p = await open(tester, ankiren: const AnkirenSettings(rulesSeen: true));
      await clearUpTo(tester, p, AnkirenTuning.rankedAfterLevel);
      await openHub(tester, p);
      await tester.tap(find.byType(PageBurst));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      await tester.tap(find.byType(RankedBurst));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenScreen), findsOneWidget);
      expect(find.byType(AnkirenCard), findsNWidgets(2 * AnkirenTuning.rankedPerSide));
      expect(
          find.descendant(
              of: find.byType(AnkirenScreen), matching: find.text(formatMinutes(AnkirenTuning.rankedMemorise))),
          findsOneWidget);
      final orientations = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations');
      expect(orientations.last.arguments, ['DeviceOrientation.portraitUp'], reason: 'portrait is held while playing');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('free play opens its sheet, whose custom setup sticks and starts', (tester) async {
      final p = await open(tester, ankiren: const AnkirenSettings(rulesSeen: true));
      await clearUpTo(tester, p, AnkirenTuning.customAfterLevel);
      await openHub(tester, p);
      await tester.tap(find.text(s.ankirenPageTitle));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenAllLevels));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(AnkirenFreeSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureScreen(tester, 'ankiren_free_sheet');

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
      await play(tester, p, AnkirenSetup.forLevel(0));
      expect(find.byType(AnkirenStrikes), findsNothing, reason: 'the strikes show once the cards are face down');
      expect(cards(tester).every((c) => c.faceUp), isTrue, reason: 'memorise: the field is face up');
      expect(cards(tester).where((c) => c.inverted).length, AnkirenLevels.of(0).perSide,
          reason: "the opponent's cards are upside down");
      await captureScreen(tester, 'ankiren_memorise');

      await tester.pump(const Duration(seconds: 3));
      final left = AnkirenLevels.of(0).memorise - const Duration(seconds: 3);
      expect(find.text(formatMinutes(left)), findsOneWidget, reason: 'the clock counts down');
      await ready(tester);
      expect(cards(tester).any((c) => c.faceUp), isFalse, reason: 'recall: every card face down');
      expect(heard.played, containsAllInOrder([Sfx.ankirenFlip, Sfx.ankirenRecall]),
          reason: 'the field turns over, then recall starts');
      expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 0);
      await captureScreen(tester, 'ankiren_recall');

      final total = AnkirenLevels.of(0).cards;
      for (var i = 0; i < total; i++) {
        final id = asked(tester);
        expect(card(tester, id).faceUp, isFalse);
        await take(tester, id, think: Duration(milliseconds: 500 + 150 * i));
        expect(card(tester, id).faceUp, isTrue, reason: 'a right tap turns the card up');
        expect(card(tester, id).flash?.kind, CardFeedback.right);
        if (i < total - 1) await next(tester);
      }
      expect(heard.played.where((x) => x == Sfx.ankirenTake).length, total);
      expect(heard.played.where((x) => x == Sfx.ankirenRecall).length, 1);
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(p.sideTrips.runs.single.level, 0, reason: 'the game was recorded');
      expect(find.text(s.ankirenWrongTaps(0)), findsOneWidget);
      expect(find.text(s.ankirenLevelCleared(0)), findsWidgets, reason: 'played out with no strike');
      expect(find.byType(ClearedCheck), findsOneWidget);
      expect(p.sideTripsHub()[SideTrip.ankiren].ladder.open, 1);
      expect(find.text(s.ankirenBackToPage), findsOneWidget);
      await captureScreen(tester, 'ankiren_results');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wrong tap turns nothing over; two reveal the card, which still has to be taken', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.developer);
      await ready(tester);
      final id = asked(tester);
      final others = cards(tester).map((c) => c.poemId).where((x) => x != id).toList();

      await take(tester, others[0]);
      expect(card(tester, others[0]).faceUp, isFalse, reason: 'a wrong tap shows nothing');
      expect(card(tester, others[0]).flash?.kind, CardFeedback.wrong);
      expect(card(tester, id).revealed, isFalse);
      expect(heard.played, contains(Sfx.ankirenWrong));
      await tester.pump(AnkirenMotion.wrongFlash ~/ 3);
      await captureScreen(tester, 'ankiren_wrong');
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

    testWidgets("dev mode's play overlay tells how the last card scored, tap by tap", (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.developer);
      expect(find.byType(AnkirenScoreReadout), findsNothing, reason: 'off unless asked for');
      await tester.pumpWidget(const SizedBox());

      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(debugMode: true, playOverlay: true)));
      await play(tester, p, const AnkirenSetup.ranked(), player: AnkirenPlayer.developer);
      expect(find.text('none answered yet'), findsOneWidget);
      await ready(tester);
      final id = asked(tester);
      await take(tester, cards(tester).map((c) => c.poemId).firstWhere((x) => x != id));
      await tester.pump(AnkirenMotion.wrongFlash);
      await take(tester, id);
      final game = tester.widget<AnkirenScoreReadout>(find.byType(AnkirenScoreReadout)).game;
      final a = game.answers.single;
      final first = a.taps.first;
      final firstPoints = (AnkirenTuning.cardPoints * AnkirenTuning.tapShare[first]!).round();
      final rows = [for (final r in AnkirenScoreReadout.rows(game)) [r.label, r.value]];
      expect(rows, containsAllInOrder([
        ['CARD', '#$id ${poems[id].kimariji}'],
        ['result', 'found on tap 2'],
        ['TAP 1', first.name],
        ['speed', '0, not the card'],
        ['TAP 2', 'card'],
        ['points', '1 × 100 = 100'],
        ['SUM', '$firstPoints + 0.2 × 100 = ${AnkirenScore.points(a)}'],
        ['GAME', '${AnkirenScore.points(a)} / ${AnkirenScore.maxFor(game.prompts.length)}'],
      ]));
      for (final [label, value] in rows) {
        expect(find.text(label), findsWidgets);
        expect(find.text(value), findsWidgets);
      }
      final panel = tester.getRect(find.byType(DebugTable));
      expect(tester.widget<DebugTable>(find.byType(DebugTable)).columns, hasLength(2),
          reason: 'two tables side by side in portrait, to keep it short');
      expect(panel.bottom, lessThanOrEqualTo(tester.getTopLeft(find.byType(AnkirenFieldView)).dy),
          reason: 'its own strip above the field');
      for (final c in tester.widgetList<AnkirenCard>(find.byType(AnkirenCard))) {
        expect(tester.getRect(find.byWidget(c)).overlaps(panel), isFalse, reason: 'it never hides a card');
      }
      expect(find.ancestor(of: find.byType(DebugTable), matching: find.byType(IgnorePointer)), findsWidgets,
          reason: 'every tap goes through');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ending in memorise leaves without recording; ending in recall records and shows Results',
        (tester) async {
      final p = await open(tester);
      await play(tester, p, const AnkirenSetup.ranked());
      await tester.tap(find.text(s.end));
      await tester.pump();
      await tester.pump(Motion.routeReverse);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(find.text(_home), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.pumpWidget(const SizedBox());

      await play(tester, p, const AnkirenSetup.ranked());
      await ready(tester);
      await take(tester, asked(tester));
      await tester.tap(find.text(s.end));
      await tester.pump();
      await tester.tap(find.text(s.ankirenLeave));
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(find.text(s.endedEarly), findsOneWidget);
      expect(p.sideTrips.runs.single.completed, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the back gesture forfeits a ranked game in recall after asking, and leaves Home in place',
        (tester) async {
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await settle();
      }

      void expectHome() {
        expect(find.byType(AnkirenScreen), findsNothing);
        expect(find.byType(AnkirenResultsScreen), findsNothing);
        expect(find.text(_home), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      final p = await open(tester);
      await play(tester, p, const AnkirenSetup.ranked());
      await back();
      expectHome();
      expect(p.sideTrips.runs, isEmpty, reason: 'leaving in memorise records nothing');
      await tester.pumpWidget(const SizedBox());

      await play(tester, p, const AnkirenSetup.ranked());
      await ready(tester);
      await take(tester, asked(tester));
      await back();
      expect(find.text(s.ankirenLeaveNote), findsOneWidget, reason: 'recall: leaving asks first');
      await tester.tap(find.text(s.cancel));
      await settle();
      expect(find.byType(AnkirenScreen), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.binding.handlePopRoute();
      await settle();
      await tester.tap(find.text(s.ankirenLeave));
      await toResults(tester);
      final run = p.sideTrips.runs.single;
      expect(run.completed, isFalse);
      expect(run.score, greaterThan(0), reason: 'the card found counts');
      expect(run.performance, isNotNull, reason: 'a forfeit is rated like a finished game');
      expect(run.rating, isNotNull);
      expect(p.sideTrips.rankedGames(SideTrip.ankiren), 1);
      await tester.pumpWidget(const SizedBox());

      await play(tester, p, const AnkirenSetup.ranked());
      await ready(tester);
      const total = 2 * AnkirenTuning.rankedPerSide;
      for (var i = 0; i < total; i++) {
        await take(tester, asked(tester));
        if (i < total - 1) await next(tester);
      }
      await back();
      expectHome();
      expect(p.sideTrips.runs, hasLength(2), reason: 'left in the pause before Results');
      expect(p.sideTrips.runs.last.completed, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('free play is left at any time with nothing recorded', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0));
      await ready(tester);
      await take(tester, asked(tester));
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.text(s.ankirenLeaveNote), findsNothing, reason: 'free play does not ask');
      expect(find.text(_home), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the test game records nothing, and Results offer it again', (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.developer);
      await ready(tester);
      for (var i = 0; i < AnkirenLevels.of(0).cards; i++) {
        await take(tester, asked(tester));
        await next(tester);
      }
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(p.sideTrips.runs, isEmpty);
      await tester.tap(find.text(s.ankirenBackToPage));
      await tester.pump();
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenResultsScreen), findsNothing);
      expect(find.text(_home), findsOneWidget, reason: 'back to where the game was started from');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("don't know shows the card like the wrong taps do, turns it up for nothing, and moves on",
        (tester) async {
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0));
      final giveUp = find.widgetWithText(BandButton, s.ankirenDontKnow);
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

    for (final landscape in [false, true]) {
      final turned = landscape ? 'landscape' : 'portrait';
      testWidgets('a free level goes on past its third strike, and Results say the level failed ($turned)',
          (tester) async {
        final p = await open(tester,
            ankiren: AnkirenSettings(layout: landscape ? AnkirenLayout.landscape : AnkirenLayout.portrait));
        await play(tester, p, AnkirenSetup.forLevel(1), screen: landscape ? usersPhoneLandscape : usersPhone);
        await ready(tester);
        final shot = landscape ? 'ankiren_strikes_landscape' : 'ankiren_strikes';
        expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 0);
        await captureScreen(tester, shot, variant: 's0');
        Future<void> strike() async {
          final id = asked(tester);
          await take(tester, cards(tester).map((c) => c.poemId).firstWhere((x) => x != id && !card(tester, x).faceUp));
        }

        await strike();
        expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 1);
        await tester.pump(AnkirenMotion.strike ~/ 2);
        await captureScreen(tester, landscape ? 'ankiren_strike_landing_landscape' : 'ankiren_strike_landing');
        await tester.pump(AnkirenMotion.strike);
        await captureScreen(tester, shot, variant: 's1');
        await tester.tap(find.widgetWithText(BandButton, s.ankirenDontKnow));
        await tester.pump();
        expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 2, reason: "don't know is a strike");
        expect(heard.played.where((x) => x == Sfx.ankirenWrong), hasLength(2));
        await tester.pump(AnkirenMotion.strike);
        await captureScreen(tester, shot, variant: 's2');
        await tester.pump(AnkirenPlayTuning.givenUpReveal);
        await next(tester);
        await strike();
        await tester.pump(AnkirenMotion.strike);
        await captureScreen(tester, shot, variant: 's3');
        expect(find.byType(AnkirenScreen), findsOneWidget, reason: 'the third strike does not end the game');
        await strike();
        await tester.pump(AnkirenMotion.strike);
        expect(heard.played.where((x) => x == Sfx.ankirenWrong), hasLength(4), reason: 'later strikes still sound');
        expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 4);
        for (var i = 1; i < AnkirenLevels.of(1).cards; i++) {
          await take(tester, asked(tester), think: _findTime);
          await next(tester);
        }
        await toResults(tester);
        expect(find.byType(AnkirenResultsScreen), findsOneWidget);
        expect(find.text(s.ankirenLevelFailed(1)), findsWidgets);
        expect(find.text(s.ankirenWrongTaps(4)), findsOneWidget);
        final run = p.sideTrips.runs.single;
        expect([run.completed, p.sideTrips.strikesIn(run)], [true, 4]);
        expect(p.sideTripsHub()[SideTrip.ankiren].ladder.cleared, isEmpty);
        if (!landscape) await captureScreen(tester, 'ankiren_results_failed');
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('strikes count only in the owner\'s free-play levels', (tester) async {
      final p = await open(tester);
      for (final (setup, player) in [
        (const AnkirenSetup.ranked(), AnkirenPlayer.owner),
        (const AnkirenSetup.custom(perSide: 3, memorise: Duration(minutes: 1)), AnkirenPlayer.owner),
        (AnkirenSetup.forLevel(0), AnkirenPlayer.guest),
        (AnkirenSetup.forLevel(0), AnkirenPlayer.developer),
      ]) {
        await play(tester, p, setup, player: player);
        await ready(tester);
        expect(find.byType(AnkirenStrikes), findsNothing, reason: '$setup by ${player.name}');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a guest game records nothing, and its Results say so', (tester) async {
      final p = await open(tester);
      final xp = p.xp.total;
      final before = await tester.runAsync(() => dbSnapshot(p.db));
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.guest);
      await ready(tester);
      for (var i = 0; i < AnkirenLevels.of(0).cards; i++) {
        await take(tester, asked(tester), think: _findTime);
        await next(tester);
      }
      await toResults(tester);
      expect(find.byType(AnkirenResultsScreen), findsOneWidget);
      expect(find.textContaining(s.ankirenGuestNote, findRichText: true), findsOneWidget);
      expect(find.textContaining(s.ankirenGuest), findsWidgets, reason: 'tagged as a guest\'s game');
      expect(find.byType(CelebrationSequence), findsNothing);
      expect([p.sideTrips.runs, p.xp.total], [isEmpty, xp]);
      expect(await tester.runAsync(() => dbSnapshot(p.db)), before,
          reason: 'no row in any table (games, runs, days, XP), and key_values as they were');
      await captureScreen(tester, 'ankiren_results_guest');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the debug game: its bar switches the level and reseeds at once; its layers toggle', (tester) async {
      final p = await open(tester);
      useScreen(tester, usersPhone);
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
      await captureScreen(tester, 'ankiren_debug', variant: 'l7');
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
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.developer);
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
        await play(tester, p, AnkirenSetup.forLevel(AnkirenLevels.top), fontScale: fontScale, player: AnkirenPlayer.developer);
        expectLaidOut(tester, usersPhone.size);
        for (final c in find.byType(AnkirenCard).evaluate()) {
          expect(tester.getSize(find.byWidget(c.widget)).width, lessThanOrEqualTo(AnkirenPlayLayout.maxCardW + 0.01));
        }
        await captureScreen(tester, 'ankiren_portrait', variant: 'l10');
        await ready(tester);
        expectLaidOut(tester, usersPhone.size);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a small folded field still spans the screen: its middles open up',
        (tester) async {
      final p = await open(tester);
      for (final level in [0, 3, 5]) {
        await play(tester, p, AnkirenSetup.forLevel(level), player: AnkirenPlayer.developer, seed: level);
        expectLaidOut(tester, usersPhone.size);
        final rects = [for (final c in find.byType(AnkirenCard).evaluate()) tester.getRect(find.byWidget(c.widget))];
        final left = rects.map((r) => r.left).reduce(math.min), right = rects.map((r) => r.right).reduce(math.max);
        if (level == 0) {
          expect(left, greaterThan(AnkirenPlayLayout.padding + 1), reason: "a beginner's row is spread evenly");
        } else {
          expect(left, moreOrLessEquals(AnkirenPlayLayout.padding, epsilon: 0.5), reason: 'level $level');
          expect(right, moreOrLessEquals(usersPhone.size.width - AnkirenPlayLayout.padding, epsilon: 0.5), reason: 'level $level');
        }
        expect(rects.first.width, lessThanOrEqualTo(AnkirenPlayLayout.maxCardW + 0.01));
        await captureScreen(tester, 'ankiren_spread', variant: 'l$level');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('accessibility mode zooms portrait: cards stay tappable, the field pans, starting centred',
        (tester) async {
      final p = await open(tester, accessibilityMode: true);
      await play(tester, p, AnkirenSetup.forLevel(AnkirenLevels.top), player: AnkirenPlayer.developer);
      expect(tester.takeException(), isNull);
      for (final c in find.byType(AnkirenCard).evaluate()) {
        expect(tester.getSize(find.byWidget(c.widget)).width,
            greaterThanOrEqualTo(AnkirenPlayLayout.minTapCardW - 0.01));
      }
      final pan = tester.widget<SingleChildScrollView>(find.descendant(
          of: find.byType(AnkirenFieldView), matching: find.byType(SingleChildScrollView)));
      final position = pan.controller!.position;
      expect(position.pixels, moreOrLessEquals(position.maxScrollExtent / 2, epsilon: 1), reason: 'starts centred');
      await captureScreen(tester, 'ankiren_zoom');

      // A drag pans the field and takes no card.
      await ready(tester);
      final id = asked(tester);
      final before = pan.controller!.position.pixels;
      final onScreen = find.byType(AnkirenCard).evaluate().map((c) => tester.getRect(find.byWidget(c.widget)));
      final from = onScreen.firstWhere((r) => r.left > 0 && r.right < usersPhone.size.width).center;
      await tester.dragFrom(from, const Offset(-120, 0));
      await tester.pump();
      expect(pan.controller!.position.pixels, isNot(before));
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
        await play(tester, p, AnkirenSetup.forLevel(level), screen: usersPhoneLandscape, fontScale: 1.3, player: AnkirenPlayer.developer);
        expectLaidOut(tester, usersPhoneLandscape.size);
        await captureScreen(tester, 'ankiren_landscape', variant: 'l$level');
        await ready(tester);
        expectLaidOut(tester, usersPhoneLandscape.size);
        final orientations = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').toList();
        expect(orientations.first.arguments, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
        await tester.pumpWidget(const SizedBox());
        final after = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').last;
        expect(after.arguments, ['DeviceOrientation.portraitUp'], reason: 'leaving returns to the app\'s portrait lock');
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
        final p = await open(tester, language: lang, ankiren: const AnkirenSettings(rulesSeen: true));
        await clearUpTo(tester, p, AnkirenTuning.customAfterLevel);
        useScreen(tester, usersPhone, fontScale: 1.3);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(t.sideTrips)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(t.ankirenPageTitle));
        await tester.pump();
        await tester.pump(Motion.route * 2);
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == t.ankirenAllLevels));
        await tester.pump();
        await tester.pump(Motion.sheet);
        expect(find.byType(AnkirenFreeSheet), findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(find.text(t.ankirenCustom));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        await captureScreen(tester, 'ankiren_free_sheet', lang: lang);
        await tester.pumpWidget(const SizedBox());

        await play(tester, p, const AnkirenSetup.ranked(), fontScale: 1.3);
        await tester.tap(find.text(t.ankirenReady));
        await tester.pump();
        await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
        await tester.pump();
        const total = 2 * AnkirenTuning.rankedPerSide;
        for (var i = 0; i < total; i++) {
          await take(tester, asked(tester));
          if (i < total - 1) await next(tester);
        }
        await toResults(tester);
        expect(find.byType(AnkirenResultsScreen), findsOneWidget);
        expect(find.byType(ClassBadge), findsOneWidget);
        await captureScreen(tester, 'ankiren_results', lang: lang);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Developer tools', () {
    test("the play overlay's readout: each tap's place, tier, time, speed and points, their sum and the game", () {
      AnkirenRow r(List<int> left, [List<int> right = const []]) =>
          AnkirenRow(left: left, middle: const [], right: right);
      // Own side: 1 2 3 | 4 in 下段; opponent: 5 6.
      final field = AnkirenField(
        own: AnkirenHalf([r([1, 2, 3], [4]), r([]), r([])]),
        opponent: AnkirenHalf([r([5, 6]), r([]), r([])]),
      );
      // A game on [field] asking 2 first, ranked-style or custom.
      AnkirenGame game({bool custom = false}) {
        const memorise = Duration(minutes: 1);
        final setup = custom
            ? const AnkirenSetup.custom(perSide: 3, memorise: memorise)
            : AnkirenSetup(perSide: 3, memorise: memorise, ranked: true);
        for (var seed = 0;; seed++) {
          final g = AnkirenGame(field: field, setup: setup, rng: math.Random(seed));
          if (g.prompts.first == 2) {
            return g
              ..startRecall()
              ..promptRevealed(Duration.zero);
          }
        }
      }

      List<List<String>> rows(AnkirenGame g) => [for (final r in AnkirenScoreReadout.rows(g)) [r.label, r.value]];
      const ms = Duration(milliseconds: 1);
      final kimariji = poems[2].kimariji;

      final quick = game()..tap(2, ms * 300);
      expect(rows(quick), [
        ['CARD', '#2 $kimariji'],
        ['result', 'found on tap 1'],
        ['TAP 1', 'card'],
        ['tier', '1'],
        ['time', '300 ms'],
        ['curve', '(300 / 1650) ^ 1.1'],
        ['range', '100 → 5000 ms'],
        ['speed', '0.88 × 50 = 44'],
        ['points', '1 × 100 + 44 = 144'],
        ['TAP 2', 'none'],
        ['SUM', '144 + 0.2 × 0 = 144'],
        ['GAME', '144 / 900'],
        ['early', '× 1 on 144 (right first taps)'],
        ['score', '144'],
      ]);

      expect([for (final part in AnkirenScoreReadout.parts(quick)) part.first.label], ['CARD', 'TAP 2'],
          reason: 'side by side: the card and its first tap, then the rest');

      final shown = game()
        ..tap(1, ms * 300)
        ..tap(5, ms * 600)
        ..tap(6, ms * 700)
        ..tap(2, ms * 900);
      expect(rows(shown).sublist(1, 13), [
        ['result', 'found on tap 4, shown'],
        ['TAP 1', 'neighbour'],
        ['tier', '0.4'],
        ['time', '300 ms'],
        ['speed', '0, not the card'],
        ['points', '0.4 × 100 = 40'],
        ['TAP 2', 'otherSide'],
        ['tier', '0'],
        ['points', '0 × 100 = 0'],
        ['later', '2 taps, not counted'],
        ['SUM', '40 + 0.2 × 0 = 40'],
        ['GAME', '40 / 900'],
      ]);

      final givenUp = game()..tap(4, ms * 500);
      givenUp.giveUp();
      expect(rows(givenUp)[1], ['result', 'given up after 1 tap']);
      expect(rows(givenUp).firstWhere((r) => r.first == 'SUM'), ['SUM', '10 + 0.2 × 0 = 10']);

      final untapped = game()..giveUp();
      expect(rows(untapped).sublist(1, 5), [
        ['result', 'given up, no tap'],
        ['TAP 1', 'none'],
        ['TAP 2', 'none'],
        ['SUM', '0 + 0.2 × 0 = 0'],
      ]);

      expect(rows(game(custom: true)..tap(2, ms * 300)).last, ['GAME', 'not ranked, no score']);
    });

    testWidgets('the AnkiRen page: levels, ranked points, its graph, and the middle-card simulator', (tester) async {
      final p = await open(tester);
      useScreen(tester, usersPhone);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(progress: p, child: MaterialApp(theme: buildMangaTheme(), home: const AnkirenToolsPage())),
      ));
      await tester.pump();
      final page = find.byType(Scrollable).first;
      await captureScreen(tester, 'debug_ankiren_top');
      String kv(String key) => tester.widget<DebugKV>(find.byWidgetPredicate((w) => w is DebugKV && w.k == key)).v;

      final full = AnkirenTuning.cardPoints + AnkirenScore.speedBonus(1000000);
      expect(kv('per card'), '$full');
      final pickers = find.byType(SegmentedButton<TapProximity?>);
      Future<void> pick(int tap, String place) async {
        final segment = find.descendant(of: pickers.at(tap), matching: find.text(place));
        await tester.ensureVisible(segment);
        await tester.pump();
        await tester.tap(segment);
        await tester.pump();
      }

      await pick(0, TapProximity.row.name);
      expect([kv('per card'), kv('speed bonus')], ['30', '0 / ${AnkirenTuning.speedMax}'], reason: 'no second tap yet');
      await pick(1, TapProximity.card.name);
      expect(kv('per card'), '${AnkirenScore.pointsOf(const [TapProximity.row, TapProximity.card], null)}');
      await pick(0, 'none');
      expect(kv('per card'), '0');

      final classes = find.text('Ranked classes by time per card');
      await tester.scrollUntilVisible(classes, 200, scrollable: page);
      await tester.runAsync(() => Scrollable.ensureVisible(tester.element(classes)));
      await tester.pumpAndSettle();
      for (final band in Rating.bands.skip(1)) {
        expect(find.textContaining(RegExp('^${RegExp.escape(band.labelEn)} ')), findsOneWidget, reason: band.labelEn);
      }
      await captureScreen(tester, 'debug_ankiren_classes');

      await tester.scrollUntilVisible(find.text('Ranked total by card time'), 200, scrollable: page);
      expect(tester.takeException(), isNull);
      final wrongLabel = find.textContaining('cards wrong 0 of');
      await tester.scrollUntilVisible(wrongLabel, 100, scrollable: page);
      final wrong = find.ancestor(of: wrongLabel, matching: find.byType(Column)).first;
      await tester.drag(find.descendant(of: wrong, matching: find.byType(Slider)), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('cards wrong 0 of'), findsNothing, reason: 'the slider moved');
      await captureScreen(tester, 'debug_ankiren_graph');
      await tester.scrollUntilVisible(find.text('Rating by score'), 200, scrollable: page);
      await tester.scrollUntilVisible(find.byType(AnkirenRatingGraph), 200, scrollable: page);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await captureScreen(tester, 'debug_ankiren_rating');
      await tester.scrollUntilVisible(find.text('Middle cards'), 200, scrollable: page);
      expect(tester.takeException(), isNull);
      final run = find.text('Run L${AnkirenLevels.top}');
      await tester.scrollUntilVisible(run, 200, scrollable: page);
      await tester.ensureVisible(run);
      await tester.pump();
      await tester.tap(find.text('${AnkirenToolsTuning.simulationGames.first}'));
      await tester.pump();
      await tester.tap(run);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(kv('level / games'), 'L${AnkirenLevels.top} × ${AnkirenToolsTuning.simulationGames.first}');
      expect(tester.takeException(), isNull);
      await captureScreen(tester, 'debug_ankiren_tools');

      final openGame = find.textContaining('game with middle cards');
      await tester.scrollUntilVisible(openGame, 200, scrollable: page);
      await tester.ensureVisible(openGame);
      await tester.pump();
      await tester.tap(openGame);
      await tester.pump();
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenDebugGame), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Reduced motion', () {
    testWidgets('no turn or shake: cards change face at once, a revealed card gets a steady outline', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await open(tester);
      await play(tester, p, AnkirenSetup.forLevel(0), player: AnkirenPlayer.developer);
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
