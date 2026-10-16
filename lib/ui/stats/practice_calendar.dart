import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/trainer.dart' show LearningMode;
import '../../l10n/home_strings.dart';
import '../../l10n/srs_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/scope.dart';
import '../../state/stats_history.dart';
import '../history/history_widgets.dart';
import '../history/run_charts.dart';
import '../manga/manga.dart';
import 'stats_page.dart';

/// Opens the practice calendar.
Future<void> openPracticeCalendar(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const PracticeCalendarScreen()));

/// How much a day was practised, as the calendar shades it.
enum _Shade { none, little, usual, lot }

/// The practice calendar: the streaks on top, then every month from this
/// one back to the first day of play, each day shaded by how much it was
/// practised, ticked when its set was finished, today ringed.
class PracticeCalendarScreen extends StatelessWidget {
  const PracticeCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final log = progress.practiceLog;
    final today = progress.dayAt().date;
    final first = log.keys.fold(today, (a, b) => b.isBefore(a) ? b : a);
    final months = [
      for (var m = DateTime.utc(today.year, today.month); !m.isBefore(DateTime.utc(first.year, first.month));
          m = DateTime.utc(m.year, m.month - 1))
        m,
    ];
    final journey = progress.trainer.config.learningMode == LearningMode.journey;
    return StatsPage(
      title: s.calendarTitle,
      sub: s.other.calendarTitle,
      body: StatsPageList(children: [
        FactGrid([
          Fact('${progress.activeStreak()}', s.calStreak),
          Fact('${progress.bestStreak}', s.calBest),
          journey
              ? Fact('${log.values.where((d) => d.setDone).length}', s.calSets)
              : Fact('${log.values.where((d) => d.active).length}', s.calDays),
        ], perRow: 3, fill: Palette.pinkSoft),
        ChartLegend([
          (const _ShadeSwatch(_Shade.little), s.calLittle),
          (const _ShadeSwatch(_Shade.usual), s.calUsual),
          (const _ShadeSwatch(_Shade.lot), s.calLot),
          if (journey) (const _Tick(size: RunChartStyle.legendBox), s.calSetDone),
        ]),
        for (final m in months) _Month(month: m, log: log, today: today),
      ]),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month({required this.month, required this.log, required this.today});
  final DateTime month;
  final Map<DateTime, PracticeDay> log;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lead = month.weekday - DateTime.monday;
    final length = DateTime.utc(month.year, month.month + 1, 0).day;
    final weeks = ((lead + length) / DateTime.daysPerWeek).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: CalendarLayout.monthGap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HistoryHeading(title: s.monthTitle(month)),
        const SizedBox(height: Gaps.small),
        Row(children: [
          for (var d = 1; d <= DateTime.daysPerWeek; d++) ...[
            if (d > 1) const SizedBox(width: CalendarLayout.cellGap),
            Expanded(
              child: Text(s.weekdayLetter(d),
                  textAlign: TextAlign.center, style: RunTabsStyle.headStyle.copyWith(color: HistoryRunStyle.muted)),
            ),
          ],
        ]),
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: const EdgeInsets.only(top: CalendarLayout.cellGap),
            child: Row(children: [
              for (var d = 0; d < DateTime.daysPerWeek; d++) ...[
                if (d > 0) const SizedBox(width: CalendarLayout.cellGap),
                Expanded(child: _cell(w * DateTime.daysPerWeek + d - lead + 1, length)),
              ],
            ]),
          ),
      ]),
    );
  }

  Widget _cell(int day, int length) {
    if (day < 1 || day > length) return const SizedBox(height: CalendarLayout.cellHeight);
    final date = DateTime.utc(month.year, month.month, day);
    return _Day(date: date, entry: log[date], today: date == today, future: date.isAfter(today));
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.entry, required this.today, required this.future});
  final DateTime date;
  final PracticeDay? entry;
  final bool today, future;

  static _Shade shadeOf(PracticeDay? d) {
    if (d == null || !d.active) return _Shade.none;
    if (d.swipes >= CalendarTuning.lotSwipes) return _Shade.lot;
    if (d.swipes >= CalendarTuning.usualSwipes) return _Shade.usual;
    return _Shade.little;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final number = Padding(
      padding: CalendarLayout.numberPadding,
      child: Text('${date.day}',
          style: TextStyle(
              fontWeight: Weights.black,
              fontSize: CalendarLayout.numberFont,
              height: 1,
              color: future ? HistoryRunStyle.muted : Palette.ink)),
    );
    final Widget box = future
        ? DashedBox(
            ink: CalendarLayout.futureInk,
            border: Strokes.label,
            dash: Strokes.fineDash,
            child: SizedBox(height: CalendarLayout.cellHeight, child: Align(alignment: Alignment.topLeft, child: number)),
          )
        : _ShadeSwatch(
            shadeOf(entry),
            height: CalendarLayout.cellHeight,
            child: Stack(children: [
              number,
              if (entry?.setDone ?? false)
                const Positioned(
                  right: CalendarLayout.tickInset,
                  bottom: CalendarLayout.tickInset,
                  child: _Tick(size: CalendarLayout.tick),
                ),
            ]),
          );
    return Semantics(
      label: [s.dayDate(date), if (entry?.active ?? false) s.calDaySwipes(entry!.swipes)].join(', '),
      child: today
          ? DecoratedBox(
              decoration: const BoxDecoration(boxShadow: [
                BoxShadow(color: Palette.ink, spreadRadius: CalendarLayout.todayRingOuter),
                BoxShadow(color: Palette.sun, spreadRadius: CalendarLayout.todayRing),
              ]),
              child: box,
            )
          : box,
    );
  }
}

/// A day's fill for [shade], in an ink border.
class _ShadeSwatch extends StatelessWidget {
  const _ShadeSwatch(this.shade, {this.height = RunChartStyle.legendBox, this.child});
  final _Shade shade;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tone = switch (shade) {
      _Shade.none => null,
      _Shade.little => Tones.calendarLittle,
      _Shade.usual => Tones.calendarUsual,
      _Shade.lot => Tones.calendarLot,
    };
    final inner = SizedBox(height: height, width: child == null ? height : null, child: child);
    return Container(
      decoration: BoxDecoration(color: Palette.paper, border: Border.all(width: Strokes.label)),
      child: tone == null ? inner : ToneBox(tone, child: inner),
    );
  }
}

/// A set finished: a white tick on an ink disc.
class _Tick extends StatelessWidget {
  const _Tick({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Palette.ink,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.paper, width: CalendarLayout.tickRim),
        ),
        alignment: Alignment.center,
        child: MangaIcon(IconArt.check,
            size: size * CalendarLayout.tickIconShare, color: Palette.paper, strokeWidth: CalendarLayout.tickStroke),
      );
}
