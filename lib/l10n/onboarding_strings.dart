import 'strings.dart';

/// Strings of the first-launch screen.
extension OnboardingStrings on S {
  String get welcomeBanner => t('WELCOME ABOARD', 'WELCOME ABOARD');
  String get tobiHello => t("Hi, I'm Tobi!", 'やあ、トビだよ！');
  String get howWell => t('How well do you know the 100 cards?', '百首、どのくらい知ってる？');
  String get beginnerTag => 'BEGINNER · 初心者';
  String get beginnerTitle => t("I'm new", 'はじめて');
  String get beginnerSub => t('Learn island by island', '島ごとに覚える');
  String firstStop(String island, int n) => ja ? '最初の島：$island（$n枚）' : 'First stop: $island, $n cards.';
  String get expertTag => 'I KNOW THEM · 全部知ってる';
  String get expertTitle => t('I know all 100', '100首ぜんぶ');
  String get expertSub => t('Skip ahead', 'スキップ');
  String get expertNote => t('All cards unlocked from day one.', '初日から全札が解放されます。');
  String get changeLaterBefore => t('Not sure? You can change this later in ', '迷ったら大丈夫。あとで ');
  String get changeLaterWhere => t('Settings › Learning mode', '設定 › 学習モード');
  String get changeLaterAfter => t('.', ' から変更できます。');
}
