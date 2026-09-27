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

  String get kimarijiLabel => t('KIMARIJI', '決まり字');
  String get newCardBand => 'A NEW CARD APPEARS';
  String twinOf(String kimariji) => t('Twin of $kimariji: watch for it', '友札: $kimariji に注意');
  String get bringItOn => t('BRING IT ON!', '受けて立つ');

  String get lookAlikeBand => 'LOOK-ALIKE';
  String get mixUpWarning => t('Watch out not to mix them up!', '取り間違えに注意!');
  String get gotIt => t('GOT IT!', '気をつける');

  String get islandCompleteBand => 'ISLAND COMPLETE';
  String nextIslandTag(String name) => ja ? '次の島・$name' : 'NEXT ISLAND · $name';
  String firstUp(String a, String b) => ja ? '最初は$a、$b' : 'first up $a, $b';
  String islandsDoneOf(int done, int total) => ja ? '島$done/$totalクリア' : 'Island $done/$total done';
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
