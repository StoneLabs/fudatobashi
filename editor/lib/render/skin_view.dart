import 'package:flutter/material.dart';

import '../config.dart';
import 'skin_scene.dart';

/// Paints the card with the skin shader, filling the space it is given. [window] picks the part of the
/// card shown for a widget size; the default fits the whole card (plus the config margin).
///
/// The window is worked out while painting rather than in a LayoutBuilder: a card inside a
/// LayoutBuilder could keep painting an old scene after the controller changed.
class SkinView extends StatelessWidget {
  const SkinView({super.key, required this.scene, this.window = fitCard});

  final SkinScene scene;
  final Rect Function(Size size) window;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _SkinPainter(scene, window, MediaQuery.devicePixelRatioOf(context)));
}

/// The card with its margin, centred and fitted into [size], keeping aspect.
Rect fitCard(Size size) {
  const m = Cfg.viewMargin;
  const cardW = Cfg.cardWidth + 2 * m, cardH = Cfg.cardHeight + 2 * m;
  if (size.isEmpty) return const Rect.fromLTWH(0, 0, cardW, cardH);
  final scale = size.width / cardW < size.height / cardH ? size.width / cardW : size.height / cardH;
  final w = size.width / scale, h = size.height / scale;
  return Rect.fromCenter(center: const Offset(Cfg.cardWidth / 2, Cfg.cardHeight / 2), width: w, height: h);
}

class _SkinPainter extends CustomPainter {
  _SkinPainter(this.scene, this.window, this.pixelRatio);

  final SkinScene scene;
  final Rect Function(Size size) window;
  final double pixelRatio;

  /// The shader runs on its own picture so its fragment coordinates start
  /// at the top left of the widget wherever the widget sits in the window.
  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width * pixelRatio).ceil(), h = (size.height * pixelRatio).ceil();
    if (w <= 0 || h <= 0) return;
    final image = renderScene(scene, window(size), w, h);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Offset.zero & size, Paint()..filterQuality = FilterQuality.none);
    image.dispose();
  }

  @override
  bool shouldRepaint(_SkinPainter old) => true;
}

/// Four windows, one on each corner of the card, in a 2x2 grid. Each shows [zoom] screen pixels per
/// card unit, with the card corner a fixed margin in from the cell's corner.
class CornersView extends StatelessWidget {
  const CornersView({super.key, required this.scene, required this.zoom});

  final SkinScene scene;
  final int zoom;

  /// Label, the card corner, and which way the card lies from that corner.
  static const _corners = [
    ('Top left', Offset(0, 0), Offset(1, 1)),
    ('Top right', Offset(Cfg.cardWidth, 0), Offset(-1, 1)),
    ('Bottom left', Offset(0, Cfg.cardHeight), Offset(1, -1)),
    ('Bottom right', Offset(Cfg.cardWidth, Cfg.cardHeight), Offset(-1, -1)),
  ];

  @override
  Widget build(BuildContext context) {
    final flat = scene.copyWith(tilt: Offset.zero);
    Widget cell(int i) {
      final (label, corner, inward) = _corners[i];
      Rect window(Size size) {
        final w = size.width / zoom, h = size.height / zoom;
        const m = Cfg.cornerMargin;
        final left = inward.dx > 0 ? corner.dx - m / zoom : corner.dx - w + m / zoom;
        final top = inward.dy > 0 ? corner.dy - m / zoom : corner.dy - h + m / zoom;
        return Rect.fromLTWH(left, top, w, h);
      }

      return Expanded(
        child: Tooltip(message: label, child: ClipRect(child: SkinView(scene: flat, window: window))),
      );
    }

    const gap = Cfg.panelGap / 2;
    return Column(
      children: [
        Expanded(child: Row(children: [cell(0), const SizedBox(width: gap), cell(1)])),
        const SizedBox(height: gap),
        Expanded(child: Row(children: [cell(2), const SizedBox(width: gap), cell(3)])),
      ],
    );
  }
}
