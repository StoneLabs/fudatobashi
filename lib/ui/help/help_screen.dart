import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/all_guides_strings.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/help_strings.dart';
import '../../l10n/match_timer_strings.dart';
import '../../l10n/rules_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../cards/card_browser_screen.dart';
import '../manga/manga.dart';
import '../tools/match_timer_screen.dart';
import '../tour/tour_overlay.dart';
import 'all_guides_screen.dart';
import 'guide_catalog.dart';
import 'help_entry.dart';
import 'karuta_rules_screen.dart';

/// Help (opened from Home's "?" button). Guides: Tobi's tour of Home
/// again, the guide to how karuta works, the full competition rules and the list
/// of all other guides.
/// Tools: the card browser, the match timer, and a slot saying more are coming.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    void open(Widget page) => Navigator.of(context).push(MangaRoute<void>(builder: (_) => page));
    final guides = [
      HelpEntry(
        title: s.replayTour,
        sub: o?.replayTour,
        note: s.replayTourNote,
        icon: IconArt.refresh,
        onTap: () => replayTour(context),
      ),
      HelpEntry(
        title: s.guideTitle,
        sub: o?.guideTitle,
        note: s.guideRowNote,
        icon: IconArt.arrow,
        onTap: () => Guides.karuta.open(context),
      ),
      HelpEntry(
        title: s.rulesTitle,
        sub: o?.rulesTitle,
        note: s.rulesRowNote,
        icon: IconArt.arrow,
        onTap: () => open(const KarutaRulesScreen()),
      ),
      HelpEntry(
        title: s.allGuidesTitle,
        sub: o?.allGuidesTitle,
        note: s.allGuidesNote,
        icon: IconArt.arrow,
        onTap: () => open(const AllGuidesScreen()),
      ),
    ];
    final tools = [
      HelpEntry(
        title: s.cardBrowserTitle,
        sub: o?.cardBrowserTitle,
        note: s.cardBrowserNote,
        icon: IconArt.arrow,
        onTap: () => open(const CardBrowserScreen()),
      ),
      HelpEntry(
        title: s.matchTimerTitle,
        sub: o?.matchTimerTitle,
        note: s.matchTimerNote,
        icon: IconArt.arrow,
        onTap: () => open(const MatchTimerScreen()),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.help, sub: s.other.help),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: Gaps.tight, bottom: ProseLayout.bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MarkerHeading(s.helpGuides, o?.helpGuides),
                      for (final entry in guides) ...[entry, const HelpRule()],
                      const SizedBox(height: MarkerHeadingStyle.sectionGap),
                      MarkerHeading(s.helpTools, o?.helpTools),
                      for (final entry in tools) ...[entry, const HelpRule()],
                      const SizedBox(height: HelpLayout.soonGap),
                      ComingSoonSlot(s.helpToolsSoon),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
