import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../db/database.dart' show SideTripRun;
import '../../domain/ankiren_field.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_review_strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../results/run_summary.dart';
import 'ankiren_field_tab.dart';
import 'ankiren_taps_tab.dart';
import 'history_widgets.dart';
import 'run_page.dart';
import 'teiichi_overview_tab.dart';
import 'teiichi_placing_tab.dart';
import 'teiichi_score_tab.dart';

/// Opens 定位置 game [run]'s page.
Future<void> openTeiichiGame(BuildContext context, SideTripRun run) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => TeiichiGamePage(run: run)));

/// A recorded 定位置 game, tab by tab: its overview, the calls replayed on
/// the layout, the placing, a ranked game's score, and every tap. Its
/// header names the setup, with the からふだ it called.
class TeiichiGamePage extends StatelessWidget {
  const TeiichiGamePage({super.key, required this.run});
  final SideTripRun run;

  static final List<PageTab<TeiichiReview>> tabs = [
    PageTab((s) => s.runTabOverview, TeiichiOverviewTab.new, cut: ReviewLayout.cut),
    PageTab((s) => s.ankirenTabField, _FieldTab.new),
    PageTab((s) => s.teiichiTabPlacing, TeiichiPlacingTab.new),
    PageTab((s) => s.ankirenTabTaps, _TapsTab.new),
  ];

  static final List<PageTab<TeiichiReview>> scoredTabs = [
    ...tabs.take(tabs.length - 1),
    PageTab((s) => s.ankirenTabScore, TeiichiScoreTab.new),
    tabs.last,
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final trips = ProgressScope.of(context).sideTrips;
    final review = TeiichiReview(
      trips.teiichiRecordOf(run),
      [for (final r in trips.runsOf(SideTrip.teiichi)) trips.teiichiRecordOf(r)],
    );
    final game = review.game;
    const trip = SideTrip.teiichi;
    final kind = teiichiKindLabel(s, game);
    final setup = teiichiSetupText(s, game.setup);
    return RunPageFrame(
      title: s.tripName(trip),
      sub: [s.other.tripName(trip), kind, s.sessionDate(run.startedAt), setup].join(' · '),
      shortSub: [s.other.tripName(trip), kind, s.sessionDay(run.startedAt)].join(' · '),
      body: RunPageTabs(tabs: [
        for (final tab in game.ranked ? scoredTabs : tabs) tab.swipeTab(s, review, HistoryLooks.teiichi),
      ]),
    );
  }
}

/// The Field: the cards asked for replayed on the layout at true scale
/// ([FieldReplay]), then how each row went, top to bottom, and each group,
/// left and right. Cards in the open middle are in neither group.
class _FieldTab extends StatelessWidget {
  const _FieldTab(this.review);
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final rows = game.layout.rows;
    final rightFirst = {for (final c in game.recall.cards) if (c.firstTry) c.poemId};
    SummaryTile? tile(String name, List<int> cards) =>
        cards.isEmpty ? null : rightFirstTile(s, name, cards.where(rightFirst.contains).length, cards.length);
    return FieldReplay(
      game: game.recall,
      deal: game.field,
      note: s.ankirenFieldNote,
      trueSlots: TeiichiTuning.rowSlots,
      tiles: [
        [for (final row in FieldRow.values.reversed) ?tile(s.teiichiRowName(row), game.layout.row(row).cards)],
        [
          ?tile(s.teiichiGroupLeft, [for (final r in rows) ...r.left]),
          ?tile(s.teiichiGroupRight, [for (final r in rows) ...r.right]),
        ],
      ],
      tilesNote: game.layout.middleCards.isEmpty ? null : s.teiichiMiddleNeither,
    );
  }
}

/// The Taps: 暗記練's table of every call ([AnkirenTapsTab]).
class _TapsTab extends StatelessWidget {
  const _TapsTab(this.review);
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) => AnkirenTapsTab(review.recall, caption: S.of(context).teiichiTapsCaption);
}
