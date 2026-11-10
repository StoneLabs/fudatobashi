import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../results/celebration_chrome.dart';
import 'ikkiuchi_rank_timeline.dart';
import 'ikkiuchi_tobi_tag.dart';

/// The rank change page's match card at [elapsed] into it: you and Tobi
/// split by a slanted ink line, the winner's half in the mode's [tone]. Your
/// half: 勝 / 負 and by how many cards (or 棄権). Tobi's: Tobi as the match
/// ended (shocked when beaten, cheering when he won, trembling once beaten)
/// over his rating for the match on his plate ([plateKey]), which swells as
/// the points leave it. The halves slide in and meet with a jolt as VS
/// pops up.
class IkkiuchiRankCard extends StatelessWidget {
  const IkkiuchiRankCard(this.timeline, {super.key, required this.elapsed, required this.tone, required this.plateKey});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final ToneSpec tone;
  final GlobalKey plateKey;

  @override
  Widget build(BuildContext context) {
    final e = elapsed, t = timeline;
    final height = MediaQuery.textScalerOf(context).scale(IkkiuchiRankLayout.cardHeight);
    final grow = Entrances.glide.transform(progressIn(
        e, IkkiuchiRankMotion.cardAt, IkkiuchiRankMotion.halves * IkkiuchiRankMotion.cardGrowShare));
    final jolt = joltAt(e, IkkiuchiRankMotion.clashAt, IkkiuchiRankMotion.clash, IkkiuchiRankLayout.clashJolt,
        IkkiuchiRankLayout.clashSteps, IkkiuchiRankLayout.clashSeed);
    final slide = Entrances.glide.transform(progressIn(e, IkkiuchiRankMotion.cardAt, IkkiuchiRankMotion.halves));
    return Transform.translate(
      offset: jolt,
      child: Opacity(
        opacity: grow,
        child: Transform.scale(
          scale: lerpDouble(IkkiuchiRankLayout.cardFrom, 1, grow)!,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth;
              final mid = w * IkkiuchiRankLayout.cardSplit;
              const slant = IkkiuchiRankLayout.cardSlant / 2;
              final from = IkkiuchiRankLayout.halvesFrom * (1 - slide);
              return Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardPainter(
                        winnerLeft: t.won, tone: tone, pixelRatio: MediaQuery.devicePixelRatioOf(context)),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  right: w - (mid - slant) + IkkiuchiRankLayout.halfGap,
                  child: Opacity(
                    opacity: slide.clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(-from, 0), child: _You(t)),
                  ),
                ),
                Positioned(
                  left: mid + slant + IkkiuchiRankLayout.halfGap,
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Opacity(
                    opacity: slide.clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(from, 0), child: _Tobi(t, e, plateKey)),
                  ),
                ),
                Positioned(
                  left: mid - IkkiuchiRankLayout.vs.width / 2,
                  top: height / 2 - IkkiuchiRankLayout.vs.height / 2,
                  child: EntranceFrame(
                    from: IkkiuchiRankMotion.vsPop.from,
                    progress: easedAt(e, IkkiuchiRankMotion.vsPop),
                    child: const _Vs(),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// Your half: 勝 or 負 in its box, your name over how it was won or lost.
class _You extends StatelessWidget {
  const _You(this.timeline);

  final IkkiuchiRankTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final change = timeline.change;
    final won = timeline.won;
    const words = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiRankLayout.marginFont, height: 1.1);
    const number = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: IkkiuchiRankLayout.marginNumber);
    final margin = switch (change.result) {
      IkkiuchiResult.won => NumberedText(s.ikkiuchiWonByTemplate(change.margin), [change.margin], style: words, numberStyle: number),
      IkkiuchiResult.lost => NumberedText(s.ikkiuchiLostByTemplate(change.margin), [change.margin], style: words, numberStyle: number),
      IkkiuchiResult.gaveUp => Text(s.ikkiuchiResult(IkkiuchiResult.gaveUp), style: words),
    };
    return Padding(
      padding: const EdgeInsets.only(left: IkkiuchiRankLayout.youInset),
      child: Row(children: [
        Container(
          width: IkkiuchiRankLayout.mark,
          height: IkkiuchiRankLayout.mark,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: won ? Palette.ink : Palette.paper,
            border: Border.all(color: Palette.ink, width: IkkiuchiRankLayout.markBorder),
          ),
          child: Text(won ? s.ikkiuchiSlotWon : s.ikkiuchiSlotLost,
              style: TextStyle(
                  fontWeight: Weights.black,
                  fontSize: IkkiuchiRankLayout.markFont,
                  height: 1,
                  color: won ? Palette.paper : IkkiuchiRankLayout.lostInk)),
        ),
        const SizedBox(width: IkkiuchiRankLayout.youGap),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.ikkiuchiYou,
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiRankLayout.nameFont, height: 1)),
              const SizedBox(height: IkkiuchiRankLayout.whoGap),
              margin,
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Tobi's half: Tobi as the match ended over his plate, at the card's foot.
class _Tobi extends StatelessWidget {
  const _Tobi(this.timeline, this.elapsed, this.plateKey);

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final GlobalKey plateKey;

  @override
  Widget build(BuildContext context) {
    final t = timeline, e = elapsed;
    final beaten = t.won && e > (t.climax ? t.impactAt : t.landAt);
    final tremble =
        beaten ? jitterAt(e, IkkiuchiRankMotion.tobiStep, IkkiuchiRankLayout.tobiSeed, IkkiuchiRankLayout.tobiTremble) : Offset.zero;
    final swell = beatAt(e, [t.chipPopAt], IkkiuchiRankMotion.plateSwell);
    return Padding(
      padding: const EdgeInsets.only(right: IkkiuchiRankLayout.tobiInset),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Transform.translate(
          offset: tremble,
          child: SizedBox.fromSize(
            size: IkkiuchiRankLayout.tobi,
            child: Tobi(pose: t.won ? TobiPose.shocked : TobiPose.cheering),
          ),
        ),
        const SizedBox(height: IkkiuchiRankLayout.tobiGap),
        Transform.scale(
          scale: 1 + IkkiuchiRankLayout.plateSwell * swell,
          child: IkkiuchiTobiTag(
            t.change.tobi.round(),
            key: plateKey,
            nameFont: IkkiuchiRankLayout.plateName,
            font: IkkiuchiRankLayout.plateFont,
            padding: IkkiuchiRankLayout.platePadding,
          ),
        ),
      ]),
    );
  }
}

/// VS in sun on an ink parallelogram.
class _Vs extends StatelessWidget {
  const _Vs();

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: IkkiuchiRankLayout.vs,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(IkkiuchiRankLayout.vsSkewDeg * math.pi / 180),
              child: const ColoredBox(color: Palette.ink),
            ),
          ),
          Text(S.of(context).ikkiuchiVs,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: IkkiuchiRankLayout.vsFont,
                  height: 1,
                  letterSpacing: IkkiuchiRankLayout.vsTracking,
                  color: Palette.sun)),
        ]),
      );
}

/// The card's ink: a panel whose top falls toward the left, split by a
/// slanted line, the winner's half (left when [winnerLeft]) in [tone].
class _CardPainter extends CustomPainter {
  const _CardPainter({required this.winnerLeft, required this.tone, required this.pixelRatio});

  final bool winnerLeft;
  final ToneSpec tone;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    const s = IkkiuchiRankLayout.cardStroke / 2, cut = IkkiuchiRankLayout.cardCut;
    final w = size.width, h = size.height;
    final mid = w * IkkiuchiRankLayout.cardSplit;
    const slant = IkkiuchiRankLayout.cardSlant / 2;
    final top = mid + slant, bottom = mid - slant;
    double topAt(double x) => s + cut * (w - x) / w;
    Path shape(List<Offset> corners) => Path()..addPolygon(corners, true);
    final outline = shape([Offset(s, cut + s), Offset(w - s, s), Offset(w - s, h - s), Offset(s, h - s)]);
    final left = shape([Offset(s, cut + s), Offset(top, topAt(top)), Offset(bottom, h - s), Offset(s, h - s)]);
    final right = shape([Offset(top, topAt(top)), Offset(w - s, s), Offset(w - s, h - s), Offset(bottom, h - s)]);
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiRankLayout.cardStroke
      ..strokeJoin = StrokeJoin.miter;
    canvas
      ..drawPath(outline, Paint()..color = Palette.paper)
      ..drawPath(winnerLeft ? left : right, Screentone.paint(tone, pixelRatio))
      ..drawLine(Offset(top, topAt(top)), Offset(bottom, h), ink)
      ..drawPath(outline, ink);
  }

  @override
  bool shouldRepaint(_CardPainter old) =>
      old.winnerLeft != winnerLeft || old.tone != tone || old.pixelRatio != pixelRatio;
}
