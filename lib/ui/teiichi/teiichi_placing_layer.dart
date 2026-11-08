import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/teiichi.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../ankiren/ankiren_field_view.dart';
import '../placing/placing_widgets.dart';

/// A card being dragged while placing: the stack's top card, or a placed
/// one ([PlacingDrag.fromStack] false), on the field.
typedef TeiichiDrag = PlacingDrag;

/// Where the stack lies in the room above the band of [placement]: its top
/// card as tall as the room allows, up to [TeiichiPlayLayout.stackCardH],
/// centred across the field, just above the band with its count under it.
Rect stackRect(FieldPlacement placement) {
  final room = placement.roomAbove;
  const margin = TeiichiPlayLayout.stackMargin;
  const tag = TeiichiPlayLayout.stackTagRoom;
  final height = math.min(TeiichiPlayLayout.stackCardH, room.height - 2 * margin - tag);
  final width = height * AnkirenFieldSize.cardW / AnkirenFieldSize.cardH;
  return Rect.fromLTWH(room.center.dx - width / 2, room.bottom - margin - tag - height, width, height);
}

/// The dashed spots a card may go while 定位置's cards are laid out, under
/// the cards: the cluster ends, and the open middle with its name in its
/// widest stretch clear of its middle cards ([cards]).
class TeiichiSpots extends StatelessWidget {
  const TeiichiSpots({super.key, required this.spots, required this.cards});

  /// Each spot and where it lies, on screen.
  final List<(TeiichiSpot, Rect)> spots;
  final Iterable<Rect> cards;

  @override
  Widget build(BuildContext context) => PlacingSpots(
        spots: spots,
        cards: cards,
        look: TeiichiPlayLayout.placing,
        middleLabel: S.of(context).teiichiOpenMiddle,
      );
}

/// What 定位置 draws over its field while the cards are laid out, and the
/// touches there: the note once every card is placed ([stack], top first,
/// is empty), and the hint before the first card is placed, right and left
/// of the stack or, without room beside it, above it. The stack and
/// the card dragged ([drag]) are [TeiichiRiding]'s, above the band.
///
/// A tap goes to [onTap], and a drag that starts on the stack's top card
/// or a placed card ([cardAt]) to [onDragStart], then [onDrag] and
/// [onDragEnd].
class TeiichiPlacingLayer extends StatelessWidget {
  const TeiichiPlacingLayer({
    super.key,
    required this.placement,
    required this.stack,
    required this.cards,
    required this.showHint,
    required this.drag,
    required this.onTap,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
  });

  final FieldPlacement placement;
  final List<int> stack;

  /// Every card laid out, on screen.
  final Map<int, Rect> cards;

  final bool showHint;
  final TeiichiDrag? drag;

  final ValueChanged<Offset> onTap;
  final void Function(int card, {required bool fromStack, required Offset at}) onDragStart;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  /// The card a drag starting [at] picks up: the stack's top card, or a
  /// placed one.
  ({int card, bool fromStack})? cardAt(Offset at) {
    final top = stack.firstOrNull;
    if (top != null && stackRect(placement).contains(at)) return (card: top, fromStack: true);
    for (final MapEntry(key: id, value: rect) in cards.entries) {
      if (rect.contains(at)) return (card: id, fromStack: false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pile = stackRect(placement);
    final shown = PlacingDrag.stackShown(stack, drag);
    final room = placement.roomAbove;
    // Either side of the stack when there is room for them there; else
    // above it.
    final beside = math.min(TeiichiPlayLayout.noteWidth, pile.left - room.left - TeiichiPlayLayout.noteGap);
    Widget note(Widget note, {required bool left}) {
      if (beside >= TeiichiPlayLayout.noteMinWidth) {
        return Positioned(
          left: left ? null : pile.right + TeiichiPlayLayout.noteGap,
          right: left ? room.right - pile.left + TeiichiPlayLayout.noteGap : null,
          top: room.top,
          height: room.height,
          width: beside,
          child: Align(alignment: left ? Alignment.centerRight : Alignment.centerLeft, child: note),
        );
      }
      final width = math.min(TeiichiPlayLayout.noteWidth, room.width - 2 * TeiichiPlayLayout.noteGap);
      return Positioned(
        left: room.center.dx - width / 2,
        width: width,
        top: room.top,
        height: math.max(0.0, pile.top - TeiichiPlayLayout.noteGap - room.top),
        child: Align(alignment: Alignment.bottomCenter, child: note),
      );
    }

    return PlacingGestures(
      cardAt: cardAt,
      onTap: onTap,
      onDragStart: onDragStart,
      onDrag: onDrag,
      onDragEnd: onDragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        if (showHint)
          note(PlacingNote(text: s.teiichiPlaceHint, look: TeiichiPlayLayout.placing, icon: IconArt.arrow, turned: true),
              left: true),
        if (shown.isEmpty && drag == null)
          note(PlacingNote(text: s.teiichiAllPlaced(cards.length), look: TeiichiPlayLayout.placing), left: false),
      ]),
    );
  }
}

/// What 定位置 draws above the band while the cards are laid out, without
/// taking touches: the stack with its count ([stack], top first), or its
/// empty spot once every card is placed, and a card being dragged ([drag]),
/// riding above the finger, a little larger than the field's cards and
/// never smaller than [TeiichiPlayLayout.dragLeastWidth], with the name of
/// where it would land ([landing]) beside it.
class TeiichiRiding extends StatelessWidget {
  const TeiichiRiding({
    super.key,
    required this.placement,
    required this.stack,
    required this.drag,
    required this.landing,
    required this.showNumber,
  });

  final FieldPlacement placement;
  final List<int> stack;
  final TeiichiDrag? drag;
  final String? landing;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final drag = this.drag;
    final pile = stackRect(placement);
    final shown = PlacingDrag.stackShown(stack, drag);
    const look = TeiichiPlayLayout.placing;
    return Stack(clipBehavior: Clip.none, children: [
      if (shown.isEmpty)
        Positioned.fromRect(rect: pile, child: const PlacingDashedSpot(look: look))
      else
        Positioned.fromRect(
          rect: pile,
          child: PlacingStack(cards: shown, tag: S.of(context).teiichiLeft(shown.length), look: look, showNumber: showNumber),
        ),
      if (drag != null)
        Positioned.fill(
          child: PlacingRiding(
            drag: drag,
            landing: landing,
            card: Size(AnkirenFieldSize.cardW, AnkirenFieldSize.cardH) * placement.scale,
            width: placement.geometry.width * placement.scale,
            look: look,
            showNumber: showNumber,
          ),
        ),
    ]);
  }
}
