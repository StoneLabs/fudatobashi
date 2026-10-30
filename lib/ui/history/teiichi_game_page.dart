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

/// Opens 定位置 game [run]'s page.
Future<void> openTeiichiGame(BuildContext context, SideTripRun run) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => TeiichiGamePage(run: run)));

/// A recorded 定位置 game, tab by tab: its overview, the cards asked for
/// replayed on the layout, the placing, and every tap.
class TeiichiGamePage extends StatelessWidget {
  const TeiichiGamePage({super.key, required this.run});
  final SideTripRun run;

  static final List<PageTab<TeiichiReview>> tabs = [
    PageTab((s) => s.runTabOverview, TeiichiOverviewTab.new, cut: ReviewLayout.cut),
    PageTab((s) => s.ankirenTabField, _FieldTab.new),
    PageTab((s) => s.teiichiTabPlacing, TeiichiPlacingTab.new),
    PageTab((s) => s.ankirenTabTaps, _TapsTab.new),
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
    final kind = teiichiKindLabel(s, custom: game.custom);
    final setup = s.teiichiSetupLine(game.setup.cards, game.setup.rows);
    return RunPageFrame(
      title: s.tripName(trip),
      sub: [s.other.tripName(trip), kind, s.sessionDate(run.startedAt), setup].join(' · '),
      shortSub: [s.other.tripName(trip), kind, s.sessionDay(run.startedAt)].join(' · '),
      body: RunPageTabs(tabs: [for (final tab in tabs) tab.swipeTab(s, review, HistoryLooks.teiichi)]),
    );
  }
}

/// The Field: the cards asked for replayed on the layout at true scale
/// ([FieldReplay]), then how each row went, top to bottom.
class _FieldTab extends StatelessWidget {
  const _FieldTab(this.review);
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final rightFirst = {for (final c in game.recall.cards) if (c.firstTry) c.poemId};
    return FieldReplay(
      game: game.recall,
      deal: game.field,
      note: s.ankirenFieldNote,
      trueSlots: TeiichiTuning.rowSlots,
      tiles: [
        for (final row in FieldRow.values.reversed)
          if (game.layout.row(row).cards case final cards when cards.isNotEmpty)
            SummaryTile(
              label: '${s.teiichiRowName(row)}\n${s.ankirenColRightFirst}'.toUpperCase(),
              big: TileFigure('${cards.where(rightFirst.contains).length}', unit: '/${cards.length}'),
              note: '',
              color: Palette.paper,
            ),
      ],
    );
  }
}

/// The Taps: 暗記練's table of every card asked ([AnkirenTapsTab]).
class _TapsTab extends StatelessWidget {
  const _TapsTab(this.review);
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) => AnkirenTapsTab(review.recall, caption: S.of(context).teiichiTapsCaption);
}
