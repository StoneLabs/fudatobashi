import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_record.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../home/home_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import '../run/run_launcher.dart';
import 'burst_button.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';
import 'teiichi_guide.dart';
import 'teiichi_rules_sheet.dart';
import 'teiichi_sheet.dart';

/// Opens 定位置's page ([TeiichiPage]), once 定位置 is open.
Future<void> openTeiichiPage(BuildContext context) async {
  if (!ProgressScope.read(context).sideTripsHub()[SideTrip.teiichi].open) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const TeiichiPage()));
}

/// 定位置's page, the hub's panel opened up, on 暗記練's page's frame: ranked,
/// chained up until it comes; the guide's card, in full until the first
/// game and then a button; practice, its setup (the cards as the way to
/// the custom game sheet, [pickTeiichiCustom]), the best placing time and
/// the burst that starts it; Guest mode and the rules, each a sheet; and,
/// once enough games are saved, the cards slowest to place. The first
/// visit opens with the rules. Home's dotted ground, in the sea's blue,
/// lies behind the panels; the page scrolls when it is taller than the
/// screen.
class TeiichiPage extends StatefulWidget {
  const TeiichiPage({super.key});

  @override
  State<TeiichiPage> createState() => _TeiichiPageState();
}

class _TeiichiPageState extends State<TeiichiPage> {
  /// The setup picked from the custom game sheet, kept while the page is
  /// open; null for the usual game.
  TeiichiSetup? _picked;

  @override
  void initState() {
    super.initState();
    if (!ProgressScope.read(context).settings.teiichiRulesSeen) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) openTeiichiRules(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final entry = progress.sideTripsHub()[SideTrip.teiichi];
    final spotless = slowestToPlace(progress.sideTrips.teiichiPlacingTimes());
    const trip = SideTrip.teiichi;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.homeSea)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: CustomScrollView(slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: HeaderStyle.topGap),
                    MangaHeader(
                      title: ScreenTitle(s.tripName(trip), sub: s.tripTag(trip)),
                      actions: [
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    const _RankedPanel(),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    if (entry.games == 0) const _LearnCard() else const _LearnButton(),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    _PracticePanel(
                      entry,
                      picked: _picked,
                      onPick: (setup) => setState(() => _picked = setup == TeiichiSetup.usual ? null : setup),
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openTeiichiGuest(context))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openTeiichiRules(context))),
                    ]),
                    if (spotless.isNotEmpty) ...[
                      const SizedBox(height: AnkirenPageLayout.gap + AnkirenPageLayout.tagRise),
                      _SpotlessPanel(spotless),
                    ],
                    const Spacer(),
                    const SizedBox(height: AnkirenPageLayout.bottomGap),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Ranked, still to come: its one setup and the burst that will start it,
/// chained up, saying so.
class _RankedPanel extends StatelessWidget {
  const _RankedPanel();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LockedPanel(
      tag: s.ankirenRankedMode,
      sub: s.sub?.ankirenRankedMode,
      why: s.teiichiRankedSoon,
      child: Padding(
        padding: const EdgeInsets.only(top: TeiichiPageLayout.rankedTop),
        child: RankedRow(facts: s.teiichiRankedFacts(TeiichiTuning.cards), line: s.ankirenRankedReal, onTap: null),
      ),
    );
  }
}

/// The guide's card for a player new to 定位置: Tobi, its title and line,
/// the layout's three main points, and the way to the guide.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
      padding: TeiichiPageLayout.learnPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox.fromSize(size: TeiichiPageLayout.learnTobi, child: const Tobi(pose: TobiPose.pointing)),
          const SizedBox(width: TeiichiPageLayout.learnTobiGap),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                header: true,
                child: Text.rich(
                  Phrases.span(s.teiichiLearnTitle),
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: TeiichiPageLayout.learnTitleFont,
                      height: TypeScale.displayLineHeight),
                ),
              ),
              const SizedBox(height: TeiichiPageLayout.learnLineGap),
              Text.rich(
                Phrases.span(s.teiichiLearnLine),
                style: const TextStyle(
                    fontWeight: Weights.bold,
                    fontSize: TeiichiPageLayout.learnLineFont,
                    height: TeiichiPageLayout.learnLineHeight),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: TeiichiPageLayout.pointsTop),
        for (final (i, point) in s.teiichiLearnPoints.indexed) ...[
          if (i > 0) const SizedBox(height: TeiichiPageLayout.pointGap),
          Row(children: [
            _PointNumber(i + 1),
            const SizedBox(width: TeiichiPageLayout.pointTextGap),
            Expanded(
              child: Text.rich(Phrases.span(point),
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: TeiichiPageLayout.pointFont)),
            ),
          ]),
        ],
        const SizedBox(height: TeiichiPageLayout.buttonTop),
        Align(
          alignment: Alignment.centerRight,
          child: IntrinsicWidth(
            child: InkButton(
              onTap: () => openTeiichiGuide(context),
              color: Palette.sun,
              border: Strokes.control,
              padding: TeiichiPageLayout.buttonPadding,
              semanticLabel: s.teiichiLearnButton,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s.teiichiLearnButton,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: TeiichiPageLayout.buttonFont)),
                const SizedBox(width: TeiichiPageLayout.buttonIconGap),
                MangaIcon(IconArt.arrow, size: TeiichiPageLayout.buttonIcon),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A point's number on an ink disc.
class _PointNumber extends StatelessWidget {
  const _PointNumber(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: TeiichiPageLayout.pointNumber,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
          child: Center(
            child: Text('$n',
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: TeiichiPageLayout.pointNumberFont,
                    height: 1,
                    color: Palette.paper)),
          ),
        ),
      );
}

/// The guide, as one of Home's buttons once the player has games.
class _LearnButton extends StatelessWidget {
  const _LearnButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return HomeRowButton(
      icon: IconArt.cards,
      title: s.teiichiLearnTitle,
      sub: s.teiichiLearnSub,
      onTap: () => openTeiichiGuide(context),
    );
  }
}

/// Practice: the usual game, or the setup [picked] instead: the cards as
/// the button to the custom game sheet, the rows and the best placing time
/// across the panel, then the burst that starts it. A setup confirmed in
/// the sheet goes to [onPick].
class _PracticePanel extends StatelessWidget {
  const _PracticePanel(this.entry, {required this.picked, required this.onPick});

  final SideTripEntry entry;
  final TeiichiSetup? picked;
  final ValueChanged<TeiichiSetup> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = picked ?? TeiichiSetup.usual;
    final best = entry.placing.best;
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    String play(S s) => s.teiichiPlay(setup.cards);
    Future<void> pick() async {
      final chosen = await pickTeiichiCustom(context, setup);
      if (chosen != null && context.mounted) onPick(chosen);
    }

    return TaggedPanel(
      tag: s.teiichiPractice,
      sub: s.sub?.teiichiPractice,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: AnkirenPageLayout.statsPadding,
          child: CellRow(firstRuled: false, fills: true, children: [
            DropCellButton(
              onTap: pick,
              semanticLabel: s.teiichiAllCards,
              label: PanelLabel(s.ankirenCards, null),
              value: Text('${setup.cards}', style: big),
            ),
            StatCell(
              inset: AnkirenPageLayout.levelButtonInset,
              label: PanelLabel(s.teiichiRows, null),
              value: Text('${setup.rows}', style: big),
            ),
            StatCell(
              inset: AnkirenPageLayout.levelButtonInset,
              label: PanelLabel(s.teiichiBestPlacing, null),
              value: Text(best == null ? missingTime : formatMinutes(best), style: big),
            ),
          ]),
        ),
        Padding(
          padding: AnkirenPageLayout.burstMargin,
          child: BurstButton(
            title: play(s),
            sub: s.sub == null ? null : play(s.sub!).toUpperCase(),
            onTap: () => startTeiichi(context, setup),
          ),
        ),
      ]),
    );
  }
}

/// The cards slowest to place lately, with their mean placing times, and
/// what to do about them.
class _SpotlessPanel extends StatelessWidget {
  const _SpotlessPanel(this.cards);

  final List<SlowPlacing> cards;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TaggedPanel(
      tag: s.teiichiSpotless,
      sub: s.sub?.teiichiSpotless,
      child: Padding(
        padding: TeiichiPageLayout.spotlessPadding,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SummaryCards([
            for (final c in cards) SummaryCard(c.poemId, ms: c.mean.inMicroseconds / Duration.microsecondsPerMillisecond),
          ]),
          const SizedBox(height: TeiichiPageLayout.spotlessNoteGap),
          Text.rich(
            Phrases.span(s.teiichiSpotlessNote(TeiichiTuning.spotlessRecentGames)),
            style: const TextStyle(fontWeight: Weights.bold, fontSize: TeiichiPageLayout.spotlessNoteFont),
          ),
        ]),
      ),
    );
  }
}
