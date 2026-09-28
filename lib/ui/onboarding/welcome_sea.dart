import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';

/// The still part of the welcome panel's sea (see [WelcomeSeaLayout]), as a
/// layer of the panel's background: the far sea to the horizon, the map's
/// sea below its swell, the boat's wake and Tobi's island.
class WelcomeSeaLayer extends ArtLayer {
  const WelcomeSeaLayer();

  @override
  List<Object?> get props => const [];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) {
    const horizon = WelcomeSeaLayout.horizon, swell = WelcomeSeaLayout.swell;
    canvas.drawRect(Rect.fromLTRB(0, horizon, size.width, size.height),
        Screentone.paint(WelcomeSeaLayout.far, pixelRatio));
    _ripples(canvas, size.width);
    VectorPainter.paint(canvas, SceneArt.farIsle, WelcomeSeaLayout.farIsle, pixelRatio: pixelRatio);
    canvas.drawLine(
      const Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..strokeWidth = WelcomeSeaLayout.horizonStroke
        ..color = Palette.ink,
    );
    final near = Rect.fromLTRB(0, swell - WelcomeSeaLayout.swellHeight, size.width, size.height);
    canvas
      ..save()
      ..clipPath(_swell(near));
    Sea.paint(canvas, near, near, pixelRatio, WelcomeSeaLayout.seaSeed);
    canvas.restore();
    VectorPainter.paint(canvas, SceneArt.boatWake, WelcomeSeaLayout.boatWake, pixelRatio: pixelRatio);
    VectorPainter.paint(canvas, SceneArt.welcomeIsle, WelcomeSeaLayout.isle, pixelRatio: pixelRatio);
  }

  static void _ripples(Canvas canvas, double width) {
    const top = WelcomeSeaLayout.horizon + WelcomeSeaLayout.rippleInset;
    const depth = WelcomeSeaLayout.swell - WelcomeSeaLayout.rippleInset - top;
    final r = SeededRandom(WelcomeSeaLayout.rippleSeed);
    final path = Path();
    for (var k = (width * depth / WelcomeSeaLayout.rippleDensity).round(); k > 0; k--) {
      final x = r.next() * width, t = r.next();
      final length = WelcomeSeaLayout.rippleMin + (WelcomeSeaLayout.rippleMax - WelcomeSeaLayout.rippleMin) * t;
      path
        ..moveTo(x, top + depth * t)
        ..relativeLineTo(length, 0);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = WelcomeSeaLayout.rippleStroke
        ..strokeCap = StrokeCap.round
        ..color = Palette.paper.withValues(alpha: MapStyle.waveOpacity),
    );
  }

  /// [area] below a gentle swell along its top edge.
  static Path _swell(Rect area) {
    const half = WelcomeSeaLayout.swellLength / 2;
    final mid = area.top + WelcomeSeaLayout.swellHeight;
    final path = Path()..moveTo(area.left, mid);
    var up = true;
    for (var x = area.left; x < area.right; x += half) {
      path.quadraticBezierTo(x + half / 2, up ? area.top : mid + WelcomeSeaLayout.swellHeight, x + half, mid);
      up = !up;
    }
    return path
      ..lineTo(area.right, area.bottom)
      ..lineTo(area.left, area.bottom)
      ..close();
  }
}

/// The moving part of the welcome panel's sea: the boat rocking at anchor
/// and the surf drifting along the front. Both hold still under reduced
/// motion.
class WelcomeSeaFront extends StatelessWidget {
  const WelcomeSeaFront({super.key});

  @override
  Widget build(BuildContext context) {
    const orbit = WelcomeSeaLayout.surfOrbit;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          Placed(
            WelcomeSeaLayout.boat,
            child: RepaintBoundary(
              child: Sway(
                turnDeg: WelcomeSeaLayout.boatTurnDeg,
                lift: WelcomeSeaLayout.boatLift,
                period: WelcomeSeaLayout.boatPeriod,
                child: VectorArtBox(MapArt.boat, size: WelcomeSeaLayout.boat.size),
              ),
            ),
          ),
          Positioned(
            left: -orbit.dx,
            right: -orbit.dx,
            top: math.max(constraints.maxHeight - WelcomeSeaLayout.surfRise, WelcomeSeaLayout.surfTopMin),
            height: SceneArt.surf.box.height,
            child: RepaintBoundary(
              child: IdleLoop(
                child: const StaticArt([_SurfLayer()]),
                builder: (context, elapsed, child) {
                  final a = 2 * math.pi * elapsed.inMicroseconds / WelcomeSeaLayout.surfPeriod.inMicroseconds;
                  return Transform.translate(
                      offset: Offset(orbit.dx * math.sin(a), -orbit.dy * math.cos(a)), child: child);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [SceneArt.surf] repeated across the width.
class _SurfLayer extends ArtLayer {
  const _SurfLayer();

  @override
  List<Object?> get props => const [];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) {
    final tile = SceneArt.surf.box;
    for (var x = 0.0; x < size.width; x += tile.width) {
      VectorPainter.paint(canvas, SceneArt.surf, Offset(x, 0) & tile, pixelRatio: pixelRatio);
    }
  }
}
