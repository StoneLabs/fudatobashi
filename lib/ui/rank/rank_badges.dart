import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../manga/manga.dart';

/// Fill, texture and text colour for one class, a step of the ladder's
/// colour progression: flat white for 入門/F下級, then pink, yellow, green, a
/// lighter and then a bolder sea, a bold violet and finally solid ink.
({Color color, ToneSpec? tone, Color text}) rungStyle(String bandId) => switch (bandId) {
      'F+' => (color: Palette.pink, tone: Tones.pink, text: Palette.ink),
      'E-' => (color: Palette.sun, tone: null, text: Palette.ink),
      'E+' => (color: Palette.land, tone: null, text: Palette.ink),
      'D' => (color: Palette.seaSoft, tone: Tones.sea, text: Palette.ink),
      'C' => (color: Palette.sea, tone: Tones.seaDeep, text: Palette.ink),
      'B' => (color: Palette.violet, tone: null, text: Palette.paper),
      'A' => (color: Palette.ink, tone: null, text: Palette.paper),
      _ => (color: Palette.paper, tone: null, text: Palette.ink), // 入門, F下級
    };

/// A class badge, "F上" big and "級" small (spec's `.rn`, skew art aside —
/// see [Sticker]).
class ClassBadge extends StatelessWidget {
  const ClassBadge(
    this.band, {
    super.key,
    this.color = Palette.paper,
    this.textColor = Palette.ink,
    this.fontSize = RankLayout.badgeFont,
    this.suffixSize = RankLayout.badgeSuffixFont,
    this.padding = RankLayout.badgePadding,
    this.border = Strokes.control,
  });

  final RankBand band;
  final Color color, textColor;
  final double fontSize, suffixSize;
  final EdgeInsets padding;
  final double border;

  @override
  Widget build(BuildContext context) {
    const suffix = '級';
    final main = band.label.endsWith(suffix) ? band.label.substring(0, band.label.length - 1) : band.label;
    return Sticker(
      tilt: 0,
      color: color,
      padding: padding,
      border: border,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: main, style: TextStyle(fontSize: fontSize)),
          if (main != band.label) TextSpan(text: suffix, style: TextStyle(fontSize: suffixSize)),
        ]),
        style: TextStyle(fontFamily: Fonts.display, height: 1, color: textColor),
      ),
    );
  }
}

/// A rotated, pink-outlined stamp on every class already passed (spec's
/// `.stamp`).
class ClearStamp extends StatelessWidget {
  const ClearStamp(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: RankLayout.stampTurn * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper.withValues(alpha: 0.85),
            border: Border.all(color: Palette.pinkDeep, width: Strokes.button),
            borderRadius: BorderRadius.circular(RankLayout.stampRadius),
          ),
          child: Padding(
            padding: RankLayout.stampPadding,
            child: Text(label,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.stampFont, color: Palette.pinkDeep)),
          ),
        ),
      );
}
