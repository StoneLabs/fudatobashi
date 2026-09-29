import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/play_session.dart';

/// A practice card of the tutorial round: TV colour bars with a big kana in
/// the test pattern's circle, labelled 練習札, so it can never pass for a
/// torifuda. The round's cards are [deck]; a [CardRef]'s poem id is the
/// card's number there, not a poem.
class TestCard extends StatelessWidget {
  const TestCard({super.key, required this.number, this.showText = true});

  final int number;

  /// False leaves the circle empty (the card under the top one).
  final bool showText;

  static final List<CardRef> deck = [for (var i = 0; i < TestCardStyle.kana.length; i++) CardRef(i)];

  /// What the player says for [card]: its kana.
  static String kanaOf(CardRef card) => TestCardStyle.kana[card.poemId];

  @override
  Widget build(BuildContext context) {
    const size = TestCardStyle.size;
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: FittedBox(
        child: MediaQuery.withNoTextScaling(
          child: RepaintBoundary(
            child: SizedBox.fromSize(
              size: size,
              child: CustomPaint(
                painter: const _PatternPainter(),
                child: Stack(children: [
                  if (showText)
                    Positioned.fromRect(
                      rect: Rect.fromCircle(center: TestCardStyle.circleCenter, radius: TestCardStyle.circleRadius),
                      child: Center(
                        child: Text(
                          TestCardStyle.kana[number],
                          style: const TextStyle(
                              fontFamily: Fonts.display, fontSize: TestCardStyle.kanaFont, color: Palette.ink, height: 1),
                        ),
                      ),
                    ),
                  Positioned(
                    left: TestCardStyle.channelAt.dx,
                    top: TestCardStyle.channelAt.dy,
                    child: const _ChannelBug(),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: TestCardStyle.inset + TestCardStyle.barsHeight + TestCardStyle.reverseBarsHeight,
                    child: Padding(padding: TestCardStyle.labelPadding, child: _Label(number: number)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelBug extends StatelessWidget {
  const _ChannelBug();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: TestCardStyle.channelPadding,
          child: Text(
            TestCardStyle.channel,
            style: TextStyle(fontFamily: Fonts.display, fontSize: TestCardStyle.channelFont, color: Palette.paper, height: 1.2),
          ),
        ),
      );
}

/// 練習札 · TEST CARD, and the card's number in the round.
class _Label extends StatelessWidget {
  const _Label({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              TestCardStyle.title,
              style: TextStyle(fontFamily: Fonts.display, fontSize: TestCardStyle.titleFont, color: Palette.paper, height: 1.1),
            ),
            Text(
              TestCardStyle.sub,
              style: TextStyle(
                fontFamily: Fonts.ui,
                fontWeight: Weights.black,
                fontSize: TestCardStyle.subFont,
                letterSpacing: TestCardStyle.subTracking * TestCardStyle.subFont,
                color: Palette.sun,
                height: 1.2,
              ),
            ),
          ]),
        ),
      ),
      Text(
        '${number + 1}/${TestCardStyle.kana.length}',
        style: const TextStyle(fontFamily: Fonts.display, fontSize: TestCardStyle.numberFont, color: Palette.paper),
      ),
    ]);
  }
}

/// The ink card, its colour bars and the circle with its crosshair.
class _PatternPainter extends CustomPainter {
  const _PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(TestCardStyle.radius));
    canvas.drawRRect(card, Paint()..color = Palette.ink);
    const inset = TestCardStyle.inset;
    final barWidth = (size.width - 2 * inset) / TestCardStyle.bars.length;
    final fill = Paint();
    for (final (i, color) in TestCardStyle.bars.indexed) {
      canvas.drawRect(Rect.fromLTWH(inset + i * barWidth, inset, barWidth + 0.5, TestCardStyle.barsHeight), fill..color = color);
    }
    for (final (i, color) in TestCardStyle.reverseBars.indexed) {
      canvas.drawRect(
        Rect.fromLTWH(inset + i * barWidth, inset + TestCardStyle.barsHeight, barWidth + 0.5, TestCardStyle.reverseBarsHeight),
        fill..color = color,
      );
    }
    const c = TestCardStyle.circleCenter;
    const r = TestCardStyle.circleRadius;
    canvas.drawCircle(c, r, fill..color = Palette.paper);
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c - const Offset(r, 0), c + const Offset(r, 0), ink..strokeWidth = TestCardStyle.crosshairStroke);
    canvas.drawLine(c - const Offset(0, r), c + const Offset(0, r), ink);
    canvas.drawCircle(c, r * TestCardStyle.innerRing, ink);
    canvas.drawCircle(c, r, ink..strokeWidth = TestCardStyle.circleStroke);
  }

  @override
  bool shouldRepaint(_PatternPainter old) => false;
}
