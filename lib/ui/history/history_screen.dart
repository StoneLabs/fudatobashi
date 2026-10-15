import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../db/database.dart' show SideTripRun;
import '../../domain/ankiren_rating.dart';
import '../../domain/ankiren_review.dart';
import '../../domain/side_trips.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../manga/swipe_tabs.dart';
import '../play/time_format.dart';
import 'ankiren_game_page.dart';
import 'history_filter.dart';
import 'history_widgets.dart';
import 'run_page.dart';

/// Opens History as a page of its own on [trip]'s tab, with a back button.
Future<void> openTripHistory(BuildContext context, SideTrip trip) =>
    Navigator.of(context).push(MangaRoute<void>(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: HeaderStyle.topGap),
            child: HistoryScreen(trip: trip, onBack: () => Navigator.maybePop(context)),
          ),
        ),
      ),
    ));

/// The History tab: the last 7 days and the streak (D2) over two swiped
/// lists (D3), the main game's runs by day and 暗記練's games, narrowed by
/// the filter sheet (D43). A run opens its own page. On [trip]'s tab at
/// first if given; as a page of its own the header has a back button
/// ([onBack]).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.trip, this.onBack});

  final SideTrip? trip;
  final VoidCallback? onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  var _filter = const HistoryFilter();
  late var _tab = widget.trip == null ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final today = progress.dayAt().date;
    final activity = progress.dayActivity;
    final runs = progress.pastRuns;
    final games = progress.ankirenRuns;
    List<PastRun> keptRuns(HistoryFilter f) => [
          for (final r in runs)
            if (f.keepsRun(r, progress.dayOf(r.session), today)) r,
        ];
    List<SideTripRun> keptGames(HistoryFilter f) => [
          for (final g in games)
            if (f.keepsGame(g, progress.dayOfGame(g), today)) g,
        ];
    final active = _filter.activeOn(ankiren: _tab == 1);
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
                      final picked = await showHistoryFilter(
                        context,
                        filter: _filter,
                        ankiren: _tab == 1,
                        count: (f) => _tab == 1 ? keptGames(f).length : keptRuns(f).length,
                      );
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
              initial: _tab,
              onChanged: (i) => setState(() => _tab = i),
              tabs: [
                SwipeTab(
                  label: s.historyMainTab,
                  sub: s.sub?.historyMainTab,
                  builder: (_) => _MainList(runs: keptRuns(_filter), activity: activity, today: today),
                ),
                SwipeTab(
                  label: s.historyAnkirenTab,
                  accent: Palette.pink,
                  sub: s.sub?.historyAnkirenTab,
                  builder: (_) => _AnkirenList(games: keptGames(_filter), all: games),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// D2: the last 7 days in three colours, today ringed, and the streak.
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
          Container(
            width: HistoryListStyle.legendBox,
            height: HistoryListStyle.legendBox,
            decoration: BoxDecoration(color: colorOf(a), border: Border.all(color: Palette.ink, width: 1)),
          ),
          const SizedBox(width: Gaps.tight),
          Flexible(
            child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont)),
          ),
        ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MangaPanel(
          color: Palette.sunSoft,
          padding: HistoryListStyle.stripPadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrackedLabel(s.historyLast7, sub: s.other.historyLast7),
                    const SizedBox(height: Gaps.tight),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          for (final d in days) ...[
                            if (d != days.first) const SizedBox(width: HistoryListStyle.dayGap),
                            _DayBox(day: d, activity: activity[d] ?? DayActivity.none, today: d == today),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gaps.panel),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$streak', style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.streakFont, height: 1)),
                  Text(s.historyStreak, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.tight),
        Wrap(spacing: Gaps.panel, runSpacing: Gaps.tight, children: [
          swatch(DayActivity.none, s.historyNotActive),
          swatch(DayActivity.some, s.historySomeActive),
          swatch(DayActivity.done, s.historyDoneActive),
        ]),
      ],
    );
  }
}

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
          width: HistoryListStyle.dayBox,
          height: HistoryListStyle.dayBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _WeekStrip.colorOf(activity),
            border: Border.all(color: today ? HistoryListStyle.today : Palette.ink, width: Strokes.label),
          ),
          child: switch (activity) {
            DayActivity.done => Text(s.historyDayDoneMark, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.tiny)),
            DayActivity.some => Container(
                width: HistoryListStyle.dayDot,
                height: HistoryListStyle.dayDot,
                decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
              ),
            DayActivity.none => null,
          },
        ),
        Text(s.weekdayLetter(day.weekday),
            style: TextStyle(
                fontWeight: Weights.black,
                fontSize: HistoryListStyle.dayLetterFont,
                color: today ? HistoryListStyle.today : Palette.ink)),
      ],
    );
  }
}

/// The main game's tab: runs grouped by practice day, newest first.
class _MainList extends StatelessWidget {
  const _MainList({required this.runs, required this.activity, required this.today});
  final List<PastRun> runs;
  final Map<DateTime, DayActivity> activity;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    if (runs.isEmpty) return _Empty(progress.sessions.isEmpty ? s.noRunsYet : s.historyNoMatch);
    final days = <DateTime, List<PastRun>>{};
    for (final r in runs) {
      (days[progress.dayOf(r.session)] ??= []).add(r);
    }
    return ListView(
      padding: const EdgeInsets.only(top: Gaps.section, bottom: HistoryListStyle.bottomPad),
      children: [
        for (final MapEntry(key: day, value: dayRuns) in days.entries) ...[
          _DayHeader(day: day, today: today, runs: dayRuns, activity: activity[day] ?? DayActivity.some),
          const SizedBox(height: Gaps.small),
          MangaPanel(
            child: Column(children: [
              for (final (i, r) in dayRuns.indexed) ...[
                if (i > 0) const Divider(height: Strokes.hairline, thickness: Strokes.hairline, color: ChartStyle.grid),
                _RunRow(r),
              ],
            ]),
          ),
          const SizedBox(height: Gaps.section),
        ],
      ],
    );
  }
}

/// D4: the day, and how much of it was played.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today, required this.runs, required this.activity});
  final DateTime day, today;
  final List<PastRun> runs;
  final DayActivity activity;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final status = progress.setDoneOn(day)
        ? s.historyDayDone
        : runs.any((r) => r.allKnown)
            ? s.historyDayAllKnown
            : runs.any((r) => r.mode == PlayMode.training)
                ? s.historyDaySome
                : s.historyDayPlayed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            if (day == today)
              TextSpan(
                  text: '${s.historyToday}  ',
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.dayHeaderFont)),
            TextSpan(
                text: s.historyDay(day),
                style: TextStyle(
                    fontFamily: day == today ? null : Fonts.display,
                    fontWeight: Weights.black,
                    fontSize: day == today ? HistoryListStyle.dayHeaderDateFont : HistoryListStyle.dayHeaderFont)),
          ])),
        ),
        Container(
          width: HistoryListStyle.legendBox,
          height: HistoryListStyle.legendBox,
          decoration: BoxDecoration(color: _WeekStrip.colorOf(activity), border: Border.all(color: Palette.ink, width: 1)),
        ),
        const SizedBox(width: Gaps.tight),
        Text(status, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
      ],
    );
  }
}

/// One row of a list: the time of day (or date) on the left, the kind and
/// badges over a line of facts, the main number with its caption, and a
/// chevron; tapping opens the run.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.when,
    required this.tags,
    required this.line,
    required this.value,
    required this.caption,
    required this.onTap,
    this.accent,
  });

  final Widget when;
  final List<Widget> tags;
  final Widget line;
  final String value, caption;
  final VoidCallback onTap;

  /// A coloured edge on the left (暗記練's rows).
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
              SizedBox(width: HistoryListStyle.rowClockWidth * MediaQuery.textScalerOf(context).scale(1), child: when),
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
      if (run.placement) ResultBadge(s.historyPlaced, color: Palette.pinkSoft),
      if (change != null)
        ResultBadge(change.$2.minRating > change.$1.minRating ? s.historyUpTo(change.$2.label) : s.historyDownTo(change.$2.label)),
      if (run.forfeit) ResultBadge(s.historyForfeit, muted: true),
      if (run.mode == PlayMode.exam) run.passed ? ResultBadge(s.runExamWon) : ResultBadge(s.runExamLost, muted: true),
    ];
    final ratingText = rating == null
        ? null
        : rating.before == null
            ? s.historyFirstRating(rating.after.round())
            : ratingChangeText(rating.after - rating.before!);
    final up = rating != null && (rating.before == null || rating.after >= rating.before!);
    final perCard = run.clock == null || run.cards == 0 ? null : run.clock!.inMilliseconds / run.cards;
    return _ListRow(
      when: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(s.clockTime(run.startedAt),
            style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryListStyle.rowClockFont)),
      ),
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
      value: hundred ? runTimeText(run) : (perCard == null ? missingTime : '${formatSeconds(perCard)}s'),
      caption: !hundred
          ? s.historyPerCardCaption
          : run.mode == PlayMode.exam
              ? s.historyYourTimeCaption
              : run.scored
                  ? s.historyScoredCaption
                  : s.historyTimeCaption,
      onTap: () => openRun(context, run),
    );
  }
}

/// The 暗記練 tab: one game a row, the date in the row.
class _AnkirenList extends StatelessWidget {
  const _AnkirenList({required this.games, required this.all});
  final List<SideTripRun> games;

  /// Every game, newest first, for ratings and bests before each one.
  final List<SideTripRun> all;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (games.isEmpty) return _Empty(all.isEmpty ? s.noRunsYet : s.historyNoMatch);
    return ListView(
      padding: const EdgeInsets.only(top: Gaps.section, bottom: HistoryListStyle.bottomPad),
      children: [
        MangaPanel(
          child: Column(children: [
            for (final (i, g) in games.indexed) ...[
              if (i > 0) const Divider(height: Strokes.hairline, thickness: Strokes.hairline, color: ChartStyle.grid),
              _GameRow(g, all: all),
            ],
          ]),
        ),
      ],
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
    final change = game.ranked && rating != null ? rating - (previous?.rating ?? AnkirenRating.start) : null;
    final best = game.ranked &&
        game.score != null &&
        earlier.where((g) => g.ranked && g.level == game.level).every((g) => (g.score ?? 0) < game.score!);
    final meta = jsonDecode(game.meta) as Map<String, dynamic>;
    final found = game.cardCount - progress.sideTrips.missesIn(game);
    final day = progress.dayOfGame(game);
    final today = progress.dayAt().date;
    return _ListRow(
      accent: Palette.pink,
      when: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(day == today ? s.historyToday : s.historyShortDay(day),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryListStyle.rowLineFont, height: 1.2)),
        Text(s.clockTime(game.startedAt),
            style: const TextStyle(
                fontWeight: Weights.bold, fontSize: HistoryListStyle.rowLineFont, height: 1.2, color: HistoryRunStyle.muted)),
      ]),
      tags: [
        AnkirenKindTag(ranked: game.ranked, level: game.level),
        if (kind == AnkirenKind.custom) ResultBadge(s.historyNotScored, muted: true),
        if (best) ResultBadge(s.historyBest),
      ],
      line: Text.rich(TextSpan(children: [
        TextSpan(
            text: kind == AnkirenKind.custom
                ? s.historyPerSide(meta[AnkirenMeta.perSideKey] ?? missingTime, game.cardCount)
                : s.historyCards(game.cardCount)),
        if (change != null)
          TextSpan(
              text: ' · ${ratingChangeText(change)}',
              style: TextStyle(color: change >= 0 ? HistoryRunStyle.ahead : HistoryRunStyle.behind)),
      ])),
      value: game.score == null ? '$found/${game.cardCount}' : '${game.score}',
      caption: game.score == null ? s.historyFirstTapCaption : s.historyPointsCaption,
      onTap: () => openAnkirenGame(context, game),
    );
  }
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
