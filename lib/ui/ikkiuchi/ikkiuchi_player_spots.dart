import 'dart:ui';

import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../domain/placing.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';

/// The player's side of a board scene as the placing sees it, in board dp:
/// where their cards and the free spots lie on the layout, and where a
/// dragged card rides ([IkkiuchiSendStyle.look]). A card from Tobi and a
/// card of theirs moved about are placed by it alike.
class IkkiuchiPlayerSpots {
  const IkkiuchiPlayerSpots(this.scene);

  final IkkiuchiBoardScene scene;

  /// Where a card may go on the player's side: their cards' places, the
  /// free group ends the field has room for, and the open middle. [moving],
  /// one of their cards being dragged, is left out of the side and of the
  /// cards.
  PlacingTargets targets({int? moving}) {
    final layout = scene.layout;
    final sides = scene.sides!;
    return PlacingTargets(
      (moving == null ? sides : sides.without(moving)).playerBoard,
      moving: moving,
      cards: {
        for (final c in layout.cards)
          if (c.side == IkkiuchiSide.player && c.id != moving) c.id: fieldRect(c.box),
      },
      clusterEnd: layout.playerEnd,
      openMiddle: (row) => layout.playerMiddle(row, leaving: moving),
    );
  }

  /// Where [spot] lies on the board: the card it takes the place of, the
  /// free group end, or the place in the open middle the card would take,
  /// [moving] gone from the side.
  Rect? rectOf(PlacingSpot spot, {int? moving}) {
    final layout = scene.layout;
    final rect = switch (spot) {
      CardSpot(:final poemId) => [
          for (final c in layout.cards)
            if (c.id == poemId) fieldRect(c.box),
        ].firstOrNull,
      ClusterEnd(:final row, :final part) => layout.playerEnd(row, part),
      OpenMiddle(:final row, :final index) => layout.playerMiddleAt(row, index, leaving: moving),
    };
    return rect == null ? null : Rect.fromLTWH(rect.x, rect.y, rect.w, rect.h);
  }

  /// Where [spot] is on the player's side: its row, and its group or open
  /// middle.
  ({FieldRow row, RowPart part})? placeOf(PlacingSpot spot) => switch (spot) {
        ClusterEnd(:final row, :final part) => (row: row, part: part),
        CardSpot(:final poemId) => switch (scene.sides!.playerBoard.side.placeOf(poemId)) {
            (row: final row, part: final part, index: _) => (row: row, part: part),
            null => null,
          },
        OpenMiddle(:final row) => (row: row, part: RowPart.middle),
      };

  /// The player's card lying [at], if any.
  int? cardAt(Offset at) {
    for (final c in scene.board.cards.cards) {
      if (c.side == IkkiuchiSide.player && c.onBoard && !c.held && boundsOf(c.box).contains(at)) return c.id;
    }
    return null;
  }

  /// The field's cards' size on the board.
  Size get cardSize => Size(scene.layout.cardW, scene.layout.cardW * IkkiuchiField.cardH);

  /// Where a dragged card rides with the finger [at].
  Rect liftedRect(Offset at) => PlacingRiding.liftedRect(at, card: cardSize, look: IkkiuchiSendStyle.look);

  CardBox liftedBox(Offset at) {
    final r = liftedRect(at);
    return CardBox(Vec(r.center.dx, r.center.dy), r.width / 2, r.height / 2);
  }

  /// The upright rect around [b], however it is turned.
  static Rect boundsOf(CardBox b) => Rect.fromCenter(
      center: Offset(b.centre.x, b.centre.y), width: 2 * b.reachAlong(const Vec(1, 0)), height: 2 * b.reachAlong(const Vec(0, 1)));

  static FieldRect fieldRect(CardBox b) => FieldRect(b.centre.x - b.hw, b.centre.y - b.hh, 2 * b.hw, 2 * b.hh);
}
