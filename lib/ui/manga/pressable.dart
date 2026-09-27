import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// Tap handling with the manga press: the control drops, shrinks and tilts a
/// little while held, like a stamp hitting paper. [builder] gets the pressed
/// state for extra ink effects.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.drop = Press.buttonDrop,
    this.scale = Press.buttonScale,
    this.turn = Tilt.pressButton,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;
  final double drop;
  final double scale;

  /// Rotation while pressed, degrees.
  final double turn;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _pressed ? 1 : 0),
          duration: Motion.press,
          curve: Motion.pressCurve,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(0, widget.drop * t),
            child: Transform.rotate(
              angle: widget.turn * t * math.pi / 180,
              child: Transform.scale(scale: 1 - (1 - widget.scale) * t, child: child),
            ),
          ),
          child: widget.builder(context, _pressed),
        ),
      ),
    );
  }
}
