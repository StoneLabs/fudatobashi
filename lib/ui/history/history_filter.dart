import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../db/database.dart' show SideTripRun;
import '../../l10n/history_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../manga/manga.dart';
import 'history_widgets.dart';

/// How far back the History list goes.
enum HistoryWhen {
  today(1),
  week(7),
  month(30),
  all(null);

  const HistoryWhen(this.days);

  /// Practice days shown, today included; null for all.
  final int? days;

  String label(S s) => switch (this) {
        today => s.filterToday,
        week => s.filterWeek,
        month => s.filterMonth,
        all => s.filterAll,
      };
}

/// A 暗記練 game's kind, for the filter.
enum AnkirenKind {
  ranked,
  free,
  custom;

  static AnkirenKind of(SideTripRun run) => run.ranked
      ? ranked
      : run.level == null
          ? custom
          : free;

  String label(S s) => switch (this) {
        ranked => s.filterAnkirenRanked,
        free => s.filterAnkirenFree,
        custom => s.historyAnkirenCustom,
      };
}

/// The main game's run kinds the filter offers.
const historyModes = [PlayMode.training, PlayMode.free, PlayMode.nigate, PlayMode.ranked, PlayMode.exam];

/// History's filter: which kinds on each tab (none picked = every kind) and
/// how far back.
@immutable
class HistoryFilter {
  const HistoryFilter({this.modes = const {}, this.games = const {}, this.when = HistoryWhen.all});

  final Set<PlayMode> modes;
  final Set<AnkirenKind> games;
  final HistoryWhen when;

  /// Choices made on tab [ankiren] (the main game's otherwise), for the
  /// filter button's count.
  int activeOn({required bool ankiren}) => (ankiren ? games.length : modes.length) + (when == HistoryWhen.all ? 0 : 1);

  bool _recent(DateTime day, DateTime today) => when.days == null || today.difference(day).inDays < when.days!;

  bool keepsRun(PastRun run, DateTime day, DateTime today) =>
      (modes.isEmpty || modes.contains(run.mode)) && _recent(day, today);

  bool keepsGame(SideTripRun run, DateTime day, DateTime today) =>
      (games.isEmpty || games.contains(AnkirenKind.of(run))) && _recent(day, today);

  HistoryFilter copyWith({Set<PlayMode>? modes, Set<AnkirenKind>? games, HistoryWhen? when}) =>
      HistoryFilter(modes: modes ?? this.modes, games: games ?? this.games, when: when ?? this.when);
}

/// The filter sheet (D43): the kinds of the tab on show, and when. It
/// returns the filter picked, or null when closed without showing.
Future<HistoryFilter?> showHistoryFilter(
  BuildContext context, {
  required HistoryFilter filter,
  required bool ankiren,
  required int Function(HistoryFilter filter) count,
}) =>
    showMangaSheet<HistoryFilter>(
      context,
      barrierColor: HistoryFilterStyle.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => _FilterSheet(filter: filter, ankiren: ankiren, count: count),
    );

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter, required this.ankiren, required this.count});
  final HistoryFilter filter;
  final bool ankiren;
  final int Function(HistoryFilter filter) count;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late HistoryFilter _filter = widget.filter;

  Set<T> _toggled<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final n = widget.count(_filter);
    Widget heading(String text, String? sub, [String? note]) => Padding(
          padding: const EdgeInsets.only(top: Gaps.section, bottom: Gaps.small),
          child: Row(children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: text, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body)),
                if (sub != null)
                  TextSpan(text: '  $sub', style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.subFont)),
              ])),
            ),
            if (note != null) Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont)),
          ]),
        );
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: MangaPanel(
            padding: HistoryFilterStyle.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: ScreenTitle(s.filterTitle, sub: s.other.filterTitle)),
                  GestureDetector(
                    onTap: () => setState(() => _filter = const HistoryFilter()),
                    child: Padding(
                      padding: const EdgeInsets.all(Gaps.small),
                      child: Text(s.filterReset,
                          style: const TextStyle(
                              fontWeight: Weights.black, fontSize: TypeScale.body, decoration: TextDecoration.underline)),
                    ),
                  ),
                  InkIconButton(icon: IconArt.close, semanticLabel: s.cancel, onTap: () => Navigator.pop(context)),
                ]),
                heading(s.filterKind, s.sub?.filterKind, widget.ankiren ? s.filterAnkirenNote : s.filterMainNote),
                Wrap(
                  spacing: Gaps.small,
                  runSpacing: Gaps.small,
                  children: widget.ankiren
                      ? [
                          for (final k in AnkirenKind.values)
                            FilterChipBox(k.label(s),
                                selected: _filter.games.contains(k),
                                onTap: () => setState(() => _filter = _filter.copyWith(games: _toggled(_filter.games, k)))),
                        ]
                      : [
                          for (final m in historyModes)
                            FilterChipBox(runKindLabel(s, m),
                                selected: _filter.modes.contains(m),
                                onTap: () => setState(() => _filter = _filter.copyWith(modes: _toggled(_filter.modes, m)))),
                        ],
                ),
                heading(s.filterWhen, s.sub?.filterWhen),
                Row(children: [
                  for (final w in HistoryWhen.values)
                    Expanded(
                      child: FilterChipBox(w.label(s),
                          selected: _filter.when == w, onTap: () => setState(() => _filter = _filter.copyWith(when: w))),
                    ),
                ]),
                const SizedBox(height: Gaps.section),
                SizedBox(
                  height: HistoryFilterStyle.showHeight,
                  child: ShoutButton(
                    label: n == 1 ? s.filterShowOne : s.filterShow(n),
                    arrow: false,
                    onTap: () => Navigator.pop(context, _filter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A choice in the filter sheet: an ink-bordered box, solid ink when
/// picked.
class FilterChipBox extends StatelessWidget {
  const FilterChipBox(this.label, {super.key, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.tab,
            constraints: const BoxConstraints(minHeight: HistoryFilterStyle.chipHeight),
            padding: HistoryFilterStyle.chipPadding,
            decoration: BoxDecoration(
              color: selected ? Palette.ink : Palette.paper,
              border: Border.all(color: Palette.ink, width: Strokes.label),
            ),
            child: Align(
              widthFactor: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                  maxLines: 1,
                  style: TextStyle(
                      fontWeight: Weights.black,
                      fontSize: TypeScale.label,
                        color: selected ? Palette.paper : Palette.ink)),
              ),
            ),
          ),
        ),
      );
}
