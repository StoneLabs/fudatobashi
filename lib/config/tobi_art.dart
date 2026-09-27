import 'dart:ui';

import '../ui/manga/vector.dart';
import 'design.dart';

/// Tobi the mascot, a torifuda with a hachimaki, ported from the spec's SVG
/// symbols (84 × 100 units; arms and effects may reach outside the box).
abstract final class TobiArt {
  static const box = Size(84, 100);

  static const _ink = Palette.ink;
  static const _white = Palette.paper;
  static const _pen = VStyle(stroke: _ink, width: 3, cap: StrokeCap.round, join: StrokeJoin.round);
  static const _open = VStyle(fill: noInk);
  static const _solid = VStyle(fill: _ink, stroke: noInk);
  static const _shine = VStyle(fill: _white, stroke: noInk);
  static const _hand = VStyle(fill: _white);

  static const body = [
    VPath('M33 80 L31 92 M47 80 L49 92', _open),
    VPath('M25 93 H34 M46 93 H55', _open),
    VRect(Rect.fromLTWH(18, 14, 44, 68), radius: 6, style: VStyle(fill: Palette.cardFrame)),
    VRect(Rect.fromLTWH(23.5, 19.5, 33, 57), radius: 2, style: VStyle(fill: Palette.cardPaper, stroke: noInk)),
    VPath('M15 31 L65 26 L65 35 L15 40 Z', VStyle(fill: Palette.pink)),
    VPath('M64 29 Q74 20 80 22 Q76 28 65 32 Z', VStyle(fill: Palette.pink)),
    VPath('M64 32 Q77 33 80 41 Q72 41 64 34 Z', VStyle(fill: Palette.pink)),
  ];

  static const _hipLeft = VPath('M18 53 L10 62 L16 68', _open);
  static const _hipRight = VPath('M62 53 L70 62 L64 68', _open);

  static const _friendlyEyes = [
    VGroup([
      VEllipse(Offset(32.5, 52), 3.2, 4.3, _solid),
      VEllipse.circle(Offset(33.7, 50.3), 1.3, _shine),
    ], tag: VTag.eye),
    VGroup([
      VEllipse(Offset(47.5, 52), 3.2, 4.3, _solid),
      VEllipse.circle(Offset(48.7, 50.3), 1.3, _shine),
    ], tag: VTag.eye),
  ];
  static const _cheeks = [
    VEllipse(Offset(26.5, 60), 3.8, 2.2, VStyle(fill: Palette.pink, stroke: noInk, opacity: 0.8)),
    VEllipse(Offset(53.5, 60), 3.8, 2.2, VStyle(fill: Palette.pink, stroke: noInk, opacity: 0.8)),
  ];

  /// Hands on hips, friendly face.
  static const standard = [
    _hipLeft,
    _hipRight,
    ..._friendlyEyes,
    VPath('M33 61 Q40 70 47 61 Z', VStyle(fill: Palette.pink, width: 2.4)),
    ..._cheeks,
  ];

  /// One arm waving, the other on the hip (onboarding).
  static const waving = [
    VPath('M18 50 L9 33', _open),
    VEllipse.circle(Offset(7.5, 30), 4.2, _hand),
    VPath('M-1 22 Q-4 28 -1 34 M3 16 Q-3 22 -2 28', VStyle(fill: noInk, width: 2)),
    _hipRight,
    ..._friendlyEyes,
    VPath('M33 61 Q40 70 47 61 Z', VStyle(fill: Palette.pink, width: 2.4)),
    ..._cheeks,
  ];

  /// Fist raised, frowning with resolve (the Training hero).
  static const fired = [
    VPath('M18 50 L9 56 L15 64', _open),
    VPath('M62 52 L71 42', _open),
    VEllipse.circle(Offset(73, 39), 4.2, _hand),
    VPath('M27 44 L36 47.5 M53 44 L44 47.5', VStyle(fill: noInk, width: 3.4)),
    VGroup([
      VEllipse(Offset(32.5, 53), 3.2, 4.2, _solid),
      VEllipse.circle(Offset(33.6, 51.4), 1.2, _shine),
    ], tag: VTag.eye),
    VGroup([
      VEllipse(Offset(47.5, 53), 3.2, 4.2, _solid),
      VEllipse.circle(Offset(48.6, 51.4), 1.2, _shine),
    ], tag: VTag.eye),
    VPath('M33 62 Q40 70.5 47 62 Z', VStyle(fill: _ink, width: 2.4)),
  ];

  /// Both arms up, eyes closed with joy.
  static const cheering = [
    VPath('M18 50 L8 37', _open),
    VEllipse.circle(Offset(7, 35), 4, _hand),
    VPath('M62 50 L72 37', _open),
    VEllipse.circle(Offset(73, 35), 4, _hand),
    VPath('M28.5 54 Q32.5 47.5 36.5 54 M43.5 54 Q47.5 47.5 51.5 54', _open),
    VPath('M32 60 Q40 72 48 60 Z', VStyle(fill: _ink, width: 2.4)),
    VEllipse(Offset(27, 61), 4, 2.3, VStyle(fill: Palette.pink, stroke: noInk, opacity: 0.85)),
    VEllipse(Offset(53, 61), 4, 2.3, VStyle(fill: Palette.pink, stroke: noInk, opacity: 0.85)),
  ];

  /// Arm out to the side, pointing at something.
  static const pointing = [
    _hipLeft,
    VPath('M62 50 L76 44', _open),
    VEllipse.circle(Offset(79, 43), 4.2, _hand),
    VPath('M86 35 L90 31 M88 44 L93 44', VStyle(fill: noInk, width: 2.4)),
    ..._friendlyEyes,
    VPath('M33 61 Q40 70 47 61 Z', VStyle(fill: _ink, width: 2.4)),
    ..._cheeks,
  ];

  /// Wide eyes and a sweat drop.
  static const shocked = [
    VPath('M18 52 L6 46', _open),
    VPath('M62 52 L74 46', _open),
    VGroup([
      VEllipse.circle(Offset(32, 52), 5.4, VStyle(fill: _white, width: 2.4)),
      VEllipse.circle(Offset(32, 52.5), 1.6, _solid),
    ], tag: VTag.eye),
    VGroup([
      VEllipse.circle(Offset(48, 52), 5.4, VStyle(fill: _white, width: 2.4)),
      VEllipse.circle(Offset(48, 52.5), 1.6, _solid),
    ], tag: VTag.eye),
    VEllipse(Offset(40, 65), 3.6, 4.6, _solid),
    VPath('M70 10 Q75 18 70 21 Q65 18 70 10 Z', VStyle(fill: _white, width: 2)),
    VPath('M10 14 L14 20 M4 26 L11 28 M40 2 L40 8', VStyle(fill: noInk, width: 2.4)),
  ];

  static VectorArt compose(List<VShape> pose) => VectorArt(box, [
        VGroup([...body, ...pose], style: _pen),
      ]);
}
