import '../config/config.dart';
import '../domain/card_mask.dart';
import 'play_config.dart';

enum AppLanguage { system, en, ja }

/// User preferences (persisted as JSON).
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.downMeansDontKnow = true,
    this.downToleranceDeg = DefaultSettings.downToleranceDeg,
    this.showPoemNumber = true,
    this.haptics = true,
    this.leadIn = true,
    this.showRunningTimer = false,
    this.freePlay = const PlayConfig(mode: PlayMode.free),
    this.nigateCount = DefaultSettings.nigateCount,
    this.maskStyle = MaskStyle.scramble,
    this.debugMode = false,
    this.onboarded = false,
  });

  final AppLanguage language;

  /// A swipe straight down means "don't know" (off: every swipe is "known").
  final bool downMeansDontKnow;
  final double downToleranceDeg;
  final bool showPoemNumber;
  final bool haptics;

  /// Short "開始" lead-in before the first card.
  final bool leadIn;
  final bool showRunningTimer;

  /// Last free-play setup (表示する札を限定する).
  final PlayConfig freePlay;
  final int nigateCount;
  final MaskStyle maskStyle;

  /// Shows the nerd pages (FSRS state, scheduler, timing diagnostics).
  final bool debugMode;

  /// The first-launch journey / all-known choice has been made.
  final bool onboarded;

  Map<String, Object> toJson() => {
        'language': language.name,
        'downMeansDontKnow': downMeansDontKnow,
        'downToleranceDeg': downToleranceDeg,
        'showPoemNumber': showPoemNumber,
        'haptics': haptics,
        'leadIn': leadIn,
        'showRunningTimer': showRunningTimer,
        'freePlay': freePlay.toJson(),
        'nigateCount': nigateCount,
        'maskStyle': maskStyle.name,
        'debugMode': debugMode,
        'onboarded': onboarded,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        language: AppLanguage.values.asNameMap()[j['language']] ?? AppLanguage.system,
        downMeansDontKnow: j['downMeansDontKnow'] as bool? ?? true,
        downToleranceDeg: (j['downToleranceDeg'] as num?)?.toDouble() ?? DefaultSettings.downToleranceDeg,
        showPoemNumber: j['showPoemNumber'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        leadIn: j['leadIn'] as bool? ?? true,
        showRunningTimer: j['showRunningTimer'] as bool? ?? false,
        freePlay: j['freePlay'] is Map
            ? PlayConfig.fromJson((j['freePlay'] as Map).cast<String, dynamic>())
            : const PlayConfig(mode: PlayMode.free),
        nigateCount: j['nigateCount'] as int? ?? DefaultSettings.nigateCount,
        maskStyle: MaskStyle.values.asNameMap()[j['maskStyle']] ?? MaskStyle.scramble,
        debugMode: j['debugMode'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
      );

  AppSettings copyWith({
    AppLanguage? language,
    bool? downMeansDontKnow,
    double? downToleranceDeg,
    bool? showPoemNumber,
    bool? haptics,
    bool? leadIn,
    bool? showRunningTimer,
    PlayConfig? freePlay,
    int? nigateCount,
    MaskStyle? maskStyle,
    bool? debugMode,
    bool? onboarded,
  }) =>
      AppSettings(
        language: language ?? this.language,
        downMeansDontKnow: downMeansDontKnow ?? this.downMeansDontKnow,
        downToleranceDeg: downToleranceDeg ?? this.downToleranceDeg,
        showPoemNumber: showPoemNumber ?? this.showPoemNumber,
        haptics: haptics ?? this.haptics,
        leadIn: leadIn ?? this.leadIn,
        showRunningTimer: showRunningTimer ?? this.showRunningTimer,
        freePlay: freePlay ?? this.freePlay,
        nigateCount: nigateCount ?? this.nigateCount,
        maskStyle: maskStyle ?? this.maskStyle,
        debugMode: debugMode ?? this.debugMode,
        onboarded: onboarded ?? this.onboarded,
      );
}
