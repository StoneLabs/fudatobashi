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
import '../ankiren/ankiren_strikes.dart';
import '../history/history_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../teiichi/teiichi_field_preview.dart';
import 'burst_button.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';
import 'teiichi_guide.dart';
import 'teiichi_rules_sheet.dart';
import 'teiichi_sheet.dart';
import 'trip_record_panels.dart';

/// Opens 定位置's page ([TeiichiPage]), once 定位置 is open.
Future<void> openTeiichiPage(BuildContext context) async {
  if (!ProgressScope.read(context).sideTripsHub()[SideTrip.teiichi].open) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const TeiichiPage()));
}

/// 定位置's page, the hub's panel opened up, on 暗記練's page's frame, with
/// History beside the back button: who the player is (the form, and the
/// class and rating once there is one); ranked, chained up until it opens
/// (see [RankedLock]); the guide's card, a short row; the next level to clear; and at
/// the foot, within the thumb's reach, Guest mode and the rules, each a
/// sheet. The first visit opens with the rules. Home's dotted
/// ground, in the sea's blue, lies behind the panels. A taller screen's
/// room to spare goes to ranked ([_GrowColumn]); the
/// page scrolls when it is taller than the screen, as it is on most phones.
class TeiichiPage extends StatefulWidget {
  const TeiichiPage({super.key});

  @override
  State<TeiichiPage> createState() => _TeiichiPageState();
}

class _TeiichiPageState extends State<TeiichiPage> {
  /// The setup picked from the level sheet, kept while the page is open;
  /// null for the next level to clear.
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
                        InkIconButton(
                            icon: IconArt.history,
                            semanticLabel: s.history,
                            onTap: () => openTripHistory(context, trip)),
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    _Banner(entry),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    _Grows(
                      share: TeiichiPageLayout.rankedShare,
                      child: RankedPanel(
                        entry,
                        facts: s.teiichiRankedFacts(TeiichiTuning.cards, formatMinutes(TeiichiTuning.rankedLimit)),
                        onStart: () => startTeiichiRanked(context),
                      ),
                    ),
                    const SizedBox(height: TeiichiPageLayout.learnTop),
                    const _LearnCard(),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    _NextLevelPanel(
                      entry,
                      picked: _picked,
                      onPick: (setup) => setState(() => _picked = setup),
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openTeiichiGuest(context))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openTeiichiRules(context))),
                    ]),
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

/// The page's [StatStrip], for 定位置: the average wrong taps and placing
/// time of the last games that count, over how many games; dashes, and the
/// game to play to start it, before the first. Once the player has a rating
/// its class, rating and way to the next class come first ([RecordStrip]).
/// The labels go without the other language's, which would wrap them.
class _Banner extends StatelessWidget {
  const _Banner(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final form = entry.placing.form;
    const big = StatStrip.valueStyle;
    final cells = [
      StatCell(
        label: PanelLabel(s.teiichiFormWrongTaps, null),
        value: Text(form == null ? missingTime : formatAverage(form.wrongTaps), style: big),
      ),
      StatCell(
        label: PanelLabel(s.teiichiFormPlacing, null),
        value: Text(form == null ? missingTime : formatMinutes(form.placing), style: big),
      ),
    ];
    final foot = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: NumberedText(
        form == null ? s.teiichiFormStart : s.teiichiFormGames(form.games),
        [form?.games ?? TeiichiTuning.cards],
        style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.gaugeFont),
        numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.gaugeNumber),
      ),
    );
    return entry.ranked
        ? RecordStrip(entry, more: cells, moreFoot: foot)
        : StatStrip(fills: true, cells: cells, foot: foot);
  }
}

/// The guide's card, a single short row: its title on one line, shrunk to
/// fit, and beside it the way to the guide.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
      padding: TeiichiPageLayout.learnPadding,
      child: Center(
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  Phrases.span(s.teiichiLearnTitle),
                  maxLines: 1,
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: TeiichiPageLayout.learnTitleFont,
                      height: TypeScale.displayLineHeight),
                ),
              ),
            ),
          ),
          const SizedBox(width: TeiichiPageLayout.learnGap),
          InkButton(
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
        ]),
      ),
    );
  }
}

/// The next level to clear (the top level again once every level is
/// cleared), or the setup [picked] instead: its facts, the level among them
/// the way to the level sheet ([pickTeiichiLevel]), what clears it (or that
/// a custom game is not scored), a preview of its side of the field, and
/// the burst that starts it. A setup confirmed in the sheet goes to
/// [onPick], as null when it is the next level to clear.
class _NextLevelPanel extends StatelessWidget {
  const _NextLevelPanel(this.entry, {required this.picked, required this.onPick});

  final SideTripEntry entry;
  final TeiichiSetup? picked;
  final ValueChanged<TeiichiSetup?> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final next = entry.nextLevel;
    final usual = TeiichiSetup.forLevel(next ?? TeiichiLevels.top);
    final setup = picked ?? usual;
    final level = setup.level;
    final allCleared = picked == null && next == null;
    String tag(S s) => picked != null
        ? (level == null ? s.ankirenCustom : s.ankirenLevelRow)
        : allCleared
            ? s.ankirenAllClearedTitle
            : s.ankirenNextToClear;
    String play(S s) => level == null ? s.teiichiPlay(setup.cards) : s.ankirenPlayLevel(level);
    Future<void> pick() async {
      final chosen = await pickTeiichiLevel(context, setup);
      if (chosen != null && context.mounted) onPick(chosen == usual ? null : chosen);
    }

    return TaggedPanel(
      tag: tag(s),
      sub: s.sub == null ? null : tag(s.sub!),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Stats(setup, onLevel: pick),
        _Hint(setup, allCleared: allCleared, cleared: level != null && entry.ladder.isCleared(level)),
        TeiichiFieldPreview(setup),
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

/// A setup's facts across the panel: the level, as the button that calls
/// [onLevel], then the cards, the rows and the most time, split by an ink
/// rule, their labels and values in line with the level's.
class _Stats extends StatelessWidget {
  const _Stats(this.setup, {required this.onLevel});

  final TeiichiSetup setup;
  final VoidCallback onLevel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final limit = setup.limit;
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    const unit = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1);
    return Padding(
      padding: AnkirenPageLayout.statsPadding,
      child: CellRow(firstRuled: false, fills: true, children: [
        DropCellButton(
          onTap: onLevel,
          semanticLabel: s.ankirenAllLevels,
          label: PanelLabel(s.ankirenLevelRow, null),
          value: NumberedText(
            s.ankirenLevelValue,
            [setup.level ?? TeiichiTuning.customLevel],
            style: unit,
            numberStyle: big,
          ),
        ),
        StatCell(
          inset: AnkirenPageLayout.levelButtonInset,
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
          label: PanelLabel(s.teiichiLimitLabel, null),
          value: limit == null ? Text(s.teiichiNoLimit, style: unit) : Text(formatMinutes(limit), style: big),
        ),
      ]),
    );
  }
}

/// What clears [setup]'s level (or that every level is, once [allCleared];
/// or that a custom game is not scored), with a checked "Cleared" on the
/// right once it is [cleared].
class _Hint extends StatelessWidget {
  const _Hint(this.setup, {required this.allCleared, required this.cleared});

  final TeiichiSetup setup;
  final bool allCleared, cleared;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.hintNumber, color: Palette.ink);
    final Widget why = allCleared
        ? Text(s.ankirenAllCleared, style: style)
        : setup.custom
            ? Text.rich(Phrases.span(s.teiichiCustomNote), style: style)
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenPageLayout.hintCard),
                const SizedBox(width: AnkirenPageLayout.hintGap),
                Flexible(
                  child: NumberedText(s.ankirenClearRule, [AnkirenTuning.strikesOut], style: style, numberStyle: number),
                ),
              ]);
    return Padding(
      padding: AnkirenPageLayout.hintPadding,
      child: Row(children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: why)),
        if (cleared) ...[
          const SizedBox(width: AnkirenPageLayout.hintGap),
          const ClearedCheck(size: AnkirenPageLayout.clearedCheck),
          const SizedBox(width: AnkirenPageLayout.hintGap),
          Text(s.ankirenClearedMark,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.clearedFont)),
        ],
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
