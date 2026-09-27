import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../state/scope.dart';
import '../state/settings.dart';

/// UI strings, English and Japanese side by side. Karuta content (kimariji,
/// poems, set names) is always Japanese and does not go through here.
///
/// Features add their own strings in an `extension FooStrings on S` using [t].
/// Templates mark numbers as `{0}`, `{1}` … so `NumberedText` can set them in
/// display type.
class S {
  const S(this.ja);

  final bool ja;

  static S of(BuildContext context) => S(isJapanese(ProgressScope.of(context).settings.language));

  static bool isJapanese(AppLanguage lang) => switch (lang) {
        AppLanguage.ja => true,
        AppLanguage.en => false,
        AppLanguage.system => PlatformDispatcher.instance.locale.languageCode == 'ja',
      };

  /// The same strings in the other language (for bilingual sub-labels).
  S get other => S(!ja);

  String t(String en, String jp) => ja ? jp : en;

  // Modes
  String get training => t('Training', '修行');
  String get startTraining => t('Start training', '修行スタート');
  String get freePlay => t('Free play', '札落とし');
  String get weakCards => t('Weak cards', '苦手');
  String get guest => t('Guest', 'ゲスト');
  String get untracked => t('untracked', '記録なし');
  String get guestNote => t(
        'We recommend always using SRS mode. Only use guest mode when you let someone else use your phone.',
        'いつもは修行モード（SRS）をおすすめします。ゲストモードは他の人に端末を貸すときだけ使ってください。',
      );

  // Navigation
  String get home => t('Home', 'ホーム');
  String get history => t('History', '履歴');
  String get stats => t('Stats', '成績');
  String get help => t('Help', '解説');
  String get settings => t('Settings', '設定');
  String get rank => t('Rank', '級');
  String get debug => t('Debug', 'デバッグ');
  String get back => t('Back', '戻る');
  String get cancel => t('Cancel', 'やめる');
  String get comingSoon => t('Coming soon', '準備中');

  // Play
  String get start => t('Start', '開始');
  String get undo => t('Undo', 'ひとつ前');
  String get end => t('End', '終了');
  String get again => t('Again', 'もう一回');
  String get done => t('Done', '完了');
  String get dontKnow => t("Don't know", 'わからない');
  String get tapToStart => t('Tap to start', 'タップで開始');

  // Results
  String get totalTime => t('Total time', '合計タイム');
  String get perCard => t('per card', '1枚あたり');
  String get personalBest => t('Personal best!', '自己ベスト！');
  String get previousBest => t('previous', '前回ベスト');
  String get slowest => t('Toughest cards', '手強い札');
  String get newCard => t('A new card appears!', '新しい札が現れた！');
  String get newCards => t('New cards appear!', '新しい札が現れた！');
  String get islandComplete => t('Island complete!', '島クリア！');
  String get goalUp => t('New speed goal!', '目標タイム更新！');
  String get rating => t('Rating', 'レーティング');

  // Misc
  String cardsCount(int n) => ja ? '$n枚' : '$n cards';
  String dueCount(int n) => ja ? '復習 $n枚' : '$n due';
  String dayStreak(int n) => ja ? '$n日連続' : '$n-day streak';
  String toNext(int points, String band) => ja ? '$bandまであと$points' : '$points to $band';
}
