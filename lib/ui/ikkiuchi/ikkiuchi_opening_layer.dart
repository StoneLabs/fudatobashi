import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_opening_flow.dart';
import 'ikkiuchi_send_layer.dart';

/// What the opening ([IkkiuchiOpeningFlow]) draws on the board while the
/// player lays out their side, in board dp, and the touches it takes, with
/// the placing's look ([IkkiuchiSendStyle.look]). Its [part] under the
/// board's cards: the dashed spots the stack's top card, or the card
/// dragged, may go. Over them: where a card dragged would land, the hint
/// before the first card is placed, and the touches. On top: the stack
/// with its count, or its empty spot, and a card being dragged.
class IkkiuchiOpeningLayer extends StatelessWidget {
  const IkkiuchiOpeningLayer({super.key, required this.scene, required this.part});

  final IkkiuchiBoardScene scene;
  final IkkiuchiLayerPart part;

  IkkiuchiOpeningFlow get _flow => scene.opening;

  static const _look = IkkiuchiSendStyle.look;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          final stack = scene.stack;
          if (!_flow.placing || stack == null) return const SizedBox.shrink();
          return switch (part) {
            IkkiuchiLayerPart.under => _spots(context),
            IkkiuchiLayerPart.over => _over(context, stack),
            IkkiuchiLayerPart.top => IgnorePointer(child: _top(context, stack)),
          };
        },
      );

  /// The dashed spots, while there is a card to place or one is dragged.
  Widget _spots(BuildContext context) {
    final flow = _flow;
    if (flow.top == null && flow.drag == null) return const SizedBox.shrink();
    final targets = flow.targets();
    return PlacingSpots(
      spots: [for (final (spot, r) in targets.freeSpots) (spot, Rect.fromLTWH(r.x, r.y, r.w, r.h))],
      cards: [for (final r in targets.cards.values) Rect.fromLTWH(r.x, r.y, r.w, r.h)],
      look: _look,
      middleLabel: S.of(context).ikkiuchiOpenMiddle,
    );
  }

  Widget _over(BuildContext context, Rect stack) {
    final flow = _flow, drag = flow.drag;
    final spot = drag?.spot;
    final landing = drag == null || spot == null ? null : flow.spots.rectOf(spot, moving: drag.fromStack ? null : drag.card);
    return PlacingGestures(
      cardAt: flow.cardAt,
      onTap: flow.tap,
      onDragStart: flow.dragStart,
      onDrag: flow.dragTo,
      onDragEnd: flow.dragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        if (landing != null) Positioned.fromRect(rect: landing, child: const PlacingLanding(look: _look)),
        if (drag == null && scene.sides!.playerCards.isEmpty) _hint(context, stack),
      ]),
    );
  }

  /// The hint beside the stack, hanging from the top of its tag, between the stack and
  /// the board's right end or the game column; under the tag where that
  /// leaves it too little room.
  Widget _hint(BuildContext context, Rect stack) {
    final size = scene.layout.size, look = _look, gap = IkkiuchiOpeningStyle.noteGap;
    final note = PlacingNote(text: S.of(context).ikkiuchiPlaceHint, look: look);
    final tagTop = stack.bottom - look.stackTagOverlap, tagBottom = tagTop + look.stackTagRoom;
    final left = stack.right + look.stackDepth * look.stackStep + gap;
    final end = scene.layout.column?.left ?? size.x, room = end - gap - left;
    if (room >= IkkiuchiOpeningStyle.noteMinWidth) {
      return Positioned(
        left: left,
        width: math.min(IkkiuchiOpeningStyle.noteWidth, room),
        top: tagTop,
        child: Align(alignment: Alignment.topLeft, child: note),
      );
    }
    final width = math.min(IkkiuchiOpeningStyle.noteWidth, size.x - 2 * gap);
    return Positioned(
      left: (stack.center.dx - width / 2).clamp(gap, size.x - gap - width),
      width: width,
      top: tagBottom + gap,
      child: Align(alignment: Alignment.topCenter, child: note),
    );
  }

  Widget _top(BuildContext context, Rect stack) {
    final s = S.of(context);
    final showNumber = ProgressScope.of(context).settings.showPoemNumber;
    final flow = _flow, drag = flow.drag;
    final shown = PlacingDrag.stackShown(flow.stack, drag);
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fromRect(
        rect: stack,
        child: shown.isEmpty
            ? const PlacingDashedSpot(look: _look)
            : PlacingStack(cards: shown, tag: s.ikkiuchiStackLeft(shown.length), look: _look, showNumber: showNumber),
      ),
      if (drag != null)
        Positioned.fill(
          child: PlacingRiding(
            drag: drag,
            landing: drag.onStack ? s.ikkiuchiBackOnStack : _spotName(s, drag),
            card: flow.spots.cardSize,
            width: scene.layout.size.x,
            look: _look,
            showNumber: showNumber,
          ),
        ),
    ]);
  }

  String? _spotName(S s, PlacingDrag drag) {
    final spot = drag.spot;
    final place = spot == null ? null : _flow.spots.placeOf(spot);
    return place == null ? null : s.ikkiuchiSpotName(place.row, place.part);
  }
}
