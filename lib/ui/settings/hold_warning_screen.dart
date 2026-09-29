import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// A full-screen alarm before something that can't be undone (see
/// [HoldWarningStyle]), confirmed only by holding its button for
/// [HoldWarningTuning.holdDuration]. Pops `true` once the hold confirms it;
/// `false` (or a back gesture) leaves everything unchanged. Under reduced
/// motion nothing flashes, marches or shakes.
class HoldWarningScreen extends StatefulWidget {
  const HoldWarningScreen({
    super.key,
    required this.headline,
    required this.body,
    required this.holdLabel,
    required this.icon,
  });

  /// Before Settings' journey → all-known switch, which unlocks every card
  /// for good.
  HoldWarningScreen.allKnown(S s, {Key? key})
      : this(
          key: key,
          headline: s.allKnownWarningTitle,
          body: s.allKnownWarningBody,
          holdLabel: s.allKnownWarningHold(HoldWarningTuning.holdDuration.inSeconds),
          icon: IconArt.lock,
        );

  /// Before Settings' Reset all data, which erases everything.
  HoldWarningScreen.resetAll(S s, {Key? key})
      : this(
          key: key,
          headline: s.resetAllWarningTitle,
          body: s.resetAllWarningBody,
          holdLabel: s.resetAllWarningHold(HoldWarningTuning.holdDuration.inSeconds),
          icon: IconArt.refresh,
        );

  /// What can't be undone, on an ink slab under 警告!!.
  final String headline;
  final String body;
  final String holdLabel;

  /// Sits in the hold button's dome until it is held.
  final VectorArt icon;

  @override
  State<HoldWarningScreen> createState() => _HoldWarningScreenState();
}

class _HoldWarningScreenState extends State<HoldWarningScreen> {
  /// How far the hold has armed it, 0–1.
  final _armed = ValueNotifier<double>(0);
  late final bool _haptics = ProgressScope.read(context).settings.haptics;

  @override
  void initState() {
    super.initState();
    if (_haptics) unawaited(HapticFeedback.heavyImpact());
  }

  @override
  void dispose() {
    _armed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.alarmDeep,
        body: IdleLoop(
          step: HoldWarningStyle.flashPeriod ~/ 2,
          builder: (context, elapsed, _) {
            final lit = (elapsed.inMicroseconds ~/ (HoldWarningStyle.flashPeriod ~/ 2).inMicroseconds).isEven;
            return ColoredBox(
              color: lit ? Palette.alarm : Palette.alarmDeep,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ToneBox(HoldWarningStyle.tone, opacity: HoldWarningStyle.toneOpacity),
                  ),
                  Positioned.fill(child: _ArmedDarkness(armed: _armed)),
                  SafeArea(
                    child: Stack(
                      children: [
                        EntranceStage(
                          length: HoldWarningStyle.entranceLength,
                          child: CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: HoldWarningStyle.padding +
                                      const EdgeInsets.all(HoldWarningStyle.tapeWidth),
                                  child: _content(context, s, lit),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Positioned.fill(child: IgnorePointer(child: _HazardTape())),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, S s, bool lit) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            InkTag(s.other.warning, textColor: Palette.sun),
            const Spacer(),
            InkIconButton(icon: IconArt.close, semanticLabel: s.cancel, onTap: () => Navigator.of(context).pop(false)),
          ]),
          const SizedBox(height: Gaps.small),
          Entrance(HoldWarningStyle.shout, child: _Shout(text: s.warningShout, lit: lit)),
          const SizedBox(height: Gaps.small),
          Center(child: Entrance(HoldWarningStyle.headline, child: _Headline(widget.headline))),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox.fromSize(
                size: HoldWarningStyle.tobi,
                child: _PanickingTobi(armed: _armed, lit: lit),
              ),
            ),
          ),
          NarrationBox(
            child: Text(
              widget.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: Weights.bold,
                fontSize: HoldWarningStyle.bodyFont,
                height: HoldWarningStyle.bodyLineHeight,
              ),
            ),
          ),
          const SizedBox(height: Gaps.section),
          Center(
            child: HoldToConfirmButton(
              duration: HoldWarningTuning.holdDuration,
              label: widget.holdLabel,
              holdingLabel: s.warningHolding,
              icon: MangaIcon(widget.icon, size: HoldConfirmStyle.icon, color: Palette.paper),
              haptics: _haptics,
              onProgress: (p) => _armed.value = p,
              onConfirmed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );
}

/// 警告!! (or WARNING!!) between two warning lamps, its fill flashing with
/// the page and the lamps lit in turn.
class _Shout extends StatelessWidget {
  const _Shout({required this.text, required this.lit});
  final String text;
  final bool lit;

  @override
  Widget build(BuildContext context) => Row(children: [
        _WarningLamp(lit: lit),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: HoldWarningStyle.shoutOutline / 2),
              child: Transform.rotate(
                angle: HoldWarningStyle.shoutTurnDeg * math.pi / 180,
                child: OutlinedText(
                  text,
                  outline: Palette.ink,
                  outlineWidth: HoldWarningStyle.shoutOutline,
                  style: TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: HoldWarningStyle.shoutFont,
                    height: TypeScale.displayLineHeight,
                    color: lit ? HoldWarningStyle.shoutLit : HoldWarningStyle.shoutDim,
                  ),
                ),
              ),
            ),
          ),
        ),
        _WarningLamp(lit: !lit),
      ]);
}

/// "This can't be undone", in paper on a tilted ink slab.
class _Headline extends StatelessWidget {
  const _Headline(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: HoldWarningStyle.headlineTurnDeg * math.pi / 180,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Palette.ink),
          child: Padding(
            padding: HoldWarningStyle.headlinePadding,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: Weights.black,
                fontSize: HoldWarningStyle.headlineFont,
                color: Palette.paper,
              ),
            ),
          ),
        ),
      );
}

/// Tobi in a panic: shocked, trembling in a pulsing siren glow, crying out.
/// The tremble and the glow grow as the hold arms, and the cry turns to a
/// scream near the end.
class _PanickingTobi extends StatelessWidget {
  const _PanickingTobi({required this.armed, required this.lit});
  final ValueListenable<double> armed;
  final bool lit;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: armed,
        builder: (context, p, _) {
          const box = HoldWarningStyle.tobi;
          final glow = box.width *
              HoldWarningStyle.glowSize *
              (lit ? 1 : HoldWarningStyle.glowDim) *
              lerpDouble(1, HoldWarningStyle.glowArmed, p)!;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: OverflowBox(
                  maxWidth: glow,
                  maxHeight: glow,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: HoldWarningStyle.glowColors),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Shake(
                  reach: lerpDouble(HoldWarningStyle.tobiTremble, HoldWarningStyle.tobiTrembleArmed, p)!,
                  step: HoldWarningStyle.trembleStep,
                  seed: HoldWarningStyle.sfxSeed,
                  child: const Tobi(pose: TobiPose.shocked),
                ),
              ),
              Positioned(
                left: HoldWarningStyle.sfxAt.dx,
                top: HoldWarningStyle.sfxAt.dy,
                child: Transform.rotate(
                  angle: HoldWarningStyle.sfxTurnDeg * math.pi / 180,
                  child: SfxText(
                    p >= HoldWarningStyle.sfxArmedFrom ? HoldWarningStyle.sfxArmed : HoldWarningStyle.sfx,
                    size: HoldWarningStyle.sfxFont,
                    color: Palette.sun,
                    seed: HoldWarningStyle.sfxSeed,
                    vertical: true,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

/// The page darkening round its edges as the hold arms.
class _ArmedDarkness extends StatelessWidget {
  const _ArmedDarkness({required this.armed});
  final ValueListenable<double> armed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: armed,
          builder: (context, p, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1,
                colors: [
                  const Color(0x00000000),
                  Palette.ink.withValues(alpha: HoldWarningStyle.armedDarkness * p),
                ],
              ),
            ),
          ),
        ),
      );
}

/// A warning lamp: an ink base under a red dome that throws sun rays while
/// [lit].
class _WarningLamp extends StatelessWidget {
  const _WarningLamp({required this.lit});
  final bool lit;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: HoldWarningStyle.lampSize,
        child: CustomPaint(painter: _LampPainter(lit: lit)),
      );
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.lit});
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    Rect scaled(Rect r) => Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
    final domeBox = scaled(HoldWarningStyle.lampDome);
    final round = Radius.circular(domeBox.width / 2);
    final dome = RRect.fromRectAndCorners(domeBox, topLeft: round, topRight: round);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = HoldWarningStyle.lampStroke
      ..color = Palette.ink;
    if (lit) {
      final from = Offset(domeBox.center.dx, domeBox.top + domeBox.width / 2);
      for (final deg in HoldWarningStyle.lampRays) {
        final dir = Offset(math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180));
        final a = from + dir * HoldWarningStyle.lampRayFrom * size.width;
        final b = from + dir * HoldWarningStyle.lampRayTo * size.width;
        final ray = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = HoldWarningStyle.lampRay + 2 * HoldWarningStyle.lampStroke
          ..color = Palette.ink;
        canvas.drawLine(a, b, ray);
        canvas.drawLine(a, b, ray
          ..strokeWidth = HoldWarningStyle.lampRay
          ..color = Palette.sun);
      }
    }
    canvas.drawRRect(dome, Paint()..color = lit ? HoldWarningStyle.lampLit : HoldWarningStyle.lampDim);
    if (lit) canvas.drawOval(scaled(HoldWarningStyle.lampShine), Paint()..color = Palette.paper);
    canvas.drawRRect(dome, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaled(HoldWarningStyle.lampBase), const Radius.circular(HoldWarningStyle.lampStroke)),
      Paint()..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.lit != lit;
}

/// Hazard tape round the page's edges, marching.
class _HazardTape extends StatelessWidget {
  const _HazardTape();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: IdleLoop(
          builder: (context, elapsed, _) => CustomPaint(
            size: Size.infinite,
            painter: _HazardTapePainter(
              shift: 2 *
                  HoldWarningStyle.tapeStripe *
                  (elapsed.inMicroseconds / HoldWarningStyle.tapeMarch.inMicroseconds),
            ),
          ),
        ),
      );
}

class _HazardTapePainter extends CustomPainter {
  _HazardTapePainter({required this.shift});
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final inner = outer.deflate(HoldWarningStyle.tapeWidth);
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRect(inner));
    paintHazardStripes(canvas, outer, stripe: HoldWarningStyle.tapeStripe, shift: shift);
    canvas.restore();
    canvas.drawRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = HoldWarningStyle.tapeBorder
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_HazardTapePainter old) => old.shift != shift;
}
