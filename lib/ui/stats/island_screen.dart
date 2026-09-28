import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/trainer.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../torifuda/torifuda_painter.dart';
import 'card_detail_screen.dart';
import 'stats_charts.dart';

enum _Sort { order, slow, due }

/// How one card's row is styled and sorted: locked (never unlocked), fresh
/// (unlocked but never reviewed), due today, or upcoming/judged.
enum _Badge { locked, fresh, dueToday, upcoming }

/// One island, opened (spec phone 7): its own zoomed mini-map, a stat
/// summary, sort chips and the scrollable list of its cards.
class IslandScreen extends StatefulWidget {
  const IslandScreen({super.key, required this.islandIndex});

  final int islandIndex;

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen> {
  _Sort _sort = _Sort.order;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final isl = archipelago.islands[widget.islandIndex];
    final rows = _CardRow.build(progress, isl, s, DateTime.now());
    final sorted = _sorted(rows, _sort);

    final judged = [for (final r in rows) if (r.medianMs != null) r];
    final islandMedian = _median([for (final r in judged) r.medianMs!]);
    final tierCounts = List<int>.filled(Palette.tiers.length, 0);
    for (final r in judged) {
      tierCounts[SpeedTiers.of(r.medianMs!)]++;
    }
    final dueCount = rows.where((r) => r.badge == _Badge.dueToday).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              _TopBar(name: isl.name, islandNumber: widget.islandIndex + 1, cardCount: isl.sites.length),
              const SizedBox(height: Gaps.section),
              _Hero(
                islandIndex: widget.islandIndex,
                rows: rows,
                islandMedian: islandMedian,
                tierCounts: tierCounts,
                dueCount: dueCount,
              ),
              const SizedBox(height: Gaps.section),
              _SortRow(sort: _sort, onChanged: (v) => setState(() => _sort = v)),
              const SizedBox(height: Gaps.panel),
              Expanded(
                child: ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gaps.panel),
                  itemBuilder: (context, i) {
                    final row = sorted[i];
                    return _CardTile(
                      data: row,
                      poem: poems[row.poemId],
                      onTap: () => Navigator.push(
                        context,
                        MangaRoute<void>(builder: (_) => CardDetailScreen(itemKey: ItemKey(row.poemId, false))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Learning order" is the island's own site order; the other two sort
  /// stably (an index tiebreak survives `List.sort` not being guaranteed
  /// stable), with locked/unseen cards always last.
  static List<_CardRow> _sorted(List<_CardRow> rows, _Sort sort) {
    if (sort == _Sort.order) return rows;
    final indexed = [for (final (i, r) in rows.indexed) (i, r)];
    indexed.sort((a, b) {
      final (i, x) = a;
      final (j, y) = b;
      switch (sort) {
        case _Sort.order:
          return i.compareTo(j);
        case _Sort.slow:
          if (x.medianMs == null && y.medianMs == null) return i.compareTo(j);
          if (x.medianMs == null) return 1;
          if (y.medianMs == null) return -1;
          final c = y.medianMs!.compareTo(x.medianMs!);
          return c != 0 ? c : i.compareTo(j);
        case _Sort.due:
          if (x.dueSortKey == null && y.dueSortKey == null) return i.compareTo(j);
          if (x.dueSortKey == null) return 1;
          if (y.dueSortKey == null) return -1;
          final c = x.dueSortKey!.compareTo(y.dueSortKey!);
          return c != 0 ? c : i.compareTo(j);
      }
    });
    return [for (final (_, r) in indexed) r];
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name, required this.islandNumber, required this.cardCount});
  final String name;
  final int islandNumber;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: Gaps.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: IslandDetailLayout.titleFont, height: 1)),
                const SizedBox(height: 2),
                Text(s.islandSubtitle(islandNumber, cardCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: Weights.black,
                        fontSize: IslandDetailLayout.subFont,
                        letterSpacing: TagStyle.tracking * IslandDetailLayout.subFont)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.islandIndex,
    required this.rows,
    required this.islandMedian,
    required this.tierCounts,
    required this.dueCount,
  });

  final int islandIndex;
  final List<_CardRow> rows;
  final double? islandMedian;
  final List<int> tierCounts;
  final int dueCount;

  static SiteMark _markFor(_CardRow r) {
    if (r.badge == _Badge.locked) return const SiteMark.dot(Palette.desk);
    if (r.medianMs == null) return const SiteMark.hollow();
    return SiteMark.dot(Palette.tiers[SpeedTiers.of(r.medianMs!)]);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isl = archipelago.islands[islandIndex];
    return SizedBox(
      height: IslandDetailLayout.heroHeight,
      child: MangaPanel(
        shape: const PanelShape(bottomRight: Offset(0, IslandDetailLayout.heroCut)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: IslandDetailLayout.mapWidth,
              child: IslandMap(
                styles: [
                  for (final other in archipelago.islands)
                    if (other.index == islandIndex)
                      IslandStyle(sites: {for (final r in rows) r.poemId: _markFor(r)})
                    else
                      const IslandStyle(look: IslandLook.shoal),
                ],
                viewport: isl.bounds.inflate(IslandDetailLayout.heroMapMargin),
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Palette.paper,
                  border: Border(left: BorderSide(color: Palette.ink, width: Strokes.control)),
                ),
                padding: IslandDetailLayout.summaryPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.islandMedianLabel,
                        style: const TextStyle(
                            fontWeight: Weights.black,
                            fontSize: IslandDetailLayout.summaryLabelFont,
                            letterSpacing: TagStyle.tracking * IslandDetailLayout.summaryLabelFont)),
                    const SizedBox(height: 3),
                    Container(
                      padding: IslandDetailLayout.summaryAvgPadding,
                      decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: Strokes.control)),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: islandMedian == null ? '—' : formatChipSeconds(islandMedian!),
                            style: const TextStyle(fontFamily: Fonts.display, fontSize: IslandDetailLayout.summaryAvgFont)),
                        if (islandMedian != null)
                          const TextSpan(
                              text: ' s', style: TextStyle(fontFamily: Fonts.ui, fontSize: IslandDetailLayout.summaryAvgUnitFont)),
                      ])),
                    ),
                    const SizedBox(height: Gaps.small),
                    if (tierCounts.any((c) => c > 0))
                      SizedBox(
                        height: IslandDetailLayout.distHeight,
                        child: Row(children: [
                          for (final (i, c) in tierCounts.indexed)
                            if (c > 0)
                              Expanded(
                                flex: c,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Palette.tiers[i],
                                    border: Border.all(color: Palette.ink, width: IslandDetailLayout.distBorder),
                                  ),
                                ),
                              ),
                        ]),
                      ),
                    const SizedBox(height: Gaps.tight),
                    NumberedText(
                      s.dueTodayLine,
                      [dueCount],
                      style: const TextStyle(fontWeight: Weights.bold, fontSize: IslandDetailLayout.dueLineFont),
                      numberStyle: const TextStyle(
                          fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: IslandDetailLayout.dueLineFont),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Sort" pill row (spec's `.is-sort`): round-cornered, one at a time,
/// horizontally scrollable so it can never overflow at any locale/text scale.
class _SortRow extends StatelessWidget {
  const _SortRow({required this.sort, required this.onChanged});
  final _Sort sort;
  final ValueChanged<_Sort> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Text(s.sortLabel, style: const TextStyle(fontWeight: Weights.black, fontSize: IslandDetailLayout.sortButtonFont)),
        const SizedBox(width: Gaps.small),
        _SortChip(s.sortOrder, selected: sort == _Sort.order, onTap: () => onChanged(_Sort.order)),
        const SizedBox(width: Gaps.tight),
        _SortChip(s.sortSlow, selected: sort == _Sort.slow, onTap: () => onChanged(_Sort.slow)),
        const SizedBox(width: Gaps.tight),
        _SortChip(s.sortDue, selected: sort == _Sort.due, onTap: () => onChanged(_Sort.due)),
      ]),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(this.label, {required this.selected, required this.onTap});
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
            padding: IslandDetailLayout.sortButtonPadding,
            decoration: BoxDecoration(
              color: selected ? Palette.ink : Palette.paper,
              border: Border.all(color: Palette.ink, width: Strokes.control),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label,
                softWrap: false,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: IslandDetailLayout.sortButtonFont,
                    color: selected ? Palette.paper : Palette.ink)),
          ),
        ),
      );
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.data, required this.poem, required this.onTap});
  final _CardRow data;
  final Poem poem;
  final VoidCallback onTap;

  static Color _badgeColor(_Badge b) => switch (b) {
        _Badge.dueToday => Palette.pink,
        _Badge.fresh => Palette.sun,
        _Badge.locked || _Badge.upcoming => Palette.paper,
      };

  @override
  Widget build(BuildContext context) {
    final locked = data.badge == _Badge.locked;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MangaPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          height: IslandDetailLayout.rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: IslandDetailLayout.rowImageWidth, child: TorifudaCard(poem: poem, showText: !locked)),
              const SizedBox(width: Gaps.section),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(locked ? '？？？' : poem.kimariji,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: IslandDetailLayout.rowKimarijiFont, height: 1)),
                    const SizedBox(height: Gaps.tight),
                    Container(
                      padding: IslandDetailLayout.rowDuePadding,
                      decoration: BoxDecoration(
                          color: _badgeColor(data.badge), border: Border.all(color: Palette.ink, width: Strokes.label)),
                      child: Text(data.dueText,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontWeight: Weights.black, fontSize: IslandDetailLayout.rowDueFont)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gaps.small),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: IslandDetailLayout.rowSpeedPadding,
                    decoration: BoxDecoration(
                      color: data.medianMs == null ? Palette.paper : Palette.tiers[SpeedTiers.of(data.medianMs!)],
                      border: Border.all(color: Palette.ink, width: Strokes.control),
                    ),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: data.medianMs == null ? '—' : formatChipSeconds(data.medianMs!),
                          style: TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: IslandDetailLayout.rowSpeedFont,
                              color: data.medianMs == null ? Palette.ink : Palette.tierText[SpeedTiers.of(data.medianMs!)])),
                      if (data.medianMs != null)
                        TextSpan(
                            text: 's',
                            style: TextStyle(
                                fontFamily: Fonts.ui,
                                fontSize: IslandDetailLayout.rowSpeedSmallFont,
                                color: Palette.tierText[SpeedTiers.of(data.medianMs!)])),
                    ])),
                  ),
                  const SizedBox(height: Gaps.tight),
                  Sparkline(
                      valuesMs: data.sparkline,
                      color: data.medianMs == null ? Palette.desk : Palette.tiers[SpeedTiers.of(data.medianMs!)]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One island card row's derived display data (median, sparkline tail, due
/// state), re-deriving the same locked/hollow/speed logic as the archipelago
/// map (`_ArchipelagoData` in `stats_screen.dart`) for just this island.
class _CardRow {
  const _CardRow({
    required this.poemId,
    required this.badge,
    required this.medianMs,
    required this.sparkline,
    required this.dueText,
    required this.dueSortKey,
  });

  final int poemId;
  final _Badge badge;

  /// Median of the last 10 timed attempts, or null when locked or too few
  /// attempts to judge (`StatsTuning.mapHollowMinTries`).
  final double? medianMs;
  final List<double> sparkline;
  final String dueText;

  /// Null sorts last in "Due" order (locked or never reviewed).
  final DateTime? dueSortKey;

  static List<_CardRow> build(Progress progress, IslandShape isl, S s, DateTime now) {
    final trainer = progress.trainer;
    return [for (final site in isl.sites) _forSite(progress, trainer, site.poemId, s, now)];
  }

  static _CardRow _forSite(Progress progress, Trainer trainer, int poemId, S s, DateTime now) {
    final key = ItemKey(poemId, false);
    final state = trainer.items[key]!;
    if (!state.unlocked) {
      return _CardRow(
          poemId: poemId, badge: _Badge.locked, medianMs: null, sparkline: const [], dueText: s.notLearnedYet, dueSortKey: null);
    }
    final stats = progress.stats(key);
    final hollow = stats.count < StatsTuning.mapHollowMinTries;
    final median = hollow ? null : stats.median(10);
    final tail = stats.timed.length <= CardDetailTuning.sparklineTail
        ? stats.timed
        : stats.timed.sublist(stats.timed.length - CardDetailTuning.sparklineTail);

    if (!state.reviewed) {
      return _CardRow(poemId: poemId, badge: _Badge.fresh, medianMs: median, sparkline: tail, dueText: s.neverReviewed, dueSortKey: null);
    }
    if (trainer.isDue(key, now)) {
      return _CardRow(
          poemId: poemId, badge: _Badge.dueToday, medianMs: median, sparkline: tail, dueText: s.dueTodayShort, dueSortKey: state.card.due);
    }
    final days = math.max(1, state.card.due.toLocal().difference(now).inDays);
    final dueText = days <= CardDetailTuning.dueSoonDays ? s.dueInDays(days) : s.shortDate(state.card.due);
    return _CardRow(poemId: poemId, badge: _Badge.upcoming, medianMs: median, sparkline: tail, dueText: dueText, dueSortKey: state.card.due);
  }
}
