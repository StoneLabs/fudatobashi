import 'strings.dart';

/// Strings of the Home screens.
extension HomeStrings on S {
  String get brandSub => 'FUDATOBASHI';
  String get journeyBanner => t('JOURNEY 旅', '旅 JOURNEY');
  String get trainingBanner => t('TRAINING', 'TRAINING');
  String get shoutStart => t('START TRAINING', '修行スタート');
  String get islandOf => t('Island {0}/{1}', '島 {0}/{1}');
  String get cardsOf => t('{0}/{1} cards', '{0}/{1}枚');
  String islandsAhead(int n) => ja ? 'あと$n島' : (n == 1 ? '1 island ahead' : '$n islands ahead');
  String get allIslandsReached => t('Every island reached', '全島到達');
  String get now => t('NOW', 'いま');
  String get nextChip => t('NEXT', '次');
  String get learnedOf => t('{0} / {1} learned', '{0} / {1} 習得');
  String get reviewsAndNew => t('{0} reviews · {1} new cards', '復習 {0}枚 · 新しい札 {1}枚');
  String get reviewsDue => t('{0} reviews due', '復習 {0}枚');
  String get slowToBeat => t('{0} slow cards to beat', '遅い札 {0}枚');
  String get caughtUp => t('All caught up, keep swiping to get faster', '復習クリア！スワイプでもっと速く');
  String finishIsland(String island) => ja ? '$islandを\nクリア!' : 'Finish\n$island!';
  String get letsGo => t("Let's go!", 'いくぞ！');
  String get keepGoing => t('Faster\nand faster!', 'もっと\n速く!');
  String get ratingLabel => t('RATING', 'レーティング');
  String get toNextBand => t('{0} to {band} ({1})', '{band}まであと{0}（{1}）');
  String get topBand => t('Top class!', '最高位！');
  String get knownSpeedLabel => t('{0}s known speed', '既知の速さ {0}秒');
  String get newCardsTodayLabel => t('New cards today {0}/{1}', '今日の新しい札 {0}/{1}');
  String get reviewsTodayLabel => t("Today's reviews: {0} cards", '今日の復習 {0}枚');
  String get streakDays => t('{0}-day streak', '{0}日連続');
  String get freePlaySub => t('Free play', 'フリー');
  String get freePlayNote => t('Pick any card set', '好きな札で');
  String get nigateSub => t('Weak cards', '苦手な札');
  String get nigateNote => t('Slow or missed', '遅い・間違えた札');
  String get nigateEmpty => t('Play a few runs first: your weak cards will show up here.',
      'まずは何回か遊ぼう。苦手な札がここに集まります。');
  String get guestTitle => t('Guest', 'ゲスト');
  String get guestMode => t('Guest mode', 'ゲストモード');
  String get untrackedTag => t('UNTRACKED', '記録なし');
  String get guestShort => t("For a friend's turn", '友だちの番に');
  String get guestConfirmTitle => t('Hand the phone over?', '端末を貸す？');
  String get guestConfirm => t('START GUEST RUN', 'ゲストで始める');
  String get settingsLabel => t('Settings', '設定');

  String get learnAhead => t('Learn ahead', '先取りで覚える');
  String get learnAheadLocked => t('Learn ahead (locked)', '先取りで覚える(ロック中)');
  String learnAheadShaky(int n) => ja
      ? 'まだ$n枚あやふや。\n先にしっかり覚えよう！'
      : '$n card${n == 1 ? ' is' : 's are'} still shaky. Get them solid first!';
  String get learnAheadPending => t("Today's new cards come first. Off to Training!", '今日の新しい札が先。\n修行へGO!');
}
