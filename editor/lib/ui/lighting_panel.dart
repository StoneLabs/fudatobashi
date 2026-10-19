import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../render/light.dart';
import 'widgets.dart';

class LightingPanel extends StatelessWidget {
  const LightingPanel({super.key, required this.controller});

  final EditorController controller;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final l = controller.light;
    Widget row(String label, Widget child) => SizedBox(
          height: Cfg.formRowHeight,
          child: Row(children: [
            SizedBox(width: 74, child: Text(label, style: const TextStyle(fontSize: Cfg.labelFontSize))),
            Expanded(child: child),
          ]),
        );
    Widget boxRow(String label, double value, double max, ValueChanged<double> onChanged) => row(
          label,
          Align(
            alignment: Alignment.centerLeft,
            child: NumberBox(value: value, decimals: 0, suffix: '°', width: Cfg.formNumberWidthSuffix, onChanged: (v) => onChanged(v.clamp(0, max))),
          ),
        );
    final labels = [for (final p in lightPresets) p.name, 'Custom'];
    return Panel(
      title: 'Preview lighting',
      trailing: const Text('Not saved with the skin', style: TextStyle(fontSize: Cfg.smallFontSize, color: Cfg.mutedColor)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - Cfg.chipGap * (_columns - 1)) / _columns;
          return Wrap(spacing: Cfg.chipGap, runSpacing: Cfg.chipGap, children: [
            for (var i = 0; i < labels.length; i++)
              PickChip(
                width: w,
                label: labels[i],
                selected: controller.lightLabel == labels[i],
                onTap: i < lightPresets.length ? () => controller.usePreset(lightPresets[i]) : null,
              ),
          ]);
        }),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LightDial(light: l, onChanged: controller.setLight),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: Cfg.lightDialSize,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              boxRow('Azimuth', l.azimuth, 360, (v) => controller.setLight(l.copyWith(azimuth: v))),
              boxRow('Elevation', l.elevation, 90, (v) => controller.setLight(l.copyWith(elevation: v))),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        row('Intensity', SliderRow(value: l.intensity, min: 0, max: 2, onChanged: (v) => controller.setLight(l.copyWith(intensity: v)))),
        row('Ambient', SliderRow(value: l.ambient, min: 0, max: 1, onChanged: (v) => controller.setLight(l.copyWith(ambient: v)))),
        row(
          'Colour',
          Align(
            alignment: Alignment.centerLeft,
            child: HexField(value: toHex(l.color), onChanged: (v) => controller.setLight(l.copyWith(color: parseHex(v)))),
          ),
        ),
      ]),
    );
  }
}

/// A round pad seen from above the card. The angle around the centre is the
/// light's azimuth; the distance from the centre is how low it is (the centre is straight above).
class LightDial extends StatelessWidget {
  const LightDial({super.key, required this.light, required this.onChanged});

  final Light light;
  final ValueChanged<Light> onChanged;

  static const _radius = Cfg.lightDialSize / 2 - Cfg.lightDialPad;

  void _pick(Offset local) {
    final d = local - const Offset(Cfg.lightDialSize / 2, Cfg.lightDialSize / 2);
    final r = math.min(d.distance / _radius, 1.0);
    final azimuth = d.distance < 1 ? light.azimuth : (math.atan2(-d.dy, d.dx) * 180 / math.pi + 360) % 360;
    onChanged(light.copyWith(azimuth: azimuth.roundToDouble(), elevation: ((1 - r) * 90).roundToDouble()));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
        onPanStart: (d) => _pick(d.localPosition),
        onPanUpdate: (d) => _pick(d.localPosition),
        onTapDown: (d) => _pick(d.localPosition),
        child: CustomPaint(size: const Size.square(Cfg.lightDialSize), painter: _DialPainter(light)),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.light);

  final Light light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = LightDial._radius;
    final line = Paint()
      ..color = Cfg.panelBorderColor
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, Cfg.lightDialSize / 2, Paint()..color = Cfg.windowColor);
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * 2 / 3, line);
    canvas.drawCircle(c, r / 3, line);
    canvas.drawLine(c - const Offset(r, 0), c + const Offset(r, 0), line);
    canvas.drawLine(c - const Offset(0, r), c + const Offset(0, r), line);
    final card = Rect.fromCenter(center: c, width: r * 0.5, height: r * 0.7);
    canvas.drawRect(card, Paint()..color = Cfg.mutedColor.withValues(alpha: 0.5));
    final az = light.azimuth * math.pi / 180;
    final dist = (1 - light.elevation.clamp(0, 90) / 90) * r;
    final dot = c + Offset(math.cos(az), -math.sin(az)) * dist;
    canvas.drawLine(c, dot, Paint()..color = Cfg.accentColor..strokeWidth = 1.5);
    canvas.drawCircle(dot, Cfg.lightDotRadius, Paint()..color = light.color);
    canvas.drawCircle(dot, Cfg.lightDotRadius, Paint()
      ..color = Cfg.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.light != light;
}
