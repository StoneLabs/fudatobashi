import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'lines.dart';
import 'seeded_random.dart';

/// Keeps a page alive after its entrance: [builder] gets the time since the
/// loop started, and the loop is frozen at zero under reduced motion. With
/// [step] the time advances in whole steps and [builder] runs once per step
/// (stop-motion, like boiling manga lines) instead of every frame.
class IdleLoop extends StatefulWidget {
  const IdleLoop({super.key, required this.builder, this.step, this.child});

  final Widget Function(BuildContext context, Duration elapsed, Widget? child) builder;
  final Duration? step;
  final Widget? child;

  @override
  State<IdleLoop> createState() => _IdleLoopState();
}

class _IdleLoopState extends State<IdleLoop> with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_tick);
  Duration _elapsed = Duration.zero;

  void _tick(Duration elapsed) {
    final step = widget.step;
    final shown = step == null ? elapsed : step * (elapsed.inMicroseconds ~/ step.inMicroseconds);
    if (shown != _elapsed) setState(() => _elapsed = shown);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _elapsed = Duration.zero;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _elapsed, widget.child);
}

/// How far [elapsed] is into the current cycle of [period], 0–1.
double _phase(Duration elapsed, Duration period) =>
    (elapsed.inMicroseconds % period.inMicroseconds) / period.inMicroseconds;

/// [child] gently swelling and shrinking by up to [amount] of its size, once
/// per [period], centred (a background that keeps breathing).
class Throb extends StatelessWidget {
  const Throb({super.key, required this.amount, required this.period, required this.child});

  final double amount;
  final Duration period;
  final Widget child;

  @override
  Widget build(BuildContext context) => IdleLoop(
        child: child,
        builder: (context, elapsed, child) => Transform.scale(
          scale: 1 + amount * (1 - math.cos(2 * math.pi * _phase(elapsed, period))) / 2,
          child: child,
        ),
      );
}

/// [child] rocking by up to [turnDeg] either way and bobbing by up to [lift]
/// px, once per [period] (a card hanging in the air).
class Sway extends StatelessWidget {
  const Sway({super.key, required this.turnDeg, required this.lift, required this.period, required this.child});

  final double turnDeg;
  final double lift;
  final Duration period;
  final Widget child;

  @override
  Widget build(BuildContext context) => IdleLoop(
        child: child,
        builder: (context, elapsed, child) {
          final angle = 2 * math.pi * _phase(elapsed, period);
          return Transform.translate(
            offset: Offset(0, -lift * math.sin(2 * angle).abs()),
            child: Transform.rotate(angle: turnDeg * math.sin(angle) * math.pi / 180, child: child),
          );
        },
      );
}

/// [child] hopping [height] px once per [period]: a jump over the first
/// [airShare] of the cycle, then a rest on the ground (a cheering mascot).
class Hop extends StatelessWidget {
  const Hop({super.key, required this.height, required this.period, required this.airShare, required this.child});

  final double height;
  final Duration period;
  final double airShare;
  final Widget child;

  @override
  Widget build(BuildContext context) => IdleLoop(
        child: child,
        builder: (context, elapsed, child) {
          final q = _phase(elapsed, period) / airShare;
          final rise = q < 1 ? 4 * q * (1 - q) : 0.0;
          return Transform.translate(offset: Offset(0, -height * rise), child: child);
        },
      );
}

/// [child] jolted to a new random spot within [reach] px every [step] (the
/// rumble of ゴゴゴゴ lettering).
class Shake extends StatelessWidget {
  const Shake({super.key, required this.reach, required this.step, required this.seed, required this.child});

  final double reach;
  final Duration step;
  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) => IdleLoop(
        step: step,
        child: child,
        builder: (context, elapsed, child) {
          if (elapsed == Duration.zero) return child!;
          final r = SeededRandom(seed + elapsed.inMicroseconds ~/ step.inMicroseconds);
          return Transform.translate(offset: Offset(r.next() * 2 - 1, r.next() * 2 - 1) * reach, child: child);
        },
      );
}

/// A focus-line burst redrawn with fresh lines every [step], cycling through
/// [frames] drawings (the flicker of manga focus lines in anime).
class BoilingLines extends StatelessWidget {
  const BoilingLines(this.spec, {super.key, required this.frames, required this.step});

  final BurstSpec spec;
  final int frames;
  final Duration step;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: IdleLoop(
          step: step,
          builder: (context, elapsed, _) => CustomPaint(
            size: Size.infinite,
            painter: FocusLinesPainter(spec.reseeded(elapsed.inMicroseconds ~/ step.inMicroseconds % frames)),
          ),
        ),
      );
}
