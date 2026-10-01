import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/trainer.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../torifuda/torifuda_painter.dart';
import 'card_detail_screen.dart';
import 'stats_charts.dart';

enum CardSort { order, slow, due }

/// How one card's row is styled and sorted: locked (never unlocked), fresh
/// (unlocked but never reviewed), due today, or upcoming/judged.
enum CardBadge { locked, fresh, dueToday, upcoming }

/// One card row's derived display data (median, sparkline tail, due state),
/// re-deriving the same locked/hollow/speed logic as the archipelago map
/// (`_ArchipelagoData` in `stats_screen.dart`), for one island or for every
/// card in the archipelago.
class CardRowData {
  const CardRowData({
    required this.poemId,
    required this.badge,
    required this.medianMs,
    required this.sparkline,
    required this.dueText,
    required this.dueSortKey,
  });

  final int poemId;
  final CardBadge badge;

  /// Median of the last 10 timed attempts, or null when locked or too few
  /// attempts to judge (`StatsTuning.mapHollowMinTries`).
  final double? medianMs;
  final List<double> sparkline;
  final String dueText;

  /// Null sorts last in "Due" order (locked or never reviewed).
  final DateTime? dueSortKey;

  static List<CardRowData> forIsland(Progress progress, IslandShape isl, S s, DateTime now) {
    final trainer = progress.trainer;
    return [for (final site in isl.sites) _forSite(progress, trainer, site.poemId, s, now)];
  }

  /// Every card of every island, in learning order — the Stats "All" tab.
  static List<CardRowData> forAll(Progress progress, S s, DateTime now) {
    final trainer = progress.trainer;
    return [
      for (final isl in archipelago.islands)
        for (final site in isl.sites) _forSite(progress, trainer, site.poemId, s, now),
    ];
  }

  static CardRowData _forSite(Progress progress, Trainer trainer, int poemId, S s, DateTime now) {
    final key = ItemKey(poemId, false);
    final state = trainer.items[key]!;
    if (!state.unlocked) {
      return CardRowData(
          poemId: poemId, badge: CardBadge.locked, medianMs: null, sparkline: const [], dueText: s.notLearnedYet, dueSortKey: null);
    }
    final stats = progress.stats(key);
    final hollow = stats.count < StatsTuning.mapHollowMinTries;
    final median = hollow ? null : stats.median(10);
    final tail = stats.timed.length <= CardDetailTuning.sparklineTail
        ? stats.timed
        : stats.timed.sublist(stats.timed.length - CardDetailTuning.sparklineTail);

    if (!state.reviewed) {
      return CardRowData(poemId: poemId, badge: CardBadge.fresh, medianMs: median, sparkline: tail, dueText: s.neverReviewed, dueSortKey: null);
    }
    if (trainer.isDue(key, now)) {
      return CardRowData(
          poemId: poemId, badge: CardBadge.dueToday, medianMs: median, sparkline: tail, dueText: s.dueTodayShort, dueSortKey: state.card.due);
    }
    final days = math.max(1, state.card.due.toLocal().difference(now).inDays);
    final dueText = days <= CardDetailTuning.dueSoonDays ? s.dueInDays(days) : s.shortDate(state.card.due);
    return CardRowData(poemId: poemId, badge: CardBadge.upcoming, medianMs: median, sparkline: tail, dueText: dueText, dueSortKey: state.card.due);
  }

  /// "Learning order" is the given order; the other two sort stably (an
  /// index tiebreak survives `List.sort` not being guaranteed stable), with
  /// locked/unseen cards always last.
  static List<CardRowData> sorted(List<CardRowData> rows, CardSort sort) {
    if (sort == CardSort.order) return rows;
    final indexed = [for (final (i, r) in rows.indexed) (i, r)];
    indexed.sort((a, b) {
      final (i, x) = a;
      final (j, y) = b;
      switch (sort) {
        case CardSort.order:
          return i.compareTo(j);
        case CardSort.slow:
          if (x.medianMs == null && y.medianMs == null) return i.compareTo(j);
          if (x.medianMs == null) return 1;
          if (y.medianMs == null) return -1;
          final c = y.medianMs!.compareTo(x.medianMs!);
          return c != 0 ? c : i.compareTo(j);
        case CardSort.due:
          if (x.dueSortKey == null && y.dueSortKey == null) return i.compareTo(j);
          if (x.dueSortKey == null) return 1;
          if (y.dueSortKey == null) return -1;
          final c = x.dueSortKey!.compareTo(y.dueSortKey!);
          return c != 0 ? c : i.compareTo(j);
      }
    });
    return [for (final (_, r) in indexed) r];
  }
}

/// The sort chips (spec's `.is-sort`) and scrollable card list shared by the
/// island page and the Stats "All" tab: tapping a row opens the card detail
/// screen.
class CardListView extends StatefulWidget {
  const CardListView({super.key, required this.rows});
  final List<CardRowData> rows;

  @override
  State<CardListView> createState() => _CardListViewState();
}

class _CardListViewState extends State<CardListView> {
  CardSort _sort = CardSort.order;

  @override
  Widget build(BuildContext context) {
    final sorted = CardRowData.sorted(widget.rows, _sort);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SortRow(sort: _sort, onChanged: (v) => setState(() => _sort = v)),
        const SizedBox(height: Gaps.panel),
        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gaps.panel),
            itemBuilder: (context, i) {
              final row = sorted[i];
              return CardTile(
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
    );
  }
}

/// The "Sort" pill row (spec's `.is-sort`): round-cornered, one at a time,
/// horizontally scrollable so it can never overflow at any locale/text scale.
class _SortRow extends StatelessWidget {
  const _SortRow({required this.sort, required this.onChanged});
  final CardSort sort;
  final ValueChanged<CardSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Text(s.sortLabel, style: const TextStyle(fontWeight: Weights.black, fontSize: IslandDetailLayout.sortButtonFont)),
        const SizedBox(width: Gaps.small),
        _SortChip(s.sortOrder, selected: sort == CardSort.order, onTap: () => onChanged(CardSort.order)),
        const SizedBox(width: Gaps.tight),
        _SortChip(s.sortSlow, selected: sort == CardSort.slow, onTap: () => onChanged(CardSort.slow)),
        const SizedBox(width: Gaps.tight),
        _SortChip(s.sortDue, selected: sort == CardSort.due, onTap: () => onChanged(CardSort.due)),
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

class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.data, required this.poem, required this.onTap});
  final CardRowData data;
  final Poem poem;
  final VoidCallback onTap;

  static Color _badgeColor(CardBadge b) => switch (b) {
        CardBadge.dueToday => Palette.pink,
        CardBadge.fresh => Palette.sun,
        CardBadge.locked || CardBadge.upcoming => Palette.paper,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locked = data.badge == CardBadge.locked;
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
                    Text(locked ? '？？？' : s.kimariji(poem.id),
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
