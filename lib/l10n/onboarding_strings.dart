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

  String get paceBanner => t('PICK YOUR PACE', 'PICK YOUR PACE');
  String get tobiPace => t('Welcome aboard!', 'よし、出航だ！');
  String get howFast => t('How fast shall we sail?', 'どのペースで進む？');
  String get relaxedTag => 'RELAXED · のんびり';
  String get relaxedTitle => t('About 1 month', '約1か月');
  String get relaxedSub => t('A few rounds a day', '1日に数ラウンド');
  String get relaxedNote => t('About 30 cards after a week, 60 after two.', '1週間で約30枚、2週間で約60枚。');
  String get sprintTag => 'SPRINT · 特訓';
  String get sprintTitle => t('About 15 days', '約15日');
  String get sprintSub => t('New cards twice as fast', '新しい札が2倍のペース');
  String get sprintNote => t('Honest warning: needs a lot more practice every day.', '正直に言うと、毎日かなり多めの練習が必要。');
  String get paceLaterWhere => t('Settings › Pace', '設定 › ペース');
}
