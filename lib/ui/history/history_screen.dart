import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../db/database.dart' show Session, SideTripRun;
import '../../domain/side_trips.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_labels.dart';

/// The History tab: every past run and side-trip game, newest first, high-
/// contrast ink on paper (unlike the original app's dim grey-on-green history
/// text), under a record strip summing them up and a run-kind filter that
/// narrows both. Opening a run for detail is a later task.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final entries = <_Entry>[
      for (final session in progress.sessions) _SessionEntry(session, progress.configOf(session).mode),
      for (final run in progress.sideTrips.runs) _TripEntry(run),
    ].where(_filter.keeps).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(title: ScreenTitle(s.history, sub: s.other.history)),
          _RecordStrip(_Record(entries), showBest: _filter.trip != null),
          const SizedBox(height: HistoryHeaderLayout.filterGap),
          _FilterBar(selected: _filter, onChanged: (filter) => setState(() => _filter = filter)),
          const SizedBox(height: Gaps.section),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: DashedBox(
                      padding: HistoryLayout.emptyPadding,
                      child: Text(s.noRunsYet, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
                    ),
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gaps.panel),
                    itemBuilder: (context, i) => switch (entries[i]) {
                      final _SessionEntry e => _SessionRow(e.session),
                      final _TripEntry e => _TripRow(e.run),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One line of History: a 札落とし session or a side-trip game.
sealed class _Entry {
  const _Entry();
  DateTime get startedAt;
  int get cardCount;

  /// The local date it was played on.
  DateTime get day {
    final at = startedAt.toLocal();
    return DateTime(at.year, at.month, at.day);
  }
}

class _SessionEntry extends _Entry {
  const _SessionEntry(this.session, this.mode);
  final Session session;
  final PlayMode mode;

  @override
  DateTime get startedAt => session.startedAt;

  @override
  int get cardCount => session.cardCount;
}

class _TripEntry extends _Entry {
  const _TripEntry(this.run);
  final SideTripRun run;

  @override
  DateTime get startedAt => run.startedAt;

  @override
  int get cardCount => run.cardCount;
}

/// What History lists: every run, one play mode's runs, or one side trip's
/// games.
class _Filter {
  const _Filter._({this.mode, this.trip});

  static const all = _Filter._();

  /// In the order the filter row shows them.
  static final values = [
    all,
    for (final mode in [PlayMode.training, PlayMode.free, PlayMode.nigate]) _Filter._(mode: mode),
    for (final trip in SideTrip.values) _Filter._(trip: trip),
  ];

  final PlayMode? mode;
  final SideTrip? trip;

  bool keeps(_Entry entry) =>
      this == all ||
      switch (entry) {
        _SessionEntry(:final mode) => mode == this.mode,
        _TripEntry(:final run) => run.game == trip?.name,
      };

  String label(S s) =>
      trip?.label ??
      switch (mode) {
        null => s.allTab,
        PlayMode.training => s.training,
        PlayMode.free => s.freePlay,
        PlayMode.nigate => s.weakCards,
        PlayMode.guest => s.guest,
      };
}

/// What the record strip sums up over the runs on show.
class _Record {
  _Record(List<_Entry> entries)
      : runs = entries.length,
        cards = entries.fold(0, (sum, entry) => sum + entry.cardCount),
        days = {for (final entry in entries) entry.day}.length,
        bestScore = entries
            .whereType<_TripEntry>()
            .map((entry) => entry.run.score)
            .fold<int?>(null, (best, score) => best == null || score > best ? score : best);

  final int runs, cards, days;

  /// The best side-trip score among them, if any.
  final int? bestScore;
}

/// The runs on show summed up: how many, how many cards they dealt, and the
/// days they were played on, or a side trip's best score when [showBest].
class _RecordStrip extends StatelessWidget {
  const _RecordStrip(this.record, {required this.showBest});
  final _Record record;
  final bool showBest;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(HistoryHeaderLayout.stripCut, 0)),
      tone: Tones.sun,
      padding: HistoryHeaderLayout.stripPadding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Stat(s.historyRunsLabel, '${record.runs}')),
            const _StatRule(),
            Expanded(child: _Stat(s.historyCardsLabel, '${record.cards}')),
            const _StatRule(),
            Expanded(
              child: showBest
                  ? _Stat(s.historyBestLabel, record.bestScore?.toString() ?? missingTime)
                  : _Stat(s.historyDaysLabel, '${record.days}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One stat of the record strip: a tracked label over its number, each
/// shrunk rather than cut when the cell is too narrow.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: Weights.black,
                fontSize: HistoryHeaderLayout.statLabelFont,
                letterSpacing: HistoryHeaderLayout.statLabelTracking * HistoryHeaderLayout.statLabelFont,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: HistoryHeaderLayout.statGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: Fonts.display,
                fontSize: HistoryHeaderLayout.statFont,
                height: TypeScale.displayLineHeight,
              ),
            ),
          ),
        ],
      );
}

/// The ink rule between two stats.
class _StatRule extends StatelessWidget {
  const _StatRule();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: HistoryHeaderLayout.statRuleInset),
        child: SizedBox(width: Strokes.label, child: ColoredBox(color: Palette.ink)),
      );
}

/// The run-kind filter: one segmented control whose segments wrap into as
/// few rows as fit, as even in count as can be, each row sharing its spare
/// room out evenly among its segments. The segments sit on ink, which shows
/// between them as the rules.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final filters = _Filter.values;
    final labels = [for (final filter in filters) filter.label(s)];
    final style = DefaultTextStyle.of(context).style.merge(_Segment.style);
    final scaler = MediaQuery.textScalerOf(context);
    final widths = [
      for (final label in labels) _textWidth(label, style, scaler) + 2 * HistoryHeaderLayout.segmentPadding,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth - 2 * Strokes.control;
        return ColoredBox(
          color: Palette.ink,
          child: Padding(
            padding: const EdgeInsets.all(Strokes.control),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Strokes.hairline,
              children: [
                for (final row in _rows(widths, room))
                  Row(
                    spacing: Strokes.hairline,
                    children: [
                      for (final f in row)
                        Expanded(
                          flex: _flex(widths[f] + _spare(row, widths, room) / row.length),
                          child: _Segment(
                            labels[f],
                            selected: filters[f] == selected,
                            onTap: () => onChanged(filters[f]),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// What is left of [room] once [row]'s segments and the rules between
  /// them are in.
  static double _spare(List<int> row, List<double> widths, double room) =>
      room - (row.length - 1) * Strokes.hairline - row.fold(0.0, (sum, i) => sum + widths[i]);

  /// A width as a flex factor, to a hundredth of a pixel.
  static int _flex(double width) => (width * 100).round();

  /// The segments' indices in the fewest rows whose [widths] fit [room], as
  /// even in count as can be, the longer rows first.
  static List<List<int>> _rows(List<double> widths, double room) {
    for (var count = 1; count < widths.length; count++) {
      final rows = _evenRows(widths.length, count);
      if (rows.every((row) => _spare(row, widths, room) >= 0)) return rows;
    }
    return _evenRows(widths.length, widths.length);
  }

  static List<List<int>> _evenRows(int length, int count) {
    final rows = <List<int>>[];
    var start = 0;
    for (var left = count; left > 0; left--) {
      final size = ((length - start) / left).ceil();
      rows.add([for (var i = start; i < start + size; i++) i]);
      start += size;
    }
    return rows;
  }
}

/// One segment of the filter, inked in while chosen, like Stats' "Islands |
/// All" switch.
class _Segment extends StatelessWidget {
  const _Segment(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const style = TextStyle(fontWeight: Weights.black, fontSize: HistoryHeaderLayout.segmentFont);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: Motion.tab,
            constraints: const BoxConstraints(minHeight: HistoryHeaderLayout.segmentHeight),
            color: selected ? Palette.ink : Palette.paper,
            padding: const EdgeInsets.symmetric(horizontal: HistoryHeaderLayout.segmentPadding),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: style.copyWith(color: selected ? Palette.paper : Palette.ink)),
            ),
          ),
        ),
      );
}

/// A run's panel: its tag (shrunk rather than cut when it is too long) and
/// date (under the tag when both don't fit on one line) over its "{n} cards · {m} misses" line, and its result
/// on the right.
class _RunPanel extends StatelessWidget {
  const _RunPanel({required this.tag, required this.at, required this.cards, required this.misses, required this.result});
  final String tag;
  final DateTime at;
  final int cards, misses;
  final Widget result;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      padding: HistoryLayout.rowPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: Gaps.panel,
                  runSpacing: Gaps.tight,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: InkTag(tag)),
                    Text(s.sessionDate(at),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryLayout.rowDateFont)),
                  ],
                ),
                const SizedBox(height: Gaps.tight),
                NumberedText(
                  s.historyLineTemplate,
                  [cards, misses],
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small),
                  numberStyle: const TextStyle(fontFamily: Fonts.display, fontWeight: Weights.black, fontSize: TypeScale.small),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gaps.panel),
          result,
        ],
      ),
    );
  }
}

/// A 札落とし session: its mode and deck, and its total time.
class _SessionRow extends StatelessWidget {
  const _SessionRow(this.session);
  final Session session;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final time = Progress.totalOf(session);
    final total = time != null
        ? formatRunTime(time)
        : session.completed
            ? missingTime
            : s.runEndedEarly;
    return _RunPanel(
      tag: runLabel(s, progress.configOf(session)),
      at: session.startedAt,
      cards: session.cardCount,
      misses: progress.missesIn(session.id),
      result: Text(total, style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryLayout.rowTimeFont, height: 1)),
    );
  }
}

/// A side-trip game: the trip, ranked or free at its level (or a custom
/// setup), its misses (cards not found with the first tap), and its score.
class _TripRow extends StatelessWidget {
  const _TripRow(this.run);
  final SideTripRun run;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final trip = SideTrip.values.asNameMap()[run.game];
    final level = run.level;
    final mode = switch ((run.ranked, level)) {
      (true, final int level) => s.sideTripRankedLevel(level),
      (true, null) => s.sideTripRanked,
      (false, final int level) => s.historyFreeLevel(level),
      (false, null) => '${s.freePlay} · ${s.deckCustom}',
    };
    return _RunPanel(
      tag: [?trip?.label, mode].join(' · '),
      at: run.startedAt,
      cards: run.cardCount,
      misses: ProgressScope.of(context).sideTrips.missesIn(run),
      result: NumberedText(
        s.historyScoreTemplate,
        [run.score],
        style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.small),
        numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryLayout.rowTimeFont, height: 1),
      ),
    );
  }
}
