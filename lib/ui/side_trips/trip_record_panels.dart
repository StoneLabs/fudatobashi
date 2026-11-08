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

/// A trip page's [ClassStrip], for a player of [entry]'s standing, with
/// any [more] cells and [moreFoot] line of the trip's own.
class RecordStrip extends StatelessWidget {
  const RecordStrip(this.entry, {super.key, this.more = const [], this.moreFoot});

  final SideTripEntry entry;
  final List<Widget> more;
  final Widget? moreFoot;

  @override
  Widget build(BuildContext context) => ClassStrip(
        rating: entry.rating,
        change: entry.ratingChange,
        placing: TripRating.isPlacement(entry.results.length),
        unratedAt: TripRating.start,
        more: more,
        moreFoot: moreFoot,
      );
}

/// A [StatStrip] for a player on the shared class scale ([Rating.bands]):
/// the class and the [rating] with the last [change] (unranked before the
/// first), then how many points the next class is away, with a gauge; and
/// any [more] cells and [moreFoot] line of the page's own. While the rating
/// is still being placed ([placing]) there is no class yet: its box says
/// so, and the gauge keeps its room (as at [unratedAt]) but is hidden.
class ClassStrip extends StatelessWidget {
  const ClassStrip({
    super.key,
    required this.rating,
    required this.change,
    required this.placing,
    required this.unratedAt,
    this.more = const [],
    this.moreFoot,
  });

  final double? rating, change;
  final bool placing;
  final double unratedAt;
  final List<Widget> more;
  final Widget? moreFoot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = this.rating;
    final band = rating == null ? Rating.bands.first : Rating.bandOf(rating);
    final at = rating ?? unratedAt;
    final next = Rating.nextBand(at);
    final floor = band.minRating.isFinite ? band.minRating : unratedAt;
    final change = this.change?.round() ?? 0;
    final moreFoot = this.moreFoot;
    final placement = placing;
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
class PanelHeading extends StatelessWidget {
  const PanelHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: PanelLabel(title, null, fontSize: AnkirenPageLayout.headFont));
}

/// Games side by side in equal columns, split by light rules.
class GameRow extends StatelessWidget {
  const GameRow(this.cells, {super.key});

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
    return GameRow([
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
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GameRow([
      for (var i = 0; i < AnkirenRatingModel.placementGames; i++)
        if (i < results.length)
          _Game(results[i])
        else
          PlacementSlot(i + 1,
              next: i == results.length ? (s.ankirenPlacementNext, s.sub?.ankirenPlacementNext) : null),
    ]);
  }
}

/// A placement game still to play: its [number] in a dashed slot, over
/// the [next] label (and its other-language sub) for the next one, or a
/// dash.
class PlacementSlot extends StatelessWidget {
  const PlacementSlot(this.number, {super.key, required this.next});

  final int number;
  final (String, String?)? next;

  @override
  Widget build(BuildContext context) {
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
      if (next case (final text, final sub))
        PanelLabel(text, sub, color: AnkirenPageLayout.todo)
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
    final heading = PanelHeading(placement ? s.ankirenPlacementTitle : s.ankirenLast5);
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
