import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../../domain/placing.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';

/// Where a 送り札 stands: none; the player picking a card of theirs to send
/// Tobi; Tobi's arm carrying his card across; or his card waiting for the
/// player to place it.
enum IkkiuchiSendStage { none, sending, carrying, waiting }

/// A 送り札 on a board scene, in both directions.
///
/// The player sends: they drag one of their cards; let go over Tobi's side
/// (its middle above the band) it goes to its home there, his row and group
/// taking it in home order; let go anywhere else it glides back.
///
/// Tobi sends: he picks one of his cards ([IkkiuchiSides.tobiSends], at his
/// rating's smart send), his arm takes it off his side, turns it to face
/// the player and sets it down at the waiting spot, and he points at it.
/// His side closes up; the player places it by the placing's rules
/// ([IkkiuchiSides.placed]): a tap on a free spot or a card, or a drag
/// there. Placing it ends the 送り札.
///
/// Every change of the sides lays the board out afresh ([IkkiuchiBoardScene.relayout]).
class IkkiuchiSendFlow {
  IkkiuchiSendFlow(this.scene);

  final IkkiuchiBoardScene scene;

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

  static final _layoutRules = IkkiuchiLayout.ofPoems();

  /// The player is to send Tobi a card.
  void startSending() {
    if (active || scene.sides == null) return;
    _stage = IkkiuchiSendStage.sending;
    scene.clearCall();
  }

  /// Tobi picks a card of his and sends it; false when he has none.
  bool startReceiving() {
    final sides = scene.sides;
    if (active || sides == null) return false;
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
        for (final c in scene.board.cards.cards) {
          if (c.side == IkkiuchiSide.player && c.onBoard && !c.held && _rectOf(c.box).contains(at)) {
            return (card: c.id, fromStack: false);
          }
        }
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
    final from = {drag.card: _liftedBox(drag.at)};
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
      _overTobi = _liftedRect(at).center.dy < scene.band.top;
      return PlacingDrag(card: card, fromStack: false, at: at);
    }
    return PlacingDrag(card: card, fromStack: true, at: at, spot: targets().spotAt(at.dx, at.dy));
  }

  // Where things lie, in board dp.

  /// Where the player's waiting card may go: their side's cards and the
  /// free group ends the field has room for.
  PlacingTargets targets() {
    final layout = scene.layout;
    return PlacingTargets(
      scene.sides!.playerBoard,
      cards: {
        for (final c in layout.cards)
          if (c.side == IkkiuchiSide.player) c.id: _fieldRect(c.box),
      },
      clusterEnd: layout.playerEnd,
    );
  }

  /// Where [spot] lies on the board: the card it takes the place of, or the
  /// free spot.
  Rect? rectOf(PlacingSpot spot) {
    final layout = scene.layout;
    final rect = switch (spot) {
      CardSpot(:final poemId) => [
          for (final c in layout.cards)
            if (c.id == poemId) _fieldRect(c.box),
        ].firstOrNull,
      ClusterEnd(:final row, :final part) => layout.playerEnd(row, part),
      OpenMiddle() => null,
    };
    return rect == null ? null : Rect.fromLTWH(rect.x, rect.y, rect.w, rect.h);
  }

  /// Where [spot] is on the player's side: its row, and its group.
  ({FieldRow row, RowPart part})? placeOf(PlacingSpot spot) => switch (spot) {
        ClusterEnd(:final row, :final part) => (row: row, part: part),
        CardSpot(:final poemId) => switch (scene.sides!.playerBoard.side.placeOf(poemId)) {
            (row: final row, part: final part, index: _) => (row: row, part: part),
            null => null,
          },
        OpenMiddle() => null,
      };

  /// The field's cards' size on the board.
  Size get cardSize => Size(scene.layout.cardW, scene.layout.cardW * IkkiuchiField.cardH);

  /// Where a dragged card rides with the finger [at].
  Rect _liftedRect(Offset at) => PlacingRiding.liftedRect(at, card: cardSize, look: IkkiuchiSendStyle.look);

  CardBox _liftedBox(Offset at) {
    final r = _liftedRect(at);
    return CardBox(Vec(r.center.dx, r.center.dy), r.width / 2, r.height / 2);
  }

  static Rect _rectOf(CardBox b) => Rect.fromCenter(
      center: Offset(b.centre.x, b.centre.y), width: 2 * b.reachAlong(const Vec(1, 0)), height: 2 * b.reachAlong(const Vec(0, 1)));

  static FieldRect _fieldRect(CardBox b) => FieldRect(b.centre.x - b.hw, b.centre.y - b.hh, 2 * b.hw, 2 * b.hh);

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
}
