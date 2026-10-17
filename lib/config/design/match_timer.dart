part of '../design.dart';

/// The match timer (`MatchTimerScreen`): a dial over its buttons, together
/// on a dotted desk panel.
abstract final class MatchTimerLayout {
  /// The desk panel: the About card's dotted desk under an ink border and
  /// hard shadow.
  static const ToneSpec panelTone = AboutCardLayout.panelTone;
  static const double panelShadow = AboutCardLayout.panelShadow;
  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(14, 14, 14, 22);

  /// The dial: the ring, its ticks outside it, and the paper face inside.
  static const double dialSize = 304;
  static const double ringStroke = 24;
  static const double ringOutline = Strokes.control;
  static const double startLine = Strokes.control;
  static const Color track = Palette.desk;
  static const Color ringNormal = Palette.sea;
  static const Color ringWarn = Palette.alarm;

  /// A tick every minute, a major one every [majorEvery].
  static const int majorEvery = 5;
  static const double tickGap = 4;
  static const double minorTick = 7;
  static const double majorTick = 12;
  static const double minorTickWidth = Strokes.label;
  static const double majorTickWidth = Strokes.panel;

  static const double timeFont = 52;
  static const double penSize = 22;
  static const double penGap = 6;

  static const double buttonGap = 14;
  static const double buttonHeight = 60;
  static const double buttonWidth = 140;
  static const double buttonFont = 20;
  static const double sectionGap = 16;

  /// The set-time and notification sheets.
  static const Color sheetBarrier = Color(0x8C141414);
  static const EdgeInsets sheetPadding = EdgeInsets.all(20);
  static const double sheetTitle = 24;
  static const double sheetGap = 16;
  static const double sheetBody = 15;
  static const double sheetLineHeight = 1.45;
  static const double fieldWidth = 96;
  static const double fieldFont = 36;
  static const double fieldLabelFont = 13;
  static const double fieldBorder = Strokes.button;
  static const double colonFont = 36;
}
