import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/rating.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';
import '../rank/rank_badges.dart';
import '../results/celebration_chrome.dart';
import '../results/celebrations.dart';
import '../side_trips/side_trip_entry.dart';

/// The stretch of the rating the flagpole stands for: from the threshold of
/// the lowest class it shows ([floor], at the foot) up to the next class's
/// ([ceiling], at the finial), crossed by the [lines] of the classes in
/// between.
class AnkirenRatingTrack {
  /// The classes from [low]'s up to [high]'s.
  factory AnkirenRatingTrack.span(double low, double high) {
    final bottom = Rating.bandOf(low);
    final next = Rating.nextBand(high);
    final floor = bottom.minRating.isFinite ? bottom.minRating : AnkirenRating.start;
    final ceiling = next?.minRating ?? math.max(high, Rating.bandOf(high).minRating + RatingScreenTuning.openSpan);
    return AnkirenRatingTrack._(floor, ceiling, next, [
      for (final b in Rating.bands)
        if (b.minRating > floor && b.minRating < ceiling) b,
    ]);
  }

  const AnkirenRatingTrack._(this.floor, this.ceiling, this.next, this.lines);

  final double floor, ceiling;

  /// The class at the finial; null at the top of the ladder.
  final RankBand? next;
  final List<RankBand> lines;

  /// Where [rating] sits on the pole, 0 at the foot to 1 at the finial.
  double fractionOf(double rating) => ((rating - floor) / (ceiling - floor)).clamp(0.0, 1.0);
}

/// When the 暗記練 rating page's flag moves and what the page reads: the
/// flag climbing or sinking to the new rating; on a breakthrough to the
/// finial, where it strains and flashes into the rank-up; during placement
/// a step up the veiled pole, and on its last game a drumroll, the reveal
/// and the rating counting up its class.
class AnkirenRatingTimeline {
  AnkirenRatingTimeline(this.data)
      : moment = data.moment,
        track = switch (data.moment) {
          AnkirenRatingMoment.rankDown => AnkirenRatingTrack.span(data.after, data.before),
          AnkirenRatingMoment.placing || AnkirenRatingMoment.placed => AnkirenRatingTrack.span(data.after, data.after),
          _ => AnkirenRatingTrack.span(data.before, data.before),
        };

  final AnkirenRatingCelebration data;
  final AnkirenRatingMoment moment;
  final AnkirenRatingTrack track;

  bool get placing => moment == AnkirenRatingMoment.placing;
  bool get reveals => moment == AnkirenRatingMoment.placed;
  bool get breaksThrough => moment == AnkirenRatingMoment.rankUp;
  bool get sinks => moment == AnkirenRatingMoment.down || moment == AnkirenRatingMoment.rankDown;

  /// A rise worth a jolt, a burst and confetti as it lands.
  bool get lands => moment == AnkirenRatingMoment.up || reveals;

  Duration get moveAt => AnkirenRatingMotion.moveAt;
  Duration get moveEnd =>
      moveAt +
      (breaksThrough
          ? AnkirenRatingMotion.climbToTop
          : sinks
              ? AnkirenRatingMotion.sink
              : AnkirenRatingMotion.climb);

  /// A breakthrough strains against the finial, then flashes into the
  /// rank-up at [cutAt].
  Duration get strainEnd => moveEnd + AnkirenRatingMotion.strain;
  Duration get cutAt => strainEnd + AnkirenRatingMotion.flashIn + AnkirenRatingMotion.flashHold;

  /// The last placement game: the drumroll, then the reveal and the count.
  Duration get revealAt => moveEnd + AnkirenRatingMotion.drumroll;
  Duration get countAt => revealAt + AnkirenRatingMotion.countAfter;
  Duration get countEnd => countAt + AnkirenRatingMotion.count;

  /// When the result lands: the change, the lettering, Tobi.
  Duration get landAt => reveals ? countEnd : moveEnd;
  Duration get length =>
      breaksThrough ? cutAt : landAt + AnkirenRatingMotion.actionsAfter + AnkirenRatingMotion.actions;

  /// The flag is veiled at [elapsed]: its class is not known yet.
  bool veiledAt(Duration elapsed) => placing || (reveals && elapsed < revealAt);

  /// The rating at [elapsed]: climbing or sinking to the new one (to the
  /// finial on a breakthrough), or after a reveal counting up from its
  /// class's threshold.
  double ratingAt(Duration elapsed) {
    if (reveals) {
      final t = AnkirenRatingMotion.countCurve.transform(_progress(elapsed, countAt, AnkirenRatingMotion.count));
      return lerpDouble(track.floor, data.after, t)!;
    }
    final curve = sinks ? AnkirenRatingMotion.sinkCurve : AnkirenRatingMotion.climbCurve;
    final t = curve.transform(_progress(elapsed, moveAt, moveEnd - moveAt));
    return lerpDouble(data.before, breaksThrough ? track.ceiling : data.after, t)!;
  }

  int shownAt(Duration elapsed) => ratingAt(elapsed).round();

  /// Where the flag is on the pole at [elapsed], 0 at the foot to 1 at the
  /// finial; veiled, a step of ランク判定 a game.
  double flagAt(Duration elapsed) {
    if (!veiledAt(elapsed)) return track.fractionOf(ratingAt(elapsed));
    final step = AnkirenRatingMotion.climbCurve.transform(_progress(elapsed, moveAt, moveEnd - moveAt));
    return (data.game - 1 + step) / AnkirenRatingModel.placementGames;
  }

  /// The class on the flag at [elapsed]; null while veiled.
  RankBand? flagBandAt(Duration elapsed) {
    if (veiledAt(elapsed)) return null;
    if (reveals) return Rating.bandOf(data.after);
    return Rating.bandOf(breaksThrough ? data.before : ratingAt(elapsed));
  }

  /// The class the rating is heading for at [elapsed]; null at the top.
  RankBand? nextAt(Duration elapsed) => breaksThrough ? track.next : Rating.nextBand(ratingAt(elapsed));

  int? toNextAt(Duration elapsed) {
    final next = nextAt(elapsed);
    return next == null ? null : math.max(0, (next.minRating - ratingAt(elapsed)).ceil());
  }

  /// A pop and a stamp for a placement slot, then the drumroll and the
  /// reveal's fanfare; a ratchet click each time the rating goes up, and a
  /// jingle as it lands, or heartbeats against the finial and the break;
  /// one soft flap for a rating that held or fell.
  List<(Sfx, Duration)> get sounds {
    const slot = [(Sfx.xpPop, AnkirenRatingMotion.slotAt), (Sfx.stamp, AnkirenRatingMotion.stampAt)];
    return switch (moment) {
      AnkirenRatingMoment.placing => slot,
      AnkirenRatingMoment.placed => [
          ...slot,
          for (final beat in AnkirenRatingMotion.beats) (Sfx.ratingStrain, moveEnd + beat),
          (Sfx.stamp, revealAt),
          (Sfx.rankUp, revealAt),
          for (final at in _clicks(countAt, countEnd)) (Sfx.ratingTick, at),
        ],
      AnkirenRatingMoment.up => [
          for (final at in _clicks(moveAt, moveEnd)) (Sfx.ratingTick, at),
          (Sfx.ratingUp, moveEnd),
        ],
      AnkirenRatingMoment.rankUp => [
          for (final at in _clicks(moveAt, moveEnd)) (Sfx.ratingTick, at),
          for (final beat in AnkirenRatingMotion.strainBeats) (Sfx.ratingStrain, moveEnd + beat),
          (Sfx.ratingBreak, strainEnd),
        ],
      AnkirenRatingMoment.held || AnkirenRatingMoment.down || AnkirenRatingMoment.rankDown => [
          (Sfx.ankirenFlip, moveEnd),
        ],
    };
  }

  /// When the shown rating first reaches each new value between [start] and
  /// [end], at most one a tick step apart.
  List<Duration> _clicks(Duration start, Duration end) {
    final clicks = <Duration>[];
    for (var value = shownAt(start) + 1; value <= shownAt(end); value++) {
      var lo = start, hi = end;
      while (hi - lo > const Duration(milliseconds: 1)) {
        final mid = lo + (hi - lo) ~/ 2;
        if (shownAt(mid) >= value) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      if (clicks.isEmpty || hi - clicks.last >= AnkirenRatingMotion.tickStep) clicks.add(hi);
    }
    return clicks;
  }
}

/// How far [elapsed] is into a stretch of [length] from [start], 0–1.
double _progress(Duration elapsed, Duration start, Duration length) =>
    ((elapsed - start).inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

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

/// 暗記練's rating page, after a ranked game: its rank flag is hoisted up a
/// flagpole that stands for the class, the foot its threshold and the
/// finial the next class's, while the rating counts from the old value to
/// the new. A rise lands with a jolt, バサッ!!, confetti and the gain; a
/// fall sinks gently on a calmer page (ドンマイ!), past a class line if it
/// must; a breakthrough strains against the finial and flashes into the
/// rank-up. During placement (ランク判定) the rating stays hidden: each game
/// stamps its slot and the veiled flag climbs a step, and the last one ends
/// in a drumroll and the reveal of the first class.
class AnkirenRatingOverlay extends StatefulWidget {
  const AnkirenRatingOverlay({super.key, required this.data, required this.onNext});
  final AnkirenRatingCelebration data;
  final VoidCallback onNext;

  @override
  State<AnkirenRatingOverlay> createState() => _AnkirenRatingOverlayState();
}

class _AnkirenRatingOverlayState extends State<AnkirenRatingOverlay> {
  late final _timeline = AnkirenRatingTimeline(widget.data);
  Timer? _breakthrough;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final frame in AnkirenRatingLayout.cloth) {
      unawaited(precacheImage(AssetImage(frame), context));
    }
    // At rest under reduced motion, the player taps on instead.
    if (_timeline.breaksThrough && _breakthrough == null && !MediaQuery.disableAnimationsOf(context)) {
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
    final calm = t.sinks;
    final (title, sun) = switch (t.moment) {
      AnkirenRatingMoment.up || AnkirenRatingMoment.rankUp => (AnkirenRatingLayout.titleUp, true),
      AnkirenRatingMoment.held => (AnkirenRatingLayout.titleHeld, true),
      AnkirenRatingMoment.down || AnkirenRatingMoment.rankDown => (AnkirenRatingLayout.titleDown, false),
      AnkirenRatingMoment.placing => (AnkirenRatingLayout.titlePlacing, false),
      AnkirenRatingMoment.placed => (AnkirenRatingLayout.titlePlaced, true),
    };
    final band = switch (t.moment) {
      AnkirenRatingMoment.placing => s.ankirenPlacement(t.data.game, AnkirenRatingModel.placementGames).toUpperCase(),
      AnkirenRatingMoment.placed => s.ankirenRankBand,
      _ => s.ankirenRatingBand,
    };
    final (cta, ctaSub) = switch (t.moment) {
      AnkirenRatingMoment.down || AnkirenRatingMoment.rankDown => (s.ankirenNextTime, s.other.ankirenNextTime),
      AnkirenRatingMoment.placing || AnkirenRatingMoment.held => (s.onward, s.other.onward),
      _ => (s.ratingCta, s.other.ratingCta),
    };
    final suspense = (t.reveals || t.breaksThrough) && !still;
    Widget page = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: AnkirenRatingLayout.topGap),
        _Dimmed(t, enabled: suspense, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Entrance(
            calm ? AnkirenRatingMotion.calmTitle : AnkirenRatingMotion.title,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OutlinedText(
                title,
                style: TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: AnkirenRatingLayout.titleFont,
                    color: sun ? Palette.sun : Palette.paper,
                    height: 1),
                outline: Palette.ink,
                outlineWidth: AnkirenRatingLayout.titleOutline,
              ),
            ),
          ),
          Entrance(
            AnkirenRatingMotion.band,
            child: CelebrationBand(band,
                inset: AnkirenRatingLayout.bandInset,
                fontSize: AnkirenRatingLayout.bandFont,
                tracking: AnkirenRatingLayout.bandTracking,
                padding: AnkirenRatingLayout.bandPadding,
                turnDeg: AnkirenRatingLayout.bandTurnDeg),
          ),
        ])),
        const SizedBox(height: AnkirenRatingLayout.headGap),
        Entrance(AnkirenRatingMotion.head, child: _Head(t)),
        const SizedBox(height: AnkirenRatingLayout.headGap),
        Expanded(child: Entrance(AnkirenRatingMotion.stage, child: _Stage(t))),
        const SizedBox(height: AnkirenRatingLayout.stripGap),
        Entrance(AnkirenRatingMotion.strip, child: _Strip(t)),
        if (!t.breaksThrough || still) ...[
          const SizedBox(height: AnkirenRatingLayout.stripGap),
          Entrance(
            _pop(t.landAt + AnkirenRatingMotion.actionsAfter, AnkirenRatingMotion.actions, curve: Entrances.springy),
            child: CelebrationCta(
              label: cta,
              sub: ctaSub,
              onTap: widget.onNext,
              height: AnkirenRatingLayout.actionHeight,
              fontSize: AnkirenRatingLayout.ctaFont,
              subFontSize: AnkirenRatingLayout.ctaSubFont,
            ),
          ),
        ],
        const SizedBox(height: Gaps.section),
      ]),
    );
    if (t.lands) {
      page = Jolt(
        _at(t.landAt, AnkirenRatingMotion.jolt),
        reach: AnkirenRatingMotion.joltReach,
        steps: AnkirenRatingMotion.joltSteps,
        seed: AnkirenRatingMotion.joltSeed,
        child: page,
      );
    }
    return EntranceStage(
      length: t.length,
      child: Stack(fit: StackFit.expand, children: [
        CelebrationChrome(
          color: calm ? AnkirenRatingLayout.calmColor : AnkirenRatingLayout.color,
          onNext: widget.onNext,
          art: calm
              ? const [
                  RadialLayer(
                      center: AnkirenRatingLayout.glowAt,
                      colors: AnkirenRatingLayout.calmGlowColors,
                      stops: AnkirenRatingLayout.glowStops),
                  ToneLayer(AnkirenRatingLayout.calmTone,
                      fadeAngle: AnkirenRatingLayout.toneAngle, fadeStops: AnkirenRatingLayout.toneStops),
                ]
              : const [
                  RadialLayer(
                      center: AnkirenRatingLayout.glowAt,
                      colors: AnkirenRatingLayout.glowColors,
                      stops: AnkirenRatingLayout.glowStops),
                  ToneLayer(AnkirenRatingLayout.tone,
                      fadeAngle: AnkirenRatingLayout.toneAngle, fadeStops: AnkirenRatingLayout.toneStops),
                ],
          backdrop: [
            if (!calm && !t.placing)
              const RotatedBox(quarterTurns: 1, child: StaticArt([SpeedLinesLayer(AnkirenRatingLayout.streaks)])),
            if (suspense) _Darkness(t),
            if (t.lands)
              EntranceBuilder(
                _at(t.reveals ? t.revealAt : t.landAt, AnkirenRatingMotion.burst),
                builder: (context, p, _) => p > 0 ? const ConfettiRain() : const SizedBox.shrink(),
              ),
          ],
          child: page,
        ),
        if (suspense) _Flash(t),
      ]),
    );
  }
}

/// [builder] with the page's time; under reduced motion a breakthrough
/// rests at the finial, the break left to the rank-up page.
class _Clock extends StatelessWidget {
  const _Clock(this.timeline, {required this.builder});
  final AnkirenRatingTimeline timeline;
  final Widget Function(BuildContext context, Duration elapsed) builder;

  @override
  Widget build(BuildContext context) {
    final rest = timeline.breaksThrough && MediaQuery.disableAnimationsOf(context);
    return StageClock(
      length: timeline.length,
      builder: (context, elapsed) => builder(context, rest ? timeline.moveEnd : elapsed),
    );
  }
}

/// Over the stage: the reading, or during placement the slots of ランク判定;
/// on the last placement game the slots give way to the reading as the
/// class shows.
class _Head extends StatelessWidget {
  const _Head(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final t = timeline;
    if (t.placing) return _Slots(t);
    if (!t.reveals) return _Reading(t);
    Widget fading(double opacity, Widget child) => Visibility(
          visible: opacity > 0,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Opacity(opacity: opacity, child: child),
        );
    return EntranceBuilder(
      _at(t.revealAt, AnkirenRatingMotion.flashOut),
      builder: (context, p, _) => Stack(alignment: Alignment.center, children: [
        fading(1 - p, _Slots(t)),
        fading(p, _Reading(t)),
      ]),
    );
  }
}

/// "1638 → 1651": the old rating, an arrow, and the new one counting in big
/// lettering from it, keeping the widest number's size. It pulses as it
/// lands, with a burst on a rise, and the change is slapped on its corner
/// (NEW for the first class; a breakthrough leaves it to the rank-up).
class _Reading extends StatelessWidget {
  const _Reading(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline;
    final from = t.reveals ? t.track.floor : t.data.before;
    final numbers = ['${from.round()}', '${t.data.after.round()}'];
    final widest = numbers.reduce((a, b) => a.length >= b.length ? a : b);
    const big = TextStyle(
        fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.readingFont, color: Palette.paper, height: 1);
    Widget lettering(String text) =>
        OutlinedText(text, style: big, outline: Palette.ink, outlineWidth: AnkirenRatingLayout.readingOutline);
    final tag = t.reveals
        ? InkTag(s.newBadge, fontSize: AnkirenRatingLayout.changeFont, color: Palette.pink, textColor: Palette.ink)
        : RatingChangeTag(t.data.after.round() - t.data.before.round(),
            fontSize: AnkirenRatingLayout.changeFont,
            padding: AnkirenRatingLayout.changePadding,
            border: Strokes.button);
    final pulse = t.sinks ? 0.0 : AnkirenRatingLayout.landPulse;
    final number = Stack(clipBehavior: Clip.none, children: [
      if (t.lands)
        Positioned.fill(
          child: ImpactBurst(
            _at(t.landAt, AnkirenRatingMotion.burst, curve: Curves.easeOut),
            burst: AnkirenRatingLayout.impactBurst,
            size: AnkirenRatingLayout.impactSize,
            fromScale: AnkirenRatingLayout.impactFromScale,
            toScale: AnkirenRatingLayout.impactToScale,
          ),
        ),
      EntranceBuilder(
        _at(t.landAt, AnkirenRatingMotion.landPulse),
        builder: (context, p, child) => Transform.scale(scale: 1 + pulse * math.sin(math.pi * p), child: child),
        child: Stack(alignment: Alignment.centerRight, children: [
          Opacity(opacity: 0, child: lettering(widest)),
          _Clock(t, builder: (context, elapsed) => lettering('${t.shownAt(elapsed)}')),
        ]),
      ),
    ]);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!t.reveals) ...[
              Center(
                child: Text('${t.data.before.round()}',
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.oldFont, height: 1)),
              ),
              const SizedBox(width: AnkirenRatingLayout.readingGap),
              const Center(
                child: Text('→',
                    style: TextStyle(fontWeight: Weights.black, fontSize: AnkirenRatingLayout.arrowFont, height: 1)),
              ),
              const SizedBox(width: AnkirenRatingLayout.readingGap),
            ],
            number,
            if (!t.breaksThrough)
              Align(
                alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: AnkirenRatingLayout.changeAt,
                  child: Entrance(
                    _pop(t.landAt + AnkirenRatingMotion.changeAfter, AnkirenRatingMotion.change,
                        curve: t.sinks ? Entrances.settle : Entrances.bouncy),
                    child: Transform.rotate(angle: AnkirenRatingLayout.changeTurnDeg * math.pi / 180, child: tag),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// ランク判定's games side by side: those played with their score, stamped
/// done (this game's popping in and stamped last), and those to come as
/// dashed slots, the next one marked.
class _Slots extends StatelessWidget {
  const _Slots(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scores = timeline.data.placementScores;
    final current = timeline.data.game - 1;
    String score(int i) => i < scores.length ? '${scores[i]}' : '—';
    return SizedBox(
      height: AnkirenRatingLayout.slotHeight,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < AnkirenRatingModel.placementGames; i++) ...[
          if (i > 0) const SizedBox(width: AnkirenRatingLayout.slotGap),
          Expanded(
            child: i > current
                ? _TodoSlot(s.ankirenSlot(i + 1), next: i == current + 1)
                : i < current
                    ? _PlayedSlot(label: s.ankirenSlot(i + 1), score: score(i))
                    : Entrance(
                        _pop(AnkirenRatingMotion.slotAt, AnkirenRatingMotion.slot),
                        child: _PlayedSlot(
                          label: s.ankirenSlot(i + 1),
                          score: score(i),
                          stamp: _pop(AnkirenRatingMotion.stampAt, AnkirenRatingMotion.stamp, curve: Entrances.springy),
                        ),
                      ),
          ),
        ],
      ]),
    );
  }
}

/// A placement game played: its label over its score, stamped done.
class _PlayedSlot extends StatelessWidget {
  const _PlayedSlot({required this.label, required this.score, this.stamp});
  final String label, score;

  /// When this game's stamp lands; null for one stamped before.
  final EntranceSpec? stamp;

  @override
  Widget build(BuildContext context) {
    final mark = ClearStamp(S.of(context).clearStamp);
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Palette.paper, border: Border.all(color: Palette.ink, width: AnkirenRatingLayout.slotBorder)),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: Weights.black,
                        fontSize: AnkirenRatingLayout.slotLabelFont,
                        letterSpacing: AnkirenRatingLayout.slotLabelTracking * AnkirenRatingLayout.slotLabelFont,
                        height: 1.2)),
                Text(score,
                    style: const TextStyle(
                        fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.slotScoreFont, height: 1.1)),
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        right: AnkirenRatingLayout.stampAt.dx,
        top: AnkirenRatingLayout.stampAt.dy,
        child: Transform.scale(
          scale: AnkirenRatingLayout.stampScale,
          alignment: Alignment.topRight,
          child: stamp == null ? mark : Entrance(stamp!, child: mark),
        ),
      ),
    ]);
  }
}

/// A placement game still to play: dashed, a question mark under its label
/// (NEXT for the next one).
class _TodoSlot extends StatelessWidget {
  const _TodoSlot(this.label, {required this.next});
  final String label;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const ink = AnkirenRatingLayout.slotInk;
    return DashedBox(
      ink: ink,
      border: AnkirenRatingLayout.slotBorder,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(next ? s.ankirenPlacementNext.toUpperCase() : label,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: AnkirenRatingLayout.slotLabelFont,
                    letterSpacing: AnkirenRatingLayout.slotLabelTracking * AnkirenRatingLayout.slotLabelFont,
                    color: ink,
                    height: 1.2)),
            const Text(AnkirenRatingLayout.veiled,
                style: TextStyle(
                    fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.slotTodoFont, color: ink, height: 1.1)),
          ]),
        ),
      ),
    );
  }
}

/// The flagpole and its flag. The pole's art is scaled to the stage's
/// height; left of it the scale (the class's ends, the old rating, the
/// lines of classes the flag passes, or during placement its three steps),
/// and the flag hoisted to the rating.
class _Stage extends StatelessWidget {
  const _Stage(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final t = timeline;
        final k = box.maxHeight / AnkirenRatingLayout.poleBox.height;
        final poleX = box.maxWidth * AnkirenRatingLayout.poleAt;
        const span = AnkirenRatingLayout.hoistLow - AnkirenRatingLayout.hoistHigh;
        final c = k * AnkirenRatingLayout.clothScale;
        double clothTop(double fraction) => (AnkirenRatingLayout.hoistLow - span * fraction) * k;
        double levelOf(double fraction) => clothTop(fraction) + AnkirenRatingLayout.bandTop * c;
        final cloth = AnkirenRatingLayout.clothBox * c;
        final clothLeft = poleX - AnkirenRatingLayout.clothPole * c;
        final scaleRight = box.maxWidth - poleX + AnkirenRatingLayout.poleWidth * k / 2;
        Widget onScale(double y, Widget child) => Positioned(
              right: scaleRight,
              top: y,
              child: FractionalTranslation(translation: const Offset(0, -0.5), child: child),
            );
        Widget popsAtReveal(Widget child) =>
            t.reveals ? Entrance(_pop(t.revealAt, AnkirenRatingMotion.change), child: child) : child;

        return _Clock(t, builder: (context, elapsed) {
          final veiled = t.veiledAt(elapsed);
          final strain = t.breaksThrough ? _progress(elapsed, t.moveEnd, AnkirenRatingMotion.strain) : 0.0;
          final flag = t.flagAt(elapsed);
          // Lettering over a flag high on the pole goes under it instead.
          final high = flag > AnkirenRatingLayout.sfxBelowFrom;
          var top = clothTop(flag);
          if (strain > 0 && strain < 1) {
            final period = AnkirenRatingMotion.strainPeriod.inMicroseconds;
            final push = strain * (0.5 + 0.5 * math.sin(2 * math.pi * elapsed.inMicroseconds / period));
            final shake = _jitter(elapsed, AnkirenRatingMotion.rumbleStep, AnkirenRatingLayout.rumbleSeed,
                AnkirenRatingLayout.strainJitter);
            top += shake.dy - AnkirenRatingLayout.strainPush * push;
          }
          return Transform.scale(
            scale: 1 + AnkirenRatingMotion.beatScale * _beatAt(elapsed),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: poleX - AnkirenRatingLayout.poleCentre * k,
                top: 0,
                width: AnkirenRatingLayout.poleBox.width * k,
                height: box.maxHeight,
                child: Image.asset(AnkirenRatingLayout.pole, fit: BoxFit.fill, excludeFromSemantics: true),
              ),
              if (veiled)
                for (var game = 1; game <= AnkirenRatingModel.placementGames; game++)
                  onScale(levelOf(game / AnkirenRatingModel.placementGames), _ScaleLabel('$game'))
              else
                Positioned.fill(
                  child: popsAtReveal(Stack(clipBehavior: Clip.none, children: _scale(onScale, levelOf, poleX))),
                ),
              if (t.reveals)
                Positioned(
                  left: clothLeft + cloth.width / 2,
                  top: top + cloth.height / 2,
                  width: 0,
                  height: 0,
                  child: ImpactBurst(
                    _at(t.revealAt, AnkirenRatingMotion.burst, curve: Curves.easeOut),
                    burst: AnkirenRatingLayout.revealBurst,
                    size: AnkirenRatingLayout.revealSize,
                    fromScale: AnkirenRatingLayout.revealFromScale,
                    toScale: AnkirenRatingLayout.revealToScale,
                  ),
                ),
              Positioned(
                left: clothLeft,
                top: top,
                width: cloth.width,
                height: cloth.height,
                child: _Cloth(t.flagBandAt(elapsed), turning: t.reveals ? _turnAt(elapsed) : 0),
              ),
              if (t.reveals)
                Positioned(
                  left: clothLeft + cloth.width * AnkirenRatingLayout.revealSfxAt,
                  top: high ? top + cloth.height : top,
                  child: FractionalTranslation(
                    translation: Offset(-0.5, high ? 0 : -1),
                    child: Entrance(
                      _pop(t.revealAt, AnkirenRatingMotion.sfx),
                      child: Transform.rotate(
                        angle: AnkirenRatingLayout.revealSfxTurnDeg * math.pi / 180,
                        child: const SfxText(AnkirenRatingLayout.revealSfx,
                            size: AnkirenRatingLayout.revealSfxFont,
                            color: Palette.sun,
                            seed: AnkirenRatingLayout.revealSfxSeed,
                            outline: NewCardLayout.sfxOutline),
                      ),
                    ),
                  ),
                )
              else if (t.lands)
                Positioned(
                  right: math.max(0.0, box.maxWidth - clothLeft - cloth.width) + AnkirenRatingLayout.landSfxAt.dx,
                  top: high ? top + cloth.height : top + AnkirenRatingLayout.landSfxAt.dy,
                  child: Entrance(
                    _pop(t.landAt, AnkirenRatingMotion.sfx),
                    child: Transform.rotate(
                      angle: AnkirenRatingLayout.landSfxTurnDeg * math.pi / 180,
                      child: const SfxText(AnkirenRatingLayout.landSfx,
                          size: AnkirenRatingLayout.landSfxFont,
                          seed: AnkirenRatingLayout.landSfxSeed,
                          outline: NewCardLayout.sfxOutline),
                    ),
                  ),
                ),
            ]),
          );
        });
      });

  /// The scale left of the pole: the lines of classes the flag sinks past,
  /// the old rating unless it comes close to one, and the class's ends
  /// unless they come close to either.
  List<Widget> _scale(
    Widget Function(double y, Widget child) onScale,
    double Function(double fraction) levelOf,
    double poleX,
  ) {
    final t = timeline;
    final track = t.track;
    final lines = [for (final line in track.lines) (levelOf(track.fractionOf(line.minRating)), line)];
    final taken = [for (final (y, _) in lines) y];
    bool free(double y) => taken.every((at) => (y - at).abs() > AnkirenRatingLayout.scaleClear);
    final oldY = levelOf(track.fractionOf(t.data.before));
    final marked = !t.reveals && t.moment != AnkirenRatingMoment.held && free(oldY);
    if (marked) taken.add(oldY);
    return [
      if (free(levelOf(1))) onScale(levelOf(1), _ScaleLabel('${track.ceiling.round()}')),
      if (free(levelOf(0))) onScale(levelOf(0), _ScaleLabel('${track.floor.round()}')),
      for (final (y, line) in lines) ...[
        Positioned(
          left: poleX - AnkirenRatingLayout.lineReach,
          width: 2 * AnkirenRatingLayout.lineReach,
          top: y,
          child: const FractionalTranslation(translation: Offset(0, -0.5), child: _ClassLine()),
        ),
        onScale(y, _LineBadge(line)),
      ],
      if (marked) onScale(oldY, _OldMark(t.data.before.round())),
    ];
  }

  /// How far the veiled flag has turned over at the reveal: 0 face on, 1
  /// edge on (at the flash's peak, where it changes), back to 0.
  double _turnAt(Duration elapsed) {
    final half = AnkirenRatingMotion.flashIn + AnkirenRatingMotion.flashHold;
    final p = _progress(elapsed, timeline.revealAt - half, half * 2);
    return p <= 0 || p >= 1 ? 0 : 1 - (2 * p - 1).abs();
  }

  /// How far into the pulse of the latest heartbeat [elapsed] is, 1 → 0.
  double _beatAt(Duration elapsed) {
    final t = timeline;
    final beats = t.reveals
        ? AnkirenRatingMotion.beats
        : t.breaksThrough
            ? AnkirenRatingMotion.strainBeats
            : const <Duration>[];
    var pulse = 0.0;
    for (final beat in beats) {
      final p = _progress(elapsed, t.moveEnd + beat, AnkirenRatingMotion.beatPulse);
      if (p > 0 && p < 1) pulse = math.sin(math.pi * p);
    }
    return pulse;
  }
}

/// The flag's cloth, fluttering through its frames, the class written on
/// it ("F上" big, "級" small); veiled, drained of colour with a question
/// mark. A new class fades in over the old as the flag sinks past its line.
/// [turning] squeezes it edge on (1) about its hoist.
class _Cloth extends StatelessWidget {
  const _Cloth(this.band, {required this.turning});
  final RankBand? band;
  final double turning;

  @override
  Widget build(BuildContext context) {
    final band = this.band;
    const frames = AnkirenRatingLayout.cloth;
    final step = AnkirenRatingMotion.flutter.inMicroseconds;
    Widget cloth = IdleLoop(
      step: AnkirenRatingMotion.flutter,
      builder: (context, elapsed, _) => Image.asset(
        frames[elapsed.inMicroseconds ~/ step % frames.length],
        fit: BoxFit.fill,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
    if (band == null) {
      cloth = ColorFiltered(colorFilter: const ColorFilter.matrix(AnkirenRatingLayout.veil), child: cloth);
    }
    const style = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.clothFont, height: 1);
    final text = band == null
        ? const Text(AnkirenRatingLayout.veiled, key: ValueKey(AnkirenRatingLayout.veiled), style: style)
        : Text.rich(
            key: ValueKey(band.id),
            TextSpan(children: [
              TextSpan(text: band.stem),
              if (band.stem != band.label)
                const TextSpan(
                    text: RankBand.classSuffix, style: TextStyle(fontSize: AnkirenRatingLayout.clothSuffixFont)),
            ]),
            style: style,
          );
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.diagonal3Values(math.cos(turning * math.pi / 2), 1, 1),
      child: LayoutBuilder(builder: (context, box) {
        final scale = box.maxWidth / AnkirenRatingLayout.clothBox.width;
        const field = AnkirenRatingLayout.clothText;
        return Stack(fit: StackFit.expand, children: [
          cloth,
          Positioned(
            left: field.left * scale,
            top: field.top * scale,
            width: field.width * scale,
            height: field.height * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedSwitcher(duration: AnkirenRatingMotion.relabel, child: text),
            ),
          ),
        ]);
      }),
    );
  }
}

/// A number on the scale left of the pole, with a tick toward the pole.
class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(text,
            style: const TextStyle(
                fontFamily: Fonts.display, fontSize: AnkirenRatingLayout.scaleFont, color: Palette.ink, height: 1)),
        const SizedBox(width: AnkirenRatingLayout.oldArrowGap),
        const SizedBox(
          width: AnkirenRatingLayout.tickLength,
          height: AnkirenRatingLayout.tickStroke,
          child: ColoredBox(color: Palette.ink),
        ),
      ]);
}

/// Where the rating started: its number on paper and an arrow at the pole.
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
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: AnkirenRatingLayout.oldMarkFont,
                    color: Palette.mute,
                    height: 1)),
          ),
        ),
        const SizedBox(width: AnkirenRatingLayout.oldArrowGap),
        const Text('▶', style: TextStyle(fontSize: AnkirenRatingLayout.oldArrow, color: Palette.ink, height: 1)),
      ]);
}

/// A class's threshold where it crosses the pole: a dashed ink line.
class _ClassLine extends StatelessWidget {
  const _ClassLine();

  static const _dashes = AnkirenRatingLayout.lineReach ~/ AnkirenRatingLayout.lineDash;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < _dashes; i++) ...[
          if (i > 0) const SizedBox(width: AnkirenRatingLayout.lineDash),
          const SizedBox(
            width: AnkirenRatingLayout.lineDash,
            height: AnkirenRatingLayout.lineStroke,
            child: ColoredBox(color: Palette.ink),
          ),
        ],
      ]);
}

/// The class whose line crosses the pole, in its rung colours.
class _LineBadge extends StatelessWidget {
  const _LineBadge(this.band);
  final RankBand band;

  @override
  Widget build(BuildContext context) {
    final style = rungStyle(band.id);
    return ClassBadge(band,
        color: style.color,
        textColor: style.text,
        fontSize: AnkirenRatingLayout.lineBadgeFont,
        suffixSize: AnkirenRatingLayout.lineBadgeSuffixFont);
  }
}

/// Under the stage: the points left to the next class, counting down as
/// the flag climbs (or the placement games left, or the line before the
/// reveal), with Tobi at the strip's end: trying hard while the flag
/// climbs, then cheering a rise, waving at a rating that held, relaxed
/// after a fall; pointing at the pole during placement, shocked through
/// the drumroll and the strain.
class _Strip extends StatelessWidget {
  const _Strip(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline;
    const text = TextStyle(fontWeight: Weights.black, fontSize: AnkirenRatingLayout.stripFont);
    const number = TextStyle(
        fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: AnkirenRatingLayout.stripNumberFont);
    final left = AnkirenRatingModel.placementGames - t.data.game;
    return Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: [
      MangaPanel(
        padding: AnkirenRatingLayout.stripPadding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _Clock(t, builder: (context, elapsed) {
            if (t.placing) return NumberedText(s.ankirenPlacementLeft(left), [left], style: text, numberStyle: number);
            if (t.veiledAt(elapsed)) return Text(s.ankirenRankIs, style: text);
            final next = t.nextAt(elapsed);
            if (next == null) return Text(s.topClassChase, style: text);
            final points = t.toNextAt(elapsed)!;
            return NumberedText(
              s.ratingToNext(next.label),
              [points],
              style: text,
              numberStyle: number.copyWith(color: points == 0 ? Palette.pinkDeep : null),
            );
          }),
        ),
      ),
      Placed(
        AnkirenRatingLayout.tobi,
        child: _Clock(t, builder: (context, elapsed) {
          if (t.placing || (t.reveals && elapsed < t.moveEnd)) return const Tobi(pose: TobiPose.pointing);
          if (t.reveals && elapsed < t.revealAt) return const Tobi(pose: TobiPose.shocked);
          if (!t.reveals && elapsed < t.landAt) return Tobi(pose: t.sinks ? TobiPose.standard : TobiPose.tryHard);
          return switch (t.moment) {
            AnkirenRatingMoment.rankUp => const Tobi(pose: TobiPose.shocked),
            AnkirenRatingMoment.held => const Tobi(pose: TobiPose.waving),
            AnkirenRatingMoment.down || AnkirenRatingMoment.rankDown => const Tobi(pose: TobiPose.relaxed),
            _ => Entrance(
                _pop(t.landAt, AnkirenRatingMotion.tobi),
                child: const Hop(
                  height: AnkirenRatingMotion.hopHeight,
                  period: AnkirenRatingMotion.hopPeriod,
                  airShare: AnkirenRatingMotion.hopAirShare,
                  child: Tobi(pose: TobiPose.cheering),
                ),
              ),
          };
        }),
      ),
    ]);
  }
}

/// The stretch of suspense: the drumroll before a reveal, or the strain
/// against the finial.
EntranceSpec _suspense(AnkirenRatingTimeline t) => EntranceSpec(Entrances.custom,
    duration: t.reveals ? AnkirenRatingMotion.drumroll : AnkirenRatingMotion.strain,
    delay: t.moveEnd,
    curve: AnkirenRatingMotion.darken);

/// How dark the suspense has made the page at [elapsed], 0–1: it deepens
/// through the drumroll or the strain and lifts at a reveal.
double _darkAt(AnkirenRatingTimeline t, Duration elapsed) {
  if (t.reveals && elapsed >= t.revealAt) return 0;
  final p = _suspense(t);
  return p.curve.transform(_progress(elapsed, p.delay, p.duration));
}

/// The title and band dimming through the suspense, and back for a reveal.
class _Dimmed extends StatelessWidget {
  const _Dimmed(this.timeline, {required this.enabled, required this.child});
  final AnkirenRatingTimeline timeline;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => !enabled
      ? child
      : _Clock(
          timeline,
          builder: (context, elapsed) =>
              Opacity(opacity: lerpDouble(1, AnkirenRatingLayout.dimTo, _darkAt(timeline, elapsed))!, child: child),
        );
}

/// The page darkening around the flag through the suspense.
class _Darkness extends StatelessWidget {
  const _Darkness(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: _Clock(timeline, builder: (context, elapsed) {
          final d = _darkAt(timeline, elapsed);
          if (d <= 0) return const SizedBox.shrink();
          return ColoredBox(color: Palette.ink.withValues(alpha: AnkirenRatingLayout.darkness * d));
        }),
      );
}

/// The white flash: at the reveal it flares and fades, uncovering the
/// class; on a breakthrough it covers everything as the page cuts to the
/// rank-up.
class _Flash extends StatelessWidget {
  const _Flash(this.timeline);
  final AnkirenRatingTimeline timeline;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: _Clock(timeline, builder: (context, elapsed) {
          final t = timeline;
          const flashIn = AnkirenRatingMotion.flashIn;
          final peak = t.reveals ? t.revealAt : t.strainEnd + flashIn;
          final rise = _progress(elapsed, peak - flashIn, flashIn);
          final fall =
              t.reveals ? _progress(elapsed, peak + AnkirenRatingMotion.flashHold, AnkirenRatingMotion.flashOut) : 0.0;
          final a = rise * (1 - fall);
          return a <= 0 ? const SizedBox.shrink() : ColoredBox(color: AnkirenRatingLayout.flash.withValues(alpha: a));
        }),
      );
}
