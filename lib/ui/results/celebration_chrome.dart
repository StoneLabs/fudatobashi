import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../manga/manga.dart';

/// Full-screen page shared by every celebration: a colour, full-bleed art
/// and [backdrop] behind the safe area, and tap-anywhere-to-continue. A
/// [cta] adds the primary button pinned to the bottom; without one the page
/// lays out its own actions in [child].
class CelebrationChrome extends StatelessWidget {
  const CelebrationChrome({
    super.key,
    required this.color,
    required this.onNext,
    required this.child,
    this.cta,
    this.art = const [],
    this.backdrop = const [],
  });

  final Color color;
  final VoidCallback onNext;
  final Widget child;
  final String? cta;
  final List<ArtLayer> art;
  final List<Widget> backdrop;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onNext,
        child: ColoredBox(
          color: color,
          child: Stack(fit: StackFit.expand, children: [
            if (art.isNotEmpty) StaticArt(art),
            ...backdrop,
            SafeArea(
              child: Stack(fit: StackFit.expand, children: [
                child,
                if (cta != null)
                  Positioned(
                    left: Gaps.gutter,
                    right: Gaps.gutter,
                    bottom: Gaps.section,
                    child: SizedBox(
                      height: PlayLayout.buttonRowHeight,
                      child: InkButton(
                        color: Palette.pink,
                        onTap: onNext,
                        child: Text(cta!, style: const TextStyle(fontFamily: Fonts.display, fontSize: TypeScale.title)),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      );
}

/// A soft radial flash of light, [size] across, centred at [at] of the page
/// (it may spill past the edges).
class CelebrationGlow extends StatelessWidget {
  const CelebrationGlow({super.key, required this.at, required this.size, required this.colors, required this.stops});

  final Alignment at;
  final double size;
  final List<Color> colors;
  final List<double> stops;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: at,
          child: OverflowBox(
            maxWidth: size,
            maxHeight: size,
            child: SizedBox.square(
              dimension: size,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RadialGradient(radius: 0.5, colors: colors, stops: stops)),
              ),
            ),
          ),
        ),
      );
}

/// The celebration's primary button: display lettering, with the same call
/// in the other language underneath.
class CelebrationCta extends StatelessWidget {
  const CelebrationCta({
    super.key,
    required this.label,
    required this.sub,
    required this.onTap,
    required this.height,
    required this.fontSize,
    required this.subFontSize,
  });

  final String label;
  final String sub;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final double subFontSize;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: InkButton(
          color: Palette.pink,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.small),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              Text(label, style: TextStyle(fontFamily: Fonts.display, fontSize: fontSize, height: 1)),
              const SizedBox(width: Gaps.small),
              Text(sub, style: TextStyle(fontWeight: Weights.black, fontSize: subFontSize, height: 1)),
            ]),
          ),
        ),
      );
}

/// A tilted ink band with sun lettering across the page (ISLAND COMPLETE,
/// RANK UP), [inset] from both sides.
class CelebrationBand extends StatelessWidget {
  const CelebrationBand(
    this.text, {
    super.key,
    required this.inset,
    required this.fontSize,
    required this.tracking,
    required this.padding,
    required this.turnDeg,
  });

  final String text;
  final double inset;
  final double fontSize;

  /// Letter spacing as a share of [fontSize].
  final double tracking;
  final EdgeInsets padding;
  final double turnDeg;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: Transform.rotate(
          angle: turnDeg * math.pi / 180,
          child: ColoredBox(
            color: Palette.ink,
            child: Padding(
              padding: padding,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text,
                    style: TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: fontSize,
                        letterSpacing: tracking * fontSize,
                        color: Palette.sun,
                        height: 1.1)),
              ),
            ),
          ),
        ),
      );
}
