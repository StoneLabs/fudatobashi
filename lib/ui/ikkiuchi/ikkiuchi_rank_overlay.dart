import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_mode.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/rank_ladder.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import '../results/celebration_chrome.dart';
import '../results/celebrations.dart';
import '../side_trips/ikkiuchi_mode_box.dart';
import '../side_trips/side_trip_entry.dart';
import 'ikkiuchi_rank_card.dart';
import 'ikkiuchi_rank_plot.dart';
import 'ikkiuchi_rank_timeline.dart';

/// [mode]'s own colours on its rank change page.
IkkiuchiRankTone ikkiuchiRankTone(IkkiuchiMode mode) => switch (mode) {
      IkkiuchiMode.bullet => IkkiuchiRankLayout.bullet,
      IkkiuchiMode.blitz => IkkiuchiRankLayout.blitz,
      IkkiuchiMode.rapid => IkkiuchiRankLayout.rapid,
    };

/// The rank change page after a ranked 一騎打ち match (mock B): one page for
/// the rating and the class. The match card (you and Tobi, who won, Tobi's
/// rating), then the mode's box from the 一騎打ち page (its tab, the class
/// badge, the rating and the way to the next class) with the mode's rating
/// curve, where this match's point is added: the points change hands
/// between Tobi's plate and the curve, and the point runs to its place over
/// the eased count while the rating counts and the bar fills. Crossing a
/// class line sets off the rank up (a strain in the dark, the break, the
/// impact frame where the old class is cut and the new one slams down) or
/// the rank down (the crack, ガーン!!, the class falling). While placing the
/// same room holds the placement chart, and the last placement match
/// reveals the first class. One button; a tap anywhere also goes on.
class IkkiuchiRankOverlay extends StatefulWidget {
  const IkkiuchiRankOverlay({super.key, required this.data, required this.onNext});

  final IkkiuchiRankCelebration data;
  final VoidCallback onNext;

  @override
  State<IkkiuchiRankOverlay> createState() => _IkkiuchiRankOverlayState();
}

/// The places on the page the effects over it follow.
class _Keys {
  final title = GlobalKey();
  final plate = GlobalKey();
  final box = GlobalKey();
  final slot = GlobalKey();
  final plot = GlobalKey();
}

class _IkkiuchiRankOverlayState extends State<IkkiuchiRankOverlay> {
  late final _timeline = IkkiuchiRankTimeline(widget.data);
  final _keys = _Keys();

  @override
  Widget build(BuildContext context) {
    final t = _timeline;
    final mode = t.change.mode;
    final tone = ikkiuchiModeTone(mode), own = ikkiuchiRankTone(mode);
    return EntranceStage(
      length: t.length,
      child: Stack(fit: StackFit.expand, children: [
        CelebrationChrome(
          color: tone.tone.background!,
          onNext: widget.onNext,
          art: [
            RadialLayer(
              center: IkkiuchiRankLayout.glowAt,
              colors: [own.glow, own.glow, own.glow.withValues(alpha: 0), own.glow.withValues(alpha: 0)],
              stops: IkkiuchiRankLayout.glowStops,
            ),
          ],
          backdrop: [
            GradationBox(GradationSpec(
              dot: tone.tone.dot,
              spacing: IkkiuchiRankLayout.groundSpacing,
              phase: IkkiuchiRankLayout.groundPhase,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              radii: IkkiuchiRankLayout.groundRadii,
              stops: IkkiuchiRankLayout.groundStops,
            )),
            if (!t.calm)
              RotatedBox(
                quarterTurns: 1,
                child: StaticArt([
                  SpeedLinesLayer(SpeedLinesSpec(
                      count: IkkiuchiRankLayout.streakCount,
                      seed: IkkiuchiRankLayout.streakSeed,
                      fromEdge: true,
                      color: own.streak)),
                ]),
              ),
            if (t.ranksDown)
              StageClock(
                length: t.length,
                builder: (context, e) => CustomPaint(
                  size: Size.infinite,
                  painter: GloomPainter(IkkiuchiRankLayout.gloom,
                      IkkiuchiRankMotion.gloomSteps.transform(progressIn(e, t.hitAt, IkkiuchiRankMotion.gloom))),
                ),
              ),
          ],
          child: StageClock(
            length: t.length,
            builder: (context, e) => _Page(t, e, keys: _keys, tone: tone, onNext: widget.onNext),
          ),
        ),
        IgnorePointer(
          child: StageClock(
            length: t.length,
            builder: (context, e) => _Effects(t, e, keys: _keys, tone: tone, own: own),
          ),
        ),
      ]),
    );
  }
}

/// [child] at [spec]'s eased progress [elapsed] into the page, turned and
/// scaled about [origin].
Widget _entered(Duration elapsed, EntranceSpec spec, Widget child, {Alignment origin = Alignment.center}) {
  final p = easedAt(elapsed, spec);
  final from = spec.from;
  final scale = lerpDouble(from.scale, 1, p)!;
  return Opacity(
    opacity: lerpDouble(from.opacity, 1, p / from.opaqueAt)!.clamp(0.0, 1.0),
    child: Transform(
      alignment: origin,
      transform: Matrix4.identity()
        ..translateByDouble(from.offset.dx * (1 - p), from.offset.dy * (1 - p), 0, 1)
        ..rotateZ(from.turnDeg * (1 - p) * math.pi / 180)
        ..scaleByDouble(scale, scale, 1, 1),
      child: child,
    ),
  );
}

/// The page's title lettering: [text] in [fill] on its ink outline.
Widget _title(String text, Color fill) => OutlinedText(
      text,
      style: TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiRankLayout.titleFont, color: fill, height: 1),
      outline: Palette.ink,
      outlineWidth: IkkiuchiRankLayout.titleOutline,
    );

/// The page's titles: the first slams in; a rank up and the first class
/// swap it for the second at the cut to the impact frame.
({String first, Color firstFill, String? second}) _titles(S s, IkkiuchiRankTimeline t) => switch (t.moment) {
      IkkiuchiRankMoment.up => (first: s.ikkiuchiRankRatingUp, firstFill: Palette.sun, second: null),
      IkkiuchiRankMoment.down ||
      IkkiuchiRankMoment.rankDown =>
        (first: s.ikkiuchiRankNextTimeTitle, firstFill: Palette.paper, second: null),
      IkkiuchiRankMoment.rankUp => (first: s.ikkiuchiRankRatingUp, firstFill: Palette.sun, second: s.ikkiuchiRankClassUp),
      IkkiuchiRankMoment.placing => (first: s.ikkiuchiRankPlacing, firstFill: Palette.paper, second: null),
      IkkiuchiRankMoment.placed => (first: s.ikkiuchiRankPlacing, firstFill: Palette.paper, second: s.ikkiuchiRankPlaced),
    };

/// The title's room: the lettering at the room's top, as tall as its
/// letters, shrinking to the width about a little under its middle.
class _TitleRoom extends StatelessWidget {
  const _TitleRoom({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.textScalerOf(context).scale(IkkiuchiRankLayout.titleRoom - IkkiuchiRankLayout.titleFont)),
        child: Align(alignment: IkkiuchiRankLayout.titleOrigin, child: child),
      );
}

/// The page at [elapsed]: the title, the match card, the mode's box and the
/// button, between the system bars.
class _Page extends StatelessWidget {
  const _Page(this.timeline, this.elapsed, {required this.keys, required this.tone, required this.onNext});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final _Keys keys;
  final IkkiuchiModeTone tone;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed;
    final scaler = MediaQuery.textScalerOf(context);
    final titles = _titles(s, t);
    final swapped = titles.second != null && e >= t.cutAt;
    final dimmed = t.placed && e >= t.suspenseAt && e < t.cutAt;
    final (cta, sub) = switch (t.moment) {
      IkkiuchiRankMoment.placing => (s.onward, s.sub?.onward),
      _ when t.won => (s.ratingCta, s.sub?.ratingCta),
      _ => (s.ikkiuchiRankNextTime, s.sub?.ikkiuchiRankNextTime),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: IkkiuchiRankLayout.topGap),
        SizedBox(
          key: keys.title,
          height: scaler.scale(IkkiuchiRankLayout.titleRoom),
          child: _TitleRoom(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: swapped
                  ? _title(titles.second!, Palette.sun)
                  : Opacity(
                      opacity: dimmed ? IkkiuchiRankLayout.hiddenTitle : 1,
                      child: _entered(e, IkkiuchiRankMotion.title, _title(titles.first, titles.firstFill),
                          origin: IkkiuchiRankLayout.titleOrigin),
                    ),
            ),
          ),
        ),
        const SizedBox(height: IkkiuchiRankLayout.cardGap),
        IkkiuchiRankCard(t, elapsed: e, tone: tone.tone, plateKey: keys.plate),
        const SizedBox(height: IkkiuchiRankLayout.boxGap),
        Expanded(child: _entered(e, IkkiuchiRankMotion.box, _Box(t, e, keys: keys, tone: tone))),
        const SizedBox(height: IkkiuchiRankLayout.ctaTop),
        _entered(
          e,
          EntranceSpec(Entrances.pop, duration: IkkiuchiRankMotion.cta, delay: t.ctaAt, curve: Entrances.springy),
          CelebrationCta(
            label: cta,
            sub: sub,
            onTap: onNext,
            height: IkkiuchiRankLayout.ctaHeight,
            fontSize: IkkiuchiRankLayout.ctaFont,
            subFontSize: IkkiuchiRankLayout.ctaSubFont,
          ),
        ),
        const SizedBox(height: IkkiuchiRankLayout.bottomGap),
      ]),
    );
  }
}

/// The mode's tab joined to its box: the standing, then the curve (or the
/// placement chart) in the rest of its height. It jolts as the point lands,
/// or as a rank down hits.
class _Box extends StatelessWidget {
  const _Box(this.timeline, this.elapsed, {required this.keys, required this.tone});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final _Keys keys;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed;
    final jolt = t.ranksDown
        ? joltAt(e, t.hitAt, IkkiuchiRankMotion.hitJolt, IkkiuchiRankLayout.knockJolt, IkkiuchiRankLayout.knockSteps,
            IkkiuchiRankLayout.knockSeed)
        : joltAt(e, t.landAt, IkkiuchiRankMotion.landJolt,
            t.won ? IkkiuchiRankLayout.winJolt : IkkiuchiRankLayout.lossJolt, IkkiuchiRankLayout.joltSteps,
            IkkiuchiRankLayout.joltSeed);
    return Transform.translate(
      offset: jolt,
      child: CustomPaint(
        painter: _FramePainter(tone.tone, MediaQuery.devicePixelRatioOf(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: IkkiuchiRankLayout.tabHeight,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(
                width: IkkiuchiRankLayout.tabWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: IkkiuchiRankLayout.tabTop),
                  child: Center(child: IkkiuchiTabLabel(t.change.mode, chosen: true)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: IkkiuchiRankLayout.rankedGap, bottom: IkkiuchiRankLayout.rankedDrop),
                child: _Skewed(
                  child: Text(s.sideTripRanked,
                      maxLines: 1,
                      style: const TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: IkkiuchiRankLayout.rankedFont,
                          letterSpacing: IkkiuchiRankLayout.rankedTracking,
                          color: Palette.paper)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              key: keys.box,
              padding: IkkiuchiRankLayout.boxPadding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Standing(t, e, slotKey: keys.slot, tone: tone),
                const SizedBox(height: IkkiuchiRankLayout.plotTop),
                Expanded(
                  child: ConstrainedBox(
                    key: keys.plot,
                    constraints: const BoxConstraints(minHeight: IkkiuchiRankLayout.plotMinHeight),
                    child: IkkiuchiRankPlot(t, elapsed: e, tone: tone),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// [child] on an ink tag skewed back, the lettering upright.
class _Skewed extends StatelessWidget {
  const _Skewed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skew = IkkiuchiRankLayout.rankedSkewDeg * math.pi / 180;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.skewX(skew),
      child: ColoredBox(
        color: Palette.ink,
        child: Padding(
          padding: IkkiuchiRankLayout.rankedPadding,
          child: Transform(alignment: Alignment.center, transform: Matrix4.skewX(-skew), child: child),
        ),
      ),
    );
  }
}

/// The tab and the box as one ink outline on paper, the tab in the mode's
/// [tone], its top on the line falling across the box's width.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.tone, this.pixelRatio);

  final ToneSpec tone;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    const edge = IkkiuchiRankLayout.frameStroke / 2;
    const tab = IkkiuchiRankLayout.tabHeight, tabW = IkkiuchiRankLayout.tabWidth;
    final w = size.width, h = size.height;
    final slant = IkkiuchiRankLayout.tabSlant * tabW / w;
    Path shape(List<Offset> corners) => Path()..addPolygon(corners, true);
    final outline = shape([
      const Offset(edge, tab + edge),
      Offset(edge, slant + edge),
      const Offset(tabW - edge, edge),
      const Offset(tabW - edge, tab + edge),
      Offset(w - edge, tab + edge),
      Offset(w - edge, h - edge),
      Offset(edge, h - edge),
    ]);
    canvas
      ..drawPath(outline, Paint()..color = Palette.paper)
      ..drawPath(
          shape([
            Offset(edge, slant + edge),
            const Offset(tabW - edge, edge),
            const Offset(tabW - edge, tab + edge),
            const Offset(edge, tab + edge),
          ]),
          Screentone.paint(tone, pixelRatio))
      ..drawPath(
          outline,
          Paint()
            ..color = Palette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = IkkiuchiRankLayout.frameStroke
            ..strokeJoin = StrokeJoin.miter);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.tone != tone || old.pixelRatio != pixelRatio;
}

/// The standing: the badge's room ([slotKey]; the badge itself moves over
/// the page), the label (the rating, the class change once it has
/// happened, or placement), the rating counting with its change stamped
/// on, and the way to the next class with its bar (while placing, what
/// placement decides).
class _Standing extends StatelessWidget {
  const _Standing(this.timeline, this.elapsed, {required this.slotKey, required this.tone});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final GlobalKey slotKey;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed, change = t.change;
    final scaler = MediaQuery.textScalerOf(context);
    const label = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiRankLayout.labelFont, height: 1.2);
    const labelNumber = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: IkkiuchiRankLayout.labelNumber);
    final placed = t.placed, placing = t.placing;
    final labelled = progressIn(e, t.labelAt, IkkiuchiRankMotion.label);
    final swapsLabel = t.ranksUp || t.ranksDown || placed;

    Widget first;
    if (placing) {
      first = NumberedText(
        s.ikkiuchiPlacingHead(IkkiuchiRating.placementMatches) +
            (placed && e >= t.labelAt ? '' : s.ikkiuchiRankEstimate),
        [change.placement.length],
        style: label,
        numberStyle: labelNumber,
      );
    } else {
      first = Text(s.rating, style: label);
    }
    final second = !swapsLabel
        ? null
        : placed
            ? Text(s.rating, style: label)
            : _ClassChange(change.from, change.to);

    final shown = t.shownAt(e);
    const ratingStyle = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiRankLayout.ratingFont, height: 1);

    final landed = e >= t.landAt
        ? IkkiuchiRankLayout.ratingSwell *
            (1 - Curves.easeOutCubic.transform(progressIn(e, t.landAt, IkkiuchiRankMotion.landPulse)))
        : 0.0;
    final tagSpec = EntranceSpec(IkkiuchiRankMotion.tagFrom,
        duration: IkkiuchiRankMotion.tag, delay: t.tagAt, curve: Entrances.springy);
    final newSpec = EntranceSpec(IkkiuchiRankMotion.newFrom,
        duration: IkkiuchiRankMotion.tag, delay: t.labelAt, curve: Entrances.springy);
    const tagOrigin = IkkiuchiRankLayout.tagOrigin;

    return Row(children: [
      SizedBox.square(
        dimension: IkkiuchiRankLayout.badge.size,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            top: IkkiuchiRankLayout.badgeDrop,
            left: 0,
            child: SizedBox.square(key: slotKey, dimension: IkkiuchiRankLayout.badge.size),
          ),
        ]),
      ),
      const SizedBox(width: IkkiuchiRankLayout.standGap),
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: scaler.scale(IkkiuchiRankLayout.labelRoom),
            child: Stack(clipBehavior: Clip.none, children: [
              Opacity(opacity: second == null ? 1 : 1 - labelled, child: FittedBox(fit: BoxFit.scaleDown, child: first)),
              if (second != null)
                Opacity(
                  opacity: labelled,
                  child: Transform.translate(
                    offset: Offset(0, (1 - Curves.easeOutCubic.transform(labelled)) * IkkiuchiRankMotion.labelRise),
                    child: second,
                  ),
                ),
            ]),
          ),
          const SizedBox(height: IkkiuchiRankLayout.ratingTop),
          // As wide as the rating it counts to, so that the tag stamped on
          // after it lands sits by it, and a narrow room shrinks it by one
          // size all along.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(
              scale: 1 + landed,
              alignment: IkkiuchiRankLayout.ratingOrigin,
              child: Stack(clipBehavior: Clip.none, children: [
                Opacity(opacity: 0, child: Text('${change.after.round()}', style: ratingStyle)),
                Positioned(left: 0, top: 0, child: Text('$shown', style: ratingStyle)),
              ]),
            ),
            const SizedBox(width: IkkiuchiRankLayout.tagGap),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: IkkiuchiRankLayout.tagMinWidth),
              child: SizedBox(
                height: scaler.scale(IkkiuchiRankLayout.tagRoom),
                child: Stack(alignment: Alignment.centerLeft, clipBehavior: Clip.none, children: [
                  if (!(placed && e >= t.labelAt))
                    _entered(e, tagSpec, _ChangeTag(change), origin: tagOrigin),
                  if (placed)
                    _entered(
                      e,
                      newSpec,
                      Transform.rotate(angle: IkkiuchiRankLayout.newTurnDeg * math.pi / 180, child: const _NewTag()),
                      origin: tagOrigin,
                    ),
                ]),
              ),
            ),
          ])),
          if (!placing || (placed && e >= t.labelAt))
            Padding(
              padding: const EdgeInsets.only(top: IkkiuchiRankLayout.gaugeTop),
              child: Opacity(
                opacity: placed ? progressIn(e, t.labelAt, IkkiuchiRankMotion.gaugeShow) : 1,
                child: _Gauge(t, e, tone: tone),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: IkkiuchiRankLayout.noteTop),
              child: Opacity(opacity: placed && e >= t.revealAt ? 0 : 1, child: _Note(t, e)),
            ),
        ]),
      ),
    ]);
  }
}

/// What [change] did to the rating, on a tag at the page's size (▲ on ink,
/// ▼ on paper): the change stamped by the rating, and the points the chip
/// carries.
class _ChangeTag extends StatelessWidget {
  const _ChangeTag(this.change);

  final IkkiuchiRankChange change;

  @override
  Widget build(BuildContext context) {
    final points = change.after.round() - change.before.round();
    return RatingChangeTag(
        points,
        fontSize: IkkiuchiRankLayout.tagFont,
        // A rise's tag has no edge: as much more padding keeps both tags one size.
        padding: points > 0
            ? IkkiuchiRankLayout.tagPadding + const EdgeInsets.all(IkkiuchiRankLayout.tagBorder)
            : IkkiuchiRankLayout.tagPadding,
        border: IkkiuchiRankLayout.tagBorder,
      );
  }
}

/// NEW in paper on a pink tag, edged in ink.
class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.pink,
          border: Border.all(color: Palette.ink, width: IkkiuchiRankLayout.tagBorder),
        ),
        child: Padding(
          padding: IkkiuchiRankLayout.tagPadding,
          child: Text(S.of(context).newBadge,
              style: const TextStyle(
                  fontFamily: Fonts.display, fontSize: IkkiuchiRankLayout.tagFont, height: 1, color: Palette.paper)),
        ),
      );
}

/// The class change: the old class struck through → the new one, as chips.
class _ClassChange extends StatelessWidget {
  const _ClassChange(this.from, this.to);

  final RankBand from, to;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget chip(RankBand band, {required bool old}) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
                color: old ? IkkiuchiRankLayout.oldChipEdge : Palette.ink, width: IkkiuchiRankLayout.chipBorder),
          ),
          child: Padding(
            padding: IkkiuchiRankLayout.chipPadding,
            child: Text(s.className(band),
                style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: IkkiuchiRankLayout.chipFont,
                  height: 1.1,
                  color: old ? IkkiuchiRankLayout.oldChip : Palette.ink,
                  decoration: old ? TextDecoration.lineThrough : null,
                  decorationColor: IkkiuchiRankLayout.oldChip,
                  decorationThickness: IkkiuchiRankLayout.strike,
                )),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      chip(from, old: true),
      const SizedBox(width: IkkiuchiRankLayout.chipGap),
      const Text('→', style: TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiRankLayout.labelFont, height: 1)),
      const SizedBox(width: IkkiuchiRankLayout.chipGap),
      chip(to, old: false),
    ]);
  }
}

/// The way to the next class as the rating counts, with its bar in the
/// mode's colour; a rank up holds its full bar at the line until it breaks
/// through. The first class's bar fills once shown. Nothing at the top
/// class.
class _Gauge extends StatelessWidget {
  const _Gauge(this.timeline, this.elapsed, {required this.tone});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed;
    final scaler = MediaQuery.textScalerOf(context);
    final rating = t.ratingAt(e);
    var progress = IkkiuchiReview.classProgress(rating);
    var fraction = progress.fraction;
    if (t.ranksUp && e < t.breakAt) {
      progress = (band: t.change.from, next: t.change.to, fraction: 1);
      fraction = 1;
    }
    if (t.placed) fraction *= Curves.easeOutCubic.transform(progressIn(e, t.gaugeAt, IkkiuchiRankMotion.gauge));
    final next = progress.next;
    return SizedBox(
      height: scaler.scale(IkkiuchiRankLayout.gaugeHeight),
      child: next == null
          ? null
          : LayoutBuilder(
              builder: (context, box) => Row(children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: box.maxWidth - IkkiuchiRankLayout.barGap - IkkiuchiRankLayout.barMinWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: NumberedText(
                      s.ratingToNext(s.className(next)),
                      [next.pointsLeft(rating)],
                      style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiRankLayout.gaugeFont, height: 1),
                      numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiRankLayout.gaugeNumber, height: 1),
                    ),
                  ),
                ),
                const SizedBox(width: IkkiuchiRankLayout.barGap),
                Expanded(
                  child: RatingBar(
                    fraction,
                    width: double.infinity,
                    color: tone.deep,
                    height: IkkiuchiRankLayout.barHeight,
                    border: IkkiuchiRankLayout.barBorder,
                  ),
                ),
              ]),
            ),
    );
  }
}

/// While placing: what the placement matches left decide; the last one's
/// drumroll asks for the rank.
class _Note extends StatelessWidget {
  const _Note(this.timeline, this.elapsed);

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed;
    const style = TextStyle(
        fontWeight: Weights.black, fontSize: IkkiuchiRankLayout.noteFont, height: IkkiuchiRankLayout.noteLineHeight);
    const number = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: IkkiuchiRankLayout.noteNumber);
    final InlineSpan words;
    if (t.placed && e >= t.suspenseAt) {
      words = Phrases.span(s.ikkiuchiRankIs);
    } else {
      final total = IkkiuchiRating.placementMatches;
      final left = t.placed ? total : total - t.change.placement.length;
      final [before, after] = s.ikkiuchiPlacingLine(t.change.mode, first: t.placed).split('{0}');
      words = TextSpan(children: [
        Phrases.span(before),
        TextSpan(text: '${Phrases.joiner}$left${Phrases.joiner}', style: number),
        Phrases.span(after),
      ]);
    }
    final text = TextSpan(style: style, children: [words]);
    return LayoutBuilder(builder: (context, box) {
      final line = TextPainter(
        text: text,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final squeeze = line.width <= box.maxWidth * (1 + IkkiuchiRankLayout.noteSqueeze);
      line.dispose();
      return squeeze
          ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text.rich(text, maxLines: 1))
          : Text.rich(text);
    });
  }
}

// ------------------------------------------------------------ the effects

/// Where things are on the page as [_Pinned] paints, in its own box of
/// [size].
class _Where {
  _Where(this._self, this.size);

  final RenderBox _self;
  final Size size;

  /// Where [inside] (the middle unless given) of [key]'s box is now.
  Offset of(GlobalKey key, [Offset Function(Size size)? inside]) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Offset.zero;
    final local = inside == null ? box.size.center(Offset.zero) : inside(box.size);
    return _self.globalToLocal(box.localToGlobal(local));
  }

  /// Where the impact frame's stage stands.
  Offset get stage => IkkiuchiRankLayout.stageAt.withinRect(Offset.zero & size);
}

/// [child] painted with its [anchor] at where [at] works out as it paints
/// (from where the page's parts are then, see [_Where]), turned [turnDeg]
/// and scaled by [scale] about its [origin], at its own size. It fills its
/// parent.
class _Pinned extends SingleChildRenderObjectWidget {
  const _Pinned({
    required this.at,
    this.anchor = Alignment.center,
    this.origin = Alignment.center,
    this.scale = 1,
    this.turnDeg = 0,
    required Widget super.child,
  });

  final Offset Function(_Where where) at;
  final Alignment anchor, origin;
  final double scale, turnDeg;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPinned(at, anchor, origin, scale, turnDeg);

  @override
  void updateRenderObject(BuildContext context, _RenderPinned renderObject) => renderObject
    ..at = at
    ..anchor = anchor
    ..origin = origin
    ..scale = scale
    ..turnDeg = turnDeg;
}

class _RenderPinned extends RenderProxyBox {
  _RenderPinned(this._at, this._anchor, this._origin, this._scale, this._turnDeg);

  Offset Function(_Where where) _at;
  Alignment _anchor, _origin;
  double _scale, _turnDeg;

  set at(Offset Function(_Where where) value) {
    _at = value;
    markNeedsPaint();
  }

  set anchor(Alignment value) {
    _anchor = value;
    markNeedsPaint();
  }

  set origin(Alignment value) {
    _origin = value;
    markNeedsPaint();
  }

  set scale(double value) {
    _scale = value;
    markNeedsPaint();
  }

  set turnDeg(double value) {
    _turnDeg = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(const BoxConstraints(), parentUsesSize: true);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  /// Where the child was last painted.
  Matrix4 _placed = Matrix4.identity();

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final at = _at(_Where(this, size));
    final anchor = _anchor.alongSize(child.size), origin = _origin.alongSize(child.size);
    final corner = at - anchor;
    _placed = Matrix4.identity()
      ..translateByDouble(corner.dx + origin.dx, corner.dy + origin.dy, 0, 1)
      ..rotateZ(_turnDeg * math.pi / 180)
      ..scaleByDouble(_scale, _scale, 1, 1)
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
    context.pushTransform(needsCompositing, offset, _placed, (context, offset) => context.paintChild(child, offset));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_placed);
}

/// Everything over the page at [elapsed]: the dark of a strain or a
/// drumroll, the impact frame, the points flying, the class badge (it moves
/// between its room in the box and the impact frame's stage), the cut, the
/// splat, the lettering, the stickers, the cracks and the flash.
class _Effects extends StatelessWidget {
  const _Effects(this.timeline, this.elapsed, {required this.keys, required this.tone, required this.own});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final _Keys keys;
  final IkkiuchiModeTone tone;
  final IkkiuchiRankTone own;

  IkkiuchiClassBadge _badge(RankBand? band) => IkkiuchiClassBadge(band, tone: tone.tone, style: IkkiuchiRankLayout.badge);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = timeline, e = elapsed, change = t.change;
    final scaler = MediaQuery.textScalerOf(context);
    final boxIn = easedAt(e, IkkiuchiRankMotion.box).clamp(0.0, 1.0);
    Offset slot(_Where w) => w.of(keys.slot);
    Offset slotCorner(_Where w) => w.of(keys.slot, (_) => Offset.zero);
    Offset plotPoint(_Where w, Offset Function(IkkiuchiRankPlotPoints points) pick) =>
        w.of(keys.plot, (size) => pick(IkkiuchiRankPlotPoints(change, size)));
    final settle = t.climax ? Entrances.glide.transform(progressIn(e, t.settleAt, IkkiuchiRankMotion.settle)) : 0.0;
    Offset onStage(_Where w) => Offset.lerp(w.stage, slot(w), settle)!;

    final layers = <Widget>[];

    // The dark: a rank up's strain round the gate, the drumroll's dim.
    if (t.ranksUp) {
      final dark = IkkiuchiRankLayout.darkness *
          Curves.easeOutCubic.transform(progressIn(e, t.gateAt, IkkiuchiRankMotion.darken)) *
          (1 - progressIn(e, t.breakAt, IkkiuchiRankMotion.lift));
      if (dark > 0) {
        final side = 2 * MediaQuery.sizeOf(context).longestSide * math.sqrt2;
        layers.add(Opacity(
          opacity: dark,
          child: _Pinned(
            at: (w) => plotPoint(w, (p) => p.along(t.gateShare!)),
            child: SizedBox.square(
              dimension: side,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: const [Color(0x00141414), Color(0x00141414), Palette.ink],
                    stops: [0, IkkiuchiRankLayout.holeClear * 2 / side, IkkiuchiRankLayout.holeDark * 2 / side],
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    if (t.placed && e >= t.suspenseAt && e < t.revealAt) {
      layers.add(ColoredBox(
          color: Palette.ink.withValues(
              alpha: IkkiuchiRankLayout.hiddenDim *
                  Curves.easeIn.transform(progressIn(e, t.suspenseAt, IkkiuchiRankMotion.dim)))));
    }

    // The impact frame, from the cut until it has faded back into the page.
    if (t.climax && e >= t.cutAt && settle < 1) {
      final title = _titles(s, t).second!;
      layers.add(Opacity(
        opacity: 1 - settle,
        child: Transform.translate(
          offset: joltAt(e, t.impactAt, IkkiuchiRankMotion.impactJolt, IkkiuchiRankLayout.impactJolt,
              IkkiuchiRankLayout.impactSteps, IkkiuchiRankLayout.impactSeed),
          child: Stack(fit: StackFit.expand, children: [
            _ImpactArt(tone: tone, own: own),
            _Pinned(
              at: (w) => w.of(keys.title),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 2 * Gaps.gutter,
                height: scaler.scale(IkkiuchiRankLayout.titleRoom),
                child: _TitleRoom(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _entered(
                      e,
                      EntranceSpec(IkkiuchiRankMotion.title.from,
                          duration: IkkiuchiRankMotion.title.duration,
                          delay: t.impactAt,
                          curve: IkkiuchiRankMotion.title.curve),
                      _title(title, Palette.sun),
                      origin: IkkiuchiRankLayout.titleOrigin,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ));
    }

    // The points changing hands.
    if (e >= t.chipPopAt && e < t.chipLandAt) {
      final pop = easedAt(e, EntranceSpec(IkkiuchiRankMotion.popFrom, duration: IkkiuchiRankMotion.chipPop,
          delay: t.chipPopAt, curve: Entrances.bouncy));
      final f = Curves.easeInOutCubic.transform(progressIn(e, t.chipFlyAt, t.chipLandAt - t.chipFlyAt));
      Offset plate(_Where w) => w.of(keys.plate, (size) => Offset(size.width / 2, -IkkiuchiRankLayout.plateLift));
      Offset curve(_Where w) => plotPoint(w, (p) => t.won ? p.tip : p.next);
      layers.add(_Pinned(
        at: (w) {
          final (a, b) = t.won ? (plate(w), curve(w)) : (curve(w), plate(w));
          final c = Offset(math.max(a.dx, b.dx), math.min(a.dy, b.dy)) + IkkiuchiRankLayout.chipBow;
          return a * (1 - f) * (1 - f) + c * (2 * (1 - f) * f) + b * (f * f);
        },
        scale: lerpDouble(IkkiuchiRankMotion.popFrom.scale, 1, pop)! * (1 - IkkiuchiRankLayout.chipShrink * f),
        turnDeg: IkkiuchiRankLayout.chipTurnDeg * (1 - f),
        child: Opacity(
          opacity: pop.clamp(0.0, 1.0),
          child: _ChangeTag(change),
        ),
      ));
    }

    // The badge, the splat, the cut and the lettering of the climaxes.
    layers.addAll(_badges(t, e, boxIn: boxIn, slot: slot, slotCorner: slotCorner, onStage: onStage, settle: settle));

    // A rank up's rumble down both sides while it strains.
    if (t.ranksUp && e >= t.gateAt + IkkiuchiRankMotion.rumbleAfter && e < t.breakAt) {
      final pop = easedAt(
          e,
          EntranceSpec(IkkiuchiRankMotion.popFrom,
              duration: IkkiuchiRankMotion.rumblePop,
              delay: t.gateAt + IkkiuchiRankMotion.rumbleAfter,
              curve: IkkiuchiRankMotion.sfxSteps));
      for (final (right, seed, shake) in [
        (true, IkkiuchiRankLayout.rumbleSeeds.$2, IkkiuchiRankLayout.rumbleShakeSeeds.$2),
        (false, IkkiuchiRankLayout.rumbleSeeds.$1, IkkiuchiRankLayout.rumbleShakeSeeds.$1),
      ]) {
        final jitter = jitterAt(e, IkkiuchiRankMotion.rumbleStep, shake, IkkiuchiRankLayout.rumbleShake);
        layers.add(_Pinned(
          at: (w) {
            final top = w.of(keys.box, (_) => Offset.zero).dy;
            final at = right ? IkkiuchiRankLayout.rumbleRight : IkkiuchiRankLayout.rumbleLeft;
            return Offset(right ? w.size.width + at.dx : at.dx, top + at.dy) + jitter;
          },
          anchor: Alignment.topLeft,
          origin: IkkiuchiRankLayout.sfxOrigin,
          scale: lerpDouble(IkkiuchiRankMotion.popFrom.scale, 1, pop)!,
          child: SfxText(IkkiuchiRankLayout.rumble,
              size: IkkiuchiRankLayout.rumbleFont, color: Palette.violet, seed: seed, vertical: true),
        ));
      }
    }

    // The class change's sticker on the badge's corner.
    if ((t.ranksUp || t.ranksDown) && e >= t.labelAt) {
      const from = IkkiuchiRankMotion.stickerFrom;
      final sticker = easedAt(
          e, EntranceSpec(from, duration: IkkiuchiRankMotion.tag, delay: t.labelAt, curve: Entrances.springy));
      layers.add(_Pinned(
        at: (w) => slotCorner(w) + IkkiuchiRankLayout.stickerAt,
        anchor: Alignment.topLeft,
        scale: lerpDouble(from.scale, 1, sticker)!,
        turnDeg: IkkiuchiRankLayout.stickerTurnDeg + lerpDouble(from.turnDeg, 0, sticker)!,
        child: Opacity(opacity: (sticker / from.opaqueAt).clamp(0.0, 1.0), child: _Sticker(up: t.ranksUp)),
      ));
    }

    // A rank down's crack in the class line, ガーン!! and the badge's crack.
    if (t.ranksDown) {
      if (e >= t.crackAt) {
        final grow = IkkiuchiRankMotion.crackSteps.transform(progressIn(e, t.crackAt, IkkiuchiRankMotion.crack));
        layers.add(_Pinned(
          at: (w) {
            final gate = plotPoint(w, (p) => p.along(t.gateShare!));
            final right = w.of(keys.plot, (size) => Offset(size.width, 0)).dx;
            final x = math.min(
                gate.dx, right + IkkiuchiRankLayout.lineCrackOverhang + IkkiuchiRankLayout.lineCrackAt.dx);
            return Offset(x, gate.dy) + IkkiuchiRankLayout.lineCrackAt;
          },
          anchor: Alignment.topLeft,
          scale: lerpDouble(IkkiuchiRankMotion.crackFrom, 1, grow)!,
          child: Image.asset(IkkiuchiRankLayout.crack, width: IkkiuchiRankLayout.lineCrack, excludeFromSemantics: true),
        ));
      }
      final fall = Curves.easeInCubic.transform(progressIn(e, t.fallAt, IkkiuchiRankMotion.fall));
      if (e >= t.hitAt && fall < 1) {
        final hit = IkkiuchiRankMotion.crackSteps.transform(progressIn(e, t.hitAt, IkkiuchiRankMotion.crack));
        layers.add(_Pinned(
          at: (w) =>
              Offset(slotCorner(w).dx, slot(w).dy) +
              IkkiuchiRankLayout.badgeCrackAt +
              Offset(0, IkkiuchiRankLayout.fallDrop * fall),
          anchor: Alignment.topLeft,
          scale: lerpDouble(IkkiuchiRankMotion.crackFrom, 1, hit)!,
          turnDeg: IkkiuchiRankLayout.fallTurnDeg * fall + IkkiuchiRankLayout.badgeCrackTurnDeg,
          child: Opacity(
            opacity: 1 - fall,
            child:
                Image.asset(IkkiuchiRankLayout.crack, width: IkkiuchiRankLayout.badgeCrack, excludeFromSemantics: true),
          ),
        ));
      }
      if (e >= t.shockAt) {
        const from = IkkiuchiRankMotion.shockFrom;
        final drop = easedAt(
            e, EntranceSpec(from, duration: IkkiuchiRankMotion.shock, delay: t.shockAt, curve: IkkiuchiRankMotion.shockSteps));
        layers.add(_Pinned(
          at: (w) => slotCorner(w) + IkkiuchiRankLayout.shockAt + from.offset * (1 - drop),
          anchor: Alignment.topLeft,
          origin: IkkiuchiRankLayout.sfxOrigin,
          turnDeg: IkkiuchiRankLayout.shockTurnDeg,
          child: Opacity(
            opacity: (drop / from.opaqueAt).clamp(0.0, 1.0) *
                (1 - progressIn(e, t.labelAt, IkkiuchiRankMotion.shockLift)),
            child: const SfxText(IkkiuchiRankLayout.shock,
                size: IkkiuchiRankLayout.shockFont, color: Palette.paper, seed: IkkiuchiRankLayout.shockSeed),
          ),
        ));
      }
    }

    // The flash of the break, or of the first class showing.
    if (t.climax) {
      final at = t.ranksUp ? t.breakAt : t.revealAt;
      final flash = progressIn(e, at, IkkiuchiRankMotion.flashIn) *
          (1 - progressIn(e, at + IkkiuchiRankMotion.flashIn + IkkiuchiRankMotion.flashHold, IkkiuchiRankMotion.flashOut));
      if (flash > 0) layers.add(ColoredBox(color: Palette.paper.withValues(alpha: IkkiuchiRankLayout.flash * flash)));
    }

    return Stack(fit: StackFit.expand, children: layers);
  }

  /// The class badge as the page's moment moves it: at rest in its room
  /// (trembling at a rank up's line, beating under the drumroll, falling
  /// and replaced at a rank down), or on the impact frame's stage: the old
  /// class popped up and cut in two, the new one dropping onto the splat
  /// with its lettering, then settling back into its room.
  List<Widget> _badges(
    IkkiuchiRankTimeline t,
    Duration e, {
    required double boxIn,
    required Offset Function(_Where w) slot,
    required Offset Function(_Where w) slotCorner,
    required Offset Function(_Where w) onStage,
    required double settle,
  }) {
    final change = t.change;
    const stageScale = IkkiuchiRankLayout.stageScale;
    final out = <Widget>[];
    Widget atSlot(RankBand? band, {Offset shift = Offset.zero, double scale = 1, double turnDeg = 0, double opacity = 1}) =>
        _Pinned(
          at: (w) => slot(w) + shift,
          scale: scale,
          turnDeg: turnDeg,
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: _badge(band)),
        );

    switch (t.moment) {
      case IkkiuchiRankMoment.up || IkkiuchiRankMoment.down || IkkiuchiRankMoment.placing:
        out.add(atSlot(change.placing ? null : change.from, opacity: boxIn));
      case IkkiuchiRankMoment.rankDown:
        final fall = Curves.easeInCubic.transform(progressIn(e, t.fallAt, IkkiuchiRankMotion.fall));
        if (fall < 1) {
          out.add(atSlot(change.from,
              shift: Offset(0, IkkiuchiRankLayout.fallDrop * fall),
              turnDeg: IkkiuchiRankLayout.fallTurnDeg * fall,
              opacity: e < t.fallAt ? boxIn : 1 - fall));
        }
        if (e >= t.dropAt) {
          final drop = Curves.easeInCubic.transform(progressIn(e, t.dropAt, t.thudAt - t.dropAt));
          final thud = joltAt(e, t.thudAt, IkkiuchiRankMotion.thud, IkkiuchiRankLayout.thudJolt,
              IkkiuchiRankLayout.thudSteps, IkkiuchiRankLayout.thudSeed);
          out.add(atSlot(change.to,
              shift: Offset(0, IkkiuchiRankLayout.dropIn * (1 - drop)) + thud,
              opacity: drop / IkkiuchiRankMotion.dropShow));
        }
      case IkkiuchiRankMoment.rankUp:
        if (e < t.cutAt) {
          final straining = e >= t.gateAt && e < t.breakAt;
          final shake = straining
              ? jitterAt(e, IkkiuchiRankMotion.trembleStep, IkkiuchiRankLayout.trembleSeed,
                  IkkiuchiRankLayout.strainTremble * beatAt(e, t.strainBeats, IkkiuchiRankMotion.beatPulse) +
                      IkkiuchiRankLayout.restTremble)
              : Offset.zero;
          out.add(atSlot(change.from, shift: shake, opacity: boxIn));
        } else if (e < t.splitAt + IkkiuchiRankMotion.split) {
          final pop = Entrances.bouncy.transform(progressIn(e, t.cutAt, IkkiuchiRankMotion.oldPop));
          final shake = e < t.splitAt
              ? jitterAt(e, IkkiuchiRankMotion.trembleStep, IkkiuchiRankLayout.stageSeed, IkkiuchiRankLayout.stageTremble)
              : Offset.zero;
          final split = Curves.easeOutCubic.transform(progressIn(e, t.splitAt, IkkiuchiRankMotion.split));
          out.add(_Pinned(
            at: (w) => w.stage + shake,
            scale: lerpDouble(IkkiuchiRankLayout.oldFrom, stageScale, pop)!,
            child: SizedBox.square(
              dimension: IkkiuchiRankLayout.badge.size,
              child: BladeSplit(IkkiuchiRankLayout.cut, progress: split, child: _badge(change.from)),
            ),
          ));
        }
        out.addAll(_stamp(t, e, change.to, onStage: onStage, settle: settle, hit: IkkiuchiRankLayout.hit));
        if (e >= t.slashAt && e < t.slashAt + IkkiuchiRankMotion.slash + IkkiuchiRankMotion.slashFade) {
          final drawn = progressIn(e, t.slashAt, IkkiuchiRankMotion.slash);
          final fade = progressIn(e, t.slashAt + IkkiuchiRankMotion.slash, IkkiuchiRankMotion.slashFade);
          out.add(_Pinned(
            at: (w) => w.stage,
            child: Opacity(
              opacity: 1 - fade,
              child: CustomPaint(
                  size: IkkiuchiRankLayout.bladeBox, painter: BladePainter(IkkiuchiRankLayout.blade, drawn)),
            ),
          ));
        }
        final slashIn = t.slashAt + IkkiuchiRankMotion.slashSfxAfterCut - IkkiuchiRankMotion.slashAfterCut;
        if (e >= slashIn && e < t.impactAt) {
          final pop = easedAt(
              e,
              EntranceSpec(IkkiuchiRankMotion.popFrom,
                  duration: IkkiuchiRankMotion.slashSfx, delay: slashIn, curve: IkkiuchiRankMotion.sfxSteps));
          out.add(_Pinned(
            at: (w) => w.stage + IkkiuchiRankLayout.slashAt,
            anchor: Alignment.topLeft,
            origin: IkkiuchiRankLayout.sfxOrigin,
            scale: lerpDouble(IkkiuchiRankMotion.popFrom.scale, 1, pop)!,
            turnDeg: IkkiuchiRankLayout.slashTurnDeg,
            child: const SfxText(IkkiuchiRankLayout.slash,
                size: IkkiuchiRankLayout.slashFont, color: Palette.sun, seed: IkkiuchiRankLayout.slashSeed),
          ));
        }
      case IkkiuchiRankMoment.placed:
        if (e < t.cutAt) {
          out.add(atSlot(null,
              scale: 1 + IkkiuchiRankLayout.hiddenBeat * beatAt(e, t.suspenseBeats, IkkiuchiRankMotion.beatPulse),
              opacity: boxIn));
        }
        out.addAll(_stamp(t, e, change.to, onStage: onStage, settle: settle, hit: IkkiuchiRankLayout.reveal));
    }
    return out;
  }

  /// The new class from [t.stampAt]: dropping from high above onto the
  /// stage, landing on the splat at the impact with its lettering ([hit]),
  /// then settling into its room as the frame fades ([settle]).
  List<Widget> _stamp(
    IkkiuchiRankTimeline t,
    Duration e,
    RankBand band, {
    required Offset Function(_Where w) onStage,
    required double settle,
    required String hit,
  }) {
    if (e < t.stampAt) return const [];
    const stageScale = IkkiuchiRankLayout.stageScale;
    final drop = Curves.easeInCubic.transform(progressIn(e, t.stampAt, t.impactAt - t.stampAt));
    final scale = lerpDouble(
        e < t.impactAt ? lerpDouble(IkkiuchiRankLayout.dropFrom * stageScale, stageScale, drop)! : stageScale,
        1,
        settle)!;
    final turn = e < t.impactAt ? lerpDouble(IkkiuchiRankLayout.dropTurnDeg, 0, drop)! : 0.0;
    final out = <Widget>[];
    if (e >= t.impactAt && settle < 1) {
      final pop = Entrances.bouncy.transform(progressIn(e, t.impactAt, IkkiuchiRankMotion.splat));
      out.add(_Pinned(
        at: onStage,
        scale: lerpDouble(IkkiuchiRankMotion.popFrom.scale, 1, pop)! *
            lerpDouble(1, IkkiuchiRankLayout.splatRest, settle)!,
        child: Opacity(
          opacity: 1 - settle,
          child: Image.asset(IkkiuchiRankLayout.splat,
              width: IkkiuchiRankLayout.splatSize.width,
              height: IkkiuchiRankLayout.splatSize.height,
              excludeFromSemantics: true),
        ),
      ));
    }
    out.add(_Pinned(
      at: onStage,
      scale: scale,
      turnDeg: turn,
      child: Opacity(
        opacity: (progressIn(e, t.stampAt, t.impactAt - t.stampAt) / IkkiuchiRankMotion.stampShow).clamp(0.0, 1.0),
        child: _badge(band),
      ),
    ));
    final sfxAt = t.impactAt + IkkiuchiRankMotion.sfxAfterImpact;
    if (e >= sfxAt && settle < 1) {
      final pop = easedAt(
          e,
          EntranceSpec(IkkiuchiRankMotion.hitFrom,
              duration: IkkiuchiRankMotion.sfx, delay: sfxAt, curve: IkkiuchiRankMotion.sfxSteps));
      final first = hit == IkkiuchiRankLayout.reveal;
      out.add(_Pinned(
        at: (w) => onStage(w) + IkkiuchiRankLayout.sfxAt,
        anchor: Alignment.topLeft,
        origin: IkkiuchiRankLayout.sfxOrigin,
        scale: lerpDouble(IkkiuchiRankMotion.hitFrom.scale, 1, pop)!,
        turnDeg: IkkiuchiRankLayout.sfxTurnDeg,
        child: Opacity(
          opacity: 1 - settle,
          child: SfxText(hit,
              size: first ? IkkiuchiRankLayout.revealFont : IkkiuchiRankLayout.hitFont,
              color: first ? Palette.sun : Palette.pink,
              seed: first ? IkkiuchiRankLayout.revealSeed : IkkiuchiRankLayout.hitSeed),
        ),
      ));
    }
    return out;
  }
}

/// The impact frame's art: the mode's colour, a white glow round the
/// stage, the dots growing toward the foot and white focus lines on the
/// stage.
class _ImpactArt extends StatelessWidget {
  const _ImpactArt({required this.tone, required this.own});

  final IkkiuchiModeTone tone;
  final IkkiuchiRankTone own;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        final stage = IkkiuchiRankLayout.stageAt.withinRect(Offset.zero & size);
        const lines = IkkiuchiRankLayout.impactLines;
        return Stack(fit: StackFit.expand, children: [
          ColoredBox(color: tone.deep),
          CelebrationGlow(
            at: IkkiuchiRankLayout.stageAt,
            size: 2 * IkkiuchiRankLayout.stageGlow,
            colors: [Palette.paper, own.glow, own.glow.withValues(alpha: 0)],
            stops: IkkiuchiRankLayout.stageGlowStops,
          ),
          GradationBox(GradationSpec(
            dot: own.impactDot,
            spacing: IkkiuchiRankLayout.groundSpacing,
            phase: IkkiuchiRankLayout.groundPhase,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            radii: IkkiuchiRankLayout.impactRadii,
            stops: IkkiuchiRankLayout.impactStops,
          )),
          CustomPaint(
            painter: FocusLinesPainter(BurstSpec(
              box: size,
              center: stage,
              count: lines.count,
              innerMin: lines.innerMin,
              innerMax: lines.innerMax,
              width: lines.width,
              seed: lines.seed,
              color: Palette.paper,
            )),
          ),
        ]);
      });
}

/// The class change's sticker: 昇級! in sun on ink with a sun shadow, or 降級
/// in ink on paper.
class _Sticker extends StatelessWidget {
  const _Sticker({required this.up});

  final bool up;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: up ? Palette.ink : Palette.paper,
        border: Border.all(color: Palette.ink, width: IkkiuchiRankLayout.stickerBorder),
        boxShadow: up ? const [BoxShadow(color: Palette.sun, offset: IkkiuchiRankLayout.stickerShadow)] : null,
      ),
      child: Padding(
        padding: IkkiuchiRankLayout.stickerPadding,
        child: Text(up ? s.ikkiuchiRankUpSticker : s.ikkiuchiRankDownSticker,
            maxLines: 1,
            style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: IkkiuchiRankLayout.stickerFont,
                height: 1,
                color: up ? Palette.sun : Palette.ink)),
      ),
    );
  }
}
