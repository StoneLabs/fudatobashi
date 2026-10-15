import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/islands.dart';
import '../islands/island_map.dart';

/// How the islands map sits in its box on journey Home, which the map
/// scrolls in. The map is as wide as the box (or as tall as the clear part
/// of it, in a box too tall for that), with sea above it for the labels laid
/// over its top and sea below it for [overhang], the part of the map that
/// runs on under the strip or banner below the box. Scrolled to either end,
/// the whole map is clear of both.
@immutable
class JourneyPan {
  JourneyPan({required this.box, required this.map, required this.labels, this.overhang = 0});

  /// What the box shows of the map, in dp, and the map in map units.
  final Size box, map;

  /// The height of the sea above the map, under which the labels sit, in dp.
  final double labels;

  /// How far the map runs on below the box, in dp.
  final double overhang;

  /// Map units to dp.
  late final double scale =
      math.max(box.width / map.width, (box.height - labels - JourneyView.bottomGap) / map.height);

  /// The height of the scrolled content, in dp: the map and the sea around it.
  late final double height = labels + map.height * scale + overhang + JourneyView.bottomGap;

  /// The height of the scrolling frame: the box and the overhang under it.
  double get frame => box.height + overhang;

  /// How far the content scrolls: to the map's top edge at the labels' bottom
  /// at 0, and to its bottom edge at the box's bottom at the end.
  double get maxOffset => height - frame;

  /// The part of the map the content shows, in map units: full width unless
  /// the box is too tall for that, and from the top of the sea.
  Rect get viewport =>
      Rect.fromLTWH((map.width - box.width / scale) / 2, -labels / scale, box.width / scale, height / scale);

  /// The boxes to keep in view for the boat sailing into [island], most
  /// wanted first: the island with its plate and the boat, the island and the
  /// boat, then the boat alone.
  static List<Rect> focuses(IslandShape island, Offset boat) {
    final sprite = IslandMap.boatRect(boat);
    final plate = Rect.fromLTRB(
        island.bounds.left, island.bounds.top, island.bounds.right, island.label.dy + JourneyView.plateReach);
    return [plate.expandToInclude(sprite), island.bounds.expandToInclude(sprite), sprite];
  }

  /// The scroll offset that shows the first of [focuses] that fits above the
  /// map's bottom and under the labels, [JourneyView.focus] of the way down
  /// there; the last one, if none does.
  double offsetFor(List<Rect> focuses) {
    final top = labels, bottom = box.height - JourneyView.bottomGap;
    final aim = top + math.max(0.0, bottom - top) * JourneyView.focus;
    var offset = 0.0;
    for (final focus in focuses) {
      final y0 = labels + focus.top * scale, y1 = labels + focus.bottom * scale;
      final lowest = y1 - bottom, highest = y0 - top;
      final fits = lowest <= highest;
      offset = fits ? ((y0 + y1) / 2 - aim).clamp(lowest, highest) : (lowest + highest) / 2;
      if (fits) break;
    }
    return offset.clamp(0.0, maxOffset);
  }

  /// The height the labels over the map's top need clear, from its top.
  static double labelsBottom(TextScaler text) =>
      HomeLayout.mapCountTop +
      HomeLayout.mapCountPadding.vertical +
      2 * Strokes.label +
      text.scale(HomeLayout.mapCountNumber) * HomeLayout.mapCountLine +
      JourneyView.labelsGap;

  @override
  bool operator ==(Object other) =>
      other is JourneyPan &&
      other.box == box &&
      other.map == map &&
      other.labels == labels &&
      other.overhang == overhang;

  @override
  int get hashCode => Object.hash(box, map, labels, overhang);
}

/// Scrolls [child], [height] tall, up and down in the room it is given: a
/// drag pans it, with a short fling, and stops at its ends. It starts at
/// [offset] and moves to it again whenever [offset] changes (the boat has
/// moved, or the box has changed shape); otherwise it stays where it was left.
class PanView extends StatefulWidget {
  const PanView({super.key, required this.height, required this.offset, required this.child});

  final double height;
  final double offset;
  final Widget child;

  @override
  State<PanView> createState() => _PanViewState();
}

class _PanViewState extends State<PanView> {
  late final _controller = ScrollController(initialScrollOffset: widget.offset);

  @override
  void didUpdateWidget(PanView old) {
    super.didUpdateWidget(old);
    if (widget.offset == old.offset) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.jumpTo(widget.offset);
      } else {
        _controller.animateTo(widget.offset, duration: JourneyView.refocus, curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: behavior.copyWith(
        scrollbars: false,
        overscroll: false,
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(height: widget.height, child: widget.child),
      ),
    );
  }
}
