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
/// text), narrowed by a filter row. Opening a run for detail is a later task.
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
          const SizedBox(height: Gaps.section),
          Wrap(
            spacing: HistoryLayout.filterGap,
            runSpacing: HistoryLayout.filterGap,
            children: [
              for (final filter in _Filter.values)
                _FilterChip(
                  filter.label(s),
                  selected: filter == _filter,
                  onTap: () => setState(() => _filter = filter),
                ),
            ],
          ),
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
}

class _SessionEntry extends _Entry {
  const _SessionEntry(this.session, this.mode);
  final Session session;
  final PlayMode mode;

  @override
  DateTime get startedAt => session.startedAt;
}

class _TripEntry extends _Entry {
  const _TripEntry(this.run);
  final SideTripRun run;

  @override
  DateTime get startedAt => run.startedAt;
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

/// One filter of the row, sun-lit while chosen (like Settings' choices).
class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: HistoryLayout.filterHeight),
            child: InkButton(
              color: selected ? Palette.sun : Palette.paper,
              onTap: selected ? null : onTap,
              padding: HistoryLayout.filterPadding,
              child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryLayout.filterFont)),
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
