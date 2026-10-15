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

/// One tab of a run page, built from the run's details.
typedef RunTabSpec = ({String Function(S s) label, Widget Function(RunDetail detail) build});

/// A recorded run, tab by tab: the 100-card view for ranked, the exam and
/// 100-card free play, the training view for the rest.
class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.run});
  final PastRun run;

  static final List<RunTabSpec> hundredTabs = [
    (label: (s) => s.runTabOverview, build: RunOverviewTab.new),
    (label: (s) => s.runTabCards, build: RunCardsTab.new),
    (label: (s) => s.runTabSpeed, build: RunSpeedTab.new),
    (label: (s) => s.runTabRating, build: RunRatingTab.new),
    (label: (s) => s.runTabSwipes, build: RunSwipesTab.new),
  ];

  static final List<RunTabSpec> trainingTabs = [
    (label: (s) => s.runTabOverview, build: RunOverviewTab.new),
    (label: (s) => s.runTabCards, build: RunCardsTab.new),
    (label: (s) => s.runTabXp, build: RunXpTab.new),
    (label: (s) => s.runTabSwipes, build: RunSwipesTab.new),
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
          return SwipeTabs(
            pager: SwipePagerWords(position: s.pagerPosition, previous: s.pagerPrevious, next: s.pagerNext),
            tabs: [
              for (final tab in tabs)
                SwipeTab(label: tab.label(s), sub: tab.label(s.other), builder: (_) => tab.build(detail)),
            ],
          );
        },
      ),
    );
  }
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
                padding: const EdgeInsets.fromLTRB(Gaps.gutter, 0, Gaps.gutter, Gaps.panel),
                child: Row(
                  children: [
                    tag,
                    const SizedBox(width: Gaps.panel),
                    Expanded(
                      child: Text(line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.small)),
                    ),
                  ],
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
