import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import 'pressable.dart';
import 'screentone.dart';
import 'vector.dart';

/// A stroked icon from [IconArt].
class MangaIcon extends StatelessWidget {
  const MangaIcon(
    this.art, {
    super.key,
    this.size = ButtonMetrics.icon,
    this.color = Palette.ink,
    this.strokeWidth = ButtonMetrics.iconStroke,
  });

  final VectorArt art;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) =>
      VectorArtBox(art, size: Size.square(size), color: color, base: VStyle(width: strokeWidth));
}

/// The manga button: an ink-bordered box that stamps when pressed (drops,
/// tilts, thickens its border and flashes a screentone).
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.onTap,
    required this.child,
    this.color = Palette.paper,
    this.border = Strokes.button,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final double border;
  final EdgeInsets padding;
  final AlignmentGeometry alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: ColoredBox(color: color)),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: pressed ? Tones.stampOpacity : 0,
              duration: Motion.stampFade,
              child: const ToneBox(Tones.stamp),
            ),
          ),
          Container(
            padding: padding,
            alignment: alignment,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: Palette.ink, width: pressed ? border + Strokes.pressed : border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A square icon button (the settings gear).
class InkIconButton extends StatelessWidget {
  const InkIconButton({super.key, required this.icon, required this.onTap, this.semanticLabel});

  final VectorArt icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: ButtonMetrics.iconButton,
        child: InkButton(
          onTap: onTap,
          border: Strokes.control,
          semanticLabel: semanticLabel,
          child: MangaIcon(icon),
        ),
      );
}

/// A round pink "go" button with an arrow.
class GoButton extends StatelessWidget {
  const GoButton({super.key, this.color = Palette.pink});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: ButtonMetrics.goButton,
        height: ButtonMetrics.goButton,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.ink, width: Strokes.button),
        ),
        child: const MangaIcon(IconArt.arrow, size: ButtonMetrics.goIcon, strokeWidth: ButtonMetrics.goIconStroke),
      );
}
