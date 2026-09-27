import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/torifuda_spec.dart';
import '../manga/manga.dart';

class _Pop {
  _Pop(this.word, this.color, this.dx, this.above, this.rotationDeg, this.seed, this.start);
  final String word;
  final Color color;

  /// Horizontal position, a fraction of the play area's width.
  final double dx;

  /// Lands in the clear strip above the card (else below it).
  final bool above;
  final double rotationDeg;
  final int seed;
  final Duration start;
}

/// Coloured SFX lettering that pops around the play area on each flick,
/// never over the card: it recomputes the same card rect as [SwipeDeck] and
/// lands in the clear strip above or below it. Runs its own ticker,
/// independent of the swipe deck's timing-critical one, and stops when idle
/// so it never costs a frame outside an active pop.
class SfxOverlay extends StatefulWidget {
  const SfxOverlay({super.key});

  @override
  State<SfxOverlay> createState() => SfxOverlayState();
}

class SfxOverlayState extends State<SfxOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _rng = math.Random();
  final _pops = <_Pop>[];
  Duration _now = Duration.zero;

  /// Pops a random known-answer word, or the don't-know word.
  void pop({required bool dontKnow}) {
    if (_pops.length >= PlaySfxTuning.maxConcurrent) _pops.removeAt(0);
    final word =
        dontKnow ? PlaySfxTuning.dontKnowWord : PlaySfxTuning.knownWords[_rng.nextInt(PlaySfxTuning.knownWords.length)];
    final color = dontKnow ? PlaySfxTuning.dontKnowColor : PlaySfxTuning.knownColor;
    final dx = PlaySfxTuning.horizontalMin + _rng.nextDouble() * (PlaySfxTuning.horizontalMax - PlaySfxTuning.horizontalMin);
    final above = _rng.nextBool();
    final rotation = (_rng.nextDouble() * 2 - 1) * PlaySfxTuning.maxRotationDeg;
    setState(() {
      _pops.add(_Pop(word, color, dx, above, rotation, _rng.nextInt(1 << 20), _ticker.isActive ? _now : Duration.zero));
    });
    if (!_ticker.isActive) {
      _now = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    _pops.removeWhere((p) => _now - p.start > PlaySfxTuning.duration);
    if (_pops.isEmpty) _ticker.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(builder: (context, c) {
          final box = c.biggest;
          final maxH = box.height * SwipeTuning.cardHeightFraction / TorifudaSpec.aspect;
          final w = math.min(box.width * SwipeTuning.cardWidthFraction, maxH);
          final cardRect = Rect.fromCenter(
            center: Offset(box.width / 2, box.height / 2),
            width: w,
            height: w * TorifudaSpec.aspect,
          );
          return Stack(children: [for (final p in _pops) _buildPop(p, box, cardRect)]);
        }),
      );

  Widget _buildPop(_Pop p, Size box, Rect cardRect) {
    final total = PlaySfxTuning.duration.inMicroseconds;
    final t = ((_now - p.start).inMicroseconds / total).clamp(0.0, 1.0);
    final y = p.above
        ? cardRect.top * (1 - PlaySfxTuning.bandBias)
        : cardRect.bottom + (box.height - cardRect.bottom) * PlaySfxTuning.bandBias;
    return Positioned(
      left: p.dx * box.width,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: _opacityAt(t),
          child: Transform.rotate(
            angle: p.rotationDeg * math.pi / 180,
            child: Transform.translate(
              offset: Offset(0, _driftAt(t)),
              child: Transform.scale(
                scale: _scaleAt(t),
                child: SfxText(p.word, size: PlaySfxTuning.fontSize, color: p.color, seed: p.seed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _scaleAt(double t) {
    if (t < PlaySfxTuning.popInEnd) {
      return _lerp(PlaySfxTuning.startScale, PlaySfxTuning.popScale, t / PlaySfxTuning.popInEnd);
    }
    if (t < PlaySfxTuning.settleEnd) {
      final k = (t - PlaySfxTuning.popInEnd) / (PlaySfxTuning.settleEnd - PlaySfxTuning.popInEnd);
      return _lerp(PlaySfxTuning.popScale, PlaySfxTuning.settleScale, k);
    }
    if (t < PlaySfxTuning.holdEnd) return PlaySfxTuning.settleScale;
    final k = (t - PlaySfxTuning.holdEnd) / (1 - PlaySfxTuning.holdEnd);
    return _lerp(PlaySfxTuning.settleScale, PlaySfxTuning.endScale, k);
  }

  static double _opacityAt(double t) {
    if (t < PlaySfxTuning.popInEnd) return t / PlaySfxTuning.popInEnd;
    if (t < PlaySfxTuning.holdEnd) return 1;
    return 1 - (t - PlaySfxTuning.holdEnd) / (1 - PlaySfxTuning.holdEnd);
  }

  static double _driftAt(double t) => t < PlaySfxTuning.holdEnd
      ? 0
      : PlaySfxTuning.endTranslateY * (t - PlaySfxTuning.holdEnd) / (1 - PlaySfxTuning.holdEnd);
}
