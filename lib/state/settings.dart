import '../config/config.dart';
import '../domain/card_mask.dart';
import 'play_config.dart';

enum AppLanguage { system, en, ja }

/// User preferences (persisted as JSON).
class AppSettings {
  const AppSettings({
    this.language = DefaultSettings.language,
    this.downMeansDontKnow = DefaultSettings.downMeansDontKnow,
    this.downToleranceDeg = DefaultSettings.downToleranceDeg,
    this.showPoemNumber = DefaultSettings.showPoemNumber,
    this.haptics = DefaultSettings.haptics,
    this.leadIn = DefaultSettings.leadIn,
    this.sfxEffects = DefaultSettings.sfxEffects,
    this.showRunningTimer = DefaultSettings.showRunningTimer,
    this.freePlay = DefaultSettings.freePlay,
    this.nigateCount = DefaultSettings.nigateCount,
    this.maskStyle = DefaultSettings.maskStyle,
    this.debugMode = DefaultSettings.debugMode,
    this.onboarded = DefaultSettings.onboarded,
    this.playOverlay = DefaultSettings.playOverlay,
    this.showPerformanceOverlay = DefaultSettings.showPerformanceOverlay,
  });

  final AppLanguage language;

  /// A swipe straight down means "don't know" (off: every swipe is "known").
  final bool downMeansDontKnow;
  final double downToleranceDeg;
  final bool showPoemNumber;
  final bool haptics;

  /// Short "開始" lead-in before the first card.
  final bool leadIn;

  /// Coloured SFX pop for a fast correct card (see [PlaySfxTuning]).
  final bool sfxEffects;
  final bool showRunningTimer;

  /// Last free-play setup (表示する札を限定する).
  final PlayConfig freePlay;
  final int nigateCount;
  final MaskStyle maskStyle;

  /// Shows the nerd pages (FSRS state, scheduler, timing diagnostics).
  final bool debugMode;

  /// The first-launch journey / all-known choice has been made.
  final bool onboarded;

  /// Dev-mode corner readout of the last attempt's timing during play.
  final bool playOverlay;

  /// Dev-mode `PerformanceOverlay`.
  final bool showPerformanceOverlay;

  Map<String, Object> toJson() => {
        'language': language.name,
        'downMeansDontKnow': downMeansDontKnow,
        'downToleranceDeg': downToleranceDeg,
        'showPoemNumber': showPoemNumber,
        'haptics': haptics,
        'leadIn': leadIn,
        'sfxEffects': sfxEffects,
        'showRunningTimer': showRunningTimer,
        'freePlay': freePlay.toJson(),
        'nigateCount': nigateCount,
        'maskStyle': maskStyle.name,
        'debugMode': debugMode,
        'onboarded': onboarded,
        'playOverlay': playOverlay,
        'showPerformanceOverlay': showPerformanceOverlay,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        language: AppLanguage.values.asNameMap()[j['language']] ?? DefaultSettings.language,
        downMeansDontKnow: j['downMeansDontKnow'] as bool? ?? DefaultSettings.downMeansDontKnow,
        downToleranceDeg: (j['downToleranceDeg'] as num?)?.toDouble() ?? DefaultSettings.downToleranceDeg,
        showPoemNumber: j['showPoemNumber'] as bool? ?? DefaultSettings.showPoemNumber,
        haptics: j['haptics'] as bool? ?? DefaultSettings.haptics,
        leadIn: j['leadIn'] as bool? ?? DefaultSettings.leadIn,
        sfxEffects: j['sfxEffects'] as bool? ?? DefaultSettings.sfxEffects,
        showRunningTimer: j['showRunningTimer'] as bool? ?? DefaultSettings.showRunningTimer,
        freePlay: j['freePlay'] is Map
            ? PlayConfig.fromJson((j['freePlay'] as Map).cast<String, dynamic>())
            : DefaultSettings.freePlay,
        nigateCount: j['nigateCount'] as int? ?? DefaultSettings.nigateCount,
        maskStyle: MaskStyle.values.asNameMap()[j['maskStyle']] ?? DefaultSettings.maskStyle,
        debugMode: j['debugMode'] as bool? ?? DefaultSettings.debugMode,
        onboarded: j['onboarded'] as bool? ?? DefaultSettings.onboarded,
        playOverlay: j['playOverlay'] as bool? ?? DefaultSettings.playOverlay,
        showPerformanceOverlay:
            j['showPerformanceOverlay'] as bool? ?? DefaultSettings.showPerformanceOverlay,
      );

  AppSettings copyWith({
    AppLanguage? language,
    bool? downMeansDontKnow,
    double? downToleranceDeg,
    bool? showPoemNumber,
    bool? haptics,
    bool? leadIn,
    bool? sfxEffects,
    bool? showRunningTimer,
    PlayConfig? freePlay,
    int? nigateCount,
    MaskStyle? maskStyle,
    bool? debugMode,
    bool? onboarded,
    bool? playOverlay,
    bool? showPerformanceOverlay,
  }) =>
      AppSettings(
        language: language ?? this.language,
        downMeansDontKnow: downMeansDontKnow ?? this.downMeansDontKnow,
        downToleranceDeg: downToleranceDeg ?? this.downToleranceDeg,
        showPoemNumber: showPoemNumber ?? this.showPoemNumber,
        haptics: haptics ?? this.haptics,
        leadIn: leadIn ?? this.leadIn,
        sfxEffects: sfxEffects ?? this.sfxEffects,
        showRunningTimer: showRunningTimer ?? this.showRunningTimer,
        freePlay: freePlay ?? this.freePlay,
        nigateCount: nigateCount ?? this.nigateCount,
        maskStyle: maskStyle ?? this.maskStyle,
        debugMode: debugMode ?? this.debugMode,
        onboarded: onboarded ?? this.onboarded,
        playOverlay: playOverlay ?? this.playOverlay,
        showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
      );
}
