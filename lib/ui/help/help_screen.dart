import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../manga/manga.dart';
import '../settings/settings_rows.dart';
import '../tour/tour_overlay.dart';
import 'karuta_guide_screen.dart';

/// Help (opened from Home's "?" button): Tobi's tour of Home again, and
/// the guide to how karuta works.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
              SettingsGroup(children: [
                SettingsTapRow(title: s.replayTour, note: s.replayTourNote, onTap: () => replayTour(context)),
                SettingsTapRow(
                  title: s.guideTitle,
                  note: s.guideRowNote,
                  opensPage: true,
                  onTap: () => Navigator.of(context).push(MangaRoute<void>(builder: (_) => const KarutaGuideScreen())),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
