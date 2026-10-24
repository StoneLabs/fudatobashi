import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../manga/geometry.dart';
import '../manga/screentone.dart';
import '../manga/seeded_random.dart';
import '../manga/static_art.dart';
import '../manga/svg_path.dart';
import '../manga/vector.dart';

enum IslandLook {
  /// Green land with a white surf line.
  land,

  /// A pale, dashed outline: not reached yet.
  shoal,

  /// Not drawn at all (a page spotlighting one island).
  hidden,
}

enum SiteKind { tree, dot, pending, hollow, flag }

/// How one card is marked on its island.
@immutable
class SiteMark {
  /// An unlocked card (journey): green once played, [Palette.sun] while new.
  const SiteMark.tree([this.color]) : kind = SiteKind.tree;

  /// A dot in a speed colour (stats).
  const SiteMark.dot(Color this.color) : kind = SiteKind.dot;

  /// A dashed circle: the next card to unlock ([Palette.sun]) or a locked one.
  const SiteMark.pending([Color this.color = Palette.paper]) : kind = SiteKind.pending;

  /// An empty circle (too few attempts to judge).
  const SiteMark.hollow()
      : kind = SiteKind.hollow,
        color = null;

  /// A flag planted on a conquered card (island complete).
  const SiteMark.flag()
      : kind = SiteKind.flag,
        color = null;

  final SiteKind kind;
  final Color? color;

  @override
  bool operator ==(Object other) => other is SiteMark && other.kind == kind && other.color == color;

  @override
  int get hashCode => Object.hash(kind, color);
}

/// An island's name plate with an optional chip ("いちひき 10/12").
@immutable
class IslandPlate {
  const IslandPlate({
    required this.name,
    this.background = Palette.paper,
    this.foreground = Palette.ink,
    this.chip,
    this.chipBackground = Palette.paper,
    this.chipForeground = Palette.ink,
    this.dashed = false,
    this.emphasis = false,
    this.fontSize = MapStyle.plateFont,
    this.chipMark,
    this.mark,
  });

  final String name;
  final Color background, foreground;
  final String? chip;
  final Color chipBackground, chipForeground;
  final bool dashed;

  /// A heavier border (the current or selected island).
  final bool emphasis;
  final double fontSize;

  /// A [MapStyle.chipMarkGlyph] after the chip's text in this colour (Stats'
  /// slowest island).
  final Color? chipMark;

  /// Art at the plate's end (the rank ladder's goal star).
  final VectorArt? mark;

  @override
  bool operator ==(Object other) =>
      other is IslandPlate &&
      other.name == name &&
      other.background == background &&
      other.foreground == foreground &&
      other.chip == chip &&
      other.chipBackground == chipBackground &&
      other.chipForeground == chipForeground &&
      other.dashed == dashed &&
      other.emphasis == emphasis &&
      other.fontSize == fontSize &&
      other.chipMark == chipMark &&
      other.mark == mark;

  @override
  int get hashCode => Object.hash(
      name, background, foreground, chip, chipBackground, chipForeground, dashed, emphasis, fontSize, chipMark, mark);
}

/// How one island is drawn.
@immutable
class IslandStyle {
  const IslandStyle({
    this.look = IslandLook.land,
    this.sites = const {},
    this.plate,
    this.flag = false,
    this.pulse = false,
  });

  final IslandLook look;

  /// Card marks by poem id; cards without an entry are not marked.
  final Map<int, SiteMark> sites;
  final IslandPlate? plate;
  final bool flag;

  /// Tide rings pulse around the island (current or selected).
  final bool pulse;

  @override
  bool operator ==(Object other) =>
      other is IslandStyle &&
      other.look == look &&
      mapEquals(other.sites, sites) &&
      other.plate == plate &&
      other.flag == flag &&
      other.pulse == pulse;

  @override
  int get hashCode => Object.hash(look, Object.hashAllUnordered(sites.entries.map((e) => (e.key, e.value))), plate,
      flag, pulse);
}

/// The route: sailed (pink, dashed) from the harbour up to island
/// [reached] (none of them at -1) and on to [stop] when given, then dotted
/// onward through every later island.
@immutable
class IslandRoute {
  const IslandRoute(this.reached, {this.harbour = MapStyle.routeStart, this.stop})
      : assert(reached >= 0 || stop != null, 'a route short of the first island stops somewhere');
  final int reached;

  /// Where the route starts, relative to the first island's centre.
  final Offset harbour;

  /// Where the sailed part ends past island [reached], in map units.
  final Offset? stop;

  @override
  bool operator ==(Object other) =>
      other is IslandRoute && other.reached == reached && other.harbour == harbour && other.stop == stop;

  @override
  int get hashCode => Object.hash(reached, harbour, stop);
}

/// The archipelago map. Shared by the Home journey and Stats: every island is
/// styled by the caller, [viewport] (map units) picks the visible part, and
/// [onIslandTap] reports taps on an island or its plate.
///
/// The map itself is rendered to cached bitmaps; only tide rings animate.
class IslandMap extends StatefulWidget {
  const IslandMap({
    super.key,
    required this.styles,
    this.viewport,
    this.fit = BoxFit.cover,
    this.route,
    this.boat,
    this.seaSeed = 1,
    this.sea = true,
    this.tideColor = Palette.pink,
    this.onIslandTap,
    this.chart,
  });

  /// One style per island of [chart], in order.
  final List<IslandStyle> styles;
  final Rect? viewport;
  final BoxFit fit;
  final IslandRoute? route;

  /// Where the boat floats, in map units.
  final Offset? boat;
  final int seaSeed;

  /// False leaves the sea transparent, for an island floating over art.
  final bool sea;
  final Color tideColor;
  final ValueChanged<int>? onIslandTap;

  /// The islands and their sea, [archipelago] unless given.
  final Archipelago? chart;

  static Path _catmullRom(List<Offset> p) {
    final path = Path();
    if (p.isEmpty) return path;
    path.moveTo(p[0].dx, p[0].dy);
    for (var k = 0; k < p.length - 1; k++) {
      final p0 = p[math.max(k - 1, 0)], p1 = p[k], p2 = p[k + 1], p3 = p[math.min(k + 2, p.length - 1)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  /// Where the boat floats: on the last sailed leg into island [reached],
  /// or on the way out of the first island before any leg is sailed.
  static Offset boatPosition(List<IslandShape> islands, int reached) {
    final (from, to) = reached == 0
        ? (islands[0].center, islands[math.min(1, islands.length - 1)].center)
        : (islands[reached - 1].center, islands[reached].center);
    return Offset.lerp(from, to, MapStyle.boatAlong)!;
  }

  /// The boat's box when it floats at [boat].
  static Rect boatRect(Offset boat) {
    final b = MapStyle.boat;
    return Rect.fromLTWH(boat.dx - b.width / 2, boat.dy - b.height * MapStyle.boatLift, b.width, b.height);
  }

  /// The square the tide rings around [island] reach at their largest.
  static Rect tideReach(IslandShape island) =>
      Rect.fromCircle(center: island.center, radius: (_MapSpec.ringRadius(island) + Tide.stroke / 2) * Tide.scaleTo);

  @override
  State<IslandMap> createState() => _IslandMapState();
}

class _IslandMapState extends State<IslandMap> with SingleTickerProviderStateMixin {
  late final _tide = AnimationController(vsync: this, duration: Tide.period);

  bool get _pulsing => widget.styles.any((s) => s.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTide();
  }

  @override
  void didUpdateWidget(IslandMap old) {
    super.didUpdateWidget(old);
    _syncTide();
  }

  void _syncTide() {
    final run = _pulsing && !MediaQuery.disableAnimationsOf(context);
    if (run && !_tide.isAnimating) _tide.repeat();
    if (!run && _tide.isAnimating) _tide.stop();
  }

  @override
  void dispose() {
    _tide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final spec = _MapSpec(widget.chart ?? archipelago, widget.styles, widget.viewport, widget.fit, widget.route,
        widget.boat, widget.sea ? widget.seaSeed : null);
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      final xf = spec.transform(size);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onIslandTap == null
            ? null
            : (d) {
                final hit = spec.hitTest(xf.toMap(d.localPosition));
                if (hit != null) widget.onIslandTap!(hit);
              },
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: CustomPaint(painter: _LayerPainter(spec, _Layer.below, dpr))),
            if (_pulsing)
              RepaintBoundary(
                  child: CustomPaint(painter: _TidePainter(spec, _tide, !_tide.isAnimating, widget.tideColor))),
            RepaintBoundary(child: CustomPaint(painter: _LayerPainter(spec, _Layer.above, dpr))),
          ],
        ),
      );
    });
  }
}

/// Maps between map units and widget pixels.
class _MapTransform {
  _MapTransform(this.scale, this.offset);
  final double scale;
  final Offset offset;

  Offset toMap(Offset p) => (p - offset) / scale;

  void apply(Canvas c) {
    c.translate(offset.dx, offset.dy);
    c.scale(scale);
  }
}

class _MapSpec {
  _MapSpec(this.chart, this.styles, this.viewport, this.fit, this.route, this.boat, this.seaSeed);
  final Archipelago chart;
  final List<IslandStyle> styles;
  final Rect? viewport;
  final BoxFit fit;
  final IslandRoute? route;
  final Offset? boat;

  /// Null: no sea.
  final int? seaSeed;

  List<IslandShape> get islands => chart.islands;

  /// [island]'s coastline in map units.
  static Path coastOf(IslandShape island) => _coasts[island] ??= island.scale == 1 && island.shift == Offset.zero
      ? SvgPath.parse(island.pathData)
      : SvgPath.parse(island.pathData)
          .transform((Matrix4.identity()
                ..translateByDouble(island.shift.dx, island.shift.dy, 0, 1)
                ..scaleByDouble(island.scale, island.scale, 1, 1))
              .storage);
  static final _coasts = Expando<Path>();

  _MapTransform transform(Size size) {
    final vp = viewport ?? Offset.zero & chart.size;
    final sx = size.width / vp.width, sy = size.height / vp.height;
    final s = fit == BoxFit.contain ? math.min(sx, sy) : math.max(sx, sy);
    final offset = Offset((size.width - vp.width * s) / 2, (size.height - vp.height * s) / 2) - vp.topLeft * s;
    return _MapTransform(s, offset);
  }

  int? hitTest(Offset p) {
    for (final isl in islands) {
      final plate = styles[isl.index].plate;
      if (plate != null && _PlateGeometry.of(plate, isl.label).rect.inflate(MapStyle.tapSlop).contains(p)) {
        return isl.index;
      }
    }
    for (final isl in islands) {
      if (coastOf(isl).contains(p)) return isl.index;
    }
    for (final isl in islands) {
      if (isl.bounds.inflate(MapStyle.tapSlop).contains(p)) return isl.index;
    }
    return null;
  }

  static double ringRadius(IslandShape isl) => math.max(isl.bounds.width, isl.bounds.height) / 2 + Tide.margin;

  @override
  bool operator ==(Object other) =>
      other is _MapSpec &&
      identical(other.chart, chart) &&
      listEquals(other.styles, styles) &&
      other.viewport == viewport &&
      other.fit == fit &&
      other.route == route &&
      other.boat == boat &&
      other.seaSeed == seaSeed;

  @override
  int get hashCode => Object.hash(identityHashCode(chart), Object.hashAll(styles), viewport, fit, route, boat, seaSeed);
}

/// The map's sea: [Tones.mapSea] with white wave squiggles.
abstract final class Sea {
  /// Tones [area] and scatters waves over [waves].
  static void paint(Canvas canvas, Rect area, Rect waves, double pixelRatio, int seed) {
    canvas.drawRect(area, Screentone.paint(Tones.mapSea, pixelRatio));
    final r = SeededRandom(seed);
    final n = (waves.width * waves.height / MapStyle.waveDensity).round();
    final path = Path();
    for (var k = 0; k < n; k++) {
      final x = waves.left + r.next() * waves.width, y = waves.top + r.next() * waves.height;
      path
        ..moveTo(x, y)
        ..quadraticBezierTo(x + MapStyle.waveHalf, y - MapStyle.waveHeight, x + MapStyle.waveHalf * 2, y)
        ..quadraticBezierTo(x + MapStyle.waveHalf * 3, y + MapStyle.waveHeight, x + MapStyle.waveHalf * 4, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = MapStyle.waveStroke
        ..strokeCap = StrokeCap.round
        ..color = Palette.paper.withValues(alpha: MapStyle.waveOpacity),
    );
  }
}

/// A full-bleed [Sea] as a [StaticArt] layer.
class SeaLayer extends ArtLayer {
  const SeaLayer(this.seed);
  final int seed;

  @override
  List<Object?> get props => [seed];

  @override
  void paint(Canvas canvas, Size size, double pixelRatio) =>
      Sea.paint(canvas, Offset.zero & size, Offset.zero & size, pixelRatio, seed);
}

enum _Layer { below, above }

class _LayerPainter extends CustomPainter {
  _LayerPainter(this.spec, this.layer, this.pixelRatio);
  final _MapSpec spec;
  final _Layer layer;
  final double pixelRatio;

  static final _images = <Object, ui.Image>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final key = (spec, layer, size, pixelRatio);
    var image = _images.remove(key);
    image ??= _render(size);
    _images[key] = image;
    while (_images.length > CacheLimits.mapLayers) {
      _images.remove(_images.keys.first)?.dispose();
    }
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render(Size size) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(pixelRatio);
    canvas.clipRect(Offset.zero & size);
    final xf = spec.transform(size);
    xf.apply(canvas);
    final ratio = pixelRatio * xf.scale;
    switch (layer) {
      case _Layer.below:
        if (spec.seaSeed != null) {
          Sea.paint(canvas, xf.toMap(Offset.zero) & (size / xf.scale), Offset.zero & spec.chart.size, ratio,
              spec.seaSeed!);
        }
        _paintRoute(canvas);
      case _Layer.above:
        _paintIslands(canvas, ratio);
    }
    return rec.endRecording().toImageSync((size.width * pixelRatio).ceil(), (size.height * pixelRatio).ceil());
  }

  void _paintRoute(Canvas canvas) {
    final route = spec.route;
    if (route == null) return;
    final islands = spec.islands;
    Paint pen(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = MapStyle.routeStroke
      ..strokeCap = StrokeCap.round
      ..color = c;
    final reached = route.reached;
    final stop = route.stop;
    final sailed = IslandMap._catmullRom([
      islands.first.center + route.harbour,
      for (var i = 0; i <= reached; i++) islands[i].center,
      ?stop,
    ]);
    canvas.drawPath(Dashes.of(sailed, MapStyle.routeDoneDash), pen(Palette.pink));
    final ahead = IslandMap._catmullRom([
      stop ?? islands[reached].center,
      for (var i = reached + 1; i < islands.length; i++) islands[i].center,
    ]);
    canvas.drawPath(Dashes.of(ahead, MapStyle.routeAheadDash), pen(Palette.paper));
  }

  void _paintIslands(Canvas canvas, double ratio) {
    final islands = spec.islands;
    for (final isl in islands) {
      final style = spec.styles[isl.index];
      if (style.look == IslandLook.hidden) continue;
      final coast = _MapSpec.coastOf(isl)..fillType = PathFillType.evenOdd;
      if (style.look == IslandLook.land) {
        canvas.drawPath(
          coast,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = MapStyle.surf
            ..strokeJoin = StrokeJoin.round
            ..color = Palette.paper,
        );
      }
      final shoal = style.look == IslandLook.shoal;
      canvas.drawPath(coast, Screentone.paint(shoal ? Tones.mapShoal : Tones.mapLand, ratio));
      canvas.drawPath(
        shoal ? Dashes.of(coast, MapStyle.shoalDash) : coast,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = shoal ? MapStyle.shoalStroke : MapStyle.coastStroke
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.ink,
      );
      for (final site in isl.sites) {
        final mark = style.sites[site.poemId];
        if (mark != null) _paintSite(canvas, mark, site.at, isl.dotRadius, ratio);
      }
    }
    for (final isl in islands) {
      if (!spec.styles[isl.index].flag) continue;
      final at = Offset(isl.center.dx, isl.bounds.top) + MapStyle.flagOffset;
      VectorPainter.paint(canvas, MapArt.flag, at & MapStyle.flag, pixelRatio: ratio);
    }
    for (final isl in islands) {
      final plate = spec.styles[isl.index].plate;
      if (plate != null) _PlateGeometry.of(plate, isl.label).paint(canvas, ratio);
    }
    final boat = spec.boat;
    if (boat != null) VectorPainter.paint(canvas, MapArt.boat, IslandMap.boatRect(boat), pixelRatio: ratio);
  }

  void _paintSite(Canvas canvas, SiteMark mark, Offset at, double dotRadius, double ratio) {
    final treeR = math.min(MapStyle.treeMaxRadius, dotRadius - MapStyle.treeInset);
    Paint ink(double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = Palette.ink;
    switch (mark.kind) {
      case SiteKind.tree:
        canvas.drawCircle(at, treeR, Paint()..color = mark.color ?? MapStyle.tree);
        canvas.drawCircle(at, treeR, ink(MapStyle.treeStroke));
        canvas.drawCircle(
          at - Offset(treeR * MapStyle.treeHighlightOffset, treeR * MapStyle.treeHighlightOffset),
          treeR * MapStyle.treeHighlightRadius,
          Paint()..color = MapStyle.treeHighlight,
        );
      case SiteKind.dot:
        canvas.drawCircle(at, dotRadius, Paint()..color = mark.color!);
        canvas.drawCircle(at, dotRadius, ink(MapStyle.dotStroke));
      case SiteKind.pending:
        canvas.drawCircle(at, treeR, Paint()..color = mark.color!);
        canvas.drawPath(
            Dashes.of(Path()..addOval(Rect.fromCircle(center: at, radius: treeR)), Strokes.fineDash),
            ink(MapStyle.pendingStroke));
      case SiteKind.hollow:
        final r = dotRadius - MapStyle.hollowInset;
        canvas.drawCircle(at, r, Paint()..color = Palette.paper);
        canvas.drawCircle(at, r, ink(MapStyle.hollowStroke));
      case SiteKind.flag:
        const f = MapStyle.siteFlag;
        VectorPainter.paint(canvas, MapArt.flag, (at - MapStyle.siteFlagFoot) & f, pixelRatio: ratio);
    }
  }

  @override
  bool shouldRepaint(_LayerPainter old) => old.spec != spec || old.layer != layer || old.pixelRatio != pixelRatio;
}

/// Layout of a name plate (and its chip) around a label point.
class _PlateGeometry {
  _PlateGeometry(this.plate, this.rect, this.name, this.chip, this.chipRect);
  final IslandPlate plate;
  final Rect rect;
  final TextPainter name;
  final TextPainter? chip;
  final Rect? chipRect;

  static final _cache = <(IslandPlate, Offset), _PlateGeometry>{};

  static _PlateGeometry of(IslandPlate p, Offset at) => _cache[(p, at)] ??= _layout(p, at);

  static _PlateGeometry _layout(IslandPlate p, Offset at) {
    final fs = p.fontSize;
    final name = TextPainter(
      text: TextSpan(
        text: p.name,
        style: TextStyle(fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: fs, color: p.foreground, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    TextPainter? chip;
    var chipW = 0.0;
    if (p.chip != null) {
      chip = TextPainter(
        text: TextSpan(
          text: p.chip,
          style: TextStyle(
              fontFamily: Fonts.display, fontSize: fs * MapStyle.chipScale, color: p.chipForeground, height: 1),
          children: [
            if (p.chipMark != null)
              TextSpan(
                text: MapStyle.chipMarkGlyph,
                style: TextStyle(fontSize: fs * MapStyle.chipMarkScale, color: p.chipMark),
              ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      chipW = chip.width + MapStyle.chipPad;
    }
    final h = fs + MapStyle.plateExtraHeight;
    final markW = p.mark == null ? 0.0 : MapStyle.chipGap + fs * MapStyle.markScale;
    final w = MapStyle.platePad * 2 + name.width + (chip == null ? 0 : MapStyle.chipGap + chipW) + markW;
    final rect = Rect.fromCenter(center: at, width: w, height: h);
    final chipRect = chip == null
        ? null
        : Rect.fromLTWH(rect.left + MapStyle.platePad + name.width + MapStyle.chipGap, rect.top + MapStyle.chipInset,
            chipW, h - MapStyle.chipInset * 2);
    return _PlateGeometry(p, rect, name, chip, chipRect);
  }

  void paint(Canvas canvas, double pixelRatio) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(MapStyle.plateRadius));
    canvas.drawRRect(rr, Paint()..color = plate.background);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = plate.emphasis ? MapStyle.plateStrokeCurrent : MapStyle.plateStroke
      ..color = Palette.ink;
    canvas.drawPath(
        plate.dashed ? Dashes.of(Path()..addRRect(rr), MapStyle.plateDash) : (Path()..addRRect(rr)), border);
    name.paint(canvas, Offset(rect.left + MapStyle.platePad, rect.center.dy - name.height / 2));
    if (chip != null) {
      final cr = RRect.fromRectAndRadius(chipRect!, const Radius.circular(MapStyle.chipRadius));
      canvas.drawRRect(cr, Paint()..color = plate.chipBackground);
      canvas.drawRRect(
        cr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = MapStyle.chipStroke
          ..color = Palette.ink,
      );
      chip!.paint(canvas, chipRect!.center - Offset(chip!.width / 2, chip!.height / 2));
    }
    if (plate.mark case final mark?) {
      final side = plate.fontSize * MapStyle.markScale;
      final at = Offset(rect.right - MapStyle.platePad - side, rect.center.dy - side / 2);
      VectorPainter.paint(canvas, mark, at & Size.square(side), pixelRatio: pixelRatio);
    }
  }
}

class _TidePainter extends CustomPainter {
  _TidePainter(this.spec, this.tide, this.still, this.color) : super(repaint: tide);
  final _MapSpec spec;
  final Animation<double> tide;
  final Color color;

  /// Draw one resting ring instead of animating (reduced motion).
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    spec.transform(size).apply(canvas);
    for (final isl in spec.islands) {
      if (!spec.styles[isl.index].pulse) continue;
      final r = _MapSpec.ringRadius(isl);
      if (still) {
        _ring(canvas, isl.center, r, 1, 1);
        continue;
      }
      for (final phase in const [0.0, 0.5]) {
        final p = ((tide.value + phase) % 1) / Tide.fadeEnd;
        if (p >= 1) continue;
        final e = Tide.curve.transform(p);
        _ring(canvas, isl.center, r, Tide.scaleFrom + (Tide.scaleTo - Tide.scaleFrom) * e, 1 - e);
      }
    }
  }

  void _ring(Canvas canvas, Offset c, double r, double scale, double opacity) {
    canvas.drawCircle(
      c,
      r * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Tide.stroke * scale
        ..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_TidePainter old) => old.spec != spec || old.still != still || old.color != color;
}
