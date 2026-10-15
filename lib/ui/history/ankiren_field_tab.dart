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
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';

/// A 暗記練 game's Field (D33): the field as dealt, each card coloured by
/// where its first tap landed, stepped through card by card with arrows
/// from the cards each wrong tap hit; then how each side went.
class AnkirenFieldTab extends StatefulWidget {
  const AnkirenFieldTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  State<AnkirenFieldTab> createState() => _AnkirenFieldTabState();
}

class _AnkirenFieldTabState extends State<AnkirenFieldTab> {
  static final _tomofuda = AnkirenTomofuda(poems);
  int _step = 0;

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
    final card = game.cards[_step];
    final firstHit = card.tapped.firstOrNull;
    final lookAlike = firstHit != null && _tomofuda.of(card.poemId).contains(firstHit);
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
          _ReplayedField(deal: deal, game: game, step: _step),
          const TierLegend(),
          const SizedBox(height: Gaps.panel),
          _Stepper(
            step: _step,
            count: game.cards.length,
            card: card,
            onGo: (step) => setState(() => _step = step),
          ),
          if (lookAlike)
            HistoryCaption(s.ankirenLookAlike(kimarijiFor(context, card.poemId), kimarijiFor(context, firstHit))),
          const SizedBox(height: Gaps.panel),
          FactGrid(sides, perRow: sides.length),
        ]),
      ),
    ]);
  }
}

/// The dealt field, every card in its first tap's colour, the [step]'s
/// card outlined and numbered, arrows from the cards its wrong taps hit.
class _ReplayedField extends StatelessWidget {
  const _ReplayedField({required this.deal, required this.game, required this.step});
  final AnkirenField deal;
  final AnkirenGameRecord game;
  final int step;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tiers = {for (final c in game.cards) c.poemId: c.first};
    final card = game.cards[step];
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
          ),
          child: SizedBox(
            height: 2 * natural.height * scale + band + 2 * pad,
            child: AnkirenFieldView(
              field: deal,
              landscape: false,
              zoom: false,
              bandExtent: band,
              card: (id, side) => _FieldCard(id, place: tiers[id], current: id == card.poemId),
              band: _Band(their: s.ankirenTheirSide, yours: s.ankirenYourSide),
              overlay: (placement) => CustomPaint(painter: _TapArrows(placement, card, step + 1)),
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

/// Arrows from the cards [card]'s wrong taps hit to the card itself, and
/// its [number] at the card's corner.
class _TapArrows extends CustomPainter {
  _TapArrows(this.placement, this.card, this.number);
  final FieldPlacement placement;
  final AnkirenCardTry card;
  final int number;

  @override
  void paint(Canvas canvas, Size size) {
    final target = placement.cardRect(card.poemId);
    if (target == null) return;
    final line = Paint()
      ..color = AnkirenReviewStyle.arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnkirenReviewStyle.arrowStroke;
    for (final id in card.tapped.toSet()) {
      if (id == card.poemId) continue;
      final from = placement.cardRect(id)?.center;
      if (from == null) continue;
      final to = target.center;
      final d = to - from;
      final normal = Offset(-d.dy, d.dx) * AnkirenReviewStyle.arrowBend;
      final control = from + d / 2 + normal;
      canvas.drawPath(Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy), line);
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
    const r = AnkirenReviewStyle.marker / 2;
    final centre = target.topRight;
    canvas.drawCircle(centre, r, Paint()..color = AnkirenReviewStyle.arrow);
    canvas.drawCircle(centre, r, Paint()
      ..color = Palette.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.hairline);
    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
            fontFamily: Fonts.ui,
            fontWeight: Weights.black,
            fontSize: AnkirenReviewStyle.markerFont,
            color: Palette.paper),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, centre - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(_TapArrows old) => old.card != card || old.placement != placement || old.number != number;
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
