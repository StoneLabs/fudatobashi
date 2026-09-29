import 'package:flutter/widgets.dart';

import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../settings/settings_screen.dart';

/// Opens the settings screen.
Future<void> openSettings(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const SettingsScreen()));

/// The EN / JA switch, bound to the app language setting.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    return LanguageToggle(
      japanese: S.of(context).ja,
      onChanged: (ja) => progress.updateSettings(progress.settings.copyWith(language: ja ? 'ja' : 'en')),
    );
  }
}

/// The gear button that opens settings.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) =>
      InkIconButton(icon: IconArt.settings, semanticLabel: S.of(context).settings, onTap: () => openSettings(context));
}
