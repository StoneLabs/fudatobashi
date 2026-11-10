import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_review.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/karafuda.dart';
import 'package:fudatobashi/domain/rank_ladder.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/trip_rating.dart';
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/karafuda_strings.dart';
import 'package:fudatobashi/l10n/run_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/xp_history.dart';
import 'package:fudatobashi/ui/history/ankiren_field_tab.dart';
import 'package:fudatobashi/ui/history/ankiren_game_page.dart';
import 'package:fudatobashi/ui/history/ankiren_widgets.dart';
import 'package:fudatobashi/ui/history/karafuda_panel.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/play/time_format.dart';

import 'test_field_review.dart';
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// A 暗記練 game dealt from all the poems and played out: card i found
/// [ms] + a little more for each, ready [early] before the memorise time
/// is up. The prompts in [near] get one wrong tap on another card of their
/// side first; those in [shown] a tap on the other side and one more on
/// their side, so the card is shown. With [karafuda] it calls the setup's
/// からふだ, drawn as a game draws them, each pressed: the [pressed] field
/// cards first get a press of the からふだ button, and the からふだ in
/// [karafudaNear] one card tapped first, those in [karafudaShown] two, and
/// those in [karafudaSkipped] are given up. [near], [shown] and [pressed]
/// count the field cards' calls, the karafuda sets the からふだ calls.
AnkirenGame _play(
  AnkirenSetup setup, {
  int seed = 1,
  int ms = 700,
  Duration early = Duration.zero,
  Set<int> near = const {},
  Set<int> shown = const {},
  bool karafuda = false,
  Set<int> pressed = const {},
  Set<int> karafudaNear = const {},
  Set<int> karafudaShown = const {},
  Set<int> karafudaSkipped = const {},
}) {
  final rng = Random(seed);
  final all = [for (final p in poems.all) p.id];
  final field = AnkirenDealer.ofPoems().deal(all, setup.perSide, rng, allInMiddle: setup.allInMiddle);
  final game = AnkirenGame(
    field: field,
    setup: setup,
    rng: rng,
    karafuda: karafuda ? KarafudaPicker.ofPoems.pick(field.cards, all, setup.karafuda, rng) : const [],
  )..startRecall(memorised: setup.memorise - early);
  var t = const Duration(seconds: 100);
  var card = 0, k = 0;
  for (var i = 0; game.phase == AnkirenPhase.recall; i++) {
    game.promptRevealed(t);
    final asked = game.current!;
    final side = field.sideOf(asked);
    int other(bool sameSide) =>
        field.cards.firstWhere((c) => c != asked && !game.isFound(c) && (field.sideOf(c) == side) == sameSide);
    if (side == null) {
      final open = [for (final c in field.cards) if (!game.isDone(c)) c];
      final wrong = karafudaShown.contains(k) ? 2 : karafudaNear.contains(k) ? 1 : 0;
      for (var w = 0; w < wrong; w++) {
        game.tap(open[w], t + Duration(milliseconds: 300 * (w + 1)));
      }
      t += Duration(milliseconds: ms + 150 * (i % 4) + 300 * wrong);
      if (karafudaSkipped.contains(k)) {
        game.giveUp();
      } else {
        game.pressKarafuda(t);
      }
      k++;
    } else {
      if (shown.contains(card)) {
        game.tap(other(false), t + const Duration(milliseconds: 300));
        game.tap(other(true), t + const Duration(milliseconds: 600));
      } else if (near.contains(card)) {
        game.tap(other(true), t + const Duration(milliseconds: 300));
      } else if (pressed.contains(card)) {
        game.pressKarafuda(t + const Duration(milliseconds: 300));
      }
      t += Duration(milliseconds: ms + 150 * (i % 4) + (shown.contains(card) ? 900 : 0));
      game.tap(asked, t);
      card++;
    }
    t += const Duration(milliseconds: 400);
  }
  return game;
}

/// The cards of [_everyWay]'s field and its からふだ, by the way each is
/// answered.
const _firstTap = 12, _late = 15, _shown = 93, _never = 11, _lookAlike = 31, _pressedOnCard = 42;
const _pressedRight = 50, _tappedFirst = 76, _shownKarafuda = 7, _skipped = 83;

/// A custom game of 6 a side and 4 からふだ that answers every way the
/// Field's step box shows, on cards with the longest kimariji and their
/// look-alikes: あまつ and the rest found with the first tap; きみがためは
/// on the second tap; よのなかは shown and found after three wrong taps;
/// わたのはらや given up after a wrong tap; あさぼらけあ after a tap on its
/// look-alike あさぼらけう; なにわが after a press of the からふだ button. Of
/// the からふだ, きみがためお pressed first; わたのはらこ after a tap on its
/// look-alike わたのはらや; あまの shown after two taps; よのなかよ given up.
/// The first deal that asks those with wrong taps in its first half, while
/// other cards are left to tap, and the look-alikes' calls before them.
AnkirenGame _everyWay() {
  const field = [_firstTap, _late, _shown, _never, _lookAlike, 64, _pressedOnCard, 75, 19, 68, 1, 2];
  const karafuda = [_pressedRight, _tappedFirst, _shownKarafuda, _skipped];
  const setup = AnkirenSetup.custom(perSide: 6, memorise: Duration(minutes: 1), karafuda: 4);
  for (var seed = 1;; seed++) {
    final rng = Random(seed);
    final deal = AnkirenDealer.ofPoems().deal(field, setup.perSide, rng);
    final game = AnkirenGame(field: deal, setup: setup, rng: rng, karafuda: karafuda);
    bool before(int a, int b) => game.prompts.indexOf(a) < game.prompts.indexOf(b);
    final early = [_late, _shown, _never, _lookAlike, _tappedFirst, _shownKarafuda]
        .every((c) => game.prompts.indexOf(c) < game.prompts.length / 2);
    if (!early || !before(_tappedFirst, _never) || !before(_lookAlike, 64)) continue;
    game.startRecall();
    var t = const Duration(seconds: 100);
    while (game.phase == AnkirenPhase.recall) {
      game.promptRevealed(t);
      final asked = game.current!;
      int wrong([int? card]) =>
          card != null && !game.isDone(card) ? card : deal.cards.firstWhere((c) => c != asked && !game.isDone(c));
      Duration at(int n) => t + Duration(milliseconds: 450 * n);
      switch (asked) {
        case _late:
          game.tap(wrong(), at(1));
          game.tap(asked, at(3));
        case _shown:
          for (var n = 1; n <= 3; n++) {
            game.tap(wrong(), at(n));
          }
          game.tap(asked, at(5));
        case _never:
          game.tap(wrong(), at(1));
          game.giveUp();
        case _lookAlike:
          game.tap(wrong(64), at(1));
          game.tap(asked, at(3));
        case _pressedOnCard:
          game.pressKarafuda(at(1));
          game.tap(asked, at(2));
        case _pressedRight:
          game.pressKarafuda(at(2));
        case _tappedFirst:
          game.tap(wrong(_never), at(1));
          game.pressKarafuda(at(3));
        case _shownKarafuda:
          game.tap(wrong(), at(1));
          game.tap(wrong(), at(2));
          game.pressKarafuda(at(4));
        case _skipped:
          game.giveUp();
        default:
          game.tap(asked, at(2));
      }
      t += const Duration(seconds: 5);
    }
    return game;
  }
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final day = DateTime(2026, 10, 1, 9);

  Future<Progress> openProgress({bool ja = false}) async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    p.tabsAlwaysOpen = true;
    await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true));
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  /// Three ranked games, the last the best, then a custom game
  /// after another with the same setup, and an old game without its deal
  /// or the cards its taps hit; returns [p]'s progress reopened.
  Future<Progress> recordGames(Progress p) async {
    const ranked = AnkirenSetup.ranked();
    const custom = AnkirenSetup.custom(perSide: 4, memorise: Duration(minutes: 1));
    await p.recordAnkiren(_play(ranked, seed: 3, ms: 1400, near: {0, 2, 5}, shown: {4}), startedAt: day);
    await p.recordAnkiren(_play(ranked, seed: 4, ms: 1200, near: {1, 3}), startedAt: day.add(const Duration(hours: 1)));
    await p.recordAnkiren(_play(ranked, seed: 5, early: const Duration(seconds: 48), near: {3, 7}, shown: {9}),
        startedAt: day.add(const Duration(hours: 2)));
    await p.recordAnkiren(_play(custom, seed: 6, ms: 1100, near: {2}), startedAt: day.add(const Duration(hours: 3)));
    await p.recordAnkiren(_play(custom, seed: 7, early: const Duration(seconds: 2), shown: {3}),
        startedAt: day.add(const Duration(hours: 4)));
    await p.recordAnkiren(_play(AnkirenSetup.forLevel(1), seed: 8), startedAt: day.add(const Duration(hours: 5)),
        meta: {AnkirenMeta.dealKey: null});
    final old = p.sideTrips.runs.last.id;
    await (p.db.update(p.db.sideTripAnswers)..where((a) => a.runId.equals(old)))
        .write(const SideTripAnswersCompanion(firstTapCard: Value(null), secondTapCard: Value(null)));
    return (await Progress.open(p.db))..tabsAlwaysOpen = true;
  }

  /// [recordGames]' games, then a ranked game and a level 4 game with
  /// からふだ: in the ranked one, one からふだ pressed after a card was
  /// tapped, one shown after two, one given up, and the button pressed on
  /// a field card's call; in the level game, one pressed late and the
  /// button pressed once on a card's call. Returns [p]'s progress
  /// reopened.
  Future<Progress> recordKarafudaGames(Progress p) async {
    p = await recordGames(p);
    await p.recordAnkiren(
        _play(const AnkirenSetup.ranked(),
            seed: 9,
            ms: 1100,
            karafuda: true,
            near: {4, 20},
            shown: {12},
            pressed: {7},
            karafudaNear: {1},
            karafudaShown: {3},
            karafudaSkipped: {6}),
        startedAt: day.add(const Duration(hours: 6)));
    await p.recordAnkiren(
        _play(AnkirenSetup.forLevel(4), seed: 10, ms: 900, karafuda: true, pressed: {2}, karafudaNear: {0}),
        startedAt: day.add(const Duration(hours: 7)));
    return (await Progress.open(p.db))..tabsAlwaysOpen = true;
  }

  group('AnkirenReview', () {
    late Progress p;
    late List<AnkirenGameRecord> all;
    setUp(() async {
      p = await recordGames(await openProgress());
      final trips = p.sideTrips;
      all = [for (final r in trips.runsOf(SideTrip.ankiren)) trips.recordOf(r)];
    });
    tearDown(() => p.db.close());

    test('a recorded game keeps its deal and the card each tap hit', () {
      final game = all[2];
      final deal = game.deal!;
      expect(deal.perSide, AnkirenTuning.rankedPerSide);
      expect({...deal.cards}, {for (final c in game.cards) c.poemId}, reason: 'every card dealt is asked once');
      final shown = game.cards[9];
      expect(shown.shown, isTrue);
      expect(shown.tapped, hasLength(2));
      expect(deal.sideOf(shown.tapped.first), isNot(deal.sideOf(shown.poemId)), reason: 'its first tap went across');
      expect(shown.first, TapProximity.otherSide);
      expect(game.cards[0].tapped, [game.cards[0].poemId]);
      expect(AnkirenField.fromJson(jsonDecode(jsonEncode(deal.toJson())) as Map<String, dynamic>).toJson(), deal.toJson());
      expect(all.last.deal, isNull, reason: 'recorded without its deal');
      expect(all.last.cards.every((c) => c.tapped.isEmpty), isTrue);
    });

    test('the score parts add up to the card points, and those to the score', () {
      final review = AnkirenReview(all[2], all);
      final game = review.game;
      final parts = [review.rightFirst, review.nearFirst, review.secondTaps, review.speed];
      expect(parts.fold(0, (sum, p) => sum + p.points), game.recall);
      expect(review.rightFirst.cards, game.firstTaps);
      expect(review.nearFirst.cards, 3);
      expect(review.secondTaps.cards, 3);
      expect(game.timeLeft, closeTo(48 / AnkirenTuning.rankedMemorise.inSeconds, 1e-9));
      expect(AnkirenScore.totalOf(game.recall, game.firstRight, game.timeLeft), game.score);
      expect(game.maxRecall, AnkirenScore.maxFor(game.cards.length));
    });

    test('a game is set against the earlier games with the same setup', () {
      final third = AnkirenReview(all[2], all);
      expect([for (final g in third.peers) g.id], [all[0].id, all[1].id]);
      expect(third.last!.id, all[1].id);
      final best = all[0].score! > all[1].score! ? all[0] : all[1];
      expect(third.bestBefore!.id, best.id);
      expect(third.isBest, all[2].score! > best.score!);
      expect(AnkirenReview(all[0], all).peers, isEmpty);
      expect(AnkirenReview(all[0], all).ratingBefore, TripRating.start);
      expect(third.ratingBefore, all[1].rating);
      final mix = third.usualMix;
      expect(mix.values.fold(0, (a, b) => a + b), all[0].cards.length + all[1].cards.length);
      expect(mix[TapProximity.otherSide], 1);
      final custom = AnkirenReview(all[4], all);
      expect([for (final g in custom.peers) g.id], [all[3].id], reason: 'custom games of 4 a side');
    });

    test('misplaced cards are the ones dealt twice and not always found first', () {
      final review = AnkirenReview(all[2], all);
      for (final row in review.misplaced) {
        expect(row.dealt, greaterThanOrEqualTo(AnkirenReviewTuning.misplacedMinDealt));
        expect(row.rightFirst, lessThan(row.dealt));
        expect(row.usual, isNot(TapProximity.card));
      }
      final shares = [for (final r in review.misplaced) r.rightFirst / r.dealt];
      expect(shares, [...shares]..sort());
    });

    test('a game with からふだ keeps them apart from its cards, and scores them as cards', () async {
      final q = await recordKarafudaGames(await openProgress());
      final trips = q.sideTrips;
      final games = [for (final r in trips.runsOf(SideTrip.ankiren)) trips.recordOf(r)];
      final ranked = games[games.length - 2];
      const setup = AnkirenSetup.ranked();
      expect(ranked.cards, hasLength(setup.cards));
      expect(ranked.karafuda, hasLength(setup.karafuda));
      expect(ranked.calls.last.karafuda, isFalse, reason: 'a game never ends on a からふだ');
      expect(ranked.karafuda.every((c) => ranked.deal!.sideOf(c.poemId) == null), isTrue);
      final tally = ranked.karafudaTally;
      expect([tally.called, tally.right, tally.late, tally.missed, tally.touched, tally.wrongPresses], [15, 12, 2, 1, 3, 1]);
      expect(ranked.medianFindMs, AnkirenReview.median([for (final c in ranked.calls) if (!c.karafuda) ?c.findMs]),
          reason: 'the find times leave the presses out');
      expect(ranked.medianPressMs, AnkirenReview.median([for (final c in ranked.karafuda) ?c.findMs]));
      final review = AnkirenReview(ranked, games);
      final parts = [review.rightFirst, review.nearFirst, review.secondTaps, review.speed, review.karafuda];
      expect(parts.fold(0, (sum, p) => sum + p.points), ranked.recall);
      expect(review.karafuda.cards, 13, reason: 'all but the one shown after two cards and the one given up earned');
      expect(ranked.maxRecall, AnkirenScore.maxFor(setup.calls));
      expect(AnkirenScore.totalOf(ranked.recall, ranked.firstRight, ranked.timeLeft), ranked.score);
      expect(ranked.sameSetup(games[0]), isTrue, reason: 'ranked against ranked');
      final level = games.last;
      expect([level.karafuda.length, level.karafudaTally.late, level.karafudaTally.wrongPresses], [6, 1, 1]);
      expect(level.strikes, 2);
      await q.db.close();
    });

    test('the median, the mean and the class progress', () {
      expect(AnkirenReview.median([3, 1, 2]), 2);
      expect(AnkirenReview.median([4, 1, 2, 3]), 2.5);
      expect(AnkirenReview.median([]), isNull);
      expect(AnkirenReview.mean([1, 2, 6]), 3);
      final band = RankLadder.bands[2];
      final next = RankLadder.bands[3];
      final half = (band.minRating + next.minRating) / 2;
      final progress = AnkirenReview.classProgress(half);
      expect(progress.band, band);
      expect(progress.next, next);
      expect(progress.fraction, closeTo(0.5, 1e-9));
    });
  });

  group('the game page', () {
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

    for (final ja in [false, true]) {
      final lang = ja ? 'ja' : 'en';
      for (final (phone, fontScale) in [(usersPhone, 1.0), (usersPhone, 1.3), (narrowTallPhone, 1.0), (narrowTallPhone, 1.3)]) {
        final setup = '$lang, ${phone.name} dp, font scale $fontScale';

        testWidgets('a ranked game, tab by tab ($setup)', (tester) async {
          final s = S(lang);
          late Progress p;
          await tester.runAsync(() async {
            p = await recordGames(await openProgress(ja: ja));
          });
          final runs = p.sideTrips.runsOf(SideTrip.ankiren).toList();
          final run = runs[2];
          final game = p.sideTrips.recordOf(run);
          useScreen(tester, phone, fontScale: fontScale);
          // Tobi idles for ever; with animations off the tabs settle.
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          Future<void> show(SideTripRun run) async {
            await tester.pumpWidget(RepaintBoundary(
              key: const ValueKey('screen'),
              child: ProgressScope(
                progress: p,
                child: MaterialApp(key: ValueKey(run.id), theme: buildMangaTheme(), home: AnkirenGamePage(run: run)),
              ),
            ));
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
          }

          Future<void> tab(String label, String shot) async {
            await tester.tap(find.text(label).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await captureScreen(tester, 'ankiren_game_$shot', lang: lang);
          }

          await show(run);
          expect(find.text(s.ankirenPointsLabel.toUpperCase()), findsOneWidget);
          expect(find.text('${game.firstTaps}/${game.cards.length}', findRichText: true), findsOneWidget);
          final xp = XpHistory.gainsOf(p).ankiren[run.id]!.award.total;
          expect(find.textContaining(groupDigits(xp), findRichText: true), findsOneWidget);
          expect(find.textContaining(s.ankirenMixTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenUsual), findsOneWidget);
          expect(find.byType(TierMixBar), findsNWidgets(2));
          await captureScreen(tester, 'ankiren_game_overview', lang: lang);
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'ankiren_game_overview2', lang: lang);

          await tab(s.ankirenTabField, 'field');
          expect(find.textContaining(s.ankirenFieldTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenStepCard(1, game.cards.length).toUpperCase()), findsNothing);
          await tester.ensureVisible(find.text(s.ankirenStartReview.toUpperCase()));
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.ankirenStartReview.toUpperCase()));
          await tester.pumpAndSettle();
          expect(find.text(s.ankirenStepCard(1, game.cards.length).toUpperCase()), findsOneWidget);
          await tester.ensureVisible(find.bySemanticsLabel(s.ankirenStepNext));
          await tester.pumpAndSettle();
          for (var i = 0; i < 9; i++) {
            await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
            await tester.pump();
          }
          expect(find.text(s.ankirenStepCard(10, game.cards.length).toUpperCase()), findsOneWidget);
          expect(find.text(s.ankirenBoxShownFound(game.cards[9].wrongTaps + 1)), findsOneWidget);
          await captureScreen(tester, 'ankiren_game_field_shown', lang: lang);

          await tester.tap(find.text(s.ankirenShowAll));
          await tester.pumpAndSettle();
          expect(find.text(s.ankirenStartReview.toUpperCase()), findsOneWidget);

          await tab(s.runTabCards, 'cards');
          expect(find.textContaining(s.ankirenRankedTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenColBest.toUpperCase()), findsOneWidget);
          await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'ankiren_game_cards2', lang: lang);

          await tab(s.ankirenTabScore, 'score');
          expect(find.text('${game.recall}'), findsWidgets);
          expect(find.text(s.ankirenRowCardPoints), findsOneWidget);
          await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'ankiren_game_score2', lang: lang);

          await tab(s.ankirenTabTaps, 'taps');
          expect(find.text(s.ankirenTotal), findsOneWidget);
          expect(find.text(s.ankirenShown), findsOneWidget);
          await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'ankiren_game_taps2', lang: lang);

          await show(runs[4]);
          expect(find.text(s.ankirenNotScored.toUpperCase()), findsOneWidget);
          expect(find.textContaining(s.ankirenSetupTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenTabScore), findsNothing, reason: 'a custom game has no score');
          await captureScreen(tester, 'ankiren_custom_overview', lang: lang);
          await tab(s.ankirenTabField, 'custom_field');
          await tab(s.ankirenTabTaps, 'custom_taps');
          expect(find.text(s.ankirenTotal), findsNothing);

          await show(runs[5]);
          await tab(s.ankirenTabField, 'old_field');
          expect(find.text(s.ankirenFieldMissing), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => p.db.close());
        });
      }
    }

    testWidgets('the Field shows the whole field, then reviews a tapped card with the others dimmed', (tester) async {
      const s = S('en');
      late Progress p;
      await tester.runAsync(() async {
        p = await recordGames(await openProgress());
      });
      final run = p.sideTrips.runsOf(SideTrip.ankiren).toList()[2];
      final game = p.sideTrips.recordOf(run);
      useScreen(tester, usersPhone);
      await tester.pumpWidget(ProgressScope(
        progress: p,
        child: MaterialApp(theme: buildMangaTheme(), home: AnkirenGamePage(run: run)),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.ankirenTabField).first);
      await tester.pumpAndSettle();

      final fieldCards = find.byWidgetPredicate((w) => w is AnimatedOpacity && w.duration == FieldReviewStyle.dimFade);
      final dimmed = find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == FieldReviewStyle.unrelatedOpacity);
      final total = fieldCards.evaluate().length;
      expect(total, game.deal!.cards.length);
      expect(dimmed, findsNothing, reason: 'nothing is dimmed before the review starts');
      expect(find.text(s.ankirenStartReview.toUpperCase()), findsOneWidget);
      expect(find.text(s.ankirenStepCard(1, game.cards.length).toUpperCase()), findsNothing);

      final step = game.cards.indexWhere((c) => c.tapped.any((id) => id != c.poemId));
      final card = game.cards[step];
      final context = tester.element(find.byType(AnkirenGamePage));
      final word = find.text(kimarijiFor(context, card.poemId));
      await tester.ensureVisible(word);
      await tester.tap(word);
      await tester.pumpAndSettle();
      expect(find.text(s.ankirenStepCard(step + 1, game.cards.length).toUpperCase()), findsOneWidget);
      final related = {card.poemId, ...card.tapped};
      expect(dimmed, findsNWidgets(total - related.length), reason: 'only the card and its wrong taps stay bright');

      await tester.ensureVisible(find.text(s.ankirenShowAll));
      await tester.tap(find.text(s.ankirenShowAll));
      await tester.pumpAndSettle();
      expect(dimmed, findsNothing);
      expect(find.text(s.ankirenStartReview.toUpperCase()), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => p.db.close());
    });

    for (final ja in [false, true]) {
      final lang = ja ? 'ja' : 'en';
      for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowTallPhone, 1.3)]) {
        final setup = '$lang, ${phone.name} dp, font scale $fontScale';

        testWidgets('a game with からふだ, tab by tab ($setup)', (tester) async {
          final s = S(lang);
          late Progress p;
          await tester.runAsync(() async {
            p = await recordKarafudaGames(await openProgress(ja: ja));
          });
          final runs = p.sideTrips.runsOf(SideTrip.ankiren).toList();
          final run = runs[runs.length - 2];
          final game = p.sideTrips.recordOf(run);
          useScreen(tester, phone, fontScale: fontScale);
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          Future<void> show(SideTripRun run) async {
            await tester.pumpWidget(RepaintBoundary(
              key: const ValueKey('screen'),
              child: ProgressScope(
                progress: p,
                child: MaterialApp(key: ValueKey(run.id), theme: buildMangaTheme(), home: AnkirenGamePage(run: run)),
              ),
            ));
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
          }

          Future<void> shot(String name) => captureScreen(tester, 'karafuda/history_$name', lang: lang);
          Future<void> tab(String label) async {
            await tester.tap(find.text(label).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          Future<void> down(double by) async {
            await tester.drag(find.byType(Scrollable).last, Offset(0, -by));
            await tester.pumpAndSettle();
          }

          await show(run);
          expect(find.textContaining(s.karafudaCount(game.karafuda.length).toUpperCase(), findRichText: true), findsWidgets,
              reason: 'the header');
          expect(find.text('${game.firstTaps}/${game.cards.length}', findRichText: true), findsOneWidget,
              reason: 'the tiles count the field cards');
          expect(find.byType(KarafudaPanel), findsOneWidget);
          final tally = game.karafudaTally;
          expect(find.text(s.karafudaCalled(tally.called)), findsOneWidget);
          await shot('overview');
          await tester.ensureVisible(find.byType(KarafudaPanel));
          await tester.pumpAndSettle();
          await shot('overview_karafuda');

          await tab(s.ankirenTabField);
          await tester.ensureVisible(find.text(s.ankirenStartReview.toUpperCase()));
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.ankirenStartReview.toUpperCase()));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(AnkirenGamePage));
          expect(find.text(s.karafudaStepCall(1, game.calls.length).toUpperCase()), findsOneWidget);
          final step = game.calls.indexWhere((c) => c.karafuda && c.shown);
          await tester.ensureVisible(find.bySemanticsLabel(s.ankirenStepNext));
          await tester.pumpAndSettle();
          for (var i = 0; i < step; i++) {
            await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
            await tester.pump();
          }
          await tester.pumpAndSettle();
          final karafuda = game.calls[step];
          final name = kimarijiFor(context, karafuda.poemId);
          expect(find.text(s.karafudaStepCall(step + 1, game.calls.length).toUpperCase()), findsOneWidget);
          expect(find.text(name), findsOneWidget, reason: 'in the box alone, off the field');
          expect(find.text(s.karafuda.toUpperCase()), findsOneWidget, reason: 'its tag');
          expect(find.text(s.karafudaOffField), findsOneWidget);
          expect(find.text(s.karafudaBoxShownPressed(karafuda.wrongTaps + 1)), findsOneWidget);
          final dimmed =
              find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == FieldReviewStyle.unrelatedOpacity);
          expect(dimmed, findsNWidgets(game.deal!.cards.length - karafuda.tapped.toSet().length),
              reason: 'only the cards tapped on it stay bright');
          await tester.ensureVisible(find.byType(ReviewField));
          await tester.pumpAndSettle();
          await shot('field_karafuda');
          final pressed = game.calls.indexWhere((c) => !c.karafuda && c.tapped.contains(Karafuda.button));
          await tester.ensureVisible(find.bySemanticsLabel(s.ankirenStepNext));
          await tester.pumpAndSettle();
          for (var i = step; i != pressed; i += pressed > step ? 1 : -1) {
            await tester.tap(find.bySemanticsLabel(pressed > step ? s.ankirenStepNext : s.ankirenStepBack));
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(find.text(s.karafuda), findsOneWidget, reason: 'the button pressed on a field card\'s call');
          expect(find.text(s.ankirenBoxFoundOn(2)), findsOneWidget);

          await tab(s.ankirenTabScore);
          expect(find.text(s.karafudaPart), findsOneWidget);
          await shot('score');
          await down(600);
          await shot('score2');

          await tab(s.ankirenTabTaps);
          expect(find.textContaining(s.karafudaTapsNote(game.calls.length, game.karafuda.length)), findsOneWidget);
          expect(find.descendant(of: find.byType(CallName), matching: find.text(s.karafudaChip.toUpperCase())),
              findsNWidgets(game.karafuda.length),
              reason: 'each からふだ call named in the table');
          expect(find.text(s.karafudaCaption), findsOneWidget);
          await shot('taps');
          await down(900);
          await shot('taps2');

          await show(runs.last);
          expect(find.byType(KarafudaPanel), findsOneWidget);
          await tester.ensureVisible(find.byType(KarafudaPanel));
          await tester.pumpAndSettle();
          await shot('level_overview');
          await tab(s.ankirenTabTaps);
          await shot('level_taps');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => p.db.close());
        });
      }
    }

    for (final ja in [false, true]) {
      final lang = ja ? 'ja' : 'en';
      for (final (phone, fontScale) in [(usersPhone, 1.0), (usersPhone, 1.3), (narrowTallPhone, 1.3)]) {
        testWidgets('the step box is as tall for every call ($lang, ${phone.name} dp, font scale $fontScale)',
            (tester) async {
          final s = S(lang);
          late Progress p;
          await tester.runAsync(() async {
            p = await openProgress(ja: ja);
            await p.recordAnkiren(_everyWay(), startedAt: day);
          });
          final run = p.sideTrips.runsOf(SideTrip.ankiren).last;
          final game = p.sideTrips.recordOf(run);
          useScreen(tester, phone, fontScale: fontScale);
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          await tester.pumpWidget(RepaintBoundary(
            key: screenKey,
            child: ProgressScope(
              progress: p,
              child: MaterialApp(theme: buildMangaTheme(), home: AnkirenGamePage(run: run)),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text(s.ankirenTabField).first);
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(AnkirenGamePage));
          int call(int poemId) => game.calls.indexWhere((c) => c.poemId == poemId);
          await stepThroughReview(tester, s, game.calls.length,
              screen: 'review_box/ankiren_${phone.name}',
              lang: lang,
              shots: {
                call(_firstTap): '1_first',
                call(_late): '2_late',
                call(_pressedRight): '3_karafuda_right',
                call(_tappedFirst): '4_karafuda_wrong',
                call(_never): '5_never',
                call(_shown): '6_shown',
                call(_lookAlike): '7_look_alike',
              }, check: (i) {
            final c = game.calls[i];
            final result = switch (c.poemId) {
              _firstTap || _pressedRight => s.ankirenBoxRightFirst,
              _late || _lookAlike || _pressedOnCard => s.ankirenBoxFoundOn(2),
              _shown => s.ankirenBoxShownFound(4),
              _never || _skipped => s.ankirenBoxGaveUp,
              _tappedFirst => s.karafudaBoxPressedOn(2),
              _shownKarafuda => s.karafudaBoxShownPressed(3),
              _ => null,
            };
            if (result != null) expect(inStepBox(s, result), findsOneWidget, reason: kimarijiFor(context, c.poemId));
            expect(inStepBox(s, s.karafudaOffField), c.karafuda ? findsOneWidget : findsNothing);
            expect(inStepBox(s, s.ankirenLookAlike(kimarijiFor(context, _never))),
                c.poemId == _tappedFirst ? findsOneWidget : findsNothing);
            if (c.poemId == _shown) expect(inStepBox(s, s.ankirenBoxMoreTaps(2)), findsOneWidget);
            if (c.poemId == _skipped) expect(inStepBox(s, s.ankirenBoxNoTaps), findsOneWidget);
          });
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => p.db.close());
        });
      }
    }
  });
}
