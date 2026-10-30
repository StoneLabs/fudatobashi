import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart' show ItemKey;
import '../../domain/trainer.dart' show LearningMode;
import '../../l10n/ranked_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../home/journey_state.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../rank/rank_screen.dart';
import '../run/run_launcher.dart';
import 'card_list.dart';
import 'island_screen.dart';
import 'srs_screen.dart';

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

  /// The island tapped on the map, if any (see [_IslandsView.picked]).
  int? _picked;

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
          MangaHeader(title: ScreenTitle(s.stats, sub: s.other.stats), actions: const [_HeaderLinks()]),
          Row(children: [
            Expanded(child: _Summary(overallMedianMs: data.overallMedianMs)),
            const SizedBox(width: Gaps.section),
            _TabToggle(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
          ]),
          const SizedBox(height: Gaps.section),
          Expanded(
            child: _tab == _Tab.islands
                ? _IslandsView(data: data, picked: _picked, onPick: (i) => setState(() => _picked = i))
                : _AllView(progress: progress),
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

/// The links in the header: the rank page in all-known mode; in journey
/// mode the SRS page, beside a locked rank link whose tap says why.
class _HeaderLinks extends StatelessWidget {
  const _HeaderLinks();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    void open(Widget page) => Navigator.push(context, MangaRoute<void>(builder: (_) => page));
    final journey = progress.trainer.config.learningMode == LearningMode.journey;
    return Container(
      height: StatsLayout.segHeight,
      decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.button)),
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (journey) ...[
          Builder(
            builder: (link) => _HeaderLink(
              s.rank,
              locked: true,
              onTap: () => BalloonPop.show(link, progress.graduated ? s.rankLockedSwitchBody : s.rankLockedTitle,
                  size: StatsLayout.rankLockedBalloon, life: StatsLayout.playButtonBalloonLife),
            ),
          ),
          const ColoredBox(color: Palette.ink, child: SizedBox(width: Strokes.button)),
          _HeaderLink(s.srs, onTap: () => open(const SrsScreen())),
        ] else
          _HeaderLink(s.rank, onTap: () => open(const RankScreen())),
      ]),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink(this.label, {required this.onTap, this.locked = false});
  final String label;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: label,
        drop: 0,
        scale: 1,
        turn: 0,
        builder: (context, pressed) => Stack(fit: StackFit.passthrough, children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: pressed ? Tones.stampOpacity : 0,
              duration: Motion.stampFade,
              child: const ToneBox(Tones.stamp),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StatsLayout.segPadding),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (locked) ...[
                MangaIcon(IconArt.lock, size: RankLayout.statsEntryIconSize),
                const SizedBox(width: Gaps.tight),
              ],
              Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.segFont)),
              const SizedBox(width: Gaps.tight),
              MangaIcon(IconArt.chevron, size: RankLayout.statsEntryIconSize),
            ]),
          ),
        ]),
      );
}

/// "100 cards · median X s".
class _Summary extends StatelessWidget {
  const _Summary({required this.overallMedianMs});
  final double? overallMedianMs;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final median = overallMedianMs == null ? '—' : formatChipSeconds(overallMedianMs!);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: NumberedText(
        s.summaryLine,
        [poems.all.length, median],
        style: const TextStyle(fontWeight: Weights.bold, fontSize: StatsLayout.summaryFont),
        numberStyle: const TextStyle(
            fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: StatsLayout.summaryNumberFont),
      ),
    );
  }
}

// --------------------------------------------------------------- Islands

/// One island's computed stats and its cards' marks on the map.
class _ArchipelagoIsland {
  const _ArchipelagoIsland({required this.index, required this.name, required this.medianMs, required this.sites});

  final int index;
  final String name;

  /// Median of this island's judged cards' own medians, or null when none
  /// yet qualify (see `StatsTuning.mapHollowMinTries`).
  final double? medianMs;
  final Map<int, SiteMark> sites;

  /// [medianMs] as its chip reads ("0.62s"); null, and no chip, until a
  /// card has enough tries.
  String? get speed => medianMs == null ? null : '${formatChipSeconds(medianMs!)}s';
}

class _ArchipelagoData {
  const _ArchipelagoData({required this.islands, required this.overallMedianMs});

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

  /// The map: island [selected] pulses on a pink plate, and the slowest
  /// island's chip carries a red mark.
  List<IslandStyle> styles(int selected) {
    final slowest = this.slowest?.index;
    return [
      for (final isl in islands)
        IslandStyle(
          sites: isl.sites,
          pulse: isl.index == selected,
          plate: IslandPlate(
            name: isl.name,
            chip: isl.speed,
            background: isl.index == selected ? Palette.pink : Palette.paper,
            emphasis: isl.index == selected,
            chipMark: isl.index == slowest ? Palette.alarm : null,
          ),
        ),
    ];
  }

  static _ArchipelagoData build(Progress progress) {
    final trainer = progress.trainer;
    final islands = <_ArchipelagoIsland>[];
    final allMedians = <double>[];

    for (final isl in archipelago.islands) {
      final sites = <int, SiteMark>{};
      final medians = <double>[];
      for (final site in isl.sites) {
        final key = ItemKey(site.poemId, false);
        if (!trainer.items[key]!.unlocked) {
          sites[site.poemId] = const SiteMark.dot(Palette.desk);
          continue;
        }
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
      islands.add(_ArchipelagoIsland(index: isl.index, name: isl.name, medianMs: _median(medians), sites: sites));
    }

    return _ArchipelagoData(islands: islands, overallMedianMs: _median(allMedians));
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

/// The map with Home's route and boat, the speed legend, and the selected
/// island's panel. Tapping an island selects it; tapping it again opens it.
class _IslandsView extends StatelessWidget {
  const _IslandsView({required this.data, required this.picked, required this.onPick});
  final _ArchipelagoData data;

  /// The island tapped last. Until one is, the slowest is selected, or
  /// before any island is judged, the journey's current one.
  final int? picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    // All-known mode has no journey: the whole route is sailed, and the boat
    // stays out of it.
    final journey =
        progress.trainer.config.learningMode == LearningMode.journey ? JourneyState.of(progress) : null;
    final slowest = data.slowest?.index;
    final selected = picked ?? slowest ?? journey?.current ?? 0;
    void openIsland(int i) => Navigator.push(context, MangaRoute<void>(builder: (_) => IslandScreen(islandIndex: i)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MangaPanel(
            shape:
                const PanelShape(topLeft: Offset(0, StatsLayout.mapCut), bottomRight: Offset(0, StatsLayout.mapCut)),
            child: IslandMap(
              styles: data.styles(selected),
              viewport: Offset.zero & archipelago.size,
              fit: BoxFit.contain,
              route: journey?.route ?? IslandRoute(archipelago.islands.length - 1),
              boat: journey?.boat,
              onIslandTap: (i) => i == selected ? openIsland(i) : onPick(i),
            ),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        const _Legend(),
        const SizedBox(height: Gaps.panel),
        _SelectedIslandPanel(
          island: data.islands[selected],
          slowest: selected == slowest,
          onDetails: () => openIsland(selected),
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

/// The island selected on the map: its name and speed, how many of its
/// cards are solid, and buttons to play it and open its page. Tobi and his
/// balloon keep a column of their own, clear of the text.
class _SelectedIslandPanel extends StatelessWidget {
  const _SelectedIslandPanel({required this.island, required this.slowest, required this.onDetails});
  final _ArchipelagoIsland island;

  /// The slowest island, noted in red beside the panel's tag.
  final bool slowest;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final islandProgress = progress.islands[island.index];
    final playable = progress.isIslandPlayable(islandProgress);
    const buttonFont = TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.playButtonFont);
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, StatsLayout.focusCut)),
      color: Palette.sunSoft,
      tone: Tones.sun,
      padding: StatsLayout.focusPadding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            // One tag's height, also when the slowest note makes the pair
            // shrink to fit.
            SizedBox(
              height: InkTag.heightOf(context),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  InkTag(s.selectedIslandTag),
                  if (slowest) ...[
                    const SizedBox(width: StatsLayout.focusTagGap),
                    InkTag('${MapStyle.chipMarkGlyph} ${s.slowestIslandNote}', color: Palette.alarm),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: StatsLayout.focusGap),
            // As tall as the name at full size, however much a long one
            // shrinks, so the panel keeps its height from island to island.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.textScalerOf(context).scale(StatsLayout.focusNameFont)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
                  child: island.speed == null
                      ? Text(s.legendFewTries(StatsTuning.mapHollowMinTries),
                          style: const TextStyle(fontWeight: Weights.black, fontSize: StatsLayout.focusFewTriesFont))
                      : Text(island.speed!,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: StatsLayout.focusSpeedFont)),
                ),
              ]),
            ),
            const SizedBox(height: StatsLayout.focusGap),
            NumberedText(
              s.islandSolidLine,
              [islandProgress.solid, islandProgress.total],
              style: const TextStyle(fontWeight: Weights.bold, fontSize: StatsLayout.focusLineFont),
              numberStyle: const TextStyle(
                  fontFamily: Fonts.display, fontWeight: Weights.black, fontSize: StatsLayout.focusLineFont),
            ),
            const SizedBox(height: StatsLayout.focusButtonGap),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: StatsLayout.playButtonHeight),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: InkButton(
                      color: playable ? Palette.pink : Palette.desk,
                      padding: StatsLayout.playButtonPadding,
                      semanticLabel: playable ? s.playThisIsland : s.playThisIslandLocked,
                      onTap: () => playable
                          ? startIslandPlay(context, islandProgress.index)
                          : BalloonPop.show(
                              context,
                              s.uncoverIslandToPlay(islandProgress.unlocked, islandProgress.total),
                              size: StatsLayout.playButtonBalloon,
                              life: StatsLayout.playButtonBalloonLife,
                            ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!playable) ...[
                            MangaIcon(IconArt.lock, size: StatsLayout.playButtonIcon),
                            const SizedBox(width: StatsLayout.playButtonIconGap),
                          ],
                          Text(s.playThisIsland, style: buttonFont),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: StatsLayout.detailsButtonGap),
                  InkButton(
                    padding: StatsLayout.detailsButtonPadding,
                    semanticLabel: s.islandDetails,
                    onTap: onDetails,
                    child: Text(s.islandDetails, style: buttonFont),
                  ),
                ]),
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
                child: BalloonText(s.tapAnIsland, style: const TextStyle(fontSize: StatsLayout.focusBalloonFont)),
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
