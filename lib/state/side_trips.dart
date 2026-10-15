import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../domain/ankiren_field.dart';
import '../domain/ankiren_game.dart';
import '../domain/ankiren_level.dart';
import '../domain/ankiren_rating.dart';
import '../domain/ankiren_review.dart';
import '../domain/ankiren_xp.dart';
import '../domain/side_trips.dart';
import '../domain/xp.dart';

/// What recording a 暗記練 game changed (for its results): 暗記練's rating
/// before and after a ranked game, both null for free play; the ranked
/// games played with it (0 for free play); and the experience it earned.
class AnkirenReport {
  const AnkirenReport({required this.ratingBefore, required this.ratingAfter, this.rankedGames = 0, this.xp});

  final double? ratingBefore;
  final double? ratingAfter;
  final int rankedGames;
  final XpGain? xp;
}

/// The side trips' recorded games (寄り道), in the order they were played,
/// and what they add up to: each trip's ranked rating, its ranked games and
/// the hub's standing. Owned by `Progress`, which loads it on start.
class SideTrips {
  SideTrips._(this._runs, this._answers, this._poems);

  static Future<SideTrips> load(AppDatabase db) async {
    final runs = await (db.select(db.sideTripRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
    final rows = await (db.select(db.sideTripAnswers)
          ..orderBy([(a) => OrderingTerm.asc(a.runId), (a) => OrderingTerm.asc(a.seq)]))
        .get();
    final answers = <int, List<AnkirenXpAnswer>>{};
    final poems = <int, List<int>>{};
    for (final a in rows) {
      (poems[a.runId] ??= []).add(a.poemId);
      (answers[a.runId] ??= []).add((
        wrongTaps: a.wrongTaps,
        responseUs: a.responseUs,
        taps: [
          for (final place in [a.firstTap, a.secondTap])
            if (place != null) ?TapProximity.values.elementAtOrNull(place),
        ],
        firstTapUs: a.firstTapUs,
      ));
    }
    return SideTrips._(runs, answers, poems);
  }

  final List<SideTripRun> _runs;

  /// Each run's answers, in the order they were asked, by run id.
  final Map<int, List<AnkirenXpAnswer>> _answers;

  /// Each run's cards, in the order they were asked, by run id.
  final Map<int, List<int>> _poems;

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

  /// [run]'s answers, one per card asked, in order.
  List<AnkirenXpAnswer> answersOf(SideTripRun run) => List.unmodifiable(_answers[run.id] ?? const []);

  /// [run]'s cards, in the order they were asked.
  List<int> poemsOf(SideTripRun run) => List.unmodifiable(_poems[run.id] ?? const []);

  /// [run] as History reviews it.
  AnkirenGameRecord recordOf(SideTripRun run) {
    final poems = _poems[run.id] ?? const [];
    return AnkirenGameRecord(
      id: run.id,
      startedAt: run.startedAt,
      ranked: run.ranked,
      level: run.level,
      score: run.score,
      maxScore: run.maxScore,
      completed: run.completed,
      rating: run.rating,
      performance: run.performance,
      meta: run.meta,
      cards: [
        for (final (i, a) in answersOf(run).indexed)
          AnkirenCardTry(
            poemId: poems[i],
            wrongTaps: a.wrongTaps,
            responseUs: a.responseUs,
            taps: a.taps,
            firstTapUs: a.firstTapUs,
          ),
      ],
    );
  }

  /// The cards of [run] not found with the first tap: found after a wrong
  /// tap, shown, or never found.
  int missesIn(SideTripRun run) =>
      run.cardCount - answersOf(run).where((a) => a.wrongTaps == 0 && a.responseUs != null).length;

  /// [trip]'s standing on the hub for a player who knows [known] cards: a
  /// ranked level capped by the levels those cards fill, and what each
  /// ranked game did to the rating (from the start for the first).
  SideTripStanding standingOf(SideTrip trip, {required int known}) {
    final runs = _rated(trip).toList();
    final rated = [for (final r in runs) r.rating!];
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
      results: [
        for (final (i, r) in runs.indexed)
          SideTripResult(score: r.score!, ratingChange: rated[i] - (i > 0 ? rated[i - 1] : start), level: r.level ?? 0),
      ],
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
      performance = AnkirenRating.performance(setup.level!, score!.fraction,
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
            score: Value(score?.total),
            maxScore: Value(score?.max),
            completed: game.completed,
            rating: Value(after),
            performance: Value(performance),
            meta: Value(jsonEncode({
              AnkirenMeta.perSideKey: setup.perSide,
              AnkirenMeta.memoriseKey: setup.memorise.inMilliseconds,
              AnkirenMeta.middleKey: game.field.own.middleCards.length + game.field.opponent.middleCards.length,
              AnkirenMeta.memorisedKey: game.memorised.inMilliseconds,
              AnkirenMeta.dealKey: game.field.toJson(),
              AnkirenMeta.tappedKey: [for (final a in game.answers) a.tapped],
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
                firstTap: Value(a.taps.elementAtOrNull(0)?.index),
                firstTapUs: Value(a.firstTapUs),
                secondTap: Value(a.taps.elementAtOrNull(1)?.index),
              ),
          ]));
      return id;
    });
    _runs.add(await (db.select(db.sideTripRuns)..where((r) => r.id.equals(runId))).getSingle());
    _poems[runId] = [for (final a in game.answers) a.poemId];
    _answers[runId] = [
      for (final a in game.answers)
        (wrongTaps: a.wrongTaps, responseUs: a.responseUs, taps: a.taps, firstTapUs: a.firstTapUs),
    ];

    return AnkirenReport(ratingBefore: before, ratingAfter: after, rankedGames: setup.ranked ? rankedGames(trip) : 0);
  }

  /// Forgets every game, once the caller has deleted them from the database.
  void clear() {
    _runs.clear();
    _answers.clear();
    _poems.clear();
  }
}
