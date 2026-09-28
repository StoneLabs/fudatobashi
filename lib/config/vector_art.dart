import 'dart:ui';

import '../ui/manga/art_image.dart';
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
  static const lock = VectorArt(_box, [VPath('M6 11h12v9H6ZM8.5 11V8a3.5 3.5 0 0 1 7 0v3M12 14.5v2', _line)]);
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
  static const _foam = VStyle(fill: Palette.paper, stroke: _ink, width: 2, join: StrokeJoin.round);
  static const _mapTree = VStyle(fill: MapStyle.tree, stroke: _ink, width: 1.6);
  static const _mapTreeShine = VStyle(fill: MapStyle.treeHighlight);
  static const _isleBank = 'M20 32 C 8 36, 8 46, 32 48 C 64 52, 116 52, 136 47 C 152 43, 156 33, 146 26Z';

  /// Tobi's island in the welcome panel, seen from the side: the map's land
  /// with a wooded hill, on a sand bank in the map's white surf, and the
  /// map's flag. Tobi stands on the flat at about (76, 30).
  static const welcomeIsle = VectorArt(Size(160, 68), origin: Offset(0, -8), [
    VPath('M4 50 C 20 60, 140 60, 156 50', _wave),
    VPath(_isleBank, VStyle(stroke: Palette.paper, width: MapStyle.surf, join: StrokeJoin.round)),
    VPath(_isleBank, VStyle(tone: Tones.sun, stroke: _ink, width: 2.6, join: StrokeJoin.round)),
    VPath('M14 33 C 14 27, 32 22, 52 22 C 72 19, 94 19, 104 20 C 110 10, 124 5, 136 9 C 146 12, 152 22, 148 32 '
        'C 146 39, 124 41, 100 40 C 76 42, 40 42, 26 39 C 18 38, 14 36, 14 33Z',
        VStyle(tone: Tones.mapLand, stroke: _ink, width: 2.6, join: StrokeJoin.round)),
    VPath('M121 8 V14 M140 11 V17', VStyle(stroke: _ink, width: 1.8, cap: StrokeCap.round)),
    VEllipse.circle(Offset(131, 0), 5.5, _mapTree),
    VEllipse.circle(Offset(129.2, -1.8), 1.6, _mapTreeShine),
    VEllipse.circle(Offset(121, 2), 6.8, _mapTree),
    VEllipse.circle(Offset(118.7, -0.3), 2.1, _mapTreeShine),
    VEllipse.circle(Offset(140, 7), 4.2, _mapTree),
    VEllipse.circle(Offset(138.6, 5.6), 1.3, _mapTreeShine),
    VUse(MapArt.flag, Rect.fromLTWH(20, 5, 16, 22)),
  ]);

  /// A far island on the horizon, not reached yet (the map's unexplored
  /// look); its base sits on the box's bottom edge.
  static const farIsle = VectorArt(Size(44, 12), [
    VPath('M1 12 C 4 8, 10 7, 14 7 C 18 2, 26 1, 30 5 C 34 5, 40 7, 43 12Z',
        VStyle(tone: Tones.land, stroke: _ink, width: 1.6, dash: [4, 3], join: StrokeJoin.round)),
  ]);

  /// White water around a boat's hull, which sits on the box's middle.
  static const boatWake = VectorArt(Size(48, 9), [
    VPath('M0 4 q4 -3 8 0 M40 4 q4 -3 8 0 M8 6 C 16 9, 32 9, 40 6', _wave),
  ]);

  static const _surfTop = 'M0 30 C 18 30, 32 24, 44 14 C 54 5, 68 3, 76 9 C 82 14, 82 22, 78 26 '
      'C 82 29, 90 32, 100 32 C 112 32, 122 28, 130 22 C 136 17, 146 16, 150 20 C 154 23, 153 28, 150 29 '
      'C 156 31, 170 30, 180 30';

  /// The welcome panel's front surf, tiled edge to edge: a big and a small
  /// deep-sea crest curling over to the right under foam caps.
  static const surf = VectorArt(Size(180, 64), [
    VPath('$_surfTop V64 H0Z', VStyle(tone: Tones.seaDeep)),
    VPath(_surfTop, VStyle(stroke: _ink, width: 2.6, cap: StrokeCap.round, join: StrokeJoin.round)),
    VPath('M40 17 C 50 7, 66 3, 76 9 C 82 14, 82 22, 78 26 Q 74 22, 72 25 Q 70 18, 65 20 Q 62 13, 57 16 '
        'Q 52 12, 47 17 Q 43 16, 40 17Z', _foam),
    VPath('M127 24 C 135 18, 146 15, 150 20 C 154 23, 153 28, 150 29 Q 148 25, 146 27 Q 144 21, 140 23 '
        'Q 136 19, 132 23 Q 130 22, 127 24Z', _foam),
    VEllipse.circle(Offset(86, 5), 2.1, _foam),
    VEllipse.circle(Offset(91.5, 9), 1.5, _foam),
    VEllipse.circle(Offset(94, 14.5), 1, _foam),
    VPath('M8 44 C 22 44, 34 40, 44 32 M52 50 C 64 50, 74 46, 82 40 M112 44 C 124 44, 132 40, 140 34 '
        'M18 58 q6 -4 12 0 M146 54 q6 -4 12 0', _wave),
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

/// Art shown from pre-rendered images (see [ArtImage]): the map's boat and
/// the onboarding scenes. Tobi stays live.
abstract final class PrerenderedArt {
  static const boat = ArtImage('boat', MapArt.boat);
  static const beginner = ArtImage('beginner', SceneArt.beginner);
  static const expert = ArtImage('expert', SceneArt.expert);

  static const all = [boat, beginner, expert];
}
