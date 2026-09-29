import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/tab_locks.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../help/help_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../manga/manga.dart';
import '../stats/stats_screen.dart';
import 'tab_chains.dart';

enum AppTab { home, history, stats, help }

/// The main screen: the four tabs above the manga tab bar. Settings open from
/// each tab's header (see `openSettings`).
///
/// History and Stats start out locked under chains (see [TabLock]); a tab
/// that opens has its chains broken, once, the next time Home shows.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.home;

  /// Tabs whose chains are breaking right now.
  final Set<LockedTab> _breaking = {};
  bool _syncScheduled = false;

  static Widget _screen(AppTab t) => switch (t) {
        AppTab.home => const HomeScreen(),
        AppTab.history => const HistoryScreen(),
        AppTab.stats => const StatsScreen(),
        AppTab.help => const HelpScreen(),
      };

  /// Remembers the tabs shown locked, and breaks the chains of any that have
  /// opened since, when Home is on screen.
  void _syncLocks(Progress progress, Map<LockedTab, TabLock?> locks) {
    final locked = [for (final e in locks.entries) if (e.value != null) e.key];
    final seen = progress.tabsSeenLocked;
    final opened = [for (final t in seen) if (locks[t] == null && !_breaking.contains(t)) t];
    final onHome = _tab == AppTab.home && ModalRoute.isCurrentOf(context) != false && progress.settings.toured;
    final unseen = locked.any((t) => !seen.contains(t));
    if (_syncScheduled || !(unseen || (onHome && opened.isNotEmpty))) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      progress.noteTabsSeenLocked(locked);
      if (!onHome || opened.isEmpty) return;
      progress.noteTabsOpened(opened);
      setState(() => _breaking.addAll(opened));
      final s = S.of(context);
      MangaToast.show(context, s.tabUnlocked(opened.map((t) => _label(s, t)).join(' · ')));
    });
  }

  static String _label(S s, LockedTab t) => switch (t) {
        LockedTab.history => s.history,
        LockedTab.stats => s.stats,
      };

  /// Tab [t], in chains while [lock] holds it shut, and after it opens
  /// until they have broken.
  MangaTab _lockable(S s, Progress progress, LockedTab t, VectorArt icon, TabLock? lock) => MangaTab(
        icon: icon,
        label: _label(s, t),
        onBlocked: lock == null
            ? null
            : (tile) => BalloonPop.show(tile, s.lockReason(_label(s, t), lock),
                size: TabLockStyle.balloon, life: TabLockStyle.balloonLife, tobi: TobiPose.pointing),
        cover: lock != null || progress.tabsSeenLocked.contains(t) || _breaking.contains(t)
            ? TabChains(
                key: ValueKey(t),
                breaking: _breaking.contains(t),
                onBroken: () => setState(() => _breaking.remove(t)),
              )
            : null,
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final locks = {for (final t in LockedTab.values) t: progress.tabLock(t)};
    _syncLocks(progress, locks);
    return PopScope(
      canPop: _tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = AppTab.home);
      },
      child: Scaffold(
        body: Stack(children: [
          if (_tab == AppTab.home) const Positioned.fill(child: GradationBox(Tones.home)),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _tab.index,
                    children: [
                      for (final t in AppTab.values) TickerMode(enabled: t == _tab, child: _screen(t)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.section, Gaps.gutter, Gaps.section),
                  child: MangaTabBar(
                    current: _tab.index,
                    onSelect: (i) => setState(() => _tab = AppTab.values[i]),
                    tabs: [
                      MangaTab(icon: IconArt.home, label: s.home),
                      _lockable(s, progress, LockedTab.history, IconArt.history, locks[LockedTab.history]),
                      _lockable(s, progress, LockedTab.stats, IconArt.stats, locks[LockedTab.stats]),
                      MangaTab(icon: IconArt.help, label: s.help),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
