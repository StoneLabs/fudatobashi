import '../config/config.dart';
import '../domain/ankiren_field.dart';
import 'strings.dart';

/// Strings of 定位置: its entry on the hub, its page, the custom game sheet,
/// the placing screen, results, and its rules and guide.
extension TeiichiStrings on S {
  /// The hub's entry: its burst and its screen-reader line.
  String get teiichiPageTitle => t('teiichiPageTitle');
  String get teiichiOpenPage => t('teiichiOpenPage');

  /// The page's form strip: the average wrong taps and placing time, over
  /// how many games; the count is a template.
  String get teiichiFormWrongTaps => t('teiichiFormWrongTaps');
  String get teiichiFormPlacing => t('teiichiFormPlacing');
  String teiichiFormGames(int games) => t(countKey('teiichiFormGames', games));

  /// The page: the next level to clear or the setup picked instead, with its
  /// time limit; and the guide's card.
  String get teiichiRows => t('teiichiRows');
  String teiichiPlay(int cards) => f('teiichiPlay', [cards]);
  String get teiichiLimitLabel => t('teiichiLimitLabel');
  String get teiichiNoLimit => t('teiichiNoLimit');
  String teiichiToPlace(String limit) => f('teiichiToPlace', [limit]);
  String get teiichiCustomNote => t('teiichiCustomNote');
  String teiichiPreviewLabel(int cards, int rows) => f('teiichiPreviewLabel', [cards, rows]);
  String get teiichiLearnTitle => t('teiichiLearnTitle');
  String get teiichiLearnButton => t('teiichiLearnButton');
  String get teiichiGuideTitle => t('teiichiGuideTitle');

  /// The level sheet: a level key's cards and how levels open; for a custom
  /// game the card count from the known cards, the rows (each key's count,
  /// how many cards it holds or, shut, how few it needs), the note when the
  /// rows had to go up, and what counts for the best placing time.
  String teiichiKeyCards(int cards) => f('teiichiKeyCards', [cards]);
  String teiichiUnlockLine(int strikes) => f('teiichiUnlockLine', [strikes]);
  String get teiichiFromKnown => t('teiichiFromKnown');
  String get teiichiAnyNumber => t('teiichiAnyNumber');
  String teiichiRowsKey(int rows) => f(countKey('teiichiRowsKey', rows), [rows]);
  String teiichiRowsUpTo(int cards) => f('teiichiRowsUpTo', [cards]);
  String teiichiRowsAtMost(int cards) => f('teiichiRowsAtMost', [cards]);
  String teiichiRowsWentUp(int rows) => f('teiichiRowsWentUp', [rows]);
  String teiichiRowsHold(int rows, int cards) => f(rows == 1 ? 'teiichiRowsHoldOne' : 'teiichiRowsHold', [rows, cards]);
  String teiichiBestNote(int cards) => f('teiichiBestNote', [cards]);
  String get teiichiGuestLine => t('teiichiGuestLine');

  /// The placing screen: the hint, the stack's count, what the band's
  /// clock counts, where a dragged card would land, the note once every
  /// card is placed, and what leaving costs.
  String get teiichiPlaceHint => t('teiichiPlaceHint');
  String teiichiLeft(int n) => f('teiichiLeft', [n]);
  String get teiichiPlacing => t('teiichiPlacing');
  String get teiichiTimeLeft => t('teiichiTimeLeft');
  String get teiichiPlaced => t('teiichiPlaced');
  String get teiichiLeaveTitle => t('teiichiLeaveTitle');
  String get teiichiLeaveNote => t('teiichiLeaveNote');
  String get teiichiForfeitTitle => t('teiichiForfeitTitle');
  String get teiichiForfeitNote => t('teiichiForfeitNote');

  /// Turning the screen: the setting, and the tip on a portrait screen.
  String get teiichiAutoTurn => t('teiichiAutoTurn');
  String get teiichiAutoTurnNote => t('teiichiAutoTurnNote');
  String get teiichiTurnTitle => t('teiichiTurnTitle');
  String get teiichiTurnBody => t('teiichiTurnBody');
  String get teiichiTurnNever => t('teiichiTurnNever');
  String teiichiAllPlaced(int cards) => f('teiichiAllPlaced', [cards]);
  String teiichiRowName(FieldRow row) => switch (row) {
        FieldRow.lower => t('teiichiRowLower'),
        FieldRow.middle => t('teiichiRowMiddle'),
        FieldRow.upper => t('teiichiRowUpper'),
      };
  String teiichiSpotName(FieldRow row, RowPart part) => f(
        switch (part) {
          RowPart.left => 'teiichiSpotLeft',
          RowPart.middle => 'teiichiSpotMiddle',
          RowPart.right => 'teiichiSpotRight',
        },
        [teiichiRowName(row)],
      );
  String get teiichiStack => t('teiichiStack');
  String get teiichiOpenMiddle => t('teiichiOpenMiddle');

  /// Too few known cards for the game asked for.
  String teiichiNeedCards(int n) => f('teiichiNeedCards', [n]);

  /// Results: the hero's first-tap finds of the cards, the placing time
  /// against the best, the wrong taps on how many cards, the average find
  /// time, the cards slowest to place, and Play again.
  String get teiichiRight => t('teiichiRight');
  String teiichiOfCards(int cards) => f('teiichiOfCards', [cards]);
  String teiichiFirstTapBar(int n) => f('teiichiFirstTapBar', [n]);
  String get teiichiNiceLayout => t('teiichiNiceLayout');
  String get teiichiPlacingLabel => t('teiichiPlacingLabel');
  String teiichiYourBest(String time) => f('teiichiYourBest', [time]);
  String get teiichiNewBest => t('teiichiNewBest');
  String get teiichiNoBest => t('teiichiNoBest');
  String get teiichiWrongTaps => t('teiichiWrongTaps');
  String teiichiWrongOn(int cards) => f(countKey('teiichiWrongOn', cards), [cards]);
  String get teiichiAvgFind => t('teiichiAvgFind');
  String get teiichiSlowestPlace => t('teiichiSlowestPlace');
  String get teiichiSlowestPlaceNote => t('teiichiSlowestPlaceNote');
  String get teiichiPlayAgain => t('teiichiPlayAgain');
  String get teiichiGuestNote => t('teiichiGuestNote');

  /// A ranked game's results: the placing time where 暗記練 says the top
  /// score, what it paid on the tile and the bar, what a forfeit counts as,
  /// and how the score works; and what ranked needs next, and the cards
  /// never placed, as a level game's results say them.
  String teiichiPlacedIn(String time) => f('teiichiPlacedIn', [time]);
  String teiichiBonusNote(int percent) => f('teiichiBonusNote', [percent]);
  String teiichiBonusBar(String points) => f('teiichiBonusBar', [points]);
  String get teiichiCountsAsZero => t('teiichiCountsAsZero');
  String get teiichiScoreNote => f('teiichiScoreNote', [
        (TeiichiTuning.bonusPerHalving * 100).round(),
        TeiichiTuning.halvingClock.inMinutes,
      ]);
  String teiichiRankedNext(int level) => f('teiichiRankedNext', [level]);
  String get teiichiUnplacedTag => t('teiichiUnplacedTag');
  String teiichiUnplacedNote(int cards) => f(cards == 1 ? 'teiichiUnplacedNoteOne' : 'teiichiUnplacedNote', [cards]);

  /// The rules: the placing step, then how placing works, a row's width,
  /// the clock, its limits, that a game always goes to the end, the
  /// strikes, the custom level, ranked, and leaving it.
  String get teiichiStepPlace => t('teiichiStepPlace');
  String get teiichiStepPlaceLine => t('teiichiStepPlaceLine');
  String get teiichiRuleTap => t('teiichiRuleTap');
  String teiichiRuleRow(String cards) => f('teiichiRuleRow', [cards]);
  String teiichiRuleClock(int cards) => f('teiichiRuleClock', [cards]);
  String get teiichiRuleToEnd => t('teiichiRuleToEnd');
  String get teiichiRuleLimit => t('teiichiRuleLimit');
  String teiichiRuleStrikes(int strikes) => f('teiichiRuleStrikes', [strikes]);
  String teiichiRuleCustom(int clear) => f('teiichiRuleCustom', [clear]);
  String teiichiRuleRanked(int cards, int rows, int karafuda, String limit, int level) =>
      f('teiichiRuleRanked', [cards, rows, karafuda, limit, level]);
  String get teiichiRuleLeave => t('teiichiRuleLeave');

  /// The rules' scoring, after 暗記練's call points: the placing bonus,
  /// its table's heads and a placing time's bonus, and the cards never
  /// placed.
  String get teiichiScorePlacing => f('teiichiScorePlacing', [
        (TeiichiTuning.bonusPerHalving * 100).round(),
        TeiichiTuning.halvingClock.inMinutes,
      ]);
  String get teiichiBonusTime => t('teiichiBonusTime');
  String get teiichiBonusHead => t('teiichiBonusHead');
  String teiichiBonusPercent(int percent) => f('teiichiBonusPercent', [percent]);
  String get teiichiScoreUnplaced => t('teiichiScoreUnplaced');
}
