import '../config/config.dart';
import '../domain/ankiren_level.dart';
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

/// Which script a card's kimariji (決まり字) is shown in; read it through
/// `kimarijiFor` (`lib/l10n/strings.dart`), which also resolves [auto].
enum KimarijiScript {
  /// Follows the UI language: hiragana for Japanese, romaji otherwise.
  auto,

  /// The hiragana reading straight from the card data.
  hiragana,

  /// Lowercase Hepburn romaji of how it's read in competitive karuta.
  romaji,
}

extension KimarijiScriptResolution on KimarijiScript {
  /// Resolves [KimarijiScript.auto] against the UI language; any explicit
  /// choice passes through unchanged.
  KimarijiScript resolve({required bool uiJapanese}) =>
      this == KimarijiScript.auto ? (uiJapanese ? KimarijiScript.hiragana : KimarijiScript.romaji) : this;
}

/// How the sound ladder on a card's About page breaks its first sounds
/// down.
enum SoundLadderMode {
  /// Each kana whole, then only its consonant.
  sounds,

  /// Whole kana only.
  kana,
}

/// How 暗記練 lays out its field.
enum AnkirenLayout {
  /// Portrait, each half folded to its clusters (the open middle closed,
  /// empty rows dropped), so the cards come out as big as they can.
  portrait,

  /// Landscape, the field at its true proportions.
  landscape,
}

/// How 暗記練 asks for each card in recall.
enum AnkirenPrompt {
  /// Its kimariji, written and read out.
  textAndVoice,

  /// Its kimariji, written only.
  textOnly,
}

/// 暗記練's options (Settings › 寄り道 › 暗記練) and its free play's last
/// setup.
class AnkirenSettings {
  const AnkirenSettings({
    this.layout = DefaultSettings.ankirenLayout,
    this.prompt = DefaultSettings.ankirenPrompt,
    this.freeLevel = DefaultSettings.ankirenFreeLevel,
    this.customPerSide = DefaultSettings.ankirenCustomPerSide,
    this.customMemorise = DefaultSettings.ankirenCustomMemorise,
    this.rulesSeen = DefaultSettings.ankirenRulesSeen,
  });

  final AnkirenLayout layout;
  final AnkirenPrompt prompt;

  /// Free play's last level preset, or null when its last setup was custom.
  final int? freeLevel;

  /// Free play's custom setup, kept while a preset is chosen.
  final int customPerSide;
  final Duration customMemorise;

  /// The rules (遊び方) have been shown once, so 暗記練's page no longer
  /// opens with them.
  final bool rulesSeen;

  /// Free play's last setup.
  AnkirenSetup get freeSetup => freeLevel == null
      ? AnkirenSetup.custom(perSide: customPerSide, memorise: customMemorise)
      : AnkirenSetup.forLevel(freeLevel!);

  /// These settings with [setup] as free play's last one.
  AnkirenSettings withFreeSetup(AnkirenSetup setup) => AnkirenSettings(
        layout: layout,
        prompt: prompt,
        freeLevel: setup.level,
        customPerSide: setup.level == null ? setup.perSide : customPerSide,
        customMemorise: setup.level == null ? setup.memorise : customMemorise,
        rulesSeen: rulesSeen,
      );

  Map<String, Object?> toJson() => {
        'layout': layout.name,
        'prompt': prompt.name,
        'freeLevel': freeLevel,
        'customPerSide': customPerSide,
        'customMemoriseMs': customMemorise.inMilliseconds,
        'rulesSeen': rulesSeen,
      };

  factory AnkirenSettings.fromJson(Map<String, dynamic> j) {
    final level = j.containsKey('freeLevel') ? j['freeLevel'] as int? : DefaultSettings.ankirenFreeLevel;
    final memoriseMs = j['customMemoriseMs'] as int?;
    return AnkirenSettings(
      layout: AnkirenLayout.values.asNameMap()[j['layout']] ?? DefaultSettings.ankirenLayout,
      prompt: AnkirenPrompt.values.asNameMap()[j['prompt']] ?? DefaultSettings.ankirenPrompt,
      freeLevel: level?.clamp(0, AnkirenLevels.top),
      customPerSide: (j['customPerSide'] as int? ?? DefaultSettings.ankirenCustomPerSide)
          .clamp(AnkirenTuning.customMinPerSide, AnkirenTuning.customMaxPerSide),
      customMemorise: memoriseMs == null
          ? DefaultSettings.ankirenCustomMemorise
          : Duration(
              milliseconds: memoriseMs.clamp(
                  AnkirenTuning.customMinMemorise.inMilliseconds, AnkirenTuning.customMaxMemorise.inMilliseconds)),
      rulesSeen: j['rulesSeen'] as bool? ?? DefaultSettings.ankirenRulesSeen,
    );
  }

  AnkirenSettings copyWith({AnkirenLayout? layout, AnkirenPrompt? prompt, bool? rulesSeen}) => AnkirenSettings(
        layout: layout ?? this.layout,
        prompt: prompt ?? this.prompt,
        freeLevel: freeLevel,
        customPerSide: customPerSide,
        customMemorise: customMemorise,
        rulesSeen: rulesSeen ?? this.rulesSeen,
      );
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
    this.dayStartHour = TodaySetTuning.defaultDayStartHour,
    this.maskStyle = DefaultSettings.maskStyle,
    this.debugMode = DefaultSettings.debugMode,
    this.onboarded = DefaultSettings.onboarded,
    this.toured = DefaultSettings.toured,
    this.playOverlay = DefaultSettings.playOverlay,
    this.showPerformanceOverlay = DefaultSettings.showPerformanceOverlay,
    this.fastTobi = DefaultSettings.fastTobi,
    this.languagePicked = DefaultSettings.languagePicked,
    this.kimarijiScript = DefaultSettings.kimarijiScript,
    this.accessibilityMode = DefaultSettings.accessibilityMode,
    this.cardPanelSwiped = DefaultSettings.cardPanelSwiped,
    this.timerNotificationsAsked = DefaultSettings.timerNotificationsAsked,
    this.reminders = DefaultSettings.reminders,
    this.remindersOffered = DefaultSettings.remindersOffered,
    this.soundLadder = DefaultSettings.soundLadder,
    this.cardScale = DefaultSettings.cardScale,
    this.ankiren = DefaultSettings.ankiren,
    this.teiichiRulesSeen = DefaultSettings.teiichiRulesSeen,
    this.teiichiCards = DefaultSettings.teiichiCards,
    this.teiichiRows = DefaultSettings.teiichiRows,
    this.teiichiAutoTurn = DefaultSettings.teiichiAutoTurn,
    this.teiichiTurnTipOff = DefaultSettings.teiichiTurnTipOff,
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

  /// The local hour at which a new day begins (journey: today's set, new
  /// cards, the daily bonus, streaks and week stamps).
  final int dayStartHour;
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

  /// Dev mode: Tobi takes `ExamDevTuning.fastTobiMs` in the graduation exam.
  final bool fastTobi;

  /// The player's choice of kimariji script; read it through `kimarijiFor`.
  final KimarijiScript kimarijiScript;

  /// Easier to see and tap: bigger cards, at the cost of fitting less on
  /// screen. Only 暗記練 reads it so far (its field zooms in and pans).
  final bool accessibilityMode;

  /// The card on an About page has been swiped once, so its SWIPE sticker
  /// no longer shows.
  final bool cardPanelSwiped;

  /// 定位置's rules have been shown, so its page no longer opens with them.
  final bool teiichiRulesSeen;

  /// 定位置's last setup picked in its custom game sheet.
  final int teiichiCards;
  final int teiichiRows;

  /// 定位置's game turns the screen sideways; else it follows how the phone
  /// is held (Settings › 寄り道 › 定位置).
  final bool teiichiAutoTurn;

  /// The tip to turn the phone, on a portrait game, is not to show again.
  final bool teiichiTurnTipOff;

  /// The match timer has asked once to show its notification, so it never
  /// asks again.
  final bool timerNotificationsAsked;

  /// The daily training reminders are on (journey mode only; see
  /// `Reminders`).
  final bool reminders;

  /// Results has offered the daily reminders once, so it never offers them
  /// again.
  final bool remindersOffered;

  /// The About pages' choice of sound ladder.
  final SoundLadderMode soundLadder;

  /// How big the swipe cards are, as a share of their full size (see
  /// `playCardSize`).
  final double cardScale;

  /// 暗記練's options and its free play's last setup.
  final AnkirenSettings ankiren;

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
        'dayStartHour': dayStartHour,
        'maskStyle': maskStyle.name,
        'debugMode': debugMode,
        'onboarded': onboarded,
        'toured': toured,
        'playOverlay': playOverlay,
        'showPerformanceOverlay': showPerformanceOverlay,
        'fastTobi': fastTobi,
        'languagePicked': languagePicked,
        'kimarijiScript': kimarijiScript.name,
        'accessibilityMode': accessibilityMode,
        'cardPanelSwiped': cardPanelSwiped,
        'timerNotificationsAsked': timerNotificationsAsked,
        'reminders': reminders,
        'remindersOffered': remindersOffered,
        'soundLadder': soundLadder.name,
        'cardScale': cardScale,
        'ankiren': ankiren.toJson(),
        'teiichiRulesSeen': teiichiRulesSeen,
        'teiichiCards': teiichiCards,
        'teiichiRows': teiichiRows,
        'teiichiAutoTurn': teiichiAutoTurn,
        'teiichiTurnTipOff': teiichiTurnTipOff,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    // The single `sounds` switch from before the split into music, swipe and
    // other sounds: turned off, it turns all three off.
    final sounds = j['sounds'] as bool?;
    final ankiren = j['ankiren'] is Map ? (j['ankiren'] as Map).cast<String, dynamic>() : null;
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
      dayStartHour: (j['dayStartHour'] as int? ?? TodaySetTuning.defaultDayStartHour)
          .clamp(TodaySetTuning.firstDayStartHour, TodaySetTuning.lastDayStartHour),
      maskStyle: MaskStyle.values.asNameMap()[j['maskStyle']] ?? DefaultSettings.maskStyle,
      debugMode: j['debugMode'] as bool? ?? DefaultSettings.debugMode,
      onboarded: j['onboarded'] as bool? ?? DefaultSettings.onboarded,
      toured: j['toured'] as bool? ?? DefaultSettings.toured,
      playOverlay: j['playOverlay'] as bool? ?? DefaultSettings.playOverlay,
      showPerformanceOverlay:
          j['showPerformanceOverlay'] as bool? ?? DefaultSettings.showPerformanceOverlay,
      fastTobi: j['fastTobi'] as bool? ?? DefaultSettings.fastTobi,
      kimarijiScript: KimarijiScript.values.asNameMap()[j['kimarijiScript']] ?? DefaultSettings.kimarijiScript,
      // 暗記練's own zoom switch became this app-wide one.
      accessibilityMode:
          j['accessibilityMode'] as bool? ?? ankiren?['zoom'] as bool? ?? DefaultSettings.accessibilityMode,
      cardPanelSwiped: j['cardPanelSwiped'] as bool? ?? DefaultSettings.cardPanelSwiped,
      timerNotificationsAsked: j['timerNotificationsAsked'] as bool? ?? DefaultSettings.timerNotificationsAsked,
      reminders: j['reminders'] as bool? ?? DefaultSettings.reminders,
      remindersOffered: j['remindersOffered'] as bool? ?? DefaultSettings.remindersOffered,
      soundLadder: SoundLadderMode.values.asNameMap()[j['soundLadder']] ?? DefaultSettings.soundLadder,
      cardScale: ((j['cardScale'] as num?)?.toDouble() ?? DefaultSettings.cardScale)
          .clamp(SwipeTuning.cardScaleMin, SwipeTuning.cardScaleMax),
      ankiren: ankiren == null ? DefaultSettings.ankiren : AnkirenSettings.fromJson(ankiren),
      teiichiRulesSeen: j['teiichiRulesSeen'] as bool? ?? DefaultSettings.teiichiRulesSeen,
      teiichiCards: (j['teiichiCards'] as int? ?? DefaultSettings.teiichiCards)
          .clamp(TeiichiTuning.minCards, TeiichiTuning.cards),
      teiichiRows: (j['teiichiRows'] as int? ?? DefaultSettings.teiichiRows).clamp(1, TeiichiTuning.rows),
      teiichiAutoTurn: j['teiichiAutoTurn'] as bool? ?? DefaultSettings.teiichiAutoTurn,
      teiichiTurnTipOff: j['teiichiTurnTipOff'] as bool? ?? DefaultSettings.teiichiTurnTipOff,
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
    int? dayStartHour,
    MaskStyle? maskStyle,
    bool? debugMode,
    bool? onboarded,
    bool? toured,
    bool? playOverlay,
    bool? showPerformanceOverlay,
    bool? fastTobi,
    bool? languagePicked,
    KimarijiScript? kimarijiScript,
    bool? accessibilityMode,
    bool? cardPanelSwiped,
    bool? timerNotificationsAsked,
    bool? reminders,
    bool? remindersOffered,
    SoundLadderMode? soundLadder,
    double? cardScale,
    AnkirenSettings? ankiren,
    bool? teiichiRulesSeen,
    int? teiichiCards,
    int? teiichiRows,
    bool? teiichiAutoTurn,
    bool? teiichiTurnTipOff,
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
        dayStartHour: dayStartHour ?? this.dayStartHour,
        maskStyle: maskStyle ?? this.maskStyle,
        debugMode: debugMode ?? this.debugMode,
        onboarded: onboarded ?? this.onboarded,
        toured: toured ?? this.toured,
        playOverlay: playOverlay ?? this.playOverlay,
        showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
        fastTobi: fastTobi ?? this.fastTobi,
        languagePicked: languagePicked ?? this.languagePicked,
        kimarijiScript: kimarijiScript ?? this.kimarijiScript,
        accessibilityMode: accessibilityMode ?? this.accessibilityMode,
        cardPanelSwiped: cardPanelSwiped ?? this.cardPanelSwiped,
        timerNotificationsAsked: timerNotificationsAsked ?? this.timerNotificationsAsked,
        reminders: reminders ?? this.reminders,
        remindersOffered: remindersOffered ?? this.remindersOffered,
        soundLadder: soundLadder ?? this.soundLadder,
        cardScale: cardScale ?? this.cardScale,
        ankiren: ankiren ?? this.ankiren,
        teiichiRulesSeen: teiichiRulesSeen ?? this.teiichiRulesSeen,
        teiichiCards: teiichiCards ?? this.teiichiCards,
        teiichiRows: teiichiRows ?? this.teiichiRows,
        teiichiAutoTurn: teiichiAutoTurn ?? this.teiichiAutoTurn,
        teiichiTurnTipOff: teiichiTurnTipOff ?? this.teiichiTurnTipOff,
      );
}
