import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../domain/ankiren_field.dart';
import '../domain/ankiren_game.dart';
import '../domain/ankiren_level.dart';
import '../domain/ankiren_review.dart';
import '../domain/ankiren_xp.dart';
import '../domain/level_ladder.dart';
import '../domain/side_trips.dart';
import '../domain/teiichi.dart';
import '../domain/teiichi_placing.dart';
import '../domain/teiichi_record.dart';
import '../domain/teiichi_review.dart';
import '../domain/teiichi_score.dart';
import '../domain/trip_rating.dart';
import '../domain/xp.dart';

/// What recording a side trip's game changed (for its results): the trip's
/// rating before and after a ranked game, both null for any other; the
/// ranked games played with it (0 for any other); the levels before and
/// after it; and the experience it earned, when it earns any.
class SideTripReport {
  const SideTripReport({
    required this.ratingBefore,
    required this.ratingAfter,
    this.rankedGames = 0,
    this.ladderBefore = LevelLadder.none,
    this.ladderAfter = LevelLadder.none,
    this.xp,
  });

  final double? ratingBefore;
  final double? ratingAfter;
  final int rankedGames;
  final LevelLadder ladderBefore, ladderAfter;
  final XpGain? xp;
}

/// The side trips' recorded games (寄り道), in the order they were played,
/// and what they add up to: each trip's ranked rating, its ranked games and
/// the hub's standing. Owned by `Progress`, which loads it on start.
class SideTrips {
  SideTrips._(this._runs, this._answers, this._cleared, this._placings);

  /// The key value that holds [trip]'s cleared levels, a JSON list.
  static String clearedKey(SideTrip trip) => '${trip.name}Cleared';

  static Future<SideTrips> load(AppDatabase db) async {
    final runs = await (db.select(db.sideTripRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
    final rows = await (db.select(db.sideTripAnswers)
          ..orderBy([(a) => OrderingTerm.asc(a.runId), (a) => OrderingTerm.asc(a.seq)]))
        .get();
    final answers = <int, List<SideTripAnswerRow>>{};
    for (final a in rows) {
      (answers[a.runId] ??= []).add(a);
    }
    final cleared = <SideTrip, Set<int>>{};
    for (final trip in SideTrip.values) {
      final stored = await (db.select(db.keyValues)..where((k) => k.key.equals(clearedKey(trip)))).getSingleOrNull();
      cleared[trip] = {if (stored != null) ...(jsonDecode(stored.value) as List).cast<int>()};
    }
    final placed = await (db.select(db.teiichiPlacings)
          ..orderBy([(p) => OrderingTerm.asc(p.runId), (p) => OrderingTerm.asc(p.seq)]))
        .get();
    final placings = <int, List<TeiichiPlacingRow>>{};
    for (final p in placed) {
      (placings[p.runId] ??= []).add(p);
    }
    return SideTrips._(runs, answers, cleared, placings);
  }

  final List<SideTripRun> _runs;

  /// The levels each trip's games have cleared, as stored.
  final Map<SideTrip, Set<int>> _cleared;

  /// Each run's answers, in the order they were asked, by run id.
  final Map<int, List<SideTripAnswerRow>> _answers;

  /// Each 定位置 run's cards, those placed in the order they were, then
  /// those never placed, by run id.
  final Map<int, List<TeiichiPlacingRow>> _placings;

  /// Every recorded game of every trip, oldest first.
  List<SideTripRun> get runs => List.unmodifiable(_runs);

  /// [trip]'s games, ranked and free, oldest first.
  Iterable<SideTripRun> runsOf(SideTrip trip) => _runs.where((r) => r.game == trip);

  /// [trip]'s ranked games that moved its rating, oldest first.
  Iterable<SideTripRun> _rated(SideTrip trip) => runsOf(trip).where((r) => r.ranked && r.rating != null);

  /// [trip]'s ranked rating: its last ranked game's; null before the first.
  double? ratingOf(SideTrip trip) => _rated(trip).lastOrNull?.rating;

  /// [trip]'s ranked games so far (placement counts them).
  int rankedGames(SideTrip trip) => _rated(trip).length;

  /// The からふだ each run called, by run id, read off its meta once.
  final Map<int, Set<int>> _karafuda = {};

  Set<int> karafudaOf(SideTripRun run) =>
      _karafuda[run.id] ??= AnkirenMeta.karafudaIn(jsonDecode(run.meta) as Map<String, dynamic>);

  /// [run]'s answers, one per call, in order.
  List<AnkirenXpAnswer> answersOf(SideTripRun run) {
    final karafuda = karafudaOf(run);
    return [
      for (final a in _answers[run.id] ?? const <SideTripAnswerRow>[])
        (
          wrongTaps: a.wrongTaps,
          responseUs: a.responseUs,
          taps: _tapsOf(a).taps,
          firstTapUs: a.firstTapUs,
          karafuda: karafuda.contains(a.poemId),
        ),
    ];
  }

  /// [run]'s answers to its field's cards, in order: its からふだ left out.
  Iterable<SideTripAnswerRow> _cardRows(SideTripRun run) {
    final karafuda = karafudaOf(run);
    return (_answers[run.id] ?? const <SideTripAnswerRow>[]).where((a) => !karafuda.contains(a.poemId));
  }

  /// [run]'s field cards, in the order they were asked.
  List<int> poemsOf(SideTripRun run) => [for (final a in _cardRows(run)) a.poemId];

  /// Cards asked in [run]: every card of its field, its からふだ not counted.
  int cardsIn(SideTripRun run) => _cardRows(run).length;

  /// [run]'s wrong taps and calls given up, one strike each.
  int strikesIn(SideTripRun run) =>
      (_answers[run.id] ?? const <SideTripAnswerRow>[]).fold(0, (n, a) => n + a.wrongTaps + (a.gaveUp ? 1 : 0));

  /// [trip]'s levels cleared.
  LevelLadder ladderOf(SideTrip trip) => LevelLadder({..._cleared[trip]!}, trip.ladder);

  Future<void> _storeCleared(AppDatabase db, SideTrip trip) => db.into(db.keyValues).insertOnConflictUpdate(
      KeyValuesCompanion.insert(key: clearedKey(trip), value: jsonEncode(_cleared[trip]!.toList()..sort())));

  /// Marks [trip]'s levels up to [level] cleared, without playing them (a
  /// developer tool).
  Future<void> clearUpTo(AppDatabase db, SideTrip trip, int level) async {
    _cleared[trip]!.addAll([for (var l = trip.ladder.first; l <= level; l++) l]);
    await _storeCleared(db, trip);
  }

  /// Forgets which of [trip]'s levels are cleared (a developer tool).
  Future<void> resetLevels(AppDatabase db, SideTrip trip) async {
    _cleared[trip]!.clear();
    await _storeCleared(db, trip);
  }

  /// Where [a]'s counted taps landed and the cards they hit, in order.
  static ({List<TapProximity> taps, List<int> tapped}) _tapsOf(SideTripAnswerRow a) {
    final taps = [(a.firstTap, a.firstTapCard), (a.secondTap, a.secondTapCard)];
    return (
      taps: [for (final (place, _) in taps) ?place],
      tapped: [for (final (place, card) in taps) if (place != null) ?card],
    );
  }

  /// [run] as History reviews it.
  AnkirenGameRecord recordOf(SideTripRun run) {
    final karafuda = karafudaOf(run);
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
      calls: [
        for (final a in _answers[run.id] ?? const <SideTripAnswerRow>[])
          if (_tapsOf(a) case (:final taps, :final tapped))
            AnkirenCardTry(
              poemId: a.poemId,
              wrongTaps: a.wrongTaps,
              gaveUp: a.gaveUp,
              responseUs: a.responseUs,
              taps: taps,
              tapped: tapped,
              firstTapUs: a.firstTapUs,
              karafuda: karafuda.contains(a.poemId),
            ),
      ],
    );
  }

  /// The field cards of [run] not found with the first tap: found after a
  /// wrong tap, shown, or never found.
  int missesIn(SideTripRun run) =>
      cardsIn(run) - _cardRows(run).where((a) => a.wrongTaps == 0 && a.responseUs != null).length;

  /// [trip]'s standing on the hub for a player who knows [known] cards: its
  /// levels (暗記練's capped by the levels those cards fill), what each
  /// ranked game did to the rating (from the start for the first), and
  /// 定位置's placing record.
  SideTripStanding standingOf(SideTrip trip, {required int known}) {
    final runs = _rated(trip).toList();
    final rated = [for (final r in runs) r.rating!];
    final rating = rated.lastOrNull;
    const start = TripRating.start;
    return SideTripStanding(
      rating: rating,
      ratingChange: rating == null ? null : rating - (rated.length > 1 ? rated[rated.length - 2] : start),
      ladder: ladderOf(trip),
      maxLevel: switch (trip) {
        SideTrip.ankiren => AnkirenLevels.maxLevelFor(known),
        SideTrip.teiichi => TeiichiLevels.top,
      },
      games: runsOf(trip).length,
      results: [
        for (final (i, r) in runs.indexed)
          SideTripResult(score: r.score!, ratingChange: rated[i] - (i > 0 ? rated[i - 1] : start)),
      ],
      placing: trip == SideTrip.teiichi ? teiichiRecord() : TeiichiRecord.none,
    );
  }

  /// A 定位置 game's card count, placing time, first-tap finds, wrong taps,
  /// whether it was played to the end, and the cards never placed.
  TeiichiGameFacts teiichiFactsOf(SideTripRun run) {
    final meta = jsonDecode(run.meta) as Map<String, dynamic>;
    return (
      cards: meta[TeiichiMeta.cardsKey] as int,
      placing: Duration(milliseconds: meta[TeiichiMeta.placingKey] as int),
      firstTaps: cardsIn(run) - missesIn(run),
      wrongTaps: answersOf(run).fold(0, (n, a) => n + a.wrongTaps),
      completed: run.completed,
      unplaced: (_placings[run.id] ?? const <TeiichiPlacingRow>[]).where((p) => !p.placed).length,
    );
  }

  /// [run], a 定位置 game, as History reviews it.
  TeiichiGameRecord teiichiRecordOf(SideTripRun run) {
    final rows = _placings[run.id] ?? const <TeiichiPlacingRow>[];
    return TeiichiGameRecord(
      recall: recordOf(run),
      meta: run.meta,
      placed: [
        for (final p in rows)
          if (p.placed) (poemId: p.poemId, time: Duration(microseconds: p.placingUs)),
      ],
      unplaced: [
        for (final p in rows)
          if (!p.placed) p.poemId,
      ],
    );
  }

  /// 定位置's record of the games played (see [TeiichiRecord.of]).
  TeiichiRecord teiichiRecord() => TeiichiRecord.of([for (final r in runsOf(SideTrip.teiichi)) teiichiFactsOf(r)]);

  /// What a ranked game of [trip] scoring [score] does to its rating:
  /// [before] it, the game's [performance] and the rating [after] it,
  /// placing it during the first ranked games (see [TripRating]); all null
  /// for a game without a score.
  ({double? before, double? performance, double? after}) _rate(SideTrip trip, int? score) {
    if (score == null) return (before: null, performance: null, after: null);
    final before = ratingOf(trip) ?? TripRating.start;
    final performance = trip.rating.performance(score);
    final after = TripRating.update(before, performance, [for (final r in _rated(trip)) r.performance!]);
    return (before: before, performance: performance, after: after);
  }

  /// Stores [game], once it is over (see [AnkirenGame.end]), as started at
  /// [startedAt] on practice day [day]: its run and one answer per card
  /// asked, in one transaction, with [meta] added to the run's own details.
  /// A ranked game moves 暗記練's rating toward its performance; free play
  /// never touches it, and its level games may clear their level.
  Future<SideTripReport> recordAnkiren(
    AppDatabase db,
    AnkirenGame game, {
    required DateTime startedAt,
    required int day,
    Map<String, Object?> meta = const {},
  }) async {
    assert(game.phase == AnkirenPhase.done, 'a game is recorded once it is over');
    const trip = SideTrip.ankiren;
    final setup = game.setup;
    final score = game.score;
    final (:before, :performance, :after) = _rate(trip, score?.total);
    final ladderBefore = ladderOf(trip);

    final runId = await db.transaction(() async {
      final id = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
            game: trip,
            startedAt: startedAt,
            endedAt: game.answers.lastOrNull?.at ?? startedAt,
            day: day,
            ranked: setup.ranked,
            level: Value(setup.level),
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
              if (game.karafuda.isNotEmpty) AnkirenMeta.karafudaKey: game.karafuda,
              ...meta,
            })),
          ));
      await _storeAnswers(db, id, game);
      final level = setup.level;
      if (level != null && game.cleared && _cleared[trip]!.add(level)) await _storeCleared(db, trip);
      return id;
    });
    await _loadRun(db, runId);

    return SideTripReport(
      ratingBefore: before,
      ratingAfter: after,
      rankedGames: setup.ranked ? rankedGames(trip) : 0,
      ladderBefore: ladderBefore,
      ladderAfter: ladderOf(trip),
    );
  }

  /// Stores a 定位置 game, once over: [placing], laid out and done, and
  /// [game], its cards asked for, as started at [startedAt] on practice day
  /// [day]. Its run keeps the setup, the placing time and the layout, one
  /// answer per card asked as 暗記練's do, and one placing per card dealt,
  /// those placed in the order they were, then the rest.
  ///
  /// A ranked game moves 定位置's rating toward its performance, and one not
  /// played to the end is a forfeit, scoring 0 whatever its calls earned. A
  /// level game may clear its level.
  Future<SideTripReport> recordTeiichi(
    AppDatabase db,
    TeiichiPlacing placing,
    AnkirenGame game, {
    required DateTime startedAt,
    required int day,
  }) async {
    assert(placing.done && game.phase == AnkirenPhase.done, 'a game is recorded once it is over');
    const trip = SideTrip.teiichi;
    final setup = placing.setup;
    final score = setup.ranked ? (game.completed ? TeiichiScore(game.answers, placing: placing.placingTime!).total : 0) : null;
    final (:before, :performance, :after) = _rate(trip, score);
    final ladderBefore = ladderOf(trip);
    final runId = await db.transaction(() async {
      final id = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
            game: trip,
            startedAt: startedAt,
            endedAt: game.answers.lastOrNull?.at ?? startedAt.add(placing.placingTime!),
            day: day,
            ranked: setup.ranked,
            level: Value(setup.level),
            score: Value(score),
            completed: game.completed,
            rating: Value(after),
            performance: Value(performance),
            meta: Value(jsonEncode({
              TeiichiMeta.cardsKey: setup.cards,
              TeiichiMeta.rowsKey: setup.rows,
              TeiichiMeta.customKey: setup.custom,
              TeiichiMeta.placingKey: placing.placingTime!.inMilliseconds,
              TeiichiMeta.layoutKey: placing.board.half.toJson(),
              if (game.karafuda.isNotEmpty) TeiichiMeta.karafudaKey: game.karafuda,
            })),
          ));
      await _storeAnswers(db, id, game);
      await db.batch((b) => b.insertAll(db.teiichiPlacings, [
            for (final (i, poemId) in [...placing.order, ...placing.unplaced].indexed)
              TeiichiPlacingsCompanion.insert(
                runId: id,
                seq: i,
                poemId: poemId,
                placingUs: placing.placingTimeOf(poemId).inMicroseconds,
                placed: Value(i < placing.order.length),
              ),
          ]));
      final level = setup.level;
      if (level != null && game.cleared && _cleared[trip]!.add(level)) await _storeCleared(db, trip);
      return id;
    });
    await _loadRun(db, runId);
    _placings[runId] = await (db.select(db.teiichiPlacings)
          ..where((p) => p.runId.equals(runId))
          ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
        .get();
    return SideTripReport(
      ratingBefore: before,
      ratingAfter: after,
      rankedGames: setup.ranked ? rankedGames(trip) : 0,
      ladderBefore: ladderBefore,
      ladderAfter: ladderOf(trip),
    );
  }

  /// [game]'s answers, one per card asked, as run [runId]'s.
  static Future<void> _storeAnswers(AppDatabase db, int runId, AnkirenGame game) =>
      db.batch((b) => b.insertAll(db.sideTripAnswers, [
            for (final (i, a) in game.answers.indexed)
              SideTripAnswersCompanion.insert(
                runId: runId,
                seq: i,
                poemId: a.poemId,
                wrongTaps: a.wrongTaps,
                gaveUp: Value(a.gaveUp),
                responseUs: Value(a.responseUs),
                at: a.at,
                firstTap: Value(a.taps.elementAtOrNull(0)),
                firstTapCard: Value(a.tapped.elementAtOrNull(0)),
                firstTapUs: Value(a.firstTapUs),
                secondTap: Value(a.taps.elementAtOrNull(1)),
                secondTapCard: Value(a.tapped.elementAtOrNull(1)),
              ),
          ]));

  /// Keeps run [runId], just stored, with its answers.
  Future<void> _loadRun(AppDatabase db, int runId) async {
    _runs.add(await (db.select(db.sideTripRuns)..where((r) => r.id.equals(runId))).getSingle());
    _answers[runId] = await (db.select(db.sideTripAnswers)
          ..where((a) => a.runId.equals(runId))
          ..orderBy([(a) => OrderingTerm.asc(a.seq)]))
        .get();
  }

  /// Forgets every game, once the caller has deleted them from the database.
  void clear() {
    _runs.clear();
    _answers.clear();
    _placings.clear();
    _karafuda.clear();
    for (final levels in _cleared.values) {
      levels.clear();
    }
  }
}
