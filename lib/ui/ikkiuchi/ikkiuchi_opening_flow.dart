import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_opening.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../../domain/placing.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_player_spots.dart';

/// The opening of a match on a board scene (一騎打ち): both sides laid out
/// before play, the board laid out with room for the player's stack
/// meanwhile ([IkkiuchiBoardScene.stack]).
///
/// The player's cards wait face up in the [stack], and they place its top
/// card, one at a time, by the placing's rules ([IkkiuchiSides.placed]):
/// a tap on a free spot or on a card, or a drag there, the cards inward of
/// a card's place moving a place in. A placed card may be dragged to
/// another spot, or back onto the stack; let go anywhere else it glides
/// back. The game may put the cards still in the stack down
/// ([placeRest]); either way, once the player is done ([finish]) the
/// board is laid out for play. Each change lays the board out afresh
/// ([IkkiuchiBoardScene.relayout]).
///
/// Meanwhile Tobi lays out his side ([startTobi], [IkkiuchiTobiOpening]):
/// his cards wait off the board, and his arm takes each from his hand to
/// its home in turn until his placing time is over ([tobiDone]), unless
/// he lays the rest down at once ([finishTobi]).
class IkkiuchiOpeningFlow {
  IkkiuchiOpeningFlow(this.scene, List<int> stack)
      : _stack = [...stack],
        _placing = stack.isNotEmpty,
        spots = IkkiuchiPlayerSpots(scene);

  final IkkiuchiBoardScene scene;

  /// Where the player's cards and spots lie.
  final IkkiuchiPlayerSpots spots;

  /// The cards still to place, the top card first.
  List<int> get stack => List.unmodifiable(_stack);
  final List<int> _stack;

  int? get top => _stack.firstOrNull;
  bool get allPlaced => _stack.isEmpty;

  /// Whether the player is laying out their side: from the deal until
  /// they are done.
  bool get placing => _placing;
  bool _placing;

  /// Whether no card is placed yet: every one still in the stack.
  bool get untouched => _placing && _drag == null && scene.sides!.playerCards.isEmpty;

  /// The card being dragged, and where it would land.
  PlacingDrag? get drag => _drag;
  PlacingDrag? _drag;

  // Tobi's side.

  IkkiuchiTobiOpening? _tobi;

  /// The board time he started at, and how many of his cards' carries
  /// have started.
  double _tobiSince = 0;
  int _laid = 0;

  /// The card in his hand, and the board his arm carries it on.
  int? _inHand;
  IkkiuchiBoard? _carriedOn;

  /// Whether Tobi has laid out his side, or never had to.
  bool get tobiDone => _tobi == null;

  /// The card in Tobi's hand now, until it lies at its home.
  int? get inHand => _inHand;

  /// Tobi's cards not on the board yet: in his hand, or still to lay down.
  Set<int> get tobiWaiting => {?_inHand, ...?_tobi?.order.skip(_laid)};

  /// Tobi starts laying out his side, over [ms]: every card of his leaves
  /// the board until his arm lays it down.
  void startTobi(double ms) {
    final tobi = _tobi = IkkiuchiTobiOpening(scene.sides!.tobi, ms: ms, rng: scene.rng);
    final cards = scene.board.cards;
    _tobiSince = scene.board.now;
    _laid = 0;
    for (final id in tobi.order) {
      cards.hold(cards.card(id));
    }
  }

  /// Each frame: the card his arm has set down lies at its home, the next
  /// card's carry starts on time, and once his time is over he is done. A
  /// board laid out afresh takes the carry under way on, to the card's new
  /// home.
  void advance() {
    final tobi = _tobi;
    if (tobi == null) return;
    final board = scene.board;
    if (_inHand case final id?) {
      if (!identical(board, _carriedOn)) {
        _carry(id, since: _carriedOn!.carryStart);
      } else if (!board.carrying) {
        board.cards.putHome(board.cards.card(id));
        _inHand = null;
      }
    }
    final at = board.now - _tobiSince;
    if (_inHand == null && _laid < tobi.order.length && at >= tobi.startOf(_laid)) {
      _carry(tobi.order[_laid++], since: board.now);
    }
    if (_inHand == null && _laid == tobi.order.length && at >= tobi.ms) _tobi = null;
  }

  void _carry(int id, {required double since}) {
    final board = scene.board, tobi = _tobi!;
    final home = board.cards.card(id).home;
    board.carryCard(
      IkkiuchiCarry.fromHand(
        tobi: board.tobi,
        to: home,
        cardW: board.cards.cardW,
        side: home.centre.x < board.tobi.centreX ? ArmSide.left : ArmSide.right,
        carryMs: tobi.carryMs,
        backMs: tobi.backMs,
      ),
      id,
      since: since,
    );
    _inHand = id;
    _carriedOn = board;
  }

  /// Tobi lays every card he has still to lay down at once, his arm still.
  void finishTobi() {
    if (_tobi == null) return;
    final board = scene.board;
    final waiting = tobiWaiting;
    board.dropCarry();
    for (final id in waiting) {
      board.cards.putHome(board.cards.card(id));
    }
    _tobi = null;
    _inHand = null;
    scene.refresh();
  }

  // The player's side.

  /// The cards still in the stack are put down by the game
  /// ([IkkiuchiSides.autoPlaced]), each gliding there from the stack, or
  /// from the finger for the one dragged; a placed card dragged glides
  /// back to its place.
  void placeRest() {
    final sides = scene.sides, stack = scene.stack;
    if (!_placing || sides == null) return;
    final from = {
      if (stack != null)
        for (final id in _stack) id: _boxOf(stack),
      ..._letGo(),
    };
    final next = sides.autoPlaced(_stack);
    final placed = next.playerCards.toSet();
    _stack.removeWhere(placed.contains);
    scene
      ..relayout(next, from: from)
      ..refresh();
  }

  /// The player is done laying out their side: the board is laid out for
  /// play, the stack's room gone.
  void finish() {
    if (!_placing) return;
    _placing = false;
    scene
      ..relayout(scene.sides!, from: _letGo(), forPlay: true)
      ..refresh();
  }

  /// A drag under way ends where it is: where its card glides from.
  Map<int, CardBox> _letGo() {
    final drag = _drag;
    _drag = null;
    return drag == null ? const {} : {drag.card: spots.liftedBox(drag.at)};
  }

  // Touches, in board dp.

  /// The card a drag starting [at] picks up: the stack's top card, or a
  /// placed one.
  ({int card, bool fromStack})? cardAt(Offset at) {
    if (!_placing) return null;
    final top = this.top, stack = scene.stack;
    if (top != null && stack != null && stack.contains(at)) return (card: top, fromStack: true);
    final id = spots.cardAt(at);
    return id == null ? null : (card: id, fromStack: false);
  }

  void dragStart(int card, {required bool fromStack, required Offset at}) {
    if (!_placing) return;
    if (!fromStack) scene.board.cards.hold(scene.board.cards.card(card));
    _drag = _dragAt(card, fromStack: fromStack, at: at);
    scene.refresh();
  }

  void dragTo(Offset at) {
    final drag = _drag;
    if (drag == null) return;
    _drag = _dragAt(drag.card, fromStack: drag.fromStack, at: at);
    scene.refresh();
  }

  /// A drag let go: its card back on the stack, at the spot it would land
  /// on, or, for a placed card, gliding back to its place.
  void dragEnd() {
    final drag = _drag, sides = scene.sides;
    if (drag == null || sides == null) return;
    _drag = null;
    final from = {drag.card: spots.liftedBox(drag.at)};
    final next = switch (drag.spot) {
      final spot? => sides.placed(drag.card, spot),
      null => null,
    };
    if (drag.onStack) {
      _stack.insert(0, drag.card);
      scene.relayout(sides.without(drag.card));
    } else if (next != null) {
      if (drag.fromStack) _stack.removeAt(0);
      scene.relayout(next, from: from);
    } else if (!drag.fromStack) {
      scene.board.cards.glideFrom(from,
          ms: _ms(IkkiuchiPlayTuning.relayoutGlide), ease: IkkiuchiPlayTuning.relayoutCurve.transform);
    }
    scene.refresh();
  }

  /// A tap on a spot or a card puts the stack's top card there.
  void tap(Offset at) {
    final top = this.top, stack = scene.stack;
    if (!_placing || _drag != null || top == null || stack == null) return;
    final spot = targets().spotAt(at.dx, at.dy);
    final next = spot == null ? null : scene.sides!.placed(top, spot);
    if (next == null) return;
    _stack.removeAt(0);
    scene
      ..relayout(next, from: {top: _boxOf(stack)})
      ..refresh();
  }

  /// Where a card may go: past the placed card being dragged, which is
  /// left out, or for the stack's top card.
  PlacingTargets targets() => spots.targets(moving: _drag?.fromStack == false ? _drag!.card : null);

  PlacingDrag _dragAt(int card, {required bool fromStack, required Offset at}) {
    final stack = scene.stack;
    if (!fromStack && stack != null && stack.inflate(IkkiuchiOpeningStyle.stackReach).contains(at)) {
      return PlacingDrag(card: card, fromStack: false, at: at, onStack: true);
    }
    final spot = spots.targets(moving: fromStack ? null : card).spotAt(at.dx, at.dy);
    return PlacingDrag(card: card, fromStack: fromStack, at: at, spot: spot);
  }

  static CardBox _boxOf(Rect r) => CardBox(Vec(r.center.dx, r.center.dy), r.width / 2, r.height / 2);

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
}
