import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
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
/// chained up until it comes, and the guide's card at the top; at the foot,
/// within the thumb's reach, Guest mode and the rules, each a sheet, over
/// practice: its setup (the cards as the way to the custom game sheet,
/// [pickTeiichiCustom]), the best placing time and the burst that starts
/// it. The first visit opens with the rules. Home's dotted ground, in the
/// sea's blue, lies behind the panels. A taller screen's room to spare goes
/// to ranked and the guide's card ([_GrowColumn]); the page scrolls when
/// it is taller than the screen.
class TeiichiPage extends StatefulWidget {
  const TeiichiPage({super.key});

  @override
  State<TeiichiPage> createState() => _TeiichiPageState();
}

class _TeiichiPageState extends State<TeiichiPage> {
  /// The custom setup, the last one picked in the custom game sheet (kept
  /// in the settings), fitted to the cards known; null for the usual game.
  TeiichiSetup? _picked;

  @override
  void initState() {
    super.initState();
    final progress = ProgressScope.read(context);
    final settings = progress.settings;
    final saved = TeiichiSetup(cards: settings.teiichiCards, rows: settings.teiichiRows);
    if (saved.custom) {
      final fitted = saved.fitted(progress.knownCards.length);
      _picked = fitted.custom ? fitted : null;
    }
    if (!settings.teiichiRulesSeen) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) openTeiichiRules(context);
      });
    }
  }

  void _pick(TeiichiSetup setup) {
    setState(() => _picked = setup.custom ? setup : null);
    final progress = ProgressScope.read(context);
    unawaited(progress.updateSettings(progress.settings.copyWith(teiichiCards: setup.cards, teiichiRows: setup.rows)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final entry = progress.sideTripsHub()[SideTrip.teiichi];
    const trip = SideTrip.teiichi;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.homeSea)),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, screen) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screen.maxHeight),
                child: _GrowColumn(
                  children: [
                    const SizedBox(height: HeaderStyle.topGap),
                    MangaHeader(
                      title: ScreenTitle(s.tripName(trip), sub: s.tripTag(trip)),
                      actions: [
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    const _Grows(share: TeiichiPageLayout.rankedShare, child: _RankedPanel()),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    const _Grows(share: TeiichiPageLayout.learnShare, child: _LearnCard()),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openTeiichiGuest(context))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openTeiichiRules(context))),
                    ]),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    _PracticePanel(
                      entry,
                      picked: _picked,
                      onPick: _pick,
                    ),
                    const SizedBox(height: AnkirenPageLayout.bottomGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Ranked, still to come: its one setup and the burst that will start it,
/// in the middle of a panel at least as tall as 暗記練's, chained up,
/// saying so.
class _RankedPanel extends StatelessWidget {
  const _RankedPanel();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LockedPanel(
      tag: s.ankirenRankedMode,
      sub: s.sub?.ankirenRankedMode,
      why: s.teiichiRankedSoon,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: TeiichiPageLayout.rankedHeight),
        child: Center(
          child: RankedRow(facts: s.teiichiRankedFacts(TeiichiTuning.cards), line: s.ankirenRankedReal, onTap: null),
        ),
      ),
    );
  }
}

/// The guide's card: its title, its line and the way to the guide, at
/// most [TeiichiPageLayout.learnMeasure] wide at the type's size, and Tobi
/// pointing at them from the room beside them, up to
/// [TeiichiPageLayout.learnTobi]. Larger type takes room from Tobi, down
/// to [TeiichiPageLayout.learnTobiLeast] wide. Given more height than it
/// needs, the card keeps them in its middle.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final measure = MediaQuery.textScalerOf(context).scale(TeiichiPageLayout.learnMeasure);
    return MangaPanel(
      shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
      padding: TeiichiPageLayout.learnPadding,
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: Row(children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints.loose(TeiichiPageLayout.learnTobi),
                  child: const AspectRatio(aspectRatio: TobiStyle.aspect, child: Tobi(pose: TobiPose.pointing)),
                ),
              ),
            ),
            const SizedBox(width: TeiichiPageLayout.learnTobiGap),
            SizedBox(
              width: math.min(measure, box.maxWidth - TeiichiPageLayout.learnTobiGap - TeiichiPageLayout.learnTobiLeast),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                const SizedBox(height: TeiichiPageLayout.buttonTop),
                IntrinsicWidth(
                  child: InkButton(
                    onTap: () => openTeiichiGuide(context),
                    color: Palette.sun,
                    border: Strokes.control,
                    padding: TeiichiPageLayout.buttonPadding,
                    semanticLabel: s.teiichiLearnButton,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(s.teiichiLearnButton,
                            style: const TextStyle(fontWeight: Weights.black, fontSize: TeiichiPageLayout.buttonFont)),
                      ),
                      const SizedBox(width: TeiichiPageLayout.buttonIconGap),
                      MangaIcon(IconArt.arrow, size: TeiichiPageLayout.buttonIcon),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
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

/// The page's blocks one under the other across its width, each as tall
/// as it needs. When that is less than the least height it is given, each
/// block in a [_Grows] takes its share of the room to spare and fills it,
/// so the page meets the screen's foot with no gap.
class _GrowColumn extends MultiChildRenderObjectWidget {
  const _GrowColumn({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGrowColumn();
}

/// A block of a [_GrowColumn] that takes [share] of the room to spare.
class _Grows extends ParentDataWidget<_GrowData> {
  const _Grows({required this.share, required super.child});

  final double share;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _GrowData;
    if (data.share == share) return;
    data.share = share;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _GrowColumn;
}

class _GrowData extends ContainerBoxParentData<RenderBox> {
  double share = 0;
}

class _RenderGrowColumn extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _GrowData>, RenderBoxContainerDefaultsMixin<RenderBox, _GrowData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GrowData) child.parentData = _GrowData();
  }

  double get _total => getChildrenAsList().fold(0.0, (sum, block) => sum + block.size.height);

  @override
  void performLayout() {
    final across = BoxConstraints.tightFor(width: constraints.maxWidth);
    final blocks = getChildrenAsList();
    for (final block in blocks) {
      block.layout(across, parentUsesSize: true);
    }
    final room = math.max(0.0, constraints.minHeight - _total);
    var y = 0.0;
    for (final block in blocks) {
      final data = block.parentData! as _GrowData;
      if (room > 0 && data.share > 0) {
        block.layout(across.tighten(height: block.size.height + room * data.share), parentUsesSize: true);
      }
      data.offset = Offset(0, y);
      y += block.size.height;
    }
    size = constraints.constrain(Size(constraints.maxWidth, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
