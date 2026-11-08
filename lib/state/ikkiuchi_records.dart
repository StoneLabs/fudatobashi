import 'package:drift/drift.dart';

import '../db/database.dart';
import '../domain/ikkiuchi_record.dart';

/// The recorded 一騎打ち matches, oldest first, each with its reads, and
/// what they add up to. Owned by `Progress`, which loads it on start.
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

  /// Stores [match], once it is over, as played on practice day [day]: its
  /// row and its reads, in one transaction. Returns it as stored.
  Future<IkkiuchiMatchRecord> record(AppDatabase db, IkkiuchiMatchRecord match, {required int day}) async {
    final setup = match.setup;
    final id = await db.transaction(() async {
      final id = await db.into(db.ikkiuchiMatches).insert(IkkiuchiMatchesCompanion.insert(
            startedAt: match.startedAt,
            endedAt: match.endedAt,
            day: day,
            ranked: setup.ranked,
            opponent: setup.opponent,
            perSide: setup.perSide,
            memoriseMs: setup.memorise.inMilliseconds,
            opponentRating: setup.opponentRating,
            completed: match.completed,
            playerLeft: match.playerLeft,
            opponentLeft: match.opponentLeft,
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
              ),
          ]));
      return id;
    });
    final stored = match.stored(id: id, rating: null);
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
          opponent: m.opponent,
          opponentRating: m.opponentRating,
          perSide: m.perSide,
          memorise: Duration(milliseconds: m.memoriseMs),
        ),
        startedAt: m.startedAt,
        endedAt: m.endedAt,
        completed: m.completed,
        playerLeft: m.playerLeft,
        opponentLeft: m.opponentLeft,
        rating: m.rating,
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
      );
}
