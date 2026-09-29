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
import 'all_known_warning_screen.dart';
import 'credits_screen.dart';
import 'language_screen.dart';

/// Settings: language, learning mode, About (hides the 10-tap developer-mode
/// unlock) and, once unlocked, the Developer section.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final mode = progress.trainer.config.learningMode;
    final pace = progress.trainer.config.pace;
    Widget choice(bool selected, String label, VoidCallback onTap) => Expanded(
          child: SizedBox(
            height: ButtonMetrics.rowHeight,
            child: InkButton(
              color: selected ? Palette.sun : Palette.paper,
              onTap: selected ? null : onTap,
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
            ),
          ),
        );
    Widget modeChoice(LearningMode m, String label) =>
        choice(mode == m, label, () => _chooseLearningMode(context, progress, mode, m));
    Widget paceChoice(LearningPace p, String label) => choice(pace == p, label, () => progress.setLearningPace(p));
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: Gaps.small),
          child: Text(text, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LanguageRow(),
                      const SizedBox(height: Gaps.section),
                      label(s.learningMode),
                      Row(children: [
                        modeChoice(LearningMode.journey, s.learningJourney),
                        const SizedBox(width: Gaps.panelWide),
                        modeChoice(LearningMode.allKnown, s.learningAllKnown),
                      ]),
                      if (mode == LearningMode.journey) ...[
                        const SizedBox(height: Gaps.section),
                        label(s.pace),
                        Row(children: [
                          paceChoice(LearningPace.month, s.paceMonth),
                          const SizedBox(width: Gaps.panelWide),
                          paceChoice(LearningPace.sprint, s.paceSprint),
                        ]),
                      ],
                      const SizedBox(height: Gaps.section),
                      label(s.dontKnowInput),
                      _DontKnowInputChoice(mode: mode),
                      const SizedBox(height: Gaps.section),
                      _SwitchRow(
                        label: s.cardEffects,
                        value: progress.settings.sfxEffects,
                        onChanged: (v) => progress.updateSettings(progress.settings.copyWith(sfxEffects: v)),
                      ),
                      const SizedBox(height: Gaps.section),
                      _SwitchRow(
                        label: s.sounds,
                        value: progress.settings.sounds,
                        onChanged: (v) => progress.updateSettings(progress.settings.copyWith(sounds: v)),
                      ),
                      const SizedBox(height: Gaps.section),
                      const _AboutRow(),
                      const SizedBox(height: Gaps.small),
                      _ButtonRow(
                        label: s.credits,
                        onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const CreditsScreen())),
                      ),
                      if (progress.settings.debugMode) ...[
                        const SizedBox(height: Gaps.section),
                        const _DeveloperSection(),
                      ],
                      const SizedBox(height: Gaps.section),
                      Center(child: NarrationBox(child: Text(s.comingSoon))),
                      const SizedBox(height: Gaps.section),
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
  final confirmed = await Navigator.of(context).push(MangaRoute<bool>(builder: (_) => const AllKnownWarningScreen()));
  if (confirmed == true) await progress.switchToAllKnown();
}

/// The don't-know input; "off" is only offered in all-known mode.
class _DontKnowInputChoice extends StatelessWidget {
  const _DontKnowInputChoice({required this.mode});
  final LearningMode mode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final current = progress.settings.dontKnowInputFor(mode);
    Widget option(DontKnowInput input, String title, String sub) => Padding(
          padding: const EdgeInsets.only(bottom: Gaps.small),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ButtonMetrics.rowHeight),
            child: InkButton(
              color: current == input ? Palette.sun : Palette.paper,
              onTap: current == input
                  ? null
                  : () => progress.updateSettings(progress.settings.copyWith(dontKnowInput: input)),
              padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.small),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                  Text(sub, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small)),
                ],
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        option(DontKnowInput.hold, s.dontKnowHold, s.dontKnowHoldSub),
        option(DontKnowInput.button, s.dontKnowButton, s.dontKnowButtonSub),
        if (mode == LearningMode.allKnown) option(DontKnowInput.off, s.dontKnowOff, s.dontKnowOffSub),
      ],
    );
  }
}

/// Settings' Language row: the current choice, opening the full list
/// (`LanguageScreen`) to change it.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ProgressScope.of(context).settings;
    final current = settings.language == 'system'
        ? s.systemDefault
        : Localization.languages.firstWhere((l) => l.code == settings.language, orElse: () => LanguageOption(settings.language, settings.language)).name;
    return SizedBox(
      height: ButtonMetrics.rowHeight,
      child: InkButton(
        onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const LanguageScreen())),
        padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
        child: Row(children: [
          Expanded(child: Text(s.language, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button))),
          Text(current, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body, color: Palette.inkSoft)),
          const SizedBox(width: Gaps.small),
          MangaIcon(IconArt.chevron, size: CreditsLayout.chevron, color: Palette.mute),
        ]),
      ),
    );
  }
}

class _AboutRow extends StatefulWidget {
  const _AboutRow();

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
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
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: ButtonMetrics.rowHeight,
      child: InkButton(
        onTap: _onTap,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
        child: Row(children: [
          Expanded(
            child: Text(s.about, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
          ),
          Text(
            _version == null ? '…' : '${s.version} $_version',
            style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body, color: Palette.inkSoft),
          ),
        ]),
      ),
    );
  }
}

class _DeveloperSection extends StatelessWidget {
  const _DeveloperSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InkTag('DEVELOPER'),
        const SizedBox(height: Gaps.panel),
        _SwitchRow(
          label: s.developerMode,
          value: settings.debugMode,
          onChanged: (v) => progress.updateSettings(settings.copyWith(debugMode: v)),
        ),
        const SizedBox(height: Gaps.small),
        _ButtonRow(
          label: 'Debug page',
          onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const DebugPage())),
        ),
        const SizedBox(height: Gaps.small),
        _SwitchRow(
          label: 'Play overlay',
          value: settings.playOverlay,
          onChanged: (v) => progress.updateSettings(settings.copyWith(playOverlay: v)),
        ),
        const SizedBox(height: Gaps.small),
        _SwitchRow(
          label: 'Performance overlay',
          value: settings.showPerformanceOverlay,
          onChanged: (v) => progress.updateSettings(settings.copyWith(showPerformanceOverlay: v)),
        ),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview celebrations', onTap: () => previewCelebrations(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview XP', onTap: () => previewXp(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview XP + level up', onTap: () => previewXpLevelUp(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview rating', onTap: () => previewRating(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview rating + rank-up', onTap: () => previewRatingRankUp(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Preview graduation', onTap: () => previewGraduation(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(
          label: 'Preview all-known warning',
          onTap: () => Navigator.push(context, MangaRoute<bool>(builder: (_) => const AllKnownWarningScreen())),
        ),
        const SizedBox(height: Gaps.small),
        _ButtonRow(
          label: 'Simulation',
          onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const SimulationPage())),
        ),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Reset onboarding', onTap: () => confirmResetOnboarding(context)),
        const SizedBox(height: Gaps.small),
        _ButtonRow(label: 'Reset progress', onTap: () => confirmResetProgress(context)),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: ButtonMetrics.rowHeight,
        child: DecoratedBox(
          decoration:
              const BoxDecoration(border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.hairline))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
            child: Row(children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button))),
              Switch(value: value, onChanged: onChanged, activeThumbColor: Palette.pink),
            ]),
          ),
        ),
      );
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: ButtonMetrics.rowHeight,
        child: InkButton(
          onTap: onTap,
          child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
        ),
      );
}
