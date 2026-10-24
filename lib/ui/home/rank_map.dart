import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../rank/rank_screen.dart';
import '../stats/practice_calendar.dart';
import '../tour/tour_anchor.dart';
import 'home_widgets.dart';

/// The class ladder as islands: one per class, Novice to A, each with a
/// journey island's coast ([RankMapStyle.coasts]), in map units above the
/// map's foot (y 0, where the cards at its foot start).
abstract final class RankCharts {
  /// Before the first ranked run: the whole ladder in two rows.
  static final Archipelago overview = _chart([
    for (var i = 0; i < Rating.bands.length; i++)
      _place(
        i,
        i < RankMapStyle.overviewRow
            ? RankMapStyle.overviewLeft + i * RankMapStyle.overviewStep
            : RankMapStyle.overviewHighRight - (i - RankMapStyle.overviewRow) * RankMapStyle.overviewStep,
        i < RankMapStyle.overviewRow ? RankMapStyle.overviewLow : RankMapStyle.overviewHigh,
        RankMapStyle.overviewScale,
        RankMapStyle.overviewPlateFont,
        RankMapStyle.overviewPlateGap,
      ),
  ]);

  /// Once placed: the ladder in one row.
  static final Archipelago row = _chart([
    for (var i = 0; i < Rating.bands.length; i++)
      _place(i, i * RankMapStyle.rowStep, i.isOdd ? RankMapStyle.rowHigh : RankMapStyle.rowLow, RankMapStyle.rowScale,
          MapStyle.plateFont, RankMapStyle.rowPlateGap),
  ]);

  static Archipelago _chart(List<IslandShape> islands) {
    final bounds = islands.map((i) => i.bounds).reduce((a, b) => a.expandToInclude(b));
    return Archipelago(bounds.size, islands);
  }

  /// Class [index]'s island centred on [x], [scale] times its size, its
  /// bottom [bottom] above the foot and its plate (in [plateFont]) [plateGap]
  /// under it.
  static IslandShape _place(int index, double x, double bottom, double scale, double plateFont, double plateGap) {
    final coast = archipelago.islands[RankMapStyle.coasts[index]];
    final at = Offset(x - (coast.bounds.center.dx - coast.center.dx) * scale,
        -bottom - (coast.bounds.bottom - coast.center.dy) * scale);
    final plate = plateFont + MapStyle.plateExtraHeight;
    return coast.placed(index, at, scale, label: Offset(x, plateGap + plate / 2 - bottom));
  }
}

/// All-known Home's rank map, built like journey Home's islands map: the
/// class ladder as islands, the player's class ringed with the next marked
/// and the boat between them, the classes reached flagged and the rest
/// still shoals. Before the first ranked run it shows the whole ladder,
/// with A as the goal. The known-card speed sits at the top right, and the
/// rating and the streak at its foot. A tap opens the rank ladder; the
/// streak opens the practice calendar.
class RankMap extends StatelessWidget {
  const RankMap({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final s = S.of(context);
    final rating = progress.rating;
    final speed = progress.knownCardSpeedMs;
    final corner = speed == null
        ? DashedBox(
            border: Strokes.label,
            padding: HomeLayout.mapMistPadding,
            child: Text(
              s.rankClasses(Rating.bands.length),
              style: const TextStyle(fontSize: HomeLayout.mapMistFont, fontWeight: Weights.black),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.label)),
            child: Padding(
              padding: RankMapLayout.cornerPadding,
              child: KnownSpeedTag(ms: speed, weekAgoMs: progress.knownCardSpeedTrendAgo),
            ),
          );
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, KnownHomeLayout.slant)),
      art: const [SeaLayer(RankMapStyle.seaSeed)],
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openRank(context),
                  child: _Ladder(rating == null ? -1 : Rating.bands.indexOf(Rating.bandOf(rating))),
                ),
              ),
              Padding(
                padding: RankMapLayout.footMargin,
                child: TourAnchor(TourSpot.rank, child: _Foot(rating: rating, streak: progress.streak)),
              ),
            ],
          ),
          Positioned(
            left: HomeLayout.mapLabelInsets.left,
            top: HomeLayout.mapLabelInsets.top,
            child: InkBanner(s.rankBanner, fontSize: RankMapLayout.bannerFont),
          ),
          Positioned(
            right: HomeLayout.mapLabelInsets.right,
            top: HomeLayout.mapLabelInsets.top + Strokes.label,
            child: corner,
          ),
        ],
      ),
    );
  }
}

void _openRank(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const RankScreen()));

/// The ladder's islands, panned to the player's class [current] (-1 before
/// the first ranked run, which shows the whole ladder). They scale with the
/// map's width, or smaller in a map too short for them under its labels.
class _Ladder extends StatelessWidget {
  const _Ladder(this.current);
  final int current;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final placed = current >= 0;
    final chart = placed ? RankCharts.row : RankCharts.overview;
    final islands = chart.islands;
    final last = islands.length - 1;
    final harbour = placed ? RankMapStyle.rowHarbour : RankMapStyle.overviewHarbour;
    final boat = placed
        ? IslandMap.boatPosition(islands, math.min(current + 1, last))
        : Offset.lerp(islands.first.center + harbour, islands.first.center, MapStyle.boatAlong)!;
    final route = IslandRoute(current, harbour: harbour, stop: current == last ? null : boat);
    final reach = -islands.map((i) => i.bounds.top).reduce(math.min);
    final labels = _labelsBottom(MediaQuery.textScalerOf(context));
    return LayoutBuilder(builder: (context, box) {
      final fit = box.maxWidth / RankMapStyle.designWidth;
      final scale = math.min(fit, math.max(0.0, box.maxHeight - labels) / reach);
      final width = box.maxWidth / scale, height = box.maxHeight / scale;
      final focus = current == last ? RankMapStyle.rowFocusTop : RankMapStyle.rowFocus;
      final left = placed
          ? islands[current].bounds.center.dx - focus * fit / scale
          : (RankMapStyle.designWidth - width) / 2;
      final viewport = Rect.fromLTWH(left, -height, width, height);
      final plates = viewport.deflate(RankMapStyle.plateEdge);
      bool plated(IslandShape isl) => plates.left <= isl.label.dx && isl.label.dx <= plates.right;
      return IslandMap(
        chart: chart,
        styles: [for (final isl in islands) _styleOf(s, isl.index, placed, plated(isl))],
        viewport: viewport,
        route: route,
        boat: boat,
        sea: false,
        tideColor: Palette.paper,
      );
    });
  }

  /// How far down the map the banner over its top reaches, with a gap.
  static double _labelsBottom(TextScaler text) =>
      HomeLayout.mapLabelInsets.top +
      text.scale(RankMapLayout.bannerFont) * TagStyle.bannerLineHeight +
      TagStyle.bannerPadding.vertical * RankMapLayout.bannerFont / TagStyle.bannerFont +
      RankMapStyle.labelsGap;

  /// Class [i]: flagged land once passed; ringed, its plate pink, where the
  /// player is; a shoal ahead, the next one marked NEXT. The goal, A, has a
  /// star on its plate before the first ranked run and once reached. Only
  /// [plated] islands get a plate, so none is cut by the map's sides.
  IslandStyle _styleOf(S s, int i, bool placed, bool plated) {
    final last = Rating.bands.length - 1;
    final name = s.className(Rating.bands[i]);
    final font = placed ? MapStyle.plateFont : RankMapStyle.overviewPlateFont;
    final goal = i == last && (!placed || current == last) ? MapArt.star : null;
    final flag = placed && (i < current || current == last);
    if (placed && i < current) {
      return IslandStyle(
        flag: flag,
        plate: plated ? IslandPlate(name: name, background: Palette.land, fontSize: font) : null,
      );
    }
    if (i == current) {
      return IslandStyle(
        flag: flag,
        pulse: true,
        plate: plated
            ? IslandPlate(name: name, background: Palette.pink, emphasis: true, mark: goal, fontSize: font)
            : null,
      );
    }
    final next = placed && i == current + 1;
    return IslandStyle(
      look: IslandLook.shoal,
      plate: plated
          ? IslandPlate(
              name: name,
              dashed: true,
              chip: next ? s.nextChip : null,
              chipBackground: Palette.sun,
              mark: goal,
              fontSize: font,
            )
          : null,
    );
  }
}

/// The rating and the streak side by side at the map's foot, their text
/// growing with the font scale only so far.
class _Foot extends StatelessWidget {
  const _Foot({required this.rating, required this.streak});
  final double? rating;
  final int streak;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: RankMapLayout.maxTextScale,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: RankMapLayout.ratingFlex, child: _RatingCard(rating)),
              const SizedBox(width: RankMapLayout.cardGap),
              Expanded(flex: RankMapLayout.streakFlex, child: _StreakCard(streak)),
            ],
          ),
        ),
      );
}

/// A card at the map's foot: white with a hard shadow.
class _FootCard extends StatelessWidget {
  const _FootCard({required this.onTap, required this.semanticLabel, required this.child});

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: Press.panelScale,
        turn: 0,
        semanticLabel: semanticLabel,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            border: Border.all(color: Palette.ink, width: RankMapLayout.cardBorder),
            boxShadow: const [BoxShadow(color: Palette.ink, offset: RankMapLayout.cardShadow)],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: RankMapLayout.cardMinHeight),
            child: child,
          ),
        ),
      );
}

/// The class stamp, the rating with its bar toward the next class and the
/// points to it; before the first ranked run, that it sets the rank.
class _RatingCard extends StatelessWidget {
  const _RatingCard(this.rating);
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = this.rating;
    return _FootCard(
      onTap: () => _openRank(context),
      semanticLabel: s.rank,
      child: Padding(
        padding: RankMapLayout.ratingPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: RankMapLayout.stampSlot),
              child: Align(
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: const Offset(0, -RankMapLayout.stampRaise),
                  child: rating == null
                      ? const UnrankedSticker(tilt: RankMapLayout.stampTilt, shadow: RankMapLayout.cardShadow)
                      : RankSticker(Rating.bandOf(rating),
                          tilt: RankMapLayout.stampTilt, shadow: RankMapLayout.cardShadow),
                ),
              ),
            ),
            const SizedBox(width: RankMapLayout.stampGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rating == null ? _unranked(s) : _rated(s, rating),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _note = TextStyle(
      fontSize: RankMapLayout.noteFont, fontWeight: Weights.bold, height: RankMapLayout.noteLineHeight);

  List<Widget> _unranked(S s) => [
        _OneLine(Text(s.rankUnplaced,
            style: const TextStyle(
                fontFamily: Fonts.display, fontSize: RankMapLayout.unrankedFont, height: TypeScale.displayLineHeight))),
        Text(s.rankFirstRun, style: _note),
      ];

  List<Widget> _rated(S s, double rating) {
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : 0.0;
    final fraction = next == null ? 1.0 : (rating - floor) / (next.minRating - floor);
    const bold = TextStyle(fontWeight: Weights.black);
    return [
      Text(
        s.ratingLabel,
        style: const TextStyle(
          fontSize: RankMapLayout.labelFont,
          fontWeight: Weights.black,
          letterSpacing: RankMapLayout.labelTracking * RankMapLayout.labelFont,
          height: 1,
        ),
      ),
      const SizedBox(height: RankMapLayout.labelGap),
      _OneLine(Text(
        rating.round().toString(),
        style: const TextStyle(fontFamily: Fonts.display, fontSize: RankMapLayout.ratingFont, height: 1),
      )),
      const SizedBox(height: RankMapLayout.barGap),
      RatingBar(fraction, width: double.infinity),
      const SizedBox(height: RankMapLayout.barGap),
      _OneLine(next == null
          ? Text(s.topBand, style: _note.merge(bold))
          : NumberedText(
              s.toNextBand.replaceAll('{band}', s.className(next)),
              [(next.minRating - rating).ceil(), next.minRating.round()],
              style: _note,
              numberStyle: bold,
            )),
    ];
  }
}

/// The streak as 正 tally marks over its length in days.
class _StreakCard extends StatelessWidget {
  const _StreakCard(this.days);
  final int days;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _FootCard(
      onTap: () => openPracticeCalendar(context),
      semanticLabel: s.streakDays.replaceAll('{0}', '$days'),
      child: Padding(
        padding: RankMapLayout.streakPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: RankMapLayout.tallyWidth,
              child: FittedBox(child: TallyMarks(days)),
            ),
            const SizedBox(height: RankMapLayout.streakGap),
            _OneLine(
              NumberedText(
                s.streakDays,
                [days],
                style: const TextStyle(fontSize: RankMapLayout.streakFont, fontWeight: Weights.black, height: 1),
                numberStyle: const TextStyle(
                    fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: RankMapLayout.streakNumber),
              ),
              alignment: Alignment.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// [child]'s text on one line, shrunk to fit. Measured on one line too, so
/// the cards around it are as tall as it shows.
class _OneLine extends StatelessWidget {
  const _OneLine(this.child, {this.alignment = Alignment.centerLeft});
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: DefaultTextStyle.merge(softWrap: false, child: child),
      );
}
