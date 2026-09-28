import 'strings.dart';

/// Strings of the settings screen.
extension SettingsStrings on S {
  String get learningMode => t('Learning mode', '学習モード');
  String get learningJourney => t('Journey', '島めぐり');
  String get learningAllKnown => t('All 100 known', '100首ぜんぶ');
  String get pace => t('Pace', 'ペース');
  String get paceMonth => t('Relaxed · ~1 month', 'のんびり・約1か月');
  String get paceSprint => t('Sprint · ~15 days', '特訓・約15日');
  String get cardEffects => t('Card effects', '演出エフェクト');
  String get sounds => t('Sounds', '効果音');
  String get dontKnowInput => t("Marking \"don't know\"", '「わからない」の付け方');
  String get dontKnowHold => t('Swipe down and hold', '下にスワイプして長押し');
  String get dontKnowHoldSub => t('A quick flick down still counts as known', '素早く下に払えば「覚えてる」のまま');
  String get dontKnowButton => t('"Don\'t remember" button', '「覚えてない」ボタン');
  String get dontKnowButtonSub => t('Every swipe counts as known', 'スワイプはすべて「覚えてる」');
  String get dontKnowOff => t('Off', 'なし');
  String get dontKnowOffSub => t('No don\'t-know marking at all', '「わからない」を付けない');

  String get allKnownWarningTitle => t('This can\'t be undone', '取り消せません');
  String get allKnownWarningBody => t(
        'Switching to All 100 known unlocks every card for good. Journey mode will afterwards show every card '
        'and island already uncovered and discovered.',
        '「100首ぜんぶ」に切り替えると、すべての札が完全にアンロックされます。島めぐりモードに戻っても、'
            'すべての札と島がすでに発見・クリア済みとして表示されます。',
      );
  String get allKnownWarningHold => t('Hold to unlock all 100', '長押しで100首をアンロック');

  String get about => t('About', 'このアプリについて');
  String get version => t('Version', 'バージョン');
  String tapsRemaining(int n) => ja ? 'あと$nタップ…' : '$n more tap${n == 1 ? '' : 's'}…';
  String get devModeUnlocked => t('Developer mode unlocked', '開発者モードが有効になりました');
  String get developerMode => t('Developer mode', '開発者モード');
}
