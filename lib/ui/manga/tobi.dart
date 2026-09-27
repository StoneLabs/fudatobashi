import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/tobi_art.dart';
import 'vector.dart';

enum TobiPose { standard, waving, fired, cheering, pointing, shocked }

/// Tobi, the mascot. Fills its box (aspect 84:100); arms may reach a little
/// outside it. Idles with a gentle bob and a blink unless [animate] is false
/// or the platform asks for reduced motion.
class Tobi extends StatefulWidget {
  const Tobi({super.key, this.pose = TobiPose.standard, this.animate = true});

  final TobiPose pose;
  final bool animate;

  static VectorArt artOf(TobiPose pose) => _art[pose]!;

  static final _art = {
    TobiPose.standard: TobiArt.compose(TobiArt.standard),
    TobiPose.waving: TobiArt.compose(TobiArt.waving),
    TobiPose.fired: TobiArt.compose(TobiArt.fired),
    TobiPose.cheering: TobiArt.compose(TobiArt.cheering),
    TobiPose.pointing: TobiArt.compose(TobiArt.pointing),
    TobiPose.shocked: TobiArt.compose(TobiArt.shocked),
  };

  @override
  State<Tobi> createState() => _TobiState();
}

class _TobiState extends State<Tobi> with TickerProviderStateMixin {
  late final _bob = AnimationController(vsync: this, duration: TobiStyle.bobPeriod ~/ 2);
  late final _blink = AnimationController(vsync: this, duration: TobiStyle.blinkLength);
  Timer? _blinkTimer;
  bool _moving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Tobi old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final move = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (move == _moving) return;
    _moving = move;
    if (move) {
      _bob.repeat(reverse: true);
      _blinkTimer = Timer.periodic(TobiStyle.blinkEvery, (_) {
        if (TickerMode.valuesOf(context).enabled) _blink.forward(from: 0);
      });
    } else {
      _bob.value = 0;
      _bob.stop();
      _blink.value = 0;
      _blinkTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bob.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = Tobi.artOf(widget.pose);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bob.value);
        return Transform.translate(
          offset: Offset(0, -TobiStyle.bobRise * t),
          child: Transform.rotate(angle: Tilt.bob * t * math.pi / 180, child: child),
        );
      },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _TobiPainter(art, _blink, dpr),
        ),
      ),
    );
  }
}

class _TobiPainter extends CustomPainter {
  _TobiPainter(this.art, this.blink, this.pixelRatio) : super(repaint: blink);
  final VectorArt art;
  final Animation<double> blink;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final b = blink.value;
    final closed = b == 0 ? 0.0 : 1 - (2 * b - 1).abs();
    VectorPainter.paint(
      canvas,
      art,
      Offset.zero & size,
      pixelRatio: pixelRatio,
      eyeOpen: 1 - (1 - TobiStyle.blinkSquash) * closed,
    );
  }

  @override
  bool shouldRepaint(_TobiPainter old) => old.art != art || old.pixelRatio != pixelRatio;
}
