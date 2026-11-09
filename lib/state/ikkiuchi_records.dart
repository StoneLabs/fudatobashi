import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../config/config.dart';
import '../db/database.dart';
import '../domain/ikkiuchi_mode.dart';
import '../domain/ikkiuchi_rating.dart';
import '../domain/ikkiuchi_record.dart';
import '../domain/ikkiuchi_xp.dart';
import '../domain/rating.dart';
import '../domain/xp.dart';

/// What recording a 一騎打ち match did: the match as stored, and what it
/// did to the player's experience.
class IkkiuchiReport {
  const IkkiuchiReport({required this.match, required this.xp});

  final IkkiuchiMatchRecord match;
  final XpGain xp;
}

/// The recorded 一騎打ち matches, oldest first, each with its reads, and
/// what they add up to: the counts, the free setup to start on, and each
/// ranked mode's standing ([of]). Owned by `Progress`, which loads it on
/// start.
class IkkiuchiRecords {
  IkkiuchiRecords._(this._matches);

  static Future<IkkiuchiRecords> load(AppDatabase db) async {
    final rows = await (db.select(db.ikkiuchiMatches)..orderBy([(m) => OrderingTerm.asc(m.id)])).get();
    final stored = await (db.select(db.ikkiuchiReads)
          ..orderBy([(r) => OrderingTerm.asc(r.matchId), (r) => OrderingTerm.asc(r.seq)]))
        .get();
    final reads = <int, List<IkkiuchiReadLog>>{};
    for (final r in stored) {
      (reads[r.matchId] ??= []).add(_readOf(r));
    }
    return IkkiuchiRecords._([for (final m in rows) _matchOf(m, reads[m.id] ?? const [])]);
  }

  final List<IkkiuchiMatchRecord> _matches;

  /// Every recorded match, oldest first.
  List<IkkiuchiMatchRecord> get matches => List.unmodifiable(_matches);

  /// The matches played, won and lost, a match given up counting as lost:
  /// every match, or only the ranked ones or the free ones by [ranked].
  ({int played, int won, int lost}) counts({bool? ranked}) {
    final kept = [
      for (final m in _matches)
        if (ranked == null || m.ranked == ranked) m,
    ];
    final won = kept.where((m) => m.result == IkkiuchiResult.won).length;
    return (played: kept.length, won: won, lost: kept.length - won);
  }

  /// The last free match's setup, or the first free one's before any.
  IkkiuchiSetup get freeSetup => _matches.where((m) => !m.ranked).lastOrNull?.setup ?? IkkiuchiSetup.firstFree;

  /// [mode]'s ranked matches as they stand now, and what they add up to.
  IkkiuchiModeRecords of(IkkiuchiMode mode) =>
      IkkiuchiModeRecords._(mode, List.unmodifiable([for (final m in _matches) if (m.ranked && m.setup.mode == mode) m]));

  /// Stores [match], once it is over, as played on practice day [day]: its
  /// row and its reads, in one transaction; a ranked one with the player's
  /// rating in its mode after it, from the mode's ranked matches before it;
  /// and the experience it earned ([IkkiuchiXp]). Returns it as stored.
  Future<IkkiuchiMatchRecord> record(AppDatabase db, IkkiuchiMatchRecord match, {required int day}) async {
    final setup = match.setup;
    final before = match.ranked ? of(setup.mode!) : null;
    final rating = before == null
        ? null
        : IkkiuchiRating.after(match.rated,
            earlier: [for (final m in before.matches) m.rated], rating: before.matches.lastOrNull?.rating);
    final xp = IkkiuchiXp.of(match, placed: before != null && IkkiuchiRating.endsPlacement(before.rankedPlayed));
    final id = await db.transaction(() async {
      final id = await db.into(db.ikkiuchiMatches).insert(IkkiuchiMatchesCompanion.insert(
            startedAt: match.startedAt,
            endedAt: match.endedAt,
            day: day,
            ranked: setup.ranked,
            mode: Value(setup.mode),
            opponent: setup.opponent,
            perSide: setup.perSide,
            rows: setup.rows,
            memoriseMs: setup.memorise.inMilliseconds,
            opponentRating: setup.opponentRating,
            completed: match.completed,
            playerLeft: match.playerLeft,
            opponentLeft: match.opponentLeft,
            rating: Value(rating),
            xp: jsonEncode(xp.toJson()),
          ));
      await db.batch((b) => b.insertAll(db.ikkiuchiReads, [
            for (final (i, r) in match.reads.indexed)
              IkkiuchiReadsCompanion.insert(
                matchId: id,
                seq: i,
                poemId: r.poemId,
                cardSide: Value(r.cardSide),
                taker: Value(r.taker),
                tied: r.tied,
                playerFaults: r.playerFaults,
                opponentFaults: r.opponentFaults,
                playerTakeUs: Value(r.playerTake?.inMicroseconds),
                opponentTakeUs: Value(r.opponentTake?.inMicroseconds),
                field: jsonEncode(r.field.toJson()),
                faults: jsonEncode([for (final f in r.faults) f.toJson()]),
                sends: jsonEncode([for (final s in r.sends) s.toJson()]),
              ),
          ]));
      return id;
    });
    final stored = match.stored(id: id, rating: rating, xp: xp);
    _matches.add(stored);
    return stored;
  }

  /// Forgets every match, once the caller has deleted them from the
  /// database.
  void clear() => _matches.clear();

  static IkkiuchiMatchRecord _matchOf(IkkiuchiMatchRow m, List<IkkiuchiReadLog> reads) => IkkiuchiMatchRecord(
        id: m.id,
        setup: IkkiuchiSetup(
          ranked: m.ranked,
          mode: m.mode,
          opponent: m.opponent,
          opponentRating: m.opponentRating,
          perSide: m.perSide,
          rows: m.rows,
          memorise: Duration(milliseconds: m.memoriseMs),
        ),
        startedAt: m.startedAt,
        endedAt: m.endedAt,
        completed: m.completed,
        playerLeft: m.playerLeft,
        opponentLeft: m.opponentLeft,
        rating: m.rating,
        xp: XpAward.fromJson(jsonDecode(m.xp) as List),
        reads: reads,
      );

  static Duration? _us(int? us) => us == null ? null : Duration(microseconds: us);

  static IkkiuchiReadLog _readOf(IkkiuchiReadRow r) => IkkiuchiReadLog(
        poemId: r.poemId,
        cardSide: r.cardSide,
        taker: r.taker,
        tied: r.tied,
        playerFaults: r.playerFaults,
        opponentFaults: r.opponentFaults,
        playerTake: _us(r.playerTakeUs),
        opponentTake: _us(r.opponentTakeUs),
        field: IkkiuchiLaidField.fromJson(jsonDecode(r.field) as Map<String, dynamic>),
        faults: [for (final f in jsonDecode(r.faults) as List) IkkiuchiFault.fromJson(f as List)],
        sends: [for (final s in jsonDecode(r.sends) as List) IkkiuchiSent.fromJson(s as List)],
      );
}

/// One mode's ranked matches, oldest first, and what they add up to: the
/// player's rating and class in it, their placement, the curve of their
/// rating, and the next ranked match's setup.
class IkkiuchiModeRecords {
  IkkiuchiModeRecords._(this.mode, this.matches);

  final IkkiuchiMode mode;

  /// The mode's ranked matches, oldest first.
  final List<IkkiuchiMatchRecord> matches;

  /// The last [n] ranked matches, newest first.
  List<IkkiuchiMatchRecord> lastRanked(int n) => matches.reversed.take(n).toList();

  /// The ranked matches played, placement's among them.
  int get rankedPlayed => matches.length;

  /// Whether the player is still being placed: the next ranked match
  /// places them.
  bool get placing => IkkiuchiRating.isPlacement(rankedPlayed);

  /// The player's rating, the last ranked match's; null while they are
  /// being placed.
  double? get rating => placing ? null : matches.lastOrNull?.rating;

  /// The class the rating stands in; null while the player is being placed.
  RankBand? get band => switch (rating) {
        final rating? => Rating.bandOf(rating),
        null => null,
      };

  /// What the last ranked match did to the rating; null while the player
  /// is being placed and for the match that placed them.
  double? get ratingChange {
    final ratings = [for (final m in matches) m.rating];
    if (IkkiuchiRating.isPlacement(ratings.length - 1)) return null;
    return switch (ratings) {
      [..., final double before, final double after] => after - before,
      _ => null,
    };
  }

  /// The rating after each of the last [IkkiuchiModeTuning.curveMatches]
  /// ranked matches, oldest first, from the match that ended placement,
  /// whose estimate is the first rating; the estimates before it are not
  /// drawn. Empty while the player is being placed.
  List<double> get curve {
    final rated = [for (final m in matches.skip(IkkiuchiRating.placementMatches - 1)) m.rating!];
    return rated.sublist(math.max(0, rated.length - IkkiuchiModeTuning.curveMatches));
  }

  /// The next ranked match's setup, each side laid out in [rows], Tobi
  /// playing at the rating [IkkiuchiRating.opponentFor] gives.
  IkkiuchiSetup rankedSetup({required int rows}) => IkkiuchiSetup.ranked(mode,
      opponentRating: IkkiuchiRating.opponentFor(mode, played: rankedPlayed, rating: matches.lastOrNull?.rating),
      rows: rows);
}
