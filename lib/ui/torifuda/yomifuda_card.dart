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

  /// The length along the column, em.
  double get length => isStretch ? stretch : text.length.toDouble();

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
    final columns = [for (final c in poem.yomifudaColumns) YomifudaToken.parse(c)];
    final endLength = YomifudaSpec.endGap + YomifudaSpec.endLength;
    double lengthOf(int i) =>
        columns[i].fold(0.0, (sum, t) => sum + t.length) + (i == columns.length - 1 ? endLength : 0);
    final room = (YomifudaSpec.textBottom - YomifudaSpec.textTop) * size.height;
    final longest = [for (var i = 0; i < columns.length; i++) lengthOf(i)].reduce(math.max);
    final em = math.min(YomifudaSpec.em * size.width, room / longest);
    var red = poem.kimarijiReading.length;
    for (final (i, column) in columns.indexed) {
      final x = YomifudaSpec.columnX[i] * size.width;
      var y = i.isEven ? YomifudaSpec.textTop * size.height : YomifudaSpec.textBottom * size.height - lengthOf(i) * em;
      for (final token in column) {
        if (token.isStretch) {
          _stretch(canvas, x, y, token.stretch * em, em);
        } else {
          final color = red > 0 ? style.kimariji : style.ink;
          red -= token.readingLength;
          _run(canvas, token, x, y, em, color);
        }
        y += token.length * em;
      }
      if (i == columns.length - 1) {
        y += YomifudaSpec.endGap * em;
        final art = CardArt.yomifudaEnd;
        final width = YomifudaSpec.endLength * em * art.box.width / art.box.height;
        VectorPainter.paint(canvas, art, Rect.fromLTWH(x - width / 2, y, width, YomifudaSpec.endLength * em),
            color: style.ink);
      }
    }
    _number(canvas, size);
  }

  /// [token]'s characters down the column from [top], its reading beside
  /// them: spread over the run, or packed and centred on it when longer.
  void _run(Canvas canvas, YomifudaToken token, double x, double top, double em, Color color) {
    for (var k = 0; k < token.text.length; k++) {
      _glyph(canvas, token.text[k], Offset(x, top + (k + 0.5) * em), em * YomifudaSpec.glyphScale, color);
    }
    final reading = token.reading;
    if (reading == null || reading == token.text) return;
    final pitch = math.max(token.text.length / reading.length, YomifudaSpec.rubyScale) * em;
    final start = top + (token.text.length * em - reading.length * pitch) / 2;
    final rx = x + YomifudaSpec.rubyOffset * em;
    for (var k = 0; k < reading.length; k++) {
      _glyph(canvas, reading[k], Offset(rx, start + (k + 0.5) * pitch), em * YomifudaSpec.rubyScale, color);
    }
  }

  void _glyph(Canvas canvas, String ch, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: ch, style: TextStyle(fontFamily: style.fontFamily, fontSize: size, height: 1, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }

  void _stretch(Canvas canvas, double x, double top, double length, double em) {
    final inset = YomifudaSpec.stretchInset * em;
    canvas.drawLine(
      Offset(x, top + inset),
      Offset(x, top + length - inset),
      Paint()
        ..color = style.ink
        ..strokeWidth = YomifudaSpec.stretchWidth * em,
    );
  }

  void _number(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${poem.id}',
        style: TextStyle(
            fontFamily: style.numberFontFamily,
            fontSize: YomifudaSpec.numberFont * size.width,
            height: 1,
            color: style.number),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width * (1 - YomifudaSpec.numberRight) - tp.width,
          size.height - YomifudaSpec.numberBottom * size.width - tp.height),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(YomifudaPainter old) => old.poem.id != poem.id || old.style != style;
}
