import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// Plays the [Entrance]s below it on one shared timeline, like a page of CSS
/// animations with staggered delays. Under reduced motion everything starts
/// at rest.
class EntranceStage extends StatefulWidget {
  const EntranceStage({super.key, required this.length, required this.child});

  /// When the last entrance is over.
  final Duration length;
  final Widget child;

  @override
  State<EntranceStage> createState() => _EntranceStageState();
}

class _EntranceStageState extends State<EntranceStage> with SingleTickerProviderStateMixin {
  late final _timeline = AnimationController(vsync: this, duration: widget.length);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timeline.value = 1;
    } else if (_timeline.isDismissed) {
      _timeline.forward();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _StageScope(timeline: _timeline, length: widget.length, child: widget.child);
}

class _StageScope extends InheritedWidget {
  const _StageScope({required this.timeline, required this.length, required super.child});
  final Animation<double> timeline;
  final Duration length;

  @override
  bool updateShouldNotify(_StageScope old) => old.timeline != timeline || old.length != length;
}

/// [child] entering per [spec] on the enclosing [EntranceStage] (at rest
/// without one).
class Entrance extends StatelessWidget {
  const Entrance(this.spec, {super.key, required this.child});

  final EntranceSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stage = context.dependOnInheritedWidgetOfExactType<_StageScope>();
    if (stage == null) return child;
    return AnimatedBuilder(
      animation: stage.timeline,
      child: child,
      builder: (context, child) {
        final elapsed = stage.length * stage.timeline.value - spec.delay;
        final t = (elapsed.inMicroseconds / spec.duration.inMicroseconds).clamp(0.0, 1.0);
        return EntranceFrame(from: spec.from, progress: t >= 1 ? 1 : spec.curve.transform(t), child: child!);
      },
    );
  }
}

/// [child] at [progress] of the way from [from] to rest (1; springy curves
/// overshoot past it). The widget structure never changes with [progress],
/// so the child is not remounted as it settles.
class EntranceFrame extends StatelessWidget {
  const EntranceFrame({super.key, required this.from, required this.progress, required this.child});

  final EntranceFrom from;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final scale = lerpDouble(from.scale, 1, p)!;
    return Opacity(
      opacity: lerpDouble(from.opacity, 1, p / from.opaqueAt)!.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(from.offset.dx * (1 - p), from.offset.dy * (1 - p), 0, 1)
          ..rotateZ(from.turnDeg * (1 - p) * math.pi / 180)
          ..scaleByDouble(scale, scale, 1, 1),
        child: child,
      ),
    );
  }
}

/// [child] gently swelling and shrinking by up to [amount] of its size, once
/// per [period], centred (a background that keeps breathing after the
/// entrance). Still under reduced motion.
class Throb extends StatefulWidget {
  const Throb({super.key, required this.amount, required this.period, required this.child});

  final double amount;
  final Duration period;
  final Widget child;

  @override
  State<Throb> createState() => _ThrobState();
}

class _ThrobState extends State<Throb> with SingleTickerProviderStateMixin {
  late final _cycle = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _cycle
        ..stop()
        ..value = 0;
    } else if (!_cycle.isAnimating) {
      _cycle.repeat();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _cycle,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: 1 + widget.amount * (1 - math.cos(2 * math.pi * _cycle.value)) / 2,
          child: child,
        ),
      );
}
