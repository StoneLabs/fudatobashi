import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';
import '../rank/rank_badges.dart';
import '../results/celebration_chrome.dart';
import '../results/celebrations.dart';
import '../side_trips/side_trip_entry.dart';

/// 暗記練's own rank-up, a manga action beat cut in at the rating page's
/// white flash. On a black page focus lines rush in on the old class,
/// trembling under ゴゴゴ; a blade flashes across it (ズバッ!!) and its
/// halves slide apart; the new class slams down onto an ink splash in a
/// negative impact frame, with a shake and ドン!!; then the page turns sea
/// blue and settles on the result. A tap skips to the end.
class AnkirenRankUpOverlay extends StatelessWidget {
  const AnkirenRankUpOverlay({super.key, required this.data, required this.onNext});
  final AnkirenRankCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: AnkirenRankUpMotion.length,
      child: Builder(
        builder: (context) => Stack(fit: StackFit.expand, children: [
          CelebrationChrome(
            color: AnkirenRankLayout.color,
            onNext: _skipOr(context, onNext),
            art: const [
              RadialLayer(
                  center: AnkirenRankLayout.glowAt, colors: AnkirenRankLayout.glowColors, stops: AnkirenRankLayout.glowStops),
              ToneLayer(AnkirenRatingLayout.tone,
                  fadeAngle: AnkirenRatingLayout.toneAngle, fadeStops: AnkirenRatingLayout.toneStops),
            ],
            backdrop: const [_Night(), _Rush()],
            child: Jolt(
              AnkirenRankUpMotion.jolt,
              reach: AnkirenRankUpMotion.joltReach,
              steps: AnkirenRankUpMotion.joltSteps,
              seed: AnkirenRankUpMotion.joltSeed,
              child: _Page(
                data: data,
                band: (s.ankirenRankUpBand, AnkirenRankUpMotion.band),
                stage: _UpStage(data),
                result: AnkirenRankUpMotion.result,
                actions: AnkirenRankUpMotion.actions,
                cta: (s.ratingCta, s.sub?.ratingCta),
                onNext: onNext,
              ),
            ),
          ),
          const _ImpactFrame(),
          const _Flash(),
        ]),
      ),
    );
  }
}

/// 暗記練's rank-down, a smaller beat in the same style: on the calm page
/// of a fall, ガーン!! drops onto the old class and cracks it with a jolt,
/// a shadow full of gloom lines comes down and Tobi starts in shock; the
/// old class falls away and the lower one drops into its place; then the
/// result. A tap skips to the end.
class AnkirenRankDownOverlay extends StatelessWidget {
  const AnkirenRankDownOverlay({super.key, required this.data, required this.onNext});
  final AnkirenRankCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: AnkirenRankDownMotion.length,
      child: Builder(
        builder: (context) => CelebrationChrome(
          color: AnkirenRatingLayout.calmColor,
          onNext: _skipOr(context, onNext),
          art: const [
            RadialLayer(
                center: AnkirenRatingLayout.glowAt,
                colors: AnkirenRatingLayout.calmGlowColors,
                stops: AnkirenRatingLayout.glowStops),
            ToneLayer(AnkirenRatingLayout.calmTone,
                fadeAngle: AnkirenRatingLayout.toneAngle, fadeStops: AnkirenRatingLayout.toneStops),
          ],
          backdrop: const [_Gloom()],
          child: Jolt(
            AnkirenRankDownMotion.jolt,
            reach: AnkirenRankDownMotion.joltReach,
            steps: AnkirenRankDownMotion.joltSteps,
            seed: AnkirenRankDownMotion.joltSeed,
            child: Jolt(
              AnkirenRankDownMotion.thud,
              reach: AnkirenRankDownMotion.thudReach,
              steps: AnkirenRankDownMotion.thudSteps,
              seed: AnkirenRankDownMotion.thudSeed,
              child: _Page(
                data: data,
                band: (s.ankirenRankDownBand, AnkirenRankDownMotion.band),
                stage: _DownStage(data),
                result: AnkirenRankDownMotion.result,
                actions: AnkirenRankDownMotion.actions,
                cta: (s.ankirenNextTime, s.sub?.ankirenNextTime),
                onNext: onNext,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tap mid-sequence skips to its end, and once it is at rest moves on;
/// [stage] is a context under the page's [EntranceStage].
VoidCallback _skipOr(BuildContext stage, VoidCallback onNext) => () {
      if (!EntranceStage.finish(stage)) onNext();
    };

/// The page: the band naming it, the stage, the result and the button,
/// each coming in on its own [EntranceSpec].
class _Page extends StatelessWidget {
  const _Page({
    required this.data,
    required this.band,
    required this.stage,
    required this.result,
    required this.actions,
    required this.cta,
    required this.onNext,
  });

  final AnkirenRankCelebration data;
  final (String, EntranceSpec) band;
  final Widget stage;
  final EntranceSpec result, actions;
  final (String, String?) cta;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final (bandText, bandSpec) = band;
    final (label, sub) = cta;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: AnkirenRankLayout.topGap),
      Entrance(
        bandSpec,
        child: CelebrationBand(bandText,
            inset: AnkirenRankLayout.bandInset,
            fontSize: AnkirenRankLayout.bandFont,
            tracking: AnkirenRankLayout.bandTracking,
            padding: AnkirenRankLayout.bandPadding,
            turnDeg: AnkirenRankLayout.bandTurnDeg),
      ),
      const SizedBox(height: AnkirenRankLayout.stageGap),
      Expanded(child: stage),
      const SizedBox(height: AnkirenRankLayout.stageGap),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Entrance(result, child: _Result(data)),
          const SizedBox(height: AnkirenRankLayout.actionGap),
          Entrance(
            actions,
            child: CelebrationCta(
              label: label,
              sub: sub,
              onTap: onNext,
              height: AnkirenRankLayout.actionHeight,
              fontSize: AnkirenRankLayout.ctaFont,
              subFontSize: AnkirenRankLayout.ctaSubFont,
            ),
          ),
        ]),
      ),
      const SizedBox(height: Gaps.section),
    ]);
  }
}

/// The rank-up's stage, scaled down to fit: the old class trembling under
/// ゴゴゴ, cut by the blade with ズバッ!!, the new class stamped onto the
/// splash with a burst and ドン!!, and Tobi hopping for joy.
class _UpStage extends StatelessWidget {
  const _UpStage(this.data);
  final AnkirenRankCelebration data;

  @override
  Widget build(BuildContext context) {
    final style = rungStyle(data.to.id);
    const splash = AnkirenRankLayout.splashSize;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox.fromSize(
        size: AnkirenRankLayout.stage,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Entrance(
            AnkirenRankUpMotion.splash,
            child: OverflowBox(
              minWidth: splash.width,
              maxWidth: splash.width,
              minHeight: splash.height,
              maxHeight: splash.height,
              child: Image.asset(AnkirenRankLayout.splash,
                  width: splash.width, height: splash.height, excludeFromSemantics: true),
            ),
          ),
          const ImpactBurst(
            AnkirenRankUpMotion.burst,
            burst: AnkirenRankLayout.impactBurst,
            size: AnkirenRankLayout.impactSize,
            fromScale: AnkirenRankLayout.impactFromScale,
            toScale: AnkirenRankLayout.impactToScale,
          ),
          Positioned.fill(
            child: Entrance(
              AnkirenRankUpMotion.old,
              child: _Cut(ClassBadge(data.from,
                  fontSize: AnkirenRankLayout.oldFont,
                  suffixSize: AnkirenRankLayout.oldSuffixFont,
                  padding: AnkirenRankLayout.oldPadding,
                  border: AnkirenRankLayout.oldBorder)),
            ),
          ),
          const Positioned.fill(child: _Blade()),
          Entrance(
            AnkirenRankUpMotion.stamp,
            child: Transform.rotate(
              angle: AnkirenRankLayout.newTurnDeg * math.pi / 180,
              child: ClassBadge(data.to,
                  key: const ValueKey('ankirenRankNew'),
                  color: style.color,
                  textColor: style.text,
                  fontSize: AnkirenRankLayout.newFont,
                  suffixSize: AnkirenRankLayout.newSuffixFont,
                  padding: AnkirenRankLayout.newPadding,
                  border: AnkirenRankLayout.newBorder),
            ),
          ),
          Positioned(
            left: AnkirenRankLayout.rumbleAt.dx,
            top: AnkirenRankLayout.rumbleAt.dy,
            child: const _Until(
              AnkirenRankUpMotion.slashAt,
              child: Entrance(
                AnkirenRankUpMotion.rumble,
                child: Shake(
                  reach: AnkirenRankLayout.trembleReach,
                  step: AnkirenRankUpMotion.trembleStep,
                  seed: AnkirenRankLayout.rumbleSeed,
                  child: SfxText(AnkirenRankLayout.rumble,
                      size: AnkirenRankLayout.rumbleFont,
                      color: Palette.violet,
                      seed: AnkirenRankLayout.rumbleSeed,
                      vertical: true),
                ),
              ),
            ),
          ),
          Positioned(
            left: AnkirenRankLayout.slashAt.dx,
            top: AnkirenRankLayout.slashAt.dy,
            child: _Until(
              AnkirenRankUpMotion.impactAt,
              child: Entrance(
                AnkirenRankUpMotion.slashSfx,
                child: Transform.rotate(
                  angle: AnkirenRankLayout.slashTurnDeg * math.pi / 180,
                  child: const SfxText(AnkirenRankLayout.slashSfx,
                      size: AnkirenRankLayout.slashFont, color: Palette.sun, seed: AnkirenRankLayout.slashSeed),
                ),
              ),
            ),
          ),
          Positioned(
            right: AnkirenRankLayout.hitAt.dx,
            top: AnkirenRankLayout.hitAt.dy,
            child: Entrance(
              AnkirenRankUpMotion.hitSfx,
              child: Transform.rotate(
                angle: AnkirenRankLayout.hitTurnDeg * math.pi / 180,
                child: const SfxText(AnkirenRankLayout.hitSfx,
                    size: AnkirenRankLayout.hitFont, seed: AnkirenRankLayout.hitSeed, outline: NewCardLayout.sfxOutline),
              ),
            ),
          ),
          const Placed(
            AnkirenRankLayout.tobi,
            child: Entrance(
              AnkirenRankUpMotion.tobi,
              child: Hop(
                height: AnkirenRankUpMotion.hopHeight,
                period: AnkirenRankUpMotion.hopPeriod,
                airShare: AnkirenRankUpMotion.hopAirShare,
                child: Tobi(pose: TobiPose.cheering),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The rank-down's stage, scaled down to fit: the old class cracking under
/// ガーン!! and falling away, the lower class dropping into its place, and
/// Tobi shaking in shock.
class _DownStage extends StatelessWidget {
  const _DownStage(this.data);
  final AnkirenRankCelebration data;

  @override
  Widget build(BuildContext context) {
    final style = rungStyle(data.to.id);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox.fromSize(
        size: AnkirenRankLayout.downStage,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Entrance(
            AnkirenRankDownMotion.drop,
            child: ClassBadge(data.to,
                key: const ValueKey('ankirenRankNew'),
                color: style.color,
                textColor: style.text,
                fontSize: AnkirenRankLayout.oldFont,
                suffixSize: AnkirenRankLayout.oldSuffixFont,
                padding: AnkirenRankLayout.oldPadding,
                border: AnkirenRankLayout.oldBorder),
          ),
          Entrance(
            AnkirenRankDownMotion.old,
            child: _Falling(
              Stack(children: [
                ClassBadge(data.from,
                    fontSize: AnkirenRankLayout.oldFont,
                    suffixSize: AnkirenRankLayout.oldSuffixFont,
                    padding: AnkirenRankLayout.oldPadding,
                    border: AnkirenRankLayout.oldBorder),
                Positioned.fill(
                  child: Entrance(
                    AnkirenRankDownMotion.crack,
                    child: Image.asset(AnkirenRankLayout.crack, fit: BoxFit.fill, excludeFromSemantics: true),
                  ),
                ),
              ]),
            ),
          ),
          Positioned(
            top: AnkirenRankLayout.shockTop,
            left: 0,
            right: 0,
            child: Center(
              child: Entrance(
                AnkirenRankDownMotion.shock,
                child: Transform.rotate(
                  angle: AnkirenRankLayout.shockTurnDeg * math.pi / 180,
                  child: const SfxText(AnkirenRankLayout.shockSfx,
                      size: AnkirenRankLayout.shockFont,
                      color: Palette.paper,
                      seed: AnkirenRankLayout.shockSeed,
                      outline: NewCardLayout.sfxOutline),
                ),
              ),
            ),
          ),
          const Placed(
            AnkirenRankLayout.tobi,
            child: Entrance(
              AnkirenRankDownMotion.tobi,
              child: Shake(
                reach: AnkirenRankLayout.tobiTremble,
                step: AnkirenRankLayout.tobiTrembleStep,
                seed: AnkirenRankLayout.shockSeed,
                child: Tobi(pose: TobiPose.shocked),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// [child] until [until] into the page, then gone.
class _Until extends StatelessWidget {
  const _Until(this.until, {required this.child});
  final Duration until;
  final Widget child;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
        EntranceSpec(Entrances.custom, duration: until, curve: Curves.linear),
        child: child,
        builder: (context, t, child) => t < 1 ? child! : const SizedBox.shrink(),
      );
}

/// The old class in the middle of the stage, trembling until the blade has
/// cut it, then in two halves sliding apart along the cut as they fade.
class _Cut extends StatelessWidget {
  const _Cut(this.badge);
  final Widget badge;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
        AnkirenRankUpMotion.split,
        child: Center(child: badge),
        builder: (context, t, child) {
          if (t <= 0) {
            return Shake(
              reach: AnkirenRankLayout.trembleReach,
              step: AnkirenRankUpMotion.trembleStep,
              seed: AnkirenRankLayout.rumbleSeed,
              child: child!,
            );
          }
          if (t >= 1) return const SizedBox.shrink();
          final (along, across) = _bladeAxes;
          final fade = ((t - AnkirenRankLayout.splitFadeFrom) / (1 - AnkirenRankLayout.splitFadeFrom)).clamp(0.0, 1.0);
          return Opacity(
            opacity: 1 - fade,
            child: Stack(fit: StackFit.expand, children: [
              for (final side in [-1.0, 1.0])
                Transform.translate(
                  offset: (along * AnkirenRankLayout.splitSlide + across * AnkirenRankLayout.splitGap) * side * t,
                  child: Transform.rotate(
                    angle: side * t * AnkirenRankLayout.splitTurnDeg * math.pi / 180,
                    child: ClipPath(clipper: _HalfClipper(side), child: child),
                  ),
                ),
            ]),
          );
        },
      );
}

/// The blade's direction and, at right angles to it, toward the lower half.
(Offset, Offset) get _bladeAxes {
  final cut = AnkirenRankLayout.bladeTo - AnkirenRankLayout.bladeFrom;
  final along = cut / cut.distance;
  return (along, Offset(-along.dy, along.dx));
}

/// The stage on one [side] of the blade's line: -1 above it, 1 below.
class _HalfClipper extends CustomClipper<Path> {
  const _HalfClipper(this.side);
  final double side;

  @override
  Path getClip(Size size) {
    final (along, across) = _bladeAxes;
    final reach = size.longestSide * 2;
    final from = AnkirenRankLayout.bladeFrom - along * reach;
    final to = AnkirenRankLayout.bladeTo + along * reach;
    final away = across * reach * side;
    return Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + away.dx, to.dy + away.dy)
      ..lineTo(from.dx + away.dx, from.dy + away.dy)
      ..close();
  }

  @override
  bool shouldReclip(_HalfClipper old) => old.side != side;
}

/// The blade flashing across the stage, then fading.
class _Blade extends StatelessWidget {
  const _Blade();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: StageClock(
          length: AnkirenRankUpMotion.length,
          builder: (context, elapsed) {
            const at = AnkirenRankUpMotion.slashAt, cut = AnkirenRankUpMotion.slash;
            final drawn = progressIn(elapsed, at, cut);
            final fade = progressIn(elapsed, at + cut, AnkirenRankUpMotion.slashFade);
            if (drawn <= 0 || fade >= 1) return const SizedBox.shrink();
            return Opacity(opacity: 1 - fade, child: CustomPaint(painter: _BladePainter(drawn)));
          },
        ),
      );
}

/// The blade's streak, [drawn] of the way from its start: a paper lens
/// with an ink edge round a sun core, widest toward its head.
class _BladePainter extends CustomPainter {
  const _BladePainter(this.drawn);
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    const from = AnkirenRankLayout.bladeFrom;
    final head = Offset.lerp(from, AnkirenRankLayout.bladeTo, drawn)!;
    final widest = Offset.lerp(from, head, AnkirenRankLayout.bladeWidest)!;
    final (_, across) = _bladeAxes;
    Path lens(double width) {
      final bulge = across * width;
      return Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(widest.dx + bulge.dx, widest.dy + bulge.dy, head.dx, head.dy)
        ..quadraticBezierTo(widest.dx - bulge.dx, widest.dy - bulge.dy, from.dx, from.dy)
        ..close();
    }

    final blade = lens(AnkirenRankLayout.bladeWidth);
    canvas
      ..drawPath(
          blade,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AnkirenRankLayout.bladeOutline
            ..strokeJoin = StrokeJoin.round
            ..color = Palette.ink)
      ..drawPath(blade, Paint()..color = Palette.paper)
      ..drawPath(lens(AnkirenRankLayout.bladeWidth * AnkirenRankLayout.bladeCore), Paint()..color = Palette.sun);
  }

  @override
  bool shouldRepaint(_BladePainter old) => old.drawn != drawn;
}

/// The old class falling away, turning as it fades.
class _Falling extends StatelessWidget {
  const _Falling(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
        AnkirenRankDownMotion.fall,
        child: child,
        builder: (context, t, child) {
          if (t >= 1) return const SizedBox.shrink();
          return Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(0, AnkirenRankLayout.fallDrop * t),
              child: Transform.rotate(angle: AnkirenRankLayout.fallTurnDeg * t * math.pi / 180, child: child),
            ),
          );
        },
      );
}

/// The rank-up's charge: a black page under a dark tone, until the impact.
class _Night extends StatelessWidget {
  const _Night();

  @override
  Widget build(BuildContext context) => const _Until(
        AnkirenRankUpMotion.impactAt,
        child: StaticArt([FillLayer(AnkirenRankLayout.night), ToneLayer(AnkirenRankLayout.nightTone)]),
      );
}

/// White focus lines boiling on the stage, rushing in from far out at the
/// start.
class _Rush extends StatelessWidget {
  const _Rush();

  @override
  Widget build(BuildContext context) {
    const lines = AnkirenRankLayout.lines;
    final focus = Alignment(lines.center.dx / lines.box.width * 2 - 1, lines.center.dy / lines.box.height * 2 - 1);
    return IgnorePointer(
      child: EntranceBuilder(
        AnkirenRankUpMotion.rush,
        child: const BoilingLines(lines, frames: AnkirenRankUpMotion.linesFrames, step: AnkirenRankUpMotion.linesStep),
        builder: (context, t, child) =>
            Transform.scale(scale: lerpDouble(AnkirenRankLayout.rushFrom, 1, t)!, alignment: focus, child: child),
      ),
    );
  }
}

/// The impact frame: for an instant as the new class lands, the whole page
/// in negative.
class _ImpactFrame extends StatelessWidget {
  const _ImpactFrame();

  static const _negative = ColorFilter.matrix(AnkirenRankLayout.negative);

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: StageClock(
          length: AnkirenRankUpMotion.length,
          builder: (context, elapsed) {
            const at = AnkirenRankUpMotion.impactAt;
            final on = elapsed >= at && elapsed < at + AnkirenRankUpMotion.impactFrame;
            return on ? const BackdropFilter(filter: _negative, child: SizedBox.expand()) : const SizedBox.shrink();
          },
        ),
      );
}

/// The rating page's white flash the rank-up cuts in on, fading off.
class _Flash extends StatelessWidget {
  const _Flash();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: EntranceBuilder(
          AnkirenRankUpMotion.flash,
          builder: (context, t, _) =>
              t >= 1 ? const SizedBox.shrink() : ColoredBox(color: AnkirenRatingLayout.flash.withValues(alpha: 1 - t)),
        ),
      );
}

/// The rank-down's shadow coming down from the top with gloom lines (縦線)
/// hanging in it.
class _Gloom extends StatelessWidget {
  const _Gloom();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: EntranceBuilder(
          AnkirenRankDownMotion.gloom,
          builder: (context, t, _) =>
              t <= 0 ? const SizedBox.shrink() : CustomPaint(size: Size.infinite, painter: _GloomPainter(t)),
        ),
      );
}

class _GloomPainter extends CustomPainter {
  const _GloomPainter(this.reach);

  /// How far down the shadow and the lines have come, 0–1.
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Rect.fromLTWH(0, 0, size.width, size.height * AnkirenRankLayout.gloomReach * reach);
    canvas.drawRect(
      shade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AnkirenRankLayout.gloomColors,
        ).createShader(shade),
    );
    final r = SeededRandom(AnkirenRankLayout.gloomSeed);
    final lines = Path();
    const shortest = AnkirenRankLayout.gloomShortest, longest = AnkirenRankLayout.gloomLongest;
    const thinnest = AnkirenRankLayout.gloomThinnest, thickest = AnkirenRankLayout.gloomThickest;
    for (var i = 0; i < AnkirenRankLayout.gloomCount; i++) {
      final x = r.next() * size.width;
      final length = size.height * (shortest + r.next() * (longest - shortest)) * reach;
      final half = (thinnest + r.next() * (thickest - thinnest)) / 2;
      lines
        ..moveTo(x - half, 0)
        ..lineTo(x + half, 0)
        ..lineTo(x, length)
        ..close();
    }
    canvas.drawPath(lines, Paint()..color = AnkirenRankLayout.gloomLine);
  }

  @override
  bool shouldRepaint(_GloomPainter old) => old.reach != reach;
}

/// The result: the old class → the new one, the rating with its change,
/// and the points to the next class (after a fall, the one just lost), or
/// the top of the ladder.
class _Result extends StatelessWidget {
  const _Result(this.data);
  final AnkirenRankCelebration data;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final next = Rating.nextBand(data.after);
    final style = rungStyle(data.to.id);
    const display = TextStyle(fontFamily: Fonts.display, height: 1);
    Widget badge(RankBand band, Color color, Color text) => ClassBadge(band,
        color: color,
        textColor: text,
        fontSize: AnkirenRankLayout.resultBadgeFont,
        suffixSize: AnkirenRankLayout.resultBadgeSuffixFont);
    const arrow = Text('→', style: TextStyle(fontWeight: Weights.black, fontSize: AnkirenRankLayout.arrowFont, height: 1));
    const gap = SizedBox(width: AnkirenRankLayout.arrowGap);
    return MangaPanel(
      padding: AnkirenRankLayout.resultPadding,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            badge(data.from, Palette.paper, Palette.mute),
            gap,
            arrow,
            gap,
            badge(data.to, style.color, style.text),
          ]),
        ),
        const SizedBox(height: AnkirenRankLayout.resultGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${data.before.round()}', style: display.copyWith(fontSize: AnkirenRankLayout.ratingOldFont)),
            gap,
            arrow,
            gap,
            Text('${data.after.round()}', style: display.copyWith(fontSize: AnkirenRankLayout.ratingFont)),
            gap,
            RatingChangeTag(data.after.round() - data.before.round(),
                fontSize: AnkirenRankLayout.changeFont, padding: AnkirenRankLayout.changePadding),
          ]),
        ),
        const SizedBox(height: AnkirenRankLayout.resultGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: next == null
              ? Text(s.topClassReached,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenRankLayout.nextFont))
              : NumberedText(
                  s.ratingToNext(s.className(next)),
                  [(next.minRating - data.after).ceil()],
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenRankLayout.nextFont),
                  numberStyle: const TextStyle(
                      fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: AnkirenRankLayout.nextNumberFont),
                ),
        ),
      ]),
    );
  }
}
