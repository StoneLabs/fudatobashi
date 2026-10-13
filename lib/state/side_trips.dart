import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../domain/ankiren_game.dart';
import '../domain/ankiren_level.dart';
import '../domain/ankiren_rating.dart';
import '../domain/side_trips.dart';

/// What recording a 暗記練 game changed (for its results): 暗記練's rating
/// before and after a ranked game, both null for free play.
class AnkirenReport {
  const AnkirenReport({required this.ratingBefore, required this.ratingAfter});

  final double? ratingBefore;
  final double? ratingAfter;
}

/// The side trips' recorded games (寄り道), in the order they were played,
/// and what they add up to: each trip's ranked rating, its ranked games and
/// the hub's standing. Owned by `Progress`, which loads it on start.
class SideTrips {
  SideTrips._(this._runs, this._firstTries);

  static Future<SideTrips> load(AppDatabase db) async {
    final runs = await (db.select(db.sideTripRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
    final firstTry = db.sideTripAnswers.wrongTaps.equals(0) & db.sideTripAnswers.responseUs.isNotNull();
    final count = db.sideTripAnswers.id.count(filter: firstTry);
    final query = db.selectOnly(db.sideTripAnswers)
      ..addColumns([db.sideTripAnswers.runId, count])
      ..groupBy([db.sideTripAnswers.runId]);
    final firstTries = {
      for (final row in await query.get()) row.read(db.sideTripAnswers.runId)!: row.read(count)!,
    };
    return SideTrips._(runs, firstTries);
  }

  final List<SideTripRun> _runs;

  /// Cards found with the first tap, by run id.
  final Map<int, int> _firstTries;

  /// Every recorded game of every trip, oldest first.
  List<SideTripRun> get runs => List.unmodifiable(_runs);

  /// [trip]'s games, ranked and free, oldest first.
  Iterable<SideTripRun> runsOf(SideTrip trip) => _runs.where((r) => r.game == trip.name);

  /// [trip]'s ranked games that moved its rating, oldest first.
  Iterable<SideTripRun> _rated(SideTrip trip) => runsOf(trip).where((r) => r.ranked && r.rating != null);

  /// [trip]'s ranked rating: its last ranked game's; null before the first.
  double? ratingOf(SideTrip trip) => _rated(trip).lastOrNull?.rating;

  /// [trip]'s ranked games so far (placement counts them).
  int rankedGames(SideTrip trip) => _rated(trip).length;

  /// The cards of [run] not found with the first tap: found after a wrong
  /// tap, shown, or never found.
  int missesIn(SideTripRun run) => run.cardCount - (_firstTries[run.id] ?? 0);

  /// [trip]'s standing on the hub for a player who knows [known] cards: a
  /// ranked level capped by the levels those cards fill, and what the last
  /// ranked game did to the rating (from the start for the first).
  SideTripStanding standingOf(SideTrip trip, {required int known}) {
    final rated = [for (final r in _rated(trip)) r.rating!];
    final rating = rated.lastOrNull;
    final start = switch (trip) {
      SideTrip.ankiren => AnkirenRating.start,
    };
    final maxLevel = switch (trip) {
      SideTrip.ankiren => AnkirenLevels.maxLevelFor(known),
    };
    final rankedLevel = switch (trip) {
      SideTrip.ankiren => maxLevel == null ? null : AnkirenRating.levelFor(rating ?? start, maxLevel: maxLevel),
    };
    return SideTripStanding(
      rating: rating,
      ratingChange: rating == null ? null : rating - (rated.length > 1 ? rated[rated.length - 2] : start),
      rankedLevel: rankedLevel,
      maxLevel: maxLevel,
      games: runsOf(trip).length,
    );
  }

  /// Stores [game], once it is over (see [AnkirenGame.end]), as started at
  /// [startedAt]: its run and one answer per card asked, in one transaction,
  /// with [meta] added to the run's own details. A ranked game moves
  /// 暗記練's rating toward its performance (see [AnkirenRating]), placing
  /// it during the first ranked games; free play never touches it.
  Future<AnkirenReport> recordAnkiren(
    AppDatabase db,
    AnkirenGame game, {
    required DateTime startedAt,
    Map<String, Object?> meta = const {},
  }) async {
    assert(game.phase == AnkirenPhase.done, 'a game is recorded once it is over');
    const trip = SideTrip.ankiren;
    final setup = game.setup;
    final score = game.score;
    final before = setup.ranked ? ratingOf(trip) ?? AnkirenRating.start : null;
    double? performance, after;
    if (before != null) {
      final gamesSoFar = rankedGames(trip);
      performance = AnkirenRating.performance(setup.level!, score.fraction,
          placement: AnkirenRating.isPlacement(gamesSoFar));
      after = AnkirenRating.update(before, performance, gamesSoFar);
    }

    final runId = await db.transaction(() async {
      final id = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
            game: trip.name,
            startedAt: startedAt,
            ranked: setup.ranked,
            level: Value(setup.level),
            cardCount: game.prompts.length,
            score: score.total,
            maxScore: score.max,
            completed: game.completed,
            rating: Value(after),
            performance: Value(performance),
            meta: Value(jsonEncode({
              'perSide': setup.perSide,
              'memoriseMs': setup.memorise.inMilliseconds,
              'middle': game.field.own.middleCards.length + game.field.opponent.middleCards.length,
              'memorisedMs': game.memorised.inMilliseconds,
              ...meta,
            })),
          ));
      await db.batch((b) => b.insertAll(db.sideTripAnswers, [
            for (final (i, a) in game.answers.indexed)
              SideTripAnswersCompanion.insert(
                runId: id,
                seq: i,
                poemId: a.poemId,
                wrongTaps: a.wrongTaps,
                responseUs: Value(a.responseUs),
                at: a.at,
              ),
          ]));
      return id;
    });
    _runs.add(await (db.select(db.sideTripRuns)..where((r) => r.id.equals(runId))).getSingle());
    _firstTries[runId] = score.firstTries;

    return AnkirenReport(ratingBefore: before, ratingAfter: after);
  }

  /// Forgets every game, once the caller has deleted them from the database.
  void clear() {
    _runs.clear();
    _firstTries.clear();
  }
}
