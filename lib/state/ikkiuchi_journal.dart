import 'dart:convert';

import '../domain/ikkiuchi_record.dart';
import '../domain/ikkiuchi_side.dart';

/// A ranked 一騎打ち match under way, saved as it stands when its first
/// card is read and again after every read, so that a match the app never
/// got to record (it was closed or killed) is recorded on the next start
/// as a forfeit with the reads and the cards left it had (see
/// `Progress.journalIkkiuchi`). Its [match] is not completed, and ends at
/// the last save.
class IkkiuchiJournal {
  const IkkiuchiJournal(this.match);

  final IkkiuchiMatchRecord match;

  String encode() {
    final setup = match.setup;
    return jsonEncode({
      'ranked': setup.ranked,
      'opponent': setup.opponent.name,
      'opponentRating': setup.opponentRating,
      'perSide': setup.perSide,
      'memoriseMs': setup.memorise.inMilliseconds,
      'startedAt': match.startedAt.toIso8601String(),
      'endedAt': match.endedAt.toIso8601String(),
      'playerLeft': match.playerLeft,
      'opponentLeft': match.opponentLeft,
      'reads': [
        for (final r in match.reads)
          {
            'poemId': r.poemId,
            'cardSide': r.cardSide?.name,
            'taker': r.taker?.name,
            'tied': r.tied,
            'playerFaults': r.playerFaults,
            'opponentFaults': r.opponentFaults,
            'playerTakeUs': r.playerTake?.inMicroseconds,
            'opponentTakeUs': r.opponentTake?.inMicroseconds,
          },
      ],
    });
  }

  static IkkiuchiJournal decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    IkkiuchiSide? side(Object? name) => name == null ? null : IkkiuchiSide.values.byName(name as String);
    Duration? us(Object? n) => n == null ? null : Duration(microseconds: n as int);
    return IkkiuchiJournal(IkkiuchiMatchRecord(
      setup: IkkiuchiSetup(
        ranked: j['ranked'] as bool,
        opponent: IkkiuchiOpponent.values.byName(j['opponent'] as String),
        opponentRating: (j['opponentRating'] as num).toDouble(),
        perSide: j['perSide'] as int,
        memorise: Duration(milliseconds: j['memoriseMs'] as int),
      ),
      startedAt: DateTime.parse(j['startedAt'] as String),
      endedAt: DateTime.parse(j['endedAt'] as String),
      completed: false,
      playerLeft: j['playerLeft'] as int,
      opponentLeft: j['opponentLeft'] as int,
      reads: [
        for (final r in (j['reads'] as List).cast<Map<String, dynamic>>())
          IkkiuchiReadLog(
            poemId: r['poemId'] as int,
            cardSide: side(r['cardSide']),
            taker: side(r['taker']),
            tied: r['tied'] as bool,
            playerFaults: r['playerFaults'] as int,
            opponentFaults: r['opponentFaults'] as int,
            playerTake: us(r['playerTakeUs']),
            opponentTake: us(r['opponentTakeUs']),
          ),
      ],
    ));
  }
}
