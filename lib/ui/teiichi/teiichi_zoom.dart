import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../ankiren/ankiren_field_view.dart';

/// How far 定位置's field grows once the layout is fixed, for play.
///
/// The field grows evenly: the bottom row stays on the bottom edge, the
/// clusters on the edges they start from, so cards grow upward and inward
/// and each row's gap between its clusters closes. It stops at the first of
/// three limits: the band reaching the top of the area, a row without
/// middle cards keeping [TeiichiPlayLayout.zoomGap] card widths between its
/// clusters, and a row with middle cards keeping
/// [TeiichiPlayLayout.zoomMiddleGap] between a cluster and its middle
/// cards. It never shrinks.
abstract final class TeiichiZoom {
  /// The scale factor, at least 1, for [field]'s own side on a screen with
  /// [area] to play in (inside its padding) and a band [band] tall.
  static double limit(AnkirenField field, Size area, double band) {
    final geometry = FieldGeometry.of(field, folded: false, trueSlots: TeiichiTuning.rowSlots);
    final scale = AnkirenFieldView.scaleFor(geometry, area,
        landscape: true, zoom: false, band: band, roomAbove: TeiichiPlayLayout.roomAbove);
    var zoom = (area.height - band) / (geometry.height * scale);
    for (final row in field.own.rows) {
      if (!row.isEmpty) zoom = math.min(zoom, _rowLimit(row, geometry.width));
    }
    return math.max(1, zoom);
  }

  /// How far [row], [width] cm across, can grow before its clusters are
  /// too near (to each other, or to its middle cards). Growing by z leaves
  /// the cards as they are and the row z times narrower, in centimetres.
  static double _rowLimit(AnkirenRow row, double width) {
    const cardW = AnkirenFieldSize.cardW;
    const cardGap = AnkirenFieldSize.cardGap;
    final clusters = (row.left.length + row.right.length) * FieldGeometry.pitch;
    if (row.middle.isEmpty) {
      return width / (TeiichiPlayLayout.zoomGap * cardW - 2 * cardGap + clusters);
    }
    // The middle cards' share of the gap, each side of a card half a card
    // plus the free space.
    final between = (row.middle.length + 1) * ((TeiichiPlayLayout.zoomMiddleGap + 0.5) * cardW - cardGap);
    return width / (clusters + between);
  }
}
