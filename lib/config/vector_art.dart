import 'dart:ui';

import '../ui/manga/vector.dart';
import 'design.dart';

/// Vector art ported from the spec's inline SVG, in each SVG's own units.

const _ink = Palette.ink;
const _line = VStyle(stroke: currentInk, cap: StrokeCap.round, join: StrokeJoin.round);

/// Stroked UI icons (24-unit box unless noted), drawn in the current colour.
abstract final class IconArt {
  static const _box = Size(24, 24);

  static const home = VectorArt(_box, [VPath('M3.5 11 12 4l8.5 7M6 9.5V20h12V9.5M10 20v-5h4v5', _line)]);
  static const history = VectorArt(_box, [
    VEllipse.circle(Offset(12, 12), 8.5, _line),
    VPath('M12 7.5V12l3.2 2', _line),
  ]);
  static const stats = VectorArt(_box, [VPath('M4 20h16M6.5 20v-6M11 20V6M15.5 20v-9M20 20V9', _line)]);
  static const help = VectorArt(_box, [
    VPath('M4 11.5C4 7 7.6 4 12 4s8 3 8 7.5S16.4 19 12 19c-1 0-2-.1-2.9-.4L5 20.5l1.2-3.3C4.8 15.8 4 13.8 4 11.5Z',
        _line),
    VPath('M10 9.4a2.1 2.1 0 1 1 3 1.9c-.6.3-1 .8-1 1.5M12 15.2v.1', _line),
  ]);
  static const settings = VectorArt(_box, [
    VEllipse.circle(
        Offset(12, 12), 7.4, VStyle(stroke: currentInk, width: 3.6, dash: [3.1, 2.7], cap: StrokeCap.butt)),
    VEllipse.circle(Offset(12, 12), 4.6, _line),
    VEllipse.circle(Offset(12, 12), 1.2, VStyle(fill: currentInk)),
  ]);
  static const arrow = VectorArt(_box, [VPath('M4 12h15M13 6l6 6-6 6', _line)]);
  static const chevron = VectorArt(_box, [VPath('M9 5l7 7-7 7', _line)]);
  static const back = VectorArt(_box, [VPath('M15 5l-7 7 7 7', _line)]);
  static const close = VectorArt(_box, [VPath('M6 6l12 12M18 6 6 18', _line)]);
  static const undo = VectorArt(_box, [VPath('M8 5 4 9l4 4M4 9h10a5.5 5.5 0 0 1 0 11h-4', _line)]);
  static const end = VectorArt(_box, [VPath('M6 21V4M6 4h11l-2.4 4.2L17 12.5H6', _line)]);
  static const question = VectorArt(_box, [VPath('M8.5 8.8a3.5 3.5 0 1 1 5.1 3.1c-1 .5-1.6 1.3-1.6 2.4v.7M12 19v.1', _line)]);
  static const refresh = VectorArt(_box, [VPath('M20 12a8 8 0 1 1-2.3-5.6M20 4v4.5h-4.5', _line)]);
  static const person = VectorArt(_box, [
    VEllipse.circle(Offset(12, 8), 3.6, _line),
    VPath('M4.5 20c.8-4 3.8-6 7.5-6s6.7 2 7.5 6', _line),
  ]);

  /// Two cards fanned (free play), 34-unit box.
  static const cards = VectorArt(Size(34, 34), [
    VGroup([
      VRect(Rect.fromLTWH(5, 7, 14, 20), radius: 1.5, style: VStyle(fill: Palette.paper)),
    ], style: _line, rotate: -12, pivot: Offset(12, 17)),
    VGroup([
      VRect(Rect.fromLTWH(14, 6, 14, 20), radius: 1.5, style: VStyle(fill: Palette.paper)),
    ], style: _line, rotate: 10, pivot: Offset(21, 16)),
  ]);
}

/// Map furniture.
abstract final class MapArt {
  static const boat = VectorArt(Size(40, 36), [
    VPath('M3 24 H37 L31 33 H9 Z', VStyle(fill: Palette.paper, stroke: _ink, width: 2.4, join: StrokeJoin.round)),
    VPath('M20 24 V3', VStyle(stroke: _ink, width: 2.4)),
    VPath('M21.5 4 L34 20 H21.5 Z', VStyle(fill: Palette.pink, stroke: _ink, width: 2, join: StrokeJoin.round)),
    VPath('M18.5 8 L8 20 H18.5 Z', VStyle(fill: Palette.sun, stroke: _ink, width: 2, join: StrokeJoin.round)),
  ]);

  static const flag = VectorArt(Size(16, 22), [
    VPath('M2.5 21 V2', VStyle(stroke: _ink, width: 2, cap: StrokeCap.round)),
    VPath('M3.5 2.3 L15 6.5 L3.5 10.7Z', VStyle(fill: Palette.pink, stroke: _ink, width: 1.5, join: StrokeJoin.round)),
  ]);

  static const star = VectorArt(Size(12, 12), [
    VPath('M6 .5l1.6 3.6 3.9.4-2.9 2.6.9 3.9L6 9 2.5 11l.9-3.9L.5 4.5l3.9-.4z',
        VStyle(fill: Palette.sun, stroke: _ink, width: 1.1)),
  ]);
}

/// Onboarding illustrations.
abstract final class SceneArt {
  static const _wave = VStyle(stroke: Palette.paper, width: 2, cap: StrokeCap.round, opacity: 0.85);

  /// The sea along the bottom of the welcome panel, with Tobi's island.
  static const welcomeSea = VectorArt(Size(352, 120), [
    VPath('M0 44 Q22 36 44 44 T88 44 T132 44 T176 44 T220 44 T264 44 T308 44 T352 44 V120 H0Z',
        VStyle(tone: Tones.mapSea, stroke: _ink, width: 2.6)),
    VPath('M18 40 C 24 22, 60 14, 92 17 C 124 14, 158 24, 162 40 C 150 50, 36 52, 18 40Z',
        VStyle(fill: Palette.paper, opacity: 0.9)),
    VPath('M24 38 C 30 24, 62 18, 92 21 C 122 18, 150 26, 155 38 C 140 46, 40 47, 24 38Z',
        VStyle(tone: Tones.mapLand, stroke: _ink, width: 2.6)),
    VPath('M232 60 q6 -6 12 0 t12 0 M286 82 q6 -6 12 0 t12 0 M196 92 q6 -6 12 0 t12 0 M300 56 q5 -5 10 0', _wave),
    VPath('M238 34 C 244 24, 270 20, 290 24 C 306 24, 318 30, 318 38 C 300 44, 250 44, 238 34Z',
        VStyle(tone: Tones.mapShoal, stroke: _ink, width: 1.8, dash: [4, 3])),
  ]);

  static const _islet = 'M22 72 C 14 54, 28 34, 50 38 C 70 28, 92 46, 86 64 C 92 84, 62 92, 48 86 C 32 92, 18 84, 22 72Z';
  static const _tree = VStyle(fill: Palette.landDeep, stroke: _ink, width: 1.4);

  /// "I'm new": an island with a flag in a round sea.
  static const beginner = VectorArt(Size(108, 108), [
    VEllipse.circle(Offset(54, 56), 50, VStyle(tone: Tones.mapSea, stroke: _ink, width: 2.6)),
    VPath(_islet, VStyle(stroke: Palette.paper, width: 8, join: StrokeJoin.round)),
    VPath(_islet, VStyle(tone: Tones.mapLand, stroke: _ink, width: 2.6)),
    VEllipse.circle(Offset(40, 70), 5, _tree),
    VEllipse.circle(Offset(56, 74), 5, _tree),
    VEllipse.circle(Offset(70, 62), 5, VStyle(stroke: _ink, width: 1.6, dash: [3, 2.4])),
    VUse(MapArt.flag, Rect.fromLTWH(44, 28, 22, 30)),
  ]);

  static const _card = VStyle(stroke: _ink, width: 2.4, join: StrokeJoin.round);

  /// "I know all 100": a fanned deck with a 100 badge.
  static const expert = VectorArt(Size(108, 108), [
    VGroup([
      VRect(Rect.fromLTWH(30, 26, 38, 54), radius: 3, style: VStyle(fill: Palette.cardFrame)),
      VRect(Rect.fromLTWH(35, 31, 28, 44), style: VStyle(fill: Palette.cardPaper, stroke: noInk)),
    ], style: _card, rotate: -16, pivot: Offset(54, 70)),
    VGroup([
      VRect(Rect.fromLTWH(36, 22, 38, 54), radius: 3, style: VStyle(fill: Palette.cardFrame)),
      VRect(Rect.fromLTWH(41, 27, 28, 44), style: VStyle(fill: Palette.cardPaper, stroke: noInk)),
    ], style: _card, rotate: 4, pivot: Offset(54, 70)),
    VGroup([
      VRect(Rect.fromLTWH(42, 20, 38, 54), radius: 3, style: VStyle(fill: Palette.cardFrame)),
      VRect(Rect.fromLTWH(47, 25, 28, 44), style: VStyle(fill: Palette.cardPaper, stroke: noInk)),
    ], style: _card, rotate: 20, pivot: Offset(54, 70)),
    VPath('M12 16 L22 22 M8 32 L19 33 M22 6 L27 16', VStyle(stroke: _ink, width: 2.6, cap: StrokeCap.round)),
    VEllipse.circle(Offset(30, 82), 19, VStyle(fill: Palette.pink, stroke: _ink, width: 2.6)),
    VText('100', Offset(30, 88), size: 17, family: Fonts.display, color: _ink),
  ]);
}
