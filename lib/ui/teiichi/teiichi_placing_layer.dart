import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/teiichi.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../ankiren/ankiren_field_view.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// A card being dragged while placing: the stack's top card, or a placed
/// one ([fromStack] false); the finger [at], on the field; and where it
/// would land: a [spot], back [onStack], or nowhere.
class TeiichiDrag {
  const TeiichiDrag({required this.card, required this.fromStack, required this.at, this.spot, this.onStack = false});

  final int card;
  final bool fromStack;
  final Offset at;
  final TeiichiSpot? spot;
  final bool onStack;

  bool get lands => spot != null || onStack;
}

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
  Widget build(BuildContext context) => Stack(children: [
        for (final (spot, rect) in spots) ...[
          Positioned.fromRect(rect: rect, child: const _DashedSpot()),
          if (spot is OpenMiddle)
            if (_clearest(rect) case final clear?) Positioned.fromRect(rect: clear, child: const _MiddleLabel()),
        ],
      ]);

  /// The widest stretch of [spot] no card lies over, if it is wide enough
  /// for the open middle's name.
  Rect? _clearest(Rect spot) {
    final over = [for (final c in cards) if (c.overlaps(spot)) c]..sort((a, b) => a.left.compareTo(b.left));
    var (from, best) = (spot.left, (spot.left, spot.left));
    for (final c in [...over, Rect.fromLTWH(spot.right, spot.top, 0, spot.height)]) {
      if (c.left - from > best.$2 - best.$1) best = (from, c.left);
      from = c.right > from ? c.right : from;
    }
    final width = best.$2 - best.$1;
    return width < TeiichiPlayLayout.middleLabelRoom ? null : Rect.fromLTRB(best.$1, spot.top, best.$2, spot.bottom);
  }
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
    final shown = _shown(stack, drag);
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) => onTap(d.localPosition),
      onPanStart: (d) {
        final picked = cardAt(d.localPosition);
        if (picked != null) onDragStart(picked.card, fromStack: picked.fromStack, at: d.localPosition);
      },
      onPanUpdate: (d) => onDrag(d.localPosition),
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        if (showHint) note(_Note(text: s.teiichiPlaceHint, icon: IconArt.arrow, turned: true), left: true),
        if (shown.isEmpty && drag == null) note(_Note(text: s.teiichiAllPlaced(cards.length)), left: false),
      ]),
    );
  }
}

/// The stack as it shows with [drag] under way: without its top card when
/// that is the one dragged.
List<int> _shown(List<int> stack, TeiichiDrag? drag) => drag != null && drag.fromStack ? stack.skip(1).toList() : stack;

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
    final shown = _shown(stack, drag);
    final width = placement.geometry.width * placement.scale;
    final liftedW = math.max(
        AnkirenFieldSize.cardW * placement.scale * TeiichiPlayLayout.dragScale, TeiichiPlayLayout.dragLeastWidth);
    final liftedH = liftedW * AnkirenFieldSize.cardH / AnkirenFieldSize.cardW;
    final lifted = drag == null
        ? null
        : Rect.fromCenter(
            center: drag.at - Offset(0, liftedH * (TeiichiPlayLayout.dragLift + 0.5)),
            width: liftedW,
            height: liftedH,
          );
    // The name goes left of the card, or right of it in the left of a
    // narrow field or near the left edge of a wide one.
    final toRight = lifted != null && lifted.left < math.min(TeiichiPlayLayout.noteWidth, width / 2);
    return Stack(clipBehavior: Clip.none, children: [
      if (shown.isEmpty)
        Positioned.fromRect(rect: pile, child: const _DashedSpot())
      else
        Positioned.fromRect(rect: pile, child: _Stack(cards: shown, showNumber: showNumber)),
      if (drag != null) ...[
        Positioned.fromRect(rect: lifted!, child: _Lifted(drag.card, showNumber: showNumber)),
        if (landing case final name?)
          Positioned(
            top: lifted.top,
            height: TeiichiPlayLayout.landingTagRoom,
            left: toRight ? lifted.right + TeiichiPlayLayout.landingTagGap : null,
            right: toRight ? null : width - lifted.left + TeiichiPlayLayout.landingTagGap,
            child: _Tag(name, fontSize: TeiichiPlayLayout.landingTagFont),
          ),
      ],
    ]);
  }
}

/// A dashed spot on the tatami.
class _DashedSpot extends StatelessWidget {
  const _DashedSpot();

  @override
  Widget build(BuildContext context) => const DashedBox(
        color: TeiichiPlayLayout.spotFill,
        ink: TeiichiPlayLayout.spotInk,
        border: TeiichiPlayLayout.spotBorder,
        child: SizedBox.expand(),
      );
}

/// The open middle's name, centred in its room.
class _MiddleLabel extends StatelessWidget {
  const _MiddleLabel();

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            S.of(context).teiichiOpenMiddle,
            style: const TextStyle(
              fontWeight: Weights.black,
              fontSize: TeiichiPlayLayout.middleLabelFont,
              letterSpacing: TeiichiPlayLayout.middleLabelTracking * TeiichiPlayLayout.middleLabelFont,
              color: TeiichiPlayLayout.spotInk,
            ),
          ),
        ),
      );
}

/// The stack: its top card face up over the edges of a few cards under it,
/// and how many are left on an ink tag at its foot.
class _Stack extends StatelessWidget {
  const _Stack({required this.cards, required this.showNumber});

  final List<int> cards;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final depth = math.min(TeiichiPlayLayout.stackDepth, cards.length - 1);
    const step = TeiichiPlayLayout.stackStep;
    return Stack(clipBehavior: Clip.none, children: [
      for (var i = depth; i >= 1; i--)
        Positioned(
          left: i * step,
          top: i * step,
          right: -i * step,
          bottom: -i * step,
          child: const _CardEdge(),
        ),
      Positioned.fill(child: TorifudaCard(poem: poems[cards.first], showNumber: showNumber)),
      Positioned(
        left: 0,
        right: 0,
        bottom: -TeiichiPlayLayout.stackTagRoom + TeiichiPlayLayout.stackTagOverlap,
        child: Center(child: _Tag(S.of(context).teiichiLeft(cards.length), fontSize: TeiichiPlayLayout.stackTagFont)),
      ),
    ]);
  }
}

/// The edge of a card under the stack's top one.
class _CardEdge extends StatelessWidget {
  const _CardEdge();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          color: AnkirenPlayLayout.backFill,
          border: Border.fromBorderSide(
              BorderSide(color: AnkirenPlayLayout.backBorder, width: AnkirenPlayLayout.backBorderWidth)),
        ),
      );
}

/// A card picked up: face up, outlined in ink.
class _Lifted extends StatelessWidget {
  const _Lifted(this.poemId, {required this.showNumber});

  final int poemId;
  final bool showNumber;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: Palette.ink, width: TeiichiPlayLayout.dragBorder),
        ),
        child: TorifudaCard(poem: poems[poemId], showNumber: showNumber),
      );
}

/// Paper words on an ink tag.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: TeiichiPlayLayout.stackTagPadding,
          child: Text(text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontWeight: Weights.black, fontSize: fontSize, color: Palette.paper, height: 1.2)),
        ),
      );
}

/// A note in a paper box, with an [icon] before it (pointing down when
/// [turned]).
class _Note extends StatelessWidget {
  const _Note({required this.text, this.icon, this.turned = false});

  final String text;
  final VectorArt? icon;
  final bool turned;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return DecoratedBox(
      decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
      child: Padding(
        padding: TeiichiPlayLayout.notePadding,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            RotatedBox(quarterTurns: turned ? 1 : 0, child: MangaIcon(icon, size: TeiichiPlayLayout.noteIcon)),
            const SizedBox(width: Gaps.tight),
          ],
          Flexible(
            child: Text.rich(Phrases.span(text),
                style: const TextStyle(fontWeight: Weights.black, fontSize: TeiichiPlayLayout.noteFont)),
          ),
        ]),
      ),
    );
  }
}
