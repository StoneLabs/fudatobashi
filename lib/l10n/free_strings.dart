import 'strings.dart';

/// Strings of free practice (始める): its lock, setup sheet and pickers. The
/// sheet's notes mark Japanese phrase ends with `\u200B` (see `Phrases`).
extension FreeStrings on S {
  String get freeSheetTag => t('FREE PLAY', 'フリー');
  String get freeStart => t('START', 'スタート');
  String get deckCount => t('{0} cards', '{0}枚');
  String get freeLocked => t('Free play (locked)', 'フリー（ロック中）');
  String freeLockedSub(int n) => ja ? 'あと$n枚' : '$n more to go';
  String freeLockedWhy(int n) => ja
      ? 'あと$n枚しっかり覚えたら\n好きな札で遊べるよ！'
      : 'Remember $n more card${n == 1 ? '' : 's'} well to unlock free play!';

  /// Whether the run counts: the tag, and a line on what that means.
  String get countsTag => t('COUNTS', 'カウント');
  String get countsNote => t('Reviews and rating update, like 修行', '修行と同じく\u200B復習・レーティングに反映');
  String get customTag => t('CUSTOM · NOT COUNTED', 'カスタム · 記録のみ');
  String get customNote => t('History only: reviews and rating stay put', '履歴だけに記録。\u200B復習・レーティングは\u200B変わらない');
  String get resetToDefault => t('Reset', '戻す');
  String get resetToDefaultLabel => t('Reset to every known card, no 隠し字', '覚えた札ぜんぶ・隠し字なしに戻す');

  /// Home's free-play panel: what the next run is.
  String get homeFreeCounts => t('All you know · counts', '覚えた札ぜんぶ · カウント');
  String get homeFreeCustom => t('Custom · not counted', 'カスタム · 記録のみ');

  String get islandsRow => t('Islands', '島');
  String get cardsRow => t('Cards', '札');
  String get lookAlikesRow => t('Look-alikes', '友札');
  String get allKnownIslands => t('All known islands', '覚えた島すべて');
  /// [n] of [of] islands wholly in the deck, and [partly] more in part.
  String islandsOf(int n, int of, {int partly = 0}) => ja
      ? '$of島中$n島${partly > 0 ? '・一部$partly島' : ''}'
      : '$n of $of islands${partly > 0 ? ', $partly partly' : ''}';
  String cardsOf(int n, int of) => ja ? '$of枚中$n枚' : '$n of $of cards';
  String setsOf(int n, int of) => ja ? '$of組中$n組' : '$n of $of sets';
  String get noSetsYet => t('None known yet', 'まだなし');

  String get maskRow => t('隠し字 hidden kana', '隠し字');
  String get maskOff => t('Off', 'なし');
  String maskLevel(int level) => switch (level) {
        1 => t('Hides the first kana', '最初の1字を隠す'),
        2 => t('Hides the first two kana', '最初の2字を隠す'),
        3 => t('Hides the first three kana', '最初の3字を隠す'),
        4 => t('Hides the whole first column', '1列目をまるごと隠す'),
        5 => t('First column + 1 random kana', '1列目＋ランダムに1字'),
        6 => t('First column + 3 random kana', '1列目＋ランダムに3字'),
        7 => t('Half the kana, anywhere', '半分の字をどこでも'),
        _ => t('Every kana shows', '全部の字を見せる'),
      };

  // Pickers
  String get pickIslands => t('Islands', '島をえらぶ');
  String get pickCards => t('Cards', '札をえらぶ');
  String get pickLookAlikes => t('Look-alikes', '友札をえらぶ');
  String get pickIslandsHint => t('Tap an island to add or drop all its cards.', '島をタップで、その札をまとめて追加・解除。');
  String get pickCardsHint => t('Tap a card to add or drop it. Grey ones are not learned yet.',
      '札をタップで追加・解除。灰色はまだ覚えていない札。');
  String get pickLookAlikesHint =>
      t('Sets of cards that start alike. Tap a set to add or drop it.', '出だしが似ている札の組。タップで組ごと追加・解除。');
  String get noLookAlikes =>
      t('No look-alike set has two cards you know yet.', '覚えた札が2枚以上ある友札の組はまだありません。');
  String get selectAll => t('All', '全部');
  String get selectNone => t('None', 'なし');
  String get legendInDeck => t('In the deck', '選択中');
  String get legendOut => t('Left out', '選択外');
  String get legendUnknown => t('Not learned yet', 'まだ');

  /// History and Results: which deck a free-play run used.
  String get deckAllKnown => t('All known', '全部');
  String get deckCustom => t('Custom', 'カスタム');
  String get customRunNote => t('Custom deck: kept in History only. Reviews and rating are unchanged.',
      'カスタムの札：履歴だけに記録。復習とレーティングは変わりません。');
}
