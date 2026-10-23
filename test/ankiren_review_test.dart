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
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/ankiren_review.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/run_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/xp_history.dart';
import 'package:fudatobashi/ui/history/ankiren_game_page.dart';
import 'package:fudatobashi/ui/history/ankiren_widgets.dart';
import 'package:fudatobashi/ui/manga/theme.dart';

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
/// their side, so the card is shown.
AnkirenGame _play(
  AnkirenSetup setup, {
  int seed = 1,
  int ms = 700,
  Duration early = Duration.zero,
  Set<int> near = const {},
  Set<int> shown = const {},
}) {
  final rng = Random(seed);
  final field = AnkirenDealer.ofPoems()
      .deal([for (final p in poems.all) p.id], setup.perSide, rng, allInMiddle: setup.allInMiddle);
  final game = AnkirenGame(field: field, setup: setup, rng: rng)..startRecall(memorised: setup.memorise - early);
  var t = const Duration(seconds: 100);
  for (var i = 0; game.phase == AnkirenPhase.recall; i++) {
    game.promptRevealed(t);
    final asked = game.current!;
    final side = field.sideOf(asked);
    int other(bool sameSide) =>
        field.cards.firstWhere((c) => c != asked && !game.isFound(c) && (field.sideOf(c) == side) == sameSide);
    if (shown.contains(i)) {
      game.tap(other(false), t + const Duration(milliseconds: 300));
      game.tap(other(true), t + const Duration(milliseconds: 600));
    } else if (near.contains(i)) {
      game.tap(other(true), t + const Duration(milliseconds: 300));
    }
    t += Duration(milliseconds: ms + 150 * (i % 4) + (shown.contains(i) ? 900 : 0));
    game.tap(asked, t);
    t += const Duration(milliseconds: 400);
  }
  return game;
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
      expect(AnkirenReview(all[0], all).ratingBefore, AnkirenRating.start);
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

    test('the median, the mean and the class progress', () {
      expect(AnkirenReview.median([3, 1, 2]), 2);
      expect(AnkirenReview.median([4, 1, 2, 3]), 2.5);
      expect(AnkirenReview.median([]), isNull);
      expect(AnkirenReview.mean([1, 2, 6]), 3);
      final band = Rating.bands[2];
      final next = Rating.bands[3];
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
          expect(find.text('${game.firstTaps}/${game.cards.length}'), findsOneWidget);
          final xp = XpHistory.gainsOf(p).ankiren[run.id]!.award.total;
          expect(find.text('+$xp'), findsOneWidget);
          expect(find.textContaining(s.ankirenMixTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenUsual), findsOneWidget);
          expect(find.byType(TierMixBar), findsNWidgets(2));
          await captureScreen(tester, 'ankiren_game_overview', lang: lang);
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
          await tester.pumpAndSettle();
          await captureScreen(tester, 'ankiren_game_overview2', lang: lang);

          await tab(s.ankirenTabField, 'field');
          expect(find.textContaining(s.ankirenFieldTitle, findRichText: true), findsOneWidget);
          expect(find.textContaining(s.ankirenStepCard(1, game.cards.length, '')), findsNothing);
          await tester.ensureVisible(find.text(s.ankirenStartReview, findRichText: true));
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.ankirenStartReview, findRichText: true));
          await tester.pumpAndSettle();
          expect(find.textContaining(s.ankirenStepCard(1, game.cards.length, '')), findsOneWidget);
          await tester.ensureVisible(find.bySemanticsLabel(s.ankirenStepNext));
          await tester.pumpAndSettle();
          for (var i = 0; i < 9; i++) {
            await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
            await tester.pump();
          }
          expect(find.textContaining(s.ankirenStepCard(10, game.cards.length, '')), findsOneWidget);
          expect(find.textContaining(s.ankirenShownFound('X').split('X').first), findsOneWidget);
          await captureScreen(tester, 'ankiren_game_field_shown', lang: lang);

          await tester.tap(find.text(s.ankirenShowAll));
          await tester.pumpAndSettle();
          expect(find.text(s.ankirenStartReview, findRichText: true), findsOneWidget);

          await tab(s.runTabCards, 'cards');
          expect(find.textContaining(s.ankirenRankedTitle, findRichText: true), findsOneWidget);
          expect(find.text(s.ankirenColBest), findsOneWidget);
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
          expect(find.text(s.ankirenRightFirstLabel.toUpperCase()), findsOneWidget);
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

      final fieldCards = find.byWidgetPredicate((w) => w is AnimatedOpacity && w.duration == AnkirenReviewStyle.dimFade);
      final dimmed = find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == AnkirenReviewStyle.unrelatedOpacity);
      final total = fieldCards.evaluate().length;
      expect(total, game.deal!.cards.length);
      expect(dimmed, findsNothing, reason: 'nothing is dimmed before the review starts');
      expect(find.text(s.ankirenStartReview, findRichText: true), findsOneWidget);
      expect(find.textContaining(s.ankirenStepCard(1, game.cards.length, '')), findsNothing);

      final step = game.cards.indexWhere((c) => c.tapped.any((id) => id != c.poemId));
      final card = game.cards[step];
      final context = tester.element(find.byType(AnkirenGamePage));
      final word = find.text(kimarijiFor(context, card.poemId));
      await tester.ensureVisible(word);
      await tester.tap(word);
      await tester.pumpAndSettle();
      expect(find.textContaining(s.ankirenStepCard(step + 1, game.cards.length, '')), findsOneWidget);
      final related = {card.poemId, ...card.tapped};
      expect(dimmed, findsNWidgets(total - related.length), reason: 'only the card and its wrong taps stay bright');

      await tester.ensureVisible(find.text(s.ankirenShowAll));
      await tester.tap(find.text(s.ankirenShowAll));
      await tester.pumpAndSettle();
      expect(dimmed, findsNothing);
      expect(find.text(s.ankirenStartReview, findRichText: true), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => p.db.close());
    });
  });
}
