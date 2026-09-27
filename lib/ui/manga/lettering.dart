import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'seeded_random.dart';

/// Text with a thick outline behind it (title lettering over busy art).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.outline = Palette.paper,
    this.outlineWidth = 10,
  });

  final String text;
  final TextStyle style;
  final Color outline;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          softWrap: false,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
            color: null,
          ),
        ),
        Text(text, softWrap: false, style: style),
      ],
    );
  }
}

/// Sound-effect lettering (擬音): Reggae One, each character jittered,
/// scaled and rotated, with an ink outline and a paper halo.
class SfxText extends StatelessWidget {
  const SfxText(
    this.text, {
    super.key,
    required this.size,
    this.color = Palette.pink,
    this.seed = 1,
    this.outline = SfxStyle.outline,
    this.halo = Palette.paper,
    this.vertical = false,
  });

  final String text;
  final double size;
  final Color color;
  final int seed;
  final double outline;
  final Color halo;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final r = SeededRandom(seed);
    final base = TextStyle(fontFamily: Fonts.sfx, fontSize: size, height: 1);
    final chars = text.characters.toList();
    final glyphs = <Widget>[
      for (var i = 0; i < chars.length; i++)
        () {
          final scale = i == 0 ? SfxStyle.firstScale : SfxStyle.scaleMin + r.next() * SfxStyle.scaleRange;
          final turn = (r.next() - 0.5) * SfxStyle.rotationDeg * math.pi / 180;
          final shift = (r.next() - 0.5) * SfxStyle.shift;
          return Align(
            alignment: Alignment.centerLeft,
            widthFactor: vertical ? 1 : 1 + SfxStyle.overlap,
            child: Transform.rotate(
              angle: turn,
              child: Transform.translate(
                offset: Offset(0, shift),
                child: Transform.scale(
                  scale: scale,
                  child: Stack(children: [
                    Text(chars[i], style: base.copyWith(foreground: _stroke(outline + SfxStyle.halo, halo))),
                    Text(chars[i], style: base.copyWith(foreground: _stroke(outline, Palette.ink))),
                    Text(chars[i], style: base.copyWith(color: color)),
                  ]),
                ),
              ),
            ),
          );
        }(),
    ];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: glyphs)
        : Row(mainAxisSize: MainAxisSize.min, children: glyphs);
  }

  static Paint _stroke(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..color = color;
}

/// A string template whose `{0}`, `{1}` … placeholders are filled with
/// [values] and set in [numberStyle] (display type by default), the rest in
/// the ambient or given [style].
class NumberedText extends StatelessWidget {
  const NumberedText(this.template, this.values, {super.key, this.style, this.numberStyle, this.textAlign});

  final String template;
  final List<Object> values;
  final TextStyle? style;
  final TextStyle? numberStyle;
  final TextAlign? textAlign;

  static final _slot = RegExp(r'\{(\d+)\}');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _slot.allMatches(template)) {
      if (m.start > at) spans.add(TextSpan(text: template.substring(at, m.start)));
      spans.add(TextSpan(
        text: '${values[int.parse(m.group(1)!)]}',
        style: numberStyle ?? const TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular),
      ));
      at = m.end;
    }
    if (at < template.length) spans.add(TextSpan(text: template.substring(at)));
    return Text.rich(TextSpan(style: style, children: spans), textAlign: textAlign);
  }
}
