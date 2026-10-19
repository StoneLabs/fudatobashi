import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';

const InputDecoration compactDecoration = InputDecoration(
  isDense: true,
  border: OutlineInputBorder(),
  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
);

/// A box width that shows every digit of a number in [min]..[max] with [decimals] places, never less
/// than the usual box ([Cfg.formNumberWidth], or [Cfg.formNumberWidthSuffix] when [suffix] is set).
double numberBoxWidth(double min, double max, int decimals, {bool suffix = false}) {
  final big = math.max(min.abs(), max.abs());
  final digits = big < 1 ? 1 : big.floor().toString().length;
  final chars = digits + (decimals > 0 ? decimals + 1 : 0) + (min < 0 ? 1 : 0);
  final fit = chars * Cfg.numberCharWidth + Cfg.numberBoxPadding + (suffix ? Cfg.numberSuffixWidth : 0);
  return math.max(fit, suffix ? Cfg.formNumberWidthSuffix : Cfg.formNumberWidth);
}

/// A small text box for one number. Typing commits valid numbers at once.
class NumberBox extends StatefulWidget {
  const NumberBox({super.key, required this.value, required this.onChanged, this.decimals = 2, this.width, this.suffix});

  final num value;
  final ValueChanged<double> onChanged;
  final int decimals;
  final double? width;
  final String? suffix;

  @override
  State<NumberBox> createState() => _NumberBoxState();
}

class _NumberBoxState extends State<NumberBox> {
  late final TextEditingController _controller = TextEditingController(text: _format(widget.value));

  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  String _format(num v) => v.toDouble().toStringAsFixed(widget.decimals);

  void _onFocus() {
    if (!_focus.hasFocus) _controller.text = _format(widget.value);
  }

  @override
  void didUpdateWidget(NumberBox old) {
    super.didUpdateWidget(old);
    final typed = double.tryParse(_controller.text);
    if (typed != widget.value.toDouble()) _controller.text = _format(widget.value);
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? Cfg.numberBoxWidth,
      height: Cfg.formRowHeight - 2,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        style: const TextStyle(fontSize: Cfg.labelFontSize),
        decoration: widget.suffix == null ? compactDecoration : compactDecoration.copyWith(suffixText: widget.suffix, suffixStyle: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor)),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
        onChanged: (t) {
          final v = double.tryParse(t);
          if (v != null) widget.onChanged(v);
        },
        onSubmitted: (_) => _controller.text = _format(widget.value),
      ),
    );
  }
}

SliderThemeData compactSlider(BuildContext context) => SliderTheme.of(context).copyWith(
      trackHeight: Cfg.formSliderTrack,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: Cfg.formSliderThumb),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: Cfg.formSliderThumb * 2),
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: Cfg.formSliderThumb),
    );

/// A slider with its current number in a box beside it.
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step,
    this.decimals = 2,
    this.suffix,
  });

  final double value, min, max;
  final String? suffix;
  final double? step;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: compactSlider(context),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
        NumberBox(value: value, decimals: decimals, suffix: suffix, width: numberBoxWidth(min, max, decimals, suffix: suffix != null), onChanged: onChanged),
      ],
    );
  }
}

Color? parseHex(String text) {
  final t = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) return null;
  return Color(0xFF000000 | int.parse(t, radix: 16));
}

String toHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A hex colour text box with a swatch beside it.
class HexField extends StatefulWidget {
  const HexField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<HexField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  void _onFocus() {
    if (_focus.hasFocus) return;
    final typed = parseHex(_controller.text);
    _controller.text = typed == null ? widget.value : toHex(typed);
    setState(() {});
  }

  @override
  void didUpdateWidget(HexField old) {
    super.didUpdateWidget(old);
    final typed = parseHex(_controller.text);
    final now = parseHex(widget.value);
    if (typed != now) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = parseHex(_controller.text) ?? parseHex(widget.value) ?? Colors.transparent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Cfg.formSwatchSize,
          height: Cfg.formSwatchSize,
          decoration: BoxDecoration(color: color, border: Border.all(color: Cfg.mutedColor)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: Cfg.hexBoxWidth,
          height: Cfg.formRowHeight - 2,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            style: const TextStyle(fontSize: Cfg.labelFontSize),
            decoration: compactDecoration,
            onChanged: (t) {
              final c = parseHex(t);
              if (c != null) widget.onChanged(toHex(c));
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}

/// A titled box used for each panel. Every header has the same height.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cfg.panelColor,
      padding: const EdgeInsets.all(Cfg.panelGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: Cfg.panelHeaderHeight,
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Cfg.panelTitleFontSize, color: Cfg.labelColor)),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// A fixed-size choice button. Selecting it changes colours only, never the size.
class PickChip extends StatelessWidget {
  const PickChip({super.key, required this.label, required this.selected, required this.onTap, this.width});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: Cfg.chipHeight,
      child: Material(
        color: selected ? Cfg.chipSelectedColor : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: selected ? Cfg.accentColor : Cfg.panelBorderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Center(
            child: Text(label, style: TextStyle(fontSize: Cfg.labelFontSize, color: selected ? Cfg.labelColor : Cfg.mutedColor)),
          ),
        ),
      ),
    );
  }
}

/// Paints a checkerboard so transparent pixels show.
class CheckerPainter extends CustomPainter {
  const CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = Cfg.checkerLight, dark = Paint()..color = Cfg.checkerDark;
    canvas.drawRect(Offset.zero & size, dark);
    for (var y = 0.0; y < size.height; y += Cfg.checkerSquare) {
      for (var x = 0.0; x < size.width; x += Cfg.checkerSquare) {
        if (((x / Cfg.checkerSquare).floor() + (y / Cfg.checkerSquare).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, Cfg.checkerSquare, Cfg.checkerSquare), light);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CheckerPainter old) => false;
}
