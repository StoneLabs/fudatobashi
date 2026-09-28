import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart' show ItemKey;
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../rank/rank_screen.dart';
import '../run/run_launcher.dart';
import 'card_list.dart';
import 'island_screen.dart';

enum _Tab { islands, all }

/// The Stats tab (spec phone 6): the archipelago, every card a dot in its
/// speed colour, or every card in one sortable list.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Tab _tab = _Tab.islands;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final data = _ArchipelagoData.build(progress);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(
            title: ScreenTitle(s.stats, sub: s.other.stats),
            actions: [
              _TabToggle(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
              const _RankButton(),
            ],
          ),
          _Summary(overallMedianMs: data.overallMedianMs, dueToday: progress.dueCount()),
          const SizedBox(height: Gaps.section),
          Expanded(
            child: _tab == _Tab.islands ? _IslandsView(data: data) : _AllView(progress: progress),
          ),
        ],
      ),
    );
  }
}

/// The "Islands | All" segmented switch (the same idea as `LanguageToggle`,
/// with square corners per the spec's `.seg`).
class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.tab, required this.onChanged});
  final _Tab tab;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      height: StatsLayout.segHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _SegButton(s.islandsTab, selected: tab == _Tab.islands, onTap: () => onChanged(_Tab.islands)),
        _SegButton(s.allTab, selected: tab == _Tab.all, onTap: () => onChanged(_Tab.all)),
      ]),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton(this.label, {required this.selected, required this.onTap});
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
            color: selected ? Palette.ink : Palette.paper,
            padding: const EdgeInsets.symmetric(horizontal: StatsLayout.segPadding),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: StatsLayout.segFont,
                    color: selected ? Palette.paper : Palette.ink)),
          ),
        ),
      );
}

/// The compact entry point to the rank ladder screen.
class _RankButton extends StatelessWidget {
  const _RankButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: StatsLayout.segHeight,
      child: InkButton(
        onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const RankScreen())),
        padding: const EdgeInsets.symmetric(horizontal: StatsLayout.segPadding),
        semanticLabel: s.rank,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.rank, style: const TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.segFont)),
          const SizedBox(width: Gaps.tight),
          const MangaIcon(IconArt.chevron, size: RankLayout.statsEntryIconSize),
        ]),
      ),
    );
  }
}

/// "100 cards · median X s · N due today".
class _Summary extends StatelessWidget {
  const _Summary({required this.overallMedianMs, required this.dueToday});
  final double? overallMedianMs;
  final int dueToday;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final median = overallMedianMs == null ? '—' : formatChipSeconds(overallMedianMs!);
    return NumberedText(
      s.summaryLine,
      [poems.all.length, median, dueToday],
      style: const TextStyle(fontWeight: Weights.bold, fontSize: StatsLayout.summaryFont),
      numberStyle: const TextStyle(
          fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: StatsLayout.summaryNumberFont),
    );
  }
}

// --------------------------------------------------------------- Islands

/// One island's computed stats, alongside the [IslandStyle] built for it.
class _ArchipelagoIsland {
  const _ArchipelagoIsland({
    required this.index,
    required this.name,
    required this.medianMs,
    required this.cardCount,
    required this.dueCount,
  });

  final int index;
  final String name;

  /// Median of this island's judged cards' own medians, or null when none
  /// yet qualify (see `StatsTuning.mapHollowMinTries`).
  final double? medianMs;
  final int cardCount;
  final int dueCount;
}

class _ArchipelagoData {
  const _ArchipelagoData({required this.styles, required this.islands, required this.overallMedianMs});

  final List<IslandStyle> styles;
  final List<_ArchipelagoIsland> islands;
  final double? overallMedianMs;

  /// The judged island with the worst (highest) median, if any.
  _ArchipelagoIsland? get slowest {
    _ArchipelagoIsland? worst;
    for (final isl in islands) {
      if (isl.medianMs == null) continue;
      if (worst == null || isl.medianMs! > worst.medianMs!) worst = isl;
    }
    return worst;
  }

  static _ArchipelagoData build(Progress progress) {
    final now = DateTime.now();
    final trainer = progress.trainer;
    final styles = <IslandStyle>[];
    final islands = <_ArchipelagoIsland>[];
    final allMedians = <double>[];

    for (final isl in archipelago.islands) {
      final sites = <int, SiteMark>{};
      final medians = <double>[];
      var due = 0;
      for (final site in isl.sites) {
        final key = ItemKey(site.poemId, false);
        if (!trainer.items[key]!.unlocked) {
          sites[site.poemId] = const SiteMark.dot(Palette.desk);
          continue;
        }
        if (trainer.isDue(key, now)) due++;
        final stats = progress.stats(key);
        // A card can rack up attempts that are all misses, leaving no timed
        // median even past the tries threshold; treat that the same as "too
        // few attempts to judge" rather than crash on a null median.
        final median = stats.count < StatsTuning.mapHollowMinTries ? null : stats.median(10);
        if (median == null) {
          sites[site.poemId] = const SiteMark.hollow();
          continue;
        }
        medians.add(median);
        allMedians.add(median);
        sites[site.poemId] = SiteMark.dot(Palette.tiers[SpeedTiers.of(median)]);
      }
      final islandMedian = _median(medians);
      styles.add(IslandStyle(
        sites: sites,
        plate: IslandPlate(
          name: isl.name,
          chip: islandMedian == null ? '—' : '${formatChipSeconds(islandMedian)}s',
        ),
      ));
      islands.add(_ArchipelagoIsland(
        index: isl.index,
        name: isl.name,
        medianMs: islandMedian,
        cardCount: isl.sites.length,
        dueCount: due,
      ));
    }

    return _ArchipelagoData(styles: styles, islands: islands, overallMedianMs: _median(allMedians));
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

class _IslandsView extends StatelessWidget {
  const _IslandsView({required this.data});
  final _ArchipelagoData data;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final slowest = data.slowest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MangaPanel(
            shape:
                const PanelShape(topLeft: Offset(0, StatsLayout.mapCut), bottomRight: Offset(0, StatsLayout.mapCut)),
            child: IslandMap(
              styles: data.styles,
              viewport: Offset.zero & archipelago.size,
              fit: BoxFit.contain,
              onIslandTap: (i) =>
                  Navigator.push(context, MangaRoute<void>(builder: (_) => IslandScreen(islandIndex: i))),
            ),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        const _Legend(),
        const SizedBox(height: Gaps.panel),
        if (slowest != null)
          _SlowestIslandPanel(island: slowest)
        else
          DashedBox(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(s.noIslandToPractise,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t0 = (SpeedTiers.upperMs[0] / 1000).toStringAsFixed(2);
    final t1 = (SpeedTiers.upperMs[1] / 1000).toStringAsFixed(2);
    final t2 = (SpeedTiers.upperMs[2] / 1000).toStringAsFixed(2);
    return SizedBox(
      height: StatsLayout.legendHeight,
      child: MangaPanel(
        padding: StatsLayout.legendPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.legendHeading,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: StatsLayout.legendHeadingFont,
                    letterSpacing: TagStyle.tracking * StatsLayout.legendHeadingFont)),
            const SizedBox(height: StatsLayout.legendRowGap),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(children: [
                _Swatch(color: Palette.tiers[0], label: s.legendUnder(t0)),
                const SizedBox(width: Gaps.section),
                _Swatch(color: Palette.tiers[1], label: s.legendRange(t0, t1)),
                const SizedBox(width: Gaps.section),
                _Swatch(color: Palette.tiers[2], label: s.legendRange(t1, t2)),
                const SizedBox(width: Gaps.section),
                _Swatch(color: Palette.tiers[3], label: s.legendOver(t2)),
                const SizedBox(width: Gaps.section),
                _Swatch(color: Palette.paper, label: s.legendFewTries(StatsTuning.mapHollowMinTries)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: StatsLayout.legendSwatch,
          height: StatsLayout.legendSwatch,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.ink, width: StatsLayout.legendSwatchBorder),
          ),
        ),
        const SizedBox(width: StatsLayout.legendItemGap),
        Text(label, softWrap: false, style: const TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.legendFont)),
      ]);
}

/// Tobi's pick of the slowest island, with a shortcut to play it. Tobi and
/// his balloon keep a column of their own, clear of the text.
class _SlowestIslandPanel extends StatelessWidget {
  const _SlowestIslandPanel({required this.island});
  final _ArchipelagoIsland island;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final islandProgress = progress.islands[island.index];
    final playable = progress.isIslandPlayable(islandProgress);
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, StatsLayout.focusCut)),
      color: Palette.sunSoft,
      tone: Tones.sun,
      padding: StatsLayout.focusPadding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: InkTag(s.slowestIslandTag)),
            const SizedBox(height: StatsLayout.focusGap),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(island.name,
                      style: const TextStyle(fontFamily: Fonts.display, fontSize: StatsLayout.focusNameFont, height: 1)),
                ),
              ),
              const SizedBox(width: Gaps.small),
              Container(
                padding: StatsLayout.focusSpeedPadding,
                decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: Strokes.control)),
                child: Text('${formatChipSeconds(island.medianMs!)}s',
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: StatsLayout.focusSpeedFont)),
              ),
            ]),
            const SizedBox(height: StatsLayout.focusGap),
            NumberedText(
              s.islandLineTemplate,
              [island.cardCount, island.dueCount],
              style: const TextStyle(fontWeight: Weights.bold, fontSize: StatsLayout.focusLineFont),
              numberStyle: const TextStyle(
                  fontFamily: Fonts.display, fontWeight: Weights.black, fontSize: StatsLayout.focusLineFont),
            ),
            const SizedBox(height: StatsLayout.focusButtonGap),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: StatsLayout.playButtonHeight),
              child: InkButton(
                color: playable ? Palette.pink : Palette.desk,
                padding: StatsLayout.playButtonPadding,
                semanticLabel: playable ? s.playThisIsland : s.playThisIslandLocked,
                onTap: () => playable
                    ? startIslandPlay(context, islandProgress.index)
                    : BalloonPop.show(context, s.uncoverIslandToPlay(islandProgress.unlocked, islandProgress.total),
                        size: StatsLayout.playButtonBalloon, life: StatsLayout.playButtonBalloonLife),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!playable) ...[
                      const MangaIcon(IconArt.lock, size: StatsLayout.playButtonIcon),
                      const SizedBox(width: StatsLayout.playButtonIconGap),
                    ],
                    Text(s.playThisIsland,
                        style: const TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.playButtonFont)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: Gaps.small),
        SizedBox(
          width: StatsLayout.focusBalloon.width,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox.fromSize(
              size: StatsLayout.focusBalloon,
              child: SpeechBalloon(
                speaker: StatsLayout.focusBalloonSpeaker,
                child: Text(s.tapAnIsland, style: const TextStyle(fontSize: StatsLayout.focusBalloonFont)),
              ),
            ),
            SizedBox.fromSize(size: StatsLayout.focusTobi, child: const Tobi(pose: TobiPose.pointing)),
          ]),
        ),
      ]),
    );
  }
}

// -------------------------------------------------------------------- All

class _AllView extends StatelessWidget {
  const _AllView({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return CardListView(rows: CardRowData.forAll(progress, s, DateTime.now()));
  }
}
