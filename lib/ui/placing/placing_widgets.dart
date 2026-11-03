import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/placing.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// A card being dragged while a side is laid out: the stack's top card, or
/// a placed one ([fromStack] false); the finger [at]; and where it would
/// land: a [spot], back [onStack], or nowhere.
class PlacingDrag {
  const PlacingDrag({required this.card, required this.fromStack, required this.at, this.spot, this.onStack = false});

  final int card;
  final bool fromStack;
  final Offset at;
  final PlacingSpot? spot;
  final bool onStack;

  bool get lands => spot != null || onStack;
}

/// The touches on a side being laid out: a tap goes to [onTap], and a drag
/// that starts on a card [cardAt] picks up to [onDragStart], then [onDrag]
/// and [onDragEnd]. [child] lies under the touches.
class PlacingGestures extends StatelessWidget {
  const PlacingGestures({
    super.key,
    required this.cardAt,
    required this.onTap,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    this.child,
  });

  final ({int card, bool fromStack})? Function(Offset at) cardAt;
  final ValueChanged<Offset> onTap;
  final void Function(int card, {required bool fromStack, required Offset at}) onDragStart;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;
  final Widget? child;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
        child: child,
      );
}

/// The dashed spots a card may go while a side is laid out, under the
/// cards: the cluster ends, and an open middle with [middleLabel] in its
/// widest stretch clear of its middle cards ([cards]).
class PlacingSpots extends StatelessWidget {
  const PlacingSpots({super.key, required this.spots, required this.cards, required this.look, this.middleLabel});

  /// Each spot and where it lies, on screen.
  final List<(PlacingSpot, Rect)> spots;
  final Iterable<Rect> cards;
  final PlacingLook look;
  final String? middleLabel;

  @override
  Widget build(BuildContext context) {
    final label = middleLabel;
    return Stack(children: [
      for (final (spot, rect) in spots) ...[
        Positioned.fromRect(rect: rect, child: PlacingDashedSpot(look: look)),
        if (spot is OpenMiddle && label != null)
          if (_clearest(rect) case final clear?)
            Positioned.fromRect(rect: clear, child: _MiddleLabel(label, look: look)),
      ],
    ]);
  }

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
    return width < look.middleLabelRoom ? null : Rect.fromLTRB(best.$1, spot.top, best.$2, spot.bottom);
  }
}

/// A dashed spot on the tatami.
class PlacingDashedSpot extends StatelessWidget {
  const PlacingDashedSpot({super.key, required this.look});

  final PlacingLook look;

  @override
  Widget build(BuildContext context) => DashedBox(
        color: look.spotFill,
        ink: look.spotInk,
        border: look.spotBorder,
        child: const SizedBox.expand(),
      );
}

/// An open middle's name, centred in its room.
class _MiddleLabel extends StatelessWidget {
  const _MiddleLabel(this.text, {required this.look});

  final String text;
  final PlacingLook look;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: Weights.black,
              fontSize: look.middleLabelFont,
              letterSpacing: look.middleLabelTracking * look.middleLabelFont,
              color: look.spotInk,
            ),
          ),
        ),
      );
}

/// Where a dragged card would land: [PlacingLook.landingFill] over its
/// spot, outlined in ink.
class PlacingLanding extends StatelessWidget {
  const PlacingLanding({super.key, required this.look});

  final PlacingLook look;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: look.landingFill,
          border: Border.all(color: Palette.ink, width: look.landingBorder),
        ),
      );
}

/// The stack of cards still to place ([cards], top first): its top card
/// face up over the edges of a few cards under it, and [tag] on an ink tag
/// at its foot.
class PlacingStack extends StatelessWidget {
  const PlacingStack({super.key, required this.cards, required this.tag, required this.look, required this.showNumber});

  final List<int> cards;
  final String tag;
  final PlacingLook look;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final depth = math.min(look.stackDepth, cards.length - 1);
    final step = look.stackStep;
    return Stack(clipBehavior: Clip.none, children: [
      for (var i = depth; i >= 1; i--)
        Positioned(
          left: i * step,
          top: i * step,
          right: -i * step,
          bottom: -i * step,
          child: _CardEdge(look: look),
        ),
      Positioned.fill(child: TorifudaCard(poem: poems[cards.first], showNumber: showNumber)),
      Positioned(
        left: 0,
        right: 0,
        bottom: -look.stackTagRoom + look.stackTagOverlap,
        child: Center(child: PlacingTag(tag, fontSize: look.stackTagFont, look: look)),
      ),
    ]);
  }
}

/// The edge of a card under the stack's top one.
class _CardEdge extends StatelessWidget {
  const _CardEdge({required this.look});

  final PlacingLook look;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: look.edgeFill,
          border: Border.fromBorderSide(BorderSide(color: look.edgeInk, width: look.edgeBorder)),
        ),
      );
}

/// A card being dragged ([drag]), riding above the finger, a little larger
/// than the field's cards ([card], their size on screen) and never narrower
/// than [PlacingLook.dragLeastWidth], with the name of where it would land
/// ([landing]) beside it, within an area [width] wide.
class PlacingRiding extends StatelessWidget {
  const PlacingRiding({
    super.key,
    required this.drag,
    required this.landing,
    required this.card,
    required this.width,
    required this.look,
    required this.showNumber,
  });

  final PlacingDrag drag;
  final String? landing;
  final Size card;
  final double width;
  final PlacingLook look;
  final bool showNumber;

  /// Where the card rides with the finger [at], on screen, for field cards
  /// of [card]'s size.
  static Rect liftedRect(Offset at, {required Size card, required PlacingLook look}) {
    final w = math.max(card.width * look.dragScale, look.dragLeastWidth);
    final h = w * card.height / card.width;
    return Rect.fromCenter(center: at - Offset(0, h * (look.dragLift + 0.5)), width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    final lifted = liftedRect(drag.at, card: card, look: look);
    // The name goes left of the card, or right of it in the left of a
    // narrow area or near the left edge of a wide one.
    final toRight = lifted.left < math.min(look.landingTagFlip, width / 2);
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fromRect(rect: lifted, child: PlacingLifted(drag.card, look: look, showNumber: showNumber)),
      if (landing case final name?)
        Positioned(
          top: lifted.top,
          height: look.landingTagRoom,
          left: toRight ? lifted.right + look.landingTagGap : null,
          right: toRight ? null : width - lifted.left + look.landingTagGap,
          child: PlacingTag(name, fontSize: look.landingTagFont, look: look),
        ),
    ]);
  }
}

/// A card picked up: face up, outlined in ink.
class PlacingLifted extends StatelessWidget {
  const PlacingLifted(this.poemId, {super.key, required this.look, required this.showNumber});

  final int poemId;
  final PlacingLook look;
  final bool showNumber;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: look.dragBorder)),
        child: TorifudaCard(poem: poems[poemId], showNumber: showNumber),
      );
}

/// Paper words on an ink tag.
class PlacingTag extends StatelessWidget {
  const PlacingTag(this.text, {super.key, required this.fontSize, required this.look});

  final String text;
  final double fontSize;
  final PlacingLook look;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: look.tagPadding,
          child: Text(text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontWeight: Weights.black, fontSize: fontSize, color: Palette.paper, height: 1.2)),
        ),
      );
}
