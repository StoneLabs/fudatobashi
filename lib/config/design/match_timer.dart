part of '../design.dart';

/// The match timer (`MatchTimerScreen`): a ring that empties
/// counter-clockwise round the time, the buttons under it.
abstract final class MatchTimerLayout {
  static const double ringSize = 280;
  static const double ringStroke = 22;
  static const Color track = Palette.desk;
  static const Color ringNormal = Palette.sea;
  static const Color ringWarn = Palette.alarm;

  static const double timeFont = 46;
  static const double penSize = 22;
  static const double penGap = 6;

  static const double buttonGap = 14;
  static const double buttonHeight = 60;
  static const double buttonWidth = 140;
  static const double buttonFont = 20;
  static const double sectionGap = 36;

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
