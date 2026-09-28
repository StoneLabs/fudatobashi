import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'entrance.dart';
import 'lines.dart';
import 'seeded_random.dart';

/// [child] rattled by an impact on the enclosing [EntranceStage]: jolted to
/// [steps] fresh random spots over [spec], within [reach] px that dies out.
class Jolt extends StatelessWidget {
  const Jolt(this.spec, {super.key, required this.reach, required this.steps, required this.seed, required this.child});

  final EntranceSpec spec;
  final double reach;
  final int steps;
  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
        spec,
        child: child,
        builder: (context, t, child) {
          var offset = Offset.zero;
          if (t > 0 && t < 1) {
            final r = SeededRandom(seed + (t * steps).floor());
            offset = Offset(r.next() * 2 - 1, r.next() * 2 - 1) * reach * (1 - t);
          }
          return Transform.translate(offset: offset, child: child);
        },
      );
}

/// A flash of focus lines bursting outward from the centre of its box over
/// [spec]: [burst] drawn [size] across, growing from [fromScale] to
/// [toScale] as it fades. It spills past the box and ignores touches.
class ImpactBurst extends StatelessWidget {
  const ImpactBurst(this.spec,
      {super.key, required this.burst, required this.size, required this.fromScale, required this.toScale});

  final EntranceSpec spec;
  final BurstSpec burst;
  final Size size;
  final double fromScale, toScale;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: OverflowBox(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: EntranceBuilder(
            spec,
            child: CustomPaint(size: size, painter: FocusLinesPainter(burst)),
            builder: (context, t, child) => Opacity(
              opacity: t > 0 && t < 1 ? 1 - t : 0,
              child: Transform.scale(scale: lerpDouble(fromScale, toScale, t)!, child: child),
            ),
          ),
        ),
      );
}
