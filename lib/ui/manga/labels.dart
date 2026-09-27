import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'geometry.dart';

/// A small black label with spaced capitals ("BEGINNER · 初心者").
class InkTag extends StatelessWidget {
  const InkTag(
    this.text, {
    super.key,
    this.fontSize = TagStyle.font,
    this.padding = TagStyle.padding,
    this.tracking = TagStyle.tracking,
    this.color = Palette.ink,
    this.textColor = Palette.paper,
  });

  final String text;
  final double fontSize;
  final EdgeInsets padding;
  final double tracking;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: Padding(
          padding: padding,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: Fonts.ui,
              fontWeight: Weights.black,
              fontSize: fontSize,
              letterSpacing: tracking * fontSize,
              color: textColor,
              height: TagStyle.lineHeight,
            ),
          ),
        ),
      );
}

/// A skewed black banner in display lettering ("TRAINING", "JOURNEY 旅").
class InkBanner extends StatelessWidget {
  const InkBanner(this.text, {super.key, this.fontSize = TagStyle.bannerFont});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final skew = Tilt.tagSkew * math.pi / 180;
    return Transform(
      transform: Matrix4.skewX(skew),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: TagStyle.bannerPadding * (fontSize / TagStyle.bannerFont),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.skewX(-skew),
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: fontSize,
                letterSpacing: TagStyle.bannerTracking * fontSize,
                color: Palette.paper,
                height: TagStyle.bannerLineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slightly tilted coloured sticker with an ink border.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.child,
    this.color = Palette.sun,
    this.tilt = Tilt.sticker,
    this.padding = StickerStyle.padding,
    this.border = Strokes.control,
  });

  final Widget child;
  final Color color;

  /// Degrees.
  final double tilt;
  final EdgeInsets padding;
  final double border;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, border: Border.all(color: Palette.ink, width: border)),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// A round count badge (the 苦手 count).
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color = Palette.pink});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: StickerStyle.badgeSize, minHeight: StickerStyle.badgeSize),
        padding: const EdgeInsets.symmetric(horizontal: StickerStyle.badgePadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Palette.ink, width: Strokes.control),
          borderRadius: BorderRadius.circular(StickerStyle.badgeSize / 2),
        ),
        child: Text(
          '$count',
          style: const TextStyle(fontFamily: Fonts.display, fontSize: StickerStyle.badgeFont, height: 1),
        ),
      );
}

/// A bordered pill label ("友札 いまこ・いまは").
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = Palette.paper});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: color, border: Border.all(color: Palette.ink, width: Strokes.label)),
        child: Padding(
          padding: PillStyle.padding,
          child: Text(
            text,
            softWrap: false,
            style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.small, height: PillStyle.lineHeight),
          ),
        ),
      );
}

/// A narration box: white with a thin ink border, like a manga caption.
class NarrationBox extends StatelessWidget {
  const NarrationBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.paper,
          border: Border.all(color: Palette.ink, width: Strokes.label),
        ),
        child: Padding(
          padding: NarrationStyle.padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: NarrationStyle.font,
              fontWeight: Weights.bold,
              height: NarrationStyle.lineHeight,
              color: Palette.ink,
            ),
            child: child,
          ),
        ),
      );
}

/// A box with a dashed ink border.
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.color = Palette.paper,
    this.border = Strokes.control,
    this.dash = Strokes.dash,
    this.radius = 0,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double border;
  final List<double> dash;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedPainter(color, border, dash, radius),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.border, this.dash, this.radius);
  final Color color;
  final double border;
  final List<double> dash;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(border / 2), Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawPath(
      Dashes.of(Path()..addRRect(rrect), dash),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.border != border || old.dash != dash || old.radius != radius;
}
