import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';

/// How 暗記練's torii stands: padlocked (also while its opening waits to be
/// shown), opening right now, or open.
enum GateState { locked, opening, open }

/// The dojo scene at the top of the Side Trips tab
/// (`research/design/sidetrips_b2.html`): sky and drifting clouds, the sea
/// with the ring of islands ([DojoRingLayout]) turned [turn] steps, the
/// torii, and Tobi's boat, under the tab's title. 暗記練's island carries
/// its banner once it is open; the islands still being built carry a
/// "coming soon" tag, shown in the two front slots.
///
/// The torii stands for the island in front: 暗記練's as [gate] says, a
/// padlocked one for any other. The boat drifts [boat] steps' worth. While
/// [fade] runs, the islands crossfade from the ring at step [fadeFrom].
///
/// It fills its box (the screen above the entries), scaled to the box's
/// width; the near swell crests just above its bottom. A box too short to
/// show the boat's hull above the swell lifts the scene, up to
/// [DojoSceneLayout.maxLift]; the sea paints on below the box.
class DojoScene extends StatefulWidget {
  const DojoScene({
    super.key,
    required this.turn,
    required this.boat,
    required this.fade,
    required this.fadeFrom,
    required this.gate,
    this.onOpened,
  });

  final Animation<double> turn, boat, fade;
  final int fadeFrom;
  final GateState gate;

  /// Called once the torii has finished opening.
  final VoidCallback? onOpened;

  @override
  State<DojoScene> createState() => _DojoSceneState();
}

class _DojoSceneState extends State<DojoScene> with SingleTickerProviderStateMixin {
  late final _unlock = AnimationController(vsync: this, duration: DojoUnlockMotion.unlock)..addListener(_onTick);
  bool _snapped = false;

  @override
  void initState() {
    super.initState();
    if (widget.gate == GateState.opening) WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(DojoScene old) {
    super.didUpdateWidget(old);
    if (widget.gate == GateState.opening && old.gate != GateState.opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    if (widget.gate == GateState.locked && old.gate != GateState.locked) {
      _unlock.value = 0;
      _snapped = false;
    }
  }

  @override
  void dispose() {
    _unlock.dispose();
    super.dispose();
  }

  void _open() {
    if (!mounted || _unlock.isAnimating || _unlock.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _unlock.value = 1;
      widget.onOpened?.call();
      return;
    }
    _unlock.forward().whenComplete(() => widget.onOpened?.call());
  }

  void _onTick() {
    if (!_snapped && _unlock.value >= DojoUnlockMotion.snapAt) _snap();
  }

  void _snap() {
    _snapped = true;
    playSound(context, Sfx.ratingBreak);
    if (ProgressScope.read(context).settings.haptics) HapticFeedback.heavyImpact();
    final s = S.of(context);
    MangaToast.show(context, s.tabUnlocked(s.ankirenName));
  }

  /// How far 暗記練's banner is up: 0 while its torii is padlocked, 1 open.
  double get _raised => switch (widget.gate) {
        GateState.locked => 0,
        GateState.open => 1,
        GateState.opening => _unlock.value < DojoUnlockMotion.snapAt
            ? 0
            : Curves.easeOut.transform((_unlock.value - DojoUnlockMotion.snapAt) / (1 - DojoUnlockMotion.snapAt)),
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final k = box.maxWidth / DojoSceneLayout.width;
        final swell = box.maxHeight - DojoSceneLayout.crest * k - DojoSceneLayout.crestGap;
        final lift = (DojoSceneLayout.foreground * k - swell - DojoSceneLayout.hullTrough * k)
            .clamp(0.0, DojoSceneLayout.maxLift * k);
        final frame = _Frame(k, lift);
        final boat = frame.at(DojoSceneLayout.boat.rect);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            frame.piece(DojoSceneLayout.sky),
            Positioned.fill(child: RepaintBoundary(child: _Clouds(k))),
            frame.piece(DojoSceneLayout.sea),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([widget.turn, widget.fade, _unlock]),
                builder: (context, _) => Stack(clipBehavior: Clip.none, children: _ring(frame)),
              ),
            ),
            Positioned.fromRect(
              rect: boat,
              child: AnimatedBuilder(
                animation: widget.boat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-widget.boat.value * DojoRingMotion.boatDrift * k, 0),
                  child: child,
                ),
                child: RepaintBoundary(
                  child: Sway(
                    turnDeg: DojoSceneLayout.boatTurnDeg,
                    lift: DojoSceneLayout.boatLift * k,
                    period: DojoSceneLayout.boatPeriod,
                    child: ScenePicture(DojoSceneLayout.boat.asset, size: boat.size),
                  ),
                ),
              ),
            ),
            Positioned(
              left: DojoSceneStyle.title.dx,
              top: MediaQuery.paddingOf(context).top + DojoSceneStyle.title.dy,
              child: const _Title(),
            ),
          ],
        );
      });

  /// The islands, back to front, then the torii and the islands' tags: the
  /// ring at [widget.turn], or while [widget.fade] runs, the ring at
  /// [widget.fadeFrom] fading out under it fading in.
  List<Widget> _ring(_Frame frame) {
    final fade = widget.fade.value;
    final turn = widget.turn.value;
    final shown = [
      if (fade < 1) (turn: widget.fadeFrom.toDouble(), opacity: 1 - fade, leaving: true),
      (turn: turn, opacity: fade, leaving: false),
    ];
    final front = SideTripRing.frontAt(fade < 1 / 2 ? widget.fadeFrom : turn.round());
    return [
      for (final ring in shown)
        for (final (isle, spec) in _placed(ring.turn))
          _Isle(isle, spec, frame, key: ValueKey((ring.leaving, isle)), opacity: ring.opacity, raised: _raised),
      _torii(frame, front == SideTripIsle.ankiren ? widget.gate : GateState.locked),
      for (final ring in shown)
        for (final (isle, spec) in _placed(ring.turn))
          if (_artOf(isle).tag case final tag? when spec.label * ring.opacity > 0)
            Positioned.fill(
              key: ValueKey((ring.leaving, isle, tag)),
              child: CustomSingleChildLayout(
                delegate: _TagAnchor(frame.onCanvas(spec, tag)),
                child: ExcludeSemantics(
                  child: Opacity(opacity: spec.label * ring.opacity, child: _SoonTag(S.of(context).sideTripsBuilding)),
                ),
              ),
            ),
    ];
  }

  /// Each island where the ring at [turn] puts it, deepest first.
  static List<(SideTripIsle, RingSlotSpec)> _placed(double turn) => [
        for (final isle in SideTripRing.isles) (isle, _specAt(SideTripRing.place(isle, turn))),
      ]..sort((a, b) => a.$2.depth.compareTo(b.$2.depth));

  /// The slot at [place] round the ring, or part of the way between two.
  static RingSlotSpec _specAt(double place) {
    const slots = DojoRingLayout.slots;
    final from = place.floor();
    return RingSlotSpec.lerp(slots[from % slots.length], slots[(from + 1) % slots.length], place - from);
  }

  /// The torii standing [state]: padlocked, opening (the padlocked one
  /// rattles, snaps and gives way to the open one popping in) or open,
  /// bobbing.
  Widget _torii(_Frame frame, GateState state) {
    final rect = frame.at(DojoSceneLayout.toriiOpen.rect);
    Widget picture(ScenePiece piece, {double opacity = 1, double scale = 1, Offset shift = Offset.zero}) =>
        Positioned.fromRect(
          rect: rect.shift(shift),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: ScenePicture(piece.asset, size: rect.size),
            ),
          ),
        );

    final t = _unlock.value;
    const snapAt = DojoUnlockMotion.snapAt;
    const pop = DojoUnlockMotion.pop;
    final children = switch (state) {
      GateState.locked => [picture(DojoSceneLayout.toriiLocked)],
      GateState.open => [
          Positioned.fromRect(
            rect: rect,
            child: RepaintBoundary(
              child: Sway(
                turnDeg: 0,
                lift: DojoSceneLayout.toriiLift * frame.k,
                period: DojoSceneLayout.toriiPeriod,
                child: ScenePicture(DojoSceneLayout.toriiOpen.asset, size: rect.size),
              ),
            ),
          ),
        ],
      GateState.opening when t < snapAt => [
          picture(DojoSceneLayout.toriiLocked,
              shift: Offset(
                  DojoUnlockMotion.rattle *
                      (t / snapAt) *
                      math.sin(2 * math.pi * DojoUnlockMotion.rattleHz * t * DojoUnlockMotion.unlock.inMicroseconds /
                          Duration.microsecondsPerSecond),
                  0)),
        ],
      // The padlocked torii is gone by halfway; the open one pops in.
      GateState.opening => [
          picture(DojoSceneLayout.toriiLocked, opacity: 1 - 2 * _raised, scale: 1 + pop * _raised),
          picture(DojoSceneLayout.toriiOpen, opacity: _raised, scale: 1 + pop * (1 - _raised)),
        ],
    };
    return Stack(key: const ValueKey('torii'), clipBehavior: Clip.none, children: children);
  }
}

/// [isle]'s pictures.
RingIsleArt _artOf(SideTripIsle isle) => switch (isle) {
      SideTripIsle.ankiren => DojoRingLayout.ankiren,
      SideTripIsle.building => DojoRingLayout.building,
      SideTripIsle.fuji => DojoRingLayout.fuji,
      SideTripIsle.lighthouse => DojoRingLayout.lighthouse,
    };

/// The scene's frame on screen: [k] dp a unit, lifted by [lift] dp.
class _Frame {
  const _Frame(this.k, this.lift);

  final double k, lift;

  Rect at(Rect r) => Rect.fromLTWH(r.left * k, r.top * k - lift, r.width * k, r.height * k);

  Widget piece(ScenePiece p) {
    final r = at(p.rect);
    return Positioned.fromRect(rect: r, child: ScenePicture(p.asset, size: r.size));
  }

  /// Where [spec] puts the island canvas's top left corner.
  Offset canvasAt(RingSlotSpec spec) => (spec.foot - DojoRingLayout.foot * spec.scale) * k - Offset(0, lift);

  /// Where [spec] puts the point [p] of the island canvas.
  Offset onCanvas(RingSlotSpec spec, Offset p) => canvasAt(spec) + p * spec.scale * k;
}

/// [isle] where [spec] puts it, [opacity] shown: its colour picture with
/// its haze one over it as far as the slot is hazy; 暗記練's island with
/// its banner, as far as it is [raised] and its slot shows labels.
class _Isle extends StatelessWidget {
  const _Isle(this.isle, this.spec, this.frame, {super.key, required this.opacity, required this.raised});

  final SideTripIsle isle;
  final RingSlotSpec spec;
  final _Frame frame;
  final double opacity, raised;

  @override
  Widget build(BuildContext context) {
    final k = frame.k;
    final art = _artOf(isle);
    final size = DojoRingLayout.canvas * k;
    final banner = isle == SideTripIsle.ankiren ? raised * spec.label : 0.0;
    final nobori = DojoRingLayout.nobori.rect;
    final at = frame.canvasAt(spec);
    return Positioned(
      left: 0,
      top: 0,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          transform: Matrix4.diagonal3Values(spec.scale, spec.scale, 1)..setTranslationRaw(at.dx, at.dy, 0),
          child: SizedBox.fromSize(
            size: size,
            child: Stack(clipBehavior: Clip.none, children: [
              if (spec.haze < 1) ScenePicture(art.colour, size: size),
              if (spec.haze > 0) Opacity(opacity: spec.haze, child: ScenePicture(art.haze, size: size)),
              if (banner > 0)
                Positioned.fromRect(
                  rect: Rect.fromLTWH(nobori.left * k, (nobori.top + DojoUnlockMotion.banner * (1 - raised)) * k,
                      nobori.width * k, nobori.height * k),
                  child: Opacity(
                    opacity: banner,
                    child: ScenePicture(DojoRingLayout.nobori.asset, size: nobori.size * k),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The clouds drifting across the sky, round and round; still under
/// reduced motion.
class _Clouds extends StatelessWidget {
  const _Clouds(this.k);

  final double k;

  @override
  Widget build(BuildContext context) => IdleLoop(
        step: DojoSceneLayout.cloudStep,
        builder: (context, elapsed, _) {
          final loop = (elapsed.inMicroseconds % DojoSceneLayout.cloudLoop.inMicroseconds) /
              DojoSceneLayout.cloudLoop.inMicroseconds;
          return Stack(clipBehavior: Clip.none, children: [
            for (final cloud in DojoSceneLayout.clouds)
              _cloud(cloud.piece.rect, cloud.piece.asset, loop * cloud.laps),
          ]);
        },
      );

  /// A cloud first at [rect], [laps] of the way round: across the frame
  /// and its own width, so it is gone on one side before it comes back on
  /// the other.
  Widget _cloud(Rect rect, String asset, double laps) {
    final span = DojoSceneLayout.width + rect.width;
    final left = (rect.left + rect.width + laps * span) % span - rect.width;
    final r = Rect.fromLTWH(left * k, rect.top * k, rect.width * k, rect.height * k);
    return Positioned.fromRect(rect: r, child: ScenePicture(asset, size: r.size));
  }
}

/// A picture of the scene at [size], decoded no bigger than it shows.
class ScenePicture extends StatelessWidget {
  const ScenePicture(this.asset, {super.key, required this.size});

  final String asset;
  final Size size;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size.width,
        height: size.height,
        fit: BoxFit.fill,
        cacheWidth: (size.width * MediaQuery.devicePixelRatioOf(context)).round(),
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );
}

/// 寄り道 lettered over the sky, with its banner.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      container: true,
      header: true,
      label: s.sideTrips,
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: SideTripsLayout.letteringMaxScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedText(
              s.sideTripsLettering,
              outlineWidth: DojoSceneStyle.titleOutline,
              style: const TextStyle(
                  fontFamily: Fonts.display, fontSize: DojoSceneStyle.titleFont, height: TypeScale.displayLineHeight),
            ),
            const SizedBox(height: DojoSceneStyle.titleBannerGap),
            InkBanner(s.sideTripsBanner, fontSize: DojoSceneStyle.titleBannerFont),
          ],
        ),
      ),
    );
  }
}

/// The "coming soon" tag of an island still being built: [label] and a
/// little ink chip saying soon in the other language, in a sun box. Like
/// the scene's lettering, it grows with the system text size only so far.
class _SoonTag extends StatelessWidget {
  const _SoonTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: SideTripsLayout.letteringMaxScale,
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: DojoSceneStyle.tagBorder)),
          child: Padding(
            padding: DojoSceneStyle.tagPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: Weights.black, fontSize: DojoSceneStyle.tagFont, height: DojoSceneStyle.tagLineHeight)),
                const SizedBox(width: DojoSceneStyle.chipGap),
                InkTag(
                  S.of(context).other.sideTripsSoon.toUpperCase(),
                  fontSize: DojoSceneStyle.chipFont,
                  tracking: DojoSceneStyle.chipTracking,
                  padding: DojoSceneStyle.chipPadding,
                ),
              ],
            ),
          ),
        ),
      );
}

/// Hangs a tag from its top left corner at [at], kept inside the screen's
/// gutters.
class _TagAnchor extends SingleChildLayoutDelegate {
  _TagAnchor(this.at);

  final Offset at;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(at.dx.clamp(Gaps.gutter, math.max(Gaps.gutter, size.width - Gaps.gutter - childSize.width)), at.dy);

  @override
  bool shouldRelayout(_TagAnchor old) => old.at != at;
}
