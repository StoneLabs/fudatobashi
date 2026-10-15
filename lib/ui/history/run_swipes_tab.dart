import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/run_review.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../play/time_format.dart';
import 'history_widgets.dart';

/// A run page's Every swipe tab (D28): a row per card, under a header that
/// stays put: its number, kimariji, way up, time, usual time, the
/// difference and the time into the run.
class RunSwipesTab extends StatelessWidget {
  const RunSwipesTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = [for (final w in detail.swipes) if (!w.undone) w];
    final penalty = detail.run.penaltyMs;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.section, Gaps.gutter, 0),
        sliver: SliverToBoxAdapter(
          child: HistorySection(
            title: s.runSwipesTitle,
            sub: s.other.runSwipesTitle,
            note: s.runSwipesCount(rows.length),
            child: const SizedBox(),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
        sliver: SliverMainAxisGroup(slivers: [
          SliverPersistentHeader(pinned: true, delegate: _HeadDelegate(MediaQuery.textScalerOf(context))),
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final w = rows[i];
              final usual = detail.usualMs[ItemKey(w.poemId, w.inverted).id];
              final at = i + 1 < detail.timeline.ms.length ? detail.timeline.ms[i + 1] : null;
              return _Row(
                number: i + 1,
                swipe: w,
                usualMs: usual,
                atMs: at,
                penaltyMs: penalty,
                rule: (i + 1) % HistoryRunStyle.ruleEvery == 0,
              );
            },
          ),
        ]),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: Gaps.gutter)),
    ]);
  }
}

/// The table's columns, shared by the header and every row.
class _Cells extends StatelessWidget {
  const _Cells(this.cells, {this.style, this.colors = const {}});
  final List<String> cells;
  final TextStyle? style;

  /// Text colours of some cells, by column.
  final Map<int, Color> colors;

  static const _widths = [
    HistoryRunStyle.colNumber,
    null,
    HistoryRunStyle.colSide,
    HistoryRunStyle.colTime,
    HistoryRunStyle.colTime,
    HistoryRunStyle.colTime,
    HistoryRunStyle.colAt,
  ];

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final (i, text) in cells.indexed)
            if (_widths[i] case final w?)
              SizedBox(
                width: w * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.15),
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: i == 0 || i == 2 ? TextAlign.center : TextAlign.right,
                    style: style?.copyWith(color: colors[i])),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: Gaps.small),
                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                ),
              ),
        ],
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.number,
    required this.swipe,
    required this.usualMs,
    required this.atMs,
    required this.penaltyMs,
    required this.rule,
  });

  final int number;
  final RunSwipe swipe;
  final double? usualMs, atMs;
  final int penaltyMs;
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final w = swipe;
    final usual = usualMs;
    final diff = usual == null || w.miss ? null : w.ms - usual;
    final diffText = w.miss
        ? (penaltyMs > 0 ? '+${penaltyMs ~/ 1000}' : '')
        : diff == null
            ? missingTime
            : formatSignedSeconds(diff);
    final diffColor = diff == null ? Palette.ink : (diff > 0 ? HistoryRunStyle.behind : HistoryRunStyle.ahead);
    const base = TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small);
    return Container(
      constraints: const BoxConstraints(minHeight: HistoryRunStyle.rowHeight),
      decoration: BoxDecoration(
        color: w.miss ? HistoryRunStyle.missRow : null,
        border: Border(
          bottom: BorderSide(color: rule ? Palette.ink : ChartStyle.grid, width: rule ? Strokes.label : 1),
          left: const BorderSide(color: Palette.ink, width: Strokes.label),
          right: const BorderSide(color: Palette.ink, width: Strokes.label),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: _Cells([
        '$number',
        poems[w.poemId].kimariji,
        w.inverted ? '↓' : '↑',
        '${formatSeconds(w.ms)}${w.miss ? ' ×' : ''}',
        usual == null ? missingTime : formatSeconds(usual),
        diffText,
        atMs == null ? missingTime : formatTenths(Duration(milliseconds: atMs!.round())),
      ], style: base, colors: {if (!w.miss) 5: diffColor}),
    );
  }
}

class _HeadDelegate extends SliverPersistentHeaderDelegate {
  _HeadDelegate(this.scaler);
  final TextScaler scaler;

  double get _height => scaler.scale(HistoryRunStyle.rowHeight);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final s = S.of(context);
    return Container(
      color: HistoryRunStyle.headRow,
      alignment: Alignment.centerLeft,
      child: _Cells(
        ['#', s.colCard.toUpperCase(), '↕', s.colTime.toUpperCase(), s.colUsual.toUpperCase(), s.colDiff, s.colAt.toUpperCase()],
        style: const TextStyle(
            fontWeight: Weights.black,
            fontSize: HistoryRunStyle.labelFont,
            letterSpacing: HistoryRunStyle.labelTracking,
            color: Palette.paper),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeadDelegate old) => old.scaler != scaler;
}
