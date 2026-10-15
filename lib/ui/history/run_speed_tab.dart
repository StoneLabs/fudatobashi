import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/run_speed.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../play/time_format.dart';
import '../torifuda/torifuda_painter.dart';
import 'history_widgets.dart';
import 'run_charts.dart';
import 'run_xp_tab.dart';

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
    return RunTabList(children: [
      if (run.forfeit) _Note(s.runSpeedForfeit(speed.cards.length)),
      _Thirds(speed, penaltyMs: run.penaltyMs),
      if (speed.blocks.length > 1) _Blocks(speed),
      _Stretch(speed, cells: run.forfeit ? run.planned : speed.cards.length),
      _Sides(speed),
      _ByKimariji(speed),
      _AgainstUsual(speed),
    ]);
  }
}

/// D18: the first, middle and last third, the slowest and fastest marked.
class _Thirds extends StatelessWidget {
  const _Thirds(this.speed, {required this.penaltyMs});
  final RunSpeed speed;
  final int penaltyMs;

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
        ].join(' · ');
    return HistorySection(
      title: s.runThirdsTitle,
      sub: s.sub?.runThirdsTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _CellRow([
          for (final t in speed.thirds)
            _Cell(
              label: s.runCardsRange(t.from, t.to),
              value: _seconds(t.meanMs),
              note: note(t),
              fill: t == ends?.slowest
                  ? Palette.pinkSoft
                  : t == ends?.fastest
                      ? Palette.landSoft
                      : Palette.paper,
            ),
        ]),
        HistoryCaption(penaltyMs > 0 ? s.runSwipeTimesPenalty(penaltyMs ~/ 1000) : s.runSwipeTimesOnly),
      ]),
    );
  }
}

/// D19: the average time of each block of cards against the run's.
class _Blocks extends StatelessWidget {
  const _Blocks(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ends = RunSpeed.extremes(speed.blocks);
    final mean = speed.meanMs;
    return HistorySection(
      title: s.runPaceTitle(RunSpeedTuning.blockCards),
      sub: s.sub?.runPaceTitle(RunSpeedTuning.blockCards),
      note: mean == null ? null : s.runAverageNote(formatSeconds(mean)),
      child: RunPanel(gap: false, children: [
        BarChart(
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
      ]),
    );
  }
}

/// D20: the fastest stretch, the longest row under the goal, and every
/// card on a strip coloured by how it went.
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
    return HistorySection(
      title: s.runStretchTitle,
      sub: s.sub?.runStretchTitle,
      child: RunPanel(gap: false, children: [
        _CellRow([
          if (fastest != null)
            _Cell(
              label: s.runFastestRow(RunSpeedTuning.blockCards),
              value: '${formatSeconds(fastest.ms, 1)}s',
              note: s.runStretchLine(
                  fastest.from, fastest.to, formatSeconds(fastest.ms / RunSpeedTuning.blockCards)),
            ),
          if (goal != null)
            _Cell(
              label: s.runUnderGoalRow(formatSeconds(goal)),
              value: s.cardsCount(under == null ? 0 : under.to - under.from + 1),
              note: under == null ? s.runNone : s.runNoMissRange(under.from, under.to),
            ),
        ], ruled: false),
        const SizedBox(height: Gaps.small),
        SizedBox(
          height: RunTabsStyle.stripHeight,
          child: CustomPaint(painter: _StripPainter(speed, cells)),
        ),
        ChartLegend([
          (const LegendMark.box(RunTabsStyle.paceFast), s.runPaceFast),
          (const LegendMark.box(RunTabsStyle.paceUnderGoal), s.runPaceUnderGoal),
          (const LegendMark.box(RunTabsStyle.paceSlow), s.runPaceSlow),
          (const LegendMark.box(RunTabsStyle.paceMiss), s.legendMiss),
          if (fastest != null) (const LegendMark.box(Palette.paper), s.runPaceFastestRow(RunSpeedTuning.blockCards)),
        ]),
      ]),
    );
  }
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

/// D21: upright against upside-down.
class _Sides extends StatelessWidget {
  const _Sides(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final up = speed.upright, down = speed.upsideDown;
    final cost = switch ((up.meanMs, down.meanMs)) {
      (final u?, final d?) => d - u,
      _ => null,
    };
    _Cell cell(String label, SpeedSide side, Color fill) => _Cell(
          label: label,
          value: '${_seconds(side.meanMs)} s',
          note: s.runSideLine(side.cards, side.misses),
          fill: fill,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: HistoryRunStyle.sectionGap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _CellRow([
          cell('↑ ${s.runUpright}', up, Palette.paper),
          cell('↓ ${s.runUpsideDownSide}', down, Palette.seaSoft),
        ]),
        if (cost != null)
          HistoryCaption(cost >= 0 ? s.runUpsideCost(formatSeconds(cost)) : s.runUpsideGain(formatSeconds(-cost))),
      ]),
    );
  }
}

/// D22: the cards by their 決まり字's length, with a tick at the usual.
class _ByKimariji extends StatelessWidget {
  const _ByKimariji(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = speed.byKimariji;
    final top = [for (final r in rows) ...[?r.meanMs, ?r.usualMs]].fold<double>(0, (m, v) => v > m ? v : m) *
        RunTabsStyle.lengthHeadroom;
    return HistorySection(
      title: s.runKimarijiTitle,
      sub: s.sub?.runKimarijiTitle,
      note: s.runKimarijiNote,
      child: RunPanel(gap: false, children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gaps.tight),
            child: Row(children: [
              Expanded(
                flex: RunTabsStyle.lengthLabelFlex,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.runKimarijiLength(r.length), style: RunTabsStyle.lineStyle),
                  Text([s.cardsCount(r.cards), if (r.misses > 0) s.runMissMark(r.misses)].join(' · '),
                      style: RunTabsStyle.noteStyle),
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
                    '${_seconds(r.meanMs)}s',
                    maxLines: 1,
                    style: RunTabsStyle.valueStyle.copyWith(
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

/// D23: the run's timed cards against their usual times, and the cards
/// that gained and lost the most.
class _AgainstUsual extends StatelessWidget {
  const _AgainstUsual(this.speed);
  final RunSpeed speed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final a = speed.againstUsual;
    final gap = a.runMs - a.usualMs;
    return HistorySection(
      title: s.runUsualTitle,
      sub: s.sub?.runUsualTitle,
      child: a.compared == 0
          ? HistoryCaption(s.runNoUsual)
          : RunPanel(gap: false, children: [
              _CellRow([
                _Cell(label: s.runUsualFor(a.compared), value: formatTenths(_duration(a.usualMs))),
                _Cell(
                  label: s.runSwipesOnly,
                  value: formatTenths(_duration(a.runMs)),
                  valueColor: gap > 0 ? HistoryRunStyle.behind : HistoryRunStyle.ahead,
                ),
              ]),
              const SizedBox(height: Gaps.small),
              Text(
                '${s.runFasterOn(a.faster, a.compared)} '
                '${gap > 0 ? s.runOverallSlower(formatSeconds(gap, 1)) : s.runOverallFaster(formatSeconds(-gap, 1))}',
                style: RunTabsStyle.lineStyle,
              ),
              const SizedBox(height: Gaps.panel),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _Tiles(s.runMostGained, a.gained)),
                const SizedBox(width: Gaps.section),
                Expanded(child: _Tiles(s.runMostLost, a.lost)),
              ]),
            ]),
    );
  }
}

/// A row of small cards, each with its time against its usual and its
/// place in the run.
class _Tiles extends StatelessWidget {
  const _Tiles(this.title, this.diffs);
  final String title;
  final List<UsualDiff> diffs;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TrackedLabel(title),
        const SizedBox(height: Gaps.tight),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < RunReviewTuning.shownCards; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: RunTabsStyle.tileGap / 2),
                child: i < diffs.length ? _Tile(diffs[i]) : const SizedBox(),
              ),
            ),
        ]),
      ]);
}

class _Tile extends StatelessWidget {
  const _Tile(this.diff);
  final UsualDiff diff;

  @override
  Widget build(BuildContext context) {
    final card = diff.card;
    return Column(children: [
      TorifudaCard(poem: poems[card.swipe.poemId], inverted: card.swipe.inverted, showNumber: false),
      const SizedBox(height: Gaps.tight),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(formatSignedSeconds(diff.diffMs),
            maxLines: 1,
            style: RunTabsStyle.valueStyle
                .copyWith(color: diff.diffMs < 0 ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('#${card.number}${card.swipe.inverted ? ' ↓' : ''}', maxLines: 1, style: RunTabsStyle.noteStyle),
      ),
    ]);
  }
}

/// A warning line on a tinted strip, over the tab.
class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => RunPanel(color: Palette.pinkSoft, children: [
        Text(text, style: RunTabsStyle.lineStyle),
      ]);
}

/// One cell of a [_CellRow]: a tracked label, a big value and a note.
class _Cell {
  const _Cell({required this.label, required this.value, this.note, this.fill = Palette.paper, this.valueColor});
  final String label, value;
  final String? note;
  final Color fill;
  final Color? valueColor;
}

/// Cells side by side in an ink box ruled between them; unboxed with
/// [ruled] false (inside a panel).
class _CellRow extends StatelessWidget {
  const _CellRow(this.cells, {this.ruled = true});
  final List<_Cell> cells;
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Palette.ink, width: Strokes.label);
    return Container(
      foregroundDecoration: BoxDecoration(border: ruled ? Border.all(color: Palette.ink, width: Strokes.panel) : null),
      padding: ruled ? const EdgeInsets.all(Strokes.panel) : EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, c) in cells.indexed)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.fill, border: i == 0 ? null : const Border(left: side)),
                child: Padding(
                  padding: ruled || i > 0 ? HistoryRunStyle.factPadding : RunTabsStyle.firstCellPadding,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TrackedLabel(c.label),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(c.value, maxLines: 1, style: RunTabsStyle.cellValueStyle.copyWith(color: c.valueColor)),
                    ),
                    if (c.note case final note? when note.isNotEmpty) Text(note, style: RunTabsStyle.noteStyle),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// [ms] in seconds, or the missing mark.
String _seconds(double? ms) => ms == null ? missingTime : formatSeconds(ms);

Duration _duration(double ms) => Duration(milliseconds: ms.round());
