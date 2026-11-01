import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../db/database.dart' show SideTripRun;
import '../../domain/ankiren_review.dart';
import '../../domain/level_ladder.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi_review.dart';
import '../../domain/trip_rating.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_review_strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../manga/swipe_tabs.dart';
import '../play/time_format.dart';
import '../stats/practice_calendar.dart';
import 'ankiren_game_page.dart';
import 'history_filter.dart';
import 'history_widgets.dart';
import 'run_page.dart';
import 'teiichi_game_page.dart';

/// Opens History as a page of its own on [trip]'s tab, with a back button.
Future<void> openTripHistory(BuildContext context, SideTrip trip) =>
    Navigator.of(context).push(MangaRoute<void>(
      builder: (context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: GradationBox(Tones.history)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: HeaderStyle.topGap),
              child: HistoryScreen(trip: trip, onBack: () => Navigator.maybePop(context)),
            ),
          ),
        ]),
      ),
    ));

/// The History tab: the last 7 days and the streak (D2) over three swiped
/// lists (D3), the main game's runs by day, 暗記練's games and 定位置's,
/// narrowed by the filter sheet (D43). A run opens its own page. On
/// [trip]'s tab at first if given; as a page of its own the header has a
/// back button ([onBack]).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.trip, this.onBack});

  final SideTrip? trip;
  final VoidCallback? onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  var _filter = const HistoryFilter();
  late var _list = switch (widget.trip) {
    final trip? => HistoryList.of(trip),
    null => HistoryList.main,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final today = progress.dayAt().date;
    final activity = progress.dayActivity;
    final runs = progress.pastRuns;
    final games = progress.ankirenRuns;
    final placings = progress.teiichiRuns;
    List<PastRun> keptRuns(HistoryFilter f) => [
          for (final r in runs)
            if (f.keepsRun(r, progress.dayOf(r.row), today)) r,
        ];
    List<SideTripRun> keptGames(HistoryFilter f) => [
          for (final g in games)
            if (f.keepsGame(g, progress.dayOfGame(g), today)) g,
        ];
    List<SideTripRun> keptPlacings(HistoryFilter f) => [
          for (final g in placings)
            if (f.keepsPlacing(g, progress.dayOfGame(g), today)) g,
        ];
    int kept(HistoryFilter f) => switch (_list) {
          HistoryList.main => keptRuns(f).length,
          HistoryList.ankiren => keptGames(f).length,
          HistoryList.teiichi => keptPlacings(f).length,
        };
    final active = _filter.activeOn(_list);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(
            title: ScreenTitle(s.history, sub: s.other.history),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkIconButton(
                    icon: IconArt.filter,
                    semanticLabel: s.historyFilterLabel,
                    onTap: () async {
                      final picked = await showHistoryFilter(context, filter: _filter, list: _list, count: kept);
                      if (picked != null && mounted) setState(() => _filter = picked);
                    },
                  ),
                  if (active > 0) Positioned(right: -Gaps.small, top: -Gaps.small, child: CountBadge(active)),
                ],
              ),
              if (widget.onBack case final onBack?) InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: onBack),
            ],
          ),
          _WeekStrip(activity: activity, today: today, streak: progress.activeStreak()),
          const SizedBox(height: HistoryListStyle.tabGap),
          Expanded(
            child: SwipeTabs(
              look: SwipeTabsLook.folders,
              initial: _list.index,
              onChanged: (i) => setState(() => _list = HistoryList.values[i]),
              tabs: [
                SwipeTab(
                  label: s.historyMainTab,
                  sub: s.sub?.historyMainTab,
                  builder: (_) => _DayList<PastRun>(
                    items: keptRuns(_filter),
                    dayOf: (r) => progress.dayOf(r.row),
                    rowOf: _RunRow.new,
                    empty: runs.isEmpty ? s.noRunsYet : s.historyNoMatch,
                    status: (day, dayRuns) => _MainDayStatus(day: day, runs: dayRuns, activity: activity[day] ?? DayActivity.some),
                  ),
                ),
                SwipeTab(
                  label: s.historyAnkirenTab,
                  accent: HistoryLooks.ankiren.accent,
                  sub: s.sub?.historyAnkirenTab,
                  builder: (_) => _DayList<SideTripRun>(
                    items: keptGames(_filter),
                    dayOf: progress.dayOfGame,
                    rowOf: (g) => _GameRow(g, all: games),
                    empty: games.isEmpty ? s.noRunsYet : s.historyNoMatch,
                  ),
                ),
                SwipeTab(
                  label: s.historyTeiichiTab,
                  accent: HistoryLooks.teiichi.accent,
                  sub: s.sub?.historyTeiichiTab,
                  builder: (_) {
                    final trips = progress.sideTrips;
                    final records = [for (final g in placings) trips.teiichiRecordOf(g)];
                    final byId = {for (final r in records) r.id: r};
                    return _DayList<SideTripRun>(
                      items: keptPlacings(_filter),
                      dayOf: progress.dayOfGame,
                      rowOf: (g) => _PlacingRow(g, review: TeiichiReview(byId[g.id]!, records)),
                      empty: placings.isEmpty ? s.noRunsYet : s.historyNoMatch,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// D2: the last 7 days in three colours on a cut, sun-toned panel, today
/// ringed, and the streak.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.activity, required this.today, required this.streak});
  final Map<DateTime, DayActivity> activity;
  final DateTime today;
  final int streak;

  static Color colorOf(DayActivity a) => switch (a) {
        DayActivity.none => HistoryListStyle.dayNone,
        DayActivity.some => HistoryListStyle.daySome,
        DayActivity.done => HistoryListStyle.dayDone,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    Widget swatch(DayActivity a, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          _DayMark(a, size: HistoryListStyle.legendBox),
          const SizedBox(width: Gaps.tight),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: HistoryListStyle.legendFont, color: HistoryListStyle.legendText)),
          ),
        ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MangaPanel(
          shape: const PanelShape(bottomRight: Offset(HistoryListStyle.stripCut, 0)),
          tone: Tones.sun,
          padding: HistoryListStyle.stripPadding,
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackedLabel(s.historyLast7, sub: s.sub?.historyLast7),
                      const SizedBox(height: HistoryListStyle.labelGap),
                      Row(
                        children: [
                          for (final d in days) ...[
                            if (d != days.first) const SizedBox(width: HistoryListStyle.dayGap),
                            _DayBox(day: d, activity: activity[d] ?? DayActivity.none, today: d == today),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Gaps.small),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openPracticeCalendar(context),
                  child: _Streak(streak),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HistoryListStyle.legendGap),
        Wrap(spacing: Gaps.panel, runSpacing: Gaps.tight, children: [
          swatch(DayActivity.none, s.historyNotActive),
          swatch(DayActivity.some, s.historySomeActive),
          swatch(DayActivity.done, s.historyDoneActive),
        ]),
      ],
    );
  }
}

/// The streak: the day count, big, with a pink drop shadow while it runs,
/// over "days in a row".
class _Streak extends StatelessWidget {
  const _Streak(this.days);
  final int days;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final going = days > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$days',
            style: TextStyle(
              fontFamily: Fonts.display,
              fontSize: HistoryListStyle.streakFont,
              height: 1,
              color: going ? Palette.ink : HistoryRunStyle.muted,
              shadows: going ? const [Shadow(color: Palette.pink, offset: HistoryListStyle.streakShadow)] : null,
            )),
        const SizedBox(height: Gaps.tight),
        Text(s.historyStreak(days), style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryListStyle.streakLabelFont)),
        if (s.sub?.historyStreak(days) case final sub?)
          Text(sub.toUpperCase(),
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: HistoryListStyle.streakSubFont,
                  letterSpacing: HistoryRunStyle.labelTracking)),
      ],
    );
  }
}

/// One day of the strip: its colour (完 when the set was done, a dot for
/// some of it) over its weekday letter; today in a pink ring.
class _DayBox extends StatelessWidget {
  const _DayBox({required this.day, required this.activity, required this.today});
  final DateTime day;
  final DayActivity activity;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(HistoryListStyle.todayRingGap),
          decoration: BoxDecoration(
            border: Border.all(
                color: today ? HistoryListStyle.today : Colors.transparent, width: HistoryListStyle.todayRing),
          ),
          child: _DayMark(activity, size: HistoryListStyle.dayBox),
        ),
        Text(s.weekdayLetter(day.weekday),
            style: TextStyle(
                fontWeight: Weights.black,
                fontSize: HistoryListStyle.dayLetterFont,
                height: 1,
                color: today ? HistoryListStyle.todayText : Palette.ink)),
      ],
    );
  }
}

/// A day's square in its colour, as in the strip: 完 when the set was
/// done, a dot for some of it, scaled to [size].
class _DayMark extends StatelessWidget {
  const _DayMark(this.activity, {required this.size});
  final DayActivity activity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scale = size / HistoryListStyle.dayBox;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _WeekStrip.colorOf(activity),
        border: Border.all(color: Palette.ink, width: Strokes.control * scale.clamp(HistoryListStyle.markMinBorder, 1)),
      ),
      child: switch (activity) {
        DayActivity.done => Text(s.historyDayDoneMark,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.dayMarkFont * scale, height: 1)),
        DayActivity.some => Container(
            width: HistoryListStyle.dayDot * scale,
            height: HistoryListStyle.dayDot * scale,
            decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
          ),
        DayActivity.none => null,
      },
    );
  }
}

/// A tab's entries grouped by practice day, newest first: a day banner
/// over the day's rows, and [status] (if given) on the banner's right.
class _DayList<T> extends StatelessWidget {
  const _DayList({required this.items, required this.dayOf, required this.rowOf, required this.empty, this.status});
  final List<T> items;
  final DateTime Function(T) dayOf;
  final Widget Function(T) rowOf;
  final String empty;
  final Widget Function(DateTime day, List<T> items)? status;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Empty(empty);
    final today = ProgressScope.of(context).dayAt().date;
    final days = <DateTime, List<T>>{};
    for (final item in items) {
      (days[dayOf(item)] ??= []).add(item);
    }
    return ListView(
      padding: const EdgeInsets.only(top: Gaps.section, bottom: HistoryListStyle.bottomPad),
      children: [
        for (final MapEntry(key: day, value: dayItems) in days.entries) ...[
          _DayHeader(day: day, today: today, trailing: status?.call(day, dayItems)),
          const SizedBox(height: Gaps.small),
          _RowsBox([for (final item in dayItems) rowOf(item)]),
          const SizedBox(height: Gaps.section),
        ],
      ],
    );
  }
}

/// The main game's day status: the day's mark and what was played.
class _MainDayStatus extends StatelessWidget {
  const _MainDayStatus({required this.day, required this.runs, required this.activity});
  final DateTime day;
  final List<PastRun> runs;
  final DayActivity activity;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final status = ProgressScope.of(context).setDoneOn(day)
        ? s.historyDayDone
        : runs.any((r) => r.allKnown)
            ? s.historyDayAllKnown
            : runs.any((r) => r.mode == PlayMode.training)
                ? s.historyDaySome
                : s.historyDayPlayed;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _DayMark(activity, size: HistoryListStyle.headerMark),
      const SizedBox(width: Gaps.tight),
      Text(status, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
    ]);
  }
}

/// A list's rows in one ink panel on a hard shadow, split by rules.
class _RowsBox extends StatelessWidget {
  const _RowsBox(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => MangaPanel(
        shadow: HistoryRunStyle.panelShadow,
        child: Column(children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: Strokes.hairline, thickness: Strokes.hairline, color: ChartStyle.grid),
            row,
          ],
        ]),
      );
}

/// D4: the day on an ink banner, and [trailing] on its right.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today, this.trailing});
  final DateTime day, today;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(children: [
                InkBanner(day == today ? s.historyToday : s.historyDay(day), fontSize: HistoryListStyle.dayHeaderFont),
                if (day == today) ...[
                  const SizedBox(width: Gaps.small),
                  Text(s.historyDay(day),
                      style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryListStyle.dayHeaderDateFont)),
                ],
              ]),
            ),
          ),
        ),
        if (trailing case final trailing?) ...[const SizedBox(width: Gaps.small), trailing],
      ],
    );
  }
}

/// One row of a list: the time of day (or date) on the left, the kind and
/// badges over a line of facts, the main number with its caption, and a
/// chevron; tapping opens the run.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.startedAt,
    required this.tags,
    required this.line,
    required this.value,
    required this.caption,
    required this.onTap,
    this.accent,
  });

  final DateTime startedAt;
  final List<Widget> tags;
  final Widget line;
  final String value, caption;
  final VoidCallback onTap;

  /// A coloured edge on the left: the run's kind, or 暗記練's pink.
  final Color? accent;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: accent == null
              ? null
              : BoxDecoration(border: Border(left: BorderSide(color: accent!, width: HistoryListStyle.accent))),
          padding: HistoryListStyle.rowPadding,
          constraints: const BoxConstraints(minHeight: HistoryListStyle.rowMinHeight),
          child: Row(
            children: [
              SizedBox(width: HistoryListStyle.rowClockWidth * MediaQuery.textScalerOf(context).scale(1), child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(S.of(context).clockTime(startedAt),
                      style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.rowClockFont)),
                ),
              ),
              const SizedBox(width: HistoryListStyle.rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: HistoryListStyle.tagGap, runSpacing: HistoryListStyle.lineGap, children: tags),
                    const SizedBox(height: HistoryListStyle.lineGap),
                    DefaultTextStyle.merge(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: Weights.bold,
                          fontSize: HistoryListStyle.rowLineFont,
                          height: HistoryListStyle.rowLineHeight,
                          color: HistoryListStyle.rowLineColor),
                      child: line,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HistoryListStyle.rowGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.rowValueFont, height: 1)),
                  const SizedBox(height: HistoryListStyle.captionGap),
                  Text(caption,
                      style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: HistoryListStyle.rowCaptionFont,
                          height: 1,
                          color: HistoryRunStyle.muted)),
                ],
              ),
              const SizedBox(width: Gaps.tight),
              SizedBox(
                width: HistoryListStyle.chevron,
                child: MangaIcon(IconArt.chevron, size: HistoryListStyle.chevron, color: HistoryRunStyle.muted),
              ),
            ],
          ),
        ),
      );
}

/// D5–D7: a main game run.
class _RunRow extends StatelessWidget {
  const _RunRow(this.run);
  final PastRun run;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final rating = progress.ratingOf(run);
    final change = progress.classChangeOf(run);
    final misses = progress.missesIn(run.id);
    final hundred = run.view == RunView.hundred;
    final cards = run.forfeit ? s.historyCardsOf(run.cards, run.planned) : s.historyCards(run.cards);
    final tags = <Widget>[
      RunKindTag(run.mode),
      if (run.placement) ResultBadge(s.historyPlaced, color: Palette.pinkSoft, cheer: true),
      if (change != null)
        change.$2.minRating > change.$1.minRating
            ? ResultBadge(s.historyUpTo(change.$2), cheer: true)
            : ResultBadge(s.historyDownTo(change.$2), muted: true),
      if (run.mode == PlayMode.exam) run.passed ? ResultBadge(s.runExamWon, cheer: true) : ResultBadge(s.runExamLost, muted: true),
      if (hundred && progress.bestOfKind(run)) ResultBadge(s.historyBest, cheer: true),
    ];
    final ratingText = rating == null
        ? null
        : rating.before == null
            ? s.historyFirstRating(rating.after.round())
            : ratingChangeText(rating.after - rating.before!);
    final up = rating != null && (rating.before == null || rating.after >= rating.before!);
    final perCard = run.clock == null || run.cards == 0 ? null : run.clock!.inMilliseconds / run.cards;
    return _ListRow(
      accent: RunKindTag.lookOf(run.mode).accent,
      startedAt: run.startedAt,
      tags: tags,
      line: Text.rich(TextSpan(children: [
        TextSpan(text: cards),
        if (run.mode == PlayMode.exam && run.tobi != null)
          TextSpan(text: ' · ${s.historyTobiTime(formatTenths(run.tobi!))}')
        else if (!run.forfeit && (misses > 0 || hundred))
          TextSpan(text: ' · ${hundred ? s.historyMissesShort(misses) : s.historyMissedShort(misses)}'),
        if (ratingText != null)
          TextSpan(
              text: ' · $ratingText',
              style: TextStyle(color: up ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ])),
      value: hundred ? runTimeText(s, run) : (perCard == null ? missingTime : '${formatSeconds(perCard)}s'),
      caption: !hundred
          ? s.historyPerCardCaption
          : run.forfeit
              ? ''
              : run.mode == PlayMode.exam
                  ? s.historyYourTimeCaption
                  : run.scored
                      ? s.historyScoredCaption
                      : s.historyTimeCaption,
      onTap: () => openRun(context, run),
    );
  }
}

/// D9: a 暗記練 game, ranked, free at a level or custom.
class _GameRow extends StatelessWidget {
  const _GameRow(this.game, {required this.all});
  final SideTripRun game;
  final List<SideTripRun> all;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final kind = AnkirenKind.of(game);
    final earlier = all.where((g) => g.startedAt.isBefore(game.startedAt));
    final previous = earlier.where((g) => g.ranked && g.rating != null).firstOrNull;
    final rating = game.rating;
    final change = game.ranked && rating != null ? rating - (previous?.rating ?? TripRating.start) : null;
    final best = game.ranked &&
        game.score != null &&
        earlier.where((g) => g.ranked).every((g) => (g.score ?? 0) < game.score!);
    final strikes = progress.sideTrips.strikesIn(game);
    final cleared = LevelLadder.clears(completed: game.completed, strikes: strikes);
    final meta = jsonDecode(game.meta) as Map<String, dynamic>;
    final cards = progress.sideTrips.cardsIn(game);
    final found = cards - progress.sideTrips.missesIn(game);
    return _ListRow(
      accent: HistoryLooks.ankiren.accent,
      startedAt: game.startedAt,
      tags: [
        _TagLine([
          AnkirenKindTag(ranked: game.ranked, level: game.level),
          if (kind == AnkirenKind.free)
            cleared ? ResultBadge(s.historyCleared, color: Palette.landSoft) : ResultBadge(s.historyFailed, muted: true),
          if (best) ResultBadge(s.historyBest, cheer: true),
        ]),
      ],
      line: Text.rich(TextSpan(children: [
        TextSpan(
            text: switch (kind) {
          AnkirenKind.ranked => s.historyCards(cards),
          AnkirenKind.free => s.ankirenStrikes(strikes),
          AnkirenKind.custom =>
            '${s.historyPerSide(meta[AnkirenMeta.perSideKey] ?? missingTime, cards)} · ${s.ankirenStrikes(strikes)}',
        }),
        if (change != null)
          TextSpan(
              text: ' · ${ratingChangeText(change)}',
              style: TextStyle(color: change >= 0 ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ])),
      value: game.ranked ? '${game.score}' : '$found/$cards',
      caption: game.ranked ? s.historyPointsCaption : s.historyFirstTapCaption,
      onTap: () => openAnkirenGame(context, game),
    );
  }
}

/// A 定位置 game: its kind, how it went (cleared, failed, forfeited or ended
/// early) and whether it set the best placing time, its cards (and rows,
/// when custom) with what it did to the rating, its strikes or its wrong
/// taps, and its score, or else its placing time.
class _PlacingRow extends StatelessWidget {
  const _PlacingRow(this.run, {required this.review});
  final SideTripRun run;
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final setup = game.setup;
    final after = run.rating;
    final change = after == null ? null : after - (review.recall.ratingBefore ?? TripRating.start);
    final cards = game.custom ? s.teiichiSetupLine(setup.cards, setup.rows) : s.historyCards(setup.cards);
    return _ListRow(
      accent: HistoryLooks.teiichi.accent,
      startedAt: run.startedAt,
      tags: [
        _TagLine([
          KindTag(teiichiKindLabel(s, game), look: HistoryLooks.teiichi),
          if (game.forfeit)
            ResultBadge(s.historyForfeit, muted: true)
          else if (game.cleared)
            ResultBadge(s.historyCleared, color: Palette.landSoft)
          else if (game.level != null)
            ResultBadge(s.historyFailed, muted: true)
          else if (!game.completed)
            ResultBadge(s.endedEarly, muted: true),
          if (review.isBest) ResultBadge(s.historyBest, cheer: true),
        ]),
      ],
      line: Text.rich(TextSpan(children: [
        TextSpan(
            text: [
          cards,
          if (game.level != null) s.ankirenStrikes(game.strikes) else if (!game.ranked) s.historyWrongTaps(game.wrongTaps),
        ].join(' · ')),
        if (change != null)
          TextSpan(
              text: ' · ${ratingChangeText(change)}',
              style: TextStyle(color: change >= 0 ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ])),
      value: game.ranked ? '${run.score}' : formatMinutes(game.placing),
      caption: game.ranked ? s.historyPointsCaption : s.historyPlacingCaption,
      onTap: () => openTeiichiGame(context, run),
    );
  }
}

/// [tags] on one line, the first shrinking to leave room for the rest, so
/// every side-trip row is as tall as the others.
class _TagLine extends StatelessWidget {
  const _TagLine(this.tags);
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: tags.first)),
        for (final tag in tags.skip(1)) ...[const SizedBox(width: HistoryListStyle.tagGap), tag],
      ]);
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: DashedBox(
          padding: HistoryLayout.emptyPadding,
          child: Text(text, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
        ),
      );
}
