import 'package:drift/drift.dart';

import '../db/database.dart';
import '../domain/ikkiuchi_record.dart';
import '../domain/ikkiuchi_side.dart';

/// The recorded 一騎打ち matches, oldest first, and each one's reads. Owned
/// by `Progress`, which loads it on start; the matches are kept in memory,
/// a match's reads are read from the database when asked for.
class IkkiuchiRecords {
  IkkiuchiRecords._(this._matches);

  static Future<IkkiuchiRecords> load(AppDatabase db) async => IkkiuchiRecords._(
      await (db.select(db.ikkiuchiMatches)..orderBy([(m) => OrderingTerm.asc(m.id)])).get());

  final List<IkkiuchiMatchRow> _matches;

  /// Every recorded match, oldest first.
  List<IkkiuchiMatchRow> get matches => List.unmodifiable(_matches);

  /// The match stored last; null before the first.
  IkkiuchiMatchRow? get last => _matches.lastOrNull;

  /// [match]'s setup as it was played.
  static IkkiuchiSetup setupOf(IkkiuchiMatchRow match) => IkkiuchiSetup(
        perSide: match.perSide,
        memorise: Duration(milliseconds: match.memoriseMs),
        rating: match.tobiRating,
      );

  /// Match [matchId]'s reads, in the order they were read.
  static Future<List<IkkiuchiReadRow>> readsOf(AppDatabase db, int matchId) => (db.select(db.ikkiuchiReads)
        ..where((r) => r.matchId.equals(matchId))
        ..orderBy([(r) => OrderingTerm.asc(r.seq)]))
      .get();

  /// Stores [record], its match and its reads in one transaction, and keeps
  /// the match.
  Future<IkkiuchiMatchRow> record(AppDatabase db, IkkiuchiMatchRecord record) async {
    final setup = record.setup;
    final row = await db.transaction(() async {
      final row = await db.into(db.ikkiuchiMatches).insertReturning(IkkiuchiMatchesCompanion.insert(
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            perSide: setup.perSide,
            memoriseMs: setup.memorise.inMilliseconds,
            tobiRating: setup.rating,
            result: record.result,
            playerLeft: record.playerLeft,
            tobiLeft: record.tobiLeft,
            playerFaults: record.faultsOf(IkkiuchiSide.player),
            tobiFaults: record.faultsOf(IkkiuchiSide.opponent),
          ));
      await db.batch((b) => b.insertAll(db.ikkiuchiReads, [
            for (final (i, r) in record.reads.indexed)
              IkkiuchiReadsCompanion.insert(
                matchId: row.id,
                seq: i,
                poemId: r.poemId,
                karafuda: r.end.cardSide == null,
                taker: Value(r.end.taker),
                tied: r.end.tied,
                playerFaults: r.end.playerFaults.length,
                tobiFaults: r.end.tobiFaults.length,
                playerUs: Value(r.playerTake?.inMicroseconds),
                tobiUs: Value(r.tobiTake?.inMicroseconds),
              ),
          ]));
      return row;
    });
    _matches.add(row);
    return row;
  }

  /// Forgets every match, once the caller has deleted them from the
  /// database.
  void clear() => _matches.clear();
}
