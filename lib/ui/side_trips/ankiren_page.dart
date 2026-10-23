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
import '../ankiren/ankiren_strikes.dart';
import '../history/history_screen.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../shell/tab_chains.dart';
import 'ankiren_free_sheet.dart';
import 'ankiren_rules_sheet.dart';
import 'burst_button.dart';
import 'side_trip_entry.dart';

/// Opens 暗記練's page ([AnkirenPage]), once 暗記練 is open.
Future<void> openAnkirenPage(BuildContext context) async {
  if (!ProgressScope.read(context).sideTripsHub()[SideTrip.ankiren].open) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const AnkirenPage()));
}

/// 暗記練's page, the hub's panel opened up, on one screen, with History
/// beside the back button: who the player is (the class and rating, and the
/// way to the next class); ranked, in a panel with its last games (or the
/// placement games so far), its one setup and the burst that starts it, all
/// chained up until ranked opens (see [RankedLock]); then free play's next
/// level to clear, in a larger panel with its facts, what clears it, a
/// preview of its field, the way to every level ([openAnkirenFree]) and the
/// burst that starts it. Guest mode
/// and the rules are Home's button pair under them, each a sheet. The first
/// visit opens with the rules. Home's dotted ground, in the sea's blue, lies
/// behind the panels.
///
/// The field preview is the one part that gives up height. With too
/// little room for it, the free-play panel closes up over its burst, which
/// stays near the thumb. When even without it the page is taller than the
/// screen, it scrolls.
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
                        InkIconButton(
                            icon: IconArt.history,
                            semanticLabel: s.history,
                            onTap: () => openTripHistory(context, trip)),
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    _RecordStrip(entry),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    _RankedPanel(entry),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    Expanded(child: Align(alignment: Alignment.bottomCenter, child: _NextLevelPanel(entry))),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openAnkirenGuest(context))),
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
/// capitals, each breaking only between words.
class _Label extends StatelessWidget {
  const _Label(this.text, this.sub, {this.fontSize = AnkirenPageLayout.labelFont, this.color = Palette.ink});

  final String text;
  final String? sub;
  final double fontSize;
  final Color color;

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
        ),
      );
}

/// Cells side by side, split by ink rules (none after the first unless
/// [firstRuled], for a boxed first cell): each as wide as it is on one
/// line, the room left shared out evenly when the row [fills] its width,
/// and all as tall as the tallest. When the row is too narrow for
/// that, the cells give up width in proportion to what they can spare
/// before a word would break, and past that all narrow in proportion.
class _CellRow extends MultiChildRenderObjectWidget {
  const _CellRow({required super.children, this.firstRuled = true, this.fills = false});

  final bool firstRuled, fills;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCellRow(firstRuled, fills);

  @override
  void updateRenderObject(BuildContext context, _RenderCellRow renderObject) => renderObject
    ..firstRuled = firstRuled
    ..fills = fills;
}

class _CellRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCellRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellRowParentData> {
  _RenderCellRow(this._firstRuled, this._fills);

  bool _firstRuled;
  set firstRuled(bool value) {
    if (value == _firstRuled) return;
    _firstRuled = value;
    markNeedsLayout();
  }

  bool _fills;
  set fills(bool value) {
    if (value == _fills) return;
    _fills = value;
    markNeedsLayout();
  }

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
    final cells = getChildrenAsList();
    final natural = [for (final cell in cells) cell.getMaxIntrinsicWidth(double.infinity)];
    final total = natural.fold(0.0, (sum, w) => sum + w);
    final room = math.max(0.0, width - _gaps);
    if (total <= room) {
      if (!_fills || !room.isFinite) return natural;
      return [for (final w in natural) w + (room - total) / natural.length];
    }
    final least = [
      for (final (i, cell) in cells.indexed) math.min(natural[i], cell.getMinIntrinsicWidth(double.infinity)),
    ];
    final slack = total - least.fold(0.0, (sum, w) => sum + w);
    final over = total - room;
    if (over <= slack) return [for (final (i, w) in natural.indexed) w - (w - least[i]) * over / slack];
    return [for (final w in natural) w * room / total];
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
        if (i > 1 || _firstRuled) rules.add(x + AnkirenPageLayout.cellGap);
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
/// overflowing; [inset] from the top and bottom.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.inset = 0});

  final Widget label, value;
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            label,
            const SizedBox(height: AnkirenPageLayout.labelGap),
            _Shrinks(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle.merge(softWrap: false, child: value),
              ),
            ),
          ],
        ),
      );
}

/// [child], which scales down to any width, so it sets no narrowest width
/// for its cell: there only the label's words count.
class _Shrinks extends SingleChildRenderObjectWidget {
  const _Shrinks({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderShrinks();
}

class _RenderShrinks extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
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

/// A panel's heading, at the right of its tag, which carries the other
/// language's words.
class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: _Label(title, null, fontSize: AnkirenPageLayout.headFont));
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

/// One ranked game: its score and what it did to the rating, each on one
/// line, shrinking rather than overflowing.
class _Game extends StatelessWidget {
  const _Game(this.result);

  final SideTripResult result;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        softWrap: false,
        child: Column(children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${result.score}',
                style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.scoreFont, height: 1)),
          ),
          const SizedBox(height: AnkirenPageLayout.gameGap),
          FittedBox(fit: BoxFit.scaleDown, child: RatingChangeTag(result.ratingChange.round())),
        ]),
      );
}

/// The last ranked games, newest first.
class _LastGames extends StatelessWidget {
  const _LastGames(this.results);

  final List<SideTripResult> results;

  @override
  Widget build(BuildContext context) {
    final last = results.reversed.take(AnkirenPageLayout.lastGames).toList();
    return _GameRow([
      for (var i = 0; i < AnkirenPageLayout.lastGames; i++)
        if (i < last.length) _Game(last[i]) else const SizedBox.shrink(),
    ]);
  }
}

/// The placement games ([AnkirenRatingModel.placementGames]): those played,
/// then dashed slots for the rest, the next one marked.
class _Placement extends StatelessWidget {
  const _Placement(this.results);

  final List<SideTripResult> results;

  @override
  Widget build(BuildContext context) => _GameRow([
        for (var i = 0; i < AnkirenRatingModel.placementGames; i++)
          if (i < results.length) _Game(results[i]) else _Slot(i + 1, next: i == results.length),
      ]);
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

/// A panel with the side trips' cut corner and [tag] on an ink banner over
/// its top edge, [heading] at the right beside the tag (or under it when
/// there is no room beside it), then [child]. With a [cover], the inside is
/// faded under it.
class _TaggedPanel extends StatelessWidget {
  const _TaggedPanel({required this.tag, required this.sub, this.heading, required this.child, this.cover});

  final String tag;
  final String? sub;
  final Widget? heading;
  final Widget child;
  final Widget? cover;

  @override
  Widget build(BuildContext context) {
    final banner = FittedBox(fit: BoxFit.scaleDown, child: InkBanner(tag, sub: sub));
    const head = AnkirenPageLayout.headPadding;
    final inside = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: head,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AnkirenPageLayout.headGap,
          runSpacing: AnkirenPageLayout.headGap,
          children: [
            Overhang(rise: AnkirenPageLayout.tagRise + head.top, child: ExcludeSemantics(child: banner)),
            ?heading,
          ],
        ),
      ),
      Flexible(child: child),
    ]);
    return Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.only(top: AnkirenPageLayout.tagRise),
        child: MangaPanel(
          shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
          child: cover == null
              ? inside
              : Stack(children: [
                  IgnorePointer(child: Opacity(opacity: AnkirenPageLayout.lockedOpacity, child: inside)),
                  Positioned.fill(child: cover!),
                ]),
        ),
      ),
      Positioned(
        left: head.left,
        right: head.right,
        top: 0,
        child: Align(alignment: Alignment.centerLeft, child: Semantics(header: true, child: banner)),
      ),
    ]);
  }
}

/// Ranked: the last ranked games (or the placement games so far), its one
/// setup and the burst that starts it. Until ranked opens the whole panel
/// is chained up, faded, with what still opens it stuck over the chains;
/// a tap says it again.
class _RankedPanel extends StatelessWidget {
  const _RankedPanel(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lock = entry.rankedLock;
    final placement = AnkirenRating.isPlacement(entry.results.length);
    final heading = _Heading(placement ? s.ankirenPlacementTitle : s.ankirenLast5);
    final content = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: AnkirenPageLayout.gamesPadding,
        child: placement ? _Placement(entry.results) : _LastGames(entry.results),
      ),
      Padding(
        padding: AnkirenPageLayout.rankedRowPadding,
        child: Row(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AnkirenPageLayout.factsMaxWidth),
            child: Text.rich(
              TextSpan(children: [
                Phrases.span(
                  s.ankirenRankedFacts(AnkirenTuning.rankedPerSide, formatMinutes(AnkirenTuning.rankedMemorise)),
                  style: const TextStyle(fontWeight: Weights.black, color: Palette.ink),
                ),
                const TextSpan(text: '\n'),
                Phrases.span(s.ankirenRankedReal),
              ]),
              maxLines: AnkirenPageLayout.factsLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute),
            ),
          ),
          const SizedBox(width: AnkirenPageLayout.rankedRowGap),
          Expanded(
            child: SizedBox(
              height: AnkirenPageLayout.rankedBurst,
              child: RankedBurst(onTap: lock == null ? () => startAnkirenRanked(context) : null),
            ),
          ),
        ]),
      ),
    ]);
    if (lock == null) {
      return _TaggedPanel(tag: s.ankirenRankedMode, sub: s.sub?.ankirenRankedMode, heading: heading, child: content);
    }
    final why = s.ankirenRankedLocked(allKnown: lock.allKnown, cleared: lock.cleared, level: RankedLock.level);
    return Pressable(
      onTap: () => BalloonPop.show(context, why,
          size: AnkirenPageLayout.lockBalloon, life: AnkirenPageLayout.lockBalloonLife),
      scale: 1,
      turn: 0,
      semanticLabel: '${s.ankirenRankedMode}: $why',
      builder: (context, _) => ExcludeSemantics(
        child: _TaggedPanel(
          tag: s.ankirenRankedMode,
          sub: s.sub?.ankirenRankedMode,
          heading: heading,
          cover: Stack(children: [
            const Positioned.fill(child: ClipRect(child: TabChains(scale: AnkirenPageLayout.chainScale))),
            Positioned(
              left: AnkirenPageLayout.lockNoteInset,
              right: AnkirenPageLayout.lockNoteInset,
              bottom: AnkirenPageLayout.lockNoteBottom,
              child: Center(
                child: Sticker(
                  color: Palette.paper,
                  tilt: AnkirenPageLayout.lockNoteTilt,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    MangaIcon(IconArt.lock,
                        size: AnkirenPageLayout.hintIcon, strokeWidth: AnkirenPageLayout.hintIconStroke),
                    const SizedBox(width: AnkirenPageLayout.hintGap),
                    Flexible(
                      child: Text.rich(Phrases.span(why),
                          style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.lockNoteFont)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
          child: content,
        ),
      ),
    );
  }
}

/// Free play's next level to clear (the top level again once every level
/// is cleared): its facts, the level among them the way to every level,
/// what clears it (or what the known cards still lack), a preview of its
/// field, and the burst that starts it.
class _NextLevelPanel extends StatelessWidget {
  const _NextLevelPanel(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final next = entry.nextLevel;
    final level = next ?? AnkirenLevels.top;
    final setup = AnkirenSetup.forLevel(level);
    final fits = entry.fits(level);
    return _TaggedPanel(
      tag: next == null ? s.ankirenAllClearedTitle : s.ankirenNextToClear,
      sub: next == null ? s.sub?.ankirenAllClearedTitle : s.sub?.ankirenNextToClear,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Stats(setup),
        _Hint(setup, fits: fits, allCleared: next == null),
        Flexible(child: AnkirenFieldPreview(setup)),
        Padding(
          padding: AnkirenPageLayout.burstMargin,
          child: BurstButton(
            title: s.ankirenPlayLevel(level),
            sub: s.sub?.ankirenPlayLevel(level).toUpperCase(),
            onTap: fits ? () => startAnkirenFree(context, setup) : null,
          ),
        ),
      ]),
    );
  }
}

/// A level's facts across the panel: the level, as the button to every
/// level, then the cards a side and the memorise time, split by an ink
/// rule, their labels and values in line with the level's.
class _Stats extends StatelessWidget {
  const _Stats(this.setup);

  final AnkirenSetup setup;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    return Padding(
      padding: AnkirenPageLayout.statsPadding,
      child: _CellRow(firstRuled: false, fills: true, children: [
        _LevelButton(setup.level!),
        _Cell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: _Label(s.ankirenCards, null),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.statSuffixFont, height: 1),
            numberStyle: big,
          ),
        ),
        _Cell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: _Label(s.ankirenMemoriseLabel, null),
          value: Text(formatMinutes(setup.memorise), style: big),
        ),
      ]),
    );
  }
}

/// The [level]'s cell in a boxed button with a drop mark, a full touch
/// target tall: it opens free play's menu of every level
/// ([openAnkirenFree]).
class _LevelButton extends StatelessWidget {
  const _LevelButton(this.level);

  final int level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AnkirenPageLayout.levelButtonHeight),
      child: InkButton(
        onTap: () => openAnkirenFree(context),
        border: Strokes.control,
        padding: const EdgeInsets.symmetric(
            horizontal: AnkirenPageLayout.levelButtonPadding, vertical: AnkirenPageLayout.levelButtonInset),
        alignment: Alignment.centerLeft,
        semanticLabel: s.ankirenAllLevels,
        child: _Cell(
          label: _Label(s.ankirenLevelRow, null),
          value: Row(mainAxisSize: MainAxisSize.min, children: [
            NumberedText(
              s.ankirenLevelValue,
              [level],
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1),
              numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1),
            ),
            const SizedBox(width: AnkirenPageLayout.levelMarkGap),
            const Text(
              AnkirenPageLayout.levelMark,
              style: TextStyle(fontSize: AnkirenPageLayout.levelMarkFont, height: 1, color: Palette.ink),
            ),
          ]),
        ),
      ),
    );
  }
}

/// What clears [setup]'s level (or that every level is, once [allCleared],
/// with a checked "Cleared" on the right), or, when the known cards do not
/// [fits] it, how many it needs.
class _Hint extends StatelessWidget {
  const _Hint(this.setup, {required this.fits, required this.allCleared});

  final AnkirenSetup setup;
  final bool fits, allCleared;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.hintNumber, color: Palette.ink);
    final Widget why;
    if (!fits) {
      why = Row(mainAxisSize: MainAxisSize.min, children: [
        MangaIcon(IconArt.lock,
            size: AnkirenPageLayout.hintIcon, color: Palette.mute, strokeWidth: AnkirenPageLayout.hintIconStroke),
        const SizedBox(width: AnkirenPageLayout.hintGap),
        Flexible(
          child: NumberedText(s.ankirenLevelFrom, [setup.level!, setup.cards], style: style, numberStyle: number),
        ),
      ]);
    } else if (allCleared) {
      why = Text(s.ankirenAllCleared, style: style);
    } else {
      why = Row(mainAxisSize: MainAxisSize.min, children: [
        const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenPageLayout.hintCard),
        const SizedBox(width: AnkirenPageLayout.hintGap),
        Flexible(
          child: NumberedText(s.ankirenClearRule, [AnkirenTuning.strikesOut], style: style, numberStyle: number),
        ),
      ]);
    }
    return Padding(
      padding: AnkirenPageLayout.hintPadding,
      child: Row(children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: why)),
        if (allCleared) ...[
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
