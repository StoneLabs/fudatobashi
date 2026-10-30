import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/config/yomifuda_spec.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/ui/help/guide_figures.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';
import 'package:fudatobashi/ui/torifuda/yomifuda_card.dart';

import 'figure_layout.dart';
import 'figure_panel.dart';

/// The karuta guide's pictures, drawn from the app's own cards. They hold
/// no words: what they show is named in the captions under them.

const _cardAspect = TorifudaSpec.width / TorifudaSpec.height;

/// A few taking cards fanned out, to open the guide.
class FanFigure extends StatelessWidget {
  const FanFigure({super.key});

  @override
  Widget build(BuildContext context) {
    const ids = KarutaFigureLayout.fanPoems;
    const width = KarutaFigureLayout.fanCard, height = width / _cardAspect;
    final middle = (ids.length - 1) / 2;
    return Center(
      child: SizedBox(
        width: width + KarutaFigureLayout.fanStep * (ids.length - 1),
        height: height + KarutaFigureLayout.fanLift * 2,
        child: Stack(children: [
          for (final (i, id) in ids.indexed)
            Positioned(
              left: KarutaFigureLayout.fanStep * i,
              top: KarutaFigureLayout.fanLift * ((i - middle) / middle).abs(),
              width: width,
              child: Transform.rotate(
                angle: KarutaFigureLayout.fanTurn * (i - middle) / middle,
                alignment: Alignment.bottomCenter,
                child: TorifudaCard(poem: poems[id], showNumber: false),
              ),
            ),
        ]),
      ),
    );
  }
}

/// [poem] in its two halves, each beside a bar in its colour, with the
/// poet's name.
class PoemHalvesFigure extends StatelessWidget {
  const PoemHalvesFigure({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    const verse = TextStyle(fontWeight: Weights.bold, fontSize: KarutaFigureLayout.poemFont, color: Palette.ink);
    Widget half(String markup, Color color) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: KarutaFigureLayout.halfBar, child: ColoredBox(color: color)),
            const SizedBox(width: KarutaFigureLayout.halfBarGap),
            Expanded(child: RubyText(markup, style: verse)),
          ]),
        );
    return FigurePanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        half(poem.kamiRuby, KarutaFigureLayout.firstHalf),
        const SizedBox(height: KarutaFigureLayout.halfGap),
        half(poem.shimoRuby, KarutaFigureLayout.secondHalf),
        const SizedBox(height: KarutaFigureLayout.halfGap),
        Align(
          alignment: Alignment.centerRight,
          child: RubyText(poem.authorRuby,
              style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small, color: Palette.mute)),
        ),
      ]),
    );
  }
}

/// [poem]'s reading card, an arrow, and its taking card.
class TwoCardsFigure extends StatelessWidget {
  const TwoCardsFigure({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) => FigurePanel(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: KarutaFigureLayout.readingCardWidth, child: YomifudaCard(poem: poem)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KarutaFigureLayout.cardArrowGap).copyWith(
                  top: KarutaFigureLayout.readingCardWidth * YomifudaSpec.aspect / 2 - KarutaFigureLayout.cardArrow / 2),
              child: MangaIcon(IconArt.arrow, size: KarutaFigureLayout.cardArrow),
            ),
            SizedBox(width: KarutaFigureLayout.cardWidth, child: TorifudaCard(poem: poem, showNumber: false)),
          ],
        ),
      );
}

/// The field from above: their three rows at the top, yours at the
/// bottom, a dashed line between, and the card just read in pink.
class FieldFigure extends StatelessWidget {
  const FieldFigure({super.key});

  @override
  Widget build(BuildContext context) => FigurePanel(
        child: LayoutBuilder(builder: (context, box) {
          final geometry = _FieldGeometry(box.maxWidth);
          return SizedBox(
            width: box.maxWidth,
            height: geometry.height,
            child: CustomPaint(painter: _FieldPainter(geometry)),
          );
        }),
      );
}

/// Where the field's cards sit, for a width: each side has
/// [KarutaFigureLayout.fieldRows] cards a row, split left and right of a
/// gap in the middle, in card widths.
class _FieldGeometry {
  _FieldGeometry(this.width) {
    const rows = KarutaFigureLayout.fieldRows;
    final perSide = rows.map((n) => (n + 1) ~/ 2).reduce(math.max);
    final units = perSide * 2 +
        (perSide - 1) * 2 * KarutaFigureLayout.fieldCardGap +
        KarutaFigureLayout.fieldMiddleGap +
        KarutaFigureLayout.fieldInset * 2;
    card = width / units;
    cardHeight = card / KarutaFigureLayout.fieldCardAspect;
    inset = card * KarutaFigureLayout.fieldInset;
    final sideHeight = cardHeight * rows.length + cardHeight * KarutaFigureLayout.fieldRowGap * (rows.length - 1);
    centre = cardHeight * KarutaFigureLayout.fieldCentre;
    height = inset * 2 + sideHeight * 2 + centre;
  }

  final double width;
  late final double card, cardHeight, inset, centre, height;

  /// Every card's box: side 0 is theirs (top), side 1 yours; row 0 is the
  /// row nearest the middle.
  Iterable<(int, int, int, Rect)> cards() sync* {
    const rows = KarutaFigureLayout.fieldRows;
    final step = card * (1 + KarutaFigureLayout.fieldCardGap);
    final rowStep = cardHeight * (1 + KarutaFigureLayout.fieldRowGap);
    for (var side = 0; side < 2; side++) {
      for (final (row, n) in rows.indexed) {
        final top = side == 0
            ? height / 2 - centre / 2 - cardHeight - rowStep * row
            : height / 2 + centre / 2 + rowStep * row;
        final leftCount = n ~/ 2;
        for (var i = 0; i < n; i++) {
          final x = i < leftCount ? inset + step * i : width - inset - card - step * (n - 1 - i);
          yield (side, row, i, Rect.fromLTWH(x, top, card, cardHeight));
        }
      }
    }
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter(this.geometry);

  final _FieldGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = KarutaFigureLayout.fieldLineStroke;
    final y = size.height / 2;
    var x = 0.0;
    for (var i = 0; x < size.width; i++) {
      final dash = KarutaFigureLayout.fieldLineDash[i % KarutaFigureLayout.fieldLineDash.length];
      if (i.isEven) canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), ink);
      x += dash;
    }
    final edge = Paint()
      ..color = Palette.cardFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = KarutaFigureLayout.fieldCardStroke;
    for (final (side, row, i, rect) in geometry.cards()) {
      final read = side == KarutaFigureLayout.fieldReadSide &&
          row == KarutaFigureLayout.fieldReadRow &&
          i == KarutaFigureLayout.fieldReadCard;
      canvas.drawRect(rect, Paint()..color = read ? Palette.pink : Palette.paper);
      canvas.drawRect(rect, read ? (Paint.from(edge)..color = Palette.ink) : edge);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => old.geometry.width != geometry.width;
}

/// The seven one-sound cards' kana, in the order players learn them.
class OneSoundFigure extends StatelessWidget {
  const OneSoundFigure({super.key});

  @override
  Widget build(BuildContext context) => FigurePanel(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: KarutaGuideLayout.tileGap,
          runSpacing: KarutaGuideLayout.tileGap,
          children: [
            for (final kana in KarutaGuideExamples.oneSound.characters)
              GuideKanaTile(kana, poems.byKimariji(kana).kamiReading[0], decides: true),
          ],
        ),
      );
}

/// Two poems that start the same, each needing its third sound.
class KimarijiLongFigure extends StatelessWidget {
  const KimarijiLongFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final first = poems[KarutaGuideExamples.readFirst], second = poems[KarutaGuideExamples.shortened];
    return FigurePanel(
      child: GuideKimarijiRows(rows: [
        GuideKimarijiRow(poem: first, kimariji: first.kimariji),
        GuideKimarijiRow(poem: second, kimariji: second.kimariji),
      ]),
    );
  }
}

/// The same two once the first is read: the second needs one sound less.
class KimarijiChangeFigure extends StatelessWidget {
  const KimarijiChangeFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final first = poems[KarutaGuideExamples.readFirst], second = poems[KarutaGuideExamples.shortened];
    final left = [for (final p in poems.all) if (p.id != first.id) p];
    return FigurePanel(
      child: GuideKimarijiRows(rows: [
        GuideKimarijiRow(poem: first, kimariji: first.kimariji, read: true),
        GuideKimarijiRow(poem: second, kimariji: poems.kimarijiAmong(second, left)),
      ]),
    );
  }
}
