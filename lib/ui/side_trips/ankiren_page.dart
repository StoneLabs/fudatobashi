import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
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
import 'ankiren_free_sheet.dart';
import 'ankiren_rules_sheet.dart';
import 'burst_button.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';

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
/// level to clear, or the setup picked instead, in a larger panel with its
/// facts, what clears it, a preview of its field, the way to the level
/// sheet ([pickAnkirenFree]) and the burst that starts it. Guest mode
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
  /// The setup picked from the level sheet, kept while the page is open;
  /// null for the next level to clear.
  AnkirenSetup? _picked;

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
                    Expanded(child: Align(alignment: Alignment.bottomCenter, child: _NextLevelPanel(
                      entry,
                      picked: _picked,
                      onPick: (setup) => setState(() => _picked = setup),
                    ))),
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
            child: CellRow(children: [
              StatCell(
                label: PanelLabel(s.sideTripClass, s.sub?.sideTripClass),
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
              StatCell(
                label: PanelLabel(s.rating, s.sub?.rating),
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
      Semantics(header: true, child: PanelLabel(title, null, fontSize: AnkirenPageLayout.headFont));
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
        PanelLabel(s.ankirenPlacementNext, s.sub?.ankirenPlacementNext, color: AnkirenPageLayout.todo)
      else
        const Text('—', style: style),
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
      RankedRow(
        facts: s.ankirenRankedFacts(AnkirenTuning.rankedPerSide, formatMinutes(AnkirenTuning.rankedMemorise)),
        line: s.ankirenRankedReal,
        onTap: lock == null ? () => startAnkirenRanked(context) : null,
      ),
    ]);
    if (lock == null) {
      return TaggedPanel(tag: s.ankirenRankedMode, sub: s.sub?.ankirenRankedMode, heading: heading, child: content);
    }
    return LockedPanel(
      tag: s.ankirenRankedMode,
      sub: s.sub?.ankirenRankedMode,
      heading: heading,
      why: s.ankirenRankedLocked(allKnown: lock.allKnown, cleared: lock.cleared, level: RankedLock.level),
      child: content,
    );
  }
}

/// Free play's next level to clear (the top level again once every level
/// is cleared), or the setup [picked] instead under Free play's tag: its
/// facts, the level among them the way to the level sheet, what clears it
/// (or that a custom game is not scored, or what the known cards still
/// lack), a preview of its field, and the burst that starts it. A setup
/// confirmed in the sheet goes to [onPick], as null when it is the next
/// level to clear.
class _NextLevelPanel extends StatelessWidget {
  const _NextLevelPanel(this.entry, {required this.picked, required this.onPick});

  final SideTripEntry entry;
  final AnkirenSetup? picked;
  final ValueChanged<AnkirenSetup?> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final next = entry.nextLevel;
    final usual = AnkirenSetup.forLevel(next ?? AnkirenLevels.top);
    final setup = picked ?? usual;
    final level = setup.level;
    final fits = level == null || entry.fits(level);
    final allCleared = picked == null && next == null;
    String tag(S s) => picked != null
        ? s.freePlay
        : allCleared
            ? s.ankirenAllClearedTitle
            : s.ankirenNextToClear;
    String play(S s) => level == null ? s.freeStart : s.ankirenPlayLevel(level);
    Future<void> pick() async {
      final chosen = await pickAnkirenFree(context, setup);
      if (chosen != null && context.mounted) onPick(chosen == usual ? null : chosen);
    }

    return TaggedPanel(
      tag: tag(s),
      sub: s.sub == null ? null : tag(s.sub!),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Stats(setup, onLevel: pick),
        _Hint(setup, fits: fits, allCleared: allCleared, cleared: level != null && entry.ladder.isCleared(level)),
        Flexible(child: AnkirenFieldPreview(setup)),
        Padding(
          padding: AnkirenPageLayout.burstMargin,
          child: BurstButton(
            title: play(s),
            sub: s.sub == null ? null : play(s.sub!).toUpperCase(),
            onTap: fits ? () => startAnkirenFree(context, setup) : null,
          ),
        ),
      ]),
    );
  }
}

/// A setup's facts across the panel: the level, as the button that calls
/// [onLevel], then the cards a side and the memorise time, split by an ink
/// rule, their labels and values in line with the level's.
class _Stats extends StatelessWidget {
  const _Stats(this.setup, {required this.onLevel});

  final AnkirenSetup setup;
  final VoidCallback onLevel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    return Padding(
      padding: AnkirenPageLayout.statsPadding,
      child: CellRow(firstRuled: false, fills: true, children: [
        _LevelButton(setup.level, onTap: onLevel),
        StatCell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: PanelLabel(s.ankirenCards, null),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.statSuffixFont, height: 1),
            numberStyle: big,
          ),
        ),
        StatCell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: PanelLabel(s.ankirenMemoriseLabel, null),
          value: Text(formatMinutes(setup.memorise), style: big),
        ),
      ]),
    );
  }
}

/// The [level]'s cell (Custom when null) as the button that calls [onTap].
class _LevelButton extends StatelessWidget {
  const _LevelButton(this.level, {required this.onTap});

  final int? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DropCellButton(
      onTap: onTap,
      semanticLabel: s.ankirenAllLevels,
      label: PanelLabel(s.ankirenLevelRow, null),
      value: level == null
          ? Text(s.ankirenCustom,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1))
          : NumberedText(
              s.ankirenLevelValue,
              [level!],
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1),
              numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1),
            ),
    );
  }
}

/// What clears [setup]'s level (or that every level is, once [allCleared];
/// or that a custom setup is not scored), with a checked "Cleared" on the
/// right once it is [cleared]; or, when the known cards do not [fits] it,
/// how many it needs.
class _Hint extends StatelessWidget {
  const _Hint(this.setup, {required this.fits, required this.allCleared, required this.cleared});

  final AnkirenSetup setup;
  final bool fits, allCleared, cleared;

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
    } else if (setup.custom) {
      why = Text.rich(Phrases.span(s.ankirenCustomNote), style: style);
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
