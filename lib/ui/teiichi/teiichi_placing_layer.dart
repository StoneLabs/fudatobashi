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
/// centred across the field.
Rect stackRect(FieldPlacement placement) {
  final room = placement.roomAbove;
  final height = math.min(TeiichiPlayLayout.stackCardH,
      room.height - 2 * TeiichiPlayLayout.stackMargin - TeiichiPlayLayout.stackTagRoom);
  final width = height * AnkirenFieldSize.cardW / AnkirenFieldSize.cardH;
  return Rect.fromLTWH(room.center.dx - width / 2, room.top + TeiichiPlayLayout.stackMargin, width, height);
}

/// What 定位置 draws over its field while the cards are laid out, and the
/// touches there: the dashed spots a card may go ([freeSpots]), the stack
/// above the band with its count ([stack], top first) or, once every card
/// is placed, its empty spot and a note; the hint before the first card is
/// placed; and a card being dragged ([drag]), riding above the finger,
/// with the name of where it would land over its spot ([landing]).
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
    required this.freeSpots,
    required this.showHint,
    required this.drag,
    required this.landing,
    required this.showNumber,
    required this.onTap,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
  });

  final FieldPlacement placement;
  final List<int> stack;

  /// Every card laid out, on screen.
  final Map<int, Rect> cards;

  final List<(TeiichiSpot, Rect)> freeSpots;
  final bool showHint;
  final TeiichiDrag? drag;

  /// Where [drag] would land, on screen, and what that place is called.
  final (Rect, String)? landing;
  final bool showNumber;

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
    final drag = this.drag;
    final pile = stackRect(placement);
    final shown = drag != null && drag.fromStack ? stack.skip(1).toList() : stack;
    final room = placement.roomAbove;
    final cardSize = Size(AnkirenFieldSize.cardW, AnkirenFieldSize.cardH) * placement.scale;
    final noteWidth = math.max(0.0, math.min(TeiichiPlayLayout.noteWidth, pile.left - TeiichiPlayLayout.noteGap));
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
        for (final (spot, rect) in freeSpots) Positioned.fromRect(rect: rect, child: _DashedSpot(middle: spot is OpenMiddle)),
        if (showHint && noteWidth > 0)
          Positioned(
            right: room.width - pile.left + TeiichiPlayLayout.noteGap,
            top: room.top,
            height: room.height,
            width: noteWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: _Note(text: s.teiichiPlaceHint, icon: IconArt.arrow, turned: true),
            ),
          ),
        if (shown.isEmpty) ...[
          Positioned.fromRect(rect: pile, child: const _DashedSpot(middle: false)),
          if (drag == null && noteWidth > 0)
            Positioned(
              left: pile.right + TeiichiPlayLayout.noteGap,
              top: room.top,
              height: room.height,
              width: noteWidth,
              child: Align(alignment: Alignment.centerLeft, child: _Note(text: s.teiichiAllPlaced(cards.length))),
            ),
        ] else
          Positioned.fromRect(
            rect: pile,
            child: _Stack(cards: shown, showNumber: showNumber),
          ),
        if (landing case (final rect, final name)?)
          Positioned(
            left: rect.center.dx - TeiichiPlayLayout.noteWidth / 2,
            width: TeiichiPlayLayout.noteWidth,
            top: rect.top - TeiichiPlayLayout.landingTagRoom,
            height: TeiichiPlayLayout.landingTagRoom - TeiichiPlayLayout.landingTagGap,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _Tag(name, fontSize: TeiichiPlayLayout.landingTagFont),
            ),
          ),
        if (drag != null)
          Positioned(
            left: drag.at.dx - cardSize.width * TeiichiPlayLayout.dragScale / 2,
            top: drag.at.dy - cardSize.height * (TeiichiPlayLayout.dragLift + TeiichiPlayLayout.dragScale / 2),
            width: cardSize.width * TeiichiPlayLayout.dragScale,
            height: cardSize.height * TeiichiPlayLayout.dragScale,
            child: IgnorePointer(child: _Lifted(drag.card, showNumber: showNumber)),
          ),
      ]),
    );
  }
}

/// A dashed spot on the tatami; the open middle's says so.
class _DashedSpot extends StatelessWidget {
  const _DashedSpot({required this.middle});

  final bool middle;

  @override
  Widget build(BuildContext context) => DashedBox(
        color: TeiichiPlayLayout.spotFill,
        ink: TeiichiPlayLayout.spotInk,
        border: TeiichiPlayLayout.spotBorder,
        child: middle
            ? Center(
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
              )
            : const SizedBox.expand(),
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
