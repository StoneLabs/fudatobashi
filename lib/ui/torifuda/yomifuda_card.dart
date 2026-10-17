import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/vector_art.dart';
import '../../config/yomifuda_spec.dart';
import '../../data/poem.dart';
import '../manga/vector.dart';
import 'card_faces.dart';

/// A yomifuda (読み札): the poem as the reader reads it in a match, in four
/// vertical columns with its kimariji in red, readings beside the kanji,
/// lines where a sound is held and the closing stroke where the voice fades.
class YomifudaCard extends StatelessWidget {
  const YomifudaCard({super.key, required this.poem, this.style = YomifudaStyle.standard});

  final Poem poem;
  final YomifudaStyle style;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1 / YomifudaSpec.aspect,
        child: RepaintBoundary(child: CustomPaint(painter: YomifudaPainter(poem: poem, style: style))),
      );
}

/// One piece of a yomifuda column: a run of characters with its reading
/// beside it, or a held sound.
@immutable
class YomifudaToken {
  const YomifudaToken.text(this.text, [this.reading]) : stretch = 0;
  const YomifudaToken.stretch(this.stretch)
      : text = '',
        reading = null;

  final String text;

  /// The furigana beside [text], if any.
  final String? reading;

  /// A held sound's length in em, or 0 for text.
  final double stretch;

  bool get isStretch => stretch > 0;

  /// How many kana of the poem's reading this piece says.
  int get readingLength => isStretch ? 0 : (reading ?? text).length;

  static final _token = RegExp(r'\[([^|\]]+)\|([^\]]+)\]|.');

  /// A column of `Poem.yomifudaColumns` as its pieces, each character of
  /// plain text a piece of its own.
  static List<YomifudaToken> parse(String column) => [
        for (final m in _token.allMatches(column))
          switch (m[0]!) {
            _ when m[1] != null => YomifudaToken.text(m[1]!, m[2]),
            _longMark => const YomifudaToken.stretch(YomifudaSpec.longStretch),
            _shortMark => const YomifudaToken.stretch(YomifudaSpec.shortStretch),
            final ch => YomifudaToken.text(ch),
          },
      ];

  static const _longMark = 'ー';
  static const _shortMark = 'ｰ';
}

class YomifudaPainter extends CustomPainter {
  YomifudaPainter({required this.poem, this.style = YomifudaStyle.standard});

  final Poem poem;
  final YomifudaStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final face = CardFaces.of(style.background);
    if (face != null) {
      canvas.drawImageRect(
        face,
        Rect.fromLTWH(0, 0, face.width.toDouble(), face.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final em = YomifudaSpec.em * size.width;
    final room = (YomifudaSpec.textBottom - YomifudaSpec.textTop) * size.height;
    final columns = [for (final c in poem.yomifudaColumns) YomifudaToken.parse(c)];
    if (columns[1].lastOrNull case final close? when close.isStretch) {
      columns[1].last = const YomifudaToken.stretch(YomifudaSpec.upperEndStretch);
    }
    var red = poem.kimarijiReading.length;
    for (final (i, column) in columns.indexed) {
      final last = i == columns.length - 1;
      final chars = column.fold(0, (n, t) => n + t.text.length);
      final end = last ? YomifudaSpec.endGap + YomifudaSpec.endLength : 0.0;
      final held = column.fold(0.0, (sum, t) => sum + t.stretch) + end;
      final pitch = math.min(em, (room - held * em) / chars);
      final x = YomifudaSpec.columnX[i] * size.width;
      var y = i.isEven
          ? YomifudaSpec.textTop * size.height
          : YomifudaSpec.textBottom * size.height - chars * pitch - held * em;
      for (final token in column) {
        if (token.isStretch) {
          _stretch(canvas, x, y, token.stretch * em, em);
          y += token.stretch * em;
        } else {
          _run(canvas, token, x, y, em, pitch, red);
          red -= token.readingLength;
          y += token.text.length * pitch;
        }
      }
      if (last) {
        y += YomifudaSpec.endGap * em;
        final art = CardArt.yomifudaEnd;
        final width = YomifudaSpec.endLength * em * art.box.width / art.box.height;
        VectorPainter.paint(canvas, art, Rect.fromLTWH(x - width / 2, y, width, YomifudaSpec.endLength * em),
            color: style.ink);
      }
    }
    _number(canvas, size);
  }

  /// [token]'s characters down the column from [top] at [pitch], flattened
  /// when it is under [em], its reading beside them: spread over the run,
  /// or packed and centred on it when longer. The first [red] kana it says
  /// are the kimariji's, and so is each character whose share of the
  /// reading starts among them.
  void _run(Canvas canvas, YomifudaToken token, double x, double top, double em, double pitch, int red) {
    final flat = pitch / em;
    Color colorOf(bool kimariji) => kimariji ? style.kimariji : style.ink;
    final said = token.readingLength;
    for (var k = 0; k < token.text.length; k++) {
      _glyph(canvas, token.text[k], Offset(x, top + (k + 0.5) * pitch), em * YomifudaSpec.glyphScale, flat,
          colorOf(k * said / token.text.length < red));
    }
    final reading = token.reading;
    if (reading == null || reading == token.text) return;
    final step = math.max(token.text.length / reading.length, YomifudaSpec.rubyScale) * pitch;
    final start = top + (token.text.length * pitch - reading.length * step) / 2;
    final rx = x + YomifudaSpec.rubyOffset * em;
    for (var k = 0; k < reading.length; k++) {
      _glyph(canvas, reading[k], Offset(rx, start + (k + 0.5) * step), em * YomifudaSpec.rubyScale, flat,
          colorOf(k < red),
          bold: YomifudaSpec.rubyBold);
    }
  }

  /// [ch] centred on [center], widened by the spec's glyph width and
  /// squeezed down the column by [flat]; [bold] thickens its strokes by
  /// that share of [size].
  void _glyph(Canvas canvas, String ch, Offset center, double size, double flat, Color color, {double bold = 0}) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(YomifudaSpec.glyphWidth, flat);
    for (final tp in _painters(ch, style.fontFamily, size, color, bold)) {
      final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp
        ..paint(canvas, Offset(-tp.width / 2, style.fontCentre * size - baseline))
        ..dispose();
    }
    canvas.restore();
  }

  void _stretch(Canvas canvas, double x, double top, double length, double em) {
    final inset = YomifudaSpec.stretchInset * em;
    final lineX = x + YomifudaSpec.stretchOffset * em;
    canvas.drawLine(
      Offset(lineX, top + inset),
      Offset(lineX, top + length - inset),
      Paint()
        ..color = style.ink
        ..strokeWidth = YomifudaSpec.stretchWidth * em,
    );
  }

  void _number(Canvas canvas, Size size) {
    final font = YomifudaSpec.numberFont * size.width;
    final painters = _painters('${poem.id}', style.numberFontFamily, font, style.number, YomifudaSpec.numberBold);
    for (final tp in painters) {
      final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp
        ..paint(
          canvas,
          Offset(size.width * (1 - YomifudaSpec.numberRight) - tp.width,
              size.height - YomifudaSpec.numberBottom * size.width - baseline),
        )
        ..dispose();
    }
  }

  /// [text] laid out to fill, and when [bold] is above 0 also to stroke its
  /// outline that share of [size] wide over the fill.
  static List<TextPainter> _painters(String text, String family, double size, Color color, double bold) {
    TextPainter painter(Paint paint) => TextPainter(
          text: TextSpan(
              text: text, style: TextStyle(fontFamily: family, fontSize: size, height: 1, foreground: paint)),
          textDirection: TextDirection.ltr,
        )..layout();
    return [
      painter(Paint()..color = color),
      if (bold > 0)
        painter(Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = bold * size),
    ];
  }

  @override
  bool shouldRepaint(YomifudaPainter old) => old.poem.id != poem.id || old.style != style;
}
