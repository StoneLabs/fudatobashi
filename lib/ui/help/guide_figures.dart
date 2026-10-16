import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/romaji.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// The karuta guide's pictures (`KarutaGuideScreen`), drawn from the app's
/// own cards and lines. They are pictures, so the font scale leaves their
/// lettering alone; captions and labels around them still follow it.

const _cardAspect = TorifudaSpec.width / TorifudaSpec.height;

/// A few taking cards fanned out, to open the guide.
class GuideFan extends StatelessWidget {
  const GuideFan({super.key});

  @override
  Widget build(BuildContext context) {
    const ids = KarutaGuideLayout.fanPoems;
    const width = KarutaGuideLayout.fanCard, height = width / _cardAspect;
    final middle = (ids.length - 1) / 2;
    return Center(
      child: SizedBox(
        width: width + KarutaGuideLayout.fanStep * (ids.length - 1),
        height: height + KarutaGuideLayout.fanLift * 2,
        child: Stack(children: [
          for (final (i, id) in ids.indexed)
            Positioned(
              left: KarutaGuideLayout.fanStep * i,
              top: KarutaGuideLayout.fanLift * ((i - middle) / middle).abs(),
              width: width,
              child: Transform.rotate(
                angle: KarutaGuideLayout.fanTurn * (i - middle) / middle,
                alignment: Alignment.bottomCenter,
                child: TorifudaCard(poem: poems[id], showNumber: false),
              ),
            ),
        ]),
      ),
    );
  }
}

/// [poem] in its two halves, each under its tag, with the poet's name.
class GuidePoemHalves extends StatelessWidget {
  const GuidePoemHalves({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const verse = TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.poemFont, color: Palette.ink);
    Widget half(String tag, String markup, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkTag(tag.toUpperCase(), color: color, textColor: color == Palette.ink ? Palette.paper : Palette.ink),
            const SizedBox(height: Gaps.tight),
            RubyText(markup, style: verse),
          ],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      half(s.guideFirstHalf, poem.kamiRuby, Palette.ink),
      const SizedBox(height: KarutaGuideLayout.halfGap),
      half(s.guideSecondHalf, poem.shimoRuby, Palette.pink),
      const SizedBox(height: KarutaGuideLayout.halfGap),
      Align(
        alignment: Alignment.centerRight,
        child: RubyText(poem.authorRuby,
            style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small, color: Palette.mute)),
      ),
    ]);
  }
}

/// [poem]'s reading card, an arrow, and its taking card, each named under it.
class GuideTwoCards extends StatelessWidget {
  const GuideTwoCards({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget card(Widget picture, String name, String note) => SizedBox(
          width: KarutaGuideLayout.cardWidth,
          child: Column(children: [
            MediaQuery.withNoTextScaling(child: picture),
            const SizedBox(height: KarutaGuideLayout.captionGap),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: Weights.black, fontSize: KarutaGuideLayout.captionFont)),
            Text(note,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: Weights.bold, fontSize: KarutaGuideLayout.captionFont, color: Palette.inkSoft)),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card(GuideYomifuda(poem: poem), s.guideYomifuda, s.guideYomifudaNote),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KarutaGuideLayout.cardArrowGap)
              .copyWith(top: KarutaGuideLayout.cardWidth / _cardAspect / 2 - KarutaGuideLayout.cardArrow / 2),
          child: MangaIcon(IconArt.arrow, size: KarutaGuideLayout.cardArrow),
        ),
        card(TorifudaCard(poem: poem, showNumber: false), s.guideTorifuda, s.guideTorifudaNote),
      ],
    );
  }
}

/// A reading card: the whole poem in columns, right to left, a phrase a
/// column, and the poet's name last.
class GuideYomifuda extends StatelessWidget {
  const GuideYomifuda({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final phrases = [...poem.kami.split(Ruby.phraseBreak), ...poem.shimo.split(Ruby.phraseBreak)];
    Widget column(String text, double size) => Column(
          children: [
            for (final ch in text.characters)
              Text(ch,
                  style: TextStyle(
                      fontWeight: Weights.medium,
                      fontSize: size,
                      height: KarutaGuideLayout.yomifudaLineHeight,
                      color: Palette.ink)),
          ],
        );
    return AspectRatio(
      aspectRatio: _cardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KarutaGuideLayout.yomifudaPaper,
          border: Border.all(color: KarutaGuideLayout.yomifudaEdge, width: KarutaGuideLayout.yomifudaBorder),
        ),
        child: Padding(
          padding: KarutaGuideLayout.yomifudaPadding,
          child: FittedBox(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final phrase in phrases) ...[
                  column(phrase, KarutaGuideLayout.yomifudaFont),
                  const SizedBox(width: KarutaGuideLayout.yomifudaColumnGap),
                ],
                column(poem.author, KarutaGuideLayout.yomifudaAuthorFont),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The field from above: their three rows at the top, yours at the bottom,
/// a dashed line between, and the card just read in pink; a tag names each
/// side and a key names the pink card.
class GuideField extends StatelessWidget {
  const GuideField({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkTag(s.guideTheirSide.toUpperCase()),
      const SizedBox(height: Gaps.small),
      LayoutBuilder(builder: (context, box) {
        final geometry = _FieldGeometry(box.maxWidth);
        return SizedBox(
          width: box.maxWidth,
          height: geometry.height,
          child: CustomPaint(painter: _FieldPainter(geometry)),
        );
      }),
      const SizedBox(height: Gaps.small),
      Row(children: [
        InkTag(s.guideYourSide.toUpperCase()),
        const Spacer(),
        const SizedBox.square(
          dimension: KarutaGuideLayout.fieldLegendSwatch,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.pink,
              border: Border.fromBorderSide(
                  BorderSide(color: Palette.ink, width: KarutaGuideLayout.fieldCardStroke)),
            ),
          ),
        ),
        const SizedBox(width: Gaps.small),
        Flexible(
          child: Text(s.guideFieldRead,
              style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.captionFont)),
        ),
      ]),
    ]);
  }
}

/// Where the field's cards sit, for a width: each side has
/// [KarutaGuideLayout.fieldRows] cards a row, split left and right of a
/// gap in the middle, in card widths.
class _FieldGeometry {
  _FieldGeometry(this.width) {
    const rows = KarutaGuideLayout.fieldRows;
    final perSide = rows.map((n) => (n + 1) ~/ 2).reduce(math.max);
    final units = perSide * 2 +
        (perSide - 1) * 2 * KarutaGuideLayout.fieldCardGap +
        KarutaGuideLayout.fieldMiddleGap +
        KarutaGuideLayout.fieldInset * 2;
    card = width / units;
    cardHeight = card / KarutaGuideLayout.fieldCardAspect;
    inset = card * KarutaGuideLayout.fieldInset;
    final sideHeight = cardHeight * rows.length + cardHeight * KarutaGuideLayout.fieldRowGap * (rows.length - 1);
    centre = cardHeight * KarutaGuideLayout.fieldCentre;
    height = inset * 2 + sideHeight * 2 + centre;
  }

  final double width;
  late final double card, cardHeight, inset, centre, height;

  /// Every card's box: side 0 is theirs (top), side 1 yours; row 0 is the
  /// row nearest the middle.
  Iterable<(int, int, int, Rect)> cards() sync* {
    const rows = KarutaGuideLayout.fieldRows;
    final step = card * (1 + KarutaGuideLayout.fieldCardGap);
    final rowStep = cardHeight * (1 + KarutaGuideLayout.fieldRowGap);
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
      ..strokeWidth = KarutaGuideLayout.fieldLineStroke;
    final y = size.height / 2;
    var x = 0.0;
    for (var i = 0; x < size.width; i++) {
      final dash = KarutaGuideLayout.fieldLineDash[i % KarutaGuideLayout.fieldLineDash.length];
      if (i.isEven) canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), ink);
      x += dash;
    }
    final edge = Paint()
      ..color = Palette.cardFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = KarutaGuideLayout.fieldCardStroke;
    for (final (side, row, i, rect) in geometry.cards()) {
      final read = side == KarutaGuideLayout.fieldReadSide &&
          row == KarutaGuideLayout.fieldReadRow &&
          i == KarutaGuideLayout.fieldReadCard;
      canvas.drawRect(rect, Paint()..color = read ? Palette.pink : Palette.paper);
      canvas.drawRect(rect, read ? (Paint.from(edge)..color = Palette.ink) : edge);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => old.geometry.width != geometry.width;
}

/// One kana as a tile, red when it is the sound that decides, grey when
/// its card has been read; the romaji of how it's read under it when the
/// player reads romaji.
class _KanaTile extends StatelessWidget {
  const _KanaTile(this.kana, this.reading, {this.decides = false, this.faded = false});

  final String kana, reading;
  final bool decides, faded;

  @override
  Widget build(BuildContext context) {
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox.square(
        dimension: KarutaGuideLayout.tile,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: decides ? Palette.alarm : (faded ? Palette.desk : Palette.paper),
            border: Border.all(color: faded ? Palette.mute : Palette.ink, width: KarutaGuideLayout.tileBorder),
          ),
          child: Center(
            child: Text(kana,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: KarutaGuideLayout.tileFont,
                    height: 1,
                    color: decides ? Palette.paper : (faded ? Palette.mute : Palette.ink))),
          ),
        ),
      ),
      if (romaji) ...[
        const SizedBox(height: KarutaGuideLayout.romajiGap),
        Text(hepburn(reading),
            style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.romajiFont)),
      ],
    ]);
  }
}

/// The seven one-sound cards' kana, in the order players learn them.
class GuideOneSoundTiles extends StatelessWidget {
  const GuideOneSoundTiles({super.key});

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: KarutaGuideLayout.tileGap,
          runSpacing: KarutaGuideLayout.tileGap,
          children: [
            for (final kana in KarutaGuideExamples.oneSound.characters)
              _KanaTile(kana, poems.byKimariji(kana).kamiReading[0], decides: true),
          ],
        ),
      );
}

/// One line of a kimariji picture: [kimariji] as tiles, its last kana
/// red, an arrow and [poem]'s taking card. A [read] card is shown already
/// gone: grey tiles and a faded card under a stamp.
class GuideKimarijiRow {
  const GuideKimarijiRow({required this.poem, required this.kimariji, this.read = false});

  final Poem poem;
  final String kimariji;
  final bool read;
}

/// Kimariji lines one under another, their arrows lined up.
class GuideKimarijiRows extends StatelessWidget {
  const GuideKimarijiRows({super.key, required this.rows});

  final List<GuideKimarijiRow> rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final most = rows.map((r) => r.kimariji.length).reduce(math.max);
    const cardHeight = KarutaGuideLayout.kimarijiCard / _cardAspect;
    return MediaQuery.withNoTextScaling(
      child: Column(children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: KarutaGuideLayout.kimarijiRowGap),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: most * KarutaGuideLayout.tile + (most - 1) * KarutaGuideLayout.tileGap,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (var k = 0; k < row.kimariji.length; k++) ...[
                  if (k > 0) const SizedBox(width: KarutaGuideLayout.tileGap),
                  _KanaTile(row.kimariji[k], row.poem.kamiReading[k],
                      decides: !row.read && k == row.kimariji.length - 1, faded: row.read),
                ],
              ]),
            ),
            const SizedBox(width: KarutaGuideLayout.kimarijiArrowGap),
            MangaIcon(IconArt.arrow,
                size: KarutaGuideLayout.kimarijiArrow, color: row.read ? Palette.mute : Palette.ink),
            const SizedBox(width: KarutaGuideLayout.kimarijiArrowGap),
            SizedBox(
              width: KarutaGuideLayout.kimarijiCard,
              height: cardHeight,
              child: row.read
                  ? Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                      Opacity(
                        opacity: KarutaGuideLayout.readOpacity,
                        child: TorifudaCard(poem: row.poem, showNumber: false),
                      ),
                      _Stamp(s.guideReadStamp),
                    ])
                  : TorifudaCard(poem: row.poem, showNumber: false),
            ),
          ]),
        ],
      ]),
    );
  }
}

/// A red hanko-style stamp across a card that has been read.
class _Stamp extends StatelessWidget {
  const _Stamp(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: KarutaGuideLayout.stampTurn,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            border: Border.all(color: Palette.alarm, width: KarutaGuideLayout.stampBorder),
          ),
          child: Padding(
            padding: KarutaGuideLayout.stampPadding,
            child: Text(text.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: KarutaGuideLayout.stampFont, color: Palette.alarm)),
          ),
        ),
      );
}
