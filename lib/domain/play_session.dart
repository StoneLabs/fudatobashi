import 'package:flutter/foundation.dart';

import '../config/config.dart';
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
  Duration? _lastCommitTs;
  Duration _breaks = Duration.zero;
  bool _onBreak = false;
  bool _redo = false;
  bool _currentTainted = false;
  bool aborted = false;

  bool get finished => index >= cards.length;
  bool get started => firstRevealTs != null;
  bool get currentRevealed => _revealTs != null;
  CardRef? get current => finished ? null : cards[index];
  CardRef? get next => index + 1 < cards.length ? cards[index + 1] : null;
  Attempt? get lastAttempt => attempts.isEmpty ? null : attempts.last;

  /// Total time from the first reveal to the last swipe, less breaks.
  Duration? get total =>
      (firstRevealTs != null && endTs != null) ? endTs! - firstRevealTs! - _breaks : null;

  /// Play pauses before the current card for a page in between (a new
  /// card's introduction): the time from the last swipe to this card's
  /// reveal is left out of [total].
  void takeBreak() => _onBreak = true;

  /// Called with the vsync timestamp of the first frame showing the current card.
  void revealed(Duration frameTs) {
    if (finished || _revealTs != null) return;
    _revealTs = frameTs;
    firstRevealTs ??= frameTs;
    if (_onBreak && _lastCommitTs != null) _breaks += frameTs - _lastCommitTs!;
    _onBreak = false;
  }

  Duration? get revealTs => _revealTs;

  void commit({
    required Duration responseTs,
    required Duration commitTs,
    required Outcome outcome,

    /// Wall-clock time of this attempt, for history and FSRS scheduling.
    /// Unrelated to the timing contract above; defaults to now (demo-data
    /// seeding backdates it to spread synthetic history over past days).
    DateTime? at,
  }) {
    if (finished || _revealTs == null) return;
    final us = (responseTs - _revealTs!).inMicroseconds;
    attempts.add(Attempt(
      index: index,
      card: cards[index],
      responseUs: us < 0 ? 0 : us,
      outcome: outcome,
      at: at ?? DateTime.now(),
      deckSize: cards.length,
      tainted: _redo || _currentTainted,
    ));
    index++;
    _revealTs = null;
    _lastCommitTs = commitTs;
    _redo = false;
    _currentTainted = false;
    if (finished) endTs = commitTs;
    notifyListeners();
  }

  /// Schedules [card] again [gap] cards after the current one (training:
  /// a missed card and its 友札 come back soon). Returns false when the queue
  /// may not grow any further (at most +50% of the planned length).
  bool requeue(CardRef card, {int gap = TrainingTuning.requeueGap}) {
    if (cards.length >= (initialLength * TrainingTuning.requeueCapGrowth).truncate() + 1) return false;
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
