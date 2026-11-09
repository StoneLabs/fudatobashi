import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../../domain/placing.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_player_spots.dart';

/// Where a 送り札 stands: none; the player picking a card of theirs to send
/// Tobi; Tobi's arm laying that card on his side; Tobi's arm carrying his
/// card across; or his card waiting for the player to place it.
enum IkkiuchiSendStage { none, sending, placing, carrying, waiting }

/// A 送り札 on a board scene, in both directions.
///
/// The player sends: they drag one of their cards; let go over Tobi's side
/// ([tobiSide], the middle of the card riding there) it lies where it was
/// let go ([dropped]) as his side makes room for it at its home, his row
/// and group taking it in home order; then his arm takes it and lays it
/// there, which ends the 送り札. Let go anywhere else it glides back.
///
/// Tobi sends: he picks one of his cards ([IkkiuchiSides.tobiSends], at his
/// rating's smart send), his arm takes it off his side, turns it to face
/// the player and sets it down at the waiting spot, and he points at it.
/// His side closes up; the player places it by the placing's rules
/// ([IkkiuchiSides.placed]): a tap on a free spot or a card, or a drag
/// there. Placing it ends the 送り札. With no free spot on the player's
/// side it does not wait: it goes there past a row's room
/// ([IkkiuchiSides.squeezedIn]).
///
/// Every change of the sides lays the board out afresh ([IkkiuchiBoardScene.relayout]),
/// and each card that goes to the other side is told to [onSent].
/// Neither starts while the player moves their cards about.
class IkkiuchiSendFlow {
  IkkiuchiSendFlow(this.scene) : spots = IkkiuchiPlayerSpots(scene);

  final IkkiuchiBoardScene scene;

  /// Told of each card sent, once the sides hold it on the side it went
  /// to.
  void Function(int card)? onSent;

  /// Where the player's cards and spots lie.
  final IkkiuchiPlayerSpots spots;

  IkkiuchiSendStage get stage => _stage;
  IkkiuchiSendStage _stage = IkkiuchiSendStage.none;
  bool get active => _stage != IkkiuchiSendStage.none;

  /// The card sent: Tobi's from his pick until placed, or the player's
  /// from its drop until his arm laid it down.
  int? get card => _card;
  int? _card;

  /// The card being dragged, and where it would land.
  PlacingDrag? get drag => _drag;
  PlacingDrag? _drag;

  /// Whether the player's card dragged now would go to Tobi.
  bool get overTobi => _overTobi;
  bool _overTobi = false;

  /// Where the card the player sent lies until Tobi's hand takes it.
  CardBox? get dropped => _dropped;
  CardBox? _dropped;

  /// Tobi's side, which takes a card the player sends anywhere on it: his
  /// half of the field, from its far edge to the band, and a little round
  /// it ([IkkiuchiSendStyle.sideOutset]).
  Rect get tobiSide {
    final field = scene.field;
    return Rect.fromLTRB(field.left, field.top, field.right, scene.band.top).inflate(IkkiuchiSendStyle.sideOutset);
  }

  static final _layoutRules = IkkiuchiLayout.ofPoems();

  /// The player is to send Tobi a card.
  void startSending() {
    if (scene.busy || scene.sides == null) return;
    _stage = IkkiuchiSendStage.sending;
    scene.clearCall();
  }

  /// Tobi picks a card of his and sends it; false when he has none.
  bool startReceiving() {
    final sides = scene.sides;
    if (scene.busy || sides == null) return false;
    final id = sides.tobiSends(
        smart: IkkiuchiTobi(scene.tobiRating).smartSend, alike: _layoutRules.alike, rng: scene.rng);
    if (id == null) return false;
    final board = scene.board;
    final wait = scene.layout.wait;
    final carry = IkkiuchiCarry(
      tobi: board.tobi,
      from: board.cards.card(id).box,
      to: CardBox(Vec(wait.center.dx, wait.center.dy), wait.width / 2, wait.height / 2),
      cardW: board.cards.cardW,
      side: wait.center.dx < board.tobi.centreX ? ArmSide.left : ArmSide.right,
      endFace: TobiFace.pointing,
    );
    board.carryCard(carry, id);
    _card = id;
    _stage = IkkiuchiSendStage.carrying;
    scene.clearCall();
    return true;
  }

  /// Each frame: once his arm is done carrying his card, it waits and his
  /// side closes up; the card the player sent is laid down.
  void advance() {
    final id = _card, sides = scene.sides;
    if (id == null || sides == null) return;
    if (_stage == IkkiuchiSendStage.placing) return _layDown(id);
    if (_stage != IkkiuchiSendStage.carrying || scene.board.carrying) return;
    if (targets().freeSpots.isEmpty) {
      _giveToPlayer(id);
      _stage = IkkiuchiSendStage.none;
      _card = null;
      return;
    }
    _stage = IkkiuchiSendStage.waiting;
    scene.board.heldFace = TobiFace.pointing;
    scene.relayout(sides.without(id));
  }

  /// Once his side has made room for card [id] the player sent, his arm
  /// takes it from where it lies and lays it at its home; once his arm is
  /// back, it lies there and the 送り札 is over.
  void _layDown(int id) {
    final board = scene.board;
    if (board.cards.gliding) return;
    if (board.carry == null) {
      final from = _dropped!;
      board.carryCard(
        IkkiuchiCarry(
          tobi: board.tobi,
          from: from,
          to: board.cards.card(id).home,
          cardW: board.cards.cardW,
          side: from.centre.x < board.tobi.centreX ? ArmSide.left : ArmSide.right,
        ),
        id,
      );
      return;
    }
    if (board.carrying) return;
    board.cards.putHome(board.cards.card(id));
    _stage = IkkiuchiSendStage.none;
    _card = null;
    _dropped = null;
    scene.settle();
  }

  /// Calls the 送り札 off where it stands, leaving the board whole: a card
  /// the player lifted glides back; the card they sent lies at its home on
  /// his side, his arm still; the card he sends, in his hand or waiting,
  /// goes to the first free spot on the player's side (which counts it
  /// theirs from his pick, [IkkiuchiBoardScene.cardsLeft]), or past a row's
  /// room with none free ([IkkiuchiSides.squeezedIn]).
  void cancel() {
    final board = scene.board;
    switch (_stage) {
      case IkkiuchiSendStage.none:
        return;
      case IkkiuchiSendStage.sending:
        if (_drag case final drag?) {
          board.cards.glideFrom({drag.card: spots.liftedBox(drag.at)},
              ms: _ms(IkkiuchiPlayTuning.relayoutGlide), ease: IkkiuchiPlayTuning.relayoutCurve.transform);
        }
      case IkkiuchiSendStage.placing:
        board.dropCarry();
        board.cards.putHome(board.cards.card(_card!));
        scene.settle();
      case IkkiuchiSendStage.carrying || IkkiuchiSendStage.waiting:
        _giveToPlayer(_card!);
    }
    _stage = IkkiuchiSendStage.none;
    _card = null;
    _drag = null;
    _dropped = null;
    _overTobi = false;
    scene.refresh();
  }

  /// Puts Tobi's card [id], from where it is now, on the player's side.
  void _giveToPlayer(int id) {
    final board = scene.board, sides = scene.sides!, wait = scene.wait;
    final from = board.carried?.box ??
        (_stage == IkkiuchiSendStage.carrying
            ? board.cards.card(id).box
            : CardBox(Vec(wait.center.dx, wait.center.dy), wait.width / 2, wait.height / 2));
    final next = [
          for (final (spot, _) in targets().freeSpots) ?sides.placed(id, spot),
        ].firstOrNull ??
        sides.squeezedIn(id);
    board.heldFace = null;
    scene.relayout(next, from: {id: from});
    onSent?.call(id);
  }

  // Touches, in board dp.

  /// The card a drag starting [at] picks up: one of the player's while
  /// they send, or Tobi's waiting card.
  ({int card, bool fromStack})? cardAt(Offset at) {
    switch (_stage) {
      case IkkiuchiSendStage.sending:
        if (spots.cardAt(at) case final id?) return (card: id, fromStack: false);
      case IkkiuchiSendStage.waiting:
        if (scene.wait.contains(at)) return (card: _card!, fromStack: true);
      case IkkiuchiSendStage.none || IkkiuchiSendStage.placing || IkkiuchiSendStage.carrying:
    }
    return null;
  }

  void dragStart(int card, {required bool fromStack, required Offset at}) {
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

  void dragEnd() {
    final drag = _drag, sides = scene.sides;
    if (drag == null || sides == null) return;
    _drag = null;
    final from = {drag.card: spots.liftedBox(drag.at)};
    if (!drag.fromStack) {
      if (_overTobi) {
        final lifted = spots.liftedRect(drag.at), size = cardSize;
        _stage = IkkiuchiSendStage.placing;
        _card = drag.card;
        _dropped = CardBox(Vec(lifted.center.dx, lifted.center.dy), size.width / 2, size.height / 2);
        scene.relayout(sides.toTobi(drag.card), held: {drag.card});
        onSent?.call(drag.card);
      } else {
        scene.board.cards.glideFrom(from,
            ms: _ms(IkkiuchiPlayTuning.relayoutGlide), ease: IkkiuchiPlayTuning.relayoutCurve.transform);
      }
      _overTobi = false;
    } else if (drag.spot case final spot?) {
      _place(spot, from: from);
    }
    scene.refresh();
  }

  /// A tap on a spot or a card places Tobi's waiting card there.
  void tap(Offset at) {
    final spot = _stage == IkkiuchiSendStage.waiting ? targets().spotAt(at.dx, at.dy) : null;
    if (spot == null) return;
    final wait = scene.wait;
    _place(spot, from: {_card!: CardBox(Vec(wait.center.dx, wait.center.dy), wait.width / 2, wait.height / 2)});
  }

  void _place(PlacingSpot spot, {required Map<int, CardBox> from}) {
    final card = _card!;
    final next = scene.sides?.placed(card, spot);
    if (next == null) return;
    _stage = IkkiuchiSendStage.none;
    _card = null;
    scene.board.heldFace = null;
    scene.relayout(next, from: from);
    onSent?.call(card);
  }

  PlacingDrag _dragAt(int card, {required bool fromStack, required Offset at}) {
    if (!fromStack) {
      _overTobi = tobiSide.contains(spots.liftedRect(at).center);
      return PlacingDrag(card: card, fromStack: false, at: at);
    }
    return PlacingDrag(card: card, fromStack: true, at: at, spot: targets().spotAt(at.dx, at.dy));
  }

  /// Where the player's waiting card may go: their side's cards, the free
  /// group ends the field has room for, and the open middle.
  PlacingTargets targets() => spots.targets();

  Rect? rectOf(PlacingSpot spot) => spots.rectOf(spot);

  ({FieldRow row, RowPart part})? placeOf(PlacingSpot spot) => spots.placeOf(spot);

  Size get cardSize => spots.cardSize;

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
}
