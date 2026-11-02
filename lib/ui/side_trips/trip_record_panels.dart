import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../domain/trip_rating.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';

/// A trip page's [StatStrip], for a player of [entry]'s standing: the class
/// and the rating with the last game's change (unranked before the first),
/// then how many points the next class is away, with a gauge; and any
/// [more] cells and [moreFoot] line of the trip's own. While the rating is
/// still being placed there is no class yet: its box says so, and the gauge
/// keeps its room but is hidden.
class RecordStrip extends StatelessWidget {
  const RecordStrip(this.entry, {super.key, this.more = const [], this.moreFoot});

  final SideTripEntry entry;
  final List<Widget> more;
  final Widget? moreFoot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final band = entry.band;
    final rating = entry.rating;
    final at = rating ?? TripRating.start;
    final next = Rating.nextBand(at);
    final floor = band.minRating.isFinite ? band.minRating : TripRating.start;
    final change = entry.ratingChange?.round() ?? 0;
    final moreFoot = this.moreFoot;
    final placement = TripRating.isPlacement(entry.results.length);
    const big = StatStrip.valueStyle;
    final bar = next == null
        ? null
        : Row(children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: NumberedText(
                  s.ratingToNext(s.className(next)),
                  [(next.minRating - at).ceil()],
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.gaugeFont),
                  numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.gaugeNumber),
                ),
              ),
            ),
            const SizedBox(width: AnkirenPageLayout.gaugeGap),
            Expanded(child: RatingBar((at - floor) / (next.minRating - floor), width: double.infinity)),
          ]);
    final gauge = bar == null || !placement
        ? bar
        : Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: bar);
    return StatStrip(
      fills: more.isNotEmpty,
      cells: [
        StatCell(
          label: PanelLabel(s.sideTripClass, more.isEmpty ? s.sub?.sideTripClass : null),
          value: placement
              ? const Text(AnkirenPageLayout.placementClass, style: big)
              : Text.rich(
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
          label: PanelLabel(s.rating, more.isEmpty ? s.sub?.rating : null),
          value: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(rating == null ? s.sideTripUnranked : '${rating.round()}', style: big),
            if (change != 0) ...[
              const SizedBox(width: AnkirenPageLayout.valueGap),
              RatingChangeTag(change),
            ],
          ]),
        ),
        ...more,
      ],
      foot: gauge == null || moreFoot == null
          ? gauge ?? moreFoot
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              gauge,
              const SizedBox(height: AnkirenPageLayout.gameGap),
              moreFoot,
            ]),
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

/// A trip's ranked panel: the last ranked games (or the placement games so
/// far) and the burst that starts it ([onStart]).
/// Until ranked opens the whole panel is chained up, faded, with what still
/// opens it stuck over the chains; a tap says it again.
class RankedPanel extends StatelessWidget {
  const RankedPanel(this.entry, {super.key, required this.onStart});

  final SideTripEntry entry;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lock = entry.rankedLock;
    final placement = TripRating.isPlacement(entry.results.length);
    final heading = _Heading(placement ? s.ankirenPlacementTitle : s.ankirenLast5);
    final content = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: AnkirenPageLayout.gamesPadding,
        child: placement ? _Placement(entry.results) : _LastGames(entry.results),
      ),
      RankedRow(onTap: lock == null ? onStart : null),
    ]);
    if (lock == null) {
      return TaggedPanel(tag: s.ankirenRankedMode, sub: s.sub?.ankirenRankedMode, heading: heading, child: content);
    }
    return LockedPanel(
      tag: s.ankirenRankedMode,
      sub: s.sub?.ankirenRankedMode,
      heading: heading,
      why: s.ankirenRankedLocked(allKnown: lock.allKnown, cleared: lock.cleared, level: lock.level),
      child: content,
    );
  }
}
