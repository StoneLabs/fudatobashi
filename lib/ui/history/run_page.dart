import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/past_runs.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../manga/swipe_tabs.dart';
import '../run/run_labels.dart';
import 'history_widgets.dart';
import 'run_cards_tab.dart';
import 'run_overview_tab.dart';
import 'run_rating_tab.dart';
import 'run_speed_tab.dart';
import 'run_swipes_tab.dart';
import 'run_xp_tab.dart';

/// Opens [run]'s page.
Future<void> openRun(BuildContext context, PastRun run) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => RunPage(run: run)));

/// One tab of a run or game page: its name, the line under it (its name
/// in the other language unless [sub] gives one) and its contents, built
/// from the page's data, their panels and tiles [cut].
class PageTab<T> {
  const PageTab(this.label, this.build, {this.sub, this.cut = ReviewLayout.detailCut});
  final String Function(S s) label;
  final String Function(S s)? sub;
  final Widget Function(T data) build;
  final double cut;

  /// This tab for [SwipeTabs] in [look]'s colours, filled in from [data].
  SwipeTab swipeTab(S s, T data, KindLook look) => SwipeTab(
        label: label(s),
        sub: s.sub == null ? null : sub?.call(s) ?? label(s.sub!),
        accent: look.accent,
        onAccent: look.onAccent,
        builder: (_) => SlantCut(cut: cut, child: build(data)),
      );
}

/// A recorded run, tab by tab: the 100-card view for ranked, the exam and
/// 100-card free play, the training view for the rest.
class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.run});
  final PastRun run;

  static final List<PageTab<RunDetail>> hundredTabs = [
    PageTab((s) => s.runTabOverview, RunOverviewTab.new, cut: ReviewLayout.cut),
    PageTab((s) => s.runTabCards, RunCardsTab.new),
    PageTab((s) => s.runTabSpeed, RunSpeedTab.new),
    PageTab((s) => s.runTabRating, RunRatingTab.new, sub: (s) => s.tabAndXp),
    PageTab((s) => s.runTabSwipes, RunSwipesTab.new),
  ];

  static final List<PageTab<RunDetail>> trainingTabs = [
    PageTab((s) => s.runTabOverview, RunOverviewTab.new, cut: ReviewLayout.cut),
    PageTab((s) => s.runTabCards, RunCardsTab.new),
    PageTab((s) => s.runTabXp, RunXpTab.new),
    PageTab((s) => s.runTabSwipes, RunSwipesTab.new),
  ];

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  late final Future<RunDetail> _detail = ProgressScope.read(context).loadRunDetail(widget.run);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final run = widget.run;
    final tabs = run.view == RunView.hundred ? RunPage.hundredTabs : RunPage.trainingTabs;
    final cards = run.forfeit ? s.summaryCardsOf(run.cards, run.planned) : s.runCardsLine(run.cards);
    return RunPageFrame(
      title: modeTitle(s, run.mode),
      sub: [modeTitle(s.other, run.mode), s.sessionDate(run.startedAt), cards].join(' · '),
      shortSub: [modeTitle(s.other, run.mode), s.sessionDay(run.startedAt), cards].join(' · '),
      body: FutureBuilder<RunDetail>(
        future: _detail,
        builder: (context, snap) {
          final detail = snap.data;
          if (detail == null) {
            return Center(
              child: Text(snap.hasError ? '${snap.error}' : s.runLoading,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
            );
          }
          final look = RunKindTag.lookOf(run.mode);
          return RunPageTabs(tabs: [for (final tab in tabs) tab.swipeTab(s, detail, look)]);
        },
      ),
    );
  }
}

/// A run or game page's swiped tabs, their row inside the gutters, the
/// open one in its kind's colour.
class RunPageTabs extends StatelessWidget {
  const RunPageTabs({super.key, required this.tabs});
  final List<SwipeTab> tabs;

  @override
  Widget build(BuildContext context) => SwipeTabs(
        look: SwipeTabsLook.slant,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
        tabs: tabs,
      );
}

/// A run or game page's frame, the summary's header on Home's dotted
/// ground: the [title] over its [sub] line (or [shortSub] when that is
/// too long) with a back button, then
/// [body] (the swiped tabs).
class RunPageFrame extends StatelessWidget {
  const RunPageFrame({super.key, required this.title, required this.sub, required this.shortSub, required this.body});

  final String title, sub, shortSub;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: ReviewLayout.maxTextScale,
        child: Stack(children: [
          const Positioned.fill(child: GradationBox(Tones.home)),
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: HeaderStyle.topGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: MangaHeader(
                  title: Padding(
                    padding: const EdgeInsetsDirectional.only(end: ReviewLayout.headerBackGap),
                    child: RunHeaderTitle(title: title, sub: sub.toUpperCase(), shortSub: shortSub.toUpperCase()),
                  ),
                  actions: [
                    InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                  ],
                ),
              ),
              const SizedBox(height: ReviewLayout.headerGap),
              Expanded(child: body),
            ]),
          ),
        ]),
      ),
    );
  }
}
