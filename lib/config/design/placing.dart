part of '../design.dart';

/// How a side looks while it is laid out (`lib/ui/placing/`); each screen
/// that lays out a side gives its own. dp.
class PlacingLook {
  const PlacingLook({
    required this.spotInk,
    required this.spotFill,
    required this.spotBorder,
    required this.middleLabelFont,
    required this.middleLabelTracking,
    required this.middleLabelRoom,
    required this.landingFill,
    required this.landingBorder,
    required this.landingTagFont,
    required this.landingTagGap,
    required this.landingTagRoom,
    required this.landingTagFlip,
    required this.dragLift,
    required this.dragScale,
    required this.dragLeastWidth,
    required this.dragBorder,
    required this.stackDepth,
    required this.stackStep,
    required this.stackTagOverlap,
    required this.stackTagRoom,
    required this.stackTagFont,
    required this.tagPadding,
    required this.edgeFill,
    required this.edgeInk,
    required this.edgeBorder,
  });

  /// A dashed spot on the tatami, and the open middle's label in it, shown
  /// only in a stretch clear of cards at least [middleLabelRoom] wide.
  final Color spotInk;
  final Color spotFill;
  final double spotBorder;
  final double middleLabelFont;
  final double middleLabelTracking;
  final double middleLabelRoom;

  /// Where a dragged card would land: [landingFill] over its spot, outlined
  /// in ink, and its name on an ink tag beside the card, [landingTagGap]
  /// from it and [landingTagRoom] tall: left of it, or right of it while
  /// its left edge is within [landingTagFlip] of the area's left (or of
  /// half the area's width).
  final Color landingFill;
  final double landingBorder;
  final double landingTagFont;
  final double landingTagGap;
  final double landingTagRoom;
  final double landingTagFlip;

  /// A dragged card rides above the finger, its foot [dragLift] of its
  /// height up so the finger never hides it, [dragScale] times the field's
  /// cards and at least [dragLeastWidth] wide, with an ink outline.
  final double dragLift;
  final double dragScale;
  final double dragLeastWidth;
  final double dragBorder;

  /// The stack: its top card over [stackDepth] cards' edges at most,
  /// [stackStep] apart, over a tag that overlaps the card's foot by
  /// [stackTagOverlap]; ink tags are padded by [tagPadding].
  final int stackDepth;
  final double stackStep;
  final double stackTagOverlap;
  final double stackTagRoom;
  final double stackTagFont;
  final EdgeInsets tagPadding;

  /// The edge of a card under the stack's top one.
  final Color edgeFill;
  final Color edgeInk;
  final double edgeBorder;
}
