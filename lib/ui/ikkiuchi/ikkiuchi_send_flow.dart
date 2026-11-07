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
/// Tobi; Tobi's arm carrying his card across; or his card waiting for the
/// player to place it.
enum IkkiuchiSendStage { none, sending, carrying, waiting }

/// A 送り札 on a board scene, in both directions.
///
/// The player sends: they drag one of their cards; let go over Tobi's side
/// ([tobiSide], the middle of the card riding there) it goes to its home
/// there, his row and group taking it in home order; let go anywhere else
/// it glides back.
///
/// Tobi sends: he picks one of his cards ([IkkiuchiSides.tobiSends], at his
/// rating's smart send), his arm takes it off his side, turns it to face
/// the player and sets it down at the waiting spot, and he points at it.
/// His side closes up; the player places it by the placing's rules
/// ([IkkiuchiSides.placed]): a tap on a free spot or a card, or a drag
/// there. Placing it ends the 送り札.
///
/// Every change of the sides lays the board out afresh ([IkkiuchiBoardScene.relayout]).
/// Neither starts while the player moves their cards about.
class IkkiuchiSendFlow {
  IkkiuchiSendFlow(this.scene) : spots = IkkiuchiPlayerSpots(scene);

  final IkkiuchiBoardScene scene;

  /// Where the player's cards and spots lie.
  final IkkiuchiPlayerSpots spots;

  IkkiuchiSendStage get stage => _stage;
  IkkiuchiSendStage _stage = IkkiuchiSendStage.none;
  bool get active => _stage != IkkiuchiSendStage.none;

  /// The card sent: Tobi's from his pick until placed, or the player's
  /// while dragged.
  int? get card => _card;
  int? _card;

  /// The card being dragged, and where it would land.
  PlacingDrag? get drag => _drag;
  PlacingDrag? _drag;

  /// Whether the player's card dragged now would go to Tobi.
  bool get overTobi => _overTobi;
  bool _overTobi = false;

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

  /// Each frame: once his arm is done, his card waits and his side closes
  /// up.
  void advance() {
    final id = _card, sides = scene.sides;
    if (_stage != IkkiuchiSendStage.carrying || scene.board.carrying || id == null || sides == null) return;
    _stage = IkkiuchiSendStage.waiting;
    scene.board.heldFace = TobiFace.pointing;
    scene.relayout(sides.without(id));
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
      case IkkiuchiSendStage.none || IkkiuchiSendStage.carrying:
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
        _stage = IkkiuchiSendStage.none;
        scene.relayout(sides.toTobi(drag.card), from: from);
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
    final next = scene.sides?.placed(_card!, spot);
    if (next == null) return;
    _stage = IkkiuchiSendStage.none;
    _card = null;
    scene.board.heldFace = null;
    scene.relayout(next, from: from);
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
