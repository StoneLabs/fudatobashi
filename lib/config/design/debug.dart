part of '../design.dart';

/// The debug Simulation page's summary and per-day charts.
abstract final class SimulationStyle {
  static const double labelWidth = 150;
  static const double chartHeight = 110;
  static const double chartGap = 20;
  static const double legendGap = 12;
  static const double swatch = 10;
}

/// The developer's 暗記練 tools page (`AnkirenToolsPage`): its charts and
/// spacing.
abstract final class AnkirenToolsStyle {
  static const double chartHeight = 120;
  static const double curveStroke = 2;
  static const double markerStroke = 1.5;
  static const double targetRadius = 3;
  static const double gap = 8;

  /// The total-points graph: its height, the margins that hold the axis
  /// labels, and the lines' stroke and label size.
  static const double graphHeight = 240;
  static const EdgeInsets graphMargin = EdgeInsets.fromLTRB(44, 8, 30, 18);
  static const double lineStroke = 1.5;
  static const double axisFont = 10;

  /// Between an axis, or a line's end, and its label.
  static const double axisLabelGap = 3;

  /// A class border's dashed line and its label at the plot's right edge;
  /// labels closer than [classLabelHeight] are pushed apart.
  static const double classStroke = 1;
  static const double classDash = 4;
  static const double classDashGap = 3;
  static const double classLabelHeight = 10;
  static const double classOpacity = 0.7;
}

/// The developer's 暗記練 test game (`AnkirenDebugGame`): its debug bar and
/// the debug layer over the field, drawn like Flutter's own debug paint:
/// hairlines and small monospace labels in high-contrast colours.
abstract final class AnkirenDebugStyle {
  static const String mono = 'monospace';
  static const double barFont = 11;
  static const double labelFont = 9;
  static const Color barBackground = Color(0xFF101010);
  static const Color barText = Color(0xFFE6E6E6);
  static const Color barMute = Color(0xFF8A8A8A);
  static const Color chipOn = Color(0xFF00E5FF);
  static const Color chipOnText = Color(0xFF000000);
  static const double chipMinWidth = 26;
  static const double chipHeight = 28;
  static const double chipGap = 3;
  static const double chipRadius = 3;
  static const double chipBorder = 1;
  static const EdgeInsets barPadding = EdgeInsets.fromLTRB(6, 4, 6, 6);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 6);
  static const double rowGap = 4;

  /// The layer's strokes: each half, each row's band, the open middle
  /// between the clusters, a middle card's lines to its 友札, and the card
  /// asked for.
  static const Color half = Color(0xFF00E5FF);
  static const Color row = Color(0xFFFFB300);
  static const Color middle = Color(0xFFFF2BD6);
  static const double middleFillOpacity = 0.14;
  static const Color tomofuda = Color(0xFFFF2BD6);
  static const Color asked = Color(0xFFFFF200);
  static const double hairline = 1;
  static const double strong = 2;
  static const double dot = 3;

  /// A card's solution (its kimariji) on a dark chip.
  static const Color labelBackground = Color(0xDD000000);
  static const Color labelText = Color(0xFFFFFFFF);
  static const EdgeInsets labelPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 1);
}
