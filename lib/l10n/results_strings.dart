import 'strings.dart';

/// Strings of the results screen and its celebration overlays.
extension ResultsStrings on S {
  String get keepGoing => t('Keep going', '続ける');
  String get keepGoingSub => 'NEXT';
  String get homeSub => 'HOME';
  String get endedEarly => t('Ended early', '途中終了');
  String get firstRecordedRun => t('First recorded run!', '初回記録!');
  String get guestNotRecorded => t('Guest run — not recorded', 'ゲストプレイ・記録なし');

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

  String get goalUpBand => 'NEW SPEED GOAL';
  String goalUpNote(int ms) => ja ? '1枚あたり${ms}ms以下が目標に' : 'Under ${ms}ms per card now';
  String get nicePace => t('NICE PACE!', 'いいペース!');
}
