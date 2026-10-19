import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../render/skin_scene.dart';
import '../render/skin_view.dart';
import 'texture_pane.dart';
import 'widgets.dart';

/// The texture pane (when open) and the card with its preview bar.
///
/// No LayoutBuilder sits above the card: one could keep painting an old scene after the
/// controller changed. Widths come from the window size instead.
class CenterView extends StatelessWidget {
  const CenterView({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final card = Expanded(key: const ValueKey('card'), child: _CardColumn(controller: controller));
    if (!controller.tabs.visible) return Row(children: [card]);
    final width = MediaQuery.sizeOf(context).width - Cfg.leftColumnWidth - Cfg.rightColumnWidth - 4 * Cfg.panelGap;
    final tabsMax = math.max(Cfg.tabsWidthMin, width - Cfg.cardMinWidth - Cfg.paneSplitterWidth);
    final tabsWidth = controller.settings.tabsWidth.clamp(Cfg.tabsWidthMin, tabsMax);
    return Row(
      children: [
        SizedBox(key: const ValueKey('tabs'), width: tabsWidth, child: TexturePane(controller: controller)),
        _Splitter(
          onDrag: (dx) => controller.setTabsWidth((tabsWidth + dx).clamp(Cfg.tabsWidthMin, tabsMax)),
          onEnd: () => controller.setTabsWidth(null, remember: true),
        ),
        card,
      ],
    );
  }
}

/// A draggable divider between two panes.
class _Splitter extends StatelessWidget {
  const _Splitter({required this.onDrag, required this.onEnd});

  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
          onHorizontalDragEnd: (_) => onEnd(),
          child: SizedBox(
            width: Cfg.paneSplitterWidth,
            child: Center(child: Container(width: 2, height: 48, color: Cfg.mutedColor)),
          ),
        ),
      );
}

class _CardColumn extends StatelessWidget {
  const _CardColumn({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final scene = controller.scene;
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Cfg.panelColor,
            child: scene == null
                ? const Center(child: Text('Nothing to show yet'))
                : Builder(
                    builder: (context) => GestureDetector(
                      onPanUpdate: (d) {
                        final box = context.size ?? Size.zero;
                        if (box.isEmpty) return;
                        controller.setTilt(controller.tilt + Offset(d.delta.dx / (box.width * Cfg.tiltDragShare), d.delta.dy / (box.height * Cfg.tiltDragShare)));
                      },
                      onDoubleTap: controller.resetTilt,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SkinView(scene: scene),
                          if (controller.comparing)
                            const Positioned(
                              left: Cfg.resetButtonInset,
                              top: Cfg.resetButtonInset,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Cfg.cornerLabelBackground),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text('Saved version', style: TextStyle(fontSize: Cfg.labelFontSize)),
                                ),
                              ),
                            ),
                          Positioned(
                            right: Cfg.resetButtonInset,
                            top: Cfg.resetButtonInset,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Listener(
                                onPointerDown: (_) => controller.setComparing(true),
                                onPointerUp: (_) => controller.setComparing(false),
                                onPointerCancel: (_) => controller.setComparing(false),
                                child: IconButton(
                                  icon: const Icon(Icons.compare),
                                  tooltip: 'Hold to show the saved version (or hold \\)',
                                  onPressed: () {},
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.restart_alt),
                                tooltip: 'Reset view (double-click)',
                                onPressed: controller.resetTilt,
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: Cfg.panelGap),
        _PreviewBar(controller: controller),
      ],
    );
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: Cfg.labelFontSize);
    final skin = controller.skin;
    final wear = controller.wear;
    final band = wearBandFor(wear);
    final range = skin == null ? null : floatRange(skin);
    final outside = range != null && (wear < range.$1 - Cfg.wearRangeSlack || wear > range.$2 + Cfg.wearRangeSlack);
    return Container(
      width: double.infinity,
      color: Cfg.panelColor,
      padding: const EdgeInsets.symmetric(horizontal: Cfg.panelGap, vertical: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Tooltip(
            message: 'The wear the preview shows, over the whole float scale. The bright part is the skin\'s float range.',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Float', style: label),
              const SizedBox(width: 10),
              SizedBox(
                width: Cfg.wearSliderWidth,
                height: Cfg.viewBarHeight - 8,
                child: WearSlider(wear: wear, range: range ?? (0, 1), onChanged: controller.setWear),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: Cfg.wearReadoutWidth,
                child: Text(
                  outside ? 'float ${wear.toStringAsFixed(3)} · outside the range' : 'float ${wear.toStringAsFixed(3)} · ${band.name}',
                  style: label.copyWith(color: outside ? Cfg.warningColor : band.color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          Tooltip(
            message: 'The seed moves the pattern and the wear.',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Seed', style: label),
              const SizedBox(width: 6),
              _seedButton(Icons.remove, 'Previous seed', () => controller.setSeed(controller.seed - 1)),
              NumberBox(value: controller.seed, decimals: 0, onChanged: (v) => controller.setSeed(v.round())),
              _seedButton(Icons.add, 'Next seed', () => controller.setSeed(controller.seed + 1)),
              _seedButton(Icons.casino_outlined, 'Random seed', controller.randomSeed),
            ]),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Preview poem', style: label),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Remembered by the editor, not saved in the skin',
              child: NumberBox(value: controller.poem, decimals: 0, width: Cfg.formNumberWidth, onChanged: (v) => controller.setPreviewPoem(v.round())),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _seedButton(IconData icon, String tip, VoidCallback onTap) => IconButton(
        icon: Icon(icon, size: Cfg.toolIconSize),
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
      );
}

/// The band a wear value falls in.
WearBand wearBandFor(double wear) => Cfg.wearBands.firstWhere((b) => wear < b.upTo, orElse: () => Cfg.wearBands.last);

/// A slider over the full wear scale 0 to 1, coloured by band. The skin's float [range] is bright, the
/// rest dimmed; the whole scale can be previewed.
class WearSlider extends StatelessWidget {
  const WearSlider({super.key, required this.wear, required this.range, required this.onChanged});

  final double wear;
  final (double, double) range;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    void pick(BuildContext context, double x) {
      final width = context.size?.width ?? 0;
      const pad = Cfg.wearThumbRadius;
      if (width <= 2 * pad) return;
      onChanged(((x - pad) / (width - 2 * pad)).clamp(0.0, 1.0));
    }

    return Builder(
      builder: (context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(context, d.localPosition.dx),
          onHorizontalDragStart: (d) => pick(context, d.localPosition.dx),
          onHorizontalDragUpdate: (d) => pick(context, d.localPosition.dx),
          child: CustomPaint(size: const Size(double.infinity, Cfg.wearSliderHeight), painter: _WearPainter(wear, range.$1, range.$2)),
        ),
      ),
    );
  }
}

class _WearPainter extends CustomPainter {
  _WearPainter(this.wear, this.lo, this.hi);

  final double wear, lo, hi;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = Cfg.wearThumbRadius;
    final left = pad, width = size.width - 2 * pad;
    final cy = size.height / 2;
    final top = cy - Cfg.wearTrackHeight / 2;
    var from = 0.0;
    for (final b in Cfg.wearBands) {
      final to = b.upTo;
      final rect = Rect.fromLTRB(left + from * width, top, left + to * width, top + Cfg.wearTrackHeight);
      canvas.drawRect(rect, Paint()..color = b.color.withValues(alpha: Cfg.wearOutsideDim));
      final a = from < lo ? lo : from, z = to > hi ? hi : to;
      if (z > a) {
        canvas.drawRect(Rect.fromLTRB(left + a * width, top, left + z * width, top + Cfg.wearTrackHeight), Paint()..color = b.color);
      }
      from = to;
    }
    final tick = Paint()
      ..color = Cfg.labelColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (final b in Cfg.wearBands.take(Cfg.wearBands.length - 1)) {
      final x = left + b.upTo * width;
      canvas.drawLine(Offset(x, top - 3), Offset(x, top + Cfg.wearTrackHeight + 3), tick);
    }
    final thumb = Offset(left + wear.clamp(0.0, 1.0) * width, cy);
    canvas.drawCircle(thumb, Cfg.wearThumbRadius, Paint()..color = Cfg.labelColor);
    canvas.drawCircle(thumb, Cfg.wearThumbRadius, Paint()
      ..color = Cfg.windowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_WearPainter old) => old.wear != wear || old.lo != lo || old.hi != hi;
}
