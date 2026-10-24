import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/trainer.dart' show LearningMode;
import '../../l10n/srs_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/progress.dart';
import '../../state/stats_history.dart';
import '../history/history_widgets.dart';
import '../history/run_charts.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'card_detail_screen.dart';
import 'day_chart.dart';
import 'practice_calendar.dart';

/// #1: known cards, the streak and the recall chance now on History's sun
/// strip, and in journey mode the pace bar under them.
class SrsGlance extends StatelessWidget {
  const SrsGlance(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final known = progress.knownCount();
    final recall = progress.recallNow();
    final journey = progress.trainer.config.learningMode == LearningMode.journey;
    Widget cell(String label, String? sub, String value, String unit, {VoidCallback? onTap}) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: SrsLayout.glanceCellPadding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TrackedLabel(label, sub: sub),
                const SizedBox(height: Gaps.tight),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: value, style: const TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.glanceFont)),
                    TextSpan(text: unit, style: const TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.glanceUnitFont)),
                  ]), maxLines: 1),
                ),
              ]),
            ),
          ),
        );
    const rule = ColoredBox(color: Palette.ink, child: SizedBox(width: Strokes.control));
    return Padding(
      padding: const EdgeInsets.only(bottom: HistoryRunStyle.sectionGap),
      child: MangaPanel(
        shape: const PanelShape(bottomRight: Offset(HistoryListStyle.stripCut, 0)),
        tone: Tones.sun,
        shadow: HistoryRunStyle.panelShadow,
        padding: SrsLayout.glancePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              cell(s.srsKnown, s.sub?.srsKnown, '$known', '/${poems.all.length}'),
              rule,
              cell(s.srsStreak, s.sub?.srsStreak, '${progress.activeStreak()}', ' ${s.srsDaysUnit(progress.activeStreak())}',
                  onTap: () => openPracticeCalendar(context)),
              rule,
              cell(s.srsRemembered, s.sub?.srsRemembered, recall == null ? '—' : '${(recall * 100).round()}', '%'),
            ]),
          ),
          if (journey) _PaceGauge(progress, known: known),
        ]),
      ),
    );
  }
}

class _PaceGauge extends StatelessWidget {
  const _PaceGauge(this.progress, {required this.known});
  final Progress progress;
  final int known;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pace = progress.paceStatus();
    final total = pace.total;
    return Container(
      margin: SrsLayout.gaugeMargin,
      padding: SrsLayout.gaugePadding,
      decoration: const BoxDecoration(border: Border(top: BorderSide(width: Strokes.control))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.srsPaceDay(pace.day + 1, pace.pace.profile.daysToAll), style: RunTabsStyle.lineStyle),
        const SizedBox(height: Gaps.tight),
        SizedBox(
          height: SrsLayout.gaugeHeight,
          child: CustomPaint(
            painter: _GaugePainter(unlocked: pace.unlocked / total, known: known / total, pace: pace.target / total),
          ),
        ),
        ChartLegend([
          (const LegendMark.box(Palette.pink), s.srsKnownCount(known)),
          (const LegendMark.box(Palette.pinkSoft), s.srsUnlockedCount(pace.unlocked)),
          (const LegendMark.line(Palette.seaDeep), s.srsPaceToday(pace.target)),
        ]),
      ]),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.unlocked, required this.known, required this.pace});
  final double unlocked, known, pace;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Palette.paper);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * unlocked, size.height), Paint()..color = Palette.pinkSoft);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * known, size.height), Paint()..color = Palette.pink);
    canvas.drawRect(
        rect.deflate(Strokes.label / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.label);
    final x = size.width * pace.clamp(0.0, 1.0);
    canvas.drawLine(Offset(x, -RunTabsStyle.tickReach * 2), Offset(x, size.height + RunTabsStyle.tickReach * 2),
        Paint()
          ..color = Palette.seaDeep
          ..strokeWidth = RunTabsStyle.tickStroke);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.unlocked != unlocked || old.known != known || old.pace != pace;
}

/// #2: upright cards known each day, with cards unlocked, the journey's
/// pace goal and where the last days' trend leads.
class SrsKnownOverTime extends StatelessWidget {
  const SrsKnownOverTime(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final counted = progress.playedDaysFromZero();
    if (counted.isEmpty) return _Empty(title: s.srsKnownTitle, sub: s.sub?.srsKnownTitle);
    final total = poems.all.length;
    final known = progress.knownOn(counted);
    final unlocked = progress.unlockedOn(counted);
    final now = known.last;
    final today = counted.length - 1;
    // The trend spans played days only, so the first day alone sets none.
    final back = math.min(SrsTuning.trendDays, today - 1);
    final gain = now - known[today - back];
    final rate = back == 0 ? 0.0 : gain / back;
    final daysLeft = rate > 0 && now < total ? ((total - now) / rate).ceil() : null;
    final ahead = daysLeft == null ? 0 : math.min(daysLeft, SrsTuning.chartDays);
    final last = counted.last;
    final days = [...counted, for (var i = 1; i <= ahead; i++) DateTime.utc(last.year, last.month, last.day + i)];
    final pace = progress.paceOn(days);
    final trend = [
      for (var i = 0; i < days.length; i++) i < today ? null : math.min(total.toDouble(), now + rate * (i - today)),
    ];
    final finish = daysLeft == null ? null : DateTime.utc(last.year, last.month, last.day + daysLeft);
    return HistorySection(
      title: s.srsKnownTitle,
      sub: s.sub?.srsKnownTitle,
      note: s.srsGainIn(gain, back),
      child: RunPanel(children: [
        DayLineChart(
          lo: 0,
          hi: total.toDouble(),
          ticks: SrsLayout.knownTicks,
          format: (v) => '${v.round()}',
          today: today,
          // Point 0 is the end of the day before the first played day, which
          // is the first day's start, so it takes the first day's date.
          xLabels: {0: s.dayDate(days[1]), today: s.srsToday, if (days.length - 1 > today) days.length - 1: s.dayDate(days.last)},
          lines: [
            ChartLine([for (final v in unlocked) v.toDouble()],
                fill: SrsLayout.unlockedFill, stroke: SrsLayout.unlockedStroke, dash: SrsLayout.unlockedDash),
            ChartLine([for (final v in known) v.toDouble()], fill: SrsLayout.knownFill, stroke: SrsLayout.knownStroke),
            if (pace != null)
              ChartLine([for (final v in pace) v?.toDouble()],
                  color: Palette.sea, stroke: SrsLayout.paceStroke, dash: SrsLayout.dotDash),
            if (ahead > 0) ChartLine(trend, color: Palette.pinkDeep, stroke: SrsLayout.trendStroke, dash: Strokes.dash),
          ],
          marks: [ChartMark(today, now.toDouble(), s.srsKnownCount(now))],
        ),
        ChartLegend([
          (const LegendMark.box(SrsLayout.knownFill), s.srsLegendKnown),
          (const LegendMark.line(Palette.ink, dashed: true, background: SrsLayout.unlockedFill), s.srsLegendUnlocked),
          if (pace != null) (const LegendMark.line(Palette.sea, dashed: true), s.srsLegendPace),
          if (ahead > 0) (const LegendMark.line(Palette.pinkDeep, dashed: true), s.srsLegendTrend),
        ]),
        if (finish != null && now < total) _Callout(big: s.dayDate(finish), text: s.srsAllKnownBy),
      ]),
    );
  }
}

/// A big value beside its line, on a sun-tinted box.
class _Callout extends StatelessWidget {
  const _Callout({required this.big, required this.text});
  final String big, text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: Gaps.panel),
        padding: SrsLayout.calloutPadding,
        decoration: BoxDecoration(color: Palette.sunSoft, border: Border.all(width: Strokes.label)),
        child: Row(children: [
          Text(big, style: const TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.calloutFont, height: 1)),
          const SizedBox(width: Gaps.panel),
          Expanded(child: Text(text, style: RunTabsStyle.lineStyle)),
        ]),
      );
}

/// A section with nothing to show yet.
class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.sub});
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => HistorySection(
        title: title,
        sub: sub,
        child: RunPanel(children: [Text(S.of(context).srsNoData, style: RunTabsStyle.noteStyle)]),
      );
}

/// A memory stage's fill and texture, and its text colour.
({Color color, ToneSpec? tone, Color text}) stageStyle(MemoryStage stage) => switch (stage) {
      MemoryStage.notStarted => (color: Palette.paper, tone: null, text: SrsLayout.notStartedInk),
      MemoryStage.fresh => (color: Palette.seaSoft, tone: Tones.sea, text: Palette.ink),
      MemoryStage.learning => (color: Palette.pink, tone: null, text: Palette.ink),
      MemoryStage.gettingThere => (color: Palette.sunSoft, tone: Tones.sun, text: Palette.ink),
      MemoryStage.solid => (color: Palette.land, tone: null, text: Palette.ink),
      MemoryStage.mastered => (color: Palette.landDeep, tone: null, text: Palette.paper),
    };

/// A stage's swatch: its fill in an ink square, dashed for not started.
class StageSwatch extends StatelessWidget {
  const StageSwatch(this.stage, {super.key, this.size = RunChartStyle.legendBox, this.child});
  final MemoryStage stage;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final style = stageStyle(stage);
    final box = SizedBox.square(dimension: size, child: child);
    if (stage == MemoryStage.notStarted) {
      return DashedBox(ink: SrsLayout.notStartedInk, border: Strokes.hairline, dash: Strokes.fineDash, child: box);
    }
    return Container(
      decoration: BoxDecoration(color: style.color, border: Border.all(width: Strokes.hairline)),
      child: style.tone == null ? box : ToneBox(style.tone!, child: box),
    );
  }
}

/// #3: every card as a tile in its stage's colour, in learning order, one
/// side at a time; a tile opens its card.
class SrsWall extends StatefulWidget {
  const SrsWall(this.progress, {super.key});
  final Progress progress;

  @override
  State<SrsWall> createState() => _SrsWallState();
}

class _SrsWallState extends State<SrsWall> {
  bool _inverted = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final order = widget.progress.learningOrder;
    return HistorySection(
      title: s.srsWallTitle,
      sub: s.sub?.srsWallTitle,
      child: RunPanel(children: [
        Align(
          alignment: Alignment.centerRight,
          child: SrsToggle(
            labels: [s.srsUpright, s.srsUpsideDown],
            picked: _inverted ? 1 : 0,
            onPick: (i) => setState(() => _inverted = i == 1),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        for (var row = 0; row < order.length; row += SrsLayout.wallColumns)
          Padding(
            padding: const EdgeInsets.only(bottom: SrsLayout.wallGap),
            child: Row(children: [
              for (var i = row; i < row + SrsLayout.wallColumns && i < order.length; i++) ...[
                if (i > row) const SizedBox(width: SrsLayout.wallGap),
                Expanded(child: _WallTile(ItemKey(order[i], _inverted), widget.progress.stageOf(ItemKey(order[i], _inverted)))),
              ],
            ]),
          ),
        ChartLegend([for (final st in MemoryStage.values.reversed) (StageSwatch(st), s.stageName(st))]),
        HistoryCaption(s.srsWallNote),
      ]),
    );
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile(this.itemKey, this.stage);
  final ItemKey itemKey;
  final MemoryStage stage;

  @override
  Widget build(BuildContext context) {
    final style = stageStyle(stage);
    final kana = poems[itemKey.poemId].kimariji.characters.first;
    return Semantics(
      button: true,
      label: '${kimarijiFor(context, itemKey.poemId)}, ${S.of(context).stageName(stage)}',
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MangaRoute<void>(builder: (_) => CardDetailScreen(itemKey: itemKey))),
        child: AspectRatio(
          aspectRatio: SrsLayout.wallTileAspect,
          child: LayoutBuilder(builder: (context, box) {
            final label = Center(
              child: RotatedBox(
                quarterTurns: itemKey.inverted ? 2 : 0,
                child: Text(kana,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                        fontFamily: Fonts.display, fontSize: box.maxWidth * SrsLayout.wallFontShare, height: 1, color: style.text)),
              ),
            );
            return Stack(fit: StackFit.expand, children: [
              StageSwatch(stage, size: box.maxWidth, child: label),
              if (stage == MemoryStage.mastered)
                Positioned(
                  right: SrsLayout.masteredDotInset,
                  top: SrsLayout.masteredDotInset,
                  child: Container(
                    width: SrsLayout.masteredDot,
                    height: SrsLayout.masteredDot,
                    decoration: BoxDecoration(color: Palette.sun, shape: BoxShape.circle, border: Border.all(width: 1)),
                  ),
                ),
            ]);
          }),
        ),
      ),
    );
  }
}

/// #4: how many cards of each side are at each stage, as a bar, and what
/// each stage means.
class SrsStrength extends StatelessWidget {
  const SrsStrength(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final order = progress.learningOrder;
    Map<MemoryStage, int> counts(bool inverted) {
      final c = {for (final st in MemoryStage.values) st: 0};
      for (final id in order) {
        c[progress.stageOf(ItemKey(id, inverted))] = c[progress.stageOf(ItemKey(id, inverted))]! + 1;
      }
      return c;
    }

    final up = counts(false), down = counts(true);
    int known(Map<MemoryStage, int> c) => c.entries.where((e) => e.key.known).fold(0, (n, e) => n + e.value);
    Widget side(String label, Map<MemoryStage, int> c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, style: RunTabsStyle.lineStyle)),
            Text(s.srsKnownCount(known(c)), style: RunTabsStyle.lineStyle),
          ]),
          const SizedBox(height: Gaps.tight),
          Container(
            height: SrsLayout.stackHeight,
            decoration: BoxDecoration(border: Border.all(width: Strokes.control)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, st) in [for (final st in MemoryStage.values.reversed) if (c[st]! > 0) st].indexed)
                Expanded(flex: c[st]!, child: _StackPart(st, c[st]!, first: i == 0)),
            ]),
          ),
          const SizedBox(height: Gaps.panel),
        ]);
    final params = {
      MemoryStage.fresh: SrsTuning.newBelowSwipes,
      MemoryStage.solid: StatsTuning.solidWindow,
      MemoryStage.mastered: progress.trainer.config.masteryStabilityDays.round(),
    };
    return HistorySection(
      title: s.srsStrengthTitle,
      sub: s.sub?.srsStrengthTitle,
      child: RunPanel(children: [
        side(s.srsUpright, up),
        side(s.srsUpsideDown, down),
        Table(
          columnWidths: const {0: FixedColumnWidth(SrsLayout.stageSwatchColumn), 1: FlexColumnWidth()},
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(children: [
              const SizedBox(),
              for (final (i, h) in [s.srsStage, s.srsUp, s.srsDown].indexed)
                Padding(
                  padding: RunTabsStyle.tableCellPadding,
                  child: Text(h.toUpperCase(), textAlign: i == 0 ? TextAlign.left : TextAlign.right, style: RunTabsStyle.headStyle),
                ),
            ]),
            for (final st in MemoryStage.values.reversed)
              TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: RunTabsStyle.rule))),
                children: [
                  Padding(padding: RunTabsStyle.tableCellPadding, child: Align(alignment: Alignment.topLeft, child: StageSwatch(st))),
                  Padding(
                    padding: RunTabsStyle.tableCellPadding,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text([s.stageName(st), ?s.sub?.stageName(st)].join('  '), style: RunTabsStyle.lineStyle),
                      Text(s.stageText(st, params[st] ?? 0), style: RunTabsStyle.rowStyle),
                    ]),
                  ),
                  for (final c in [up, down])
                    Padding(
                      padding: RunTabsStyle.tableCellPadding,
                      child: Text('${c[st]}', textAlign: TextAlign.right, style: RunTabsStyle.valueStyle),
                    ),
                ],
              ),
          ],
        ),
      ]),
    );
  }
}

class _StackPart extends StatelessWidget {
  const _StackPart(this.stage, this.count, {required this.first});
  final MemoryStage stage;
  final int count;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final style = stageStyle(stage);
    final label = Center(
      child: count >= SrsLayout.stackMinLabel
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$count', style: TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.stackFont, color: style.text)),
            )
          : null,
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: style.color, border: first ? null : const Border(left: BorderSide(width: Strokes.label))),
      child: style.tone == null ? label : ToneBox(style.tone!, child: label),
    );
  }
}

/// #17: minutes practised each of the last days, the total, and the last
/// weeks' totals.
class SrsTimePractised extends StatelessWidget {
  const SrsTimePractised(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final log = progress.practiceLog;
    final days = progress.lastDays(SrsTuning.chartDays);
    final total = log.values.fold(Duration.zero, (t, d) => t + d.clock);
    if (total == Duration.zero) return _Empty(title: s.srsTimeTitle, sub: s.sub?.srsTimeTitle);
    final minutes = [for (final d in days) (log[d]?.clock ?? Duration.zero).inSeconds / Duration.secondsPerMinute];
    final today = days.last;
    final weekStart = DateTime.utc(today.year, today.month, today.day - (today.weekday - DateTime.monday));
    final weeks = [
      for (var w = SrsLayout.weeks - 1; w >= 0; w--) DateTime.utc(weekStart.year, weekStart.month, weekStart.day - 7 * w),
    ];
    Duration weekTotal(DateTime start) => [
          for (var i = 0; i < DateTime.daysPerWeek; i++) log[DateTime.utc(start.year, start.month, start.day + i)]?.clock,
        ].nonNulls.fold(Duration.zero, (t, c) => t + c);
    return HistorySection(
      title: s.srsTimeTitle,
      sub: s.sub?.srsTimeTitle,
      note: s.srsTotal(s.srsDuration(total)),
      child: RunPanel(children: [
        BarChart(
          bars: [
            for (final (i, m) in minutes.indexed)
              ChartBar(m, color: i == minutes.length - 1 ? Palette.pinkSoft : Palette.pink),
          ],
          format: (v) => s.srsMinuteAxis(v.round()),
          steps: SrsLayout.minuteSteps,
          xLabels: {
            for (var i = 0; i < days.length; i += DateTime.daysPerWeek) i: s.dayDate(days[i]),
            days.length - 1: s.srsToday,
          },
        ),
        const SizedBox(height: Gaps.panel),
        FactGrid(
          [
            for (final w in weeks)
              Fact(s.srsDuration(weekTotal(w)), w == weekStart ? s.srsThisWeek : s.srsWeekOf(s.dayDate(w))),
          ],
          perRow: SrsLayout.weeks,
        ),
      ]),
    );
  }
}

/// #18: the median time of each of the last days' right swipes, over
/// every card and over the cards known now.
class SrsSpeed extends StatelessWidget {
  const SrsSpeed(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final days = progress.lastDays(SrsTuning.chartDays);
    final speed = progress.speedOn(days);
    final values = [...speed.all, ...speed.known].nonNulls.toList();
    if (values.isEmpty) return _Empty(title: s.srsSpeedTitle, sub: s.sub?.srsSpeedTitle);
    const step = SrsLayout.speedStepMs;
    final lo = (values.reduce(math.min) / step).floor() * step;
    final hi = math.max(lo + step, (values.reduce(math.max) / step).ceil() * step);
    String sec(double ms) => formatSeconds(ms, 1);
    return HistorySection(
      title: s.srsSpeedTitle,
      sub: s.sub?.srsSpeedTitle,
      note: s.srsLowerFaster,
      child: RunPanel(children: [
        DayLineChart(
          lo: lo,
          hi: hi,
          ticks: [for (var t = lo; t <= hi; t += step) t],
          format: (v) => s.srsSecondsAxis(sec(v)),
          today: days.length - 1,
          xLabels: {
            for (var i = 0; i < days.length; i += DateTime.daysPerWeek) i: s.dayDate(days[i]),
            days.length - 1: s.srsToday,
          },
          lines: [
            ChartLine(speed.all, dots: true),
            ChartLine(speed.known, color: Palette.pinkDeep, stroke: SrsLayout.knownStroke, dots: true),
          ],
        ),
        ChartLegend([
          (const LegendMark.line(Palette.ink), s.srsAllSwipes),
          (const LegendMark.line(Palette.pinkDeep), s.srsCardsYouKnow),
        ]),
      ]),
    );
  }
}

/// #19: known cards, swipes, misses and the typical time of upright and
/// upside-down cards side by side; the worse of each pair in pink.
class SrsSides extends StatelessWidget {
  const SrsSides(this.progress, {super.key});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final up = progress.sideSummary(inverted: false), down = progress.sideSummary(inverted: true);
    String percent(double? r) => r == null ? missingTime : '${(r * 100).round()}%';
    String time(double? ms) => ms == null ? missingTime : '${formatSeconds(ms)}s';
    bool worse(double? a, double? b) => a != null && b != null && a > b;
    final rows = [
      (s.srsRowKnown, '${up.known}', '${down.known}', false, false),
      (s.srsRowSwipes, '${up.swipes}', '${down.swipes}', false, false),
      (s.srsRowMissed, percent(up.missRate), percent(down.missRate), worse(up.missRate, down.missRate),
          worse(down.missRate, up.missRate)),
      (s.srsRowTime, time(up.medianMs), time(down.medianMs), worse(up.medianMs, down.medianMs),
          worse(down.medianMs, up.medianMs)),
    ];
    Widget value(String v, bool bad) => Padding(
          padding: RunTabsStyle.tableCellPadding,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(v,
                maxLines: 1,
                style: RunTabsStyle.cellValueStyle.copyWith(color: bad ? HistoryRunStyle.behind : Palette.ink)),
          ),
        );
    Widget head(String label, bool inverted) => Padding(
          padding: RunTabsStyle.tableCellPadding,
          child: Column(children: [
            StageSwatch(MemoryStage.solid,
                size: SrsLayout.sideCard,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: inverted ? 2 : 0,
                    child: const Text(SrsLayout.sideCardGlyph,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.sideCardFont, height: 1)),
                  ),
                )),
            const SizedBox(height: Gaps.tight),
            Text(label, textAlign: TextAlign.center, style: RunTabsStyle.lineStyle),
          ]),
        );
    return HistorySection(
      title: s.srsSidesTitle,
      sub: s.sub?.srsSidesTitle,
      child: RunPanel(children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(SrsLayout.sideLabelFlex)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [const SizedBox(), head(s.srsUpright, false), head(s.srsUpsideDown, true)]),
            for (final (label, a, b, badA, badB) in rows)
              TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: RunTabsStyle.rule))),
                children: [
                  Padding(padding: RunTabsStyle.tableCellPadding, child: Text(label, style: RunTabsStyle.lineStyle)),
                  value(a, badA),
                  value(b, badB),
                ],
              ),
          ],
        ),
      ]),
    );
  }
}

/// A small two-way switch, as Stats' Islands | All.
class SrsToggle extends StatelessWidget {
  const SrsToggle({super.key, required this.labels, required this.picked, required this.onPick});
  final List<String> labels;
  final int picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Container(
        height: SrsLayout.toggleHeight,
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(width: Strokes.control)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, label) in labels.indexed) ...[
            if (i > 0) const ColoredBox(color: Palette.ink, child: SizedBox(width: Strokes.control)),
            Semantics(
              button: true,
              selected: i == picked,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: AnimatedContainer(
                  duration: Motion.tab,
                  color: i == picked ? Palette.ink : Palette.paper,
                  padding: SrsLayout.togglePadding,
                  alignment: Alignment.center,
                  child: Text(label,
                      style: TextStyle(
                          fontWeight: Weights.black,
                          fontSize: SrsLayout.toggleFont,
                          color: i == picked ? Palette.paper : Palette.ink)),
                ),
              ),
            ),
          ],
        ]),
      );
}
