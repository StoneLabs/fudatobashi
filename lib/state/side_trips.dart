import 'dart:convert';

import 'package:drift/drift.dart';

import '../config/config.dart';
import '../db/database.dart';
import '../domain/ankiren_field.dart';
import '../domain/ankiren_game.dart';
import '../domain/ankiren_level.dart';
import '../domain/ankiren_rating.dart';
import '../domain/ankiren_review.dart';
import '../domain/ankiren_xp.dart';
import '../domain/side_trips.dart';
import '../domain/teiichi_placing.dart';
import '../domain/teiichi_record.dart';
import '../domain/xp.dart';

/// What recording a 暗記練 game changed (for its results): 暗記練's rating
/// before and after a ranked game, both null for free play; the ranked
/// games played with it (0 for free play); free play's levels before and
/// after it; and the experience it earned.
class AnkirenReport {
  const AnkirenReport({
    required this.ratingBefore,
    required this.ratingAfter,
    this.rankedGames = 0,
    this.ladderBefore = AnkirenLadder.none,
    this.ladderAfter = AnkirenLadder.none,
    this.xp,
  });

  final double? ratingBefore;
  final double? ratingAfter;
  final int rankedGames;
  final AnkirenLadder ladderBefore, ladderAfter;
  final XpGain? xp;
}

/// The side trips' recorded games (寄り道), in the order they were played,
/// and what they add up to: each trip's ranked rating, its ranked games and
/// the hub's standing. Owned by `Progress`, which loads it on start.
class SideTrips {
  SideTrips._(this._runs, this._answers, this._cleared);

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
    return SideTrips._(runs, answers, cleared);
  }

  final List<SideTripRun> _runs;

  /// The free-play levels each trip's games have cleared, as stored.
  final Map<SideTrip, Set<int>> _cleared;

  /// Each run's answers, in the order they were asked, by run id.
  final Map<int, List<SideTripAnswerRow>> _answers;

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

  /// [run]'s answers, one per card asked, in order.
  List<AnkirenXpAnswer> answersOf(SideTripRun run) => [
        for (final a in _answers[run.id] ?? const <SideTripAnswerRow>[])
          (wrongTaps: a.wrongTaps, responseUs: a.responseUs, taps: _tapsOf(a).taps, firstTapUs: a.firstTapUs),
      ];

  /// [run]'s cards, in the order they were asked.
  List<int> poemsOf(SideTripRun run) => [for (final a in _answers[run.id] ?? const <SideTripAnswerRow>[]) a.poemId];

  /// Cards asked in [run]: every card of its field.
  int cardsIn(SideTripRun run) => _answers[run.id]?.length ?? 0;

  /// [run]'s wrong taps and cards given up, one strike each.
  int strikesIn(SideTripRun run) =>
      (_answers[run.id] ?? const <SideTripAnswerRow>[]).fold(0, (n, a) => n + a.wrongTaps + (a.gaveUp ? 1 : 0));

  /// [trip]'s free-play levels cleared.
  AnkirenLadder ladderOf(SideTrip trip) => AnkirenLadder({..._cleared[trip]!});

  Future<void> _storeCleared(AppDatabase db, SideTrip trip) => db.into(db.keyValues).insertOnConflictUpdate(
      KeyValuesCompanion.insert(key: clearedKey(trip), value: jsonEncode(_cleared[trip]!.toList()..sort())));

  /// Marks [trip]'s free-play levels 0 through [level] cleared, without
  /// playing them (a developer tool).
  Future<void> clearUpTo(AppDatabase db, SideTrip trip, int level) async {
    _cleared[trip]!.addAll([for (var l = 0; l <= level; l++) l]);
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
  AnkirenGameRecord recordOf(SideTripRun run) => AnkirenGameRecord(
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
              ),
        ],
      );

  /// The cards of [run] not found with the first tap: found after a wrong
  /// tap, shown, or never found.
  int missesIn(SideTripRun run) =>
      cardsIn(run) - answersOf(run).where((a) => a.wrongTaps == 0 && a.responseUs != null).length;

  /// [trip]'s standing on the hub for a player who knows [known] cards:
  /// 暗記練's free-play levels, capped by the levels those cards fill, and
  /// what each ranked game did to the rating (from the start for the
  /// first); 定位置's placing record.
  SideTripStanding standingOf(SideTrip trip, {required int known}) => switch (trip) {
        SideTrip.ankiren => _ankirenStanding(known),
        SideTrip.teiichi => SideTripStanding(games: runsOf(trip).length, placing: teiichiRecord()),
      };

  SideTripStanding _ankirenStanding(int known) {
    const trip = SideTrip.ankiren;
    final runs = _rated(trip).toList();
    final rated = [for (final r in runs) r.rating!];
    final rating = rated.lastOrNull;
    const start = AnkirenRating.start;
    return SideTripStanding(
      rating: rating,
      ratingChange: rating == null ? null : rating - (rated.length > 1 ? rated[rated.length - 2] : start),
      ladder: ladderOf(trip),
      maxLevel: AnkirenLevels.maxLevelFor(known),
      games: runsOf(trip).length,
      results: [
        for (final (i, r) in runs.indexed)
          SideTripResult(score: r.score!, ratingChange: rated[i] - (i > 0 ? rated[i - 1] : start)),
      ],
    );
  }

  /// A 定位置 game's card count, placing time and first-tap finds.
  TeiichiGameFacts teiichiFactsOf(SideTripRun run) {
    final meta = jsonDecode(run.meta) as Map<String, dynamic>;
    return (
      cards: meta[TeiichiMeta.cardsKey] as int,
      placing: Duration(milliseconds: meta[TeiichiMeta.placingKey] as int),
      firstTaps: cardsIn(run) - missesIn(run),
    );
  }

  /// 定位置's best placing time, of games of the usual count of cards played
  /// to the end, and its last game.
  TeiichiRecord teiichiRecord() {
    final runs = runsOf(SideTrip.teiichi).toList();
    final counted = [
      for (final r in runs)
        if (r.completed) teiichiFactsOf(r),
    ].where((f) => f.cards == TeiichiTuning.cards);
    return TeiichiRecord(
      best: counted.isEmpty ? null : counted.map((f) => f.placing).reduce((a, b) => a < b ? a : b),
      last: runs.isEmpty ? null : teiichiFactsOf(runs.last),
      games: runs.length,
    );
  }

  /// Stores [game], once it is over (see [AnkirenGame.end]), as started at
  /// [startedAt] on practice day [day]: its run and one answer per card
  /// asked, in one transaction, with [meta] added to the run's own details.
  /// A ranked game moves 暗記練's rating toward its performance (see
  /// [AnkirenRating]), placing it during the first ranked games; free play
  /// never touches it, and its level games may clear their level.
  Future<AnkirenReport> recordAnkiren(
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
    final before = setup.ranked ? ratingOf(trip) ?? AnkirenRating.start : null;
    final ladderBefore = ladderOf(trip);
    double? performance, after;
    if (before != null) {
      performance = AnkirenRating.performance(score!.total);
      after = AnkirenRating.update(before, performance, [for (final r in _rated(trip)) r.performance!]);
    }

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
              ...meta,
            })),
          ));
      await _storeAnswers(db, id, game);
      final level = setup.level;
      if (level != null && game.cleared && _cleared[trip]!.add(level)) await _storeCleared(db, trip);
      return id;
    });
    await _loadRun(db, runId);

    return AnkirenReport(
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
  /// answer per card asked as 暗記練's do, and one placing per card in the
  /// order they were placed.
  Future<void> recordTeiichi(
    AppDatabase db,
    TeiichiPlacing placing,
    AnkirenGame game, {
    required DateTime startedAt,
    required int day,
  }) async {
    assert(placing.done && game.phase == AnkirenPhase.done, 'a game is recorded once it is over');
    final setup = placing.setup;
    final runId = await db.transaction(() async {
      final id = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
            game: SideTrip.teiichi,
            startedAt: startedAt,
            endedAt: game.answers.lastOrNull?.at ?? startedAt,
            day: day,
            ranked: false,
            completed: game.completed,
            meta: Value(jsonEncode({
              TeiichiMeta.cardsKey: setup.cards,
              TeiichiMeta.rowsKey: setup.rows,
              TeiichiMeta.customKey: setup.custom,
              TeiichiMeta.placingKey: placing.placingTime!.inMilliseconds,
              TeiichiMeta.layoutKey: placing.board.half.toJson(),
            })),
          ));
      await _storeAnswers(db, id, game);
      await db.batch((b) => b.insertAll(db.teiichiPlacings, [
            for (final (i, poemId) in placing.order.indexed)
              TeiichiPlacingsCompanion.insert(
                runId: id,
                seq: i,
                poemId: poemId,
                placingUs: placing.placingTimeOf(poemId).inMicroseconds,
              ),
          ]));
      return id;
    });
    await _loadRun(db, runId);
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
    for (final levels in _cleared.values) {
      levels.clear();
    }
  }
}
