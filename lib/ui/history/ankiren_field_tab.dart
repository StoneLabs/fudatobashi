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
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../ankiren/ankiren_field_view.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'run_charts.dart';

/// A 暗記練 game's Field (D33): the field as dealt, each card coloured by
/// where its first tap landed; then, once the review starts (or a card is
/// tapped), stepped through card by card with the unrelated cards dimmed
/// and arrows from the cards each wrong tap hit; then how each side went.
class AnkirenFieldTab extends StatefulWidget {
  const AnkirenFieldTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  State<AnkirenFieldTab> createState() => _AnkirenFieldTabState();
}

class _AnkirenFieldTabState extends State<AnkirenFieldTab> {
  static final _tomofuda = AnkirenTomofuda(poems);

  /// The card being reviewed; null before the review starts, and after
  /// Show all, when the whole field shows as dealt.
  int? _step;

  void _goTo(int? step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = widget.review.game;
    final deal = game.deal;
    final note = game.scored ? s.ankirenFieldNote : s.ankirenASide(game.perSide);
    if (deal == null || game.cards.isEmpty) {
      return RunTabList(children: [
        HistorySection(
          title: s.ankirenFieldTitle,
          sub: s.sub?.ankirenFieldTitle,
          child: ReviewPanel(child: ReviewTable.cell(s.ankirenFieldMissing)),
        ),
      ]);
    }
    final step = _step;
    final card = step == null ? null : game.cards[step];
    final firstHit = card?.tapped.firstOrNull;
    final lookAlike = card != null && firstHit != null && _tomofuda.of(card.poemId).contains(firstHit);
    final sides = [
      for (final side in [FieldSide.opponent, FieldSide.own])
        if (game.rightFirstOn(side) case final r?)
          Fact('${r.right}/${r.of}',
              '${side == FieldSide.own ? s.ankirenYourSide : s.ankirenTheirSide} · ${s.ankirenColRightFirst}'),
    ];
    return RunTabList(children: [
      HistorySection(
        title: s.ankirenFieldTitle,
        sub: s.sub?.ankirenFieldTitle,
        note: note,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ReplayedField(
            deal: deal,
            game: game,
            step: step,
            onPick: (id) {
              final picked = game.cards.indexWhere((c) => c.poemId == id);
              if (picked >= 0) _goTo(picked);
            },
          ),
          const TierLegend(),
          if (card != null) const _TapLegend(),
          const SizedBox(height: Gaps.panel),
          if (step == null || card == null)
            HistoryButton(icon: IconArt.arrow, label: s.ankirenStartReview, onTap: () => _goTo(0))
          else ...[
            _Stepper(step: step, count: game.cards.length, card: card, onGo: _goTo),
            const SizedBox(height: Gaps.small),
            Center(child: _ShowAll(onTap: () => _goTo(null))),
          ],
          if (lookAlike)
            HistoryCaption(s.ankirenLookAlike(kimarijiFor(context, card.poemId), kimarijiFor(context, firstHit))),
          const SizedBox(height: Gaps.panel),
          FactGrid(sides, perRow: sides.length),
        ]),
      ),
    ]);
  }
}

/// The dealt field, every card in its first tap's colour. In a [step],
/// its card is outlined, its taps numbered with arrows from the wrong
/// ones, and every card it did not touch dimmed. Tapping a card picks it
/// ([onPick]).
class _ReplayedField extends StatelessWidget {
  const _ReplayedField({required this.deal, required this.game, required this.step, required this.onPick});
  final AnkirenField deal;
  final AnkirenGameRecord game;
  final int? step;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tiers = {for (final c in game.cards) c.poemId: c.first};
    final card = step == null ? null : game.cards[step!];
    final related = card == null ? null : {card.poemId, ...card.tapped};
    return Semantics(
      image: true,
      label: s.ankirenFieldLabel,
      child: LayoutBuilder(builder: (context, box) {
        const pad = AnkirenPlayLayout.padding;
        const band = AnkirenReviewStyle.fieldBand;
        final natural = FieldGeometry.of(deal, folded: true);
        final scale = math.min(
            (box.maxWidth - 2 * pad) / natural.width, AnkirenPlayLayout.maxCardW / AnkirenFieldSize.cardW);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AnkirenReviewStyle.fieldGround,
            border: Border.all(color: Palette.ink, width: Strokes.label),
            boxShadow: const [BoxShadow(color: Palette.ink, offset: HistoryRunStyle.panelShadow)],
          ),
          child: SizedBox(
            height: 2 * natural.height * scale + band + 2 * pad,
            child: AnkirenFieldView(
              field: deal,
              landscape: false,
              zoom: false,
              bandExtent: band,
              card: (id, side) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(id),
                child: AnimatedOpacity(
                  opacity: related == null || related.contains(id) ? 1 : AnkirenReviewStyle.unrelatedOpacity,
                  duration: AnkirenReviewStyle.dimFade,
                  child: _FieldCard(id, place: tiers[id], current: id == card?.poemId),
                ),
              ),
              band: _Band(their: s.ankirenTheirSide, yours: s.ankirenYourSide),
              overlay: card == null ? null : (placement) => CustomPaint(painter: _TapArrows(placement, card)),
              overlayOverBand: true,
            ),
          ),
        );
      }),
    );
  }
}

/// One card of the replayed field: its kimariji on its first tap's colour
/// (paper when never tapped), outlined heavier when [current].
class _FieldCard extends StatelessWidget {
  const _FieldCard(this.poemId, {required this.place, required this.current});
  final int poemId;
  final TapProximity? place;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final text = kimarijiFor(context, poemId);
    final kana = text.runes.any((r) => r > _ascii);
    final color = place == null ? Palette.ink : AnkirenReviewStyle.tierText[place!.index];
    final word = Text(kana ? text.split('').join('\n') : text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontWeight: Weights.black, fontSize: AnkirenReviewStyle.fieldCardFont, height: 1, color: color));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: place == null ? Palette.paper : AnkirenReviewStyle.tierFill[place!.index],
        border: Border.all(
            color: Palette.ink, width: current ? AnkirenReviewStyle.highlight : AnkirenReviewStyle.fieldCardBorder),
      ),
      child: Padding(
        padding: AnkirenReviewStyle.fieldCardPadding,
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: kana ? word : RotatedBox(quarterTurns: 1, child: word)),
        ),
      ),
    );
  }

  static const _ascii = 0x7f;
}

/// The band across the field: their side up, yours down.
class _Band extends StatelessWidget {
  const _Band({required this.their, required this.yours});
  final String their, yours;

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.fieldBandFont, color: Palette.paper);
    return ColoredBox(
      color: Palette.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.small),
        child: Row(children: [
          Text('${their.toUpperCase()} ↑', style: style),
          const Spacer(),
          Text('${yours.toUpperCase()} ↓', style: style),
        ]),
      ),
    );
  }
}

/// [card]'s taps across the field: an arrow from each wrong card it hit
/// to the card itself, solid for the first tap and dashed after, then a
/// numbered badge on every card it hit, in order, over the arrows.
class _TapArrows extends CustomPainter {
  _TapArrows(this.placement, this.card);
  final FieldPlacement placement;
  final AnkirenCardTry card;

  @override
  void paint(Canvas canvas, Size size) {
    final target = placement.cardRect(card.poemId);
    if (target == null) return;
    final line = Paint()
      ..color = AnkirenReviewStyle.arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnkirenReviewStyle.arrowStroke;
    for (final (i, id) in card.tapped.indexed) {
      if (id == card.poemId) continue;
      final from = placement.cardRect(id)?.center;
      if (from == null) continue;
      final to = target.center;
      final d = to - from;
      final normal = Offset(-d.dy, d.dx) * AnkirenReviewStyle.arrowBend * (i.isEven ? 1 : -1);
      final control = from + d / 2 + normal;
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
          Text(s.ankirenShowAll, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stepSubFont)),
        ]),
      ),
    );
  }
}

/// The step through the cards: back and forward, the card asked and how
/// its taps went.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.count, required this.card, required this.onGo});
  final int step, count;
  final AnkirenCardTry card;
  final ValueChanged<int> onGo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final taps = card.taps.isEmpty ? s.ankirenNoTap : [for (final t in card.taps) s.ankirenChip(t)].join(' → ');
    final find = card.findMs;
    final outcome = switch ((card.found, card.shown)) {
      (false, _) => s.ankirenNotFound,
      (true, true) => s.ankirenShownFound(find == null ? missingTime : formatSeconds(find)),
      (true, false) => s.ankirenFoundIn(find == null ? missingTime : formatSeconds(find)),
    };
    Widget button(VectorArt icon, String label, int to) => Opacity(
          opacity: to >= 0 && to < count ? 1 : ChartStyle.dimOpacity,
          child: InkIconButton(icon: icon, semanticLabel: label, onTap: to >= 0 && to < count ? () => onGo(to) : null),
        );
    return Row(children: [
      button(IconArt.back, s.ankirenStepBack, step - 1),
      const SizedBox(width: Gaps.small),
      Expanded(
        child: Column(children: [
          Text(s.ankirenStepCard(step + 1, count, kimarijiFor(context, card.poemId)),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenReviewStyle.stepFont)),
          Text('$taps · $outcome',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stepSubFont)),
        ]),
      ),
      const SizedBox(width: Gaps.small),
      button(IconArt.chevron, s.ankirenStepNext, step + 1),
    ]);
  }
}
