import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/licenses.dart';
import '../../config/vector_art.dart';
import '../../domain/side_trips.dart';
import '../../domain/trainer.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/credits_strings.dart';
import '../../l10n/language_strings.dart';
import '../../l10n/localization.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../debug/celebration_preview.dart';
import '../debug/debug_page.dart';
import '../debug/reset_actions.dart';
import '../debug/simulation_page.dart';
import '../manga/manga.dart';
import '../play/pointer_clock.dart';
import '../run/run_launcher.dart';
import '../tour/tour_overlay.dart';
import 'credits_screen.dart';
import 'hold_warning_screen.dart';
import 'language_screen.dart';
import 'settings_rows.dart';
import 'side_trip_settings_screen.dart';

/// Settings, in sections: Language; Learning (mode, pace, the don't-know
/// input); Play; Sound; Side Trips (a page per side trip); About, whose version row hides the 10-tap
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
                        children: const [
                          SettingsGroup(children: [_LanguageRow()]),
                          _KimarijiScriptRow(),
                        ],
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
                              title: s.music,
                              note: s.musicNote,
                              value: settings.music,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(music: v)),
                            ),
                            SettingsSlider(
                              title: s.musicVolume,
                              enabled: settings.music,
                              value: settings.musicVolume,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(musicVolume: v)),
                            ),
                            SettingsSwitch(
                              title: s.swipeSound,
                              note: s.swipeSoundNote,
                              value: settings.swipeSound,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(swipeSound: v)),
                            ),
                            SettingsSwitch(
                              title: s.effectSounds,
                              note: s.effectSoundsNote,
                              value: settings.effectSounds,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(effectSounds: v)),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.sectionAccessibility,
                        sub: s.other.sectionAccessibility,
                        children: [
                          SettingsGroup(children: [
                            SettingsSwitch(
                              title: s.accessibilityMode,
                              note: s.accessibilityModeNote,
                              value: settings.accessibilityMode,
                              onChanged: (v) => progress.updateSettings(settings.copyWith(accessibilityMode: v)),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.sideTrips,
                        sub: s.other.sideTrips,
                        children: [
                          SettingsGroup(children: [
                            SettingsTapRow(
                              title: SideTrip.ankiren.label,
                              note: s.ankirenSettingsNote,
                              opensPage: true,
                              onTap: () => Navigator.push(
                                  context, MangaRoute<void>(builder: (_) => const AnkirenSettingsScreen())),
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
                            SettingsTapRow(
                              title: s.privacyPolicy,
                              opensPage: true,
                              onTap: () => Navigator.push(
                                context,
                                MangaRoute<void>(
                                  builder: (_) => LicenseTextScreen(title: s.privacyPolicy, asset: privacyPolicyAsset(ja: s.ja)),
                                ),
                              ),
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
        SettingsChoices(
          label: SettingsLabel(title: s.learningMode, note: s.learningModeNote),
          side: true,
          options: [
            SettingsOption(s.learningJourney, selected: mode == LearningMode.journey,
                onTap: () => _chooseLearningMode(context, progress, mode, LearningMode.journey)),
            SettingsOption(s.learningAllKnown, selected: mode == LearningMode.allKnown,
                onTap: () => _chooseLearningMode(context, progress, mode, LearningMode.allKnown)),
          ],
        ),
        if (mode == LearningMode.journey)
          SettingsChoices(
            label: SettingsLabel(title: s.pace, note: s.paceNote),
            side: true,
            options: [
              SettingsOption(s.paceMonth, selected: pace == LearningPace.month, onTap: () => progress.setLearningPace(LearningPace.month)),
              SettingsOption(s.paceSprint, selected: pace == LearningPace.sprint, onTap: () => progress.setLearningPace(LearningPace.sprint)),
            ],
          ),
        SettingsChoices(
          label: SettingsLabel(title: s.dontKnowInput, note: s.dontKnowInputNote),
          options: [
            SettingsOption(s.dontKnowHold, sub: s.dontKnowHoldSub, selected: dontKnow == DontKnowInput.hold,
                onTap: () => setDontKnow(DontKnowInput.hold)),
            SettingsOption(s.dontKnowButton, sub: s.dontKnowButtonSub, selected: dontKnow == DontKnowInput.button,
                onTap: () => setDontKnow(DontKnowInput.button)),
            if (mode == LearningMode.allKnown)
              SettingsOption(s.dontKnowOff, sub: s.dontKnowOffSub, selected: dontKnow == DontKnowInput.off,
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

/// Hiragana or romaji for every card's kimariji. [KimarijiScript.auto] has
/// no button of its own: whichever it resolves to (see
/// [resolvedKimarijiScript]) shows pre-selected until the player taps the
/// other one, which then becomes their explicit, standing choice.
class _KimarijiScriptRow extends StatelessWidget {
  const _KimarijiScriptRow();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final current = resolvedKimarijiScript(context);
    void choose(KimarijiScript script) => progress.updateSettings(progress.settings.copyWith(kimarijiScript: script));
    return SettingsChoices(
      label: SettingsLabel(title: s.kimarijiScript, note: s.kimarijiScriptNote),
      side: true,
      options: [
        SettingsOption(s.kimarijiHiragana,
            selected: current == KimarijiScript.hiragana, onTap: () => choose(KimarijiScript.hiragana)),
        SettingsOption(s.kimarijiRomaji, selected: current == KimarijiScript.romaji, onTap: () => choose(KimarijiScript.romaji)),
      ],
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
          const _ClockOffsetRow(),
        ]),
        SettingsGroup(children: [
          SettingsTapRow(title: 'Debug page', opensPage: true, onTap: () => open(const DebugPage())),
          SettingsTapRow(title: 'Simulation', opensPage: true, onTap: () => open(const SimulationPage())),
          SettingsTapRow(
            title: '${SideTrip.ankiren.label} test game',
            note: 'Untracked; any level, debug layers',
            onTap: () => startAnkirenTest(context),
          ),
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
          SettingsTapRow(title: 'Replay tour', onTap: () => replayTour(context)),
          SettingsTapRow(title: 'Reset onboarding', onTap: () => confirmResetOnboarding(context)),
          SettingsTapRow(title: 'Reset progress', onTap: () => confirmResetProgress(context)),
        ]),
      ],
    );
  }
}

/// How far the pointer-event clock is behind the frame clock on this
/// platform (see [PointerClock]), for testers' screenshots; a tap reads it
/// again.
class _ClockOffsetRow extends StatefulWidget {
  const _ClockOffsetRow();

  @override
  State<_ClockOffsetRow> createState() => _ClockOffsetRowState();
}

class _ClockOffsetRowState extends State<_ClockOffsetRow> {
  Future<void> _read() async {
    await PointerClock.sync();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final offset = PointerClock.offset;
    return SettingsTapRow(
      title: s.clockOffset,
      note: defaultTargetPlatform.name,
      value: offset == null
          ? s.clockOffsetUnread
          : '${(offset.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(6)} s',
      onTap: _read,
    );
  }
}
