import 'dart:convert';

/// A ranked 定位置 game under way, saved when its first card is placed so
/// that a game the app never got to record (it was closed or killed) is
/// recorded on the next start as a forfeit (see `Progress.journalTeiichi`).
/// Only the deal is kept: the forfeit lays no card out.
class TeiichiJournal {
  const TeiichiJournal({required this.deck, required this.startedAt});

  /// The cards dealt, the top of the stack first.
  final List<int> deck;
  final DateTime startedAt;

  String encode() => jsonEncode({'deck': deck, 'startedAt': startedAt.toIso8601String()});

  static TeiichiJournal decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    return TeiichiJournal(
      deck: (j['deck'] as List).cast<int>(),
      startedAt: DateTime.parse(j['startedAt'] as String),
    );
  }
}
