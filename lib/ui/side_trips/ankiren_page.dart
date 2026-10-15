import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_field_preview.dart';
import '../history/history_screen.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_free_sheet.dart';
import 'ankiren_rules_sheet.dart';
import 'side_trip_entry.dart';

/// Opens 暗記練's page ([AnkirenPage]), once 暗記練 is open.
Future<void> openAnkirenPage(BuildContext context) async {
  if (!ProgressScope.read(context).sideTripsHub()[SideTrip.ankiren].open) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const AnkirenPage()));
}

/// 暗記練's page, the hub's panel opened up, on one screen: who the player
/// is (the class and rating, and the way to the next class), how it has
/// gone (the last ranked games, or the placement games so far), what is
/// next (the next ranked game's level, cards and memorise time, why it is
/// that level, and a preview of its field) and the burst that starts it.
/// Ranked picks its level from the rating alone; free play, with a level
/// or setup of the player's own, and the rules are Home's button pair
/// under it, each a sheet. The first visit opens with the rules. Home's
/// dotted ground, in the sea's blue, lies behind the panels.
///
/// The field preview is the one part that gives up height. With too
/// little room for it, the panel closes up over the burst, which stays
/// near the thumb, and the room left parts the last games from it. When
/// even without it the page is taller than the screen, it scrolls.
class AnkirenPage extends StatefulWidget {
  const AnkirenPage({super.key});

  @override
  State<AnkirenPage> createState() => _AnkirenPageState();
}

class _AnkirenPageState extends State<AnkirenPage> {
  @override
  void initState() {
    super.initState();
    if (!ProgressScope.read(context).settings.ankiren.rulesSeen) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) openAnkirenRules(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final entry = ProgressScope.of(context).sideTripsHub()[SideTrip.ankiren];
    const trip = SideTrip.ankiren;
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
                    _RecordStrip(entry),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    MangaPanel(
                      padding: AnkirenPageLayout.gamesPadding,
                      child: AnkirenRating.isPlacement(entry.results.length)
                          ? _Placement(entry.results)
                          : _LastGames(entry.results),
                    ),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    Expanded(child: Align(alignment: Alignment.bottomCenter, child: _NextGame(entry))),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripFreeButton(entry, onTap: () => openAnkirenFree(context))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openAnkirenRules(context))),
                    ]),
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

/// [text] in black type, then [sub] (the other language's) in small tracked
/// capitals, each breaking only between words; [underline]d as a link.
class _Label extends StatelessWidget {
  const _Label(this.text, this.sub,
      {this.fontSize = AnkirenPageLayout.labelFont, this.color = Palette.ink, this.underline = false});

  final String text;
  final String? sub;
  final double fontSize;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(text),
          if (sub != null) ...[
            const TextSpan(text: ' '),
            Phrases.span(
              sub!.toUpperCase(),
              style: const TextStyle(
                fontSize: AnkirenPageLayout.labelFont,
                letterSpacing: AnkirenPageLayout.labelTracking * AnkirenPageLayout.labelFont,
              ),
            ),
          ],
        ]),
        style: TextStyle(
          fontWeight: Weights.black,
          fontSize: fontSize,
          height: AnkirenPageLayout.labelLineHeight,
          color: color,
          decoration: underline ? TextDecoration.underline : null,
          decorationThickness: AnkirenPageLayout.linkUnderline,
        ),
      );
}

/// Cells side by side, split by ink rules: each as wide as it is on one
/// line, all narrowed in proportion when the row is too narrow for that,
/// and all as tall as the tallest.
class _CellRow extends MultiChildRenderObjectWidget {
  const _CellRow({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCellRow();
}

class _CellRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCellRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellRowParentData> {
  /// The room between two cells, the rule in its middle.
  static const _between = 2 * AnkirenPageLayout.cellGap + Strokes.control;

  /// Where each rule starts, from the last layout.
  List<double> _rules = const [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellRowParentData) child.parentData = _CellRowParentData();
  }

  double get _gaps => _between * math.max(0, childCount - 1);

  /// Each cell's width in a row [width] wide.
  List<double> _widths(double width) {
    final natural = [for (final cell in getChildrenAsList()) cell.getMaxIntrinsicWidth(double.infinity)];
    final total = natural.fold(0.0, (sum, w) => sum + w);
    final room = math.max(0.0, width - _gaps);
    final scale = total > room ? room / total : 1.0;
    return [for (final w in natural) w * scale];
  }

  double _tallest(double width, double Function(RenderBox cell, double width) heightOf) {
    final widths = _widths(width);
    return [for (final (i, cell) in getChildrenAsList().indexed) heightOf(cell, widths[i])].fold(0.0, math.max);
  }

  double _dryHeight(RenderBox cell, double width) => cell.getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _gaps + getChildrenAsList().fold(0.0, (sum, cell) => sum + cell.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _gaps + getChildrenAsList().fold(0.0, (sum, cell) => sum + cell.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) => _tallest(width, (cell, w) => cell.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _tallest(width, (cell, w) => cell.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final widths = _widths(constraints.maxWidth);
    final width = _gaps + widths.fold(0.0, (sum, w) => sum + w);
    return constraints.constrain(Size(width, _tallest(constraints.maxWidth, _dryHeight)));
  }

  @override
  void performLayout() {
    final widths = _widths(constraints.maxWidth);
    final height = _tallest(constraints.maxWidth, _dryHeight);
    final rules = <double>[];
    var x = 0.0;
    for (final (i, cell) in getChildrenAsList().indexed) {
      if (i > 0) {
        rules.add(x + AnkirenPageLayout.cellGap);
        x += _between;
      }
      cell.layout(BoxConstraints(maxWidth: widths[i], minHeight: height, maxHeight: height));
      (cell.parentData! as _CellRowParentData).offset = Offset(x, 0);
      x += widths[i];
    }
    _rules = rules;
    size = constraints.constrain(Size(x, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    final ink = Paint()..color = Palette.ink;
    for (final left in _rules) {
      context.canvas.drawRect(Rect.fromLTWH(offset.dx + left, offset.dy, Strokes.control, size.height), ink);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A label over its value, the value on one line, shrinking rather than
/// overflowing.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final Widget label, value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          label,
          const SizedBox(height: AnkirenPageLayout.labelGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle.merge(softWrap: false, child: value),
          ),
        ],
      );
}

/// History's sun-toned strip, for 暗記練: the class and the rating with the
/// last game's change (unranked before the first), then how many points
/// the next class is away, with a gauge.
class _RecordStrip extends StatelessWidget {
  const _RecordStrip(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final band = entry.band;
    final rating = entry.rating;
    final at = rating ?? AnkirenRating.start;
    final next = Rating.nextBand(at);
    final floor = band.minRating.isFinite ? band.minRating : AnkirenRating.start;
    final change = entry.ratingChange?.round() ?? 0;
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.stripFont, height: 1);
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(AnkirenPageLayout.stripCut, 0)),
      tone: Tones.sun,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AnkirenPageLayout.cellsPadding,
            child: _CellRow(children: [
              _Cell(
                label: _Label(s.sideTripClass, s.sub?.sideTripClass),
                value: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: s.classStem(band)),
                    if (s.classStem(band) != s.className(band))
                      const TextSpan(
                          text: RankBand.classSuffix, style: TextStyle(fontSize: AnkirenPageLayout.classSuffixFont)),
                  ]),
                  style: big,
                ),
              ),
              _Cell(
                label: _Label(s.rating, s.sub?.rating),
                value: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rating == null ? s.sideTripUnranked : '${rating.round()}', style: big),
                  if (change != 0) ...[
                    const SizedBox(width: AnkirenPageLayout.valueGap),
                    RatingChangeTag(change),
                  ],
                ]),
              ),
            ]),
          ),
          if (next != null)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Palette.ink, width: Strokes.control)),
              ),
              child: Padding(
                padding: AnkirenPageLayout.gaugePadding,
                child: Row(children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: NumberedText(
                        s.ratingToNext(s.className(next)),
                        [(next.minRating - at).ceil()],
                        style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.gaugeFont),
                        numberStyle:
                            const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.gaugeNumber),
                      ),
                    ),
                  ),
                  const SizedBox(width: AnkirenPageLayout.gaugeGap),
                  Expanded(child: RatingBar((at - floor) / (next.minRating - floor), width: double.infinity)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// A heading: [title] with its other-language [sub], and [trailing] at
/// the right.
class _Heading extends StatelessWidget {
  const _Heading(this.title, this.sub, {required this.trailing});

  final String title;
  final String? sub;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Semantics(header: true, child: _Label(title, sub, fontSize: AnkirenPageLayout.headFont)),
        ),
        trailing,
      ]);
}

/// Games side by side in equal columns, split by light rules.
class _GameRow extends StatelessWidget {
  const _GameRow(this.cells);

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, cell) in cells.indexed) ...[
            if (i > 0)
              const SizedBox(
                width: AnkirenPageLayout.lightRuleWidth,
                child: ColoredBox(color: AnkirenPageLayout.lightRule),
              ),
            Expanded(child: Padding(padding: AnkirenPageLayout.gamePadding, child: cell)),
          ],
        ]),
      );
}

/// One ranked game: its score, what it did to the rating, and its level,
/// each on one line, shrinking rather than overflowing.
class _Game extends StatelessWidget {
  const _Game(this.result);

  final SideTripResult result;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DefaultTextStyle.merge(
      softWrap: false,
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${result.score}',
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.scoreFont, height: 1)),
        ),
        const SizedBox(height: AnkirenPageLayout.gameGap),
        FittedBox(fit: BoxFit.scaleDown, child: RatingChangeTag(result.ratingChange.round())),
        const SizedBox(height: AnkirenPageLayout.gameGap),
        Text(
          s.ankirenLevelTag(result.level),
          maxLines: 1,
          style: const TextStyle(
              fontWeight: Weights.black, fontSize: AnkirenPageLayout.gameLevelFont, height: 1, color: Palette.mute),
        ),
      ]),
    );
  }
}

/// The last ranked games, newest first, with a link to all of them in
/// History.
class _LastGames extends StatelessWidget {
  const _LastGames(this.results);

  final List<SideTripResult> results;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final last = results.reversed.take(AnkirenPageLayout.lastGames).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Heading(s.ankirenLast5, s.sub?.ankirenLast5, trailing: const _HistoryLink()),
      const SizedBox(height: AnkirenPageLayout.headGap),
      _GameRow([
        for (var i = 0; i < AnkirenPageLayout.lastGames; i++)
          if (i < last.length) _Game(last[i]) else const SizedBox.shrink(),
      ]),
    ]);
  }
}

/// History, showing 暗記練's games: an underlined link with a chevron, a
/// full touch target tall.
class _HistoryLink extends StatelessWidget {
  const _HistoryLink();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Pressable(
      onTap: () => openTripHistory(context, SideTrip.ankiren),
      scale: 1,
      turn: 0,
      semanticLabel: s.history,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ButtonMetrics.iconButton),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Label(s.history, s.sub?.history, fontSize: AnkirenPageLayout.linkFont, underline: true),
          const SizedBox(width: AnkirenPageLayout.linkGap),
          MangaIcon(IconArt.chevron, size: AnkirenPageLayout.linkIcon, strokeWidth: AnkirenPageLayout.linkIconStroke),
        ]),
      ),
    );
  }
}

/// The placement games ([AnkirenRatingModel.placementGames]): those played,
/// then dashed slots for the rest, the next one marked.
class _Placement extends StatelessWidget {
  const _Placement(this.results);

  final List<SideTripResult> results;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const games = AnkirenRatingModel.placementGames;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Heading(
        s.ankirenPlacementTitle,
        s.sub?.ankirenPlacementTitle,
        trailing: NumberedText(
          s.ankirenPlacementCount,
          [results.length, games],
          style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.countFont),
          numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.countNumber),
        ),
      ),
      const SizedBox(height: AnkirenPageLayout.headGap),
      _GameRow([
        for (var i = 0; i < games; i++)
          if (i < results.length) _Game(results[i]) else _Slot(i + 1, next: i == results.length),
      ]),
    ]);
  }
}

/// A placement game still to play: its [number] in a dashed slot, over
/// "next" for the [next] one.
class _Slot extends StatelessWidget {
  const _Slot(this.number, {required this.next});

  final int number;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.gameLevelFont, height: 1);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox.square(
        dimension: AnkirenPageLayout.slot,
        child: DashedBox(
          ink: AnkirenPageLayout.slotInk,
          border: AnkirenPageLayout.slotBorder,
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: AnkirenPageLayout.slotFont,
                    height: 1,
                    color: AnkirenPageLayout.todo)),
          ),
        ),
      ),
      const SizedBox(height: AnkirenPageLayout.gameGap),
      if (next)
        _Label(s.ankirenPlacementNext, s.sub?.ankirenPlacementNext, color: AnkirenPageLayout.todo)
      else
        const Text('—', style: style),
    ]);
  }
}

/// The next ranked game, in a panel with the side trips' cut corner and a
/// tag over its top edge: its level, cards and memorise time, why it plays
/// that level, a preview of its field, and the burst that starts it.
class _NextGame extends StatelessWidget {
  const _NextGame(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final level = entry.rankedLevel ?? 0;
    return Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.only(top: AnkirenPageLayout.tagRise),
        child: MangaPanel(
          shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Stats(level),
            _Hint(entry, level),
            Flexible(child: AnkirenFieldPreview(level)),
            Padding(
              padding: AnkirenPageLayout.burstMargin,
              child: RankedBurst(onTap: () => startAnkirenRanked(context)),
            ),
          ]),
        ),
      ),
      Positioned(
        left: AnkirenPageLayout.tagLeft,
        right: AnkirenPageLayout.tagLeft,
        top: 0,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Semantics(header: true, child: InkBanner(s.ankirenNextRanked, sub: s.sub?.ankirenNextRanked)),
          ),
        ),
      ),
    ]);
  }
}

/// [level]'s facts: the level, the cards a side and the memorise time,
/// split by ink rules.
class _Stats extends StatelessWidget {
  const _Stats(this.level);

  final int level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final of = AnkirenLevels.of(level);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    return Padding(
      padding: AnkirenPageLayout.statsPadding,
      child: _CellRow(children: [
        _Cell(
          label: _Label(s.ankirenLevelRow, s.sub?.ankirenLevelRow),
          value: NumberedText(
            s.ankirenLevelValue,
            [level],
            style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1),
            numberStyle: big,
          ),
        ),
        _Cell(
          label: _Label(s.ankirenCards, s.sub?.ankirenCards),
          value: NumberedText(
            s.ankirenPerSideCount,
            [of.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.statSuffixFont, height: 1),
            numberStyle: big,
          ),
        ),
        _Cell(
          label: _Label(s.ankirenMemoriseLabel, s.sub?.ankirenMemoriseLabel),
          value: Text(formatMinutes(of.memorise), style: big),
        ),
      ]),
    );
  }
}

/// Why ranked plays [level]: the rating sets it, with the points still to
/// go to the next level; or the known cards hold it back, with the cards
/// the next level needs; or it is the top level.
class _Hint extends StatelessWidget {
  const _Hint(this.entry, this.level);

  final SideTripEntry entry;
  final int level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = entry.rating ?? AnkirenRating.start;
    final capped = AnkirenRating.levelFor(rating, maxLevel: AnkirenLevels.top) > level;
    final nextAt = AnkirenRating.nextLevelAt(level);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.hintNumber, color: Palette.ink);
    final why = capped
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            MangaIcon(IconArt.lock,
                size: AnkirenPageLayout.hintIcon, color: Palette.mute, strokeWidth: AnkirenPageLayout.hintIconStroke),
            const SizedBox(width: AnkirenPageLayout.hintGap),
            Flexible(child: _Label(s.ankirenCapped, s.sub?.ankirenCapped, color: Palette.mute)),
          ])
        : _Label(s.ankirenSetByRating, s.sub?.ankirenSetByRating, color: Palette.mute);
    final Widget toGo;
    if (capped) {
      toGo = NumberedText(s.ankirenLevelFrom, [level + 1, AnkirenLevels.of(level + 1).cards],
          style: style, numberStyle: number);
    } else if (nextAt == null) {
      toGo = Text(s.ankirenTopLevel, style: style);
    } else {
      toGo = NumberedText(s.ankirenToLevel, [level + 1, (nextAt - rating).ceil()], style: style, numberStyle: number);
    }
    return Padding(
      padding: AnkirenPageLayout.hintPadding,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AnkirenPageLayout.gaugeGap,
        children: [why, toGo],
      ),
    );
  }
}
