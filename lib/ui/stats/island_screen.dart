import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'card_list.dart';

/// One island, opened (spec phone 7): its own zoomed mini-map, a stat
/// summary, sort chips and the scrollable list of its cards.
class IslandScreen extends StatefulWidget {
  const IslandScreen({super.key, required this.islandIndex});

  final int islandIndex;

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final isl = archipelago.islands[widget.islandIndex];
    final rows = CardRowData.forIsland(progress, isl, s, DateTime.now());

    final judged = [for (final r in rows) if (r.medianMs != null) r];
    final islandMedian = _median([for (final r in judged) r.medianMs!]);
    final tierCounts = List<int>.filled(Palette.tiers.length, 0);
    for (final r in judged) {
      tierCounts[SpeedTiers.of(r.medianMs!)]++;
    }
    final dueCount = rows.where((r) => r.badge == CardBadge.dueToday).length;

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
              Expanded(child: CardListView(rows: rows)),
            ],
          ),
        ),
      ),
    );
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
  final List<CardRowData> rows;
  final double? islandMedian;
  final List<int> tierCounts;
  final int dueCount;

  static SiteMark _markFor(CardRowData r) {
    if (r.badge == CardBadge.locked) return const SiteMark.dot(Palette.desk);
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
