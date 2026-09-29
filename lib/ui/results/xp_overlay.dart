import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/xp.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';
import 'celebration_chrome.dart';

/// When each line of an XP award pops in and counts into the total, and
/// what the total reads at any moment of the page.
class XpTimeline {
  XpTimeline(this.gain) : parts = gain.award.parts;

  final XpGain gain;
  final List<XpPart> parts;

  Duration rowAt(int i) => XpMotion.rowsAt + XpMotion.rowStep * i;
  Duration get countEnd => parts.isEmpty ? XpMotion.rowsAt : rowAt(parts.length - 1) + XpMotion.rowCount;
  Duration get finishAt => countEnd + XpMotion.finishGap;
  Duration get length => finishAt + XpMotion.actionsAfter + XpMotion.actions;

  /// XP of line [i] counted in [elapsed] into the page.
  double partAt(int i, Duration elapsed) {
    final t = ((elapsed - rowAt(i)).inMicroseconds / XpMotion.rowCount.inMicroseconds).clamp(0.0, 1.0);
    return parts[i].xp * XpMotion.countCurve.transform(t);
  }

  /// The award counted in [elapsed] into the page.
  double shownAt(Duration elapsed) {
    var sum = 0.0;
    for (var i = 0; i < parts.length; i++) {
      sum += partAt(i, elapsed);
    }
    return sum;
  }

  XpLevel levelAt(Duration elapsed) => XpCurve.of(gain.before + shownAt(elapsed).round());

  /// When the counting total reaches each new level, in order.
  late final List<Duration> levelUps = [
    for (var level = gain.levelBefore.level + 1; level <= gain.levelAfter.level; level++) _reaching(level),
  ];

  Duration _reaching(int level) {
    final target = XpCurve.reach(level) - gain.before;
    var lo = XpMotion.rowsAt, hi = countEnd;
    while (hi - lo > const Duration(milliseconds: 1)) {
      final mid = lo + (hi - lo) ~/ 2;
      if (shownAt(mid).round() >= target) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }

  /// The last new level reached by [elapsed], if any.
  Duration? lastLevelUp(Duration elapsed) {
    Duration? last;
    for (final at in levelUps) {
      if (at <= elapsed) last = at;
    }
    return last;
  }

  /// A pop per line, the counter ticking between them, and the total
  /// landing.
  List<(Sfx, Duration)> get sounds {
    final pops = [for (var i = 0; i < parts.length; i++) rowAt(i)];
    bool nearPop(Duration t) => pops.any((p) => (t - p).abs() < XpMotion.tickStep ~/ 2);
    return [
      for (final p in pops) (Sfx.xpPop, p),
      for (var t = XpMotion.rowsAt; t < countEnd; t += XpMotion.tickStep)
        if (!nearPop(t)) (Sfx.xpTick, t),
      (Sfx.xpDone, finishAt),
    ];
  }
}

/// The XP page (経験値!!), after every tracked run: the run's XP sources pop
/// in line by line, each counting into a big total while the level bar fills
/// with sparks flying off its tip, then the total lands with a jolt.
class XpOverlay extends StatelessWidget {
  const XpOverlay({super.key, required this.gain, required this.onNext});
  final XpGain gain;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final timeline = XpTimeline(gain);
    final finish = timeline.finishAt;
    return EntranceStage(
      length: timeline.length,
      child: CelebrationChrome(
        color: XpLayout.color,
        onNext: onNext,
        art: const [
          RadialLayer(center: XpLayout.skyCenter, colors: XpLayout.skyColors, stops: XpLayout.skyStops),
          ToneLayer(Tones.pink, fadeAngle: XpLayout.toneAngle, fadeStops: XpLayout.toneStops),
        ],
        backdrop: [
          const Opacity(
            opacity: XpLayout.focusOpacity,
            child: BoilingLines(XpLayout.focus, frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
          ),
          const CelebrationGlow(
              at: XpLayout.glowAt, size: XpLayout.glowSize, colors: XpLayout.glowColors, stops: XpLayout.glowStops),
          EntranceBuilder(
            _at(finish, XpMotion.burst),
            builder: (context, t, _) => t > 0 ? const ConfettiRain() : const SizedBox.shrink(),
          ),
        ],
        child: Jolt(
          _at(finish, XpMotion.jolt),
          reach: XpMotion.joltReach,
          steps: XpMotion.joltSteps,
          seed: XpMotion.joltSeed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: XpLayout.topGap),
              const Entrance(
                XpMotion.title,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OutlinedText(
                    XpLayout.title,
                    style: TextStyle(fontFamily: Fonts.display, fontSize: XpLayout.titleFont, color: Palette.paper, height: 1),
                    outline: Palette.ink,
                    outlineWidth: XpLayout.titleOutline,
                  ),
                ),
              ),
              Entrance(
                XpMotion.band,
                child: Padding(
                  padding: const EdgeInsets.only(right: XpLayout.bandShift),
                  child: CelebrationBand(s.xpBand,
                      inset: XpLayout.bandInset,
                      fontSize: XpLayout.bandFont,
                      tracking: XpLayout.bandTracking,
                      padding: XpLayout.bandPadding,
                      turnDeg: XpLayout.bandTurnDeg),
                ),
              ),
              const SizedBox(height: XpLayout.counterGap),
              Stack(clipBehavior: Clip.none, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: XpLayout.counterSide),
                  child: Entrance(XpMotion.counter, child: _Counter(timeline)),
                ),
                Positioned(
                  right: XpLayout.sfxAt.dx,
                  top: XpLayout.sfxAt.dy,
                  child: Entrance(
                    _pop(finish, XpMotion.sfx),
                    child: Transform.rotate(
                      angle: XpLayout.sfxTurnDeg * math.pi / 180,
                      child: const SfxText(XpLayout.sfx,
                          size: XpLayout.sfxFont, seed: XpLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
                    ),
                  ),
                ),
                Positioned(
                  right: XpLayout.tobi.right,
                  bottom: XpLayout.tobi.bottom,
                  width: XpLayout.tobi.size.width,
                  height: XpLayout.tobi.size.height,
                  child: Entrance(
                    _pop(finish + XpMotion.tobiAfter, XpMotion.tobi),
                    child: const Hop(
                      height: XpMotion.hopHeight,
                      period: XpMotion.hopPeriod,
                      airShare: XpMotion.hopAirShare,
                      child: Tobi(pose: TobiPose.cheering),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: XpLayout.barGap),
              Entrance(XpMotion.bar, child: _LevelBar(timeline)),
              const SizedBox(height: XpLayout.listGap),
              Expanded(child: _Breakdown(timeline)),
              const SizedBox(height: XpLayout.actionGap),
              Entrance(
                _pop(finish + XpMotion.actionsAfter, XpMotion.actions, curve: Entrances.springy),
                child: CelebrationCta(
                  label: s.xpCta,
                  sub: s.other.xpCta,
                  onTap: onNext,
                  height: XpLayout.actionHeight,
                  fontSize: XpLayout.ctaFont,
                  subFontSize: XpLayout.ctaSubFont,
                ),
              ),
              const SizedBox(height: Gaps.section),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A custom-drawn stretch of [length] starting [delay] into the page.
EntranceSpec _at(Duration delay, Duration length, {Curve curve = Curves.linear}) =>
    EntranceSpec(Entrances.custom, duration: length, delay: delay, curve: curve);

EntranceSpec _pop(Duration delay, Duration length, {Curve curve = Entrances.bouncy}) =>
    EntranceSpec(Entrances.pop, duration: length, delay: delay, curve: curve);

/// "+482 XP": counts up with the lines, then lands with a pulse and a burst
/// of focus lines. The box keeps the final width while counting.
class _Counter extends StatelessWidget {
  const _Counter(this.timeline);
  final XpTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final finish = timeline.finishAt;
    const style = TextStyle(fontFamily: Fonts.display, fontSize: XpLayout.counterFont, color: Palette.sun, height: 1);
    OutlinedText lettering(String text, [TextStyle style = style]) =>
        OutlinedText(text, style: style, outline: Palette.ink, outlineWidth: XpLayout.counterOutline);
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      Positioned.fill(
        child: ImpactBurst(
          _at(finish, XpMotion.burst, curve: Curves.easeOut),
          burst: XpLayout.impactBurst,
          size: XpLayout.impactSize,
          fromScale: XpLayout.impactFromScale,
          toScale: XpLayout.impactToScale,
        ),
      ),
      EntranceBuilder(
        _at(finish, XpMotion.finishPulse),
        builder: (context, t, child) =>
            Transform.scale(scale: 1 + XpLayout.finishPulse * math.sin(math.pi * t), child: child),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Stack(alignment: Alignment.centerRight, children: [
              Opacity(opacity: 0, child: lettering('+${timeline.gain.award.total}')),
              StageClock(length: timeline.length, builder: (context, elapsed) => lettering('+${timeline.shownAt(elapsed).round()}')),
            ]),
            const SizedBox(width: Gaps.small),
            lettering(s.xpUnit, style.copyWith(fontSize: XpLayout.counterUnitFont)),
          ]),
        ),
      ),
    ]);
  }
}

/// The level badge and the bar filling toward the next level: sparks fly
/// off its tip, and each new level flashes the bar and pops the badge.
class _LevelBar extends StatelessWidget {
  const _LevelBar(this.timeline);
  final XpTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final levelUps = timeline.levelUps;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        StageClock(length: timeline.length, builder: (context, elapsed) {
          final since = _since(timeline.lastLevelUp(elapsed), elapsed);
          final pop = since == null ? 0.0 : math.sin(math.pi * since);
          return Transform.scale(
            scale: 1 + XpLayout.badgePop * pop,
            child: _Badge(s.levelShort(timeline.levelAt(elapsed).level)),
          );
        }),
        const SizedBox(width: XpLayout.barBadgeGap),
        Expanded(
          child: SizedBox(
            height: XpLayout.barHeight,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: StageClock(length: timeline.length, builder: (context, elapsed) {
                  final since = _since(timeline.lastLevelUp(elapsed), elapsed);
                  return CustomPaint(
                    painter: _BarPainter(timeline.levelAt(elapsed).fraction, flash: since == null ? 0 : 1 - since),
                  );
                }),
              ),
              Positioned(
                left: -XpSparks.reach.left,
                top: -XpSparks.reach.top,
                right: -XpSparks.reach.right,
                bottom: -XpSparks.reach.bottom,
                child: IgnorePointer(
                  child: StageClock(
                    length: timeline.length,
                    builder: (context, elapsed) => CustomPaint(painter: _SparksPainter(timeline, elapsed)),
                  ),
                ),
              ),
              Positioned.fill(child: _TipLettering(timeline)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: XpLayout.noteGap),
      Row(children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: StageClock(length: timeline.length, builder: (context, elapsed) {
              final level = timeline.levelAt(elapsed);
              return _Note(s.xpToNext(level.toNext, level.level + 1));
            }),
          ),
        ),
        if (levelUps.isNotEmpty) ...[
          const SizedBox(width: Gaps.small),
          Entrance(
            _pop(levelUps.first, XpMotion.levelFlash),
            child: Transform.rotate(
              angle: XpLayout.flashTurnDeg * math.pi / 180,
              child: InkTag(s.levelUpFlash, fontSize: XpLayout.flashFont, color: Palette.pink, textColor: Palette.ink),
            ),
          ),
        ],
      ]),
    ]);
  }

  /// How far into its flash a new level reached at [at] is by [elapsed],
  /// 0–1, or null once over.
  static double? _since(Duration? at, Duration elapsed) {
    if (at == null) return null;
    final t = (elapsed - at).inMicroseconds / XpMotion.levelFlash.inMicroseconds;
    return t < 1 ? t : null;
  }
}

/// SFX lettering thrown off the tip as each line counts in: popping where
/// the tip is, then floating up and fading.
class _TipLettering extends StatelessWidget {
  const _TipLettering(this.timeline);
  final XpTimeline timeline;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => Stack(clipBehavior: Clip.none, children: [
          for (var i = 0; i < timeline.parts.length; i++)
            Positioned(
              left: box.maxWidth * timeline.levelAt(timeline.rowAt(i) + XpMotion.tipWordAt).fraction,
              top: 0,
              child: EntranceBuilder(
                _at(timeline.rowAt(i) + XpMotion.tipWordAt, XpMotion.tipWord),
                child: Transform.rotate(
                  angle: XpLayout.tipWordTurnDeg[i % XpLayout.tipWordTurnDeg.length] * math.pi / 180,
                  child: SfxText(
                    XpLayout.tipWords[i % XpLayout.tipWords.length],
                    size: XpLayout.tipWordFont,
                    color: XpLayout.tipWordColors[i % XpLayout.tipWordColors.length],
                    seed: XpLayout.tipWordSeed + i,
                    outline: NewCardLayout.sfxOutline,
                  ),
                ),
                builder: (context, t, child) => t <= 0 || t >= 1
                    ? const SizedBox.shrink()
                    : FractionalTranslation(
                        translation: Offset(i.isEven ? -XpLayout.tipWordLean : XpLayout.tipWordLean - 1, -1),
                        child: Transform.translate(
                          offset: Offset(0, -XpLayout.tipWordRise * t),
                          child: Opacity(
                            opacity: (t < XpLayout.tipWordFadeFrom ? 1.0 : (1 - t) / (1 - XpLayout.tipWordFadeFrom))
                                .clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: t < XpLayout.tipWordPopShare ? t / XpLayout.tipWordPopShare : 1,
                              child: child,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ]),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: XpLayout.badgeTurnDeg * math.pi / 180,
        child: ColoredBox(
          color: Palette.ink,
          child: Padding(
            padding: XpLayout.badgePadding,
            child: Text(text,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: XpLayout.badgeFont, color: Palette.sun, height: 1.1)),
          ),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: XpLayout.noteBorder)),
        child: Padding(
          padding: XpLayout.notePadding,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: const TextStyle(fontWeight: Weights.black, fontSize: XpLayout.noteFont)),
          ),
        ),
      );
}

/// The bar: a paper track, filled [fraction] in pink with a sheen, flashing
/// sun at a new level ([flash] 1 → 0).
class _BarPainter extends CustomPainter {
  const _BarPainter(this.fraction, {required this.flash});
  final double fraction;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = XpLayout.barTrack);
    final fill = Rect.fromLTWH(0, 0, size.width * fraction.clamp(0.0, 1.0), size.height);
    canvas.drawRect(fill, Paint()..color = XpLayout.barFill);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, fill.width, size.height * XpLayout.barSheenShare), Paint()..color = XpLayout.barSheen);
    if (flash > 0) canvas.drawRect(rect, Paint()..color = XpLayout.barFlash.withValues(alpha: flash));
    canvas.drawRect(
      rect.deflate(XpLayout.barBorder / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = XpLayout.barBorder
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.fraction != fraction || old.flash != flash;
}

/// Sparks thrown off the tip of the filling bar: one launched every
/// [XpSparks.spawnStep] while the total counts, each flying, falling and
/// fading on its own seeded course. Drawn in a box grown past the bar by
/// [XpSparks.reach], where the bar sits.
class _SparksPainter extends CustomPainter {
  _SparksPainter(this.timeline, this.elapsed);
  final XpTimeline timeline;
  final Duration elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = XpSparks.reach.deflateRect(Offset.zero & size);
    final start = XpMotion.rowsAt;
    final end = timeline.countEnd;
    if (elapsed < start) return;
    final fills = <Color, Path>{};
    final ink = Path();
    for (var at = start, k = 0; at < end && at <= elapsed; at += XpSparks.spawnStep, k++) {
      final r = SeededRandom(XpSparks.seed + k);
      final life = XpSparks.minLife + r.next() * XpSparks.lifeRange;
      final age = (elapsed - at).inMicroseconds / 1e6;
      if (age >= life) continue;
      final angle = (XpSparks.minAngle + r.next() * XpSparks.angleRange) * math.pi / 180;
      final speed = XpSparks.minSpeed + r.next() * XpSparks.speedRange;
      final tip = Offset(bar.left + bar.width * timeline.levelAt(at).fraction, bar.center.dy);
      final p = tip +
          Offset(math.cos(angle), math.sin(angle)) * speed * age +
          Offset(0, XpSparks.gravity * age * age / 2);
      final fade = ((life - age) / (life * (1 - XpSparks.fadeFrom))).clamp(0.0, 1.0);
      final size = (XpSparks.minSize + r.next() * XpSparks.sizeRange) * (XpSparks.fadedSize + (1 - XpSparks.fadedSize) * fade);
      final shape = k % XpSparks.squareEvery == 0
          ? _square(p, size, r.next() * XpSparks.spin * age)
          : _star(p, size, r.next() * XpSparks.spin * age);
      (fills[XpSparks.colors[k % XpSparks.colors.length]] ??= Path()).addPath(shape, Offset.zero);
      ink.addPath(shape, Offset.zero);
    }
    if (elapsed < end) {
      final glint = _star(Offset(bar.left + bar.width * timeline.levelAt(elapsed).fraction, bar.center.dy),
          XpSparks.glint, elapsed.inMicroseconds / 1e6 * XpSparks.spin);
      (fills[Palette.paper] ??= Path()).addPath(glint, Offset.zero);
      ink.addPath(glint, Offset.zero);
    }
    // The fill covers the inner half of the stroke, leaving [XpSparks.stroke].
    canvas.drawPath(
      ink,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = XpSparks.stroke * 2
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.ink,
    );
    for (final MapEntry(key: color, value: path) in fills.entries) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  /// A four-point sparkle [size] across at [c], turned [turn] radians.
  static Path _star(Offset c, double size, double turn) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = turn + i * math.pi / 4;
      final r = i.isEven ? size / 2 : size * XpSparks.starWaist;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _square(Offset c, double size, double turn) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = turn + i * math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * size * math.sqrt1_2;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.elapsed != elapsed || old.timeline != timeline;
}

/// The run's XP line by line, each a strip slapped down in turn, counting
/// its own XP up. Scales down to fit rather than scroll.
class _Breakdown extends StatelessWidget {
  const _Breakdown(this.timeline);
  final XpTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final parts = timeline.parts;
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: box.maxWidth,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(height: XpLayout.rowGap),
              Entrance(
                EntranceSpec(Entrances.slideL, duration: XpMotion.rowIn, delay: timeline.rowAt(i), curve: XpMotion.rowCurve),
                child: Transform.rotate(
                  angle: (i.isEven ? XpLayout.rowTurnDeg : -XpLayout.rowTurnDeg) * math.pi / 180,
                  child: _Line(timeline, i),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// One source on its strip: its name, how many, and its XP counting up.
class _Line extends StatelessWidget {
  const _Line(this.timeline, this.index);
  final XpTimeline timeline;
  final int index;

  /// Big one-off bonuses sit on a sun strip.
  static const _highlighted = {XpSource.best, XpSource.island, XpSource.graduation};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final part = timeline.parts[index];
    final count = s.xpCount(part);
    const xpStyle = TextStyle(fontFamily: Fonts.display, fontSize: XpLayout.rowXpFont, height: 1.1);
    final line = Row(children: [
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Text(s.xpSource(part.source), style: const TextStyle(fontWeight: Weights.black, fontSize: XpLayout.rowLabelFont)),
            if (count != null) ...[
              const SizedBox(width: XpLayout.rowCountGap),
              Text(count,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: XpLayout.rowCountFont, color: Palette.mute)),
            ],
          ]),
        ),
      ),
      const SizedBox(width: XpLayout.rowCountGap),
      Stack(alignment: Alignment.centerRight, children: [
        Opacity(opacity: 0, child: Text('+${part.xp}', style: xpStyle)),
        StageClock(length: timeline.length, builder: (context, elapsed) => Text('+${timeline.partAt(index, elapsed).round()}', style: xpStyle)),
      ]),
    ]);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _highlighted.contains(part.source) ? Palette.sun : Palette.paper,
        border: Border.all(color: Palette.ink, width: XpLayout.rowBorder),
      ),
      child: Padding(padding: XpLayout.rowPadding, child: line),
    );
  }
}
