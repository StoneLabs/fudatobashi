import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';
import '../rank/rank_badges.dart';
import 'celebration_chrome.dart';
import 'celebrations.dart';

/// The stretch of the rating ladder the rating page shows: the class a run
/// started in, from its threshold ([floor]) up to the next class's
/// ([ceiling], the gate).
class RatingTrack {
  factory RatingTrack.of(double before, double after) {
    final band = Rating.bandOf(before);
    final next = Rating.nextBand(before);
    final floor =
        band.minRating.isFinite ? band.minRating : math.min(before, next!.minRating - RatingScreenTuning.openSpan);
    final ceiling = next?.minRating ?? math.max(after, floor + RatingScreenTuning.openSpan);
    return RatingTrack._(band, next, floor, ceiling);
  }

  const RatingTrack._(this.band, this.next, this.floor, this.ceiling);

  final RankBand band;

  /// The class behind the gate; null at the top of the ladder, which has
  /// no gate.
  final RankBand? next;
  final double floor, ceiling;

  /// Where [rating] sits on the track, 0 at the floor to 1 at the ceiling.
  double fractionOf(double rating) => ((rating - floor) / (ceiling - floor)).clamp(0.0, 1.0);
}

/// When the rating page's needle climbs and what it reads: up the track to
/// the new rating, or, when the run ranks up, to the gate, where it strains,
/// hangs in silence and breaks through.
class RatingTimeline {
  RatingTimeline(this.data) : track = RatingTrack.of(data.before, data.after);

  final RatingCelebration data;
  final RatingTrack track;

  bool get ranksUp => data.ranksUp;

  /// Where the needle stops: the new rating, or the gate.
  double get target => ranksUp ? track.ceiling : data.after;

  int get gain => data.after.round() - data.before.round();

  Duration get climbEnd => RatingMotion.climbAt + (ranksUp ? RatingMotion.climbToGate : RatingMotion.climb);
  Duration get strainEnd => climbEnd + RatingMotion.strain;
  Duration get breakAt => strainEnd + RatingMotion.hush;

  /// When a breakthrough hands over to the rank-up: at the peak of the flash.
  Duration get cutAt => breakAt + RatingMotion.flashAt + RatingMotion.flashIn + RatingMotion.flashHold;
  Duration get length => ranksUp ? cutAt : climbEnd + RatingMotion.actionsAfter + RatingMotion.actions;

  /// The landing, or the break: where the page jolts.
  Duration get impactAt => ranksUp ? breakAt : climbEnd;

  /// The strain against the gate, eased by [curve].
  EntranceSpec strain({Curve curve = Curves.linear}) =>
      EntranceSpec(Entrances.custom, duration: RatingMotion.strain, delay: climbEnd, curve: curve);

  double ratingAt(Duration elapsed) {
    final climb = (climbEnd - RatingMotion.climbAt).inMicroseconds;
    final t = ((elapsed - RatingMotion.climbAt).inMicroseconds / climb).clamp(0.0, 1.0);
    return lerpDouble(data.before, target, RatingMotion.climbCurve.transform(t))!;
  }

  /// The number on the needle's tag.
  int shownAt(Duration elapsed) => ratingAt(elapsed).round();

  /// Points left to the next class; null at the top of the ladder.
  int? toNextAt(Duration elapsed) {
    final next = track.next;
    return next == null ? null : math.max(0, (next.minRating - ratingAt(elapsed)).ceil());
  }

  /// A ratchet click each time the number goes up, then a jingle as it
  /// lands; or heartbeats against the gate, silence, and the break.
  List<(Sfx, Duration)> get sounds {
    final clicks = <Duration>[];
    for (var value = data.before.round() + 1; value <= target.round(); value++) {
      final at = _reaching(value);
      if (clicks.isEmpty || at - clicks.last >= RatingMotion.tickStep) clicks.add(at);
    }
    return [
      for (final at in clicks) (Sfx.ratingTick, at),
      if (ranksUp) ...[
        for (final beat in RatingMotion.beats) (Sfx.ratingStrain, climbEnd + beat),
        (Sfx.ratingBreak, breakAt),
      ] else
        (Sfx.ratingUp, climbEnd),
    ];
  }

  Duration _reaching(int value) {
    var lo = RatingMotion.climbAt, hi = climbEnd;
    while (hi - lo > const Duration(milliseconds: 1)) {
      final mid = lo + (hi - lo) ~/ 2;
      if (shownAt(mid) >= value) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }
}

/// The rating page (実力UP!!), when a run raised the rating: the class's
/// track stands as a segmented power gauge capped by the next class's gate,
/// and a needle carries the counting rating up it. It lands with the gain
/// and what's left to the next class; or, on a rank-up, it strains against
/// the gate while the page darkens and rumbles, a beat of silence hangs
/// (…!?), and it breaks through, flashing into the rank-up page.
class RatingOverlay extends StatefulWidget {
  const RatingOverlay({super.key, required this.data, required this.onNext});
  final RatingCelebration data;
  final VoidCallback onNext;

  @override
  State<RatingOverlay> createState() => _RatingOverlayState();
}

class _RatingOverlayState extends State<RatingOverlay> {
  RatingTimeline get _timeline => RatingTimeline(widget.data);
  Timer? _breakthrough;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // At rest under reduced motion, the player taps on instead.
    if (_timeline.ranksUp && _breakthrough == null && !MediaQuery.disableAnimationsOf(context)) {
      _breakthrough = Timer(_timeline.cutAt, widget.onNext);
    }
  }

  @override
  void dispose() {
    _breakthrough?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = _timeline;
    final still = MediaQuery.disableAnimationsOf(context);
    return EntranceStage(
      length: t.length,
      child: Stack(fit: StackFit.expand, children: [
        CelebrationChrome(
          color: RatingLayout.color,
          onNext: widget.onNext,
          art: const [
            RadialLayer(center: RatingLayout.glowAt, colors: RatingLayout.glowColors, stops: RatingLayout.glowStops),
            ToneLayer(RatingLayout.tone, fadeAngle: RatingLayout.toneAngle, fadeStops: RatingLayout.toneStops),
          ],
          backdrop: [
            const RotatedBox(quarterTurns: 1, child: StaticArt([SpeedLinesLayer(RatingLayout.streaks)])),
            if (t.ranksUp) ...[
              _Darkness(t),
              _RumbleLettering(t, alignment: Alignment(-1, RatingLayout.rumbleAt.y), seed: RatingLayout.rumbleSeedLeft),
              _RumbleLettering(t, alignment: Alignment(1, RatingLayout.rumbleAt.y), seed: RatingLayout.rumbleSeedRight),
            ],
          ],
          child: _Rumble(
            t,
            child: Jolt(
              _at(t.impactAt, RatingMotion.jolt),
              reach: RatingMotion.joltReach,
              steps: RatingMotion.joltSteps,
              seed: RatingMotion.joltSeed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: RatingLayout.topGap),
                  _Dimmed(t, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Entrance(
                      RatingMotion.title,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: OutlinedText(
                          RatingLayout.title,
                          style: TextStyle(
                              fontFamily: Fonts.display, fontSize: RatingLayout.titleFont, color: Palette.sun, height: 1),
                          outline: Palette.ink,
                          outlineWidth: RatingLayout.titleOutline,
                        ),
                      ),
                    ),
                    Entrance(
                      RatingMotion.band,
                      child: CelebrationBand(s.ratingBand,
                          inset: RatingLayout.bandInset,
                          fontSize: RatingLayout.bandFont,
                          tracking: RatingLayout.bandTracking,
                          padding: RatingLayout.bandPadding,
                          turnDeg: RatingLayout.bandTurnDeg),
                    ),
                  ])),
                  const SizedBox(height: RatingLayout.gaugeGap),
                  Expanded(child: Entrance(RatingMotion.gauge, child: _Gauge(t))),
                  const SizedBox(height: RatingLayout.stripGap),
                  Entrance(RatingMotion.strip, child: _ToNext(t)),
                  if (!t.ranksUp || still) ...[
                    const SizedBox(height: RatingLayout.stripGap),
                    Entrance(
                      _pop(t.climbEnd + RatingMotion.actionsAfter, RatingMotion.actions, curve: Entrances.springy),
                      child: CelebrationCta(
                        label: s.ratingCta,
                        sub: s.other.ratingCta,
                        onTap: widget.onNext,
                        height: RatingLayout.actionHeight,
                        fontSize: RatingLayout.ctaFont,
                        subFontSize: RatingLayout.ctaSubFont,
                      ),
                    ),
                  ],
                  const SizedBox(height: Gaps.section),
                ]),
              ),
            ),
          ),
        ),
        if (t.ranksUp && !still) _Flash(t),
      ]),
    );
  }
}

/// A custom-drawn stretch of [length] starting [delay] into the page.
EntranceSpec _at(Duration delay, Duration length, {Curve curve = Curves.linear}) =>
    EntranceSpec(Entrances.custom, duration: length, delay: delay, curve: curve);

EntranceSpec _pop(Duration delay, Duration length, {Curve curve = Entrances.bouncy}) =>
    EntranceSpec(Entrances.pop, duration: length, delay: delay, curve: curve);

/// A fresh random offset within ±[reach] px each [step] of [elapsed].
Offset _jitter(Duration elapsed, Duration step, int seed, double reach) {
  final r = SeededRandom(seed + elapsed.inMicroseconds ~/ step.inMicroseconds);
  return Offset(r.next() * 2 - 1, r.next() * 2 - 1) * reach;
}

/// The gauge: the next class over its gate on top, the tower of cells, the
/// current class below, the track's ends and the old rating on the left,
/// and the needle's tag climbing on the right.
class _Gauge extends StatelessWidget {
  const _Gauge(this.timeline);
  final RatingTimeline timeline;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final t = timeline;
        final track = t.track;
        final next = track.next;
        final centre = box.maxWidth * RatingLayout.towerAt;
        final tower = Rect.fromLTRB(centre - RatingLayout.towerWidth / 2, RatingLayout.topRoom,
            centre + RatingLayout.towerWidth / 2, box.maxHeight - RatingLayout.bottomRoom);
        final inner = tower.deflate(RatingLayout.towerPadding);
        double yOf(double rating) => inner.bottom - inner.height * track.fractionOf(rating);
        final beforeY = yOf(t.data.before);
        final leftOfTower = box.maxWidth - tower.left + RatingLayout.scaleGap;
        final landed = _at(t.climbEnd, RatingMotion.burst, curve: Curves.easeOut);
        final resting = t.ranksUp && MediaQuery.disableAnimationsOf(context);

        Widget onLeft(double y, Widget child) =>
            Positioned(right: leftOfTower, top: y, child: FractionalTranslation(translation: const Offset(0, -0.5), child: child));
        Widget centred({required double top, required Widget child, Alignment align = Alignment.topCenter}) =>
            Positioned(left: 0, width: 2 * centre, top: top, child: Align(alignment: align, child: child));

        return StageClock(
          length: t.length,
          builder: (context, at) {
            // At rest under reduced motion a rank-up holds the beat of
            // silence, the break left to the rank-up page.
            final elapsed = resting ? t.breakAt - const Duration(microseconds: 1) : at;
            final strain = t.ranksUp ? _progress(elapsed, t.climbEnd, RatingMotion.strain) : 0.0;
            final straining = strain > 0 && strain < 1;
            final push = straining
                ? strain * (0.5 + 0.5 * math.sin(2 * math.pi * elapsed.inMicroseconds / RatingMotion.strainPeriod.inMicroseconds))
                : (t.ranksUp && elapsed >= t.strainEnd ? 1.0 : 0.0);
            final shatter = t.ranksUp ? _progress(elapsed, t.breakAt, RatingMotion.shatter) : 0.0;
            final leap = Curves.easeOut.transform(t.ranksUp ? _progress(elapsed, t.breakAt, RatingMotion.leap) : 0);
            final climbing = elapsed > RatingMotion.climbAt && elapsed < t.climbEnd;
            // The cell at the needle flickers as it climbs and blinks
            // faster, overloaded, while it strains.
            final flicker = (climbing && elapsed.inMicroseconds ~/ RatingMotion.flicker.inMicroseconds % 2 == 0) ||
                (straining && elapsed.inMicroseconds ~/ RatingMotion.overload.inMicroseconds % 2 == 0);
            var needleY = yOf(t.ratingAt(elapsed)) - RatingLayout.strainPush * push - RatingLayout.leap * leap;
            if (straining) needleY += _jitter(elapsed, RatingMotion.rumbleStep, RatingLayout.rumbleSeed, RatingLayout.strainJitter).dy;
            final beat = _beatAt(elapsed);

            return Transform.scale(
              scale: 1 + RatingLayout.beatPulse * beat,
              child: Stack(clipBehavior: Clip.none, children: [
                if (t.ranksUp)
                  Positioned(
                    left: centre,
                    top: tower.top,
                    width: 0,
                    height: 0,
                    child: ImpactBurst(
                      _at(t.breakAt, RatingMotion.burst, curve: Curves.easeOut),
                      burst: RatingLayout.breakBurst,
                      size: RatingLayout.breakSize,
                      fromScale: RatingLayout.impactFromScale,
                      toScale: RatingLayout.impactToScale,
                    ),
                  ),
                centred(
                  top: 0,
                  align: Alignment.bottomCenter,
                  child: SizedBox(
                    height: RatingLayout.topRoom - RatingLayout.badgeGap,
                    child: Align(alignment: Alignment.bottomCenter, child: _EndBadge(next, big: true)),
                  ),
                ),
                Positioned.fromRect(
                  rect: tower,
                  child: CustomPaint(
                    painter: _TowerPainter(
                      lit: track.fractionOf(t.ratingAt(elapsed)),
                      before: track.fractionOf(t.data.before),
                      glow: flicker ? 1 : 0,
                      surge: t.ranksUp ? 0 : _progress(elapsed, t.climbEnd, RatingMotion.surge),
                      bow: RatingLayout.gateBow * push,
                      crack: ((strain - RatingLayout.crackFrom) / (1 - RatingLayout.crackFrom)).clamp(0.0, 1.0),
                      shatter: shatter,
                      gate: next != null,
                    ),
                  ),
                ),
                centred(top: tower.bottom + RatingLayout.badgeGap, child: _EndBadge(track.band, big: false)),
                if (next != null && (beforeY - inner.top).abs() > RatingLayout.scaleClear)
                  onLeft(inner.top, _ScaleLabel(track.ceiling.round())),
                if (track.band.minRating.isFinite && (inner.bottom - beforeY).abs() > RatingLayout.scaleClear)
                  onLeft(inner.bottom, _ScaleLabel(track.floor.round())),
                Positioned(
                  right: box.maxWidth - tower.left + RatingLayout.tickGap,
                  top: beforeY,
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: Entrance(RatingMotion.needle, child: _OldMark(t.data.before.round())),
                  ),
                ),
                Positioned(
                  left: tower.right + RatingLayout.needleGap,
                  right: 0,
                  top: needleY,
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Entrance(
                        RatingMotion.needle,
                        child: _Needle(t, value: t.shownAt(elapsed), landed: landed),
                      ),
                    ),
                  ),
                ),
                if (t.ranksUp && elapsed < t.breakAt)
                  Positioned(
                    left: tower.right + RatingLayout.hushAt.dx,
                    top: tower.top + RatingLayout.hushAt.dy,
                    child: Entrance(
                      _pop(t.strainEnd + RatingMotion.hushPop, RatingMotion.hushIn),
                      child: Transform.rotate(
                        angle: RatingLayout.hushTurnDeg * math.pi / 180,
                        child: const OutlinedText(
                          RatingLayout.hush,
                          style: TextStyle(
                              fontFamily: Fonts.display, fontSize: RatingLayout.hushFont, color: Palette.paper, height: 1),
                          outline: Palette.ink,
                          outlineWidth: RatingLayout.hushOutline,
                        ),
                      ),
                    ),
                  ),
                if (t.ranksUp && elapsed >= t.breakAt) ...[
                  centred(
                    top: 0,
                    child: Entrance(
                      _pop(t.breakAt, RatingMotion.sfx),
                      child: Transform.rotate(
                        angle: RatingLayout.breakSfxTurnDeg * math.pi / 180,
                        child: const SfxText(RatingLayout.breakSfx,
                            size: RatingLayout.breakSfxFont, seed: RatingLayout.breakSfxSeed, outline: NewCardLayout.sfxOutline),
                      ),
                    ),
                  ),
                ],
              ]),
            );
          },
        );
      });

  /// How far into the pulse of the latest heartbeat [elapsed] is, 1 → 0.
  double _beatAt(Duration elapsed) {
    if (!timeline.ranksUp) return 0;
    var pulse = 0.0;
    for (final beat in RatingMotion.beats) {
      final t = _progress(elapsed, timeline.climbEnd + beat, RatingMotion.beatPulse);
      if (t > 0 && t < 1) pulse = math.sin(math.pi * t);
    }
    return pulse;
  }
}

/// How far [elapsed] is into a stretch of [length] from [start], 0–1.
double _progress(Duration elapsed, Duration start, Duration length) =>
    ((elapsed - start).inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

/// A class badge at one end of the track, in its rung colour; the top of
/// the ladder (no next class) shows TOP CLASS instead.
class _EndBadge extends StatelessWidget {
  const _EndBadge(this.band, {required this.big});
  final RankBand? band;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final band = this.band;
    final font = big ? RatingLayout.nextBadgeFont : RatingLayout.bandBadgeFont;
    if (band == null) {
      return Sticker(
        tilt: 0,
        color: Palette.ink,
        padding: RankLayout.badgePadding,
        child: Text(S.of(context).topClassNote,
            style: const TextStyle(fontFamily: Fonts.display, fontSize: RatingLayout.bandBadgeFont, color: Palette.sun, height: 1)),
      );
    }
    final style = rungStyle(band.id);
    return ClassBadge(band,
        color: style.color,
        textColor: style.text,
        fontSize: font,
        suffixSize: big ? RatingLayout.nextBadgeSuffixFont : RatingLayout.bandBadgeSuffixFont);
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel(this.rating);
  final int rating;

  @override
  Widget build(BuildContext context) => Text('$rating',
      style: const TextStyle(fontFamily: Fonts.display, fontSize: RatingLayout.scaleFont, color: Palette.ink, height: 1));
}

/// Where the rating started: its number and a small arrow at the tower.
class _OldMark extends StatelessWidget {
  const _OldMark(this.rating);
  final int rating;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        DecoratedBox(
          decoration: const BoxDecoration(color: Palette.paper),
          child: Padding(
            padding: TagStyle.compactPadding,
            child: Text('$rating',
                style: const TextStyle(fontFamily: Fonts.display, fontSize: RatingLayout.oldFont, color: Palette.mute, height: 1)),
          ),
        ),
        const SizedBox(width: RatingLayout.oldArrowGap),
        CustomPaint(
          size: const Size(RatingLayout.oldArrow, RatingLayout.oldArrow * 1.4),
          painter: const _ArrowPainter(pointsLeft: false),
        ),
      ]);
}

/// The needle: an ink arrow at the tower and a paper tag with the rating
/// [value], keeping the widest number's size. It pulses as it lands, with a
/// burst, グンッ!! and the gain slapped onto its corner.
class _Needle extends StatelessWidget {
  const _Needle(this.timeline, {required this.value, required this.landed});
  final RatingTimeline timeline;
  final int value;
  final EntranceSpec landed;

  @override
  Widget build(BuildContext context) {
    final t = timeline;
    final numbers = ['${t.data.before.round()}', '${t.target.round()}'];
    final widest = numbers.reduce((a, b) => a.length >= b.length ? a : b);
    const style = TextStyle(fontFamily: Fonts.display, fontSize: RatingLayout.needleFont, color: Palette.ink, height: 1);
    final tag = Row(mainAxisSize: MainAxisSize.min, children: [
      CustomPaint(size: RatingLayout.needleArrow, painter: const _ArrowPainter(pointsLeft: true)),
      DecoratedBox(
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: RatingLayout.needleBorder)),
        child: Padding(
          padding: RatingLayout.needlePadding,
          child: Stack(alignment: Alignment.centerRight, children: [
            Opacity(opacity: 0, child: Text(widest, style: style)),
            Text('$value', style: style),
          ]),
        ),
      ),
    ]);
    if (t.ranksUp) return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: tag);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: ImpactBurst(
            landed,
            burst: RatingLayout.impactBurst,
            size: RatingLayout.impactSize,
            fromScale: RatingLayout.impactFromScale,
            toScale: RatingLayout.impactToScale,
          ),
        ),
        EntranceBuilder(
          _at(t.climbEnd, RatingMotion.landPulse),
          child: tag,
          builder: (context, p, child) => Transform.scale(scale: 1 + RatingLayout.landPulse * math.sin(math.pi * p), child: child),
        ),
        Positioned(
          left: RatingLayout.landSfxAt.dx,
          top: RatingLayout.landSfxAt.dy,
          child: Entrance(
            _pop(t.climbEnd, RatingMotion.sfx),
            child: Transform.rotate(
              angle: RatingLayout.landSfxTurnDeg * math.pi / 180,
              child: const SfxText(RatingLayout.landSfx,
                  size: RatingLayout.landSfxFont,
                  color: Palette.sun,
                  seed: RatingLayout.landSfxSeed,
                  outline: NewCardLayout.sfxOutline),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: -RatingLayout.gainDrop,
          child: Entrance(
            _pop(t.climbEnd + RatingMotion.gainAfter, RatingMotion.gain),
            child: Transform.rotate(
              angle: RatingLayout.gainTurnDeg * math.pi / 180,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: Strokes.button)),
                child: Padding(
                  padding: RatingLayout.gainPadding,
                  child: Text('+${t.gain}',
                      style: const TextStyle(fontFamily: Fonts.display, fontSize: RatingLayout.gainFont, height: 1.1)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A solid ink triangle filling its box, pointing left or right.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.pointsLeft});
  final bool pointsLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = pointsLeft ? 0.0 : size.width;
    final base = size.width - tip;
    canvas.drawPath(
      Path()
        ..moveTo(tip, size.height / 2)
        ..lineTo(base, 0)
        ..lineTo(base, size.height)
        ..close(),
      Paint()..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.pointsLeft != pointsLeft;
}

/// The points left to the next class, counting down as the needle climbs,
/// with Tobi at the strip's end: trying hard, then cheering, or shaking in
/// shock at the gate.
class _ToNext extends StatelessWidget {
  const _ToNext(this.timeline);
  final RatingTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline;
    final next = t.track.next;
    const text = TextStyle(fontWeight: Weights.black, fontSize: RatingLayout.stripFont);
    const number = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: RatingLayout.stripNumberFont);
    return Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: [
      MangaPanel(
        padding: RatingLayout.stripPadding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: next == null
              ? Text(s.topClassChase, style: text)
              : StageClock(
                  length: t.length,
                  builder: (context, elapsed) => NumberedText(
                    s.ratingToNext(next.label),
                    [t.toNextAt(elapsed)!],
                    style: text,
                    numberStyle: number.copyWith(color: t.toNextAt(elapsed) == 0 ? Palette.pinkDeep : null),
                  ),
                ),
        ),
      ),
      Placed(
        RatingLayout.tobi,
        child: StageClock(
          length: t.length,
          builder: (context, elapsed) {
            if (elapsed < t.climbEnd) return const Tobi(pose: TobiPose.tryHard);
            if (!t.ranksUp) {
              return Entrance(
                _pop(t.climbEnd, RatingMotion.tobi),
                child: const Hop(
                  height: RatingMotion.hopHeight,
                  period: RatingMotion.hopPeriod,
                  airShare: RatingMotion.hopAirShare,
                  child: Tobi(pose: TobiPose.cheering),
                ),
              );
            }
            return Transform.translate(
              offset: Offset(_jitter(elapsed, RatingMotion.rumbleStep, RatingLayout.rumbleSeed, RatingLayout.tobiTremble).dx, 0),
              child: const Tobi(pose: TobiPose.shocked),
            );
          },
        ),
      ),
    ]);
  }
}

/// Title and band fading back into the dark while the needle strains.
class _Dimmed extends StatelessWidget {
  const _Dimmed(this.timeline, {required this.child});
  final RatingTimeline timeline;
  final Widget child;

  @override
  Widget build(BuildContext context) => !timeline.ranksUp
      ? child
      : EntranceBuilder(
          timeline.strain(curve: RatingMotion.darken),
          child: child,
          builder: (context, t, child) => Opacity(opacity: lerpDouble(1, RatingLayout.dimTo, t)!, child: child),
        );
}

/// The page shaking harder and harder while the needle strains, and still
/// once it falls silent.
class _Rumble extends StatelessWidget {
  const _Rumble(this.timeline, {required this.child});
  final RatingTimeline timeline;
  final Widget child;

  @override
  Widget build(BuildContext context) => !timeline.ranksUp
      ? child
      : EntranceBuilder(
          timeline.strain(),
          child: child,
          builder: (context, t, child) => t <= 0 || t >= 1
              ? child!
              : Transform.translate(
                  offset: _jitter(RatingMotion.strain * t, RatingMotion.rumbleStep, RatingLayout.rumbleSeed, RatingLayout.rumbleReach * t),
                  child: child,
                ),
        );
}

/// The page darkening around the gauge as the needle strains.
class _Darkness extends StatelessWidget {
  const _Darkness(this.timeline);
  final RatingTimeline timeline;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: EntranceBuilder(
          timeline.strain(curve: RatingMotion.darken),
          builder: (context, t, _) => t <= 0
              ? const SizedBox.shrink()
              : ColoredBox(color: Palette.ink.withValues(alpha: RatingLayout.darkness * t)),
        ),
      );
}

/// ゴゴゴゴ rumbling down one side of the page while the needle strains.
class _RumbleLettering extends StatelessWidget {
  const _RumbleLettering(this.timeline, {required this.alignment, required this.seed});
  final RatingTimeline timeline;
  final Alignment alignment;
  final int seed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: RatingLayout.rumbleSide),
            child: EntranceBuilder(
              timeline.strain(),
              child: SfxText(RatingLayout.rumble,
                  size: RatingLayout.rumbleFont,
                  color: RatingLayout.rumbleColor,
                  seed: seed,
                  outline: NewCardLayout.sfxOutline,
                  vertical: true),
              builder: (context, t, child) => t <= 0 || t >= 1
                  ? const SizedBox.shrink()
                  : Transform.translate(
                      offset: _jitter(RatingMotion.strain * t, RatingMotion.rumbleStep, seed, RatingLayout.rumbleShake),
                      child: child,
                    ),
            ),
          ),
        ),
      );
}

/// The white flash of the breakthrough, covering everything as the page
/// cuts to the rank-up.
class _Flash extends StatelessWidget {
  const _Flash(this.timeline);
  final RatingTimeline timeline;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: EntranceBuilder(
          _at(timeline.breakAt + RatingMotion.flashAt, RatingMotion.flashIn),
          builder: (context, t, _) =>
              t <= 0 ? const SizedBox.shrink() : ColoredBox(color: RatingLayout.flash.withValues(alpha: t)),
        ),
      );
}

/// The tower: an ink column of cells lit up to [lit], cool at the bottom and
/// hot at the top, with the old rating marked at [before] and ticks at every
/// cell boundary; the gate across its top bows [bow] px and cracks under
/// the needle, and flies apart in shards as it [shatter]s (0 whole, 1 gone).
class _TowerPainter extends CustomPainter {
  const _TowerPainter({
    required this.lit,
    required this.before,
    required this.glow,
    required this.surge,
    required this.bow,
    required this.crack,
    required this.shatter,
    required this.gate,
  });

  final double lit, before;

  /// The flicker on the cell at the needle, 0–1.
  final double glow;

  /// How far a flash of light has run up the lit cells as the needle
  /// lands, 0–1 (none at either end).
  final double surge;
  final double bow, crack, shatter;
  final bool gate;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Offset.zero & size;
    canvas.drawRect(body, Paint()..color = Palette.ink);
    final inner = body.deflate(RatingLayout.towerPadding);
    const n = RatingLayout.cells;
    const gap = RatingLayout.cellGap;
    final cell = (inner.height - gap * (n - 1)) / n;
    final litTop = inner.bottom - inner.height * lit;
    final beforeY = inner.bottom - inner.height * before;
    for (var i = 0; i < n; i++) {
      final bottom = inner.bottom - i * (cell + gap);
      final rect = Rect.fromLTRB(inner.left, bottom - cell, inner.right, bottom);
      final color = _heat(i / (n - 1));
      canvas.drawRect(rect, Paint()..color = Color.lerp(Palette.ink, color, RatingLayout.cellOffTint)!);
      if (litTop >= rect.bottom) continue;
      final on = Rect.fromLTRB(rect.left, math.max(rect.top, litTop), rect.right, rect.bottom);
      canvas.drawRect(on, Paint()..color = color);
      if (on.top < beforeY) {
        final gained = Rect.fromLTRB(
            on.left, on.top, on.left + on.width * RatingLayout.gainSheenShare, math.min(on.bottom, beforeY));
        canvas.drawRect(gained, Paint()..color = RatingLayout.gainSheen);
      }
      if (glow > 0 && litTop >= rect.top) {
        canvas.drawRect(on, Paint()..color = Palette.paper.withValues(alpha: RatingLayout.tipGlow * glow));
      }
    }
    if (surge > 0 && surge < 1) {
      final y = inner.bottom - (inner.bottom - litTop) * surge;
      final band = Rect.fromLTRB(inner.left, math.max(litTop, y - RatingLayout.surgeHeight / 2), inner.right,
          math.min(inner.bottom, y + RatingLayout.surgeHeight / 2));
      canvas.drawRect(band, Paint()..color = Palette.paper.withValues(alpha: RatingLayout.surgeGlow * (1 - surge)));
    }
    if (before < lit) {
      canvas.drawLine(Offset(body.left, beforeY), Offset(body.right, beforeY),
          Paint()
            ..color = Palette.paper
            ..strokeWidth = RatingLayout.oldMarkStroke);
    }
    final tick = Paint()
      ..color = Palette.ink
      ..strokeWidth = RatingLayout.tickStroke;
    for (var i = 0; i <= n; i++) {
      final y = i == 0 ? inner.bottom : (i == n ? inner.top : inner.bottom - i * (cell + gap) + gap / 2);
      canvas.drawLine(Offset(-RatingLayout.tickGap - RatingLayout.tickLength, y), Offset(-RatingLayout.tickGap, y), tick);
    }
    if (!gate) return;
    if (shatter <= 0) {
      _gate(canvas, size);
    } else if (shatter < 1) {
      _shards(canvas, size);
    }
  }

  /// A colour of the cool-to-hot scale, [t] 0 (bottom) to 1 (top).
  static Color _heat(double t) {
    const colors = RatingLayout.cellColors;
    final at = t * (colors.length - 1);
    final i = math.min(at.floor(), colors.length - 2);
    return Color.lerp(colors[i], colors[i + 1], at - i)!;
  }

  void _gate(Canvas canvas, Size size) {
    const h = RatingLayout.gateHeight / 2;
    const left = -RatingLayout.gateOverhang;
    final right = size.width + RatingLayout.gateOverhang;
    final mid = size.width / 2;
    // A quadratic's control point at twice the bow lifts its middle by the bow.
    final bar = Path()
      ..moveTo(left, -h)
      ..quadraticBezierTo(mid, -h - 2 * bow, right, -h)
      ..lineTo(right, h)
      ..quadraticBezierTo(mid, h - 2 * bow, left, h)
      ..close();
    final bounds = bar.getBounds();
    canvas.save();
    canvas.clipPath(bar);
    canvas.drawRect(bounds, Paint()..color = Palette.sun);
    final stripes = Path();
    const w = RatingLayout.gateStripe;
    for (var x = bounds.left - bounds.height; x < bounds.right; x += 2 * w) {
      stripes
        ..moveTo(x, bounds.bottom)
        ..lineTo(x + bounds.height, bounds.top)
        ..lineTo(x + bounds.height + w, bounds.top)
        ..lineTo(x + w, bounds.bottom)
        ..close();
    }
    canvas.drawPath(stripes, Paint()..color = Palette.ink);
    canvas.restore();
    canvas.drawPath(
      bar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = RatingLayout.gateBorder
        ..color = Palette.ink,
    );
    if (crack > 0) _cracks(canvas, Offset(mid, -bow), size.width);
  }

  /// Jagged cracks spreading from the middle of the gate as it gives.
  void _cracks(Canvas canvas, Offset from, double width) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = RatingLayout.crackStroke
      ..strokeJoin = StrokeJoin.miter
      ..color = Palette.paper;
    final r = SeededRandom(RatingShards.seed);
    for (final side in [-1.0, 1.0, -0.4, 0.5]) {
      final path = Path()..moveTo(from.dx, from.dy);
      var p = from;
      for (var k = 0; k < 4; k++) {
        p += Offset(side * width * 0.16 * crack, (r.next() - 0.5) * RatingLayout.gateHeight * 1.2);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// The gate's shards, flying up and out, falling and fading.
  void _shards(Canvas canvas, Size size) {
    final age = shatter * RatingMotion.shatter.inMicroseconds / 1e6;
    final alpha = 1 - shatter;
    final span = size.width + 2 * RatingLayout.gateOverhang;
    for (var k = 0; k < RatingShards.count; k++) {
      final r = SeededRandom(RatingShards.seed + k);
      final origin = Offset(-RatingLayout.gateOverhang + span * (k + r.next()) / RatingShards.count, 0);
      final angle = (RatingShards.minAngle + r.next() * RatingShards.angleRange) * math.pi / 180;
      final speed = RatingShards.minSpeed + r.next() * RatingShards.speedRange;
      final side = RatingShards.minSize + r.next() * RatingShards.sizeRange;
      final c = origin +
          Offset(math.cos(angle), math.sin(angle)) * speed * age +
          Offset(0, RatingShards.gravity * age * age / 2);
      final turn = (r.next() - 0.5) * RatingShards.spin * age;
      final shard = Path();
      for (var i = 0; i < 3; i++) {
        final a = turn + i * 2 * math.pi / 3 + (r.next() - 0.5);
        final p = c + Offset(math.cos(a), math.sin(a)) * side / 2;
        i == 0 ? shard.moveTo(p.dx, p.dy) : shard.lineTo(p.dx, p.dy);
      }
      shard.close();
      final color = RatingShards.colors[k % RatingShards.colors.length];
      canvas.drawPath(shard, Paint()..color = color.withValues(alpha: alpha));
      canvas.drawPath(
        shard,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = RatingShards.stroke
          ..color = Palette.ink.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_TowerPainter old) =>
      old.lit != lit ||
      old.before != before ||
      old.glow != glow ||
      old.surge != surge ||
      old.bow != bow ||
      old.crack != crack ||
      old.shatter != shatter ||
      old.gate != gate;
}
