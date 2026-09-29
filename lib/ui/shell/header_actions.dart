import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/profile_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

/// Opens the settings screen.
Future<void> openSettings(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const SettingsScreen()));

/// Opens My Profile.
Future<void> openProfile(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const ProfileScreen()));

/// Home's level readout, where the EN/JA toggle used to sit: with the
/// toggle gone, the level itself doubles as the button that opens My
/// Profile.
class LevelButton extends StatelessWidget {
  const LevelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final level = ProgressScope.of(context).xp.level.level;
    return SizedBox(
      height: LevelButtonStyle.height,
      child: InkButton(
        onTap: () => openProfile(context),
        padding: const EdgeInsets.symmetric(horizontal: LevelButtonStyle.padding),
        semanticLabel: s.myProfile,
        child: Text(s.levelShort(level), style: const TextStyle(fontFamily: Fonts.display, fontSize: LevelButtonStyle.font)),
      ),
    );
  }
}

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
