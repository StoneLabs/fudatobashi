import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/joka.dart';
import '../manga/manga.dart';

/// The card on top of every run's deck: the 序歌 that a reader recites
/// before a match's first card, on black lacquer with gold and vermilion, so
/// it can never pass for a torifuda. Swiping it away starts the run; it is
/// never timed or recorded (see `SwipeDeck.startCard`).
///
/// A fixed composition in card units, scaled to whatever size the deck
/// gives it, like the torifuda itself.
class StartCard extends StatelessWidget {
  const StartCard({super.key, required this.cue});

  /// The swipe hint under the greeting ("SWIPE TO START").
  final String cue;

  @override
  Widget build(BuildContext context) {
    const size = StartCardStyle.size;
    return Semantics(
      label: '$jokaTitle. $cue',
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: FittedBox(
          child: MediaQuery.withNoTextScaling(
            child: SizedBox.fromSize(
              size: size,
              child: Stack(fit: StackFit.expand, children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: const _LacquerPainter(),
                    child: Padding(padding: StartCardStyle.padding, child: _Face(cue: cue)),
                  ),
                ),
                const RepaintBoundary(child: _Sheen()),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.cue});
  final String cue;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const _Title(),
      const SizedBox(height: StartCardStyle.titleGap),
      const Expanded(child: _Poem()),
      const SizedBox(height: StartCardStyle.bandGap),
      _Band(cue: cue),
    ]);
  }
}

/// 序歌 between two gold rules.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    const rule = SizedBox(
      width: StartCardStyle.titleRule,
      height: StartCardStyle.innerFrameWidth,
      child: ColoredBox(color: Palette.gold),
    );
    return const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      rule,
      SizedBox(width: StartCardStyle.titleRuleGap),
      Text(
        jokaTitle,
        style: TextStyle(
          fontFamily: Fonts.joka,
          fontSize: StartCardStyle.titleFont,
          letterSpacing: StartCardStyle.titleTracking * StartCardStyle.titleFont,
          color: Palette.goldLight,
          height: 1,
        ),
      ),
      SizedBox(width: StartCardStyle.titleRuleGap),
      rule,
    ]);
  }
}

/// The poem in scattered columns, right to left, with the seal beside its
/// last column.
class _Poem extends StatelessWidget {
  const _Poem();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: Fonts.joka,
      fontSize: StartCardStyle.jokaFont,
      height: StartCardStyle.jokaLineHeight,
      color: Palette.gold,
    );
    const pitch = StartCardStyle.jokaFont * StartCardStyle.jokaLineHeight;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, phrase) in jokaPhrases.indexed) ...[
            if (i > 0) const SizedBox(width: StartCardStyle.jokaColumnGap),
            Padding(
              padding: EdgeInsets.only(top: StartCardStyle.jokaDrops[i] * pitch),
              child: Column(children: [for (final c in phrase.characters) Text(c, style: style)]),
            ),
          ],
          const SizedBox(width: StartCardStyle.jokaColumnGap),
          const Padding(
            padding: EdgeInsets.only(top: StartCardStyle.sealDrop * pitch),
            child: _Seal(),
          ),
        ],
      ),
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: StartCardStyle.sealTurnDeg * math.pi / 180,
        child: Container(
          width: StartCardStyle.seal,
          height: StartCardStyle.seal,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.vermilion,
            borderRadius: BorderRadius.circular(StartCardStyle.sealRadius),
          ),
          child: const Text(
            StartCardStyle.sealText,
            style: TextStyle(fontFamily: Fonts.display, fontSize: StartCardStyle.sealFont, color: Palette.lacquer, height: 1),
          ),
        ),
      );
}

/// The vermilion band: the greeting, and the swipe cue between marks.
class _Band extends StatelessWidget {
  const _Band({required this.cue});
  final String cue;

  @override
  Widget build(BuildContext context) {
    const rule = Border(
      top: BorderSide(color: Palette.gold, width: StartCardStyle.bandRule),
      bottom: BorderSide(color: Palette.gold, width: StartCardStyle.bandRule),
    );
    const cueStyle = TextStyle(
      fontFamily: Fonts.ui,
      fontWeight: Weights.black,
      fontSize: StartCardStyle.cueFont,
      letterSpacing: StartCardStyle.cueTracking * StartCardStyle.cueFont,
      color: Palette.paper,
      height: 1.1,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(color: Palette.vermilion, border: rule),
      child: Padding(
        padding: StartCardStyle.bandPadding,
        child: Column(children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              jokaGreeting,
              maxLines: 1,
              style: TextStyle(fontFamily: Fonts.joka, fontSize: StartCardStyle.greetingFont, color: Palette.goldLight, height: 1.15),
            ),
          ),
          const SizedBox(height: StartCardStyle.cueGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text(StartCardStyle.cueMarks, style: cueStyle),
              const SizedBox(width: StartCardStyle.cueMarkGap),
              Text(cue.toUpperCase(), maxLines: 1, style: cueStyle),
              const SizedBox(width: StartCardStyle.cueMarkGap),
              const Text(StartCardStyle.cueMarks, style: cueStyle),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The lacquer ground and the gold frame.
class _LacquerPainter extends CustomPainter {
  const _LacquerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final card = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(StartCardStyle.radius)),
      Paint()
        ..shader = const RadialGradient(
          center: StartCardStyle.glowCenter,
          radius: StartCardStyle.glowRadius,
          colors: [Palette.lacquerGlow, Palette.lacquer],
        ).createShader(card),
    );
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: StartCardStyle.goldLeaf,
      ).createShader(card);
    canvas.drawRect(
      card.deflate(StartCardStyle.outerFrameInset),
      gold..strokeWidth = StartCardStyle.outerFrameWidth,
    );
    final inner = card.deflate(StartCardStyle.innerFrameInset);
    canvas.drawRect(inner, gold..strokeWidth = StartCardStyle.innerFrameWidth);
    gold
      ..strokeWidth = StartCardStyle.cornerBracketWidth
      ..strokeCap = StrokeCap.square;
    const b = StartCardStyle.cornerBracket;
    for (final (corner, dx, dy) in [
      (inner.topLeft, 1.0, 1.0),
      (inner.topRight, -1.0, 1.0),
      (inner.bottomLeft, 1.0, -1.0),
      (inner.bottomRight, -1.0, -1.0),
    ]) {
      final at = corner + Offset(dx, dy) * StartCardStyle.cornerBracketInset;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx + dx * b, at.dy)
          ..lineTo(at.dx, at.dy)
          ..lineTo(at.dx, at.dy + dy * b),
        gold,
      );
    }
  }

  @override
  bool shouldRepaint(_LacquerPainter old) => false;
}

/// A band of light gliding across the card now and then.
class _Sheen extends StatelessWidget {
  const _Sheen();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: IdleLoop(
          builder: (context, elapsed, _) {
            final t = (elapsed.inMicroseconds % StartCardStyle.sheenPeriod.inMicroseconds) /
                StartCardStyle.sheenSweep.inMicroseconds;
            return CustomPaint(size: Size.infinite, painter: _SheenPainter(t));
          },
        ),
      );
}

class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t);

  /// The sweep's progress: 0 before it enters, 1 once it has left.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    const w = StartCardStyle.sheenWidth;
    final reach = size.width + size.height;
    final x = -w + (reach + w) * t;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(StartCardStyle.radius)));
    canvas.translate(x, 0);
    canvas.skew(-math.tan(StartCardStyle.sheenTurnDeg * math.pi / 180), 0);
    final band = Rect.fromLTWH(0, 0, w, size.height);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(colors: [
          Palette.goldLight.withValues(alpha: 0),
          Palette.goldLight.withValues(alpha: StartCardStyle.sheenAlpha),
          Palette.goldLight.withValues(alpha: 0),
        ]).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}
