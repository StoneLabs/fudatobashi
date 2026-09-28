import 'strings.dart';

/// Strings of the first-launch screen. Japanese marks where lines may break
/// inside a sentence with `\u200B` (see `Phrases`).
extension OnboardingStrings on S {
  /// Big lettering, Japanese in both languages.
  String get welcomeTitle => 'ようこそ!';
  String get welcomeBanner => t('WELCOME ABOARD', 'WELCOME ABOARD');
  String get tobiHello => t("Hi, I'm Tobi!", 'やあ、トビだよ！');

  /// Tobi's question, broken into balloon lines.
  String get howWell => t('How well do you know\nthe 100 cards?', '百首、\nどのくらい知ってる？');
  String get howWellOneLine => howWell.replaceAll('\n', ja ? '' : ' ');
  String get beginnerTag => t('BEGINNER', '初心者');
  String get beginnerTitle => t("I'm new", 'はじめて');
  String get beginnerSub => t('Learn island by island', '島ごとに覚える');
  String firstStop(String island, int n) => ja ? '最初の島：$island（$n枚）' : 'First stop: $island, $n cards.';
  String get expertTag => t('I KNOW THEM', '全部知ってる');
  String get expertTitle => t('I know all 100', '100首ぜんぶ');
  String get expertSub => t('Skip ahead', 'スキップ');
  String get expertNote => t('All cards unlocked from day one.', '初日から全札が解放されます。');
  String get changeLaterBefore => t('Not sure? Change this later in ', '迷ったら\u200B大丈夫。\u200Bあとで ');
  String get changeLaterWhere => t('Settings › Learning mode', '設定 › 学習モード');
  String get changeLaterAfter => t('.', ' から\u200B変更\u200Bできます。');

  String get paceBanner => t('PICK YOUR PACE', 'PICK YOUR PACE');
  String get howFast => t('How fast shall we sail?', 'どのペースで進む？');
  String get relaxedTag => t('RELAXED', 'のんびり');
  String get relaxedCall => t('Nice and easy ♪', 'のんびり行こう♪');
  String get relaxedTitle => t('About 1 month', '約1か月');
  String get relaxedSub => t('A few rounds a day', '1日に\u200B数ラウンド');
  String get relaxedNote =>
      t('About 30 cards after a week, 60 after two.', '1週間で\u200B約30枚、\u200B2週間で\u200B約60枚。');
  String get sprintTag => t('SPRINT', '特訓');
  String get sprintCall => t('All out!', '全力だ！');
  String get sprintTitle => t('About 15 days', '約15日');
  String get sprintSub => t('New cards twice as fast', '新しい札が\u200B2倍の\u200Bペース');
  String get sprintNote => t('Honest warning: needs a lot more practice every day.',
      '正直に\u200B言うと、\u200B毎日\u200Bかなり\u200B多めの\u200B練習が\u200B必要。');
  String get paceLaterWhere => t('Settings › Pace', '設定 › ペース');
}
