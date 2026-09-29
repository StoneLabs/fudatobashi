import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/language_strings.dart';
import '../../l10n/localization.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../settings/language_screen.dart';

/// First launch, before onboarding: picks the UI language once, preselecting
/// the device's if Fudatobashi has it. Skipped for good once picked (see
/// `AppSettings.languagePicked` and `FudatobashiApp`'s launch gate).
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    final preselected = Localization.languages.any((l) => l.code == deviceCode) ? deviceCode : null;
    void choose(String code) =>
        progress.updateSettings(progress.settings.copyWith(language: code, languagePicked: true));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: LanguageLayout.pickerTopGap),
              SizedBox(height: LanguageLayout.pickerTobiHeight, child: const Tobi(pose: TobiPose.waving)),
              const SizedBox(height: Gaps.panel),
              Text(
                s.chooseLanguage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: LanguageLayout.pickerTitleFont, height: 1.2),
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: ListView(
                  children: [
                    for (final (i, lang) in Localization.languages.indexed) ...[
                      if (i > 0) const SizedBox(height: Gaps.panel),
                      LanguageCard(label: lang.name, selected: lang.code == preselected, onTap: () => choose(lang.code)),
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
