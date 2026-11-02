// 定位置's levels and ranked on screen: the page and its level sheet, a timed
// game with its countdown and strikes, ranked's forfeit, the results, and
// History's score. With RENDER_SCREENS=1 it writes PNGs to
// build/screens/teiichi_ranked/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/teiichi_review_strings.dart';
import 'package:fudatobashi/l10n/teiichi_strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/side_trips.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_band.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_strikes.dart';
import 'package:fudatobashi/ui/debug/teiichi_score_readout.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';
import 'package:fudatobashi/ui/history/teiichi_game_page.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_chrome.dart';
import 'package:fudatobashi/ui/shell/tobi_notice.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_sheet.dart';
import 'package:fudatobashi/ui/side_trips/burst_button.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_panels.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_page.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_sheet.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_placing_layer.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_results_screen.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_screen.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_teiichi.dart';
import 'test_vector_art.dart';

const _home = 'home page';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

class _Silent extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

/// The Play button and the pair at the foot are on screen as the page opens,
/// above the navigation bar, for a player at any stage.
void _expectPlayAndPairVisible(WidgetTester tester) {
  const bottom = 832.0 - 48;
  expect(tester.getRect(find.byType(BurstButton).last).bottom, lessThanOrEqualTo(bottom), reason: 'Play');
  expect(tester.getRect(find.byType(SideTripGuestButton)).bottom, lessThanOrEqualTo(bottom), reason: 'Guest mode');
  expect(tester.getRect(find.byType(SideTripRulesButton)).bottom, lessThanOrEqualTo(bottom), reason: 'How to play');
}

/// The banner's class box says "???" and hides the line to the next class
/// (keeping its room) while the rating is placed, and shows both once
/// [rated].
void _expectClassBox(WidgetTester tester, S s, SideTripEntry entry, {required bool rated}) {
  expect(find.text(AnkirenPageLayout.placementClass), rated ? findsNothing : findsOneWidget);
  if (rated) {
    expect(find.textContaining(s.classStem(entry.band), findRichText: true), findsWidgets);
  }
  final bar = find.byType(RatingBar, skipOffstage: false);
  expect(bar, findsOneWidget);
  expect(tester.getSize(bar).height, greaterThan(0), reason: 'the line to the next class keeps its room');
  expect(find.ancestor(of: bar, matching: find.byWidgetPredicate((w) => w is Visibility && !w.visible)),
      rated ? findsNothing : findsOneWidget);
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const trip = SideTrip.teiichi;
  final allCards = [for (final p in poems.all) p.id];

  final real = sounds;
  setUp(() => sounds = _Silent());
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
    if (renderScreens) {
      await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
      await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
      await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    }
  });

  // An all-known player who has taken the tour, with levels cleared up to
  // [cleared] and [ranked] ranked games recorded.
  Future<Progress> open(WidgetTester tester, {int? cleared, int ranked = 0, String language = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(
          p.settings.copyWith(language: language, languagePicked: true, toured: true, teiichiRulesSeen: true));
      if (cleared != null) await p.clearLevelsUpTo(trip, cleared);
      for (var i = 0; i < ranked; i++) {
        final played = playTeiichi(const TeiichiSetup.ranked(),
            placeMs: 3000 - 400 * i,
            wrongAt: i.isEven ? {1, 4} : {1},
            karafuda: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89],
            deck: [for (var id = 1; id <= 25; id++) (id * 7 + i) % 79 + 1]);
        await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());
      }
    });
    return p;
  }

  // [child] over a home page, as its own route, for [p], on [screen].
  Future<void> show(WidgetTester tester, Progress p, Widget Function() child, {Screen screen = usersPhone}) async {
    useScreen(tester, screen);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
            navigatorKey: navigator,
            debugShowCheckedModeBanner: false,
            theme: buildMangaTheme(),
            home: const Scaffold(body: Text(_home))),
      ),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => child()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder band(S s, String label) => find.widgetWithText(BandButton, label);

  group('the page', () {
    for (final lang in ['en', 'ja']) {
      final s = S(lang);

      testWidgets('new: ranked chained, level 0 next ($lang)', (tester) async {
        final p = await open(tester, language: lang);
        await show(tester, p, () => const TeiichiPage());
        expect(find.byType(LockedPanel), findsOneWidget);
        expect(tester.widget<LockedPanel>(find.byType(LockedPanel)).why,
            s.ankirenRankedLocked(allKnown: true, cleared: false, level: 3));
        expect(find.text(s.ankirenPlayLevel(0)), findsOneWidget);
        expect(tester.takeException(), isNull);
        _expectPlayAndPairVisible(tester);
        _expectClassBox(tester, s, p.sideTripsHub()[trip], rated: false);
        await captureScreen(tester, 'teiichi_ranked/page_new', lang: lang);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('ranked open, placement games so far ($lang)', (tester) async {
        final p = await open(tester, cleared: 3, ranked: 1, language: lang);
        await show(tester, p, () => const TeiichiPage());
        expect(find.byType(LockedPanel), findsNothing);
        expect(find.text(s.ankirenPlayLevel(4)), findsOneWidget);
        expect(tester.takeException(), isNull);
        _expectPlayAndPairVisible(tester);
        _expectClassBox(tester, s, p.sideTripsHub()[trip], rated: false);
        await captureScreen(tester, 'teiichi_ranked/page_placement', lang: lang);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('with a rating: class and rating beside the averages ($lang)', (tester) async {
        final p = await open(tester, cleared: 5, ranked: 5, language: lang);
        await show(tester, p, () => const TeiichiPage());
        final rating = p.sideTripsHub()[trip].rating!;
        expect(find.text('${rating.round()}'), findsOneWidget);
        expect(find.text(s.teiichiFormWrongTaps), findsOneWidget, reason: 'the averages stay');
        expect(tester.takeException(), isNull);
        _expectPlayAndPairVisible(tester);
        _expectClassBox(tester, s, p.sideTripsHub()[trip], rated: true);
        await captureScreen(tester, 'teiichi_ranked/page_rated', lang: lang);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('outside all-known mode ranked says so', (tester) async {
      final p = await open(tester, cleared: 3);
      await tester.runAsync(() => p.setLearningMode(LearningMode.journey));
      await show(tester, p, () => const TeiichiPage());
      const s = S('en');
      expect(tester.widget<LockedPanel>(find.byType(LockedPanel)).why,
          s.ankirenRankedLocked(allKnown: false, cleared: true, level: 3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the level sheet', () {
    for (final lang in ['en', 'ja']) {
      final s = S(lang);

      Future<void> openSheet(WidgetTester tester) async {
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenAllLevels));
        await tester.pump();
        await tester.pump(Motion.sheet);
        expect(find.byType(TeiichiSheet), findsOneWidget);
      }

      testWidgets('shut levels chained, cleared ones checked, custom shut before level 5 ($lang)', (tester) async {
        final p = await open(tester, cleared: 2, language: lang);
        await show(tester, p, () => const TeiichiPage());
        await openSheet(tester);
        await captureScreen(tester, 'teiichi_ranked/sheet', lang: lang);
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenLevelTag(5)));
        await tester.pump();
        expect(find.text(s.ankirenLevelLocked(4, 5)), findsOneWidget);
        await tester.pump(AnkirenSheetLayout.lockBalloonLife);
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenCustom));
        await tester.pump();
        expect(find.text(s.ankirenCustomLocked(5)), findsOneWidget);
        await tester.pump(AnkirenSheetLayout.lockBalloonLife);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('custom opens with level 5, its steppers keep today\'s custom game ($lang)', (tester) async {
        final p = await open(tester, cleared: 5, language: lang);
        await show(tester, p, () => const TeiichiPage());
        await openSheet(tester);
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenCustom));
        await tester.pump();
        expect(find.byType(SheetStepper), findsNWidgets(2), reason: 'the cards and the からふだ');
        await captureScreen(tester, 'teiichi_ranked/sheet_custom', lang: lang);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a guest has every level and the custom game, dealt from all the cards ($lang)', (tester) async {
        final p = await open(tester, language: lang);
        await show(tester, p, () => const TeiichiPage());
        await tester.ensureVisible(find.byType(SideTripGuestButton));
        await tester.pump();
        await tester.tap(find.byType(SideTripGuestButton));
        await tester.pump();
        await tester.pump(Motion.sheet);
        expect(find.byType(TeiichiSheet), findsOneWidget);
        await captureScreen(tester, 'teiichi_ranked/sheet_guest', lang: lang);
        await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenLevelTag(8)));
        await tester.pump();
        expect(find.text(s.ankirenLevelLocked(7, 8)), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('a timed game', () {
    Finder layer() => find.byType(TeiichiPlacingLayer);
    List<(TeiichiSpot, Rect)> spotsOf(WidgetTester tester) => tester.widget<TeiichiSpots>(find.byType(TeiichiSpots)).spots;

    Future<void> placeOne(WidgetTester tester, TeiichiSpot want) async {
      final (_, rect) = spotsOf(tester).firstWhere((e) => e.$1 == want);
      await tester.tapAt(tester.getTopLeft(find.byType(TeiichiSpots)) + rect.center);
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);
    }

    Duration clock(WidgetTester tester) => tester.widget<MemoriseClock>(find.byType(MemoriseClock)).left.value;

    for (final (name, screen) in [('landscape', usersPhoneLandscape), ('portrait', usersPhone)]) {
      for (final lang in ['en', 'ja']) {
        final s = S(lang);

        testWidgets('a level counts down, the cards flip at the limit, unplaced cards strike ($name, $lang)', (tester) async {
          final p = await open(tester, language: lang);
          await tester.runAsync(() => p.updateSettings(p.settings.copyWith(teiichiTurnTipOff: true)));
          final setup = TeiichiSetup.forLevel(0);
          await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: screen);
          expect(clock(tester), setup.limit, reason: 'the time left, not the time so far');
          await tester.pump(const Duration(seconds: 3));
          expect(clock(tester), setup.limit! - const Duration(seconds: 3));
          expect(find.text(s.teiichiTimeLeft), findsOneWidget);
          await placeOne(tester, dealtSpot(setup, 0));
          await placeOne(tester, dealtSpot(setup, 1));
          await captureScreen(tester, 'teiichi_ranked/countdown', lang: lang, variant: name);
          expect(find.byType(AnkirenStrikes), findsNothing, reason: 'none while placing');

          await tester.pump(setup.limit! - TeiichiPlayTuning.lowTime);
          await tester.pump();
          await captureScreen(tester, 'teiichi_ranked/countdown_low', lang: lang, variant: name);
          await tester.pump(TeiichiPlayTuning.lowTime);
          await tester.pump();
          expect(layer(), findsNothing, reason: 'the cards flip as if Done was pressed');
          await tester.pump(TeiichiPlayLayout.zoomTime);
          await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
          await tester.pump();
          await tester.pump();
          expect(find.byType(AnkirenStrikes), findsOneWidget);
          final state = tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes));
          expect(state.strikes, 2, reason: 'two cards left in the stack');
          await tester.pump(AnkirenMotion.strike);
          await captureScreen(tester, 'teiichi_ranked/strikes', lang: lang, variant: name);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    for (final (name, screen) in [('landscape', usersPhoneLandscape), ('portrait', usersPhone)]) {
      testWidgets('the dev readout shows with dev mode and the overlay on, placing and after the flip ($name)', (tester) async {
        final p = await open(tester);
        await tester.runAsync(() => p.updateSettings(
            p.settings.copyWith(teiichiTurnTipOff: true, debugMode: true, playOverlay: true)));
        final setup = TeiichiSetup.forLevel(0);
        await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: screen);
        expect(find.byType(TeiichiScoreReadout), findsOneWidget);
        expect(find.text('PLACING'), findsOneWidget);
        expect(find.text('halvings'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await placeOne(tester, dealtSpot(setup, 0));
        await captureScreen(tester, 'teiichi_ranked/readout_placing', variant: name);
        await tester.pump(setup.limit!);
        await tester.pump();
        await tester.pump(TeiichiPlayLayout.zoomTime);
        await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
        await tester.pump();
        expect(find.text('PLACING'), findsNothing);
        expect(find.text('GAME'), findsOneWidget);
        expect(find.text('applied'), findsOneWidget);
        await captureScreen(tester, 'teiichi_ranked/readout_recall', variant: name);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final (name, debugMode, overlay) in [('overlay off', true, false), ('dev mode off', false, true)]) {
      testWidgets('the dev readout is not shown with $name', (tester) async {
        final p = await open(tester);
        await tester.runAsync(() => p.updateSettings(
            p.settings.copyWith(teiichiTurnTipOff: true, debugMode: debugMode, playOverlay: overlay)));
        await show(tester, p, () => TeiichiScreen(setup: TeiichiSetup.forLevel(0), known: allCards, seed: 3),
            screen: usersPhoneLandscape);
        expect(find.byType(TeiichiScoreReadout), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a level with からふだ shows the strikes beside End and both controls ($usersPhoneLandscape)', (tester) async {
      final p = await open(tester, cleared: 3);
      final setup = TeiichiSetup.forLevel(3);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: usersPhoneLandscape);
      for (var i = 0; i < setup.cards - 1; i++) {
        await placeOne(tester, dealtSpot(setup, i));
      }
      await tester.pump(setup.limit!);
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime);
      await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
      await tester.pump();
      await tester.pump(AnkirenMotion.strike);
      expect(tester.widget<AnkirenStrikes>(find.byType(AnkirenStrikes)).strikes, 1);
      await captureScreen(tester, 'teiichi_ranked/strikes_karafuda', variant: 'landscape');
      useScreen(tester, usersPhone);
      await tester.pump();
      await tester.pump(Motion.route);
      await captureScreen(tester, 'teiichi_ranked/strikes_karafuda', variant: 'portrait');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with no card placed the game ends at once, at Results', (tester) async {
      final p = await open(tester, cleared: 3);
      final setup = TeiichiSetup.forLevel(0);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: usersPhoneLandscape);
      await tester.pump(setup.limit!);
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      useScreen(tester, usersPhone);
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      final run = p.sideTrips.runsOf(trip).single;
      expect(p.sideTrips.teiichiRecordOf(run).unplaced, hasLength(setup.cards));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('custom games keep the clock counting up, and no strikes', (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup(cards: 4, rows: 1);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: usersPhoneLandscape);
      await tester.pump(const Duration(seconds: 2));
      expect(clock(tester), const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a guest\'s level keeps the limit, shows no strikes and writes nothing', (tester) async {
      final p = await open(tester);
      final setup = TeiichiSetup.forLevel(0);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, player: AnkirenPlayer.guest, seed: 3),
          screen: usersPhoneLandscape);
      expect(clock(tester), setup.limit);
      await placeOne(tester, dealtSpot(setup, 0));
      await tester.pump(setup.limit!);
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime);
      await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
      await tester.pump();
      expect(find.byType(AnkirenStrikes), findsNothing);
      expect(p.sideTrips.runsOf(trip), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the ranked clock never stops, and no tip takes up its time', (tester) async {
      final p = await open(tester);
      await show(tester, p, () => TeiichiScreen(setup: const TeiichiSetup.ranked(), known: allCards, seed: 3));
      await tester.pump(TeiichiPlayTuning.tipDelay);
      await tester.pump(Motion.route);
      expect(find.byType(TobiNotice), findsNothing);
      expect(clock(tester) < TeiichiTuning.rankedLimit, isTrue);
      // Leaves the game, recording its forfeit, before the test closes it.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('leaving ranked while placing asks first, then records a forfeit at 0', (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup.ranked();
      const s = S('en');
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: usersPhoneLandscape);
      await tester.tap(band(s, s.end));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(s.teiichiForfeitTitle), findsOneWidget);
      expect(find.text(s.teiichiForfeitNote), findsOneWidget);
      await captureScreen(tester, 'teiichi_ranked/forfeit_dialog');
      await tester.tap(find.text(s.cancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TeiichiScreen), findsOneWidget);
      expect(p.sideTrips.runsOf(trip), isEmpty, reason: 'staying records nothing');

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(s.teiichiForfeitTitle), findsOneWidget, reason: 'the Back key asks too');
      await tester.tap(find.text(s.ankirenLeave));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      useScreen(tester, usersPhone);
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsOneWidget);
      await tester.pump(ResultsLayout.overlayStagger);
      await tester.pump(const Duration(seconds: 1));
      final run = p.sideTrips.runsOf(trip).single;
      expect((run.ranked, run.score, run.performance, run.completed), (true, 0, 0, false));
      expect(p.sideTripsHub()[trip].rating, 0);
      await tester.pumpWidget(const SizedBox());
      final again = (await tester.runAsync(() => Progress.open(p.db)))!;
      expect(again.sideTrips.runsOf(trip), hasLength(1), reason: 'leaving left no journal to forfeit a second time');
    });
  });

  group('results and History', () {
    ({TeiichiSetup setup, int placeMs, int? placeCards, int? endAfter, Set<int> wrongAt}) sample(String name) => switch (name) {
          'ranked' => (setup: const TeiichiSetup.ranked(), placeMs: 4480, placeCards: null, endAfter: null, wrongAt: const {1, 5, 9}),
          'ranked_unplaced' => (setup: const TeiichiSetup.ranked(), placeMs: 30000, placeCards: 21, endAfter: null, wrongAt: const {2}),
          'forfeit' => (setup: const TeiichiSetup.ranked(), placeMs: 3000, placeCards: null, endAfter: 12, wrongAt: const {1}),
          'no_cards' => (setup: const TeiichiSetup.ranked(), placeMs: 3000, placeCards: 0, endAfter: null, wrongAt: const {}),
          'level_clear' => (setup: TeiichiSetup.forLevel(1), placeMs: 2000, placeCards: null, endAfter: null, wrongAt: const {1}),
          'level_fail' => (setup: TeiichiSetup.forLevel(3), placeMs: 2000, placeCards: 13, endAfter: null, wrongAt: const {2}),
          _ => throw ArgumentError(name),
        };

    Future<({TeiichiResultsScreen screen, SideTripReport report})> record(
        WidgetTester tester, Progress p, String name) async {
      final (:setup, :placeMs, :placeCards, :endAfter, :wrongAt) = sample(name);
      final played = playTeiichi(setup,
          placeMs: placeMs,
          placeCards: placeCards,
          endAfter: endAfter,
          wrongAt: wrongAt,
          strikes: setup.level != null,
          karafuda: setup.karafuda == 0 || placeCards == 0
              ? const []
              : [for (var i = 0; i < setup.karafuda; i++) 80 + i]);
      final report = (await tester.runAsync(() => p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now())))!;
      return (
        screen: TeiichiResultsScreen(
            placing: played.placing, game: played.game, player: AnkirenPlayer.owner, bestBefore: null, report: report),
        report: report,
      );
    }

    for (final lang in ['en', 'ja']) {
      for (final name in ['ranked', 'ranked_unplaced', 'forfeit', 'no_cards', 'level_clear', 'level_fail']) {
        testWidgets('$name ($lang)', (tester) async {
          final p = await open(tester, language: lang, cleared: 3, ranked: name.startsWith('ranked') ? 4 : 0);
          final (:screen, :report) = await record(tester, p, name);
          final s = S(lang);
          await show(tester, p, () => screen);
          await tester.pump(Motion.route);
          await tester.pump(ResultsLayout.overlayStagger);
          await tester.pump();
          if (report.rankedGames > AnkirenRatingModel.placementGames) {
            // The XP page plays first; the rating page follows it.
            for (var i = 0; i < 4 && !tester.any(find.text(s.tripRatingBand(trip))); i++) {
              await tester.tap(find.byType(CelebrationCta).first);
              await tester.pump();
              await tester.pump(const Duration(seconds: 6));
            }
            expect(find.text(s.tripRatingBand(trip)), findsWidgets, reason: 'the rating is its own');
          }
          await tester.pump(const Duration(seconds: 12));
          await tester.pump(const Duration(seconds: 4));
          // Past the celebrations, tap by tap.
          for (var i = 0; i < 6 && tester.any(find.byType(CelebrationCta)); i++) {
            await tester.tap(find.byType(CelebrationCta).first);
            await tester.pump();
            await tester.pump(const Duration(seconds: 6));
          }
          expect(tester.takeException(), isNull);
          await captureScreen(tester, 'teiichi_ranked/results_$name', lang: lang);
          if (name.startsWith('ranked')) {
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
            await tester.pump();
            await captureScreen(tester, 'teiichi_ranked/results_$name', lang: lang, variant: 'scrolled');
          }

          final played = p.sideTrips.runsOf(trip).last;
          await show(tester, p, () => Scaffold(body: SafeArea(child: HistoryScreen(trip: trip, onBack: () {}))));
          await tester.pump(Motion.route);
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          await captureScreen(tester, 'teiichi_ranked/history_$name', lang: lang);

          await show(tester, p, () => TeiichiGamePage(run: played));
          await tester.pump(Motion.route);
          expect(tester.takeException(), isNull);
          await captureScreen(tester, 'teiichi_ranked/game_${name}_overview', lang: lang);
          final tabs = [
            (S(lang).ankirenTabField, 'field'),
            (S(lang).teiichiTabPlacing, 'placing'),
            if (played.ranked) (S(lang).ankirenTabScore, 'score'),
            (S(lang).ankirenTabTaps, 'taps'),
          ];
          for (final (label, tab) in tabs) {
            await tester.tap(find.text(label).first);
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull, reason: tab);
            if (tab == 'field' && name == 'no_cards') expect(find.text(s.teiichiNoneLaid), findsOneWidget);
            await captureScreen(tester, 'teiichi_ranked/game_${name}_$tab', lang: lang);
          }
          expect(s.code, lang);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
