import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/geometry.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'ikkiuchi_parts.dart';
import 'review_field.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A 一騎打ち match's Field: the field as the first card was read, each
/// card in the colour of who took it in the end; then, once the review
/// starts (or a card is tapped), stepped through read by read, the field
/// as each read began, with its touches numbered, arrows from each fault
/// to the card read and from each 送り札 to where it went, and the cards
/// the read did not involve faded back; then the player's takes by the
/// side and the row each card lay in when it was read.
class IkkiuchiFieldTab extends StatefulWidget {
  const IkkiuchiFieldTab(this.review, {super.key});
  final IkkiuchiReview review;

  @override
  State<IkkiuchiFieldTab> createState() => _IkkiuchiFieldTabState();
}

class _IkkiuchiFieldTabState extends State<IkkiuchiFieldTab> {
  /// The read being reviewed; null before the review starts, and after
  /// Show all, when the field shows as the first card was read.
  int? _step;

  void _goTo(int? step) => setState(() => _step = step);

  /// The widest the field gets over the match, in card widths: the cards
  /// keep one size from read to read.
  late final double _widest = widget.review.match.reads
      .map((r) => _StepField.of(widget.review, r).layout.leastWidth())
      .fold(0, math.max);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final review = widget.review;
    final reads = review.match.reads;
    if (reads.isEmpty) {
      return ReviewColumn(children: [
        ReviewSlab(
          title: s.ikkiuchiFieldTitle,
          sub: s.sub?.ikkiuchiFieldTitle,
          flatTop: true,
          child: ReviewText(s.ikkiuchiNoReads),
        ),
      ]);
    }
    final step = _step;
    SummaryTile tile(String name, IkkiuchiTakes takes) => SummaryTile(
          label: '$name\n${s.ikkiuchiTileTakes}'.toUpperCase(),
          big: TileFigure('${takes.took}', unit: '/${takes.read}'),
          note: '',
          color: Palette.paper,
        );
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.ikkiuchiFieldTitle,
        sub: s.sub?.ikkiuchiFieldTitle,
        note: s.ikkiuchiFieldNote,
        flatTop: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ReplayedField(
            review: review,
            step: step,
            widest: _widest,
            onPick: (id) {
              final picked = reads.indexWhere((r) => r.poemId == id);
              if (picked >= 0) _goTo(picked);
            },
          ),
          ChartLegend([
            for (final end in IkkiuchiCardEnd.values)
              if (review.cardEnds.containsValue(end)) (LegendMark.box(_fillOf(end)), _endName(s, end)),
          ]),
          if (step != null)
            ChartLegend([
              (const TapLegendMark(1), s.ikkiuchiFirstTouch),
              (const TapLegendMark(2), s.ikkiuchiSecondTouch),
              (const LegendMark.line(IkkiuchiHistoryStyle.sentArrow), s.ikkiuchiSent),
            ]),
        ]),
      ),
      if (step == null)
        ReviewShout(label: s.ikkiuchiStartReview, onTap: () => _goTo(0))
      else
        ReviewSlab(child: _StepBox(review, step: step, onGo: _goTo)),
      TileBand([
        tile(s.ikkiuchiTheirSide, review.takesOn(IkkiuchiSide.opponent)),
        tile(s.ikkiuchiOwnSide, review.takesOn(IkkiuchiSide.player)),
      ], spec: ReviewTileLayout.twoLines, minHeight: ReviewTileLayout.sidesHeight),
      TileBand([
        for (final row in FieldRow.values.reversed) tile(s.ikkiuchiRowName(row), review.takesInRow(row)),
      ], spec: ReviewTileLayout.twoLines, minHeight: ReviewTileLayout.sidesHeight),
      ReviewCaption(s.ikkiuchiFieldCaption),
    ]);
  }
}

/// The colour of a card that went to [end].
Color _fillOf(IkkiuchiCardEnd end) => switch (end) {
      IkkiuchiCardEnd.player => Palette.land,
      IkkiuchiCardEnd.opponent => Palette.pink,
      IkkiuchiCardEnd.tied => Palette.sun,
      IkkiuchiCardEnd.left => Palette.paper,
    };

String _endName(S s, IkkiuchiCardEnd end) => switch (end) {
      IkkiuchiCardEnd.player => s.ikkiuchiYouTook,
      IkkiuchiCardEnd.opponent => s.ikkiuchiTobiTook,
      IkkiuchiCardEnd.tied => s.ikkiuchiTied,
      IkkiuchiCardEnd.left => s.ikkiuchiLeftCaption,
    };

/// The field shown for a read: both sides as it began, and each 送り札
/// made after it laid where it went too, beside the card itself.
class _StepField {
  _StepField._(this.sent, this.layout);

  /// The field as the first card was read.
  _StepField.atRest(IkkiuchiReview review)
      : sent = const [],
        layout = IkkiuchiField(tobi: review.atRest.opponent, player: review.atRest.player, keepRows: true);

  factory _StepField.of(IkkiuchiReview review, IkkiuchiReadLog read) {
    final sent = review.sentAfter(read);
    final field = sent.fold(read.field, (field, s) => field.laidAt(s.card, s.to));
    return _StepField._(sent, IkkiuchiField(tobi: field.opponent, player: field.player, keepRows: true));
  }

  final List<IkkiuchiSentTo> sent;
  final IkkiuchiField layout;

  /// Whether the card [id] laid on [side] is where a 送り札 went.
  bool goneTo(int id, IkkiuchiSide side) => sent.any((s) => s.card == id && s.to.side == side);
}

/// The field on the review's ground, Tobi's side above the band and the
/// player's below, every card at one size for the whole match ([widest]
/// card widths across, a card at most [FieldReviewStyle.maxCardW]). At
/// rest the field as the first card was read; in a [step], the field as
/// its read began, with its marks. Tapping a card picks its read
/// ([onPick]).
class _ReplayedField extends StatelessWidget {
  const _ReplayedField({required this.review, required this.step, required this.widest, required this.onPick});
  final IkkiuchiReview review;
  final int? step;
  final double widest;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final reads = review.match.reads;
    final read = step == null ? null : reads[step!];
    final field = read == null ? _StepField.atRest(review) : _StepField.of(review, read);
    final related = read == null
        ? null
        : {read.poemId, for (final f in read.faults) f.card, for (final t in field.sent) t.card};
    return Semantics(
      image: true,
      label: s.ikkiuchiFieldLabel,
      child: LayoutBuilder(builder: (context, box) {
        const pad = IkkiuchiHistoryStyle.fieldPadding;
        const band = FieldReviewStyle.band;
        final width = box.maxWidth - 2 * pad;
        final card = math.min(width / widest, FieldReviewStyle.maxCardW);
        final half = field.layout.halfHeight * card;
        final cards = <int, Rect>{}, sentTo = <int, Rect>{};
        for (final c in field.layout.layOut(width / card, gap: band / card)) {
          final box = c.box;
          final rect = Rect.fromCenter(
              center: Offset(box.centre.x, box.centre.y) * card, width: 2 * box.hw * card, height: 2 * box.hh * card);
          if (field.goneTo(c.id, c.side)) {
            sentTo[c.id] = rect;
          } else {
            cards[c.id] = rect;
          }
        }
        return FieldGround(
          child: SizedBox(
            height: 2 * half + band + 2 * pad,
            child: Stack(children: [
              Positioned(
                left: 0,
                right: 0,
                top: pad + half,
                height: band,
                child: FieldBand(their: s.ikkiuchiTheirSide, yours: s.ikkiuchiOwnSide),
              ),
              Positioned.fill(
                left: pad,
                top: pad,
                right: pad,
                bottom: pad,
                child: Stack(clipBehavior: Clip.none, children: [
                  for (final MapEntry(key: id, value: rect) in cards.entries)
                    Positioned.fromRect(
                      rect: rect,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onPick(id),
                        child: AnimatedOpacity(
                          opacity: related == null || related.contains(id) ? 1 : FieldReviewStyle.unrelatedOpacity,
                          duration: FieldReviewStyle.dimFade,
                          child: FieldWordCard(
                            id,
                            fill: _fillOf(review.cardEnds[id] ?? IkkiuchiCardEnd.left),
                            color: Palette.ink,
                            current: id == read?.poemId,
                          ),
                        ),
                      ),
                    ),
                  for (final MapEntry(key: id, value: rect) in sentTo.entries)
                    Positioned.fromRect(rect: rect, child: _SentCard(id)),
                  if (read != null)
                    Positioned.fill(
                      child: IgnorePointer(child: CustomPaint(painter: _marks(read, field, cards, sentTo))),
                    ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  /// [read]'s marks: an ink arrow from each 送り札 to where it went, a pink
  /// one from each fault to the card read (solid when it was the first
  /// touch, dashed after), and every touch numbered at its card.
  StepMarks _marks(IkkiuchiReadLog read, _StepField field, Map<int, Rect> cards, Map<int, Rect> sentTo) {
    final touches = review.touchesOf(read);
    final target = cards[read.poemId]?.center;
    return StepMarks(
      arrows: [
        for (final t in field.sent)
          if ((cards[t.card], sentTo[t.card]) case (final from?, final to?))
            (from: from.center, to: to.center, color: IkkiuchiHistoryStyle.sentArrow, dashed: false),
        if (target != null)
          for (final (i, t) in touches.indexed)
            if (t.fault)
              if (cards[t.card] case final from?)
                (from: from.center, to: target, color: FieldReviewStyle.arrow, dashed: i > 0),
      ],
      badges: [
        for (final (i, t) in touches.indexed)
          if (cards[t.card] case final rect?) (card: rect, number: i + 1),
      ],
    );
  }
}

/// Where a 送り札 went: a dashed outline with its word faded.
class _SentCard extends StatelessWidget {
  const _SentCard(this.poemId);
  final int poemId;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _DashedOutline(),
        child: Padding(
          padding: FieldReviewStyle.cardPadding,
          child: FieldWord(poemId, color: IkkiuchiHistoryStyle.sentWord),
        ),
      );
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline();

  @override
  void paint(Canvas canvas, Size size) {
    final edge = (Offset.zero & size).deflate(FieldReviewStyle.cardBorder / 2);
    canvas.drawPath(
      Dashes.of(Path()..addRect(edge), IkkiuchiHistoryStyle.sentDash),
      Paint()
        ..color = Palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = FieldReviewStyle.cardBorder,
    );
  }

  @override
  bool shouldRepaint(_DashedOutline old) => false;
}

/// The box stepping through the reads: the read's count and kimariji
/// (tagged when a からふだ), where its card lay, its touches in order, how
/// it ended, both times and its 送り札, a line for a fault on a look-alike,
/// and back, Show all and forward.
class _StepBox extends StatelessWidget {
  const _StepBox(this.review, {required this.step, required this.onGo});
  final IkkiuchiReview review;
  final int step;

  /// Goes to a read, or with null back to the whole field.
  final ValueChanged<int?> onGo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final reads = review.match.reads;
    final read = reads[step];
    final touches = review.touchesOf(read);
    final lookAlike = read.karafuda ? null : touches.where((t) => t.fault && t.lookAlike).firstOrNull;
    String who(IkkiuchiSide side) => side == IkkiuchiSide.player ? s.ikkiuchiYou : s.ikkiuchiTobi;
    String time(Duration? take) => take == null ? missingTime : s.ikkiuchiBoxSeconds(secondsOf(take));
    return StepBox(
      count: s.ikkiuchiStepRead(step + 1, reads.length),
      poemId: read.poemId,
      tag: read.karafuda ? s.ikkiuchiKarafuda : null,
      rows: [
        StepRow(s.ikkiuchiBoxPlace, StepBox.text(_place(s, read))),
        if (touches.isEmpty)
          StepRow(s.ikkiuchiBoxTouches, StepBox.text(s.ikkiuchiNoTouches))
        else
          StepRow(
            s.ikkiuchiBoxTouches,
            StepChips([
              for (final t in touches)
                t.fault
                    ? (
                        text: t.by == IkkiuchiSide.player ? s.ikkiuchiYourFaultChip : s.ikkiuchiTobiFaultChip,
                        fill: IkkiuchiHistoryStyle.faultChip,
                        ink: IkkiuchiHistoryStyle.faultChipText,
                      )
                    : (
                        text: who(t.by),
                        fill: t.by == IkkiuchiSide.player ? Palette.land : Palette.pink,
                        ink: Palette.ink,
                      ),
            ]),
            chips: true,
          ),
        StepRow(s.ikkiuchiResultLabel, StepBox.text(s.ikkiuchiFeedback(read.callouts))),
        StepRow(
            s.ikkiuchiBoxTime,
            StepBox.text(
                read.karafuda ? missingTime : s.ikkiuchiBoxTimes(time(read.playerTake), time(read.opponentTake)))),
        StepRow(s.ikkiuchiSent, StepBox.text(_sent(context, s, review.sentAfter(read)))),
      ],
      note: lookAlike == null ? '' : s.ikkiuchiLookAlike(who(lookAlike.by), kimarijiFor(context, lookAlike.card)),
      backLabel: s.ikkiuchiStepBack,
      nextLabel: s.ikkiuchiStepNext,
      showAllLabel: s.ikkiuchiShowAll,
      onBack: step > 0 ? () => onGo(step - 1) : null,
      onNext: step < reads.length - 1 ? () => onGo(step + 1) : null,
      onShowAll: () => onGo(null),
    );
  }

  /// Where the card read lay as the read began: its side and row, or off
  /// the field for a からふだ.
  String _place(S s, IkkiuchiReadLog read) => switch (review.spotOf(read)) {
        final spot? => s.ikkiuchiSideRow(
            spot.side == IkkiuchiSide.player ? s.ikkiuchiOwnSide : s.ikkiuchiTheirSide, s.ikkiuchiRowName(spot.row)),
        null => s.ikkiuchiOffField,
      };

  /// The 送り札 after the read: those the player sent Tobi, those he sent
  /// them, or none.
  static String _sent(BuildContext context, S s, List<IkkiuchiSentTo> sent) {
    String names(IkkiuchiSide to) =>
        [for (final c in sent) if (c.to.side == to) kimarijiFor(context, c.card)].join(s.ikkiuchiNamesJoin);
    final toTobi = names(IkkiuchiSide.opponent), fromTobi = names(IkkiuchiSide.player);
    final parts = [
      if (toTobi.isNotEmpty) s.ikkiuchiSentTo(toTobi),
      if (fromTobi.isNotEmpty) s.ikkiuchiSentFrom(fromTobi),
    ];
    return parts.isEmpty ? s.ikkiuchiSentNone : parts.join(s.ikkiuchiNamesJoin);
  }
}
