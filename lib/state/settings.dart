import '../config/config.dart';
import '../domain/card_mask.dart';
import '../domain/trainer.dart';
import 'play_config.dart';

/// How the player marks a card as "don't know" during play.
enum DontKnowInput {
  /// Swipe straight down and hold there (see `SwipeTuning.dontKnowHoldDwell`);
  /// a quick down flick is an ordinary known swipe.
  hold,

  /// A "don't remember" button on the play screen; every swipe is known.
  button,

  /// No don't-know marking at all. Only offered in all-known mode.
  off,
}

/// User preferences (persisted as JSON).
class AppSettings {
  const AppSettings({
    this.language = DefaultSettings.language,
    this.dontKnowInput = DefaultSettings.dontKnowInput,
    this.showPoemNumber = DefaultSettings.showPoemNumber,
    this.haptics = DefaultSettings.haptics,
    this.sfxEffects = DefaultSettings.sfxEffects,
    this.music = DefaultSettings.music,
    this.musicVolume = DefaultSettings.musicVolume,
    this.swipeSound = DefaultSettings.swipeSound,
    this.effectSounds = DefaultSettings.effectSounds,
    this.showRunningTimer = DefaultSettings.showRunningTimer,
    this.freePractice = DefaultSettings.freePractice,
    this.nigateCount = DefaultSettings.nigateCount,
    this.maskStyle = DefaultSettings.maskStyle,
    this.debugMode = DefaultSettings.debugMode,
    this.onboarded = DefaultSettings.onboarded,
    this.toured = DefaultSettings.toured,
    this.playOverlay = DefaultSettings.playOverlay,
    this.showPerformanceOverlay = DefaultSettings.showPerformanceOverlay,
    this.languagePicked = DefaultSettings.languagePicked,
  });

  /// A language code (e.g. `'ja'`), or `'system'` for the device's language.
  final String language;

  /// The first-open language picker has been resolved (a language chosen,
  /// there or in Settings), so it never shows again.
  final bool languagePicked;

  /// The stored choice; read it through [dontKnowInputFor].
  final DontKnowInput dontKnowInput;
  final bool showPoemNumber;
  final bool haptics;

  /// Coloured SFX pop for a fast correct card (see [PlaySfxTuning]).
  final bool sfxEffects;

  /// The sound switches, one per [SoundCategory]; read them through
  /// [plays]. Silent or vibrate mode still mutes everything.
  final bool music;

  /// The music volume slider's position, 0–1, which `Music.gainFor` turns
  /// into the player's gain; only meaningful while [music] is on.
  final double musicVolume;
  final bool swipeSound;
  final bool effectSounds;
  final bool showRunningTimer;

  /// Free practice's last setup (its deck and 隠し字).
  final FreePracticeSetup freePractice;
  final int nigateCount;
  final MaskStyle maskStyle;

  /// Shows the nerd pages (FSRS state, scheduler, timing diagnostics).
  final bool debugMode;

  /// The first-launch journey / all-known choice has been made.
  final bool onboarded;

  /// Tobi's tour of Home is done; set back to false to take it again.
  final bool toured;

  /// Dev-mode corner readout of the last attempt's timing during play.
  final bool playOverlay;

  /// Dev-mode `PerformanceOverlay`.
  final bool showPerformanceOverlay;

  /// Whether sounds of [category] are switched on.
  bool plays(SoundCategory category) => switch (category) {
        SoundCategory.music => music,
        SoundCategory.swipe => swipeSound,
        SoundCategory.effects => effectSounds,
      };

  /// The don't-know input in effect: journey mode has no "off" and falls
  /// back to [DontKnowInput.hold].
  DontKnowInput dontKnowInputFor(LearningMode mode) =>
      mode == LearningMode.journey && dontKnowInput == DontKnowInput.off ? DontKnowInput.hold : dontKnowInput;

  Map<String, Object> toJson() => {
        'language': language,
        'dontKnowInput': dontKnowInput.name,
        'showPoemNumber': showPoemNumber,
        'haptics': haptics,
        'sfxEffects': sfxEffects,
        'music': music,
        'musicVolume': musicVolume,
        'swipeSound': swipeSound,
        'effectSounds': effectSounds,
        'showRunningTimer': showRunningTimer,
        'freePractice': freePractice.toJson(),
        'nigateCount': nigateCount,
        'maskStyle': maskStyle.name,
        'debugMode': debugMode,
        'onboarded': onboarded,
        'toured': toured,
        'playOverlay': playOverlay,
        'showPerformanceOverlay': showPerformanceOverlay,
        'languagePicked': languagePicked,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    // The single `sounds` switch from before the split into music, swipe and
    // other sounds: turned off, it turns all three off.
    final sounds = j['sounds'] as bool?;
    return AppSettings(
      // The old `AppLanguage` enum's stored name ("system"/"en"/"ja") is
      // already the language code or "system" this field now holds.
      language: j['language'] as String? ?? DefaultSettings.language,
      // A truly fresh install has no settings saved at all (`j` is empty):
      // the first-open picker still has to run. Any prior settings, even
      // from before this field existed, mean it doesn't.
      languagePicked: j['languagePicked'] as bool? ?? j.isNotEmpty,
      dontKnowInput: DontKnowInput.values.asNameMap()[j['dontKnowInput']] ?? DefaultSettings.dontKnowInput,
      showPoemNumber: j['showPoemNumber'] as bool? ?? DefaultSettings.showPoemNumber,
      haptics: j['haptics'] as bool? ?? DefaultSettings.haptics,
      sfxEffects: j['sfxEffects'] as bool? ?? DefaultSettings.sfxEffects,
      music: j['music'] as bool? ?? sounds ?? DefaultSettings.music,
      musicVolume: (j['musicVolume'] as num?)?.toDouble() ?? DefaultSettings.musicVolume,
      swipeSound: j['swipeSound'] as bool? ?? sounds ?? DefaultSettings.swipeSound,
      effectSounds: j['effectSounds'] as bool? ?? sounds ?? DefaultSettings.effectSounds,
      showRunningTimer: j['showRunningTimer'] as bool? ?? DefaultSettings.showRunningTimer,
      // The old `freePlay` entry (set ids, orientation) is dropped: free
      // practice starts over at its default deck, which counts for SRS.
      freePractice: j['freePractice'] is Map
          ? FreePracticeSetup.fromJson((j['freePractice'] as Map).cast<String, dynamic>())
          : DefaultSettings.freePractice,
      nigateCount: j['nigateCount'] as int? ?? DefaultSettings.nigateCount,
      maskStyle: MaskStyle.values.asNameMap()[j['maskStyle']] ?? DefaultSettings.maskStyle,
      debugMode: j['debugMode'] as bool? ?? DefaultSettings.debugMode,
      onboarded: j['onboarded'] as bool? ?? DefaultSettings.onboarded,
      toured: j['toured'] as bool? ?? DefaultSettings.toured,
      playOverlay: j['playOverlay'] as bool? ?? DefaultSettings.playOverlay,
      showPerformanceOverlay:
          j['showPerformanceOverlay'] as bool? ?? DefaultSettings.showPerformanceOverlay,
    );
  }

  AppSettings copyWith({
    String? language,
    DontKnowInput? dontKnowInput,
    bool? showPoemNumber,
    bool? haptics,
    bool? sfxEffects,
    bool? music,
    double? musicVolume,
    bool? swipeSound,
    bool? effectSounds,
    bool? showRunningTimer,
    FreePracticeSetup? freePractice,
    int? nigateCount,
    MaskStyle? maskStyle,
    bool? debugMode,
    bool? onboarded,
    bool? toured,
    bool? playOverlay,
    bool? showPerformanceOverlay,
    bool? languagePicked,
  }) =>
      AppSettings(
        language: language ?? this.language,
        dontKnowInput: dontKnowInput ?? this.dontKnowInput,
        showPoemNumber: showPoemNumber ?? this.showPoemNumber,
        haptics: haptics ?? this.haptics,
        sfxEffects: sfxEffects ?? this.sfxEffects,
        music: music ?? this.music,
        musicVolume: musicVolume ?? this.musicVolume,
        swipeSound: swipeSound ?? this.swipeSound,
        effectSounds: effectSounds ?? this.effectSounds,
        showRunningTimer: showRunningTimer ?? this.showRunningTimer,
        freePractice: freePractice ?? this.freePractice,
        nigateCount: nigateCount ?? this.nigateCount,
        maskStyle: maskStyle ?? this.maskStyle,
        debugMode: debugMode ?? this.debugMode,
        onboarded: onboarded ?? this.onboarded,
        toured: toured ?? this.toured,
        playOverlay: playOverlay ?? this.playOverlay,
        showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
        languagePicked: languagePicked ?? this.languagePicked,
      );
}
