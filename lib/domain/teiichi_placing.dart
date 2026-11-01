import 'dart:math' as math;

import 'ankiren_field.dart';
import 'ankiren_game.dart';
import 'ankiren_level.dart';
import 'teiichi.dart';

/// Laying out a 定位置 game's cards: they come face up in a stack, and its
/// top card goes on the board, one at a time, with no skipping. A placed
/// card can be moved, or taken back on top of the stack. Once every card is
/// placed the player is done, and the clock stops; or the placing is
/// stopped short, with the cards left in the stack never to be placed.
///
/// A card's placing time is how long it was on top of the stack, every
/// time it was. Times are counted from the deal.
class TeiichiPlacing {
  TeiichiPlacing(this.setup, List<int> deck)
      : assert(deck.length == setup.cards),
        _stack = [...deck],
        board = TeiichiBoard(setup);

  final TeiichiSetup setup;

  /// The stack, its top card first.
  final List<int> _stack;
  TeiichiBoard board;
  final Map<int, Duration> _onTop = {};
  Duration _topSince = Duration.zero;
  final List<int> _order = [];
  Duration? _doneAt;

  /// The card to place next; null once every card is placed.
  int? get top => _stack.firstOrNull;

  /// The cards still to place, the top card first.
  List<int> get stack => List.unmodifiable(_stack);

  /// Cards still in the stack.
  int get left => _stack.length;
  bool get allPlaced => _stack.isEmpty;

  /// The player is done: the layout is final.
  bool get done => _doneAt != null;

  /// From the deal to done; null until then.
  Duration? get placingTime => _doneAt;

  /// The cards in the order they were placed, each where it was last put
  /// from the stack.
  List<int> get order => List.unmodifiable(_order);

  /// How long [poemId] has been on top of the stack, up to [now] while it
  /// is.
  Duration placingTimeOf(int poemId, {Duration? now}) {
    final so = _onTop[poemId] ?? Duration.zero;
    return now != null && poemId == top ? so + (now - _topSince) : so;
  }

  /// The placing time of every placed card.
  Map<int, Duration> get placingTimes => {for (final id in _order) id: placingTimeOf(id)};

  /// Puts the top card at [spot] [at] its time; false when it may not go
  /// there.
  bool placeTop(TeiichiSpot spot, Duration at) {
    final card = top;
    if (card == null || done) return false;
    final placed = board.put(card, spot);
    if (placed == null) return false;
    _endTurn(at);
    board = placed;
    _stack.removeAt(0);
    _order
      ..remove(card)
      ..add(card);
    return true;
  }

  /// Moves [poemId], a placed card, to [spot]; false when it may not go
  /// there.
  bool move(int poemId, TeiichiSpot spot) {
    if (done || !board.contains(poemId)) return false;
    final moved = board.put(poemId, spot);
    if (moved == null) return false;
    board = moved;
    return true;
  }

  /// Takes [poemId], a placed card, back on top of the stack [at] its
  /// time.
  bool takeBack(int poemId, Duration at) {
    if (done || !board.contains(poemId)) return false;
    _endTurn(at);
    board = board.without(poemId);
    _stack.insert(0, poemId);
    _order.remove(poemId);
    return true;
  }

  /// Every card is placed and the player is done [at] the clock's time.
  bool finish(Duration at) {
    if (!allPlaced || done) return false;
    _doneAt = at;
    return true;
  }

  /// The layout is final as it stands [at] the clock's time, whatever is
  /// still in the stack: the time ran out, or the player left.
  void stop(Duration at) {
    if (done) return;
    _endTurn(at);
    _doneAt = at;
  }

  /// The cards never placed, once done.
  List<int> get unplaced => done ? stack : const [];

  /// The game that asks for the laid-out cards once done, as 暗記練's: only
  /// the own side holds cards, they and [karafuda] are asked in an order
  /// [rng] draws, and the placing time is the time to memorise them. Each
  /// card left unplaced is a strike from the start; with no card laid out
  /// nothing is called at all.
  AnkirenGame recall(
    math.Random rng, {
    List<int> karafuda = const [],
    bool countsStrikes = false,
    DateTime Function()? clock,
  }) {
    assert(done, 'the cards are asked for once they are laid out');
    final called = board.cards.isEmpty ? const <int>[] : karafuda;
    return AnkirenGame(
      field: AnkirenField(own: board.half, opponent: AnkirenHalf.empty()),
      setup: AnkirenSetup.custom(perSide: setup.cards, memorise: placingTime!, karafuda: called.length),
      rng: rng,
      karafuda: called,
      countsStrikes: countsStrikes,
      startingStrikes: unplaced.length,
      clock: clock,
    );
  }

  /// The top card's turn on top ends [at] its time; the next card's starts.
  void _endTurn(Duration at) {
    final card = top;
    if (card != null) _onTop[card] = placingTimeOf(card) + (at - _topSince);
    _topSince = at;
  }
}
