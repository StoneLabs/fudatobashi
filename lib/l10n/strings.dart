import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../state/scope.dart';
import '../state/settings.dart';

/// UI strings, English and Japanese side by side. Karuta content (kimariji,
/// poems, set names) is always Japanese and does not go through here.
class S {
  const S(this.ja);

  final bool ja;

  static S of(BuildContext context) {
    final lang = ProgressScope.of(context).settings.language;
    return S(switch (lang) {
      AppLanguage.ja => true,
      AppLanguage.en => false,
      AppLanguage.system => PlatformDispatcher.instance.locale.languageCode == 'ja',
    });
  }

  String _(String en, String jp) => ja ? jp : en;

  // Modes
  String get training => _('Training', '修行');
  String get startTraining => _('Start training', '修行スタート');
  String get freePlay => _('Free play', '札落とし');
  String get weakCards => _('Weak cards', '苦手');
  String get guest => _('Guest', 'ゲスト');
  String get untracked => _('untracked', '記録なし');
  String get guestNote => _(
        'We recommend always using SRS mode. Only use guest mode when you let someone else use your phone.',
        'いつもは修行モード（SRS）をおすすめします。ゲストモードは他の人に端末を貸すときだけ使ってください。',
      );

  // Navigation
  String get home => _('Home', 'ホーム');
  String get history => _('History', '履歴');
  String get stats => _('Stats', '成績');
  String get help => _('Help', '解説');
  String get settings => _('Settings', '設定');
  String get rank => _('Rank', '級');
  String get debug => _('Debug', 'デバッグ');

  // Play
  String get start => _('Start', '開始');
  String get undo => _('Undo', 'ひとつ前');
  String get end => _('End', '終了');
  String get again => _('Again', 'もう一回');
  String get done => _('Done', '完了');
  String get dontKnow => _("Don't know", 'わからない');
  String get tapToStart => _('Tap to start', 'タップで開始');

  // Results
  String get totalTime => _('Total time', '合計タイム');
  String get perCard => _('per card', '1枚あたり');
  String get personalBest => _('Personal best!', '自己ベスト！');
  String get previousBest => _('previous', '前回ベスト');
  String get slowest => _('Toughest cards', '手強い札');
  String get newCard => _('A new card appears!', '新しい札が現れた！');
  String get newCards => _('New cards appear!', '新しい札が現れた！');
  String get islandComplete => _('Island complete!', '島クリア！');
  String get goalUp => _('New speed goal!', '目標タイム更新！');
  String get rating => _('Rating', 'レーティング');

  // Onboarding
  String get welcome => _('Welcome to Fudatobashi!', '札飛ばしへようこそ！');
  String get chooseStart => _('How well do you know the 100 cards?', '百人一首、どのくらい知ってる？');
  String get journeyTitle => _("I'm new", 'はじめて');
  String get journeyBody => _('Learn island by island, a few cards at a time.', '島をひとつずつ、少しずつ覚えよう。');
  String get allKnownTitle => _('I know all 100', '100首ぜんぶ知ってる');
  String get allKnownBody => _('Skip ahead: every card is in play right away.', 'すぐに100首すべてで練習。');
  String get changeLater => _('You can change this later in Settings.', 'あとで設定から変更できます。');

  // Misc
  String cardsCount(int n) => ja ? '$n枚' : '$n cards';
  String dueCount(int n) => ja ? '復習 $n枚' : '$n due';
  String dayStreak(int n) => ja ? '$n日連続' : '$n-day streak';
  String toNext(int points, String band) => ja ? '$bandまであと$points' : '$points to $band';
}
