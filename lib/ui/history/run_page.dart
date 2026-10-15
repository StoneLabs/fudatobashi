import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../manga/swipe_tabs.dart';
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
/// from the page's data.
class PageTab<T> {
  const PageTab(this.label, this.build, {this.sub});
  final String Function(S s) label;
  final String Function(S s)? sub;
  final Widget Function(T data) build;

  /// This tab for [SwipeTabs], filled in from [data].
  SwipeTab swipeTab(S s, T data, {Color accent = Palette.ink}) =>
      SwipeTab(label: label(s), sub: sub?.call(s) ?? label(s.other), accent: accent, builder: (_) => build(data));
}

/// A recorded run, tab by tab: the 100-card view for ranked, the exam and
/// 100-card free play, the training view for the rest.
class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.run});
  final PastRun run;

  static final List<PageTab<RunDetail>> hundredTabs = [
    PageTab((s) => s.runTabOverview, RunOverviewTab.new),
    PageTab((s) => s.runTabCards, RunCardsTab.new),
    PageTab((s) => s.runTabSpeed, RunSpeedTab.new),
    PageTab((s) => s.runTabRating, RunRatingTab.new, sub: (s) => s.tabAndXp),
    PageTab((s) => s.runTabSwipes, RunSwipesTab.new),
  ];

  static final List<PageTab<RunDetail>> trainingTabs = [
    PageTab((s) => s.runTabOverview, RunOverviewTab.new),
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
    return RunPageFrame(
      title: s.runTitle,
      titleSub: s.other.runTitle,
      tag: RunKindTag(run.mode),
      line: '${s.sessionDate(run.startedAt)} · ${s.runCardsLine(run.cards)}',
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
          return RunPageTabs(tabs: [for (final tab in tabs) tab.swipeTab(s, detail)]);
        },
      ),
    );
  }
}

/// A run or game page's swiped tabs, their row inside the gutters.
class RunPageTabs extends StatelessWidget {
  const RunPageTabs({super.key, required this.tabs});
  final List<SwipeTab> tabs;

  @override
  Widget build(BuildContext context) =>
      SwipeTabs(padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter), tabs: tabs);
}

/// A run or game page's frame: the title with a back button, the kind tag
/// and a line about it, then [body] (the swiped tabs).
class RunPageFrame extends StatelessWidget {
  const RunPageFrame({
    super.key,
    required this.title,
    required this.titleSub,
    required this.tag,
    required this.line,
    required this.body,
  });

  final String title, titleSub, line;
  final Widget tag;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: HeaderStyle.topGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: MangaHeader(
                  title: ScreenTitle(title, sub: titleSub),
                  actions: [InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context))],
                ),
              ),
              Padding(
                padding: HistoryRunStyle.tagRowPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: HistoryRunStyle.tagRowHeight),
                  child: Row(
                    children: [
                      tag,
                      const SizedBox(width: Gaps.panel),
                      Expanded(
                        child: Text(line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.tagRowFont)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
