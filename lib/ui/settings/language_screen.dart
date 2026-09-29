import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/language_strings.dart';
import '../../l10n/localization.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// One tappable language card, its own name as the label — the first-open
/// picker's only content, and Settings' Language row reuses it.
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: LanguageLayout.cardHeight,
        child: InkButton(
          color: selected ? Palette.sun : Palette.paper,
          onTap: onTap,
          child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: LanguageLayout.cardFont)),
        ),
      );
}

/// Settings' Language row: every language `languages.json` lists, plus
/// "System default".
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final current = progress.settings.language;
    void choose(String code) {
      progress.updateSettings(progress.settings.copyWith(language: code));
      Navigator.maybePop(context);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.language, sub: s.other.language),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: ListView(
                  children: [
                    LanguageCard(label: s.systemDefault, selected: current == 'system', onTap: () => choose('system')),
                    for (final lang in Localization.languages) ...[
                      const SizedBox(height: Gaps.panel),
                      LanguageCard(label: lang.name, selected: current == lang.code, onTap: () => choose(lang.code)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Gaps.section),
            ],
          ),
        ),
      ),
    );
  }
}
