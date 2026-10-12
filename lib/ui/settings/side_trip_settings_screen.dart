import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import 'settings_rows.dart';

/// Settings › 寄り道 › 暗記練: the field's layout and how each card is asked
/// for.
class AnkirenSettingsScreen extends StatelessWidget {
  const AnkirenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final a = progress.settings.ankiren;
    void update(AnkirenSettings next) => progress.updateSettings(progress.settings.copyWith(ankiren: next));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(SideTrip.ankiren.label, sub: s.tripBanner(SideTrip.ankiren)),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsChoices(
                        label: SettingsLabel(title: s.ankirenLayout, note: s.ankirenLayoutNote),
                        side: true,
                        options: [
                          SettingsOption(s.ankirenPortrait,
                              sub: s.ankirenPortraitSub,
                              selected: a.layout == AnkirenLayout.portrait,
                              onTap: () => update(a.copyWith(layout: AnkirenLayout.portrait))),
                          SettingsOption(s.ankirenLandscape,
                              sub: s.ankirenLandscapeSub,
                              selected: a.layout == AnkirenLayout.landscape,
                              onTap: () => update(a.copyWith(layout: AnkirenLayout.landscape))),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsChoices(
                        label: SettingsLabel(title: s.ankirenPrompt, note: s.ankirenPromptNote),
                        side: true,
                        options: [
                          SettingsOption(s.ankirenPromptVoice,
                              selected: a.prompt == AnkirenPrompt.textAndVoice,
                              onTap: () => update(a.copyWith(prompt: AnkirenPrompt.textAndVoice))),
                          SettingsOption(s.ankirenPromptText,
                              selected: a.prompt == AnkirenPrompt.textOnly,
                              onTap: () => update(a.copyWith(prompt: AnkirenPrompt.textOnly))),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
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
