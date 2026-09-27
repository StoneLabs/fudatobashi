import 'strings.dart';

/// Strings of the settings screen.
extension SettingsStrings on S {
  String get learningJourney => t('Journey', '島めぐり');
  String get learningAllKnown => t('All 100 known', '100首ぜんぶ');
  String get cardEffects => t('Card effects', '演出エフェクト');

  String get about => t('About', 'このアプリについて');
  String get version => t('Version', 'バージョン');
  String tapsRemaining(int n) => ja ? 'あと$nタップ…' : '$n more tap${n == 1 ? '' : 's'}…';
  String get devModeUnlocked => t('Developer mode unlocked', '開発者モードが有効になりました');
  String get developerMode => t('Developer mode', '開発者モード');
}
