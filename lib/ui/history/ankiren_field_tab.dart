import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
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
import '../play/time_format.dart';
import '../teiichi/teiichi_zoom.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'review_field.dart';
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
    this.empty,
  });
  final AnkirenGameRecord game;
  final AnkirenField? deal;
  final String? note, tilesNote;

  /// What to say of a game with no card on its field.
  final String? empty;
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
          child: ReviewText(deal == null ? s.ankirenFieldMissing : widget.empty ?? s.ankirenFieldMissing),
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
          if (card != null)
            ChartLegend([
              (const TapLegendMark(1), s.ankirenFirstTapLegend),
              (const TapLegendMark(2), s.ankirenSecondTapLegend),
            ]),
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
            opacity: related == null || related.contains(id) ? 1 : FieldReviewStyle.unrelatedOpacity,
            duration: FieldReviewStyle.dimFade,
            child: FieldWordCard(
              id,
              fill: place == null ? Palette.paper : AnkirenReviewStyle.tierFill[place.index],
              color: place == null ? Palette.ink : AnkirenReviewStyle.tierText[place.index],
              current: id == card?.poemId,
            ),
          ),
        );
      },
      overlay: card == null ? null : (placement) => CustomPaint(painter: _marks(placement, card)),
    );
  }

  /// [card]'s taps across the field: an arrow from each wrong card it hit
  /// to the card itself, solid for the first tap and dashed after, and a
  /// numbered badge on every card it hit, in order. A からふだ call has no
  /// card on the field to point to: only its badges show.
  static StepMarks _marks(FieldPlacement placement, AnkirenCardTry card) {
    final target = placement.cardRect(card.poemId)?.center;
    return StepMarks(
      arrows: [
        if (target != null)
          for (final (i, id) in card.tapped.indexed)
            if (id != card.poemId)
              if (placement.cardRect(id) case final from?)
                (from: from.center, to: target, color: FieldReviewStyle.arrow, dashed: i > 0),
      ],
      badges: [
        for (final (i, id) in card.tapped.indexed)
          if (placement.cardRect(id) case final rect?) (card: rect, number: i + 1),
      ],
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
        const band = FieldReviewStyle.band;
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
          scale = math.min(width / natural.width, FieldReviewStyle.maxCardW / AnkirenFieldSize.cardW);
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
          band: FieldBand(their: trueScale ? null : s.ankirenTheirSide, yours: s.ankirenYourSide),
          overlay: overlay,
          overlayOverBand: true,
        );
        final height = (trueScale ? 1 : 2) * shown.height * scale + band;
        return FieldGround(
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
    final lookAlike = this.lookAlike;
    return StepBox(
      count: calls ? s.karafudaStepCall(step + 1, count) : s.ankirenStepCard(step + 1, count),
      poemId: card.poemId,
      tag: card.karafuda ? s.karafuda : null,
      rows: [
        StepRow(s.ankirenBoxPlace, StepBox.text(_place(s))),
        if (card.taps.isEmpty)
          StepRow(s.ankirenBoxTaps, StepBox.text(s.ankirenBoxNoTaps))
        else
          StepRow(s.ankirenBoxTaps, _Taps(card), chips: true),
        StepRow(s.ankirenBoxResult, StepBox.text(_result(s))),
        StepRow(s.ankirenBoxTime, StepBox.text(_time(s))),
      ],
      note: lookAlike == null ? '' : s.ankirenLookAlike(kimarijiFor(context, lookAlike)),
      backLabel: s.ankirenStepBack,
      nextLabel: s.ankirenStepNext,
      showAllLabel: s.ankirenShowAll,
      onBack: step > 0 ? () => onGo(step - 1) : null,
      onNext: step < count - 1 ? () => onGo(step + 1) : null,
      onShowAll: () => onGo(null),
    );
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
    final more = call.wrongTaps + (call.found ? 1 : 0) - call.taps.length;
    return StepChips(
      [
        for (final (i, place) in call.taps.indexed)
          (
            text: _name(s, i),
            fill: AnkirenReviewStyle.tierFill[place.index],
            ink: AnkirenReviewStyle.tierText[place.index],
          ),
      ],
      more: more > 0 ? s.ankirenBoxMoreTaps(more) : null,
    );
  }

  String _name(S s, int i) => call.tapped.elementAtOrNull(i) == Karafuda.button
      ? s.karafuda
      : call.karafuda
          ? s.karafudaBoxCard
          : s.ankirenTier(call.taps[i]).replaceAll('​', '');
}
