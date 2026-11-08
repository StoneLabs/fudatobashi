import 'dart:convert';

import '../domain/ikkiuchi_record.dart';

/// A ranked 一騎打ち match under way, saved when its first card is read so
/// that a match the app never got to record (it was closed or killed) is
/// recorded on the next start as a forfeit (see `Progress.journalIkkiuchi`).
/// Only its setup and start are kept: the forfeit keeps no read.
class IkkiuchiJournal {
  const IkkiuchiJournal({required this.setup, required this.startedAt});

  final IkkiuchiSetup setup;
  final DateTime startedAt;

  String encode() => jsonEncode({
        'ranked': setup.ranked,
        'opponent': setup.opponent.name,
        'opponentRating': setup.opponentRating,
        'perSide': setup.perSide,
        'memoriseMs': setup.memorise.inMilliseconds,
        'startedAt': startedAt.toIso8601String(),
      });

  static IkkiuchiJournal decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    return IkkiuchiJournal(
      setup: IkkiuchiSetup(
        ranked: j['ranked'] as bool,
        opponent: IkkiuchiOpponent.values.byName(j['opponent'] as String),
        opponentRating: (j['opponentRating'] as num).toDouble(),
        perSide: j['perSide'] as int,
        memorise: Duration(milliseconds: j['memoriseMs'] as int),
      ),
      startedAt: DateTime.parse(j['startedAt'] as String),
    );
  }
}
