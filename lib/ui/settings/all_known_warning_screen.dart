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

/// A full-screen alarm before Settings' journey → all-known switch, since
/// unlocking every card can't be undone (see [AllKnownWarningStyle]). Pops
/// `true` once the hold confirms it; `false` (or a back gesture) leaves
/// everything unchanged. Under reduced motion nothing flashes, marches or
/// shakes.
class AllKnownWarningScreen extends StatefulWidget {
  const AllKnownWarningScreen({super.key});

  @override
  State<AllKnownWarningScreen> createState() => _AllKnownWarningScreenState();
}

class _AllKnownWarningScreenState extends State<AllKnownWarningScreen> {
  /// How far the hold has armed the switch, 0–1.
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
          step: AllKnownWarningStyle.flashPeriod ~/ 2,
          builder: (context, elapsed, _) {
            final lit = (elapsed.inMicroseconds ~/ (AllKnownWarningStyle.flashPeriod ~/ 2).inMicroseconds).isEven;
            return ColoredBox(
              color: lit ? Palette.alarm : Palette.alarmDeep,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ToneBox(AllKnownWarningStyle.tone, opacity: AllKnownWarningStyle.toneOpacity),
                  ),
                  Positioned.fill(child: _ArmedDarkness(armed: _armed)),
                  SafeArea(
                    child: Stack(
                      children: [
                        EntranceStage(
                          length: AllKnownWarningStyle.entranceLength,
                          child: CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: AllKnownWarningStyle.padding +
                                      const EdgeInsets.all(AllKnownWarningStyle.tapeWidth),
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
          Entrance(AllKnownWarningStyle.shout, child: _Shout(text: s.allKnownWarningShout, lit: lit)),
          const SizedBox(height: Gaps.small),
          Center(child: Entrance(AllKnownWarningStyle.headline, child: _Headline(s.allKnownWarningTitle))),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox.fromSize(
                size: AllKnownWarningStyle.tobi,
                child: _PanickingTobi(armed: _armed, lit: lit),
              ),
            ),
          ),
          NarrationBox(
            child: Text(
              s.allKnownWarningBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: Weights.bold,
                fontSize: AllKnownWarningStyle.bodyFont,
                height: AllKnownWarningStyle.bodyLineHeight,
              ),
            ),
          ),
          const SizedBox(height: Gaps.section),
          Center(
            child: HoldToConfirmButton(
              duration: AllKnownSwitchTuning.holdDuration,
              label: s.allKnownWarningHold(AllKnownSwitchTuning.holdDuration.inSeconds),
              holdingLabel: s.allKnownWarningHolding,
              icon: MangaIcon(IconArt.lock, size: HoldConfirmStyle.icon, color: Palette.paper),
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
              padding: const EdgeInsets.symmetric(horizontal: AllKnownWarningStyle.shoutOutline / 2),
              child: Transform.rotate(
                angle: AllKnownWarningStyle.shoutTurnDeg * math.pi / 180,
                child: OutlinedText(
                  text,
                  outline: Palette.ink,
                  outlineWidth: AllKnownWarningStyle.shoutOutline,
                  style: TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: AllKnownWarningStyle.shoutFont,
                    height: TypeScale.displayLineHeight,
                    color: lit ? AllKnownWarningStyle.shoutLit : AllKnownWarningStyle.shoutDim,
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
        angle: AllKnownWarningStyle.headlineTurnDeg * math.pi / 180,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Palette.ink),
          child: Padding(
            padding: AllKnownWarningStyle.headlinePadding,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: Weights.black,
                fontSize: AllKnownWarningStyle.headlineFont,
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
          const box = AllKnownWarningStyle.tobi;
          final glow = box.width *
              AllKnownWarningStyle.glowSize *
              (lit ? 1 : AllKnownWarningStyle.glowDim) *
              lerpDouble(1, AllKnownWarningStyle.glowArmed, p)!;
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
                      gradient: RadialGradient(colors: AllKnownWarningStyle.glowColors),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Shake(
                  reach: lerpDouble(AllKnownWarningStyle.tobiTremble, AllKnownWarningStyle.tobiTrembleArmed, p)!,
                  step: AllKnownWarningStyle.trembleStep,
                  seed: AllKnownWarningStyle.sfxSeed,
                  child: const Tobi(pose: TobiPose.shocked),
                ),
              ),
              Positioned(
                left: AllKnownWarningStyle.sfxAt.dx,
                top: AllKnownWarningStyle.sfxAt.dy,
                child: Transform.rotate(
                  angle: AllKnownWarningStyle.sfxTurnDeg * math.pi / 180,
                  child: SfxText(
                    p >= AllKnownWarningStyle.sfxArmedFrom ? AllKnownWarningStyle.sfxArmed : AllKnownWarningStyle.sfx,
                    size: AllKnownWarningStyle.sfxFont,
                    color: Palette.sun,
                    seed: AllKnownWarningStyle.sfxSeed,
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
                  Palette.ink.withValues(alpha: AllKnownWarningStyle.armedDarkness * p),
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
        dimension: AllKnownWarningStyle.lampSize,
        child: CustomPaint(painter: _LampPainter(lit: lit)),
      );
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.lit});
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    Rect scaled(Rect r) => Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
    final domeBox = scaled(AllKnownWarningStyle.lampDome);
    final round = Radius.circular(domeBox.width / 2);
    final dome = RRect.fromRectAndCorners(domeBox, topLeft: round, topRight: round);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AllKnownWarningStyle.lampStroke
      ..color = Palette.ink;
    if (lit) {
      final from = Offset(domeBox.center.dx, domeBox.top + domeBox.width / 2);
      for (final deg in AllKnownWarningStyle.lampRays) {
        final dir = Offset(math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180));
        final a = from + dir * AllKnownWarningStyle.lampRayFrom * size.width;
        final b = from + dir * AllKnownWarningStyle.lampRayTo * size.width;
        final ray = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = AllKnownWarningStyle.lampRay + 2 * AllKnownWarningStyle.lampStroke
          ..color = Palette.ink;
        canvas.drawLine(a, b, ray);
        canvas.drawLine(a, b, ray
          ..strokeWidth = AllKnownWarningStyle.lampRay
          ..color = Palette.sun);
      }
    }
    canvas.drawRRect(dome, Paint()..color = lit ? AllKnownWarningStyle.lampLit : AllKnownWarningStyle.lampDim);
    if (lit) canvas.drawOval(scaled(AllKnownWarningStyle.lampShine), Paint()..color = Palette.paper);
    canvas.drawRRect(dome, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaled(AllKnownWarningStyle.lampBase), const Radius.circular(AllKnownWarningStyle.lampStroke)),
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
                  AllKnownWarningStyle.tapeStripe *
                  (elapsed.inMicroseconds / AllKnownWarningStyle.tapeMarch.inMicroseconds),
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
    final inner = outer.deflate(AllKnownWarningStyle.tapeWidth);
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRect(inner));
    paintHazardStripes(canvas, outer, stripe: AllKnownWarningStyle.tapeStripe, shift: shift);
    canvas.restore();
    canvas.drawRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AllKnownWarningStyle.tapeBorder
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_HazardTapePainter old) => old.shift != shift;
}
