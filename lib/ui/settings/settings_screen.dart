import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/trainer.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../debug/debug_page.dart';
import '../manga/manga.dart';
import '../shell/header_actions.dart';

/// Settings (placeholder: language, learning mode and the debug pages).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final mode = progress.trainer.config.learningMode;
    Widget choice(LearningMode m, String label) => Expanded(
          child: SizedBox(
            height: ButtonMetrics.rowHeight,
            child: InkButton(
              color: mode == m ? Palette.sun : Palette.paper,
              onTap: mode == m ? null : () => progress.setLearningMode(m),
              child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
            ),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.settings, sub: s.other.settings),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              const Align(alignment: Alignment.centerLeft, child: LanguageSwitch()),
              const SizedBox(height: Gaps.section),
              Row(children: [
                choice(LearningMode.journey, s.learningJourney),
                const SizedBox(width: Gaps.panelWide),
                choice(LearningMode.allKnown, s.learningAllKnown),
              ]),
              const SizedBox(height: Gaps.section),
              SizedBox(
                height: ButtonMetrics.rowHeight,
                child: InkButton(
                  onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const DebugPage())),
                  child: Text(s.debug, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                ),
              ),
              const Spacer(),
              Center(child: NarrationBox(child: Text(s.comingSoon))),
              const SizedBox(height: Gaps.section),
            ],
          ),
        ),
      ),
    );
  }
}
