import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/placing.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_arrange_flow.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_send_layer.dart';

/// What 並べ替え ([IkkiuchiArrangeFlow]) draws on the board, in board dp,
/// and the touches it takes, with the placing's look
/// ([IkkiuchiSendStyle.look]). Its [part] under the board's cards: the
/// dashed spots a card may go. Over them: where a card dragged would land,
/// and the touches. On top: a card being dragged.
class IkkiuchiArrangeLayer extends StatelessWidget {
  const IkkiuchiArrangeLayer({super.key, required this.scene, required this.part});

  final IkkiuchiBoardScene scene;
  final IkkiuchiLayerPart part;

  IkkiuchiArrangeFlow get _flow => scene.arrange;

  static const _look = IkkiuchiSendStyle.look;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          if (!_flow.active) return const SizedBox.shrink();
          return switch (part) {
            IkkiuchiLayerPart.under => _spots(context),
            IkkiuchiLayerPart.over => _over(),
            IkkiuchiLayerPart.top => IgnorePointer(child: _top(context)),
          };
        },
      );

  Widget _spots(BuildContext context) {
    final targets = _flow.targets();
    return PlacingSpots(
      spots: [for (final (spot, r) in targets.freeSpots) (spot, Rect.fromLTWH(r.x, r.y, r.w, r.h))],
      cards: [for (final r in targets.cards.values) Rect.fromLTWH(r.x, r.y, r.w, r.h)],
      look: _look,
      middleLabel: S.of(context).ikkiuchiOpenMiddle,
    );
  }

  Widget _over() {
    final flow = _flow, drag = flow.drag;
    final spot = drag?.spot;
    final landing = spot == null ? null : flow.spots.rectOf(spot, moving: drag?.card);
    return PlacingGestures(
      cardAt: flow.cardAt,
      onTap: (_) {},
      onDragStart: flow.dragStart,
      onDrag: flow.dragTo,
      onDragEnd: flow.dragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        if (landing != null) Positioned.fromRect(rect: landing, child: const PlacingLanding(look: _look)),
      ]),
    );
  }

  Widget _top(BuildContext context) {
    final drag = _flow.drag;
    if (drag == null) return const SizedBox.shrink();
    return PlacingRiding(
      drag: drag,
      landing: _spotName(S.of(context), drag.spot),
      card: _flow.spots.cardSize,
      width: scene.layout.size.x,
      look: _look,
      showNumber: ProgressScope.of(context).settings.showPoemNumber,
    );
  }

  String? _spotName(S s, PlacingSpot? spot) {
    final place = spot == null ? null : _flow.spots.placeOf(spot);
    return place == null ? null : s.ikkiuchiSpotName(place.row, place.part);
  }
}
