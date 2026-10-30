// 定位置 through its screens on a phone: the hub's entry and the page, its
// settings, the custom game sheet, a whole game laid out by taps and drags
// on a landscape field and on a portrait one, played to its end, turned
// midway, and Results; what a game records, and that a guest's records
// nothing. With RENDER_SCREENS=1 it also writes PNGs to
// build/screens/teiichi/.
import 'dart:io';

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
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/teiichi_strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_band.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_card.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_field_view.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';
import 'package:fudatobashi/ui/settings/side_trip_settings_screen.dart';
import 'package:fudatobashi/ui/shell/tobi_notice.dart';
import 'package:fudatobashi/ui/side_trips/burst_button.dart';
import 'package:fudatobashi/ui/side_trips/dojo_scene.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_panels.dart';
import 'package:fudatobashi/ui/side_trips/side_trips_screen.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_guide.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_page.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_sheet.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_placing_layer.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_results_screen.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_screen.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_zoom.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';

import 'db_snapshot.dart';
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

class _HeardSounds extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
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

  final real = sounds;
  setUp(() => sounds = _HeardSounds());
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

  // An all-known player who has taken the tour, with [games] 定位置 games
  // recorded.
  Future<Progress> open(WidgetTester tester, {int games = 0, bool rulesSeen = true, String language = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(p.settings
          .copyWith(language: language, languagePicked: true, toured: true, teiichiRulesSeen: rulesSeen));
      for (var i = 0; i < games; i++) {
        final played = playTeiichi(TeiichiSetup.usual,
            placeMs: 900 + 150 * i,
            wrongAt: i == 2 ? {1, 4} : {1},
            deck: [for (var id = 1; id <= 25; id++) (id * 7 + i) % 100 + 1]);
        await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());
      }
    });
    return p;
  }

  // [child] over a home page, as its own route, for [p], on [screen] at
  // [fontScale].
  Future<void> show(WidgetTester tester, Progress p, Widget Function() child,
      {Screen screen = usersPhone, double fontScale = 1}) async {
    useScreen(tester, screen, fontScale: fontScale);
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
    expect(tester.takeException(), isNull);
  }

  group('hub and page', () {
    testWidgets('the storehouse island shows 定位置\'s entry, whose burst opens its page, rules first', (tester) async {
      final p = await open(tester, rulesSeen: false);
      useScreen(tester, usersPhone);
      await tester.pumpWidget(RepaintBoundary(key: screenKey, child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.sideTrips)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.fling(find.byType(DojoScene), const Offset(-200, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final burst = find.byWidgetPredicate((w) => w is PageBurst && w.trip == SideTrip.teiichi);
      expect(burst.hitTestable(), findsOneWidget);
      expect(find.descendant(of: find.byType(SideTripsScreen), matching: find.text(s.teiichiBestPlacing)).hitTestable(),
          findsOneWidget);
      await captureScreen(tester, 'teiichi/hub');

      await tester.tap(burst);
      await tester.pump();
      await tester.pump(Motion.route * 2);
      expect(find.byType(TeiichiPage), findsOneWidget);
      await tester.pump(Motion.sheet);
      expect(find.byType(TeiichiRulesSheet), findsOneWidget, reason: 'the first visit opens with the rules');
      expect(p.settings.teiichiRulesSeen, isTrue);
      await captureScreen(tester, 'teiichi/rules');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new player\'s page: ranked chained, the guide\'s card, practice', (tester) async {
      final p = await open(tester);
      await show(tester, p, () => const TeiichiPage());
      expect(find.text(s.teiichiRankedSoon), findsOneWidget);
      expect(find.text(s.teiichiPlay(TeiichiTuning.cards)), findsOneWidget);
      await tester.tap(find.text(s.teiichiLearnButton));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiGuideScreen), findsOneWidget);
      expect(find.text(s.teiichiGuideSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with games: the best placing time, and the guide\'s card still in full', (tester) async {
      final p = await open(tester, games: 3);
      await show(tester, p, () => const TeiichiPage());
      final best = p.sideTripsHub()[SideTrip.teiichi].placing.best!;
      expect(best, const Duration(milliseconds: 900 * TeiichiTuning.cards));
      expect(find.text(formatMinutes(best)), findsOneWidget);
      expect(find.text(s.teiichiLearnLine, findRichText: true), findsOneWidget);
      expect(find.text(s.teiichiLearnButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  // The page, new and with games, on the phones at font scales 1 and 1.3:
  // at 1 it is one screen with Guest mode and the rules at its foot; larger
  // type scrolls.
  group('page fits', () {
    final page = find.descendant(of: find.byType(TeiichiPage), matching: find.byType(Scrollable)).first;
    for (final phone in [narrowPhone, usersPhone, widePhone]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          testWidgets('${phone.name} dp, font scale $fontScale ($lang)', (tester) async {
            final s = S(lang);
            for (final (name, games) in [('page_new', 0), ('page_games', 3)]) {
              final p = await open(tester, games: games, language: lang);
              await show(tester, p, () => const TeiichiPage(), screen: phone, fontScale: fontScale);
              final scroll = tester.state<ScrollableState>(page);
              if (fontScale == 1) expect(scroll.position.maxScrollExtent, 0, reason: 'nothing to scroll to');
              final burst = find.byWidgetPredicate((w) => w is BurstButton && w.title == s.teiichiPlay(TeiichiTuning.cards));
              final blocks = [
                find.byType(StatStrip),
                find.byType(RankedBurst),
                find.text(s.teiichiLearnButton),
                burst,
                find.byType(SideTripGuestButton),
              ];
              final tops = [for (final f in blocks) tester.getRect(f).top];
              expect(tops, orderedEquals([...tops]..sort()), reason: 'the form, ranked, the guide, practice, the pair');
              if (fontScale == 1) {
                expect(tester.getRect(find.byType(SideTripGuestButton)).bottom,
                    moreOrLessEquals(phone.size.height - phone.bars.bottom - AnkirenPageLayout.bottomGap, epsilon: 1),
                    reason: 'the pair sits at the foot, as on 暗記練\'s page');
              }
              for (final f in blocks) {
                await tester.ensureVisible(f);
                await tester.pump();
                final r = tester.getRect(f);
                expect(r.top, greaterThanOrEqualTo(phone.bars.top), reason: '$f');
                expect(r.bottom, lessThanOrEqualTo(phone.size.height - phone.bars.bottom + 0.5), reason: '$f');
              }
              scroll.position.jumpTo(0);
              await tester.pump();
              expect(tester.takeException(), isNull);
              await captureScreen(tester, 'teiichi/$name', lang: lang);
              await tester.pumpWidget(const SizedBox());
            }
          });
        }
      }
    }
  });

  group('settings', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('Settings › Side trips › Teiichi turns the screen on its own until switched off ($lang)', (tester) async {
        final s = S(lang);
        final p = await open(tester, language: lang);
        await show(tester, p, () => const TeiichiSettingsScreen());
        final row = find.text(s.teiichiAutoTurn, findRichText: true);
        expect(row, findsOneWidget);
        expect(p.settings.teiichiAutoTurn, isTrue);
        await captureScreen(tester, 'teiichi/settings', lang: lang);
        await tester.tap(row);
        await tester.pump();
        expect(p.settings.teiichiAutoTurn, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('custom game sheet', () {
    testWidgets('rows hold their share of the cards: fewer are locked, and more cards raise them', (tester) async {
      final p = await open(tester);
      await show(tester, p, () => const TeiichiPage());
      await tester.tap(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.teiichiAllCards));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(TeiichiSheet), findsOneWidget);
      expect(find.textContaining('100', findRichText: true), findsWidgets, reason: 'from the cards known');

      Future<void> tap(Finder f) async {
        await tester.tap(f);
        await tester.pump();
      }

      final sheet = find.byType(TeiichiSheet);
      await tap(find.descendant(of: sheet, matching: find.text('12')));
      await tap(find.descendant(of: sheet, matching: find.text(s.teiichiRowsKey(2), findRichText: true)));
      await captureScreen(tester, 'teiichi/custom_12');
      await tap(find.descendant(of: sheet, matching: find.text(s.teiichiRowsKey(1), findRichText: true)));
      expect(find.text(s.teiichiRowsHold(1, TeiichiSetup.mostCards(1))), findsOneWidget, reason: 'says why');
      await tester.pump(AnkirenSheetLayout.lockBalloonLife);
      await tester.pump(const Duration(seconds: 1));

      await tap(find.descendant(of: sheet, matching: find.text('20')));
      expect(find.textContaining(s.teiichiRowsWentUp(3), findRichText: true), findsOneWidget);
      await captureScreen(tester, 'teiichi/custom_20');

      await tap(find.descendant(of: sheet, matching: find.text(s.ankirenConfirm)));
      await tester.pump(Motion.sheet);
      expect(find.text(s.teiichiPlay(20)), findsOneWidget, reason: 'the page plays the custom game');
      expect((p.settings.teiichiCards, p.settings.teiichiRows), (20, 3), reason: 'kept in the settings');

      await tester.pumpWidget(const SizedBox());
      await show(tester, p, () => const TeiichiPage());
      expect(find.text(s.teiichiPlay(20)), findsOneWidget, reason: 'the page opens on the saved setup');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  // Results with both shelves of cards full: every card's kimariji shows in
  // full, inside the card panel, on the phones at font scales 1 and 1.3.
  group('results fit', () {
    for (final phone in [narrowPhone, usersPhone]) {
      for (final fontScale in [1.0, 1.3]) {
        testWidgets('${phone.name} dp, font scale $fontScale', (tester) async {
          final p = await open(tester);
          final played = playTeiichi(TeiichiSetup.usual, placeMs: 900, wrongAt: {2});
          await show(
              tester,
              p,
              () => TeiichiResultsScreen(
                    placing: played.placing,
                    game: played.game,
                    player: AnkirenPlayer.owner,
                    bestBefore: null,
                  ),
              screen: phone,
              fontScale: fontScale);
          await tester.pump(Motion.route);
          await captureScreen(tester, 'teiichi/results_fit');
          final names = {for (final c in poems.all) s.kimariji(c.id)};
          final labels = find.byWidgetPredicate((w) => w is Text && names.contains(w.data) && w.maxLines == 1);
          expect(labels, findsNWidgets(2 * SummaryPanelLayout.perLine));
          await tester.ensureVisible(labels.last);
          await tester.pump();
          final panel = tester.getRect(find.ancestor(of: find.byType(SummaryRow).last, matching: find.byType(MangaPanel)).first);
          for (final label in labels.evaluate()) {
            final bottom = tester.getRect(find.byWidget(label.widget)).bottom;
            expect(bottom, lessThanOrEqualTo(panel.bottom - Strokes.panel), reason: 'inside the panel');
            expect(bottom, lessThanOrEqualTo(phone.size.height - phone.bars.bottom), reason: 'on screen');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('a game', () {
    Finder layer() => find.byType(TeiichiPlacingLayer);
    TeiichiPlacingLayer layerOf(WidgetTester tester) => tester.widget<TeiichiPlacingLayer>(layer());
    List<(TeiichiSpot, Rect)> spotsOf(WidgetTester tester) => tester.widget<TeiichiSpots>(find.byType(TeiichiSpots)).spots;

    // A free spot's centre on screen.
    Offset spotAt(WidgetTester tester, bool Function(TeiichiSpot spot) which) {
      final (_, rect) = spotsOf(tester).firstWhere((e) => which(e.$1));
      return tester.getTopLeft(find.byType(TeiichiSpots)) + rect.center;
    }

    Future<void> tapAt(WidgetTester tester, Offset at) async {
      await tester.tapAt(at);
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);
    }

    // Places the rest of the stack round the rows, by taps on their spots.
    Future<void> placeRest(WidgetTester tester, TeiichiSetup setup, {int? upTo}) async {
      var i = setup.cards - layerOf(tester).stack.length;
      while (layerOf(tester).stack.isNotEmpty && (upTo == null || i < upTo)) {
        final want = dealtSpot(setup, i);
        await tapAt(tester, spotAt(tester, (spot) => spot == want));
        i++;
      }
    }

    int asked(WidgetTester tester) {
      final text = tester.widget<PromptText>(find.byType(PromptText)).text;
      return poems.all.firstWhere((p) => s.kimariji(p.id) == text).id;
    }

    Future<void> take(WidgetTester tester, int poemId) async {
      final gesture = await tester.createGesture();
      final card = find.byWidgetPredicate((w) => w is AnkirenCard && w.poemId == poemId);
      await gesture.down(tester.getCenter(card), timeStamp: SchedulerBinding.instance.currentSystemFrameTimeStamp);
      await gesture.up();
      await tester.pump();
    }

    testWidgets('laid out by taps and a drag, turned face down, played to the end and recorded', (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup.usual;
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3), screen: usersPhoneLandscape);
      expect(layerOf(tester).stack, hasLength(setup.cards));
      expect(spotsOf(tester).where((e) => e.$1 is OpenMiddle), hasLength(1));
      final done = find.widgetWithText(BandButton, s.done);
      expect(tester.widget<BandButton>(done).onTap, isNull, reason: 'Done waits for every card');
      await captureScreen(tester, 'teiichi/place_start');

      await placeRest(tester, setup, upTo: 10);
      final top = layerOf(tester).stack.first;
      await tapAt(tester, spotAt(tester, (spot) => spot is OpenMiddle));
      expect(layerOf(tester).cards.keys, contains(top));
      // A placed card dragged onto another takes its place.
      final placed = layerOf(tester).cards;
      final first = placed.keys.first;
      final target = placed.keys.elementAt(3);
      final gesture = await tester.startGesture(tester.getTopLeft(layer()) + placed[first]!.center);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getTopLeft(layer()) + placed[target]!.center);
      await tester.pump();
      expect(layerOf(tester).drag?.spot, CardSpot(target));
      expect(tester.widget<TeiichiRiding>(find.byType(TeiichiRiding)).landing, isNotNull);
      await tester.pump(TeiichiPlayLayout.move);
      await captureScreen(tester, 'teiichi/place_drag');
      await gesture.up();
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);
      expect(layerOf(tester).drag, isNull);
      await captureScreen(tester, 'teiichi/place_mid');

      // A card carried across the band paints above it.
      final placement = layerOf(tester).placement;
      final origin = tester.getTopLeft(layer());
      final carry = await tester.startGesture(origin + stackRect(placement).center);
      await carry.moveBy(const Offset(0, 20));
      await tester.pump();
      await carry.moveTo(origin + Offset(placement.roomAbove.center.dx + 120, placement.bandTop + 100));
      await tester.pump();
      expect(layerOf(tester).drag, isNotNull);
      await captureScreen(tester, 'teiichi/place_over_band');
      await carry.up();
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);

      await placeRest(tester, setup);
      expect(layerOf(tester).stack, isEmpty);
      expect(tester.widget<BandButton>(done).onTap, isNotNull);
      await captureScreen(tester, 'teiichi/place_done');

      await tester.tap(done);
      await tester.pump();
      expect(find.byType(TeiichiPlacingLayer), findsNothing);
      expect(tester.widgetList<AnkirenCard>(find.byType(AnkirenCard)).every((c) => c.faceUp), isTrue,
          reason: 'the field grows with its cards still face up');
      await tester.pump(TeiichiPlayLayout.zoomTime ~/ 2);
      await tester.pump(TeiichiPlayLayout.zoomTime ~/ 2);
      await captureScreen(tester, 'teiichi/zoomed');
      await tester.pump(AnkirenMotion.flip);
      await captureScreen(tester, 'teiichi/flip');
      await tester.pump(AnkirenPlayTuning.promptPause);
      await tester.pump();
      expect(find.byType(AnkirenCard), findsNWidgets(setup.cards));
      expect(tester.widgetList<AnkirenCard>(find.byType(AnkirenCard)).where((c) => c.faceUp), isEmpty);

      // One wrong tap, then every card found.
      final wrong = tester.widgetList<AnkirenCard>(find.byType(AnkirenCard)).map((c) => c.poemId).firstWhere((id) => id != asked(tester));
      await take(tester, wrong);
      await tester.pump(const Duration(milliseconds: 100));
      await captureScreen(tester, 'teiichi/wrong');
      for (var i = 0; i < setup.cards; i++) {
        if (i == 3) await captureScreen(tester, 'teiichi/play');
        await tester.pump(Duration(milliseconds: 600 + 90 * (i % 7)));
        await take(tester, asked(tester));
        await tester.pump(i == setup.cards - 1 ? AnkirenPlayTuning.finishPause : AnkirenPlayTuning.promptPause);
        await tester.pump();
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      useScreen(tester, usersPhone);
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureScreen(tester, 'teiichi/results');

      final trips = p.sideTrips;
      final run = trips.runsOf(SideTrip.teiichi).single;
      expect(run.completed, isTrue);
      final placings = await tester.runAsync(() => p.db.select(p.db.teiichiPlacings).get());
      expect({for (final x in placings!) x.poemId}, hasLength(setup.cards), reason: 'each card\'s placing time is kept');
      expect(trips.teiichiFactsOf(run).firstTaps, setup.cards - 1);

      await tester.tap(find.text(s.teiichiPlayAgain.toUpperCase()));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a placed card dragged onto the stack goes back on top; a card off a full row is refused',
        (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup(cards: 8, rows: 1);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 5), screen: usersPhoneLandscape);
      expect(spotsOf(tester).map((e) => e.$1),
          [const ClusterEnd(FieldRow.lower, RowPart.left), const ClusterEnd(FieldRow.lower, RowPart.right)],
          reason: 'one row: no open middle');
      await placeRest(tester, setup, upTo: 2);
      final placedCard = layerOf(tester).cards.keys.first;
      final from = tester.getTopLeft(layer()) + layerOf(tester).cards[placedCard]!.center;
      final pile = stackRect(layerOf(tester).placement);
      final gesture = await tester.startGesture(from);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getTopLeft(layer()) + pile.center);
      await tester.pump();
      expect(layerOf(tester).drag?.onStack, isTrue);
      await gesture.up();
      await tester.pump();
      expect(layerOf(tester).stack.first, placedCard);
      expect(layerOf(tester).stack, hasLength(setup.cards - 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('End while placing leaves with nothing recorded', (tester) async {
      final p = await open(tester);
      await show(tester, p, () => TeiichiScreen(setup: TeiichiSetup.usual, known: allCards, seed: 1),
          screen: usersPhoneLandscape);
      await tester.tap(find.widgetWithText(BandButton, s.end));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.text(_home), findsOneWidget, reason: 'with no card placed it leaves at once');
      expect(p.sideTrips.runsOf(SideTrip.teiichi), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('End or Back with cards placed asks first; Cancel stays, Leave goes', (tester) async {
      final p = await open(tester);
      await show(tester, p, () => TeiichiScreen(setup: TeiichiSetup.usual, known: allCards, seed: 1),
          screen: usersPhoneLandscape);
      await placeRest(tester, TeiichiSetup.usual, upTo: 3);
      await tester.tap(find.widgetWithText(BandButton, s.end));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(s.teiichiLeaveTitle), findsOneWidget);
      expect(find.text(s.teiichiLeaveNote), findsOneWidget);
      await captureScreen(tester, 'teiichi/leave');
      await tester.tap(find.text(s.cancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TeiichiScreen), findsOneWidget);
      expect(layerOf(tester).cards, hasLength(3), reason: 'the layout is kept');

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(s.teiichiLeaveTitle), findsOneWidget, reason: 'the Back key asks too');
      await tester.tap(find.text(s.ankirenLeave));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.text(_home), findsOneWidget);
      expect(p.sideTrips.runsOf(SideTrip.teiichi), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a guest\'s game writes nothing at all', (tester) async {
      final p = await open(tester);
      final before = await tester.runAsync(() => dbSnapshot(p.db));
      const setup = TeiichiSetup(cards: 4, rows: 1);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, player: AnkirenPlayer.guest, seed: 2),
          screen: usersPhoneLandscape);
      await placeRest(tester, setup);
      await tester.tap(find.widgetWithText(BandButton, s.done));
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime);
      await tester.pump(AnkirenMotion.flip + AnkirenPlayTuning.promptPause);
      await tester.pump();
      for (var i = 0; i < setup.cards; i++) {
        await take(tester, asked(tester));
        await tester.pump(i == setup.cards - 1 ? AnkirenPlayTuning.finishPause : AnkirenPlayTuning.promptPause);
        await tester.pump();
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      useScreen(tester, usersPhone);
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsOneWidget);
      expect(find.text(s.teiichiGuestNote), findsOneWidget);
      await captureScreen(tester, 'teiichi/results_guest');
      expect(await tester.runAsync(() => dbSnapshot(p.db)), before);
      await tester.pumpWidget(const SizedBox());
    });

    // The tip to turn the phone, over a portrait game: OK goes on with the
    // game.
    Future<void> dismissTip(WidgetTester tester, {bool never = false, S s = s}) async {
      await tester.pump(TeiichiPlayTuning.tipDelay);
      await tester.pump(Motion.route);
      expect(find.byType(TobiNotice), findsOneWidget);
      await tester.tap(never ? find.text(s.teiichiTurnNever) : find.text(s.noticeOk));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(TobiNotice), findsNothing);
    }

    testWidgets('portrait: the field across the foot at true scale, the stack over the band, played to the end',
        (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup.usual;
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 3));
      await dismissTip(tester);

      final placement = layerOf(tester).placement;
      final cardW = placement.scale * AnkirenFieldSize.cardW;
      final area = AnkirenFieldView.areaIn(tester.getSize(find.byType(AnkirenFieldView)));
      expect(placement.geometry.width * placement.scale, moreOrLessEquals(area.width), reason: 'the full width');
      expect(cardW, moreOrLessEquals(area.width / (TeiichiTuning.rowSlots * FieldGeometry.pitch - AnkirenFieldSize.cardGap) * AnkirenFieldSize.cardW));
      final own = placement.halfRect(FieldSide.own);
      expect(own.bottom, moreOrLessEquals(area.height), reason: 'the rows at the foot');
      expect(placement.ownTop - placement.bandTop, AnkirenPlayLayout.bandPortrait, reason: 'the band just above them');
      final pile = stackRect(placement);
      expect(pile.center.dx, moreOrLessEquals(own.center.dx), reason: 'the stack centred');
      expect(pile.bottom + TeiichiPlayLayout.stackTagRoom + TeiichiPlayLayout.stackMargin,
          moreOrLessEquals(placement.bandTop), reason: 'just above the band');
      await captureScreen(tester, 'teiichi/portrait_start');

      await placeRest(tester, setup, upTo: 12);
      // A drag carries the card above the finger, larger than the field's.
      final from = tester.getTopLeft(layer()) + stackRect(placement).center;
      final carry = await tester.startGesture(from);
      await carry.moveBy(const Offset(0, 20));
      await tester.pump();
      await carry.moveTo(spotAt(tester, (spot) => spot == const ClusterEnd(FieldRow.middle, RowPart.right)));
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);
      expect(layerOf(tester).drag?.spot, const ClusterEnd(FieldRow.middle, RowPart.right));
      await captureScreen(tester, 'teiichi/portrait_drag');
      await carry.up();
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.move);
      await captureScreen(tester, 'teiichi/portrait_mid');

      // Each card takes taps over itself, exactly.
      for (final MapEntry(key: id, value: r) in layerOf(tester).cards.entries) {
        final card = find.byWidgetPredicate((w) => w is AnkirenCard && w.poemId == id);
        expect(tester.getRect(card), rectMoreOrLessEquals(r.shift(tester.getTopLeft(layer())), epsilon: 0.01));
      }

      await placeRest(tester, setup);
      await captureScreen(tester, 'teiichi/portrait_done');
      await tester.tap(find.widgetWithText(BandButton, s.done));
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime ~/ 2);
      await tester.pump(TeiichiPlayLayout.zoomTime ~/ 2);
      final grown = tester.getSize(find.byType(AnkirenCard).first).width;
      // ignore: avoid_print
      if (renderScreens) print('portrait card width: ${cardW.toStringAsFixed(1)} dp, grown ${grown.toStringAsFixed(1)} dp');
      expect(grown, greaterThan(cardW * 1.3), reason: 'the gaps, not the height, stop the growth');
      await captureScreen(tester, 'teiichi/portrait_zoomed');
      await tester.pump(AnkirenMotion.flip);
      await tester.pump(AnkirenPlayTuning.promptPause);
      await tester.pump();
      for (var i = 0; i < setup.cards; i++) {
        if (i == 3) await captureScreen(tester, 'teiichi/portrait_play');
        await tester.pump(const Duration(milliseconds: 700));
        await take(tester, asked(tester));
        await tester.pump(i == setup.cards - 1 ? AnkirenPlayTuning.finishPause : AnkirenPlayTuning.promptPause);
        await tester.pump();
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      await tester.pump(Motion.route);
      await tester.pump(Motion.route);
      expect(find.byType(TeiichiResultsScreen), findsOneWidget);
      expect(p.sideTrips.runsOf(SideTrip.teiichi).single.completed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      testWidgets('the tip stops the clock while it is up, and "Don\'t show again" keeps it away ($lang)',
          (tester) async {
        final s = S(lang);
        final p = await open(tester, language: lang);
        await show(tester, p, () => TeiichiScreen(setup: TeiichiSetup.usual, known: allCards, seed: 4));
        final clock = tester.widget<MemoriseClock>(find.byType(MemoriseClock)).left;
        await tester.pump(TeiichiPlayTuning.tipDelay);
        final before = clock.value;
        await tester.pump(const Duration(seconds: 3));
        expect(find.byType(TobiNotice), findsOneWidget);
        expect(clock.value, before, reason: 'nothing is laid out while the tip is up');
        await captureScreen(tester, 'teiichi/portrait_tip', lang: lang);
        await dismissTip(tester, never: true, s: s);
        expect(p.settings.teiichiTurnTipOff, isTrue);
        final resumed = clock.value;
        await tester.pump(const Duration(seconds: 2));
        expect(clock.value, resumed + const Duration(seconds: 2), reason: 'the clock goes on once it closes');
        await tester.pumpWidget(const SizedBox());

        await show(tester, p, () => TeiichiScreen(setup: TeiichiSetup.usual, known: allCards, seed: 4));
        await tester.pump(TeiichiPlayTuning.tipDelay);
        await tester.pump(Motion.route);
        expect(find.byType(TobiNotice), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('turned mid-game: placed cards, the stack and the clock stay; a drag under way lets go', (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup.usual;
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 6), screen: usersPhoneLandscape);
      await placeRest(tester, setup, upTo: 9);
      await tester.pump(const Duration(seconds: 4));
      final placed = {...layerOf(tester).cards.keys};
      final stack = [...layerOf(tester).stack];
      final clock = tester.widget<MemoriseClock>(find.byType(MemoriseClock)).left.value;

      final moved = placed.first;
      final carry = await tester.startGesture(tester.getTopLeft(layer()) + layerOf(tester).cards[moved]!.center);
      await carry.moveBy(const Offset(0, -20));
      await tester.pump();
      await carry.moveBy(const Offset(120, -40));
      await tester.pump();
      expect(layerOf(tester).drag?.card, moved);

      useScreen(tester, usersPhone);
      await tester.pump();
      await tester.pump(Motion.route);
      expect(layerOf(tester).drag, isNull, reason: 'the drag is let go');
      expect({...layerOf(tester).cards.keys}, placed, reason: 'its card back where it was');
      expect(layerOf(tester).stack, stack);
      final after = tester.widget<MemoriseClock>(find.byType(MemoriseClock)).left.value;
      expect(after - clock, lessThanOrEqualTo(TeiichiPlayTuning.clockTick), reason: 'the clock goes on');
      expect(after, greaterThanOrEqualTo(clock));
      expect(layerOf(tester).placement.ownTop - layerOf(tester).placement.bandTop, AnkirenPlayLayout.bandPortrait,
          reason: 'laid out for portrait');
      await dismissTip(tester);
      await carry.moveBy(const Offset(-60, 30));
      await carry.up();
      await tester.pump();
      expect({...layerOf(tester).cards.keys}, placed, reason: 'the rest of the old drag does nothing');

      // After Done, the growth follows the screen's new shape.
      await placeRest(tester, setup);
      await tester.tap(find.widgetWithText(BandButton, s.done));
      await tester.pump();
      await tester.pump(TeiichiPlayLayout.zoomTime);
      Rect field() => tester.getRect(find.byType(AnkirenFieldView));
      double grownW() => tester.getSize(find.byType(AnkirenCard).first).width;
      final board = tester.widget<AnkirenFieldView>(find.byType(AnkirenFieldView)).field;
      double expected(Screen screen) {
        final area = AnkirenFieldView.areaIn(field().size);
        final band = AnkirenFieldView.bandHeight(landscape: screen.size.width > screen.size.height);
        final geometry = FieldGeometry.of(board, folded: false, trueSlots: TeiichiTuning.rowSlots);
        final scale = AnkirenFieldView.trueScaleFor(geometry, area, band: band, roomAbove: TeiichiPlayLayout.roomAbove);
        return scale * TeiichiZoom.limit(board, area, band) * AnkirenFieldSize.cardW;
      }

      expect(grownW(), moreOrLessEquals(expected(usersPhone), epsilon: 0.01));
      useScreen(tester, usersPhoneLandscape);
      await tester.pump();
      expect(grownW(), moreOrLessEquals(expected(usersPhoneLandscape), epsilon: 0.01), reason: 'at once');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a field with no room to grow turns face down at once after Done', (tester) async {
      final p = await open(tester);
      const setup = TeiichiSetup(cards: 16, rows: 3);
      await show(tester, p, () => TeiichiScreen(setup: setup, known: allCards, seed: 7), screen: usersPhoneLandscape);
      for (var i = 0; i < setup.cards; i++) {
        final want = ClusterEnd(FieldRow.lower, i.isEven ? RowPart.left : RowPart.right);
        await tapAt(tester, spotAt(tester, (spot) => spot == want));
      }
      await tester.tap(find.widgetWithText(BandButton, s.done));
      await tester.pump();
      await tester.pump(Duration.zero);
      expect(tester.widgetList<AnkirenCard>(find.byType(AnkirenCard)).where((c) => c.faceUp), isEmpty,
          reason: 'no zoom to wait for');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
