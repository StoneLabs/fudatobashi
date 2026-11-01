import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ankiren_review.dart';
import '../../domain/ankiren_tomofuda.dart';
import '../../domain/karafuda.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../ankiren/ankiren_field_view.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../teiichi/teiichi_zoom.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A 暗記練 game's Field (D33): the field replayed ([FieldReplay]), then how
/// each side went.
class AnkirenFieldTab extends StatelessWidget {
  const AnkirenFieldTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    return FieldReplay(
      game: game,
      deal: game.deal,
      note: game.scored ? s.ankirenFieldNote : s.ankirenASide(game.perSide),
      tiles: [
        [
          for (final side in [FieldSide.opponent, FieldSide.own])
            if (game.rightFirstOn(side) case final r?)
              rightFirstTile(s, side == FieldSide.own ? s.ankirenYourSide : s.ankirenTheirSide, r.right, r.of),
        ],
      ],
    );
  }
}

/// A Field tile: how many of [name]'s [of] cards were found with the first
/// tap.
SummaryTile rightFirstTile(S s, String name, int right, int of) => SummaryTile(
      label: '$name\n${s.ankirenColRightFirst}'.toUpperCase(),
      big: TileFigure('$right', unit: '/$of'),
      note: '',
      color: Palette.paper,
    );

/// A recorded game's field as dealt ([deal]), each card coloured by where
/// its first tap landed; then, once the review starts (or a card is
/// tapped), stepped through call by call with the unrelated cards dimmed
/// and arrows from the cards each wrong tap hit (a からふだ call, off the
/// field, only numbers the cards tapped on it); then [tiles], a band per
/// list, with [tilesNote] under them. With [trueSlots] the field is the
/// own side alone at true scale, as 定位置 lays it out (see [ReviewField]).
class FieldReplay extends StatefulWidget {
  const FieldReplay({
    super.key,
    required this.game,
    required this.deal,
    this.note,
    this.tiles = const [],
    this.tilesNote,
    this.trueSlots,
  });
  final AnkirenGameRecord game;
  final AnkirenField? deal;
  final String? note, tilesNote;
  final List<List<SummaryTile>> tiles;
  final double? trueSlots;

  @override
  State<FieldReplay> createState() => _FieldReplayState();
}

class _FieldReplayState extends State<FieldReplay> {
  static final _tomofuda = AnkirenTomofuda(poems);

  /// The call being reviewed; null before the review starts, and after
  /// Show all, when the whole field shows as dealt.
  int? _step;

  void _goTo(int? step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = widget.game;
    final deal = widget.deal;
    if (deal == null || game.cards.isEmpty) {
      return ReviewColumn(children: [
        ReviewSlab(
          title: s.ankirenFieldTitle,
          sub: s.sub?.ankirenFieldTitle,
          flatTop: true,
          child: ReviewText(s.ankirenFieldMissing),
        ),
      ]);
    }
    final step = _step;
    final card = step == null ? null : game.calls[step];
    final firstHit = card?.tapped.firstOrNull;
    final tilesNote = widget.tilesNote;
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.ankirenFieldTitle,
        sub: s.sub?.ankirenFieldTitle,
        note: widget.note,
        flatTop: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ReplayedField(
            deal: deal,
            game: game,
            step: step,
            trueSlots: widget.trueSlots,
            onPick: (id) {
              final picked = game.calls.indexWhere((c) => c.poemId == id);
              if (picked >= 0) _goTo(picked);
            },
          ),
          TierLegend(
            tiers: [
              for (final place in TapProximity.values)
                if (place != TapProximity.otherSide || deal.opponent.cards.isNotEmpty) place,
            ],
          ),
          if (card != null) const _TapLegend(),
        ]),
      ),
      if (step == null || card == null)
        ReviewShout(label: s.ankirenStartReview, onTap: () => _goTo(0))
      else
        ReviewSlab(
          child: _StepBox(
            deal: deal,
            step: step,
            count: game.calls.length,
            card: card,
            calls: game.karafuda.isNotEmpty,
            lookAlike: firstHit != null && _tomofuda.of(card.poemId).contains(firstHit) ? firstHit : null,
            onGo: _goTo,
          ),
        ),
      for (final band in widget.tiles)
        if (band.isNotEmpty)
          TileBand(band, spec: ReviewTileLayout.twoLines, minHeight: ReviewTileLayout.sidesHeight),
      if (tilesNote != null) ReviewCaption(tilesNote),
    ]);
  }
}

/// The dealt field, every card in its first tap's colour. In a [step],
/// its call's card is outlined, its taps numbered with arrows from the
/// wrong ones, and every card it did not touch dimmed. Tapping a card picks
/// its call ([onPick]).
class _ReplayedField extends StatelessWidget {
  const _ReplayedField(
      {required this.deal, required this.game, required this.step, required this.trueSlots, required this.onPick});
  final AnkirenField deal;
  final AnkirenGameRecord game;
  final int? step;
  final double? trueSlots;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tiers = {for (final c in game.cards) c.poemId: c.first};
    final card = step == null ? null : game.calls[step!];
    final related = card == null ? null : {card.poemId, ...card.tapped};
    return ReviewField(
      field: deal,
      trueSlots: trueSlots,
      label: s.ankirenFieldLabel,
      card: (id) {
        final place = tiers[id];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onPick(id),
          child: AnimatedOpacity(
            opacity: related == null || related.contains(id) ? 1 : AnkirenReviewStyle.unrelatedOpacity,
            duration: AnkirenReviewStyle.dimFade,
            child: FieldWordCard(
              id,
              fill: place == null ? Palette.paper : AnkirenReviewStyle.tierFill[place.index],
              color: place == null ? Palette.ink : AnkirenReviewStyle.tierText[place.index],
              current: id == card?.poemId,
            ),
          ),
        );
      },
      overlay: card == null ? null : (placement) => CustomPaint(painter: _TapArrows(placement, card)),
    );
  }
}

/// A recorded game's [field] on the review's ground, as wide as it is
/// given: both halves folded with the band between them, or with
/// [trueSlots] the own half alone at true scale, its rows that many card
/// pitches across, under the band. Its cards are [card]'s; an [overlay]
/// lies over the field and the band.
class ReviewField extends StatelessWidget {
  const ReviewField(
      {super.key, required this.field, required this.label, required this.card, this.overlay, this.trueSlots});
  final AnkirenField field;
  final String label;
  final Widget Function(int poemId) card;
  final Widget Function(FieldPlacement placement)? overlay;
  final double? trueSlots;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final trueScale = trueSlots != null;
    return Semantics(
      image: true,
      label: label,
      child: LayoutBuilder(builder: (context, box) {
        const pad = AnkirenPlayLayout.padding;
        const band = AnkirenReviewStyle.fieldBand;
        final width = box.maxWidth - 2 * pad;
        final natural = FieldGeometry.of(field, folded: !trueScale, trueSlots: trueSlots);
        final double slots, scale;
        if (trueScale) {
          // As 定位置 shows the side once the cards are down: grown until
          // its zoom stops, with only the card width capped.
          final zoom = math.min(
              TeiichiZoom.limit(field, Size(width, double.infinity), band),
              TeiichiReviewStyle.maxCardW * natural.width / (width * AnkirenFieldSize.cardW));
          slots = FieldGeometry.slotsAcross(natural.width / math.max(1, zoom));
          scale = width / FieldGeometry.of(field, folded: false, trueSlots: slots).width;
        } else {
          slots = 0;
          scale = math.min(width / natural.width, AnkirenReviewStyle.fieldMaxCardW / AnkirenFieldSize.cardW);
        }
        final shown = trueScale ? FieldGeometry.of(field, folded: false, trueSlots: slots) : natural;
        final view = AnkirenFieldView(
          field: field,
          landscape: false,
          trueScale: trueScale,
          zoom: false,
          trueSlots: trueScale ? slots : null,
          roomAbove: trueScale ? 0 : null,
          bandExtent: band,
          card: (id, _) => card(id),
          band: _Band(their: trueScale ? null : s.ankirenTheirSide, yours: s.ankirenYourSide),
          overlay: overlay,
          overlayOverBand: true,
        );
        final height = (trueScale ? 1 : 2) * shown.height * scale + band;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AnkirenReviewStyle.fieldGround,
            border: Border.all(color: Palette.ink, width: Strokes.label),
          ),
          child: trueScale
              // The view pads its top; the band starts the box instead.
              ? SizedBox(
                  height: height + pad,
                  child: Stack(clipBehavior: Clip.hardEdge, children: [
                    Positioned(left: 0, right: 0, top: -pad, height: height + 2 * pad, child: view),
                  ]),
                )
              : SizedBox(height: height + 2 * pad, child: view),
        );
      }),
    );
  }
}

/// One card of a reviewed field: its kimariji in [color] on [fill],
/// outlined heavier when [current], with a [foot] under the word.
class FieldWordCard extends StatelessWidget {
  const FieldWordCard(this.poemId,
      {super.key, required this.fill, required this.color, this.current = false, this.foot});
  final int poemId;
  final Color fill, color;
  final bool current;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    final text = kimarijiFor(context, poemId);
    final kana = text.runes.any((r) => r >= _kanaStart);
    final word = Text(kana ? text.split('').join('\n') : text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontWeight: Weights.black, fontSize: AnkirenReviewStyle.fieldCardFont, height: 1, color: color));
    final fitted = Center(
      child: FittedBox(fit: BoxFit.scaleDown, child: kana ? word : RotatedBox(quarterTurns: 1, child: word)),
    );
    final foot = this.foot;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
            color: Palette.ink, width: current ? AnkirenReviewStyle.highlight : AnkirenReviewStyle.fieldCardBorder),
      ),
      child: Padding(
        padding: AnkirenReviewStyle.fieldCardPadding,
        child: foot == null
            ? fitted
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: fitted), foot]),
      ),
    );
  }

  /// Where the kana blocks start: romaji, macrons and all, sits below.
  static const _kanaStart = 0x3040;
}

/// The band across the field: their side up (when it shows), yours down.
class _Band extends StatelessWidget {
  const _Band({required this.their, required this.yours});
  final String? their;
  final String yours;

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.fieldBandFont, color: Palette.paper);
    return ColoredBox(
      color: Palette.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.small),
        child: Row(children: [
          if (their != null) ...[Text('${their!.toUpperCase()} ↑', style: style), const Spacer()],
          Text('${yours.toUpperCase()} ↓', style: style),
        ]),
      ),
    );
  }
}

/// [card]'s taps across the field: an arrow from each wrong card it hit
/// to the card itself, bowed toward the field's middle, solid for the first
/// tap and dashed after, then a numbered badge on every card it hit, in
/// order, over the arrows. A からふだ call has no card on the field to
/// point to: only its badges show.
class _TapArrows extends CustomPainter {
  _TapArrows(this.placement, this.card);
  final FieldPlacement placement;
  final AnkirenCardTry card;

  @override
  void paint(Canvas canvas, Size size) {
    final target = placement.cardRect(card.poemId);
    if (target != null) _arrows(canvas, size, target);
    final onCard = <int, int>{};
    for (final (i, id) in card.tapped.indexed) {
      final rect = placement.cardRect(id);
      if (rect == null) continue;
      final before = onCard.update(id, (n) => n + 1, ifAbsent: () => 0);
      const r = AnkirenReviewStyle.marker / 2;
      _TapBadge.draw(canvas, rect.topRight + Offset(-r - before * AnkirenReviewStyle.marker, r), i + 1,
          size: AnkirenReviewStyle.marker);
    }
  }

  void _arrows(Canvas canvas, Size size, Rect target) {
    final line = Paint()
      ..color = AnkirenReviewStyle.arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnkirenReviewStyle.arrowStroke;
    final middle = size.center(Offset.zero);
    for (final (i, id) in card.tapped.indexed) {
      if (id == card.poemId) continue;
      final from = placement.cardRect(id)?.center;
      if (from == null) continue;
      final to = target.center;
      final d = to - from;
      final normal = Offset(-d.dy, d.dx) * AnkirenReviewStyle.arrowBend;
      final halfway = from + d / 2;
      final control = (halfway + normal - middle).distance <= (halfway - normal - middle).distance
          ? halfway + normal
          : halfway - normal;
      final shaft = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      canvas.drawPath(i == 0 ? shaft : Dashes.of(shaft, AnkirenReviewStyle.laterTapDash), line);
      final back = (control - to).direction;
      const spread = AnkirenReviewStyle.arrowSpread;
      const head = AnkirenReviewStyle.arrowHead;
      canvas.drawPath(
        Path()
          ..moveTo(to.dx + head * math.cos(back + spread), to.dy + head * math.sin(back + spread))
          ..lineTo(to.dx, to.dy)
          ..lineTo(to.dx + head * math.cos(back - spread), to.dy + head * math.sin(back - spread)),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_TapArrows old) => old.card != card || old.placement != placement;
}

/// A tap's number in a circle: the first filled pink, later ones
/// pink-ringed paper, like their solid and dashed arrows.
class _TapBadge extends CustomPainter {
  const _TapBadge(this.number);
  final int number;

  static void draw(Canvas canvas, Offset centre, int number, {required double size}) {
    final first = number == 1;
    final r = size / 2;
    canvas.drawCircle(centre, r, Paint()..color = first ? AnkirenReviewStyle.arrow : Palette.paper);
    canvas.drawCircle(centre, r - AnkirenReviewStyle.markerRing / 2, Paint()
      ..color = first ? Palette.paper : AnkirenReviewStyle.arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = first ? Strokes.hairline : AnkirenReviewStyle.markerRing);
    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
            fontFamily: Fonts.ui,
            fontWeight: Weights.black,
            fontSize: size * AnkirenReviewStyle.markerFontShare,
            color: first ? Palette.paper : AnkirenReviewStyle.arrow),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, centre - Offset(label.width / 2, label.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size.center(Offset.zero), number, size: size.shortestSide);

  @override
  bool shouldRepaint(_TapBadge old) => old.number != number;
}

/// What the replay's arrows mean: a solid arrow and badge 1 for the first
/// tap, dashed and badge 2 for the second.
class _TapLegend extends StatelessWidget {
  const _TapLegend();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget mark(int number) => Row(mainAxisSize: MainAxisSize.min, children: [
          LegendMark.line(AnkirenReviewStyle.arrow, dashed: number > 1),
          const SizedBox(width: Gaps.tight),
          SizedBox.square(
            dimension: AnkirenReviewStyle.legendMarker,
            child: CustomPaint(painter: _TapBadge(number)),
          ),
        ]);
    return ChartLegend([(mark(1), s.ankirenFirstTapLegend), (mark(2), s.ankirenSecondTapLegend)]);
  }
}

/// A small button back from the review to the whole field as dealt.
class _ShowAll extends StatelessWidget {
  const _ShowAll({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return IntrinsicWidth(
      child: InkButton(
        onTap: onTap,
        border: Strokes.label,
        padding: AnkirenReviewStyle.showAllPadding,
        semanticLabel: s.ankirenShowAll,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          MangaIcon(IconArt.close, size: AnkirenReviewStyle.showAllIcon),
          const SizedBox(width: Gaps.tight),
          Text(s.ankirenShowAll,
              maxLines: 1, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.showAllFont)),
        ]),
      ),
    );
  }
}

/// The box stepping through the cards, or with [calls] through every
/// call: the call's count, its kimariji (tagged when a からふだ), then where
/// it lay on [deal], its taps, how it went and its time, a line for a
/// look-alike its first tap hit, and back, Show all and forward. Every line
/// keeps its slot, so the box is as tall for every call.
class _StepBox extends StatelessWidget {
  const _StepBox({
    required this.deal,
    required this.step,
    required this.count,
    required this.card,
    required this.calls,
    required this.lookAlike,
    required this.onGo,
  });
  final AnkirenField deal;
  final int step, count;
  final AnkirenCardTry card;
  final bool calls;

  /// The look-alike its first tap hit, if it did.
  final int? lookAlike;

  /// Goes to a call, or with null back to the whole field.
  final ValueChanged<int?> onGo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double line(double height) => scaler.scale(height);
    final lookAlike = this.lookAlike;
    const value = TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stepValueFont, height: 1);
    final rowHeight = line(AnkirenReviewStyle.stepRowLine);
    // Labels sit on the line of a value's text, which is centred; chips
    // stand on the slot's foot, their words about on that line.
    TableRow row(String label, Widget child, {Alignment alignment = Alignment.centerLeft}) => TableRow(children: [
          _Slot(
            height: rowHeight,
            alignment: Alignment.bottomLeft,
            inset: (rowHeight - line(AnkirenReviewStyle.stepValueFont)) / 2,
            child: Text(label.toUpperCase(),
                maxLines: 1,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: AnkirenReviewStyle.stepLabelFont,
                    letterSpacing: AnkirenReviewStyle.stepLabelTracking * AnkirenReviewStyle.stepLabelFont,
                    height: 1,
                    color: AnkirenReviewStyle.muted)),
          ),
          const SizedBox.shrink(),
          _Slot(height: rowHeight, alignment: alignment, child: child),
        ]);
    Widget button(VectorArt icon, String label, int to) => Opacity(
          opacity: to >= 0 && to < count ? 1 : ChartStyle.dimOpacity,
          child: InkIconButton(icon: icon, semanticLabel: label, onTap: to >= 0 && to < count ? () => onGo(to) : null),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Slot(
        height: line(AnkirenReviewStyle.stepCountLine),
        alignment: Alignment.center,
        child: ShelfLabel(calls ? s.karafudaStepCall(step + 1, count) : s.ankirenStepCard(step + 1, count)),
      ),
      const SizedBox(height: AnkirenReviewStyle.stepCountGap),
      _Slot(
        height: AnkirenReviewStyle.stepWordLine,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(kimarijiFor(context, card.poemId),
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenReviewStyle.stepWordFont, height: 1)),
            if (card.karafuda) ...[const SizedBox(width: AnkirenReviewStyle.stepTagGap), const _KarafudaTag()],
          ],
        ),
      ),
      const SizedBox(height: AnkirenReviewStyle.stepTableGap),
      Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(AnkirenReviewStyle.stepLabelGap),
          2: FlexColumnWidth(),
        },
        children: [
          row(s.ankirenBoxPlace, Text(_place(s), maxLines: 1, style: value)),
          if (card.taps.isEmpty)
            row(s.ankirenBoxTaps, Text(s.ankirenBoxNoTaps, maxLines: 1, style: value))
          else
            row(s.ankirenBoxTaps, _Taps(card), alignment: Alignment.bottomLeft),
          row(s.ankirenBoxResult, Text(_result(s), maxLines: 1, style: value)),
          row(s.ankirenBoxTime, Text(_time(s), maxLines: 1, style: value)),
        ],
      ),
      _Slot(
        height: line(AnkirenReviewStyle.stepNoteLine),
        child: Text(lookAlike == null ? '' : s.ankirenLookAlike(kimarijiFor(context, lookAlike)),
            maxLines: 1,
            style: const TextStyle(
                fontWeight: Weights.bold, fontSize: AnkirenReviewStyle.stepNoteFont, height: 1, color: Palette.inkSoft)),
      ),
      const SizedBox(height: AnkirenReviewStyle.stepButtonsGap),
      Row(children: [
        button(IconArt.back, s.ankirenStepBack, step - 1),
        Expanded(child: Center(child: _ShowAll(onTap: () => onGo(null)))),
        button(IconArt.chevron, s.ankirenStepNext, step + 1),
      ]),
    ]);
  }

  /// Where the card lay: off the field for a からふだ; on a field of one
  /// side, its row and group; else its side.
  String _place(S s) {
    if (card.karafuda) return s.karafudaOffField;
    final side = deal.sideOf(card.poemId);
    if (side == null) return missingTime;
    if (deal.opponent.cards.isNotEmpty) return side == FieldSide.own ? s.ankirenYourSide : s.ankirenTheirSide;
    final at = deal.own.placeOf(card.poemId)!;
    return s.teiichiSpotName(at.row, at.part);
  }

  /// How the call went: right first, on which tap and whether the card was
  /// shown first, or given up or missed.
  String _result(S s) {
    final tap = card.wrongTaps + 1;
    return switch (card) {
      AnkirenCardTry(found: false, gaveUp: true) => s.ankirenBoxGaveUp,
      AnkirenCardTry(found: false, karafuda: true) => s.karafudaNotPressed,
      AnkirenCardTry(found: false) => s.ankirenNotFound,
      AnkirenCardTry(wrongTaps: 0) => s.ankirenBoxRightFirst,
      AnkirenCardTry(shown: true, karafuda: true) => s.karafudaBoxShownPressed(tap),
      AnkirenCardTry(shown: true) => s.ankirenBoxShownFound(tap),
      AnkirenCardTry(karafuda: true) => s.karafudaBoxPressedOn(tap),
      _ => s.ankirenBoxFoundOn(tap),
    };
  }

  String _time(S s) => switch (card.findMs) {
        final ms? => s.ankirenBoxSeconds(formatSeconds(ms)),
        null => missingTime,
      };
}

/// One line of the step box, [height] tall: [child] at [alignment],
/// [inset] off the bottom, shrunk to fit across.
class _Slot extends StatelessWidget {
  const _Slot({required this.height, required this.child, this.alignment = Alignment.centerLeft, this.inset = 0});
  final double height, inset;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: Align(
            alignment: alignment,
            child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
          ),
        ),
      );
}

/// The からふだ tag beside a からふだ call's kimariji.
class _KarafudaTag extends StatelessWidget {
  const _KarafudaTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AnkirenReviewStyle.stepTagFill,
          border: Border.all(color: KarafudaStyle.tag, width: Strokes.hairline),
        ),
        child: Padding(
          padding: AnkirenReviewStyle.stepTagPadding,
          child: Text(S.of(context).karafuda.toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: AnkirenReviewStyle.stepTagFont,
                  letterSpacing: AnkirenReviewStyle.stepTagTracking * AnkirenReviewStyle.stepTagFont,
                  height: AnkirenReviewStyle.stepChipHeight,
                  color: KarafudaStyle.tag)),
        ),
      );
}

/// A call's taps in order, each a chip in its tier's colour with its
/// number as the field marks it, named by what it hit: where it landed,
/// the からふだ button, or on a からふだ call a field card. Taps past the
/// ones kept are counted after them.
class _Taps extends StatelessWidget {
  const _Taps(this.call);
  final AnkirenCardTry call;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final badge = MediaQuery.textScalerOf(context).scale(AnkirenReviewStyle.stepBadge);
    const text = TextStyle(
        fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stepChipFont, height: AnkirenReviewStyle.stepChipHeight);
    final more = call.wrongTaps + (call.found ? 1 : 0) - call.taps.length;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final (i, place) in call.taps.indexed) ...[
        if (i > 0) const SizedBox(width: AnkirenReviewStyle.stepChipGap),
        SizedBox.square(dimension: badge, child: CustomPaint(painter: _TapBadge(i + 1))),
        const SizedBox(width: AnkirenReviewStyle.stepBadgeGap),
        DecoratedBox(
          decoration: BoxDecoration(
              color: AnkirenReviewStyle.tierFill[place.index], border: Border.all(width: Strokes.hairline)),
          child: Padding(
            padding: AnkirenReviewStyle.stepChipPadding,
            child: Text(_name(s, i),
                maxLines: 1, style: text.copyWith(color: AnkirenReviewStyle.tierText[place.index])),
          ),
        ),
      ],
      if (more > 0) ...[
        const SizedBox(width: AnkirenReviewStyle.stepChipGap),
        Text(s.ankirenBoxMoreTaps(more), maxLines: 1, style: text.copyWith(color: AnkirenReviewStyle.muted)),
      ],
    ]);
  }

  String _name(S s, int i) => call.tapped.elementAtOrNull(i) == Karafuda.button
      ? s.karafuda
      : call.karafuda
          ? s.karafudaBoxCard
          : s.ankirenTier(call.taps[i]).replaceAll('​', '');
}
