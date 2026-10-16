import '../state/stats_history.dart';
import 'strings.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Strings of the SRS page, the practice calendar and the rank page.
extension SrsStrings on S {
  String get srsTitle => t('srsTitle');
  String get srsDetailsButton => t('srsDetailsButton');
  String get srsDetailsTitle => t('srsDetailsTitle');
  String get srsNoData => t('srsNoData');

  String get srsKnown => t('srsKnown');
  String get srsStreak => t('srsStreak');
  String get srsRemembered => t('srsRemembered');
  String srsDaysUnit(int days) => t(countKey('srsDaysUnit', days));
  String srsPaceDay(int day, int of) => f('srsPaceDay', [day, of]);
  String srsKnownCount(int n) => f('srsKnownCount', [n]);
  String srsUnlockedCount(int n) => f('srsUnlockedCount', [n]);
  String srsPaceToday(int n) => f('srsPaceToday', [n]);

  String get srsKnownTitle => t('srsKnownTitle');
  String srsGainIn(int n, int days) => f(countKey('srsGainIn', days), [n, days]);
  String get srsLegendKnown => t('srsLegendKnown');
  String get srsLegendUnlocked => t('srsLegendUnlocked');
  String get srsLegendPace => t('srsLegendPace');
  String get srsLegendTrend => t('srsLegendTrend');
  String get srsAllKnownBy => t('srsAllKnownBy');
  String get srsToday => t('srsToday');

  String get srsWallTitle => t('srsWallTitle');
  String get srsWallNote => t('srsWallNote');
  String get srsUpright => t('srsUpright');
  String get srsUpsideDown => t('srsUpsideDown');

  String stageName(MemoryStage stage) => t('stage${_stageKey(stage)}');
  String stageText(MemoryStage stage, int n) => f('stage${_stageKey(stage)}Text', [n]);
  static String _stageKey(MemoryStage stage) => switch (stage) {
        MemoryStage.notStarted => 'NotStarted',
        MemoryStage.fresh => 'New',
        MemoryStage.learning => 'Learning',
        MemoryStage.gettingThere => 'GettingThere',
        MemoryStage.solid => 'Solid',
        MemoryStage.mastered => 'Mastered',
      };

  String get srsStrengthTitle => t('srsStrengthTitle');
  String get srsStage => t('srsStage');
  String get srsUp => t('srsUp');
  String get srsDown => t('srsDown');

  String get srsTimeTitle => t('srsTimeTitle');
  String srsTotal(String time) => f('srsTotal', [time]);
  String srsWeekOf(String date) => f('srsWeekOf', [date]);
  String get srsThisWeek => t('srsThisWeek');

  /// [d] as hours and minutes, or minutes alone under an hour.
  String srsDuration(Duration d) =>
      d.inHours > 0 ? f('srsHoursMinutes', [d.inHours, d.inMinutes % 60]) : f('srsMinutes', [d.inMinutes]);
  String srsMinuteAxis(int n) => f('srsMinuteAxis', [n]);

  String get srsSpeedTitle => t('srsSpeedTitle');
  String get srsLowerFaster => t('srsLowerFaster');
  String get srsAllSwipes => t('srsAllSwipes');
  String get srsCardsYouKnow => t('srsCardsYouKnow');
  String srsSecondsAxis(String n) => f('srsSecondsAxis', [n]);

  String get srsSidesTitle => t('srsSidesTitle');
  String get srsRowKnown => t('srsRowKnown');
  String get srsRowSwipes => t('srsRowSwipes');
  String get srsRowMissed => t('srsRowMissed');
  String get srsRowTime => t('srsRowTime');

  String get srsTableTitle => t('srsTableTitle');
  String get srsTableSort => t('srsTableSort');
  String get srsColCard => t('srsColCard');
  String get srsColStab => t('srsColStab');
  String get srsColDiff => t('srsColDiff');
  String get srsColRecall => t('srsColRecall');
  String get srsColNext => t('srsColNext');
  String get srsColLapses => t('srsColLapses');
  String get srsColTime => t('srsColTime');
  String srsTableKey(int n) => f('srsTableKey', [n]);
  String get srsInvertedTag => t('srsInvertedTag');
  String srsStabilityDays(String n) => f('srsStabilityDays', [n]);

  String get calendarTitle => t('calendarTitle');
  String get calStreak => t('calStreak');
  String get calBest => t('calBest');
  String get calDays => t('calDays');
  String get calSets => t('calSets');
  String get calLittle => t('calLittle');
  String get calUsual => t('calUsual');
  String get calLot => t('calLot');
  String get calSetDone => t('calSetDone');
  String calDaySwipes(int n) => f(countKey('calDaySwipes', n), [n]);

  /// A practice [day] (a UTC midnight) as "Oct 14" / "10月14日".
  String dayDate(DateTime day) => ja ? '${day.month}月${day.day}日' : '${_months[day.month - 1].substring(0, 3)} ${day.day}';

  /// "October 2026" / "2026年10月".
  String monthTitle(DateTime month) => ja ? '${month.year}年${month.month}月' : '${_months[month.month - 1]} ${month.year}';

  String get rankRatingTitle => t('rankRatingTitle');
  String get rankClassesTitle => t('rankClassesTitle');
}
