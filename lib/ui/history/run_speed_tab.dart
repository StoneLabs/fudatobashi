import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/run_speed.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import '../torifuda/torifuda_painter.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// The 100-card view's Speed tab: the run's pace by stretch, side,
/// 決まり字 length and against the usual times, from swipe times only.
class RunSpeedTab extends StatelessWidget {
  const RunSpeedTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = detail.run;
    final speed = RunSpeed(
      detail.swipes,
      goalMs: run.goalMs,
      usualMs: detail.usualMs,
      kimarijiLength: (id) => poems[id].kimariji.length,
    );
    final usual = speed.againstUsual;
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.runThirdsTitle,
        sub: s.sub?.runThirdsTitle,
        flatTop: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (run.forfeit) ...[
            _Warning(s.runSpeedForfeit(speed.cards.length)),
            const SizedBox(height: Gaps.small),
          ],
          Text(run.penaltyMs > 0 ? s.runSwipeTimesPenalty(run.penaltyMs ~/ 1000) : s.runSwipeTimesOnly,
              style: ReviewTextStyle.caption),
        ]),
      ),
      _Thirds(speed),
      if (speed.blocks.length > 1) _Blocks(speed),
      _Stretch(speed, cells: run.forfeit ? run.planned : speed.cards.length),
      ..._sides(s, speed),
      _ByKimariji(speed),
      ReviewSlab(
        title: s.runUsualTitle,
        sub: s.sub?.runUsualTitle,
        flatBottom: usual.compared == 0,
        child: usual.compared == 0
            ? ReviewText(s.runNoUsual)
            : ReviewText(
                s.runFasterOn(usual.faster, usual.compared),
                strong: usual.runMs > usual.usualMs
                    ? s.runOverallSlower(formatSeconds(usual.runMs - usual.usualMs, 1))
                    : s.runOverallFaster(formatSeconds(usual.usualMs - usual.runMs, 1)),
                strongColor: usual.runMs > usual.usualMs ? HistoryRunStyle.behind : HistoryRunStyle.ahead,
              ),
      ),
      if (usual.compared > 0) ...[
        _UsualTiles(usual),
        _GainedLost(usual),
      ],
    ]);
  }

  /// Upright against upside-down, and what turning cost.
  static List<Widget> _sides(S s, RunSpeed speed) {
    final up = speed.upright, down = speed.upsideDown;
    final cost = switch ((up.meanMs, down.meanMs)) {
      (final u?, final d?) => d - u,
      _ => null,
    };
    SummaryTile tile(String label, SpeedSide side, Color color) => SummaryTile(
          label: label.toUpperCase(),
          big: _seconds(side.meanMs),
          note: s.runSideLine(side.cards, side.misses),
          color: color,
        );
    return [
      TileBand([
        tile('↑ ${s.runUpright}', up, Palette.paper),
        tile('↓ ${s.runUpsideDownSide}', down, Palette.seaSoft),
      ], spec: ReviewTileLayout.spec, height: ReviewTileLayout.sidesHeight),
      if (cost != null)
        ReviewCaption(cost >= 0 ? s.runUpsideCost(formatSeconds(cost)) : s.runUpsideGain(formatSeconds(-cost))),
    ];
  }
}

/// A seconds figure, or the missing mark.
TileFigure _seconds(double? ms, {double size = SummaryTileLayout.bigFont}) =>
    ms == null ? TileFigure(missingTime, size: size) : TileFigure(formatSeconds(ms), unit: ' s', size: size);

/// The first, middle and last third as tiles, the slowest pink and the
/// fastest green.
class _Thirds extends StatelessWidget {
  const _Thirds(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ends = RunSpeed.extremes(speed.thirds);
    String note(SpeedSpan t) => [
          if (t == ends?.slowest)
            t.from == 1 ? s.runSlowStart : s.runSlowestThird
          else if (t == ends?.fastest)
            s.runFastestThird
          else if ((t.meanMs, speed.meanMs) case (final ms?, final mean?))
            s.runVsRun(formatSignedSeconds(ms - mean)),
          if (t.misses > 0) s.runMissMark(t.misses),
        ].join('\n');
    return TileBand([
      for (final t in speed.thirds)
        SummaryTile(
          label: s.runCardsRange(t.from, t.to).toUpperCase(),
          big: _seconds(t.meanMs, size: ReviewTileLayout.smallFont),
          note: note(t),
          color: t == ends?.slowest
              ? Palette.pinkSoft
              : t == ends?.fastest
                  ? Palette.landSoft
                  : Palette.paper,
        ),
    ], spec: ReviewTileLayout.small, height: ReviewTileLayout.thirdsHeight);
  }
}

/// The average time of each block of cards against the run's.
class _Blocks extends StatelessWidget {
  const _Blocks(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ends = RunSpeed.extremes(speed.blocks);
    final mean = speed.meanMs;
    return ReviewSlab(
      title: s.runPaceTitle(RunSpeedTuning.blockCards),
      sub: s.sub?.runPaceTitle(RunSpeedTuning.blockCards),
      note: mean == null ? null : s.runAverageNote(formatSeconds(mean)),
      child: BarChart(
        bars: [
          for (final b in speed.blocks)
            ChartBar(
              b.meanMs ?? 0,
              color: b == ends?.slowest
                  ? Palette.pink
                  : b == ends?.fastest
                      ? Palette.land
                      : Palette.paper,
              label: b.meanMs == null ? null : formatSeconds(b.meanMs!),
            ),
        ],
        guide: mean,
        guideColor: Palette.seaDeep,
        format: (ms) => formatSeconds(ms, 1),
        xLabels: {for (final (i, b) in speed.blocks.indexed) i: '${b.to}'},
      ),
    );
  }
}

/// The fastest stretch, the longest row under the goal, and every card on
/// a strip coloured by how it went.
class _Stretch extends StatelessWidget {
  const _Stretch(this.speed, {required this.cells});
  final RunSpeed speed;

  /// Cells on the strip: the cards planned, the ones never played grey.
  final int cells;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fastest = speed.fastestStretch;
    final under = speed.longestUnderGoal;
    final goal = speed.goalMs;
    final played = cells > speed.cards.length;
    return ReviewSlab(
      title: s.runStretchTitle,
      sub: s.sub?.runStretchTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (fastest != null)
              Expanded(
                child: _Fact(
                  label: s.runFastestRow(RunSpeedTuning.blockCards),
                  value: '${formatSeconds(fastest.ms, 1)}s',
                  note: s.runStretchLine(fastest.from, fastest.to, formatSeconds(fastest.ms / RunSpeedTuning.blockCards)),
                ),
              ),
            if (fastest != null && goal != null) const _Divider(),
            if (goal != null)
              Expanded(
                child: _Fact(
                  label: s.runUnderGoalRow(formatSeconds(goal)),
                  value: s.cardsCount(under == null ? 0 : under.to - under.from + 1),
                  note: under == null ? s.runNone : s.runNoMissRange(under.from, under.to),
                ),
              ),
          ]),
        ),
        const SizedBox(height: Gaps.panel),
        SizedBox(height: RunTabsStyle.stripHeight, child: CustomPaint(painter: _StripPainter(speed, cells))),
        ChartLegend([
          (const LegendMark.box(RunTabsStyle.paceFast), s.runPaceFast),
          (const LegendMark.box(RunTabsStyle.paceUnderGoal), s.runPaceUnderGoal),
          (const LegendMark.box(RunTabsStyle.paceSlow), s.runPaceSlow),
          (const LegendMark.box(RunTabsStyle.paceMiss), s.legendMiss),
          if (fastest != null) (const LegendMark.box(Palette.paper), s.runPaceFastestRow(RunSpeedTuning.blockCards)),
          if (played) (const LegendMark.box(RunTabsStyle.paceUnplayed), s.reviewNotPlayed),
        ]),
      ]),
    );
  }
}

/// A fact of the fastest stretch: a tracked label, a big value, a note.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, required this.note});
  final String label, value, note;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: ReviewTextStyle.factLabel),
        const SizedBox(height: Gaps.tight),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: ReviewTextStyle.factValue),
        ),
        const SizedBox(height: Gaps.tight),
        Text(note, style: ReviewTextStyle.factNote),
      ]);
}

/// An ink rule between two halves of a panel.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: ReviewLayout.dividerGap),
        child: SizedBox(width: Strokes.label, child: ColoredBox(color: Palette.ink)),
      );
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.speed, this.cells);
  final RunSpeed speed;
  final int cells;

  static Color _colorOf(CardPace pace) => switch (pace) {
        CardPace.miss => RunTabsStyle.paceMiss,
        CardPace.fast => RunTabsStyle.paceFast,
        CardPace.underGoal => RunTabsStyle.paceUnderGoal,
        CardPace.overGoal => Palette.paper,
        CardPace.slow => RunTabsStyle.paceSlow,
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (cells == 0) return;
    final w = size.width / cells;
    final inner = Rect.fromLTRB(0, RunTabsStyle.stripBoxReach, size.width, size.height - RunTabsStyle.stripBoxReach);
    for (var i = 0; i < cells; i++) {
      final color = i < speed.cards.length ? _colorOf(speed.paceOf(speed.cards[i])) : RunTabsStyle.paceUnplayed;
      canvas.drawRect(Rect.fromLTWH(i * w, inner.top, w + 0.5, inner.height), Paint()..color = color);
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.hairline;
    canvas.drawRect(inner, outline);
    if (speed.fastestStretch case final f?) {
      canvas.drawRect(
        Rect.fromLTRB((f.from - 1) * w, 0, f.to * w, size.height).deflate(RunTabsStyle.stripBoxStroke / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = RunTabsStyle.stripBoxStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) => old.speed != speed || old.cells != cells;
}

/// The cards by their 決まり字's length, with a tick at the usual.
class _ByKimariji extends StatelessWidget {
  const _ByKimariji(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = speed.byKimariji;
    final top = [for (final r in rows) ...[?r.meanMs, ?r.usualMs]].fold<double>(0, (m, v) => v > m ? v : m) *
        RunTabsStyle.lengthHeadroom;
    return ReviewSlab(
      title: s.runKimarijiTitle,
      sub: s.sub?.runKimarijiTitle,
      note: s.runKimarijiNote,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: RunTabsStyle.lengthRowGap / 2),
            child: Row(children: [
              Expanded(
                flex: RunTabsStyle.lengthLabelFlex,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.runKimarijiLength(r.length), style: ReviewTextStyle.rowLabel),
                  Text([s.cardsCount(r.cards), if (r.misses > 0) s.runMissMark(r.misses)].join(' · '),
                      style: ReviewTextStyle.rowNote),
                ]),
              ),
              Expanded(
                flex: RunTabsStyle.lengthBarFlex,
                child: SizedBox(
                  height: RunTabsStyle.lengthBarHeight,
                  child: CustomPaint(painter: _LengthBarPainter(r.meanMs, r.usualMs, top)),
                ),
              ),
              const SizedBox(width: Gaps.panel),
              SizedBox(
                width: RunTabsStyle.lengthValueWidth * MediaQuery.textScalerOf(context).scale(1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${r.meanMs == null ? missingTime : formatSeconds(r.meanMs!)}s',
                    maxLines: 1,
                    style: ReviewTextStyle.rowValue.copyWith(
                        color: (r.meanMs ?? 0) > (r.usualMs ?? double.infinity) ? HistoryRunStyle.behind : null),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _LengthBarPainter extends CustomPainter {
  _LengthBarPainter(this.ms, this.usualMs, this.top);
  final double? ms, usualMs;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Offset.zero & size;
    canvas.drawRect(track, Paint()..color = Palette.paper);
    if (ms case final ms? when top > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width * ms / top, size.height), Paint()..color = Palette.land);
    }
    canvas.drawRect(
        track.deflate(Strokes.hairline / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.hairline);
    if (usualMs case final u? when top > 0) {
      final x = size.width * u / top;
      canvas.drawLine(Offset(x, -RunTabsStyle.tickReach), Offset(x, size.height + RunTabsStyle.tickReach),
          Paint()..strokeWidth = RunTabsStyle.tickStroke);
    }
  }

  @override
  bool shouldRepaint(_LengthBarPainter old) => old.ms != ms || old.usualMs != usualMs || old.top != top;
}

/// The usual time of the cards compared, and this run's.
class _UsualTiles extends StatelessWidget {
  const _UsualTiles(this.usual);
  final AgainstUsual usual;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final gap = usual.runMs - usual.usualMs;
    final color = gap > 0 ? HistoryRunStyle.behind : HistoryRunStyle.ahead;
    return TileBand([
      SummaryTile(
        label: s.runUsualFor(usual.compared).toUpperCase(),
        big: TileFigure(formatTenths(_duration(usual.usualMs))),
        note: s.reviewBeforeRun,
        color: Palette.paper,
      ),
      SummaryTile(
        label: s.runSwipesOnly.toUpperCase(),
        big: TileFigure(formatTenths(_duration(usual.runMs)), color: color),
        note: '${formatSignedSeconds(gap, 1)} s',
        color: gap > 0 ? Palette.pinkSoft : Palette.landSoft,
      ),
    ], spec: ReviewTileLayout.twoLines, height: ReviewTileLayout.thirdsHeight);
  }

  static Duration _duration(double ms) => Duration(milliseconds: ms.round());
}

/// The cards that gained and lost the most against their usual times.
class _GainedLost extends StatelessWidget {
  const _GainedLost(this.usual);
  final AgainstUsual usual;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      flatBottom: true,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _Diffs(s.runMostGained, usual.gained)),
          const _Divider(),
          Expanded(child: _Diffs(s.runMostLost, usual.lost)),
        ]),
      ),
    );
  }
}

/// A row of small cards, each with its time against its usual and its
/// place in the run.
class _Diffs extends StatelessWidget {
  const _Diffs(this.title, this.diffs);
  final String title;
  final List<UsualDiff> diffs;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShelfLabel(title),
        const SizedBox(height: ReviewLayout.shelfGap),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < RunReviewTuning.shownCards; i++) ...[
            if (i > 0) const SizedBox(width: RunTabsStyle.tileGap),
            Expanded(child: i < diffs.length ? _Diff(diffs[i]) : const SizedBox()),
          ],
        ]),
      ]);
}

class _Diff extends StatelessWidget {
  const _Diff(this.diff);
  final UsualDiff diff;

  @override
  Widget build(BuildContext context) {
    final card = diff.card;
    return Column(children: [
      TorifudaCard(poem: poems[card.swipe.poemId], inverted: card.swipe.inverted, showNumber: false),
      const SizedBox(height: ReviewCardStyle.chipGap),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(formatSignedSeconds(diff.diffMs),
            maxLines: 1,
            style: ReviewTextStyle.rowValue
                .copyWith(color: diff.diffMs < 0 ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ),
      const SizedBox(height: ReviewCardStyle.numberGap),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('#${card.number}${card.swipe.inverted ? ' ↓' : ''}', maxLines: 1, style: ReviewTextStyle.rowNote),
      ),
    ]);
  }
}

/// A warning in a pink box.
class _Warning extends StatelessWidget {
  const _Warning(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: Palette.pinkSoft, border: Border.all(color: Palette.ink, width: Strokes.label)),
        child: Padding(
          padding: ReviewLayout.warningPadding,
          child: Text(text, style: ReviewTextStyle.warning),
        ),
      );
}
