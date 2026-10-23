import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../db/database.dart' show SideTripRun;
import '../../domain/ankiren_review.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../../state/xp_history.dart';
import '../manga/manga.dart';
import 'ankiren_cards_tab.dart';
import 'ankiren_field_tab.dart';
import 'ankiren_overview_tab.dart';
import 'ankiren_score_tab.dart';
import 'ankiren_taps_tab.dart';
import 'history_widgets.dart';
import 'run_page.dart';

/// Opens 暗記練 game [run]'s page.
Future<void> openAnkirenGame(BuildContext context, SideTripRun run) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => AnkirenGamePage(run: run)));

/// A recorded 暗記練 game, tab by tab: a ranked game's overview, field,
/// cards, score and taps; any other game's overview, field and taps.
class AnkirenGamePage extends StatelessWidget {
  const AnkirenGamePage({super.key, required this.run});
  final SideTripRun run;

  static final List<PageTab<AnkirenReview>> scoredTabs = [
    PageTab((s) => s.runTabOverview, AnkirenOverviewTab.new),
    PageTab((s) => s.ankirenTabField, AnkirenFieldTab.new),
    PageTab((s) => s.runTabCards, AnkirenCardsTab.new),
    PageTab((s) => s.ankirenTabScore, AnkirenScoreTab.new, sub: (s) => s.tabAndXp),
    PageTab((s) => s.ankirenTabTaps, AnkirenTapsTab.new),
  ];

  static final List<PageTab<AnkirenReview>> unscoredTabs = [
    PageTab((s) => s.runTabOverview, AnkirenOverviewTab.new),
    PageTab((s) => s.ankirenTabField, AnkirenFieldTab.new),
    PageTab((s) => s.ankirenTabTaps, AnkirenTapsTab.new),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final trips = progress.sideTrips;
    final review = AnkirenReview(
      trips.recordOf(run),
      [for (final r in trips.runsOf(SideTrip.ankiren)) trips.recordOf(r)],
      xp: XpHistory.gainsOf(progress).ankiren[run.id],
    );
    final tabs = review.game.scored ? scoredTabs : unscoredTabs;
    return RunPageFrame(
      look: HistoryLooks.ankiren,
      title: s.runTabGame,
      titleSub: s.other.runTabGame,
      tag: AnkirenKindTag(ranked: run.ranked, level: run.level),
      line: '${s.sessionDate(run.startedAt)} · ${s.ankirenASide(review.game.perSide)}',
      body: RunPageTabs(tabs: [for (final tab in tabs) tab.swipeTab(s, review, HistoryLooks.ankiren)]),
    );
  }
}
