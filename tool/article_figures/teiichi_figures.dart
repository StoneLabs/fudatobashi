import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_geometry.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/manga/geometry.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/teiichi/teiichi_zoom.dart';

import 'figure_layout.dart';
import 'figure_panel.dart';

/// The 定位置 guide's pictures: your side from where you sit, laid out as
/// the game lays it out once grown for play (`TeiichiZoom`), the centre
/// line above it. Where a picture compares two sides they come one panel
/// above the other, so that their cards stay large enough to read on a
/// phone. They hold no words: what they show is named in the captions,
/// and only a kimariji short enough to fit under its card gets its
/// romaji there.

typedef _Rows = List<(List<int>, List<int>, List<int>)>;

AnkirenHalf _half(_Rows rows) => AnkirenHalf([
      for (final (left, middle, right) in rows.reversed) AnkirenRow(left: left, middle: middle, right: right),
    ]);

/// The card pitches across a row that every one of [halves] fits in once
/// grown for play.
double _slots(Iterable<AnkirenHalf> halves) => halves.map((half) {
      final field = AnkirenField(own: half, opponent: AnkirenHalf.empty());
      final zoom = TeiichiZoom.limit(field, TeiichiFigureLayout.zoomArea, 0);
      return FieldGeometry.slotsAcross(TeiichiTargets.geometryOf(half).width / zoom);
    }).reduce(math.max);

FieldGeometry _grown(AnkirenHalf own, double slots, [AnkirenHalf? theirs]) => FieldGeometry.of(
    AnkirenField(own: own, opponent: theirs ?? AnkirenHalf.empty()),
    folded: false,
    trueSlots: slots);

enum _Mark { outlined, oneSound, sixSound, lookAlike, moved }

/// A side to draw: [half]'s cards, some [marks]ed, the [gone] ones as empty
/// places, and the cards that moved with where they lay [before].
class _Side {
  const _Side(this.half, {this.marks = const {}, this.gone = const {}, this.before = const {}});

  final AnkirenHalf half;
  final Map<int, _Mark> marks;
  final Set<int> gone;
  final Map<int, FieldRect> before;
}

/// A side as cards, or with its rows' clusters as blocks in
/// [TeiichiFigureLayout.fullness]'s screentones.
class _SideView extends StatelessWidget {
  const _SideView(this.side, {required this.slots, this.blocks = false});

  final _Side side;
  final double slots;
  final bool blocks;

  static const _kana = {_Mark.oneSound, _Mark.sixSound, _Mark.lookAlike};
  static const _labelled = {_Mark.oneSound, _Mark.lookAlike};

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final geometry = _grown(side.half, slots);
        final scale = box.maxWidth / geometry.width;
        final top = AnkirenFieldSize.cardH * scale * TeiichiFigureLayout.centreLine;
        Rect place(FieldRect r) =>
            Rect.fromLTWH(r.x * scale, top + r.y * scale, r.w * scale, r.h * scale).deflate(TeiichiFigureLayout.cardInset);
        final cards = {for (final MapEntry(:key, :value) in geometry.half(FieldSide.own).entries) key: place(value)};
        final kana = {
          for (final MapEntry(:key, :value) in side.marks.entries)
            if (_kana.contains(value)) key: value,
        };
        final labels = resolvedKimarijiScript(context) == KimarijiScript.romaji
            ? _labels(context, {
                for (final MapEntry(:key, :value) in kana.entries)
                  if (_labelled.contains(value)) key: cards[key]!,
              })
            : const <(String, Rect)>[];
        final bottom = labels.fold(top + geometry.height * scale, (b, l) => math.max(b, l.$2.bottom));
        return SizedBox(
          width: box.maxWidth,
          height: bottom,
          child: CustomPaint(
            painter: _SidePainter(
              side: side,
              cards: cards,
              before: {for (final MapEntry(:key, :value) in side.before.entries) key: place(value)},
              blocks: blocks ? _blocks(side.half, cards) : null,
              line: top / 2,
            ),
            child: Stack(children: [
              for (final MapEntry(key: id, value: mark) in kana.entries)
                Positioned.fromRect(rect: cards[id]!, child: _CardKana(poems[id].kimariji, mark)),
              for (final (text, rect) in labels)
                Positioned.fromRect(
                    rect: rect,
                    child: Text(text, maxLines: 1, softWrap: false, style: _romajiStyle)),
            ]),
          ),
        );
      });

  static const _romajiStyle =
      TextStyle(fontWeight: Weights.bold, fontSize: KimarijiFigureLayout.romajiFont, height: 1, color: Palette.ink);

  /// The romaji kimariji under each of [cards] (all in 下段), pushed apart
  /// where they would run into each other.
  static List<(String, Rect)> _labels(BuildContext context, Map<int, Rect> cards) {
    final style = DefaultTextStyle.of(context).style.merge(_romajiStyle);
    final ids = cards.keys.toList()..sort((a, b) => cards[a]!.left.compareTo(cards[b]!.left));
    final boxes = [
      for (final id in ids)
        () {
          final painter = TextPainter(
              text: TextSpan(text: kimarijiFor(context, id), style: style), textDirection: TextDirection.ltr)
            ..layout();
          final card = cards[id]!;
          return Rect.fromCenter(
              center: Offset(card.center.dx, card.bottom + TeiichiFigureLayout.romajiGap + painter.height / 2),
              width: painter.width,
              height: painter.height);
        }(),
    ];
    for (var i = 1; i < boxes.length; i++) {
      final over = boxes[i - 1].right + TeiichiFigureLayout.romajiSpace - boxes[i].left;
      if (over > 0) {
        boxes[i - 1] = boxes[i - 1].shift(Offset(-over / 2, 0));
        boxes[i] = boxes[i].shift(Offset(over / 2, 0));
      }
    }
    return [for (final (i, id) in ids.indexed) (kimarijiFor(context, id), boxes[i])];
  }

  /// Each row's clusters as blocks, with their screentones' dot radii.
  static List<(Rect, double)> _blocks(AnkirenHalf half, Map<int, Rect> cards) {
    Rect around(List<int> ids) => ids.map((id) => cards[id]!).reduce((a, b) => a.expandToInclude(b));
    final rows = half.rows.reversed.toList();
    return [
      for (final (i, (left, right)) in TeiichiFigureLayout.fullness.indexed)
        for (final (part, radius) in [(rows[i].left, left), (rows[i].right, right)])
          if (part.isNotEmpty) (around(part), radius),
    ];
  }
}

/// A marked card's kimariji, down the card as on a real one: in two
/// columns, the first on the right, when it is longer than
/// [TeiichiFigureLayout.kanaColumn].
class _CardKana extends StatelessWidget {
  const _CardKana(this.kimariji, this.mark);

  final String kimariji;
  final _Mark mark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final kana = kimariji.characters.toList();
        final columns = kana.length > TeiichiFigureLayout.kanaColumn ? 2 : 1;
        final rows = (kana.length / columns).ceil();
        final across = columns == 1 ? TeiichiFigureLayout.kanaShare : TeiichiFigureLayout.kanaTwoColumnShare;
        final size = math.min(box.maxWidth * across / columns,
            box.maxHeight * TeiichiFigureLayout.kanaColumnShare / rows);
        final color = switch (mark) {
          _Mark.oneSound => TeiichiFigureLayout.oneSoundKana,
          _Mark.sixSound => TeiichiFigureLayout.sixSoundKana,
          _ => TeiichiFigureLayout.lookAlikeKana,
        };
        return Center(
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var c = columns - 1; c >= 0; c--)
              Column(mainAxisSize: MainAxisSize.min, children: [
                for (final k in kana.skip(c * rows).take(rows))
                  Text(k, style: TextStyle(fontWeight: Weights.black, fontSize: size, height: 1, color: color)),
              ]),
          ]),
        );
      });
}

class _SidePainter extends CustomPainter {
  _SidePainter({required this.side, required this.cards, required this.before, required this.blocks, required this.line});

  final _Side side;
  final Map<int, Rect> cards, before;
  final List<(Rect, double)>? blocks;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    _centreLine(canvas, line, size.width);
    final blocks = this.blocks;
    if (blocks != null) {
      for (final (rect, radius) in blocks) {
        _block(canvas, rect, radius);
      }
      for (final id in side.half.middleCards) {
        _card(canvas, cards[id]!, null);
      }
      return;
    }
    for (final MapEntry(key: id, value: rect) in cards.entries) {
      if (side.gone.contains(id)) {
        _spot(canvas, rect);
      } else {
        _card(canvas, rect, side.marks[id]);
      }
    }
    for (final rect in before.values) {
      _spot(canvas, rect);
    }
    for (final MapEntry(key: id, value: from) in before.entries) {
      _arrow(canvas, from.center, cards[id]!);
    }
  }

  @override
  bool shouldRepaint(_SidePainter old) => true;
}

void _centreLine(Canvas canvas, double y, double width) {
  final ink = Paint()
    ..color = Palette.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = TeiichiFigureLayout.lineStroke;
  canvas.drawPath(Dashes.of(Path()..moveTo(0, y)..lineTo(width, y), KarutaFigureLayout.fieldLineDash), ink);
}

void _card(Canvas canvas, Rect rect, _Mark? mark) {
  final fill = switch (mark) {
    _Mark.oneSound => TeiichiFigureLayout.oneSound,
    _Mark.sixSound => TeiichiFigureLayout.sixSound,
    _Mark.lookAlike => TeiichiFigureLayout.lookAlike,
    _Mark.moved => TeiichiFigureLayout.moved,
    _ => Palette.paper,
  };
  canvas.drawRect(rect, Paint()..color = fill);
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..color = mark == null ? Palette.cardFrame : Palette.ink
    ..strokeWidth = mark == _Mark.outlined ? TeiichiFigureLayout.outlineStroke : TeiichiFigureLayout.cardStroke;
  canvas.drawRect(mark == _Mark.outlined ? rect.deflate(TeiichiFigureLayout.outlineStroke / 2) : rect, edge);
}

/// An empty place where a card lay.
void _spot(Canvas canvas, Rect rect) {
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..color = Palette.mute
    ..strokeWidth = TeiichiFigureLayout.cardStroke;
  canvas.drawPath(Dashes.of(Path()..addRect(rect.deflate(TeiichiFigureLayout.cardStroke / 2)), TeiichiFigureLayout.spotDash),
      edge);
}

/// An arrow from [from] to the edge of [to].
void _arrow(Canvas canvas, Offset from, Rect to) {
  final d = to.center - from;
  final reach = math.min(
      d.dx == 0 ? double.infinity : to.width / 2 / d.dx.abs(), d.dy == 0 ? double.infinity : to.height / 2 / d.dy.abs());
  final tip = to.center - d * reach;
  final unit = d / d.distance;
  final back = tip - unit * TeiichiFigureLayout.arrowHead;
  final side = Offset(-unit.dy, unit.dx) * TeiichiFigureLayout.arrowHead * TeiichiFigureLayout.arrowHeadWidth / 2;
  final head = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(back.dx + side.dx, back.dy + side.dy)
    ..lineTo(back.dx - side.dx, back.dy - side.dy)
    ..close();
  for (final (color, extra) in [(Palette.paper, TeiichiFigureLayout.arrowHalo), (Palette.ink, 0.0)]) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = TeiichiFigureLayout.arrowStroke + extra
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(from, back, stroke);
    canvas.drawPath(head, stroke);
    if (extra == 0) canvas.drawPath(head, Paint()..color = color);
  }
}

void _block(Canvas canvas, Rect rect, double radius) {
  final tone =
      ToneSpec(dot: Palette.ink, radius: radius, spacing: TeiichiFigureLayout.toneSpacing, background: Palette.paper);
  canvas.drawRect(rect, Screentone.paint(tone, FigureFile.pixelRatio));
  canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Palette.ink
        ..strokeWidth = TeiichiFigureLayout.cardStroke);
}

/// Two versions of a side, one panel above the other.
class _Compare extends StatelessWidget {
  const _Compare(this.first, this.second);

  final _Side first, second;

  @override
  Widget build(BuildContext context) {
    final slots = _slots([first.half, second.half]);
    return Column(children: [
      FigurePanel(child: _SideView(first, slots: slots)),
      const SizedBox(height: TeiichiFigureLayout.panelGap),
      FigurePanel(child: _SideView(second, slots: slots)),
    ]);
  }
}

/// Your side from where you sit, a few cards outlined.
class TeiichiSideFigure extends StatelessWidget {
  const TeiichiSideFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final half = _half(TeiichiGuideExamples.base);
    return FigurePanel(
      child: _SideView(
        _Side(half, marks: {for (final id in TeiichiGuideExamples.outlined) id: _Mark.outlined}),
        slots: _slots([half]),
      ),
    );
  }
}

/// The one-sound cards low on both sides, and the six-sound cards at the
/// right's outer end of 中段 and 下段.
class TeiichiFirstCardsFigure extends StatelessWidget {
  const TeiichiFirstCardsFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final half = _half(TeiichiGuideExamples.firstCards);
    return FigurePanel(
      child: _SideView(
        _Side(half, marks: {
          for (final k in KarutaGuideExamples.oneSound.characters) poems.byKimariji(k).id: _Mark.oneSound,
          for (final id in TeiichiGuideExamples.sixSound) id: _Mark.sixSound,
        }),
        slots: _slots([half]),
      ),
    );
  }
}

/// The なげ pair side by side, then one in each cluster.
class TeiichiLookAlikeFigure extends StatelessWidget {
  const TeiichiLookAlikeFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final marks = {for (final id in TeiichiGuideExamples.lookAlikes) id: _Mark.lookAlike};
    return _Compare(
      _Side(_half(TeiichiGuideExamples.base), marks: marks),
      _Side(_half(TeiichiGuideExamples.lookAlikeSplit), marks: marks),
    );
  }
}

/// Your side's rows as blocks toned by how full they usually are, and
/// one card alone in the middle of 上段.
class TeiichiRowsFigure extends StatelessWidget {
  const TeiichiRowsFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final half = _half(TeiichiGuideExamples.fullness);
    return FigurePanel(child: _SideView(_Side(half), slots: _slots([half]), blocks: true));
  }
}

/// Your side at the start and after a few cards have gone, two small
/// panels side by side, then with its gaps closed: cards moved down a row
/// and across, with arrows.
class TeiichiGapsFigure extends StatelessWidget {
  const TeiichiGapsFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final base = _half(TeiichiGuideExamples.base), closed = _half(TeiichiGuideExamples.closed);
    final slots = _slots([base, closed]);
    final was = _grown(base, slots).half(FieldSide.own);
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: FigurePanel(child: _SideView(_Side(base), slots: slots))),
        const SizedBox(width: TeiichiFigureLayout.panelGap),
        Expanded(
            child: FigurePanel(child: _SideView(_Side(base, gone: TeiichiGuideExamples.gone.toSet()), slots: slots))),
      ]),
      const SizedBox(height: TeiichiFigureLayout.panelGap),
      FigurePanel(
        child: _SideView(
          _Side(closed,
              marks: {for (final id in TeiichiGuideExamples.moved) id: _Mark.moved},
              before: {for (final id in TeiichiGuideExamples.moved) id: was[id]!}),
          slots: slots,
        ),
      ),
    ]);
  }
}

/// Both sides, theirs above: a large clock with the match's 15 minutes
/// shaded beside theirs, a small stopwatch short of a full turn beside
/// yours.
class TeiichiTimeFigure extends StatelessWidget {
  const TeiichiTimeFigure({super.key});

  @override
  Widget build(BuildContext context) => FigurePanel(
        child: LayoutBuilder(builder: (context, box) {
          final own = _half(TeiichiGuideExamples.base), theirs = _half(TeiichiGuideExamples.theirs);
          final geometry = _grown(own, _slots([own, theirs]), theirs);
          final fieldWidth = box.maxWidth * TeiichiFigureLayout.timeFieldShare;
          final scale = fieldWidth / geometry.width;
          final sideHeight = geometry.height * scale;
          final centre = AnkirenFieldSize.cardH * scale * TeiichiFigureLayout.timeCentre;
          return SizedBox(
            width: box.maxWidth,
            height: sideHeight * 2 + centre,
            child: CustomPaint(
              painter: _TimePainter(
                theirs: [
                  for (final r in geometry.half(FieldSide.opponent).values)
                    Rect.fromLTWH(r.x * scale, r.y * scale, r.w * scale, r.h * scale).deflate(TeiichiFigureLayout.cardInset),
                ],
                yours: [
                  for (final r in geometry.half(FieldSide.own).values)
                    Rect.fromLTWH(r.x * scale, sideHeight + centre + r.y * scale, r.w * scale, r.h * scale)
                        .deflate(TeiichiFigureLayout.cardInset),
                ],
                fieldWidth: fieldWidth,
                sideHeight: sideHeight,
                centre: centre,
              ),
            ),
          );
        }),
      );
}

class _TimePainter extends CustomPainter {
  _TimePainter(
      {required this.theirs, required this.yours, required this.fieldWidth, required this.sideHeight, required this.centre});

  final List<Rect> theirs, yours;
  final double fieldWidth, sideHeight, centre;

  @override
  void paint(Canvas canvas, Size size) {
    _centreLine(canvas, sideHeight + centre / 2, fieldWidth);
    for (final rect in [...theirs, ...yours]) {
      _card(canvas, rect, null);
    }
    final x = (fieldWidth + size.width) / 2;
    _clock(canvas, Offset(x, sideHeight / 2));
    _stopwatch(canvas, Offset(x, sideHeight + centre + sideHeight / 2));
  }

  /// A clock face with its hours ticked and the match's minutes shaded.
  void _clock(Canvas canvas, Offset c) {
    const r = TeiichiFigureLayout.clockSize / 2;
    canvas.drawCircle(c, r, Paint()..color = Palette.paper);
    _sector(canvas, c, r - TeiichiFigureLayout.clockStroke / 2,
        TeiichiFigureLayout.matchMinutes / TeiichiFigureLayout.clockMinutes);
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = TeiichiFigureLayout.clockStroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < TeiichiFigureLayout.clockTicks; i++) {
      final a = 2 * math.pi * i / TeiichiFigureLayout.clockTicks;
      final dir = Offset(math.sin(a), -math.cos(a));
      final tick = i % (TeiichiFigureLayout.clockTicks ~/ 4) == 0
          ? TeiichiFigureLayout.clockQuarterTick
          : TeiichiFigureLayout.clockTick;
      canvas.drawLine(c + dir * r * (1 - tick), c + dir * (r - TeiichiFigureLayout.clockStroke), ink..strokeWidth = TeiichiFigureLayout.handStroke);
    }
    _hand(canvas, c, r * (1 - TeiichiFigureLayout.clockQuarterTick),
        TeiichiFigureLayout.matchMinutes / TeiichiFigureLayout.clockMinutes);
    canvas.drawCircle(c, r - TeiichiFigureLayout.clockStroke / 2, ink..strokeWidth = TeiichiFigureLayout.clockStroke);
  }

  /// A stopwatch, its time shaded short of one full turn.
  void _stopwatch(Canvas canvas, Offset c) {
    const r = TeiichiFigureLayout.watchSize / 2;
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = TeiichiFigureLayout.watchStroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Palette.ink;
    Rect scaled(Rect unit) => Rect.fromLTRB(unit.left * r, unit.top * r, unit.right * r, unit.bottom * r);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawRect(scaled(TeiichiFigureLayout.watchCrown), fill);
    canvas.rotate(2 * math.pi * TeiichiFigureLayout.watchButtonTurn);
    canvas.drawRect(scaled(TeiichiFigureLayout.watchButton), fill);
    canvas.restore();
    canvas.drawCircle(c, r, Paint()..color = Palette.paper);
    _sector(canvas, c, r * TeiichiFigureLayout.watchDial, TeiichiFigureLayout.placingTurn);
    _hand(canvas, c, r * TeiichiFigureLayout.watchDial, TeiichiFigureLayout.placingTurn);
    canvas.drawCircle(c, r - TeiichiFigureLayout.watchStroke / 2, ink);
  }

  void _sector(Canvas canvas, Offset c, double r, double turn) => canvas.drawArc(
      Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * turn, true, Paint()..color = Palette.pink);

  void _hand(Canvas canvas, Offset c, double r, double turn) {
    final a = 2 * math.pi * turn;
    canvas.drawLine(
        c,
        c + Offset(math.sin(a), -math.cos(a)) * r,
        Paint()
          ..color = Palette.ink
          ..strokeWidth = TeiichiFigureLayout.handStroke
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, TeiichiFigureLayout.handDot, Paint()..color = Palette.ink);
  }

  @override
  bool shouldRepaint(_TimePainter old) => true;
}
