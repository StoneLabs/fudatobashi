import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/xp_history.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'history_widgets.dart';
import 'ikkiuchi_field_tab.dart';
import 'ikkiuchi_overview_tab.dart';
import 'ikkiuchi_rating_tab.dart';
import 'ikkiuchi_reads_tab.dart';
import 'ikkiuchi_speed_tab.dart';
import 'run_page.dart';

/// Opens 一騎打ち match [match]'s page on its [tab] (one of
/// [IkkiuchiMatchPage.tabs]).
Future<void> openIkkiuchiMatch(BuildContext context, IkkiuchiMatchRecord match, {int tab = 0}) {
  final page = IkkiuchiMatchPage.of(ProgressScope.read(context), match, initialTab: tab);
  return Navigator.of(context).push(MangaRoute<void>(builder: (_) => page));
}

/// A recorded 一騎打ち match, tab by tab: its overview, the field replayed
/// read by read, the speed of the takes, the rating and the experience it
/// earned, and every read. Its header names its kind (a ranked match of its
/// mode, or custom), the practice day it counts to (as History lists it)
/// and Tobi's rating, a free match's setup too. It opens on [initialTab].
class IkkiuchiMatchPage extends StatelessWidget {
  const IkkiuchiMatchPage({super.key, required this.review, this.initialTab = 0});

  /// [match]'s page, against the matches [progress] recorded and with the
  /// experience it earned.
  factory IkkiuchiMatchPage.of(Progress progress, IkkiuchiMatchRecord match, {int initialTab = 0}) =>
      IkkiuchiMatchPage(
          review: IkkiuchiReview(match, progress.ikkiuchi.matches, xp: XpHistory.gainsOf(progress).ikkiuchi[match.id]),
          initialTab: initialTab);

  final IkkiuchiReview review;
  final int initialTab;

  static final List<PageTab<IkkiuchiReview>> tabs = [
    PageTab((s) => s.ikkiuchiTabOverview, IkkiuchiOverviewTab.new, cut: ReviewLayout.cut),
    PageTab((s) => s.ikkiuchiTabField, IkkiuchiFieldTab.new),
    PageTab((s) => s.ikkiuchiTabSpeed, IkkiuchiSpeedTab.new),
    PageTab((s) => s.ikkiuchiTabRating, IkkiuchiRatingTab.new, sub: (s) => s.tabAndXp),
    PageTab((s) => s.ikkiuchiTabReads, IkkiuchiReadsTab.new),
  ];

  /// The field's tab (盤面) in [tabs].
  static const fieldTab = 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = review.match;
    final setup = match.setup;
    final kind = ikkiuchiKindLabel(s, match);
    final day = s.sessionDay(match.startedAt, day: ProgressScope.of(context).dayStartedOn(match.startedAt));
    final tobi = s.ikkiuchiTobiAt(setup.opponentRating.round());
    final line = s.ikkiuchiSetupLine(setup.perSide, formatMinutes(setup.memorise), setup.opponentRating.round());
    return RunPageFrame(
      title: s.hallName,
      sub: [s.other.hallName, kind, day, if (match.ranked) tobi else line].join(' · '),
      shortSub: [s.other.hallName, kind, day, if (!match.ranked) tobi].join(' · '),
      body: RunPageTabs(
          tabs: [for (final tab in tabs) tab.swipeTab(s, review, HistoryLooks.ikkiuchi)], initial: initialTab),
    );
  }
}
