import 'strings.dart';

/// Month abbreviations for `StatsStrings.sessionDate` (no `intl` in this
/// project; the Japanese side just uses numerals).
const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Strings of the Stats screen (the archipelago and the Runs list).
extension StatsStrings on S {
  String get islandsTab => t('Islands', '諸島');
  String get runsTab => t('Runs', '記録');

  String get summaryLine => t('{0} cards · median {1} s · {2} due today', '{0}枚 · 中央値 {1} 秒 · 本日の復習 {2}枚');

  String get legendHeading => t('DOT = CARD · MEDIAN OF LAST 10', 'ドット = 札 · 直近10回の中央値');
  String legendUnder(String upperS) => ja ? '$upperS秒未満' : '<$upperS s';
  String legendRange(String lowerS, String upperS) => '$lowerS–$upperS';
  String legendOver(String lowerS) => ja ? '$lowerS秒超' : '>$lowerS';
  String legendFewTries(int n) => ja ? '$n回未満' : '<$n tries';

  String get slowestIslandTag => t('SLOWEST ISLAND · 次の修行', 'もっとも遅い島 · 次の修行');
  String get islandLineTemplate => t('{0} cards · {1} due today', '{0}枚 · 本日{1}件');
  String get tapAnIsland => t('Tap an\nisland!', '島を\nタップ！');
  String get playThisIsland => t('Play this island ›', 'この島で修行 ›');
  String get noIslandToPractise =>
      t('Play a few rounds to find your slowest island.', 'まずは何回か遊ぼう。もっとも遅い島がここに出ます。');

  String get noRunsYet =>
      t('No runs yet — play a round to see it here.', 'まだ記録がありません。プレイすると記録がここに出ます。');
  String get runEndedEarly => t('Ended early', '途中終了');

  /// A short "Mon D, HH:MM" (EN) / "M月D日 HH:MM" (JA) timestamp.
  String sessionDate(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return ja ? '${local.month}月${local.day}日 $hh:$mm' : '${_monthAbbr[local.month - 1]} ${local.day}, $hh:$mm';
  }
}
