import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'geometry.dart';
import 'screentone.dart';
import 'static_art.dart';

/// The outline of a manga panel: a rectangle whose corners may be pulled
/// inward (a cut or tilted edge). Each corner offset moves that corner toward
/// the inside of the box: `dx` horizontally, `dy` vertically.
@immutable
class PanelShape {
  const PanelShape({
    this.topLeft = Offset.zero,
    this.topRight = Offset.zero,
    this.bottomRight = Offset.zero,
    this.bottomLeft = Offset.zero,
  });

  static const rect = PanelShape();

  final Offset topLeft, topRight, bottomRight, bottomLeft;

  List<Offset> corners(Size s) => [
        topLeft,
        Offset(s.width - topRight.dx, topRight.dy),
        Offset(s.width - bottomRight.dx, s.height - bottomRight.dy),
        Offset(bottomLeft.dx, s.height - bottomLeft.dy),
      ];

  Path outer(Size s) => Polygon.path(corners(s));

  Path inner(Size s, double border) => Polygon.path(Polygon.inset(corners(s), border));

  @override
  bool operator ==(Object other) =>
      other is PanelShape &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);
}

/// A manga panel: an ink border around a paper, colour, screentone or
/// layered-art fill. The child is clipped to the inside of the border.
class MangaPanel extends StatelessWidget {
  const MangaPanel({
    super.key,
    this.shape = PanelShape.rect,
    this.border = Strokes.panel,
    this.color = Palette.paper,
    this.tone,
    this.art = const [],
    this.padding = EdgeInsets.zero,
    this.child,
  });

  final PanelShape shape;
  final double border;
  final Color color;
  final ToneSpec? tone;

  /// Static background layers drawn above [color]/[tone], cached as a bitmap.
  final List<ArtLayer> art;
  final EdgeInsets padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CustomPaint(
      painter: _PanelPainter(shape, border, color, tone, dpr),
      child: ClipPath(
        clipper: _InnerClipper(shape, border),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (art.isNotEmpty) Positioned.fill(child: StaticArt(art)),
            Padding(padding: padding, child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter(this.shape, this.border, this.color, this.tone, this.pixelRatio);
  final PanelShape shape;
  final double border;
  final Color color;
  final ToneSpec? tone;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(shape.outer(size), Paint()..color = Palette.ink);
    final inner = shape.inner(size, border);
    canvas.drawPath(inner, Paint()..color = color);
    if (tone != null) canvas.drawPath(inner, Screentone.paint(tone!, pixelRatio));
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.shape != shape ||
      old.border != border ||
      old.color != color ||
      old.tone != tone ||
      old.pixelRatio != pixelRatio;
}

class _InnerClipper extends CustomClipper<Path> {
  _InnerClipper(this.shape, this.border);
  final PanelShape shape;
  final double border;

  @override
  Path getClip(Size size) => shape.inner(size, border);

  @override
  bool shouldReclip(_InnerClipper old) => old.shape != shape || old.border != border;
}
