import 'dart:math' as math;

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
    this.revealAtUs,
    this.commitUs,
    this.tainted = false,
  });

  /// Position of the card in the session.
  final int index;
  final CardRef card;

  /// Reveal → response, in microseconds, as measured (see [isValidTime]).
  /// The card's time is [cardUs].
  final int responseUs;

  /// The card's reveal, µs after the run's first reveal (breaks included),
  /// and reveal → the swipe let go, µs; set by [PlaySession.commit].
  final int? revealAtUs, commitUs;
  final Outcome outcome;
  final DateTime at;
  final int deckSize;

  /// A response at or before the reveal (≤ 0 µs) is no measurement: it never
  /// counts as a timed answer, for speed, scheduling, rating, experience or
  /// a run's numbers.
  static bool isValidTime(int us) => us > 0;

  bool get validTime => isValidTime(responseUs);

  CardTime get time => CardTime(responseUs, commitUs);

  /// The card's time, µs (see [CardTime.us]).
  int get cardUs => time.us;

  /// Marked wrong afterwards (kimariji chip tap or ひとつ前).
  bool wrong = false;

  /// The time is not a clean measurement (a redo after ひとつ前, or the card
  /// was on screen while the previous result was being corrected).
  bool tainted;

  /// Counts as a miss for statistics and scheduling.
  bool get isMiss => wrong || outcome == Outcome.dontKnow;
}

/// How a card's time is counted from a swipe's raw times: the reaction
/// (reveal → touch) plus any of the swipe (touch → let go) past
/// [SwipeTuning.gestureBudget], so a finger held down to think still counts.
@immutable
class CardTime {
  const CardTime(this.reactionUs, int? commitUs) : _commitUs = commitUs;

  /// Reveal → response (`Attempt.responseUs`).
  final int reactionUs;

  /// Reveal → the swipe let go; null for a swipe from before it was kept.
  final int? _commitUs;

  /// Touch → let go, µs; 0 when unknown.
  int get gestureUs => _commitUs == null ? 0 : math.max(0, _commitUs - reactionUs);

  /// The part of the swipe past the budget, µs.
  int get extraUs => math.max(0, gestureUs - SwipeTuning.gestureBudget.inMicroseconds);

  /// The card's time, µs. A reaction that is no measurement (see
  /// [Attempt.isValidTime]) stays as it is.
  int get us => Attempt.isValidTime(reactionUs) ? reactionUs + extraUs : reactionUs;

  /// The card's time worked out from a stored swipe's columns.
  static int of(int responseUs, int? commitUs) => CardTime(responseUs, commitUs).us;
}

/// Plans the rest of a run from its [swipes] so far, with [next] already on
/// screen when given (it stays where it is).
typedef RunPlanner = List<CardRef> Function(List<Attempt> swipes, CardRef? next);

/// State machine of one 札落とし run: the queue, the current card, timing and
/// corrections. Timestamps are on the pointer-event clock; a reveal's vsync
/// time is put on it first (see `PointerClock`).
class PlaySession extends ChangeNotifier {
  PlaySession(List<CardRef> cards, {this.planner})
      : assert(cards.isNotEmpty),
        cards = [...cards],
        initialLength = cards.length;

  /// A run cut short, brought back as it stood: its queue, [attempts] and
  /// [undone] swipes, and [elapsed], its time so far. Nothing more is played
  /// on it.
  PlaySession.restored(List<CardRef> cards,
      {required List<Attempt> attempts, required List<Attempt> undone, required Duration elapsed})
      : cards = [...cards],
        initialLength = cards.length,
        planner = null {
    this.attempts.addAll(attempts);
    this.undone.addAll(undone);
    swipes.addAll([...attempts, ...undone]..sort((a, b) => a.at.compareTo(b.at)));
    index = attempts.length;
    firstRevealTs = Duration.zero;
    _lastCommitTs = elapsed;
    if (finished) endTs = elapsed;
  }

  /// The queue. Training may grow it with [requeue], or its [planner]
  /// replans what comes after the card on screen at every swipe and
  /// correction.
  final List<CardRef> cards;
  final int initialLength;
  final RunPlanner? planner;

  /// Every swipe in the order made, undone ones included.
  final List<Attempt> swipes = [];

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

  /// Total time from the first reveal to the last swipe, less breaks; null
  /// until the run is finished, or if it is no measurement (≤ 0).
  Duration? get total {
    if (firstRevealTs == null || endTs == null) return null;
    final t = endTs! - firstRevealTs! - _breaks;
    return t > Duration.zero ? t : null;
  }

  /// Time from the first reveal to the latest swipe, less breaks: a run
  /// ended early's time so far.
  Duration get elapsed {
    final last = endTs ?? _lastCommitTs;
    if (firstRevealTs == null || last == null) return Duration.zero;
    final t = last - firstRevealTs! - _breaks;
    return t > Duration.zero ? t : Duration.zero;
  }

  /// Play pauses before the current card for a page in between (a new
  /// card's introduction): the time from the last swipe to this card's
  /// reveal is left out of [total].
  void takeBreak() => _onBreak = true;

  /// Called with the vsync timestamp of the first frame showing the current
  /// card, on the pointer-event clock.
  void revealed(Duration frameTs) {
    if (finished || _revealTs != null) return;
    _revealTs = frameTs;
    firstRevealTs ??= frameTs;
    if (_onBreak && _lastCommitTs != null) _breaks += frameTs - _lastCommitTs!;
    _onBreak = false;
  }

  Duration? get revealTs => _revealTs;

  /// Play stops with the current card on screen (the app hidden, a sheet
  /// over it): the card is revealed again when play resumes, timed from
  /// there, and its swipe is left out of time statistics. The run's clock
  /// keeps going.
  void interrupt() {
    if (finished || _revealTs == null) return;
    _revealTs = null;
    _currentTainted = true;
    notifyListeners();
  }

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
    final attempt = Attempt(
      index: index,
      card: cards[index],
      responseUs: (responseTs - _revealTs!).inMicroseconds,
      outcome: outcome,
      at: at ?? DateTime.now(),
      deckSize: cards.length,
      revealAtUs: (_revealTs! - firstRevealTs!).inMicroseconds,
      commitUs: (commitTs - _revealTs!).inMicroseconds,
      tainted: _redo || _currentTainted,
    );
    attempts.add(attempt);
    swipes.add(attempt);
    index++;
    _replan();
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
    _replan(next: cards[index]);
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
    if (!finished) _replan(next: cards[index]);
    notifyListeners();
  }

  /// Replaces the queue after the current card ([next], kept) or from it.
  void _replan({CardRef? next}) {
    final plan = planner;
    if (plan == null) return;
    cards
      ..removeRange(next == null ? index : index + 1, cards.length)
      ..addAll(plan(swipes, next));
  }
}
