// 定位置's levels and ranked away from the screen: the level table and how it
// opens, cards left unplaced when time runs out, the score, the rating, and
// what a game stores.
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/level_ladder.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_placing.dart';
import 'package:fudatobashi/domain/teiichi_score.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/trip_rating.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/side_trips.dart';

import 'test_teiichi.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const teiichi = SideTrip.teiichi;
  final clock = DateTime(2026, 11, 2, 12);

  AnkirenAnswer call(List<TapProximity> taps, {int firstTapUs = 1400000, bool found = true}) => AnkirenAnswer(
        poemId: 1,
        side: FieldSide.own,
        wrongTaps: taps.where((t) => t != TapProximity.card).length,
        responseUs: found ? firstTapUs : null,
        at: clock,
        taps: taps,
        firstTapUs: taps.isEmpty ? null : firstTapUs,
      );

  Future<Progress> open(AppDatabase db) async {
    final p = await Progress.open(db);
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  Future<SideTripReport> record(Progress p, ({TeiichiPlacing placing, AnkirenGame game}) played) =>
      p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());

  group('the level table', () {
    test('levels 0 to 8 as decided, numbered from 0', () {
      expect(TeiichiLevels.first, 0);
      expect(TeiichiLevels.top, 8);
      expect([
        for (var l = TeiichiLevels.first; l <= TeiichiLevels.top; l++)
          if (TeiichiSetup.forLevel(l) case final s) (s.cards, s.rows, s.limit!.inSeconds, s.karafuda),
      ], [
        (4, 1, 900, 0),
        (8, 2, 900, 0),
        (12, 2, 600, 0),
        (16, 3, 300, 7),
        (20, 3, 180, 8),
        (25, 3, 180, 10),
        (25, 3, 150, 10),
        (25, 3, 120, 10),
        (25, 3, 90, 10),
      ]);
    });

    test('every level fits its rows, and every level fits the cards the island opens at', () {
      for (var l = TeiichiLevels.first; l <= TeiichiLevels.top; l++) {
        final setup = TeiichiSetup.forLevel(l);
        expect(TeiichiSetup.allows(cards: setup.cards, rows: setup.rows), isTrue, reason: 'level $l');
        expect(setup.calls, lessThanOrEqualTo(SideTripTuning.teiichiSeen), reason: 'level $l');
        expect(setup.custom, isFalse);
      }
    });

    test('ranked is the usual game, 15 minutes at most, and no level', () {
      const ranked = TeiichiSetup.ranked();
      expect((ranked.cards, ranked.rows, ranked.karafuda, ranked.limit), (25, 3, 10, const Duration(minutes: 15)));
      expect((ranked.ranked, ranked.level, ranked.custom), (true, null, false));
      expect(const TeiichiSetup(cards: 12, rows: 2).custom, isTrue);
      expect(const TeiichiSetup(cards: 12, rows: 2).limit, isNull);
    });
  });

  group('the ladder', () {
    LevelLadder cleared(Set<int> levels) => LevelLadder(levels, LadderRules.teiichi);

    test('level 0 is open at first, and each level cleared opens the next', () {
      final none = teiichi.noLevels;
      expect((none.open, none.next), (0, 0));
      expect(none.isOpen(1), isFalse);
      expect(cleared({0}).next, 1);
      expect(cleared({0, 1, 2}).open, 3);
    });

    test('ranked needs level 3 and custom level 5, whatever is cleared after it', () {
      expect(cleared({0, 1, 2}).rankedReady, isFalse);
      expect(cleared({0, 1, 2, 3}).rankedReady, isTrue);
      expect(cleared({0, 1, 2, 3, 4}).customOpen, isFalse);
      expect(cleared({0, 1, 2, 3, 4, 5}).customOpen, isTrue);
      expect(cleared({0, 1, 2, 3, 4, 5}).allCleared, isFalse);
    });

    test('once level 8 is cleared none is left to clear', () {
      final all = cleared({for (var l = 0; l <= 8; l++) l});
      expect((all.allCleared, all.next, all.open), (true, null, 8));
    });

    test('ranked stays shut until all-known mode and level 3, each on its own', () {
      final shut = RankedLock.of(allKnown: false, ladder: cleared({0, 1, 2}))!;
      expect((shut.allKnown, shut.cleared, shut.level), (false, false, 3));
      expect(RankedLock.of(allKnown: true, ladder: cleared({0, 1, 2}))!.cleared, isFalse);
      expect(RankedLock.of(allKnown: false, ladder: cleared({0, 1, 2, 3}))!.allKnown, isFalse);
      expect(RankedLock.of(allKnown: true, ladder: cleared({0, 1, 2, 3})), isNull);
    });
  });

  group('the score', () {
    test('the worked example: 1:52, 27 right first taps at 1.4 s and eight other calls', () {
      final answers = [
        for (var i = 0; i < 27; i++) call([TapProximity.card]),
        for (var i = 0; i < 4; i++) call([TapProximity.neighbour, TapProximity.card]),
        for (var i = 0; i < 2; i++) call([TapProximity.row], found: false),
        call([TapProximity.otherSide, TapProximity.card]),
        call([], found: false),
      ];
      expect({for (final a in answers) AnkirenScore.points(a)}, {122, 60, 30, 20, 0});
      final score = TeiichiScore(answers, placing: const Duration(minutes: 1, seconds: 52));
      expect(score.firstRight, 3294);
      expect(score.recall, 3614);
      expect(score.total, 5099);
      expect(TripRating.teiichi.performance(score.total), closeTo(1888.5, 0.05));
    });

    test('each halving of the 15 minutes earns 15%, fractions of one too', () {
      expect(TeiichiScore.halvings(const Duration(minutes: 15)), 0);
      expect(TeiichiScore.factorOf(const Duration(minutes: 15)), 1);
      expect(TeiichiScore.factorOf(const Duration(seconds: 450)), closeTo(1.15, 1e-9));
      expect(TeiichiScore.factorOf(const Duration(seconds: 225)), closeTo(1.30, 1e-9));
      expect(TeiichiScore.halvings(const Duration(seconds: 636)), closeTo(0.501, 0.001));
    });

    test('no bonus past the clock, and none for a time of zero', () {
      expect(TeiichiScore.halvings(const Duration(minutes: 20)), 0);
      expect(TeiichiScore.halvings(Duration.zero), 0);
      expect(TeiichiScore.factorOf(Duration.zero), 1);
    });

    test('only right first taps are multiplied, and they carry their speed points with them', () {
      final score = TeiichiScore([
        call([TapProximity.card]),
        call([TapProximity.neighbour, TapProximity.card]),
      ], placing: const Duration(seconds: 450));
      expect(score.firstRight, 122);
      expect(score.total, (122 * 1.15).round() + 60);
      expect(score.bonus, score.total - score.recall);
    });

    test('a right press of the からふだ button counts as a right first tap', () {
      final karafuda = AnkirenAnswer(
          poemId: 2, side: null, wrongTaps: 0, responseUs: 900000, at: clock, taps: const [TapProximity.card], firstTapUs: 900000);
      final score = TeiichiScore([karafuda], placing: const Duration(seconds: 450));
      expect(score.karafuda, score.recall);
      expect(score.firstRight, score.recall);
      expect(score.total, greaterThan(score.recall));
    });

    test('points scale 2.70 to the rating, and a game never performs below 0', () {
      expect(TripRating.teiichi.performance(2700), closeTo(1000, 1e-9));
      expect(TripRating.teiichi.performance(0), 0);
      expect(TripRating.teiichi.performance(-5), 0);
      expect(TripRating.ankiren.performance(2700), closeTo(2700 / AnkirenRatingModel.pointsPerRating, 1e-9),
          reason: '暗記練 keeps its own');
    });
  });

  group('time running out', () {
    TeiichiPlacing placed(TeiichiSetup setup, int cards) {
      final placing = TeiichiPlacing(setup, [for (var id = 1; id <= setup.cards; id++) id]);
      for (var i = 0; i < cards; i++) {
        expect(placing.placeTop(dealtSpot(setup, i), Duration(seconds: i + 1)), isTrue);
      }
      return placing;
    }

    test('the cards flip as they lie, and those left in the stack are unplaced', () {
      final setup = TeiichiSetup.forLevel(0);
      final placing = placed(setup, 2)..stop(setup.limit!);
      expect(placing.done, isTrue);
      expect(placing.placingTime, setup.limit);
      expect(placing.unplaced, [3, 4]);
      expect(placing.placeTop(dealtSpot(setup, 2), const Duration(hours: 1)), isFalse);
    });

    test('nothing is unplaced until the placing is over', () {
      final placing = placed(TeiichiSetup.forLevel(0), 2);
      expect(placing.unplaced, isEmpty);
    });

    test('the top card keeps the time it was on top', () {
      final placing = placed(TeiichiSetup.forLevel(0), 1)..stop(const Duration(seconds: 7));
      expect(placing.placingTimeOf(2), const Duration(seconds: 6));
      expect(placing.placingTimes.keys, [1]);
    });

    test('unplaced cards are never called, and each is a strike from the start', () {
      final setup = TeiichiSetup.forLevel(1);
      final placing = placed(setup, 6)..stop(setup.limit!);
      final game = placing.recall(Random(1), countsStrikes: true);
      expect(game.prompts.toSet(), {1, 2, 3, 4, 5, 6});
      expect(game.strikes, 2);
    });

    test('a game still ends on a laid-out card, with its からふだ among fewer calls', () {
      final setup = TeiichiSetup.forLevel(3);
      for (var seed = 0; seed < 40; seed++) {
        final placing = placed(setup, 1)..stop(setup.limit!);
        final game = placing.recall(Random(seed), karafuda: [90, 91, 92, 93, 94, 95, 96]);
        expect(game.prompts, hasLength(8));
        expect(game.prompts.last, 1);
      }
    });

    test('with no card placed nothing is called and the game is over at once, played to its end', () {
      final setup = TeiichiSetup.forLevel(3);
      final placing = placed(setup, 0)..stop(setup.limit!);
      final game = placing.recall(Random(1), karafuda: [90, 91], countsStrikes: true)..startRecall();
      expect(game.prompts, isEmpty);
      expect(game.karafuda, isEmpty);
      expect((game.phase, game.completed, game.strikes), (AnkirenPhase.done, true, setup.cards));
      expect(game.cleared, isFalse);
    });
  });

  group('recorded games', () {
    test('a level game with fewer than 3 strikes clears its level and opens the next', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final report = await record(p, playTeiichi(TeiichiSetup.forLevel(0), strikes: true, wrongAt: {0, 1}));
      expect(report.ladderBefore.isCleared(0), isFalse);
      expect(report.ladderAfter.isCleared(0), isTrue);
      expect(p.sideTripsHub()[teiichi].nextLevel, 1);
      expect((report.ratingBefore, report.ratingAfter), (null, null));

      final again = await open(db);
      expect(again.sideTripsHub()[teiichi].ladder.cleared, {0}, reason: 'it comes back on load');
      expect(again.sideTripsHub()[SideTrip.ankiren].ladder.cleared, isEmpty, reason: '暗記練 has its own');
      await db.close();
    });

    test('3 strikes fail a level, played to its end', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final played = playTeiichi(TeiichiSetup.forLevel(0), strikes: true, wrongAt: {0, 1, 2});
      expect(played.game.completed, isTrue);
      await record(p, played);
      expect(p.sideTripsHub()[teiichi].ladder.cleared, isEmpty);
      await db.close();
    });

    test('unplaced cards are strikes: 3 of them fail the level', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final setup = TeiichiSetup.forLevel(1);
      await record(p, playTeiichi(setup, strikes: true, placeCards: 5));
      expect(p.sideTripsHub()[teiichi].ladder.cleared, isEmpty);
      await record(p, playTeiichi(setup, strikes: true, placeCards: 6, wrongAt: {0}));
      expect(p.sideTripsHub()[teiichi].ladder.cleared, isEmpty, reason: 'two unplaced and a wrong tap');
      await record(p, playTeiichi(setup, strikes: true, placeCards: 6));
      expect(p.sideTripsHub()[teiichi].ladder.cleared, {1});
      await db.close();
    });

    test('a custom game clears nothing and counts no strikes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final played = playTeiichi(const TeiichiSetup(cards: 4, rows: 1));
      expect(played.game.countsStrikes, isFalse);
      await record(p, played);
      expect(p.sideTripsHub()[teiichi].ladder.cleared, isEmpty);
      await db.close();
    });

    test('ranked places over 3 games, then moves by K 0.35, on a rating of its own', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final performances = <double>[];
      for (final (i, placeMs) in [4000, 3000, 2000, 1000].indexed) {
        final played = playTeiichi(const TeiichiSetup.ranked(), placeMs: placeMs);
        final total = TeiichiScore(played.game.answers, placing: played.placing.placingTime!).total;
        final performance = TripRating.teiichi.performance(total);
        final report = await record(p, played);
        expect(report.rankedGames, i + 1);
        performances.add(performance);
        if (i == 3) {
          final placed = (performances[0] + performances[1] + performances[2]) / 3;
          expect(report.ratingBefore, closeTo(placed, 1e-9));
          expect(report.ratingAfter, closeTo(placed + 0.35 * (performance - placed), 1e-9));
        } else {
          expect(report.ratingAfter, closeTo(performances.reduce((a, b) => a + b) / performances.length, 1e-9));
        }
      }
      final entry = p.sideTripsHub()[teiichi];
      expect(entry.rating, isNotNull);
      expect([for (final r in entry.results) r.score], hasLength(4));
      expect(p.sideTripsHub()[SideTrip.ankiren].rating, isNull, reason: '暗記練 is rated apart');

      final run = (await db.select(db.sideTripRuns).get()).last;
      expect((run.ranked, run.level, run.maxScore), (true, null, null));
      expect(run.score, entry.results.last.score);
      expect(run.rating, entry.rating);
      await db.close();
    });

    test('leaving ranked is a forfeit at 0 that counts for the rating, whatever the calls earned', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final played = playTeiichi(const TeiichiSetup.ranked(), endAfter: 20);
      expect(played.game.completed, isFalse);
      final report = await record(p, played);
      expect(report.ratingAfter, 0, reason: 'the mean of one game at 0');
      final run = await db.select(db.sideTripRuns).getSingle();
      expect((run.score, run.performance, run.completed), (0, 0, false));
      await db.close();
    });

    test('a forfeit while placing keeps the cards laid out so far and the rest as unplaced', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      const setup = TeiichiSetup.ranked();
      final placing = TeiichiPlacing(setup, [for (var id = 1; id <= setup.cards; id++) id]);
      placing.placeTop(dealtSpot(setup, 0), const Duration(seconds: 2));
      placing.stop(const Duration(seconds: 5));
      final game = placing.recall(Random(1))..end();
      await p.recordTeiichi(placing, game, startedAt: DateTime.now());

      final run = await db.select(db.sideTripRuns).getSingle();
      expect((run.score, run.performance, run.completed), (0, 0, false));
      final record_ = p.sideTrips.teiichiRecordOf(run);
      expect(record_.forfeit, isTrue);
      expect(record_.placed.map((c) => c.poemId), [1]);
      expect(record_.unplaced, hasLength(setup.cards - 1));
      expect(record_.dealt, setup.cards);
      await db.close();
    });

    test('a ranked game that runs out of time scores its calls, the unplaced cards earning nothing', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final played = playTeiichi(const TeiichiSetup.ranked(), placeCards: 20);
      expect(played.placing.unplaced, hasLength(5));
      await record(p, played);
      final run = await db.select(db.sideTripRuns).getSingle();
      expect(run.score, TeiichiScore(played.game.answers, placing: played.placing.placingTime!).total);
      expect(run.completed, isTrue);
      await db.close();
    });

    test('a ranked game with no card placed scores 0 and is no forfeit', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final played = playTeiichi(const TeiichiSetup.ranked(), placeCards: 0);
      expect(played.game.prompts, isEmpty);
      await record(p, played);
      final run = await db.select(db.sideTripRuns).getSingle();
      expect((run.score, run.completed), (0, true));
      expect(p.sideTrips.teiichiRecordOf(run).forfeit, isFalse);
      await db.close();
    });

    test('unplaced cards are kept apart, in stack order, with their time on top, and come back on load', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final setup = TeiichiSetup.forLevel(1);
      await record(p, playTeiichi(setup, strikes: true, placeCards: 5, placeMs: 2000, deck: [11, 12, 13, 14, 15, 16, 17, 18]));
      final rows = await (db.select(db.teiichiPlacings)..orderBy([(x) => OrderingTerm.asc(x.seq)])).get();
      expect([for (final r in rows) r.placed], [true, true, true, true, true, false, false, false]);
      expect([for (final r in rows) r.poemId], [11, 12, 13, 14, 15, 16, 17, 18]);
      expect(rows[5].placingUs, greaterThan(0), reason: 'the card on top when the time ran out');

      final again = await open(db);
      final game = again.sideTrips.teiichiRecordOf(again.sideTrips.runsOf(teiichi).single);
      expect(game.placed, hasLength(5));
      expect(game.unplaced, [16, 17, 18]);
      expect((game.dealt, game.strikes, game.level, game.cleared), (8, 3, 1, false));
      await db.close();
    });

    test('a game with unplaced cards sets no best and no form', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await record(p, playTeiichi(TeiichiSetup.forLevel(8), strikes: true, placeCards: 24, placeMs: 100));
      final facts = p.sideTripsHub()[teiichi].placing;
      expect(facts.best, isNull);
      expect(facts.form, isNull);
      expect(facts.last?.unplaced, 1);
      await db.close();
    });

    test('a progress reset forgets the rating and the levels', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await record(p, playTeiichi(TeiichiSetup.forLevel(0), strikes: true));
      await record(p, playTeiichi(const TeiichiSetup.ranked()));
      await p.resetProgress();
      final entry = p.sideTripsHub()[teiichi];
      expect(entry.rating, isNull);
      expect(entry.ladder.cleared, isEmpty);
      expect(entry.results, isEmpty);
      final again = await open(db);
      expect(again.sideTripsHub()[teiichi].ladder.cleared, isEmpty);
      await db.close();
    });

    test('the developer tools clear levels up to one, and reset them', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await p.clearLevelsUpTo(teiichi, TeiichiTuning.rankedAfterLevel);
      expect(p.sideTripsHub()[teiichi].ladder.cleared, {0, 1, 2, 3});
      expect(p.sideTripsHub()[teiichi].rankedOpen, isTrue);
      await p.resetLevels(teiichi);
      expect(p.sideTripsHub()[teiichi].ladder.cleared, isEmpty);
      await db.close();
    });
  });
}
