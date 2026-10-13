import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

import 'test_ankiren.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const ankiren = SideTrip.ankiren;
  final startedAt = DateTime(2026, 10, 12, 9);

  Future<Progress> allKnown(AppDatabase db) async {
    final p = await Progress.open(db);
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  test('a ranked game is stored with its answers and places the rating; free play leaves it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    final fresh = p.sideTripsHub()[ankiren];
    expect([fresh.rating, fresh.rankedLevel, fresh.maxLevel, fresh.games], [null, 0, AnkirenLevels.top, 0]);

    var notified = 0;
    p.addListener(() => notified++);
    final perfect = playAnkiren(AnkirenSetup.forLevel(0, ranked: true), ms: 100);
    final first = await p.recordAnkiren(perfect, startedAt: startedAt);
    expect(notified, 1);
    final placed = AnkirenRating.update(
        AnkirenRating.start, AnkirenRating.performance(0, 1, placement: true), 0);
    final stored = p.sideTrips.runs.single;
    expect([stored.ranked, stored.level, stored.completed, stored.cardCount, stored.score, stored.maxScore],
        [true, 0, true, perfect.prompts.length, perfect.score!.total, perfect.score!.max]);
    expect([stored.rating, stored.performance], [placed, AnkirenRating.performance(0, 1, placement: true)]);
    expect([first.ratingBefore, first.ratingAfter], [AnkirenRating.start, placed]);
    expect(
        placed - AnkirenRating.start,
        closeTo(
            AnkirenRatingModel.placementK *
                AnkirenRatingModel.placementStretch *
                AnkirenRatingModel.weight *
                (1 - AnkirenRatingModel.par),
            1e-9),
        reason: 'placement: K ${AnkirenRatingModel.placementK} of a stretched performance');
    expect(p.sideTrips.missesIn(stored), 0);
    expect(stored.meta, contains('"perSide":${AnkirenLevels.of(0).perSide}'));
    expect(Rating.bandOf(placed), isNot(Rating.bandOf(AnkirenRating.start)));

    final answers = await (db.select(db.sideTripAnswers)..where((a) => a.runId.equals(stored.id))).get();
    expect([for (final a in answers) a.poemId], perfect.prompts);
    expect([for (final a in answers) a.seq], List.generate(answers.length, (i) => i));
    expect(answers.every((a) => a.wrongTaps == 0 && a.responseUs == 100000), isTrue);

    final hub = p.sideTripsHub()[ankiren];
    expect([hub.rating, hub.rankedLevel, hub.games], [placed, AnkirenRating.levelFor(placed, maxLevel: 10), 1]);

    final free = await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(2), wrongAt: {0, 3}), startedAt: startedAt);
    expect([free.ratingBefore, free.ratingAfter], [null, null]);
    expect(p.sideTrips.ratingOf(ankiren), placed, reason: 'free play never moves the rating');
    expect(p.sideTrips.rankedGames(ankiren), 1);
    final run = p.sideTrips.runs.last;
    expect([run.game, run.ranked, run.level, run.rating, run.performance], ['ankiren', false, 2, null, null]);
    expect(p.sideTrips.missesIn(run), 2);

    final again = await Progress.open(db);
    expect(again.sideTrips.runs, p.sideTrips.runs, reason: 'survives a restart');
    expect(again.sideTrips.missesIn(again.sideTrips.runs.last), 2);
    expect(again.sideTripsHub()[ankiren].rating, placed);
    await db.close();
  });

  test('placement moves the rating fully for its games, then by the established K', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    final ratings = <double>[];
    for (var game = 0; game <= AnkirenRatingModel.placementGames; game++) {
      final level = p.sideTripsHub()[ankiren].rankedLevel!;
      final played = playAnkiren(AnkirenSetup.forLevel(level, ranked: true), seed: game, ms: 3000);
      final report = await p.recordAnkiren(played, startedAt: startedAt);
      final placing = game < AnkirenRatingModel.placementGames;
      final perf = AnkirenRating.performance(level, played.score!.fraction, placement: placing);
      final k = placing ? AnkirenRatingModel.placementK : AnkirenRatingModel.establishedK;
      expect(report.ratingAfter, closeTo(report.ratingBefore! + k * (perf - report.ratingBefore!), 1e-9));
      ratings.add(report.ratingAfter!);
    }
    expect(p.sideTrips.rankedGames(ankiren), AnkirenRatingModel.placementGames + 1);
    expect(p.sideTrips.ratingOf(ankiren), ratings.last);
    await db.close();
  });

  test('a ranked game ended early counts; its unasked cards are stored as never found', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    final game = playAnkiren(AnkirenSetup.forLevel(1, ranked: true), endAfter: 3);
    final report = await p.recordAnkiren(game, startedAt: startedAt, meta: {'layout': 'v2'});
    expect(report.ratingAfter, isNotNull);
    final answers = await db.select(db.sideTripAnswers).get();
    final cards = AnkirenLevels.of(1).cards;
    expect([for (final a in answers) a.responseUs == null], [for (var i = 0; i < cards; i++) i >= 3]);
    final run = p.sideTrips.runs.single;
    expect([run.completed, run.cardCount], [false, cards]);
    expect(p.sideTrips.missesIn(run), cards - 3);
    expect(run.meta, contains('"layout":"v2"'));
    expect(run.meta, contains('"perSide":${AnkirenLevels.of(1).perSide}'));
    await db.close();
  });

  test('each answer keeps where its taps landed; a custom game is stored without a score', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    final free = playAnkiren(AnkirenSetup.forLevel(2), wrongAt: {0});
    await p.recordAnkiren(free, startedAt: startedAt);
    final rows = await db.select(db.sideTripAnswers).get();
    expect([for (final r in rows) [r.firstTap, r.firstTapUs, r.secondTap]], [
      for (final a in free.answers) [a.taps.first.index, a.firstTapUs, a.taps.elementAtOrNull(1)?.index],
    ]);
    expect([rows.first.firstTap, rows.first.secondTap], isNot(contains(null)), reason: 'a wrong tap, then the card');
    expect(rows.skip(1).map((r) => r.secondTap), everyElement(isNull), reason: 'found with the first tap');
    expect([for (final r in rows.skip(1)) r.firstTapUs], [for (final r in rows.skip(1)) r.responseUs]);
    final again = await Progress.open(db);
    expect([for (final a in again.sideTrips.answersOf(again.sideTrips.runs.single)) [a.taps, a.firstTapUs]],
        [for (final a in free.answers) [a.taps, a.firstTapUs]]);

    final custom = await p.recordAnkiren(
        playAnkiren(const AnkirenSetup.custom(perSide: 4, memorise: Duration(minutes: 1))),
        startedAt: startedAt);
    final run = p.sideTrips.runs.last;
    expect([run.level, run.score, run.maxScore, run.rating, run.performance], [null, null, null, null, null]);
    expect(custom.xp!.award.parts, isEmpty);
    await db.close();
  });

  test('every tap that counts is stored: a reloaded game scores and earns as it did when played', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    final rng = math.Random(4);
    final setup = AnkirenSetup.forLevel(3);
    final field = AnkirenDealer.ofPoems().deal([for (final poem in poems.all) poem.id], setup.perSide, rng);
    final game = AnkirenGame(field: field, setup: setup, rng: rng)..startRecall();
    var t = const Duration(seconds: 100);
    const step = Duration(milliseconds: 300);
    // From none to three wrong taps a card; every fifth given up.
    for (var i = 0; game.phase == AnkirenPhase.recall; i++) {
      game.promptRevealed(t += step);
      final asked = game.current!;
      for (final other in field.cards.where((c) => c != asked && !game.isDone(c)).take(i % 4)) {
        game.tap(other, t += step);
      }
      i % 5 == 4 ? game.giveUp() : game.tap(asked, t += step);
    }
    await p.recordAnkiren(game, startedAt: startedAt);
    final again = await Progress.open(db);
    final stored = again.sideTrips.answersOf(again.sideTrips.runs.single);
    expect([for (final a in stored) [a.taps, a.firstTapUs]], [for (final a in game.answers) [a.taps, a.firstTapUs]]);
    expect([for (final a in stored) AnkirenScore.pointsOf(a.taps, a.firstTapUs)],
        [for (final a in game.answers) AnkirenScore.points(a)]);
    expect(again.xp.total, p.xp.total);
    await db.close();
  });

  test('a progress reset deletes every side-trip game', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true)), startedAt: startedAt);
    await p.resetProgress();
    expect(await db.select(db.sideTripRuns).get(), isEmpty);
    expect(await db.select(db.sideTripAnswers).get(), isEmpty);
    expect(p.sideTrips.runs, isEmpty);
    await p.setLearningMode(LearningMode.allKnown);
    final hub = p.sideTripsHub()[ankiren];
    expect([hub.rating, hub.rankedLevel, hub.games], [null, 0, 0]);
    await db.close();
  });

  test('the ranked level is capped by the levels the known cards fill', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await allKnown(db);
    await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true)), startedAt: startedAt);
    final rating = p.sideTrips.ratingOf(ankiren)!;
    expect(AnkirenRating.levelFor(rating, maxLevel: AnkirenLevels.top), greaterThan(1));
    for (final (known, maxLevel) in [(100, AnkirenLevels.top), (8, 1), (7, 0), (5, null)]) {
      final standing = p.sideTrips.standingOf(ankiren, known: known);
      expect([standing.maxLevel, standing.rankedLevel],
          [maxLevel, maxLevel == null ? null : AnkirenRating.levelFor(rating, maxLevel: maxLevel)],
          reason: '$known known cards');
    }

    // The hub counts the cards known in journey mode.
    final journey = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await journey.setLearningMode(LearningMode.journey);
    final ids = [for (final g in initialGroups) ...fudaSets['initial:$g'].poemIds].take(10).toList();
    for (final id in ids) {
      journey.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    final session = PlaySession([for (final id in ids) CardRef(id)]);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += const Duration(milliseconds: 700);
      session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    await journey.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
    expect(journey.knownCards, hasLength(10));
    final entry = journey.sideTripsHub()[ankiren];
    expect([entry.maxLevel, entry.rankedLevel], [AnkirenLevels.maxLevelFor(10), 0]);
    expect(entry.maxLevel, 2);
    await db.close();
    await journey.db.close();
  });
}
