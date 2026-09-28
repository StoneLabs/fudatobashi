import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../help/help_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../manga/manga.dart';
import '../stats/stats_screen.dart';
import 'coming_soon.dart';

enum AppTab { home, history, stats, help }

/// The main screen: the four tabs above the manga tab bar. Settings open from
/// each tab's header (see `openSettings`).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.home;

  static Widget _screen(AppTab t) => switch (t) {
        AppTab.home => const HomeScreen(),
        AppTab.history => const HistoryScreen(),
        AppTab.stats => const StatsScreen(),
        AppTab.help => const HelpScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
                    onUnready: ComingSoonBubble.show,
                    tabs: [
                      MangaTab(icon: IconArt.home, label: s.home),
                      MangaTab(icon: IconArt.history, label: s.history),
                      MangaTab(icon: IconArt.stats, label: s.stats),
                      MangaTab(icon: IconArt.help, label: s.help, ready: false),
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
