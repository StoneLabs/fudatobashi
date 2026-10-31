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
/// phone. A marked card shows its kimariji; in romaji, that goes under the
/// card where it fits there, across the card where the picture asks for
/// it, and else in a box under the side, its tail up to the cards.

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

/// How a card stands out: [fill]ed, and its kimariji on it in [face] when
/// that is set.
class _Mark {
  const _Mark(this.fill, [this.face]);

  final Color fill;
  final Color? face;

  static const oneSound = _Mark(TeiichiFigureLayout.oneSound, TeiichiFigureLayout.oneSoundKana);
  static const sixSound = _Mark(TeiichiFigureLayout.sixSound, TeiichiFigureLayout.sixSoundKana);
  static const lookAlike = _Mark(TeiichiFigureLayout.lookAlike, TeiichiFigureLayout.lookAlikeKana);
  static const moved = _Mark(TeiichiFigureLayout.moved);
}

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
/// [TeiichiFigureLayout.fullness]'s screentones. In romaji, its marked
/// cards' kimariji go [romajiAcross] the cards, or under them, or for the
/// [callout] cards in a box under the side. [rows] names its rows down
/// the open middle, 上段 first.
class _SideView extends StatelessWidget {
  const _SideView(this.side,
      {required this.slots, this.blocks = false, this.romajiAcross = false, this.callout = const {}, this.rows});

  final _Side side;
  final double slots;
  final bool blocks;
  final bool romajiAcross;
  final Set<int> callout;
  final List<String>? rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final geometry = _grown(side.half, slots);
        final scale = box.maxWidth / geometry.width;
        final top = AnkirenFieldSize.cardH * scale * TeiichiFigureLayout.centreLine;
        Rect place(FieldRect r) =>
            Rect.fromLTWH(r.x * scale, top + r.y * scale, r.w * scale, r.h * scale).deflate(TeiichiFigureLayout.cardInset);
        final cards = {for (final MapEntry(:key, :value) in geometry.half(FieldSide.own).entries) key: place(value)};
        final faces = {
          for (final MapEntry(:key, :value) in side.marks.entries)
            if (value.face != null) key: value.face!,
        };
        final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
        final labels = romaji && !romajiAcross
            ? _labels(context, {
                for (final id in faces.keys)
                  if (!callout.contains(id)) id: cards[id]!,
              })
            : const <(String, Rect)>[];
        final under = labels.fold(top + geometry.height * scale, (b, l) => math.max(b, l.$2.bottom));
        final box_ = callout.isEmpty
            ? null
            : _Callout.lay(context, {for (final id in callout) id: cards[id]!},
                top: under + TeiichiFigureLayout.calloutGap, right: box.maxWidth);
        final names = rows;
        return SizedBox(
          width: box.maxWidth,
          height: box_ == null ? under : box_.frame.bottom + TeiichiFigureLayout.calloutStroke / 2,
          child: CustomPaint(
            painter: _SidePainter(
              side: side,
              cards: cards,
              before: {for (final MapEntry(:key, :value) in side.before.entries) key: place(value)},
              blocks: blocks ? _blocks(side.half, cards) : null,
              line: top / 2,
              callout: box_,
            ),
            child: Stack(children: [
              for (final MapEntry(key: id, value: color) in faces.entries)
                Positioned.fromRect(
                  rect: cards[id]!,
                  child: romaji && romajiAcross
                      ? _CardRomaji(kimarijiFor(context, id), color)
                      : _CardKana(poems[id].kimariji, color),
                ),
              for (final (text, rect) in labels)
                Positioned.fromRect(
                    rect: rect,
                    child: Text(text, maxLines: 1, softWrap: false, style: _romajiStyle)),
              if (names != null)
                for (final (name, rect) in _rowNames(side.half, cards, names))
                  Positioned.fromRect(
                    rect: rect,
                    child: Center(
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text(name, maxLines: 1, style: _rowStyle))),
                  ),
              if (box_ != null)
                for (final (id, rect) in box_.chips)
                  Positioned.fromRect(
                    rect: rect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: side.marks[id]!.fill,
                        border: Border.all(color: Palette.ink, width: TeiichiFigureLayout.cardStroke),
                      ),
                      child: Center(
                        child: Text(kimarijiFor(context, id),
                            maxLines: 1,
                            softWrap: false,
                            style: _Callout.style.copyWith(color: side.marks[id]!.face)),
                      ),
                    ),
                  ),
            ]),
          ),
        );
      });

  static const _romajiStyle =
      TextStyle(fontWeight: Weights.bold, fontSize: KimarijiFigureLayout.romajiFont, height: 1, color: Palette.ink);
  static const _rowStyle =
      TextStyle(fontWeight: Weights.black, fontSize: TeiichiFigureLayout.rowFont, height: 1, color: Palette.ink);

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

  /// [names] by each row, 上段 first, in the room every row leaves open
  /// between its clusters.
  static List<(String, Rect)> _rowNames(AnkirenHalf half, Map<int, Rect> cards, List<String> names) {
    final rows = half.rows.reversed.toList();
    var from = 0.0, to = double.infinity;
    for (final row in rows) {
      for (final id in row.left) {
        from = math.max(from, cards[id]!.right);
      }
      for (final id in row.right) {
        to = math.min(to, cards[id]!.left);
      }
    }
    Rect across(Rect card) => Rect.fromLTRB(from, card.top, to, card.bottom);
    return [for (final (i, row) in rows.indexed) (names[i], across(cards[[...row.left, ...row.right].first]!))];
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

/// A box under a side for cards whose kimariji are too long to go under
/// them: its [frame], its tail's [tip] by the cards, and a chip for each
/// card, laid out as the cards lie.
class _Callout {
  const _Callout(this.frame, this.tip, this.chips);

  final Rect frame;
  final Offset tip;
  final List<(int, Rect)> chips;

  static const style =
      TextStyle(fontWeight: Weights.black, fontSize: TeiichiFigureLayout.calloutFont, height: 1.1, color: Palette.ink);

  /// The box for [cards], from [top] down, its right edge on [right].
  static _Callout lay(BuildContext context, Map<int, Rect> cards, {required double top, required double right}) {
    final font = DefaultTextStyle.of(context).style.merge(style);
    final ids = cards.keys.toList()
      ..sort((a, b) => cards[a]!.top == cards[b]!.top
          ? cards[a]!.left.compareTo(cards[b]!.left)
          : cards[a]!.top.compareTo(cards[b]!.top));
    final rows = <List<int>>[];
    for (final id in ids) {
      if (rows.isEmpty || cards[id]!.top > cards[rows.last.first]!.center.dy) rows.add([]);
      rows.last.add(id);
    }
    final words = [
      for (final id in ids)
        (TextPainter(text: TextSpan(text: kimarijiFor(context, id), style: font), textDirection: TextDirection.ltr)
              ..layout())
            .size,
    ];
    const pad = TeiichiFigureLayout.chipPadding, inner = TeiichiFigureLayout.calloutPadding;
    const gap = TeiichiFigureLayout.chipGap;
    final chip = Size(words.map((s) => s.width).reduce(math.max) + pad.horizontal,
        words.map((s) => s.height).reduce(math.max) + pad.vertical);
    final across = rows.map((r) => r.length).reduce(math.max);
    final width = inner.horizontal + across * chip.width + (across - 1) * gap;
    final height = inner.vertical + rows.length * chip.height + (rows.length - 1) * gap;
    final frame = Rect.fromLTWH(right - TeiichiFigureLayout.calloutStroke / 2 - width, top, width, height);
    final block = ids.map((id) => cards[id]!).reduce((a, b) => a.expandToInclude(b));
    return _Callout(
      frame,
      Offset(block.center.dx, block.bottom + TeiichiFigureLayout.calloutTip),
      [
        for (final (r, row) in rows.indexed)
          for (final (c, id) in row.indexed)
            (
              id,
              Rect.fromLTWH(frame.left + inner.left + (across - row.length + c) * (chip.width + gap),
                  frame.top + inner.top + r * (chip.height + gap), chip.width, chip.height),
            ),
      ],
    );
  }

  void paint(Canvas canvas) {
    const half = TeiichiFigureLayout.calloutTail / 2;
    final tail = Path()
      ..moveTo(tip.dx - half, frame.top + TeiichiFigureLayout.calloutStroke)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + half, frame.top + TeiichiFigureLayout.calloutStroke)
      ..close();
    final shape = Path.combine(PathOperation.union, Path()..addRect(frame), tail);
    canvas.drawPath(shape, Paint()..color = Palette.paper);
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Palette.ink
          ..strokeWidth = TeiichiFigureLayout.calloutStroke
          ..strokeJoin = StrokeJoin.round);
  }
}

/// A marked card's kimariji, down the card as on a real one: in two
/// columns, the first on the right, when it is longer than
/// [TeiichiFigureLayout.kanaColumn].
class _CardKana extends StatelessWidget {
  const _CardKana(this.kimariji, this.color);

  final String kimariji;
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final kana = kimariji.characters.toList();
        final columns = kana.length > TeiichiFigureLayout.kanaColumn ? 2 : 1;
        final rows = (kana.length / columns).ceil();
        final across = columns == 1 ? TeiichiFigureLayout.kanaShare : TeiichiFigureLayout.kanaTwoColumnShare;
        final size = math.min(box.maxWidth * across / columns,
            box.maxHeight * TeiichiFigureLayout.kanaColumnShare / rows);
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

/// A marked card's kimariji in romaji, across the card.
class _CardRomaji extends StatelessWidget {
  const _CardRomaji(this.romaji, this.color);

  final String romaji;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TeiichiFigureLayout.cardRomajiInset),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(romaji,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontWeight: Weights.black, fontSize: TeiichiFigureLayout.cardRomajiFont, height: 1, color: color)),
          ),
        ),
      );
}

class _SidePainter extends CustomPainter {
  _SidePainter(
      {required this.side,
      required this.cards,
      required this.before,
      required this.blocks,
      required this.line,
      required this.callout});

  final _Side side;
  final Map<int, Rect> cards, before;
  final List<(Rect, double)>? blocks;
  final double line;
  final _Callout? callout;

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
    callout?.paint(canvas);
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
  canvas.drawRect(rect, Paint()..color = mark?.fill ?? Palette.paper);
  canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = mark == null ? Palette.cardFrame : Palette.ink
        ..strokeWidth = TeiichiFigureLayout.cardStroke);
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

/// Your side in two games, one panel above the other, each under its
/// name: different cards dealt, but a few, each in its own colour, in the
/// same places in both. The first names its rows down the open middle.
class TeiichiSideFigure extends StatelessWidget {
  const TeiichiSideFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final code = S.of(context).code;
    final halves = [_half(TeiichiGuideExamples.gameOne), _half(TeiichiGuideExamples.gameTwo)];
    final slots = _slots(halves);
    final marks = {
      for (final (i, id) in TeiichiGuideExamples.fixed.indexed)
        id: _Mark(TeiichiFigureLayout.fixed[i].$1, TeiichiFigureLayout.fixed[i].$2),
    };
    return Column(children: [
      for (final (i, half) in halves.indexed) ...[
        if (i > 0) const SizedBox(height: TeiichiFigureLayout.panelGap),
        FigurePanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GameTag(FigureWords.games[code]![i]),
            const SizedBox(height: TeiichiFigureLayout.gameGap),
            _SideView(_Side(half, marks: marks),
                slots: slots, romajiAcross: true, rows: i == 0 ? FigureWords.rows[code] : null),
          ]),
        ),
      ],
    ]);
  }
}

/// A game's name in an ink tag.
class _GameTag extends StatelessWidget {
  const _GameTag(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: TeiichiFigureLayout.gamePadding,
          child: Text(name,
              style: const TextStyle(
                  fontWeight: Weights.black, fontSize: TeiichiFigureLayout.gameFont, height: 1.1, color: Palette.paper)),
        ),
      );
}

/// The one-sound cards low on both sides, and the six-sound cards at the
/// right's outer end of 中段 and 下段, their kimariji in a box under the
/// side.
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
        callout: TeiichiGuideExamples.sixSound.toSet(),
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

/// Both sides, theirs above, and beside each the same 15-minute timer:
/// yours with its first minute filled, theirs with the other 14.
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
    const yoursEnd = TeiichiFigureLayout.yourMinutes;
    _timer(canvas, Offset(x, sideHeight / 2), yoursEnd, TeiichiFigureLayout.timerMinutes);
    _timer(canvas, Offset(x, sideHeight + centre + sideHeight / 2), 0, yoursEnd);
  }

  /// The timer, its minutes [from] up to [to] filled.
  void _timer(Canvas canvas, Offset c, int from, int to) {
    const r = TeiichiFigureLayout.timerSize / 2;
    const minutes = TeiichiFigureLayout.timerMinutes;
    final solid = Paint()..color = Palette.ink;
    Rect scaled(Rect unit) => Rect.fromLTRB(unit.left * r, unit.top * r, unit.right * r, unit.bottom * r);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawRect(scaled(TeiichiFigureLayout.timerCrown), solid);
    canvas.rotate(2 * math.pi * TeiichiFigureLayout.timerButtonTurn);
    canvas.drawRect(scaled(TeiichiFigureLayout.timerButton), solid);
    canvas.restore();
    canvas.drawCircle(c, r, Paint()..color = Palette.paper);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - TeiichiFigureLayout.timerStroke / 2),
        -math.pi / 2 + 2 * math.pi * from / minutes, 2 * math.pi * (to - from) / minutes, true, Paint()..color = Palette.pink);
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = TeiichiFigureLayout.tickStroke
      ..strokeCap = StrokeCap.round;
    for (var m = 0; m < minutes; m++) {
      final a = 2 * math.pi * m / minutes;
      final dir = Offset(math.sin(a), -math.cos(a));
      final tick = m % TeiichiFigureLayout.longTickEvery == 0 ? TeiichiFigureLayout.longTick : TeiichiFigureLayout.tick;
      canvas.drawLine(c + dir * r * (1 - tick), c + dir * (r - TeiichiFigureLayout.timerStroke), ink);
    }
    canvas.drawCircle(c, TeiichiFigureLayout.centreDot, solid);
    canvas.drawCircle(c, r - TeiichiFigureLayout.timerStroke / 2, ink..strokeWidth = TeiichiFigureLayout.timerStroke);
  }

  @override
  bool shouldRepaint(_TimePainter old) => true;
}
