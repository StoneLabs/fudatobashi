import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/trainer.dart';
import '../../l10n/credits_strings.dart';
import '../../l10n/language_strings.dart';
import '../../l10n/localization.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../debug/celebration_preview.dart';
import '../debug/debug_page.dart';
import '../debug/reset_actions.dart';
import '../debug/simulation_page.dart';
import '../manga/manga.dart';
import 'credits_screen.dart';
import 'hold_warning_screen.dart';
import 'language_screen.dart';
import 'settings_rows.dart';

/// Settings, in sections: Language; Learning (mode, pace, the don't-know
/// input); Play; Sound; About, whose version row hides the 10-tap
/// developer-mode unlock; Data (Reset all data); and, once developer mode
/// is unlocked, Developer.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSection(
                        title: s.language,
                        sub: s.other.language,
                        children: const [SettingsGroup(children: [_LanguageRow()])],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      const _LearningSection(),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.sectionPlay,
                        sub: s.other.sectionPlay,
                        children: [
                          SettingsGroup(children: [
                            SettingsSwitch(
                              title: s.cardEffects,
                              note: s.cardEffectsNote,
                              value: settings.sfxEffects,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(sfxEffects: v)),
                            ),
                            SettingsSwitch(
                              title: s.vibration,
                              note: s.vibrationNote,
                              value: settings.haptics,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(haptics: v)),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.sectionSound,
                        sub: s.other.sectionSound,
                        footnote: s.soundSilentNote,
                        children: [
                          SettingsGroup(children: [
                            SettingsSwitch(
                              title: s.sounds,
                              note: s.soundsNote,
                              value: settings.sounds,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(sounds: v)),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.about,
                        sub: s.other.about,
                        children: [
                          SettingsGroup(children: [
                            const _VersionRow(),
                            SettingsTapRow(
                              title: s.credits,
                              note: s.creditsNote,
                              opensPage: true,
                              onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const CreditsScreen())),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.sectionData,
                        sub: s.other.sectionData,
                        children: [
                          SettingsGroup(children: [
                            SettingsTapRow(
                              title: s.resetAllData,
                              note: s.resetAllDataNote,
                              danger: true,
                              onTap: () => _resetAllData(context, progress),
                            ),
                          ]),
                        ],
                      ),
                      if (settings.debugMode) ...[
                        const SizedBox(height: SettingsLayout.sectionGap),
                        const _DeveloperSection(),
                      ],
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

/// Learning mode, the journey's pace (journey only) and how a card is
/// marked "don't know" during play ("off" only in all-known mode).
class _LearningSection extends StatelessWidget {
  const _LearningSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final mode = progress.trainer.config.learningMode;
    final pace = progress.trainer.config.pace;
    final dontKnow = progress.settings.dontKnowInputFor(mode);
    void setDontKnow(DontKnowInput input) => progress.updateSettings(progress.settings.copyWith(dontKnowInput: input));
    return SettingsSection(
      title: s.sectionLearning,
      sub: s.other.sectionLearning,
      children: [
        _Choices(
          label: SettingsLabel(title: s.learningMode, note: s.learningModeNote),
          side: true,
          options: [
            _Option(s.learningJourney, selected: mode == LearningMode.journey,
                onTap: () => _chooseLearningMode(context, progress, mode, LearningMode.journey)),
            _Option(s.learningAllKnown, selected: mode == LearningMode.allKnown,
                onTap: () => _chooseLearningMode(context, progress, mode, LearningMode.allKnown)),
          ],
        ),
        if (mode == LearningMode.journey)
          _Choices(
            label: SettingsLabel(title: s.pace, note: s.paceNote),
            side: true,
            options: [
              _Option(s.paceMonth, selected: pace == LearningPace.month, onTap: () => progress.setLearningPace(LearningPace.month)),
              _Option(s.paceSprint, selected: pace == LearningPace.sprint, onTap: () => progress.setLearningPace(LearningPace.sprint)),
            ],
          ),
        _Choices(
          label: SettingsLabel(title: s.dontKnowInput, note: s.dontKnowInputNote),
          options: [
            _Option(s.dontKnowHold, sub: s.dontKnowHoldSub, selected: dontKnow == DontKnowInput.hold,
                onTap: () => setDontKnow(DontKnowInput.hold)),
            _Option(s.dontKnowButton, sub: s.dontKnowButtonSub, selected: dontKnow == DontKnowInput.button,
                onTap: () => setDontKnow(DontKnowInput.button)),
            if (mode == LearningMode.allKnown)
              _Option(s.dontKnowOff, sub: s.dontKnowOffSub, selected: dontKnow == DontKnowInput.off,
                  onTap: () => setDontKnow(DontKnowInput.off)),
          ],
        ),
      ],
    );
  }
}

/// Journey → all-known goes behind a full-screen warning (it can't be
/// undone), unless every card is already unlocked and there's nothing left
/// to warn about; the other direction needs none either, since journey then
/// simply shows everything unlocked.
Future<void> _chooseLearningMode(BuildContext context, Progress progress, LearningMode from, LearningMode to) async {
  if (from != LearningMode.journey || to != LearningMode.allKnown) {
    await progress.setLearningMode(to);
    return;
  }
  if (progress.allCardsUnlocked) {
    await progress.switchToAllKnown();
    return;
  }
  final warning = HoldWarningScreen.allKnown(S.of(context));
  final confirmed = await Navigator.of(context).push(MangaRoute<bool>(builder: (_) => warning));
  if (confirmed == true) await progress.switchToAllKnown();
}

/// Reset all data goes behind the same full-screen warning. Once it is
/// confirmed the app starts over at the language picker, as on a fresh
/// install.
Future<void> _resetAllData(BuildContext context, Progress progress) async {
  final navigator = Navigator.of(context);
  final warning = HoldWarningScreen.resetAll(S.of(context));
  final confirmed = await navigator.push(MangaRoute<bool>(builder: (_) => warning));
  if (confirmed != true) return;
  await progress.resetAllData();
  navigator.popUntil((route) => route.isFirst);
}

class _Option {
  const _Option(this.title, {this.sub, required this.selected, required this.onTap});
  final String title;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;
}

/// A named choice: its label above sun-lit (chosen) or paper buttons, side
/// by side or stacked, equal in height either way.
class _Choices extends StatelessWidget {
  const _Choices({required this.label, required this.options, this.side = false});
  final SettingsLabel label;
  final List<_Option> options;
  final bool side;

  @override
  Widget build(BuildContext context) {
    final buttons = [for (final o in options) _button(o)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label,
        if (side)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, b) in buttons.indexed) ...[
                  if (i > 0) const SizedBox(width: Gaps.panelWide),
                  Expanded(child: b),
                ],
              ],
            ),
          )
        else
          for (final (i, b) in buttons.indexed) ...[
            if (i > 0) const SizedBox(height: Gaps.small),
            b,
          ],
      ],
    );
  }

  Widget _button(_Option o) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ButtonMetrics.rowHeight),
        child: InkButton(
          color: o.selected ? Palette.sun : Palette.paper,
          onTap: o.selected ? null : o.onTap,
          padding: SettingsLayout.rowPadding,
          alignment: o.sub == null ? Alignment.center : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: o.sub == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                Phrases.span(o.title),
                textAlign: o.sub == null ? TextAlign.center : TextAlign.start,
                style: const TextStyle(fontWeight: Weights.black, fontSize: SettingsLayout.titleFont),
              ),
              if (o.sub != null)
                Text(o.sub!, style: const TextStyle(fontWeight: Weights.bold, fontSize: SettingsLayout.noteFont)),
            ],
          ),
        ),
      );
}

/// The language in use, opening the full list (`LanguageScreen`) to change
/// it.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = ProgressScope.of(context).settings.language;
    final current = language == 'system'
        ? s.systemDefault
        : Localization.languages.firstWhere((l) => l.code == language, orElse: () => LanguageOption(language, language)).name;
    return SettingsTapRow(
      title: current,
      note: s.languageNote,
      opensPage: true,
      onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const LanguageScreen())),
    );
  }
}

/// The app's version; tapping it [DevModeTuning.tapsRequired] times unlocks
/// developer mode.
class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  String? _version;
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  void _onTap() {
    final progress = ProgressScope.read(context);
    if (progress.settings.debugMode) return;
    _taps++;
    final remaining = DevModeTuning.tapsRequired - _taps;
    if (remaining <= 0) {
      _taps = 0;
      progress.updateSettings(progress.settings.copyWith(debugMode: true));
      MangaToast.show(context, S.of(context).devModeUnlocked);
    } else if (remaining <= DevModeTuning.countdownFrom) {
      MangaToast.show(context, S.of(context).tapsRemaining(remaining));
    }
  }

  @override
  Widget build(BuildContext context) =>
      SettingsTapRow(title: S.of(context).version, value: _version ?? '…', onTap: _onTap);
}

class _DeveloperSection extends StatelessWidget {
  const _DeveloperSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
    void open(Widget page) => Navigator.push(context, MangaRoute<void>(builder: (_) => page));
    return SettingsSection(
      title: s.sectionDeveloper,
      sub: s.other.sectionDeveloper,
      children: [
        SettingsGroup(children: [
          SettingsSwitch(
            title: s.developerMode,
            value: settings.debugMode,
            onChanged: (v) => progress.updateSettings(settings.copyWith(debugMode: v)),
          ),
          SettingsSwitch(
            title: 'Play overlay',
            value: settings.playOverlay,
            onChanged: (v) => progress.updateSettings(settings.copyWith(playOverlay: v)),
          ),
          SettingsSwitch(
            title: 'Performance overlay',
            value: settings.showPerformanceOverlay,
            onChanged: (v) => progress.updateSettings(settings.copyWith(showPerformanceOverlay: v)),
          ),
        ]),
        SettingsGroup(children: [
          SettingsTapRow(title: 'Debug page', opensPage: true, onTap: () => open(const DebugPage())),
          SettingsTapRow(title: 'Simulation', opensPage: true, onTap: () => open(const SimulationPage())),
          SettingsTapRow(title: 'Preview celebrations', onTap: () => previewCelebrations(context)),
          SettingsTapRow(title: 'Preview XP', onTap: () => previewXp(context)),
          SettingsTapRow(title: 'Preview XP + level up', onTap: () => previewXpLevelUp(context)),
          SettingsTapRow(title: 'Preview rating', onTap: () => previewRating(context)),
          SettingsTapRow(title: 'Preview rating + rank-up', onTap: () => previewRatingRankUp(context)),
          SettingsTapRow(title: 'Preview graduation', onTap: () => previewGraduation(context)),
          SettingsTapRow(
            title: 'Preview all-known warning',
            onTap: () => Navigator.push(context, MangaRoute<bool>(builder: (_) => HoldWarningScreen.allKnown(s))),
          ),
        ]),
        SettingsGroup(children: [
          SettingsTapRow(title: 'Reset onboarding', onTap: () => confirmResetOnboarding(context)),
          SettingsTapRow(title: 'Reset progress', onTap: () => confirmResetProgress(context)),
        ]),
      ],
    );
  }
}
