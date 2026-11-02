// 定位置 in History: what a recorded game keeps for its page (the layout,
// the placing order and times, the games before it), its tab's list and
// filter, an empty tab, the way in from 定位置's page, and each game's page
// tab by tab, in English and Japanese. With RENDER_SCREENS=1 it also
// writes PNGs to build/screens/teiichi_history/.
import 'dart:io';
import 'dart:math';

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
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_review.dart';
import 'package:fudatobashi/domain/karafuda.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_review.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/karafuda_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/teiichi_review_strings.dart';
import 'package:fudatobashi/l10n/teiichi_strings.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/history/history_widgets.dart';
import 'package:fudatobashi/ui/history/karafuda_panel.dart';
import 'package:fudatobashi/ui/history/teiichi_game_page.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';
import 'package:fudatobashi/ui/side_trips/teiichi_page.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';

import 'test_field_review.dart';
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_teiichi.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// The user's phone stretched to show each tab's whole contents.
const _tallPhone = Screen('384', Size(384, 1500), 2.8125);

/// The level game of the usual 25 cards.
final _full = TeiichiSetup.forLevel(TeiichiTuning.customAfterLevel);

/// [n] known cards from [shift] on, the same spread as 定位置's deals.
List<int> _deck(int n, int shift) => [for (var id = 1; id <= n; id++) (id * 7 + shift) % 100 + 1];

/// Placing times that wander: card i takes [base] ms and up to 3.6 s more.
int Function(int i) _times(int base) => (i) => base + (i * 37 % 10) * 400;

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
    if (renderScreens) {
      await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
      await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
      await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    }
  });

  /// An all-known player in [language] with five 定位置 games, oldest first:
  /// two 25-card level games yesterday, the second the faster; today a custom
  /// game of 12 cards in 2 rows, a 25-card level game ended early, and one
  /// slower than the best. With [games] false, none.
  Future<Progress> open(WidgetTester tester, {String language = 'en', bool games = true}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(
          p.settings.copyWith(language: language, languagePicked: true, toured: true, teiichiRulesSeen: true));
      if (!games) return;
      final today = p.dayAt().date;
      final yesterday = today.subtract(const Duration(days: 1));
      Future<void> record(DateTime at, TeiichiSetup setup,
          {required int base, required int shift, Set<int> wrongAt = const {}, int? endAfter}) async {
        final played = playTeiichi(setup,
            deck: _deck(setup.cards, shift), placeMsOf: _times(base), wrongAt: wrongAt, endAfter: endAfter);
        await p.recordTeiichi(played.placing, played.game, startedAt: at);
      }

      await record(yesterday.add(const Duration(hours: 10)), _full, base: 2400, shift: 0, wrongAt: {1, 6});
      await record(yesterday.add(const Duration(hours: 18)), _full, base: 1500, shift: 3, wrongAt: {3});
      await record(today.add(const Duration(hours: 8)), const TeiichiSetup(cards: 12, rows: 2),
          base: 1800, shift: 40, wrongAt: {0, 4});
      await record(today.add(const Duration(hours: 9, minutes: 30)), _full,
          base: 2200, shift: 9, wrongAt: {2}, endAfter: 15);
      await record(today.add(const Duration(hours: 12)), _full, base: 1800, shift: 5, wrongAt: {1, 2, 7});
    });
    return p;
  }

  /// [home] on its own in a manga app, for [p], on [screen] at [fontScale].
  Future<void> show(WidgetTester tester, Progress p, Widget home,
      {Screen screen = usersPhone, double fontScale = 1}) async {
    useScreen(tester, screen, fontScale: fontScale);
    // Tobi idles for ever; with animations off the tabs settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
            key: UniqueKey(), debugShowCheckedModeBanner: false, theme: buildMangaTheme(), home: home),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  }

  /// History from 定位置's page, for [p], on [screen].
  Future<void> openHistory(WidgetTester tester, Progress p, {Screen screen = usersPhone}) async {
    await show(tester, p, const TeiichiPage(), screen: screen);
    final s = S.of(tester.element(find.byType(TeiichiPage)));
    await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<HistoryScreen>(find.byType(HistoryScreen)).trip, SideTrip.teiichi);
  }

  group('a recorded game', () {
    testWidgets('keeps its layout, placing order and times, and is set against the games before it', (tester) async {
      final p = await open(tester);
      late Progress reopened;
      await tester.runAsync(() async => reopened = await Progress.open(p.db));
      final trips = reopened.sideTrips;
      final runs = trips.runsOf(SideTrip.teiichi).toList();
      final all = [for (final r in runs) trips.teiichiRecordOf(r)];
      expect(all, hasLength(5));

      final first = all.first;
      expect((first.setup.cards, first.setup.rows, first.setup.level), (_full.cards, _full.rows, _full.level));
      expect(first.custom, isFalse);
      expect(first.layout.cards.toSet(), _deck(TeiichiTuning.cards, 0).toSet());
      expect([for (final c in first.placed) c.poemId], _deck(TeiichiTuning.cards, 0), reason: 'in the order placed');
      expect(first.placed[1].time, Duration(milliseconds: _times(2400)(1)));
      expect(first.placing, first.placed.fold(Duration.zero, (sum, c) => sum + c.time));
      expect(first.slowest.first.time, first.placed.map((c) => c.time).reduce((a, b) => a > b ? a : b));
      expect(first.wrongTaps, 2);
      expect(first.field.own.cards, first.layout.cards);
      expect(first.recall.cards, hasLength(TeiichiTuning.cards));

      final reviews = [for (final g in all) TeiichiReview(g, all)];
      expect(reviews[0].isBest, isTrue, reason: 'the first game that counts');
      expect(reviews[1].isBest, isTrue);
      expect(reviews[1].bestBefore, all[0].placing);
      expect(reviews[2].game.custom, isTrue);
      expect(reviews[2].isBest, isFalse, reason: 'a custom game never counts');
      expect(reviews[2].peers, isEmpty);
      expect(reviews[3].game.completed, isFalse);
      expect(reviews[3].isBest, isFalse, reason: 'a game ended early never counts');
      expect(reviews[4].isBest, isFalse);
      expect(reviews[4].bestBefore, all[1].placing);
      expect([for (final g in reviews[4].peers) g.id], [all[0].id, all[1].id, all[3].id]);
      expect(reviews[4].last!.id, all[3].id);
      expect(reviews[4].recall.game.id, all[4].id);
      expect(reopened.activeStreak(), 2, reason: 'a day with a 定位置 game is a day played');
      await tester.runAsync(() => p.db.close());
    });
  });

  for (final lang in ['en', 'ja']) {
    final s = S(lang);

    group('History ($lang)', () {
      testWidgets('定位置\'s page opens History on its tab, its games newest first; the filter narrows them', (tester) async {
        final p = await open(tester, language: lang);
        await openHistory(tester, p);
        final rows = find.byWidgetPredicate((w) => w is KindTag && w.look == HistoryLooks.teiichi);
        expect(rows, findsNWidgets(5));
        expect(find.text(s.historyPracticeCustom), findsOneWidget);
        expect(find.text(s.endedEarly), findsOneWidget, reason: 'a level game ended early is not called failed');
        expect(find.text(s.historyFailed), findsWidgets);
        expect(find.text(s.teiichiBestStamp), findsNWidgets(2));
        expect(find.text(s.historyBest), findsNothing, reason: 'no ranked game, so no best score');
        expect(find.text('${s.teiichiSetupLine(12, 2)} · ${s.historyWrongTaps(2)}'), findsOneWidget);
        expect(find.textContaining(s.historyCards(25)), findsNWidgets(4));
        final placings = [for (final r in p.teiichiRuns) p.sideTrips.teiichiRecordOf(r).placing];
        final first = tester.getTopLeft(find.text(formatMinutes(placings.first)));
        final last = tester.getTopLeft(find.text(formatMinutes(placings.last)));
        expect(first.dy, lessThan(last.dy), reason: 'newest first');
        await captureScreen(tester, 'teiichi_history/list', lang: lang);

        await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.historyFilterLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(s.filterTeiichiNote), findsOneWidget);
        await tester.tap(find.text(s.historyAnkirenCustom).last);
        await tester.pump();
        await tester.pump(Motion.tab);
        await captureScreen(tester, 'teiichi_history/filter', lang: lang);
        await tester.tap(find.text(s.filterShowOne));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(rows, findsOneWidget);
        expect(find.text(s.historyPracticeCustom), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => p.db.close());
      });

      testWidgets('with no games yet the tab says so', (tester) async {
        final p = await open(tester, language: lang, games: false);
        await openHistory(tester, p);
        expect(find.text(s.noRunsYet), findsOneWidget);
        await captureScreen(tester, 'teiichi_history/empty', lang: lang);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => p.db.close());
      });
    });

    group('a game\'s page ($lang)', () {
      for (final (screen, tall) in [(usersPhone, ''), (_tallPhone, '_tall')]) {
        testWidgets('a usual game, tab by tab${tall.replaceAll('_', ' ')}', (tester) async {
          final p = await open(tester, language: lang);
          final run = p.teiichiRuns.first;
          final game = p.sideTrips.teiichiRecordOf(run);
          final best = p.sideTrips.teiichiRecordOf(p.sideTrips.runsOf(SideTrip.teiichi).elementAt(1)).placing;
          await openHistory(tester, p, screen: screen);
          await tester.tap(find.text(formatMinutes(game.placing)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(TeiichiGamePage), findsOneWidget);

          expect(find.text(s.ankirenFirstTapFact.toUpperCase()), findsWidgets);
          expect(find.text(s.teiichiBestThen(formatMinutes(best))), findsOneWidget);
          expect(find.textContaining(s.teiichiSlowestPlace, findRichText: true), findsOneWidget);
          expect(find.textContaining(s.ankirenSetupTitle, findRichText: true), findsOneWidget);
          Future<void> next() async {
            await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          await captureScreen(tester, 'teiichi_history/game$tall', lang: lang, variant: 'overview');
          await next();
          expect(find.textContaining(s.ankirenFieldTitle, findRichText: true), findsOneWidget);
          expect(find.textContaining(s.teiichiRowName(FieldRow.upper).toUpperCase()), findsOneWidget);
          await captureScreen(tester, 'teiichi_history/game$tall', lang: lang, variant: 'field');
          if (tall.isNotEmpty) {
            final step = game.recall.cards.indexWhere((c) => c.wrongTaps > 0);
            await tester.tap(find.text(s.ankirenStartReview.toUpperCase()));
            await tester.pumpAndSettle();
            for (var i = 0; i < step; i++) {
              await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
              await tester.pump();
            }
            await tester.pumpAndSettle();
            expect(find.text(s.ankirenStepCard(step + 1, game.recall.cards.length).toUpperCase()), findsOneWidget);
            await captureScreen(tester, 'teiichi_history/game$tall', lang: lang, variant: 'field_review');
          }
          await next();
          expect(find.textContaining(s.teiichiLayoutTitle, findRichText: true), findsOneWidget);
          for (var n = 1; n <= TeiichiTuning.cards; n++) {
            expect(find.text('$n'), findsWidgets);
          }
          await captureScreen(tester, 'teiichi_history/game$tall', lang: lang, variant: 'placing');
          await next();
          expect(find.textContaining(s.ankirenTapsTitle, findRichText: true), findsWidgets);
          expect(find.text(s.teiichiTapsCaption), findsOneWidget);
          await captureScreen(tester, 'teiichi_history/game$tall', lang: lang, variant: 'taps');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => p.db.close());
        });
      }

      testWidgets('a custom game and a game ended early are stamped so', (tester) async {
        final p = await open(tester, language: lang);
        final runs = p.sideTrips.runsOf(SideTrip.teiichi).toList();
        for (final (i, stamp, name) in [
          (2, s.ankirenCustom, 'custom'),
          (3, s.endedEarly, 'ended'),
        ]) {
          await show(tester, p, TeiichiGamePage(run: runs[i]), screen: _tallPhone);
          expect(find.text(stamp.toUpperCase()), findsOneWidget);
          await captureScreen(tester, 'teiichi_history/game_tall', lang: lang, variant: name);
        }
        expect(find.text(s.teiichiNotCounted), findsOneWidget, reason: 'a game ended early does not count');
        expect(find.text(s.historyFailed.toUpperCase()), findsNothing);
        expect(find.text(s.teiichiBestStamp.toUpperCase()), findsNothing, reason: 'an unplaced card never sets the best');
        await show(tester, p, TeiichiGamePage(run: runs[1]), screen: _tallPhone);
        expect(find.text(s.teiichiNewBest), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => p.db.close());
      });

      testWidgets('a level game that beats the best time is stamped with it beside its own stamp', (tester) async {
        final p = await open(tester, language: lang);
        final runs = p.sideTrips.runsOf(SideTrip.teiichi).toList();
        final game = p.sideTrips.teiichiRecordOf(runs[1]);
        expect(game.level, isNotNull);
        await show(tester, p, TeiichiGamePage(run: runs[1]), screen: _tallPhone);
        expect(find.text(s.teiichiBestStamp.toUpperCase()), findsOneWidget);
        final was = p.sideTrips.teiichiRecordOf(runs[0]).placing;
        expect(find.text(s.teiichiBestWas(formatMinutes(was)).toUpperCase()), findsOneWidget);
        final own = game.cleared ? s.historyCleared : s.historyFailed;
        expect(find.text(own.toUpperCase()), findsOneWidget, reason: 'its level stamp stays');
        await captureScreen(tester, 'teiichi_history/game_tall', lang: lang, variant: 'best_time');
        await show(tester, p, TeiichiGamePage(run: runs[4]), screen: _tallPhone);
        expect(find.text(s.teiichiBestStamp.toUpperCase()), findsNothing, reason: 'slower than the best');
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => p.db.close());
      });

      testWidgets('a game with からふだ: counted apart, named in the review and the taps', (tester) async {
        final p = await open(tester, language: lang);
        await tester.runAsync(() async {
          const setup = TeiichiSetup.usual;
          final deck = _deck(setup.cards, 11);
          final known = [for (final poem in poems.all) poem.id];
          final karafuda = KarafudaPicker.ofPoems.pick(deck, known, setup.karafuda, Random(3));
          final played = playTeiichi(setup,
              deck: deck, placeMsOf: _times(1700), wrongAt: {4}, karafuda: karafuda, karafudaWrongAt: {1, 6});
          await p.recordTeiichi(played.placing, played.game, startedAt: p.dayAt().date.add(const Duration(hours: 14)));
        });
        final run = p.sideTrips.runsOf(SideTrip.teiichi).last;
        final game = p.sideTrips.teiichiRecordOf(run);
        expect(game.setup, TeiichiSetup.usual);
        expect(game.recall.cards, hasLength(TeiichiTuning.cards));
        expect(game.recall.karafuda, hasLength(TeiichiTuning.karafuda));
        expect(game.wrongTaps, 3, reason: 'the からふだ calls\' among them');
        expect(game.wrongCards, 1);
        expect(game.recall.medianFindMs, AnkirenReview.median([for (final c in game.recall.cards) ?c.findMs]));

        await show(tester, p, TeiichiGamePage(run: run), screen: _tallPhone);
        expect(find.text(s.karafudaCalled(TeiichiTuning.karafuda)), findsOneWidget);
        expect(find.text(s.karafudaRowFirstTap), findsOneWidget, reason: 'against the same setup');
        expect(find.text(s.teiichiWrongOnKarafuda(1, 2)), findsOneWidget, reason: 'as the results say it');
        expect(find.byType(KarafudaPanel), findsOneWidget);
        await captureScreen(tester, 'karafuda/teiichi_history', lang: lang, variant: 'overview');
        Future<void> next() async {
          await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await next();
        final step = game.recall.calls.indexWhere((c) => c.karafuda && c.wrongTaps > 0);
        await tester.tap(find.text(s.ankirenStartReview.toUpperCase()));
        await tester.pumpAndSettle();
        for (var i = 0; i < step; i++) {
          await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        final name = kimarijiFor(tester.element(find.byType(TeiichiGamePage)), game.recall.calls[step].poemId);
        expect(find.text(s.karafudaStepCall(step + 1, game.recall.calls.length).toUpperCase()), findsOneWidget);
        expect(find.text(name), findsOneWidget);
        expect(find.text(s.karafudaOffField), findsOneWidget);
        await captureScreen(tester, 'karafuda/teiichi_history', lang: lang, variant: 'field_review');
        await next();
        await next();
        expect(find.text(s.karafudaCaption), findsOneWidget);
        await captureScreen(tester, 'karafuda/teiichi_history', lang: lang, variant: 'taps');

        // A custom game says its からふだ on its stamp.
        await tester.runAsync(() async {
          const setup = TeiichiSetup(cards: 12, rows: 2, karafuda: 3);
          final deck = _deck(setup.cards, 23);
          final known = [for (final poem in poems.all) poem.id];
          final karafuda = KarafudaPicker.ofPoems.pick(deck, known, setup.karafuda, Random(4));
          final played = playTeiichi(setup, deck: deck, placeMsOf: _times(1500), karafuda: karafuda);
          await p.recordTeiichi(played.placing, played.game, startedAt: p.dayAt().date.add(const Duration(hours: 15)));
        });
        await show(tester, p, TeiichiGamePage(run: p.sideTrips.runsOf(SideTrip.teiichi).last), screen: _tallPhone);
        expect(find.text(s.ankirenCustom.toUpperCase()), findsOneWidget);
        expect(find.textContaining(s.karafudaCount(3).toUpperCase(), findRichText: true), findsWidgets);
        await captureScreen(tester, 'karafuda/teiichi_history', lang: lang, variant: 'custom');
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => p.db.close());
      });

      for (final (screen, fontScale) in [(usersPhone, 1.0), (usersPhone, 1.3), (narrowTallPhone, 1.3)]) {
        testWidgets(
            'the step box is as tall for every call, and the groups are counted (${screen.name} dp, '
            'font scale $fontScale)', (tester) async {
          // Two cards in the open middle; wrong taps on the first calls that
          // are cards, a card tapped on the second からふだ, and the game
          // ended on the last call, so that card is never found.
          final p = await open(tester, language: lang, games: false);
          await tester.runAsync(() async {
            const setup = TeiichiSetup.usual;
            final deck = _deck(setup.cards, 17);
            final known = [for (final poem in poems.all) poem.id];
            final karafuda = KarafudaPicker.ofPoems.pick(deck, known, setup.karafuda, Random(5));
            final played = playTeiichi(setup,
                deck: deck,
                placeMsOf: _times(1600),
                spotOf: (i) => i < 2 ? const OpenMiddle(AnkirenTuning.middleRow, 0) : null,
                wrongAt: {1, 2, 3, 4},
                karafuda: karafuda,
                karafudaWrongAt: {1},
                endAfter: setup.calls - 1);
            await p.recordTeiichi(played.placing, played.game, startedAt: p.dayAt().date.add(const Duration(hours: 9)));
          });
          final run = p.sideTrips.runsOf(SideTrip.teiichi).last;
          final game = p.sideTrips.teiichiRecordOf(run);
          final layout = game.layout;
          final left = [for (final r in layout.rows) ...r.left];
          final right = [for (final r in layout.rows) ...r.right];
          expect(layout.middleCards, hasLength(2));
          expect(left.length + right.length + layout.middleCards.length, TeiichiTuning.cards);
          final rightFirst = {for (final c in game.recall.cards) if (c.firstTry) c.poemId};

          await show(tester, p, TeiichiGamePage(run: run), screen: screen, fontScale: fontScale);
          await tester.tap(find.text(s.ankirenTabField).first);
          await tester.pumpAndSettle();
          final bands = [for (final b in tester.widgetList<TileBand>(find.byType(TileBand))) b.tiles];
          expect(bands, hasLength(2), reason: 'the rows, then the groups');
          for (final (i, (name, cards)) in [(s.teiichiGroupLeft, left), (s.teiichiGroupRight, right)].indexed) {
            final tile = bands[1][i];
            expect(tile.label, '$name\n${s.ankirenColRightFirst}'.toUpperCase());
            final figure = tile.big as TileFigure;
            expect([figure.value, figure.unit], ['${cards.where(rightFirst.contains).length}', '/${cards.length}']);
          }
          expect(find.text(s.teiichiMiddleNeither), findsOneWidget);
          await tester.ensureVisible(find.text(s.teiichiMiddleNeither));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'review_box/teiichi_${screen.name}', lang: lang, variant: '0_tiles');

          final calls = game.recall.calls;
          int first(bool Function(AnkirenCardTry c) test) => calls.indexWhere(test);
          await stepThroughReview(tester, s, calls.length,
              screen: 'review_box/teiichi_${screen.name}',
              lang: lang,
              shots: {
                first((c) => !c.karafuda && c.firstTry): '1_first',
                first((c) => !c.karafuda && c.found && c.wrongTaps > 0): '2_late',
                first((c) => c.karafuda && c.firstTry): '3_karafuda_right',
                first((c) => c.karafuda && c.wrongTaps > 0): '4_karafuda_wrong',
                calls.length - 1: '5_never',
              }, check: (i) {
            final c = calls[i];
            if (c.karafuda) {
              expect(inStepBox(s, s.karafudaOffField), findsOneWidget);
            } else {
              final at = layout.placeOf(c.poemId)!;
              expect(inStepBox(s, s.teiichiSpotName(at.row, at.part)), findsOneWidget);
            }
            if (i == calls.length - 1) {
              expect(inStepBox(s, s.ankirenNotFound), findsOneWidget);
              expect(inStepBox(s, s.ankirenBoxNoTaps), findsOneWidget);
            }
          });
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => p.db.close());
        });
      }
    });
  }
}
