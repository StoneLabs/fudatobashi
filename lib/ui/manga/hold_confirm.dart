import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import 'hazard.dart';
import 'lettering.dart';
import 'seeded_random.dart';

/// A button that confirms only once held for [duration], for actions too
/// consequential for a single tap. It is built like the arming button of
/// something dangerous (see [HoldConfirmStyle]): held, its ring fills and
/// its dome counts the seconds down while it rattles, spins up and, with
/// [haptics], buzzes faster and harder (see [HoldConfirmTuning]). Releasing
/// early drains it back to empty. [onProgress] reports the hold, 0–1, so
/// the page around it can react.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.duration,
    required this.label,
    required this.onConfirmed,
    this.holdingLabel,
    this.icon,
    this.haptics = true,
    this.onProgress,
  });

  final Duration duration;
  final String label;

  /// Shown in place of [label] while the button is held.
  final String? holdingLabel;
  final VoidCallback onConfirmed;

  /// Sits in the dome until the button is held.
  final Widget? icon;
  final bool haptics;
  final ValueChanged<double>? onProgress;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final _fill = AnimationController(vsync: this, duration: widget.duration)
    ..addListener(_onTick)
    ..addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (widget.haptics) unawaited(HapticFeedback.heavyImpact());
      widget.onConfirmed();
    });
  bool _held = false;

  /// Reduced motion: no rattle, spin or drain.
  bool _still = false;

  /// When, into the hold, the next buzz is due.
  Duration _nextBuzz = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
  }

  void _press() {
    setState(() => _held = true);
    _nextBuzz = Duration.zero;
    _fill.forward(from: 0);
  }

  void _release() {
    if (!_held || !mounted) return;
    setState(() => _held = false);
    if (_fill.status == AnimationStatus.completed) return;
    if (_still) {
      _fill.value = 0;
    } else {
      _fill.animateBack(0, duration: HoldConfirmStyle.drain, curve: Curves.easeOut);
    }
  }

  void _onTick() {
    widget.onProgress?.call(_fill.value);
    if (!_held || !widget.haptics) return;
    final elapsed = widget.duration * _fill.value;
    if (elapsed < _nextBuzz) return;
    _buzz(_fill.value);
    final gap = lerpDouble(HoldConfirmTuning.buzzFirst.inMicroseconds, HoldConfirmTuning.buzzLast.inMicroseconds,
        _fill.value * _fill.value)!;
    _nextBuzz = elapsed + Duration(microseconds: gap.round());
  }

  static void _buzz(double progress) {
    final step = HoldConfirmTuning.strengthSteps.where((s) => progress >= s).length;
    unawaited(switch (step) {
      0 => HapticFeedback.selectionClick(),
      1 => HapticFeedback.lightImpact(),
      2 => HapticFeedback.mediumImpact(),
      _ => HapticFeedback.heavyImpact(),
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _held ? widget.holdingLabel ?? widget.label : widget.label;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _fill,
              child: widget.icon,
              builder: (context, icon) {
                final p = _fill.value;
                final into = widget.duration * p;
                var rattle = Offset.zero;
                if (_held && !_still) {
                  final r = SeededRandom(into.inMicroseconds ~/ HoldConfirmStyle.shakeStep.inMicroseconds);
                  rattle = Offset(r.next() * 2 - 1, r.next() * 2 - 1) * HoldConfirmStyle.shakeReach * p * p;
                }
                final secondsLeft = ((widget.duration - into).inMilliseconds / 1000).ceil();
                return Transform.translate(
                  offset: rattle,
                  child: CustomPaint(
                    painter: _ArmingPainter(
                      progress: p,
                      spin: _still ? 0 : HoldConfirmStyle.bezelTurns * 2 * math.pi * p * p,
                      pressed: _held,
                    ),
                    child: SizedBox.square(
                      dimension: HoldConfirmStyle.ringSize,
                      child: Center(child: _held ? _Countdown(secondsLeft) : icon),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: HoldConfirmStyle.labelGap),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.paper,
                border: Border.all(color: Palette.ink, width: Strokes.control),
              ),
              child: Padding(
                padding: HoldConfirmStyle.labelPadding,
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: HoldConfirmStyle.labelFont)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The seconds left, in display lettering on the dome.
class _Countdown extends StatelessWidget {
  const _Countdown(this.seconds);
  final int seconds;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: FittedBox(
          child: OutlinedText(
            '$seconds',
            outline: Palette.ink,
            outlineWidth: HoldConfirmStyle.countOutline,
            style: const TextStyle(
              fontFamily: Fonts.display,
              fontSize: HoldConfirmStyle.countFont,
              color: Palette.paper,
              height: 1,
            ),
          ),
        ),
      );
}

class _ArmingPainter extends CustomPainter {
  _ArmingPainter({required this.progress, required this.spin, required this.pressed});
  final double progress;

  /// The bezel's turn, radians.
  final double spin;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    if (progress > 0) _glow(canvas, center, outer);

    final ring = outer - HoldConfirmStyle.ringStroke / 2;
    canvas.drawCircle(center, ring, _stroke(HoldConfirmStyle.ringStroke, Palette.ink));
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        _stroke(HoldConfirmStyle.fillStroke, _fillColor(progress))..strokeCap = StrokeCap.round,
      );
    }

    final bezelOuter = outer - HoldConfirmStyle.ringStroke;
    final bezelInner = bezelOuter - HoldConfirmStyle.bezel;
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: bezelOuter))
      ..addOval(Rect.fromCircle(center: center, radius: bezelInner)));
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);
    paintHazardStripes(canvas, Rect.fromCircle(center: Offset.zero, radius: bezelOuter),
        stripe: HoldConfirmStyle.bezelStripe);
    canvas.restore();

    final dome = bezelInner * (pressed ? HoldConfirmStyle.pressedScale : 1);
    final domeRect = Rect.fromCircle(center: center, radius: dome);
    canvas.drawCircle(center, bezelInner, Paint()..color = Palette.ink);
    canvas.drawCircle(
      center,
      dome,
      Paint()
        ..shader = const RadialGradient(
          center: HoldConfirmStyle.domeLight,
          radius: HoldConfirmStyle.domeLightRadius,
          colors: [HoldConfirmStyle.domeLit, HoldConfirmStyle.dome],
        ).createShader(domeRect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + HoldConfirmStyle.shineAt * dome,
        width: HoldConfirmStyle.shineSize.width * dome,
        height: HoldConfirmStyle.shineSize.height * dome,
      ),
      Paint()..color = Palette.paper.withValues(alpha: HoldConfirmStyle.shineOpacity),
    );
    canvas.drawCircle(center, dome, _stroke(HoldConfirmStyle.domeBorder, Palette.ink));
  }

  /// A light swelling round the ring as the hold goes on.
  void _glow(Canvas canvas, Offset center, double outer) {
    final reach = outer * (1 + HoldConfirmStyle.glowReach * progress);
    canvas.drawCircle(
      center,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: HoldConfirmStyle.glowColors,
          stops: [outer / reach * HoldConfirmStyle.glowFrom, (outer / reach + 1) / 2, 1],
        ).createShader(Rect.fromCircle(center: center, radius: reach))
        ..color = Color.fromRGBO(0, 0, 0, progress.clamp(0.0, 1.0)),
    );
  }

  static Paint _stroke(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  static Color _fillColor(double t) {
    const colors = HoldConfirmStyle.fillColors;
    final at = t * (colors.length - 1);
    final i = math.min(at.floor(), colors.length - 2);
    return Color.lerp(colors[i], colors[i + 1], at - i)!;
  }

  @override
  bool shouldRepaint(_ArmingPainter old) => old.progress != progress || old.spin != spin || old.pressed != pressed;
}
