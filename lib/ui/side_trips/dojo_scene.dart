import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
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
/// (`research/design/sidetrips_b2.html`): sky and sea with the far isles,
/// 暗記練's island with its torii and banner, Tobi's boat and the near swell,
/// under the tab's title and the "coming soon" tags.
///
/// It fills its box (the screen above the entry), scaled to the box's
/// width. A box too short to show the boat clear of the entry lifts the
/// scene, up to [DojoSceneLayout.maxLift]; the sea and the near swell paint
/// on below the box, under the entry.
class DojoScene extends StatelessWidget {
  const DojoScene({super.key, required this.gate, required this.day, this.onOpened});

  final GateState gate;

  /// The day of the month: it picks the far isle on the left.
  final int day;

  /// Called once the torii has finished opening.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LayoutBuilder(builder: (context, box) {
      final k = box.maxWidth / DojoSceneLayout.width;
      final lift = (DojoSceneLayout.foreground * k - box.maxHeight).clamp(0.0, DojoSceneLayout.maxLift * k);
      Rect at(Rect r) => Rect.fromLTWH(r.left * k, r.top * k - lift, r.width * k, r.height * k);
      Widget piece(ScenePiece p, {Rect? rect}) {
        final r = rect ?? at(p.rect);
        return Positioned.fromRect(rect: r, child: ScenePicture(p.asset, size: r.size));
      }

      final near = at(DojoSceneLayout.seaNear.rect);
      final boat = at(DojoSceneLayout.boat.rect);
      const farLeft = DojoSceneLayout.farLeft;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          piece(DojoSceneLayout.sky),
          piece(farLeft[day % farLeft.length]),
          piece(DojoSceneLayout.fuji),
          piece(DojoSceneLayout.sea),
          piece(DojoSceneLayout.construction),
          piece(DojoSceneLayout.isle),
          Positioned.fill(
            child: _Gate(
              state: gate,
              torii: at(DojoSceneLayout.toriiOpen.rect),
              banner: at(DojoSceneLayout.nobori.rect),
              scale: k,
              onOpened: onOpened,
            ),
          ),
          Positioned.fromRect(
            rect: boat,
            child: RepaintBoundary(
              child: Sway(
                turnDeg: DojoSceneLayout.boatTurnDeg,
                lift: DojoSceneLayout.boatLift * k,
                period: DojoSceneLayout.boatPeriod,
                child: ScenePicture(DojoSceneLayout.boat.asset, size: boat.size),
              ),
            ),
          ),
          // The entry always floats on the swell.
          piece(DojoSceneLayout.seaNear, rect: near.shift(Offset(0, math.min(0.0, box.maxHeight - near.top)))),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _TagAnchor(DojoSceneLayout.mistTag * k - Offset(0, lift), hangs: false),
              child: _SoonTag(s.sideTripsMist),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _TagAnchor(DojoSceneLayout.buildingTag * k - Offset(0, lift), hangs: true),
              child: _SoonTag(s.sideTripsBuilding, solid: true),
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

/// A "coming soon" tag on the scene: [label] and a little ink chip saying
/// soon in the other language, in a dashed paper box, or a [solid] sun one.
/// Like the scene's lettering, it grows with the system text size only so
/// far.
class _SoonTag extends StatelessWidget {
  const _SoonTag(this.label, {this.solid = false});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: DojoSceneStyle.tagPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(
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
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SideTripsLayout.letteringMaxScale,
      child: solid
          ? DecoratedBox(
              decoration: BoxDecoration(
                  color: Palette.sun, border: Border.all(color: Palette.ink, width: DojoSceneStyle.tagBorder)),
              child: content,
            )
          : DashedBox(border: DojoSceneStyle.tagBorder, dash: DojoSceneStyle.tagDash, child: content),
    );
  }
}

/// Puts a tag's bottom left corner (or its top left, when it [hangs]) at
/// [at], kept inside the screen's gutters.
class _TagAnchor extends SingleChildLayoutDelegate {
  _TagAnchor(this.at, {required this.hangs});

  final Offset at;
  final bool hangs;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final room = math.max(Gaps.gutter, size.width - Gaps.gutter - childSize.width);
    return Offset(at.dx.clamp(Gaps.gutter, room), hangs ? at.dy : at.dy - childSize.height);
  }

  @override
  bool shouldRelayout(_TagAnchor old) => old.at != at || old.hangs != hangs;
}

/// 暗記練's torii at [torii], and once it is open its banner at [banner],
/// both on screen. Opening, the padlocked torii rattles, snaps (with the
/// tab chains' sound, a buzz and a toast) and gives way to the open one as
/// the banner rises; then [onOpened]. Under reduced motion it simply opens.
class _Gate extends StatefulWidget {
  const _Gate({required this.state, required this.torii, required this.banner, required this.scale, this.onOpened});

  final GateState state;
  final Rect torii, banner;

  /// The scene's scale, for the bob and the banner's rise.
  final double scale;
  final VoidCallback? onOpened;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> with SingleTickerProviderStateMixin {
  late final _unlock = AnimationController(vsync: this, duration: DojoUnlockMotion.unlock)..addListener(_onTick);
  bool _snapped = false;

  @override
  void initState() {
    super.initState();
    if (widget.state == GateState.opening) WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(_Gate old) {
    super.didUpdateWidget(old);
    if (widget.state == GateState.opening && old.state != GateState.opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    if (widget.state == GateState.locked && old.state != GateState.locked) {
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

  Widget _picture(ScenePiece piece, Rect rect, {double opacity = 1, double scale = 1, Offset shift = Offset.zero}) =>
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

  @override
  Widget build(BuildContext context) => switch (widget.state) {
        GateState.locked => Stack(clipBehavior: Clip.none, children: [
            _picture(DojoSceneLayout.toriiLocked, widget.torii),
          ]),
        GateState.open => Stack(clipBehavior: Clip.none, children: [
            _picture(DojoSceneLayout.nobori, widget.banner),
            Positioned.fromRect(
              rect: widget.torii,
              child: RepaintBoundary(
                child: Sway(
                  turnDeg: 0,
                  lift: DojoSceneLayout.toriiLift * widget.scale,
                  period: DojoSceneLayout.toriiPeriod,
                  child: ScenePicture(DojoSceneLayout.toriiOpen.asset, size: widget.torii.size),
                ),
              ),
            ),
          ]),
        GateState.opening => AnimatedBuilder(animation: _unlock, builder: (context, _) => _opening(_unlock.value)),
      };

  /// The opening [t] of the way through: the rattle, then the swap.
  Widget _opening(double t) {
    const snapAt = DojoUnlockMotion.snapAt;
    if (t < snapAt) {
      final seconds = t * DojoUnlockMotion.unlock.inMicroseconds / Duration.microsecondsPerSecond;
      final rattle = DojoUnlockMotion.rattle * (t / snapAt) * math.sin(2 * math.pi * DojoUnlockMotion.rattleHz * seconds);
      return Stack(clipBehavior: Clip.none, children: [
        _picture(DojoSceneLayout.toriiLocked, widget.torii, shift: Offset(rattle, 0)),
      ]);
    }
    final u = Curves.easeOut.transform((t - snapAt) / (1 - snapAt));
    const pop = DojoUnlockMotion.pop;
    return Stack(clipBehavior: Clip.none, children: [
      _picture(DojoSceneLayout.nobori, widget.banner,
          opacity: u, shift: Offset(0, DojoUnlockMotion.banner * widget.scale * (1 - u))),
      // The padlocked torii is gone by halfway; the open one pops in.
      _picture(DojoSceneLayout.toriiLocked, widget.torii, opacity: 1 - 2 * u, scale: 1 + pop * u),
      _picture(DojoSceneLayout.toriiOpen, widget.torii, opacity: u, scale: 1 + pop * (1 - u)),
    ]);
  }
}
