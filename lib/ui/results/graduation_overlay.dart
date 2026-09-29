import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'celebration_chrome.dart';

/// Graduation (卒業!!), once the journey's 100th card is learned: the
/// biggest page of all. Fireworks over a night sky, Tobi flying over the
/// moon, 100/100 and 皆伝 stamped down, and the word that it's time for a
/// real かるた会 (the app switches to all-known mode behind it).
class GraduationOverlay extends StatelessWidget {
  const GraduationOverlay({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: GraduationMotion.length,
      child: CelebrationChrome(
        color: GraduationLayout.night,
        onNext: onNext,
        art: const [
          LinearLayer(angle: GraduationLayout.skyAngle, colors: GraduationLayout.skyColors, stops: GraduationLayout.skyStops),
          ToneLayer(GraduationLayout.stars, fadeAngle: GraduationLayout.starsAngle, fadeStops: GraduationLayout.starsStops),
        ],
        backdrop: [
          const Fireworks(),
          EntranceBuilder(
            _at(GraduationMotion.fullImpactAt),
            builder: (context, t, _) => t > 0 ? const ConfettiRain() : const SizedBox.shrink(),
          ),
        ],
        child: Jolt(
          _at(GraduationMotion.kaidenImpactAt),
          reach: GraduationMotion.joltReach,
          steps: GraduationMotion.joltSteps,
          seed: GraduationMotion.joltSeed + 1,
          child: Jolt(
            _at(GraduationMotion.fullImpactAt),
            reach: GraduationMotion.joltReach,
            steps: GraduationMotion.joltSteps,
            seed: GraduationMotion.joltSeed,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: GraduationLayout.topGap),
              const Entrance(
                GraduationMotion.title,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Gaps.gutter),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: OutlinedText(
                      GraduationLayout.title,
                      style: TextStyle(
                          fontFamily: Fonts.display, fontSize: GraduationLayout.titleFont, color: Palette.sun, height: 1),
                      outline: Palette.ink,
                      outlineWidth: GraduationLayout.titleOutline,
                    ),
                  ),
                ),
              ),
              Entrance(
                GraduationMotion.band,
                child: CelebrationBand(s.graduationBand,
                    inset: GraduationLayout.bandInset,
                    fontSize: GraduationLayout.bandFont,
                    tracking: GraduationLayout.bandTracking,
                    padding: GraduationLayout.bandPadding,
                    turnDeg: GraduationLayout.bandTurnDeg),
              ),
              const Expanded(child: _MoonScene()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Entrance(GraduationMotion.message, child: _Message()),
                  const SizedBox(height: GraduationLayout.sectionGap),
                  Entrance(
                    GraduationMotion.actions,
                    child: CelebrationCta(
                      label: s.graduationCta,
                      sub: s.other.graduationCta,
                      onTap: onNext,
                      height: GraduationLayout.actionHeight,
                      fontSize: GraduationLayout.ctaFont,
                      subFontSize: GraduationLayout.ctaSubFont,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: Gaps.section),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A jolt's stretch of the timeline, from an impact at [delay].
EntranceSpec _at(Duration delay) =>
    EntranceSpec(Entrances.custom, duration: GraduationMotion.jolt, delay: delay, curve: Curves.linear);

/// The moon rising in a glow, Tobi flying over it, and the two stamps
/// landing on either side.
class _MoonScene extends StatelessWidget {
  const _MoonScene();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final radius = math.min(box.maxWidth, box.maxHeight) * GraduationLayout.moonShare / 2;
        final center = Offset(box.maxWidth / 2, box.maxHeight / 2);
        final tobi = Size(radius * GraduationLayout.tobiShare * TobiStyle.aspect, radius * GraduationLayout.tobiShare);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fromRect(
            rect: Rect.fromCircle(center: center, radius: radius * GraduationLayout.glowScale),
            child: const Entrance(
              GraduationMotion.moon,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                      radius: 0.5, colors: GraduationLayout.glowColors, stops: GraduationLayout.glowStops),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: Rect.fromCircle(center: center, radius: radius),
            child: Entrance(
              GraduationMotion.moon,
              child: RepaintBoundary(child: CustomPaint(painter: _MoonPainter(MediaQuery.devicePixelRatioOf(context)))),
            ),
          ),
          Positioned(
            left: GraduationLayout.sfxAt.dx,
            top: GraduationLayout.sfxAt.dy,
            child: Entrance(
              GraduationMotion.sfx,
              child: Transform.rotate(
                angle: GraduationLayout.sfxTurnDeg * math.pi / 180,
                child: const SfxText(GraduationLayout.sfx,
                    size: GraduationLayout.sfxFont, seed: GraduationLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
              ),
            ),
          ),
          EntranceBuilder(
            GraduationMotion.fly,
            child: SizedBox.fromSize(
              size: tobi,
              child: const Sway(
                turnDeg: GraduationMotion.swayTurnDeg,
                lift: GraduationMotion.swayLift,
                period: GraduationMotion.swayPeriod,
                child: Tobi(pose: TobiPose.cheering),
              ),
            ),
            builder: (context, t, child) {
              // A quadratic curve from off the lower left, up and over, to in
              // front of the moon's upper right.
              final u = 1 - t;
              final at = (GraduationLayout.flyFrom * u * u +
                      GraduationLayout.flyVia * 2 * u * t +
                      GraduationLayout.flyTo * t * t) *
                  radius;
              final turn = lerpDouble(GraduationLayout.flyFromTurnDeg, GraduationLayout.flyToTurnDeg, t)!;
              return Positioned(
                left: center.dx + at.dx - tobi.width / 2,
                top: center.dy + at.dy - tobi.height / 2,
                child: Visibility(
                  visible: t > 0,
                  child: Transform.rotate(angle: turn * math.pi / 180, child: child),
                ),
              );
            },
          ),
          Positioned.fromRect(
            rect: Rect.fromCircle(center: center, radius: radius),
            child: const Stack(clipBehavior: Clip.none, children: [
              Align(
                alignment: GraduationLayout.fullStampAt,
                child: Entrance(
                  GraduationMotion.fullStamp,
                  child: _Stamp(GraduationLayout.fullStamp, turnDeg: GraduationLayout.fullStampTurnDeg),
                ),
              ),
              Align(
                alignment: GraduationLayout.kaidenStampAt,
                child: Entrance(
                  GraduationMotion.kaidenStamp,
                  child: _Stamp(GraduationLayout.kaidenStamp, turnDeg: GraduationLayout.kaidenStampTurnDeg, round: true),
                ),
              ),
            ]),
          ),
        ]);
      });
}

/// The moon: a pale disc with toned craters and a shaded rim, outlined in
/// ink.
class _MoonPainter extends CustomPainter {
  const _MoonPainter(this.pixelRatio);
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = GraduationLayout.moon);
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c + GraduationLayout.shadeCut * r, radius: r)),
    );
    canvas.drawPath(shade, Screentone.paint(GraduationLayout.shade, pixelRatio));
    final crater = Screentone.paint(GraduationLayout.crater, pixelRatio);
    for (final (x, y, cr) in GraduationLayout.craters) {
      canvas.drawCircle(c + Offset(x, y) * r, cr * r, crater);
    }
    canvas.drawCircle(
      c,
      r - GraduationLayout.moonBorder / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GraduationLayout.moonBorder
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.pixelRatio != pixelRatio;
}

/// A red seal stamped at a tilt: a rounded box, or a round 判子.
class _Stamp extends StatelessWidget {
  const _Stamp(this.text, {required this.turnDeg, this.round = false});
  final String text;
  final double turnDeg;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final label = Text(text,
        style: const TextStyle(
            fontFamily: Fonts.display, fontSize: GraduationLayout.stampFont, color: GraduationLayout.stampInk, height: 1.1));
    const border = BorderSide(color: GraduationLayout.stampInk, width: GraduationLayout.stampBorder);
    return Transform.rotate(
      angle: turnDeg * math.pi / 180,
      child: round
          ? Container(
              width: GraduationLayout.hankoSize,
              height: GraduationLayout.hankoSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: GraduationLayout.stampPaper, shape: BoxShape.circle, border: Border.fromBorderSide(border)),
              child: FittedBox(fit: BoxFit.scaleDown, child: label),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: GraduationLayout.stampPaper,
                border: const Border.fromBorderSide(border),
                borderRadius: BorderRadius.circular(GraduationLayout.stampRadius),
              ),
              child: Padding(padding: GraduationLayout.stampPadding, child: label),
            ),
    );
  }
}

/// Off to a real かるた会, and the switch to all-known mode.
class _Message extends StatelessWidget {
  const _Message();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      shape: const PanelShape(topLeft: GraduationLayout.messageCut),
      padding: GraduationLayout.messagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(s.graduationKai, style: const TextStyle(fontFamily: Fonts.display, fontSize: GraduationLayout.kaiFont, height: 1.15)),
        const SizedBox(height: Gaps.tight),
        Text(s.graduationKaiNote, style: const TextStyle(fontWeight: Weights.bold, fontSize: GraduationLayout.kaiNoteFont)),
        const SizedBox(height: GraduationLayout.switchGap),
        Entrance(
          GraduationMotion.switchNote,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: InkTag(s.graduationSwitch,
                fontSize: GraduationLayout.switchFont, color: Palette.pink, textColor: Palette.ink),
          ),
        ),
      ]),
    );
  }
}
