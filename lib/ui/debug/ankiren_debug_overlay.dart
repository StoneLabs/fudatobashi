import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_game.dart';
import '../ankiren/ankiren_field_view.dart';

/// What the 暗記練 debug layer draws.
enum AnkirenDebugLayer {
  /// Every card's kimariji, face down or not, and the card asked for.
  solutions,

  /// Lines from each middle card to its 友札 on its side: the pair it splits.
  tomofuda,

  /// Each half, its rows and the open middle between its clusters.
  regions,
}

/// The 暗記練 debug layer over [game]'s field, as [placement] puts it on
/// screen: hairlines and monospace labels, never taking taps.
class AnkirenDebugOverlay extends StatelessWidget {
  const AnkirenDebugOverlay({
    super.key,
    required this.game,
    required this.placement,
    required this.layers,
    required this.kimariji,
    required this.tomofuda,
  });

  final AnkirenGame game;
  final FieldPlacement placement;
  final Set<AnkirenDebugLayer> layers;

  /// A card's kimariji, as labelled.
  final String Function(int poemId) kimariji;

  /// A card's 友札.
  final List<int> Function(int poemId) tomofuda;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _DebugPainter(
          field: game.field,
          asked: game.current,
          placement: placement,
          layers: layers,
          kimariji: kimariji,
          tomofuda: tomofuda,
        ),
      );
}

class _DebugPainter extends CustomPainter {
  _DebugPainter({
    required this.field,
    required this.asked,
    required this.placement,
    required this.layers,
    required this.kimariji,
    required this.tomofuda,
  });

  final AnkirenField field;
  final int? asked;
  final FieldPlacement placement;
  final Set<AnkirenDebugLayer> layers;
  final String Function(int poemId) kimariji;
  final List<int> Function(int poemId) tomofuda;

  static const _rowNames = {FieldRow.lower: '下段 lower', FieldRow.middle: '中段 middle', FieldRow.upper: '上段 upper'};

  Paint _stroke(Color color, [double width = AnkirenDebugStyle.hairline]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    if (layers.contains(AnkirenDebugLayer.regions)) _regions(canvas);
    if (layers.contains(AnkirenDebugLayer.tomofuda)) _tomofudaLines(canvas);
    if (layers.contains(AnkirenDebugLayer.solutions)) _solutions(canvas);
  }

  void _regions(Canvas canvas) {
    final rowPaint = _stroke(AnkirenDebugStyle.row);
    final middlePaint = _stroke(AnkirenDebugStyle.middle);
    final middleFill = Paint()..color = AnkirenDebugStyle.middle.withValues(alpha: AnkirenDebugStyle.middleFillOpacity);
    for (final side in FieldSide.values) {
      final halfRect = placement.halfRect(side);
      canvas.drawRect(halfRect, _stroke(AnkirenDebugStyle.half));
      _label(
        canvas,
        side == FieldSide.own ? '自陣 OWN' : '敵陣 OPPONENT',
        halfRect.topRight,
        color: AnkirenDebugStyle.half,
        align: Alignment.topRight,
      );

      final half = field.half(side);
      for (final row in FieldRow.values) {
        final cards = half.row(row);
        if (cards.isEmpty) continue;
        final rects = [for (final id in cards.cards) placement.cardRect(id)!];
        final band = Rect.fromLTRB(
          halfRect.left,
          rects.map((r) => r.top).reduce(math.min),
          halfRect.right,
          rects.map((r) => r.bottom).reduce(math.max),
        );
        canvas.drawRect(band, rowPaint);
        _label(canvas, _rowNames[row]!, band.topLeft, color: AnkirenDebugStyle.row, align: Alignment.topLeft);

        final gap = _openMiddle(side, cards, band);
        if (gap.width <= 0) continue;
        canvas
          ..drawRect(gap, middleFill)
          ..drawRect(gap, middlePaint);
        final label = cards.middle.isEmpty ? 'open' : 'open · ${cards.middle.length} mid';
        _label(canvas, label, gap.center, color: AnkirenDebugStyle.middle, align: Alignment.center);
      }
    }
  }

  /// The open middle of one row on screen: between the inner ends of its
  /// left and right clusters (the half's edges when a cluster is empty).
  /// The opponent's half is turned, so its owner's left cluster is on the
  /// screen's right.
  Rect _openMiddle(FieldSide side, AnkirenRow row, Rect band) {
    final turned = side == FieldSide.opponent;
    final screenLeft = turned ? row.right : row.left;
    final screenRight = turned ? row.left : row.right;
    final from =
        screenLeft.isEmpty ? band.left : screenLeft.map((id) => placement.cardRect(id)!.right).reduce(math.max);
    final to =
        screenRight.isEmpty ? band.right : screenRight.map((id) => placement.cardRect(id)!.left).reduce(math.min);
    return Rect.fromLTRB(from, band.top, to, band.bottom);
  }

  void _tomofudaLines(Canvas canvas) {
    final line = _stroke(AnkirenDebugStyle.tomofuda, AnkirenDebugStyle.strong);
    final dot = Paint()..color = AnkirenDebugStyle.tomofuda;
    for (final side in FieldSide.values) {
      final half = field.half(side);
      for (final id in half.middleCards) {
        final from = placement.cardRect(id)!.center;
        canvas.drawCircle(from, AnkirenDebugStyle.dot, dot);
        for (final t in tomofuda(id).where(half.cards.contains)) {
          final to = placement.cardRect(t)!.center;
          canvas
            ..drawLine(from, to, line)
            ..drawCircle(to, AnkirenDebugStyle.dot, dot);
        }
      }
    }
  }

  void _solutions(Canvas canvas) {
    final middle = {...field.own.middleCards, ...field.opponent.middleCards};
    for (final id in field.cards) {
      final r = placement.cardRect(id)!;
      if (id == asked) {
        canvas.drawRect(
          r.inflate(AnkirenDebugStyle.strong),
          _stroke(AnkirenDebugStyle.asked, AnkirenDebugStyle.strong),
        );
      }
      _label(
        canvas,
        '${kimariji(id)}\n#$id',
        r.bottomCenter,
        color: id == asked
            ? AnkirenDebugStyle.asked
            : middle.contains(id)
                ? AnkirenDebugStyle.middle
                : AnkirenDebugStyle.labelText,
        align: Alignment.bottomCenter,
      );
    }
  }

  /// [text] on a dark chip, the chip's [align] point at [at] (e.g. its top
  /// left with [Alignment.topLeft]).
  void _label(Canvas canvas, String text, Offset at, {required Color color, required Alignment align}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AnkirenDebugStyle.mono,
          fontSize: AnkirenDebugStyle.labelFont,
          height: 1,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = AnkirenDebugStyle.labelPadding;
    final box = Size(tp.width + pad.horizontal, tp.height + pad.vertical);
    final left = at.dx - box.width * (align.x + 1) / 2;
    final top = at.dy - box.height * (align.y + 1) / 2;
    canvas.drawRect(
      Rect.fromLTWH(left, top, box.width, box.height),
      Paint()..color = AnkirenDebugStyle.labelBackground,
    );
    tp
      ..paint(canvas, Offset(left + pad.left, top + pad.top))
      ..dispose();
  }

  @override
  bool shouldRepaint(_DebugPainter old) =>
      old.field != field || old.asked != asked || old.placement != placement || old.layers != layers;
}
