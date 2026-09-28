import 'strings.dart';

/// Month abbreviations for `StatsStrings.shortDate` (no `intl` in this
/// project; the Japanese side just uses numerals).
const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Strings of the Stats screen (the archipelago and the all-cards list).
extension StatsStrings on S {
  String get islandsTab => t('Islands', '諸島');
  String get allTab => t('All', 'すべて');

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
  String get playThisIslandLocked => t('Play this island (locked)', 'この島で修行（ロック中）');
  String uncoverIslandToPlay(int unlocked, int total) => ja
      ? 'この島の札を全部（$total枚）覚えたら遊べます（いま$unlocked/$total）'
      : 'Uncover all $total cards of this island to play it ($unlocked/$total so far).';
  String get noIslandToPractise =>
      t('Play a few rounds to find your slowest island.', 'まずは何回か遊ぼう。もっとも遅い島がここに出ます。');

  /// A short "Mon D" (EN) / "M月D日" (JA) date, no time (island/card detail's
  /// due dates).
  String shortDate(DateTime at) {
    final local = at.toLocal();
    return ja ? '${local.month}月${local.day}日' : '${_monthAbbr[local.month - 1]} ${local.day}';
  }

  // ---------------------------------------------------------- Island detail

  String islandSubtitle(int number, int cardCount) =>
      ja ? '第$number島 · $cardCount枚' : 'ISLAND $number · $cardCount CARDS';
  String get islandMedianLabel => t('ISLAND MEDIAN', '島の中央値');

  /// "{0} due today", the number set in display type by `NumberedText`.
  String get dueTodayLine => t('{0} due today', '本日の復習 {0}枚');

  String get sortLabel => t('Sort', '並び替え');
  String get sortOrder => t('Learning order', '学習順');
  String get sortSlow => t('Slowest', '遅い順');
  String get sortDue => t('Due', '復習順');

  String get notLearnedYet => t('not learned yet', 'まだ未学習');
  String get neverReviewed => t('never reviewed', 'まだ復習なし');
  String get dueTodayShort => t('due today', '本日復習');
  String dueInDays(int n) => ja ? '$n日後' : 'in ${n}d';

  // ------------------------------------------------------------ Card detail

  String islandCrumb(String islandName) => ja ? '$islandNameの島' : '$islandName island';
  String get kimarijiCaption => t('KIMARIJI · 決まり字', '決まり字');
  String get topSpeedLabel => t('TOP SPEED', '最速');
  String get attemptsLabel => t('ATTEMPTS', '挑戦');
  String get dontKnowLabel => t("DON'T KNOW", 'わからない');

  /// After a count of attempts ("57 回"); English needs none.
  String? get timesSuffix => ja ? '回' : null;
  String get lookAlikesLabel => t('EASILY CONFUSED WITH · 友札', '間違えやすい友札');
  String get topSpeedChartLabel => t('top', '最速');
  String get attemptsAxis => t('attempts', '回数');
  String get noAttemptsYet => t('No attempts yet', 'まだ記録なし');
  String get uprightLabel => t('Upright', '正位置');
  String get invertedLabel => t('Inverted', '逆さま');
  String get allModes => t('All', 'すべて');

  String get memoryTag => t('MEMORY · FSRS 記憶', 'FSRS 記憶');
  String lastReviewedOn(String date) => t('last review $date', '前回 $date');
  String get stabilityLabel => t('STABILITY', '安定度');
  String get difficultyLabel => t('DIFFICULTY', '難易度');
  String get retrievabilityLabel => t('RETRIEVABILITY', '想起確率');
  String get nextDueLabel => t('NEXT DUE', '次回復習');
  String get stabilityUnit => t('days', '日');
  String outOf(int max) => '/ $max';
  String get retrievabilityNow => t('% now', '% 今');
  String get dueTodayValue => t('Today', '今日');
  String get dueTomorrow => t('tomorrow', '明日');
  String dueInDaysSuffix(int n) => ja ? 'あと$n日' : 'in $n d';
  String get notScheduled => t('not scheduled', '未定');
  String seeYouOn(String date) => t('See you $date!', '$dateにまた！');

  // ------------------------------------------------------------ Rank ladder

  String get youTag => t('YOU', '現在');
  String get topClassNote => t('TOP CLASS', '最高位');
  String get clearStamp => t('CLEAR', '済');
  String get toGoTemplate => t('{0} to go!', 'あと{0}！');
  String get previewRankUp => t('Preview', 'プレビュー');
}
