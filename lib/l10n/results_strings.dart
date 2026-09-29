import '../domain/xp.dart';
import 'strings.dart';

/// Strings of the results screen and its celebration overlays.
extension ResultsStrings on S {
  String get keepGoing => t('Keep going', '続ける');
  String get keepGoingSub => 'NEXT';
  String get homeSub => 'HOME';
  String get endedEarly => t('Ended early', '途中終了');
  String timeSaved(String seconds) => t('−$seconds s', '−$seconds秒');
  String get firstRecordedRun => t('First recorded run!', '初回記録!');
  String get guestNotRecorded => t('Guest run — not recorded', 'ゲストプレイ・記録なし');

  String get newCardsHeading => '新顔';
  String get newCardsLabel => t('New cards', '新しい札');
  String get newCardsNote => t('Met for the first time this round', '今回はじめて出会った札');

  String get toughestHeading => '強敵';
  String get toughestNote => t('Your slowest cards this run', '今回、遅かった札');

  String get avgPerCardLabel => t('AVG / CARD', '1枚あたり平均');
  String knownOf(int known, int total) => ja ? '$total枚中$known枚正解' : '$known / $total known';
  String get knownSpeedNote => t('{0}s known speed', '既知の速さ {0}秒');

  String get newCardShout => t('A new card appears!', '新しい札、登場!!');
  String get kimarijiLabel => 'KIMARIJI\n決まり字';
  String get newCardBand => 'A NEW CARD APPEARS';

  /// Where a card is decided; `{0}` marks where the deciding kana goes.
  String deciderTip(int position, String? twin) {
    final nth = ja ? '$position音目' : '${_ordinal(position)} sound';
    if (twin == null) return t('Decided on the $nth: {0}', '$nthの{0}で決まり');
    return t('Twin of $twin: wait for the $nth, {0}', '友札「$twin」: $nthの{0}で決まり');
  }

  static String _ordinal(int n) => switch (n % 100) {
        11 || 12 || 13 => '${n}th',
        _ => switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' },
      };

  String get learnAboutCard => t('Learn about this card', 'この札について');
  String get bringItOn => t('BRING IT ON!', '受けて立つ');

  String get lookAlikeBand => 'LOOK-ALIKE';
  String get mixUpWarning => t('Watch out not to mix them up!', '取り間違えに注意!');
  String get gotIt => t('GOT IT!', '気をつける');

  String get islandCompleteBand => 'ISLAND COMPLETE';
  String get cardsLearnedOf => t('{0} / {1} cards learned', '{0} / {1}枚 習得');
  String get nextIslandBand => 'NEXT ISLAND · 次の島';
  String nextIslandNote(int cards, String first, String second) =>
      ja ? '$cards枚 · 最初は$first、$second' : '$cards cards · first up $first, $second';
  String get islandProgress => t('Island {0} of {1} done · {2} / {3} cards', '島 {0}/{1} クリア · {2}/{3}枚');
  String get allIslandsDone => t('Every island sailed!', '全島制覇!');
  String get setSail => t('SET SAIL!', '出航');

  String get rankUpBand => 'RANK UP';
  String get beforeBandLabel => 'BEFORE';
  String get nowBandLabel => 'NOW';
  String get newBadge => 'NEW';
  String get onward => t('ONWARD!', '次へ');
  String get nextClassBand => 'NEXT CLASS · 次の級';
  String get nextClassTarget => t('100 cards in {0} s', '100枚 {0}秒以内');
  String get nextClassPace => t('Your pace {0} s · {1} pts to go', 'いまのペース {0}秒 · あと{1}pt');
  String get topClassReached => t('Top of the ladder!', '頂点に到達!');
  String get topClassChase => t('From here on, race your own best', 'ここからは自分との勝負');

  String get xpBand => 'EXP GET!';
  String get xpUnit => 'XP';
  String levelShort(int level) => 'LV $level';
  String xpToNext(int xp, int level) => ja ? 'LV $levelまで あと $xp XP' : '$xp XP to LV $level';
  String get levelUpFlash => 'LEVEL UP!';
  String get xpCta => t('SWEET!', 'やったね!');

  String xpSource(XpSource source) => switch (source) {
        XpSource.correct => t('Correct', '正解'),
        XpSource.missed => t('Tried', '挑戦'),
        XpSource.speed => t('Speed', 'スピード'),
        XpSource.reviews => t('Reviews', '復習'),
        XpSource.newCards => t('New cards', '新しい札'),
        XpSource.clear => t('Run clear', '完走'),
        XpSource.daily => t('Daily', 'デイリー'),
        XpSource.best => t('Personal best', '自己ベスト'),
        XpSource.island => t('Island complete', '島制覇'),
        XpSource.graduation => t('All 100 learned', '100首習得'),
      };

  /// The count beside an XP line, or null where it says nothing.
  String? xpCount(XpPart part) => switch (part.source) {
        XpSource.clear || XpSource.best || XpSource.graduation => null,
        XpSource.daily => part.count > 1 ? dayStreak(part.count) : null,
        _ => '×${part.count}',
      };

  String get levelUpBand => 'レベルアップ';
  String levelsGained(int n) => ja ? '$nレベルアップ!' : '+$n LEVELS';
  String get nextLevelBand => 'NEXT LEVEL · 次のレベル';

  String get graduationBand => 'ALL 100 CARDS LEARNED';
  String get graduationKai => t('Join a real karuta kai!', '本物のかるた会へ行こう!');
  String get graduationKaiNote =>
      t('You know every card. Real matches at a かるた会 await.', '100首ぜんぶ覚えた。次はかるた会で実戦だ!');
  String get graduationSwitch =>
      t('From now on: All 100 known mode', 'これからは「100首ぜんぶ」モード');
  String get graduationCta => t("LET'S GO!", 'いざ!');

  String get goalUpBand => 'NEW SPEED GOAL';
  String goalUpNote(int ms) => ja ? '1枚あたり${ms}ms以下が目標に' : 'Under ${ms}ms per card now';
  String get nicePace => t('NICE PACE!', 'いいペース!');
}
