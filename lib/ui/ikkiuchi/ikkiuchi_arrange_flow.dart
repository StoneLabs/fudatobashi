import 'dart:ui';

import '../../config/config.dart';
import '../../domain/placing.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_player_spots.dart';

/// 並べ替え on a board scene: between reads the player moves their own
/// cards about by the placing's rules ([IkkiuchiSides.placed]), as many as
/// they like, until they are done ([finish]). A card dragged from its place
/// goes to a free group end or onto a card's place, the cards inward of it
/// moving a place in; let go anywhere else it glides back. Each move lays
/// the board out afresh ([IkkiuchiBoardScene.relayout]). Nothing is read
/// meanwhile, and it never starts during a 送り札.
class IkkiuchiArrangeFlow {
  IkkiuchiArrangeFlow(this.scene) : spots = IkkiuchiPlayerSpots(scene);

  final IkkiuchiBoardScene scene;

  /// Where the player's cards and spots lie.
  final IkkiuchiPlayerSpots spots;

  bool get active => _active;
  bool _active = false;

  /// Whether the player may start: nothing else under way.
  bool get canStart => !scene.busy && scene.sides != null;

  /// The card being dragged, and where it would land.
  PlacingDrag? get drag => _drag;
  PlacingDrag? _drag;

  /// The player starts moving their cards; the call is put away.
  void start() {
    if (!canStart) return;
    _active = true;
    scene.clearCall();
  }

  /// The player is done: a card still dragged glides back, and once the
  /// cards are home the board is settled.
  void finish() {
    if (!_active) return;
    if (_drag case final drag?) {
      _drag = null;
      _glideBack(drag);
    }
    _active = false;
    scene
      ..settle()
      ..refresh();
  }

  // Touches, in board dp.

  /// The card a drag starting [at] picks up: one of the player's.
  ({int card, bool fromStack})? cardAt(Offset at) {
    if (!_active) return null;
    final id = spots.cardAt(at);
    return id == null ? null : (card: id, fromStack: false);
  }

  void dragStart(int card, {required bool fromStack, required Offset at}) {
    scene.board.cards.hold(scene.board.cards.card(card));
    _drag = _dragAt(card, at);
    scene.refresh();
  }

  void dragTo(Offset at) {
    final drag = _drag;
    if (drag == null) return;
    _drag = _dragAt(drag.card, at);
    scene.refresh();
  }

  void dragEnd() {
    final drag = _drag, sides = scene.sides;
    if (drag == null || sides == null) return;
    _drag = null;
    final next = switch (drag.spot) {
      final spot? => sides.placed(drag.card, spot),
      null => null,
    };
    if (next == null) {
      _glideBack(drag);
    } else {
      scene.relayout(next, from: {drag.card: spots.liftedBox(drag.at)});
    }
    scene.refresh();
  }

  /// Where a card may go: past the dragged card, which is left out, or for
  /// a card not on the side while none is dragged.
  PlacingTargets targets() => spots.targets(moving: _drag?.card);

  PlacingDrag _dragAt(int card, Offset at) =>
      PlacingDrag(card: card, fromStack: false, at: at, spot: spots.targets(moving: card).spotAt(at.dx, at.dy));

  void _glideBack(PlacingDrag drag) => scene.board.cards.glideFrom({drag.card: spots.liftedBox(drag.at)},
      ms: _ms(IkkiuchiPlayTuning.relayoutGlide), ease: IkkiuchiPlayTuning.relayoutCurve.transform);

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
}
