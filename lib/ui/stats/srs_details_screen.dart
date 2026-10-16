import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../l10n/srs_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/stats_history.dart';
import '../history/history_widgets.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'card_detail_screen.dart';
import 'stats_page.dart';

/// The SRS page's advanced view, opened from its last button: every
/// card side's memory in one sortable table.
class SrsDetailsScreen extends StatelessWidget {
  const SrsDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return StatsPage(
      title: s.srsDetailsTitle,
      sub: s.other.srsDetailsTitle,
      body: SrsCardTable(ProgressScope.of(context)),
    );
  }
}

enum _Column { card, stability, difficulty, recall, next, lapses, time }

/// #34: every unlocked card side's memory in one table, sorted by the
/// heading tapped last (again to turn the order round); a row opens its
/// card.
class SrsCardTable extends StatefulWidget {
  const SrsCardTable(this.progress, {super.key});
  final Progress progress;

  @override
  State<SrsCardTable> createState() => _SrsCardTableState();
}

class _SrsCardTableState extends State<SrsCardTable> {
  var _sort = _Column.recall;
  var _ascending = true;

  static num? _keyOf(CardTableRow r, _Column c) => switch (c) {
        _Column.card => r.order * 2 + (r.key.inverted ? 1 : 0),
        _Column.stability => r.stability,
        _Column.difficulty => r.difficulty,
        _Column.recall => r.recall,
        _Column.next => r.due?.millisecondsSinceEpoch,
        _Column.lapses => r.lapses,
        _Column.time => r.medianMs,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = widget.progress.cardTable()
      ..sort((a, b) {
        final x = _keyOf(a, _sort), y = _keyOf(b, _sort);
        if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
        return _ascending ? x.compareTo(y) : y.compareTo(x);
      });
    final heads = {
      _Column.card: s.srsColCard,
      _Column.stability: s.srsColStab,
      _Column.difficulty: s.srsColDiff,
      _Column.recall: s.srsColRecall,
      _Column.next: s.srsColNext,
      _Column.lapses: s.srsColLapses,
      _Column.time: s.srsColTime,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.tight, Gaps.gutter, Gaps.gutter),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HistoryHeading(title: s.srsTableTitle, sub: s.sub?.srsTableTitle, note: s.srsTableSort),
        const SizedBox(height: Gaps.small),
        Expanded(
          child: Container(
            color: Palette.paper,
            foregroundDecoration: BoxDecoration(border: Border.all(width: Strokes.control)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ColoredBox(
                color: Palette.ink,
                child: Row(children: [
                  for (final c in _Column.values)
                    Expanded(
                      flex: SrsLayout.tableFlex[c.index],
                      child: Semantics(
                        button: true,
                        selected: c == _sort,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            _ascending = c == _sort ? !_ascending : true;
                            _sort = c;
                          }),
                          child: ColoredBox(
                            color: c == _sort ? Palette.pinkDeep : Palette.ink,
                            child: _Cell(
                              '${heads[c]}${c == _sort ? (_ascending ? SrsLayout.upArrow : SrsLayout.downArrow) : ''}',
                              style: SrsLayout.tableHeadStyle,
                              start: c == _Column.card,
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: rows.isEmpty
                    ? Padding(padding: SrsLayout.tableEmptyPadding, child: Text(s.srsNoData, style: RunTabsStyle.noteStyle))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _TableRow(rows[i], shaded: i.isOdd),
                      ),
              ),
            ]),
          ),
        ),
        HistoryCaption(s.srsTableKey(SrsTuning.typicalWindow)),
      ]),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.row, {required this.shaded});
  final CardTableRow row;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final low = row.recall != null && row.recall! < SrsTuning.lowRecall;
    final stability = switch (row.stability) {
      null => missingTime,
      final v => s.srsStabilityDays(formatStability(v)),
    };
    final values = [
      stability,
      row.difficulty?.toStringAsFixed(1) ?? missingTime,
      row.recall == null ? missingTime : '${(row.recall! * 100).round()}%',
      row.due == null ? missingTime : s.shortDate(row.due!),
      '${row.lapses}',
      row.medianMs == null ? missingTime : formatSeconds(row.medianMs!),
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => CardDetailScreen(itemKey: row.key))),
      child: Container(
        decoration: BoxDecoration(
          color: shaded ? SrsLayout.tableShade : Palette.paper,
          border: const Border(top: BorderSide(color: RunTabsStyle.rule)),
        ),
        child: Row(children: [
          Expanded(
            flex: SrsLayout.tableFlex[0],
            child: Padding(
              padding: SrsLayout.tableCellPadding,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(kimarijiFor(context, row.key.poemId), style: SrsLayout.tableCardStyle),
                  if (row.key.inverted) ...[
                    const SizedBox(width: Gaps.tight),
                    Container(
                      color: Palette.ink,
                      padding: SrsLayout.invertedTagPadding,
                      child: Text(s.srsInvertedTag, style: SrsLayout.invertedTagStyle),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          for (final (i, v) in values.indexed)
            Expanded(
              flex: SrsLayout.tableFlex[i + 1],
              child: _Cell(v,
                  style: i == 2 && low ? SrsLayout.tableCellStyle.copyWith(color: Palette.pinkDeep) : SrsLayout.tableCellStyle),
            ),
        ]),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.style, this.start = false});
  final String text;
  final TextStyle style;
  final bool start;

  @override
  Widget build(BuildContext context) => Padding(
        padding: SrsLayout.tableCellPadding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: start ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(text, maxLines: 1, style: style),
        ),
      );
}
