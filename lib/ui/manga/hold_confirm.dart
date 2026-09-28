import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// A button that confirms only once held for [duration], for actions too
/// consequential for a single tap: a ring fills in around it as the hold
/// continues, and releasing early resets it to empty.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({super.key, required this.duration, required this.label, required this.onConfirmed, this.icon});

  final Duration duration;
  final String label;
  final VoidCallback onConfirmed;
  final Widget? icon;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final _fill = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onConfirmed();
    });

  void _release() {
    if (_fill.status != AnimationStatus.completed) _fill.value = 0;
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _fill.forward(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _fill,
              builder: (context, child) => CustomPaint(
                painter: _RingPainter(_fill.value),
                child: SizedBox.square(dimension: HoldConfirmStyle.ringSize, child: Center(child: child)),
              ),
              child: widget.icon,
            ),
            const SizedBox(height: Gaps.small),
            Text(widget.label,
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - HoldConfirmStyle.ringStroke) / 2;
    final track = Paint()
      ..color = HoldConfirmStyle.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = HoldConfirmStyle.ringStroke;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final fill = Paint()
      ..color = HoldConfirmStyle.fill
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = HoldConfirmStyle.ringStroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
