import 'package:flutter/foundation.dart';

import 'card_mask.dart';

enum Outcome { known, dontKnow }

/// A card to be shown during a session.
@immutable
class CardRef {
  const CardRef(this.poemId, {this.inverted = false, this.mask = CardMask.none});
  final int poemId;
  final bool inverted;
  final CardMask mask;
}

/// One swipe of one card.
class Attempt {
  Attempt({
    required this.index,
    required this.card,
    required this.responseUs,
    required this.outcome,
    required this.at,
    required this.deckSize,
    this.tainted = false,
  });

  /// Position of the card in the session.
  final int index;
  final CardRef card;

  /// Reveal → response, in microseconds.
  final int responseUs;
  final Outcome outcome;
  final DateTime at;
  final int deckSize;

  /// Marked wrong afterwards (kimariji chip tap or ひとつ前).
  bool wrong = false;

  /// The time is not a clean measurement (a redo after ひとつ前, or the card
  /// was on screen while the previous result was being corrected).
  bool tainted;

  /// Counts as a miss for statistics and scheduling.
  bool get isMiss => wrong || outcome == Outcome.dontKnow;
}

/// State machine of one 札落とし run: the queue, the current card, timing and
/// corrections. Timestamps are engine timestamps (same clock as pointer
/// events and frame vsync times).
class PlaySession extends ChangeNotifier {
  PlaySession(List<CardRef> cards)
      : assert(cards.isNotEmpty),
        cards = [...cards],
        initialLength = cards.length;

  /// The queue. Training may grow it with [requeue].
  final List<CardRef> cards;
  final int initialLength;

  /// Index of the card currently on top.
  int index = 0;

  /// The accepted attempt for each finished card index, in order.
  final List<Attempt> attempts = [];

  /// Attempts that were undone with ひとつ前 (kept as misses for statistics).
  final List<Attempt> undone = [];

  Duration? _revealTs;
  Duration? firstRevealTs;
  Duration? endTs;
  bool _redo = false;
  bool _currentTainted = false;
  bool aborted = false;

  bool get finished => index >= cards.length;
  bool get started => firstRevealTs != null;
  bool get currentRevealed => _revealTs != null;
  CardRef? get current => finished ? null : cards[index];
  CardRef? get next => index + 1 < cards.length ? cards[index + 1] : null;
  Attempt? get lastAttempt => attempts.isEmpty ? null : attempts.last;

  /// Total time from the first reveal to the last swipe.
  Duration? get total =>
      (firstRevealTs != null && endTs != null) ? endTs! - firstRevealTs! : null;

  /// Called with the vsync timestamp of the first frame showing the current card.
  void revealed(Duration frameTs) {
    if (finished || _revealTs != null) return;
    _revealTs = frameTs;
    firstRevealTs ??= frameTs;
  }

  Duration? get revealTs => _revealTs;

  void commit({
    required Duration responseTs,
    required Duration commitTs,
    required Outcome outcome,
  }) {
    if (finished || _revealTs == null) return;
    final us = (responseTs - _revealTs!).inMicroseconds;
    attempts.add(Attempt(
      index: index,
      card: cards[index],
      responseUs: us < 0 ? 0 : us,
      outcome: outcome,
      at: DateTime.now(),
      deckSize: cards.length,
      tainted: _redo || _currentTainted,
    ));
    index++;
    _revealTs = null;
    _redo = false;
    _currentTainted = false;
    if (finished) endTs = commitTs;
    notifyListeners();
  }

  /// Schedules [card] again [gap] cards after the current one (training:
  /// a missed card and its 友札 come back soon). Returns false when the queue
  /// may not grow any further (at most +50% of the planned length).
  bool requeue(CardRef card, {int gap = 4}) {
    if (cards.length >= initialLength * 3 ~/ 2 + 1) return false;
    final at = (index + gap).clamp(index, cards.length);
    cards.insert(at, card);
    notifyListeners();
    return true;
  }

  /// ひとつ前: bring the previous card back. Its attempt counts as a miss, and
  /// the redo's time is excluded from statistics.
  bool undo() {
    if (attempts.isEmpty) return false;
    final prev = attempts.removeLast()..wrong = true;
    undone.add(prev);
    index = prev.index;
    _revealTs = null;
    _redo = true;
    _currentTainted = false;
    endTs = null;
    notifyListeners();
    return true;
  }

  /// The player saw the previous card's kimariji and realised they were wrong.
  /// The card now on screen is excluded from time statistics, because its
  /// timer kept running during the correction.
  void togglePreviousWrong() {
    final a = lastAttempt;
    if (a == null) return;
    a.wrong = !a.wrong;
    if (a.wrong && !finished) _currentTainted = true;
    notifyListeners();
  }
}
