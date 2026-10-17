import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../tour/tour_anchor.dart';
import 'exam_strip.dart';
import 'home_screen.dart';
import 'journey_pan.dart';
import 'journey_state.dart';
import 'learn_ahead_button.dart';
import 'pause_sheet.dart';
import 'switch_banner.dart';
import 'today_box.dart';
import 'training_hero.dart';

/// Home in journey mode (spec phone 2): the archipelago map as the progress
/// bar, with the graduation exam as its last stop once it opens (or, once
/// it is passed, the offer of all-known mode), today's set, and the
/// Training hero. A new day's set is built when Home finds it missing; the
/// first time Home shows on a day with reviews piled up, it offers to pause
/// the new cards.
class JourneyHome extends StatefulWidget {
  const JourneyHome({super.key});

  @override
  State<JourneyHome> createState() => _JourneyHomeState();
}

class _JourneyHomeState extends State<JourneyHome> {
  bool _refreshing = false;
  bool _asking = false;

  void _watchToday(Progress progress) {
    if (progress.todayStale) {
      if (_refreshing) return;
      _refreshing = true;
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await progress.refreshToday();
        _refreshing = false;
      });
      return;
    }
    final shown = TickerMode.valuesOf(context).enabled && ModalRoute.isCurrentOf(context) != false;
    if (_asking || !shown || !progress.settings.toured || !progress.pauseOffered()) return;
    _asking = true;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await askToPauseNewCards(context);
      _asking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final s = S.of(context);
    final journey = JourneyState.of(progress);
    _watchToday(progress);
    final set = progress.todaySet();
    final bar = set?.bar;
    const number = TextStyle(fontFamily: Fonts.display, fontSize: NarrationStyle.number);
    final left = bar?.left ?? 0;
    final narration = set != null && set.done
        ? NumberedText(s.todayDoneExtra, [progress.trainer.config.sessionLength], numberStyle: number)
        : left == 0
            ? Text(s.caughtUp)
            : NumberedText(s.todayLeft, [left], numberStyle: number);
    final balloon = set != null && set.done
        ? s.heroKeepGoing
        : (bar?.done ?? 0) > 0
            ? s.heroKeepItUp
            : s.heroTodaySet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TourAnchor(
            TourSpot.map,
            child: _JourneyMap(
              journey,
              footer: progress.switchBannerShown
                  ? const SwitchBanner()
                  : progress.graduated || !progress.exam().open
                      ? null
                      : const TourAnchor(TourSpot.exam, child: ExamStrip()),
            ),
          ),
        ),
        const SizedBox(height: Gaps.journeyPanel),
        TourAnchor(TourSpot.islandPlan, child: TodayBox(set: set, week: progress.weekStamps())),
        const SizedBox(height: Gaps.journeyPanel),
        SizedBox(
          height: HomeLayout.journeyHeroHeight,
          child: TourAnchor(
            TourSpot.training,
            child: TrainingHero(
              size: HeroSize.compact,
              narration: narration,
              balloon: balloon,
              beside: progress.canLearnMore ? const LearnAheadButton() : null,
            ),
          ),
        ),
        const SizedBox(height: Gaps.section),
        const FreeAndGuestRow(),
      ],
    );
  }
}

/// The islands map, with [footer] along its bottom: the map runs on behind
/// it, and the boat and the current island stay in the part above. A drag
/// pans the map up and down; it stays where it is left until the boat moves.
class _JourneyMap extends StatelessWidget {
  const _JourneyMap(this.journey, {this.footer});
  final JourneyState journey;
  final Widget? footer;

  List<IslandStyle> _styles(S s) {
    final cur = journey.current;
    return [
      for (final isl in archipelago.islands)
        if (journey.done(isl.index))
          IslandStyle(
            flag: true,
            sites: {for (final site in isl.sites) site.poemId: journey.markOf(site.poemId)},
            plate: IslandPlate(name: isl.name, background: Palette.land, fontSize: MapStyle.plateFont),
          )
        else if (isl.index == cur)
          IslandStyle(
            pulse: true,
            sites: {for (final site in isl.sites) site.poemId: journey.markOf(site.poemId)},
            plate: IslandPlate(
              name: isl.name,
              background: Palette.pink,
              chip: '${journey.island.unlocked}/${journey.island.total}',
              emphasis: true,
            ),
          )
        else if (isl.index < cur)
          IslandStyle(sites: {
            for (final site in isl.sites)
              if (journey.unlocked.contains(site.poemId)) site.poemId: journey.markOf(site.poemId),
          })
        else
          IslandStyle(
            look: IslandLook.shoal,
            plate: isl.index - cur <= JourneyView.platesAhead
                ? IslandPlate(
                    name: isl.name,
                    dashed: true,
                    chip: isl.index == cur + 1 ? s.nextChip : '${isl.sites.length}',
                    chipBackground: isl.index == cur + 1 ? Palette.sun : Palette.paper,
                  )
                : null,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const count = TextStyle(fontFamily: Fonts.display, fontSize: HomeLayout.mapCountNumber);
    final footer = this.footer;
    final overhang = footer == null ? 0.0 : ExamStripStyle.mapOverhang;
    final labels = JourneyPan.labelsBottom(MediaQuery.textScalerOf(context));
    final map = LayoutBuilder(builder: (context, box) {
      final pan = JourneyPan(box: box.biggest, map: archipelago.size, labels: labels, overhang: overhang);
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: pan.frame,
            child: PanView(
              height: pan.height,
              offset: pan.offsetFor(JourneyPan.focuses(archipelago.islands[journey.current], journey.boat)),
              child: IslandMap(
                styles: _styles(s),
                viewport: pan.viewport,
                route: journey.route,
                boat: journey.boat,
                seaSeed: JourneyView.seaSeed,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: Backdrops.mapFogHeight,
            child: IgnorePointer(child: _Fog()),
          ),
          Positioned(
            left: HomeLayout.mapLabelInsets.left,
            top: HomeLayout.mapLabelInsets.top,
            child: InkBanner(s.journeyBanner, fontSize: HomeLayout.mapBannerFont),
          ),
          Positioned(
            left: HomeLayout.mapLabelInsets.left,
            top: HomeLayout.mapCountTop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.paper,
                border: Border.all(color: Palette.ink, width: Strokes.label),
              ),
              child: Padding(
                padding: HomeLayout.mapCountPadding,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: HomeLayout.mapCountFont, fontWeight: Weights.bold),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    NumberedText(s.islandOf, [journey.current + 1, journey.islands.length], numberStyle: count),
                    const Text(' · '),
                    NumberedText(s.cardsOf, [journey.cardsUnlocked, poems.all.length], numberStyle: count),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            right: HomeLayout.mapLabelInsets.right,
            top: HomeLayout.mapLabelInsets.top + Strokes.label,
            child: DashedBox(
              border: Strokes.label,
              padding: HomeLayout.mapMistPadding,
              child: Text(
                journey.islandsAhead == 0 ? s.allIslandsReached : s.islandsAhead(journey.islandsAhead),
                style: const TextStyle(fontSize: HomeLayout.mapMistFont, fontWeight: Weights.black),
              ),
            ),
          ),
        ],
      );
    });
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, HomeLayout.mapCut)),
      child: footer == null
          ? map
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: map), footer]),
    );
  }
}

class _Fog extends StatelessWidget {
  const _Fog();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [for (final a in Backdrops.mapFogAlpha) Palette.paper.withValues(alpha: a)],
            stops: Backdrops.mapFogStops,
          ),
        ),
      );
}
