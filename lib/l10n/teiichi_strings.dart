import '../domain/ankiren_field.dart';
import 'strings.dart';

/// Strings of 定位置: its entry on the hub, its page, the custom game sheet,
/// the placing screen, results, and its rules and guide.
extension TeiichiStrings on S {
  /// The hub's entry: its burst, its screen-reader line, and the best and
  /// last games (the last one's facts a template: first-tap finds of the
  /// cards).
  String get teiichiPageTitle => t('teiichiPageTitle');
  String get teiichiOpenPage => t('teiichiOpenPage');
  String get teiichiBestPlacing => t('teiichiBestPlacing');
  String get teiichiLastGame => t('teiichiLastGame');
  String get teiichiLastFacts => t('teiichiLastFacts');
  String get teiichiNoGames => t('teiichiNoGames');

  /// The page: ranked, still to come; practice with its setup; and the
  /// guide's card.
  String teiichiRankedFacts(int cards) => f('teiichiRankedFacts', [cards]);
  String get teiichiRankedSoon => t('teiichiRankedSoon');
  String get teiichiPractice => t('teiichiPractice');
  String get teiichiRows => t('teiichiRows');
  String teiichiPlay(int cards) => f('teiichiPlay', [cards]);
  String get teiichiAllCards => t('teiichiAllCards');
  String get teiichiLearnTitle => t('teiichiLearnTitle');
  String get teiichiLearnLine => t('teiichiLearnLine');
  String get teiichiLearnButton => t('teiichiLearnButton');
  String get teiichiGuideTitle => t('teiichiGuideTitle');
  String get teiichiGuideSoon => t('teiichiGuideSoon');

  /// The custom game sheet: the card count from the known cards, the rows
  /// (each key's count, how many cards it holds or, shut, how few it
  /// needs), the note when the rows had to go up, and what counts for the
  /// best placing time.
  String get teiichiCustomTitle => t('teiichiCustomTitle');
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
  /// clock counts, where a dragged card would land, and the note once every
  /// card is placed.
  String get teiichiPlaceHint => t('teiichiPlaceHint');
  String teiichiLeft(int n) => f('teiichiLeft', [n]);
  String get teiichiPlacing => t('teiichiPlacing');
  String get teiichiPlaced => t('teiichiPlaced');
  String get teiichiLeaveTitle => t('teiichiLeaveTitle');
  String get teiichiLeaveNote => t('teiichiLeaveNote');
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

  /// The rules: the placing step, then how placing works, a row's width,
  /// the clock, and that a game always goes to the end.
  String get teiichiStepPlace => t('teiichiStepPlace');
  String get teiichiStepPlaceLine => t('teiichiStepPlaceLine');
  String get teiichiRuleTap => t('teiichiRuleTap');
  String teiichiRuleRow(String cards) => f('teiichiRuleRow', [cards]);
  String teiichiRuleClock(int cards) => f('teiichiRuleClock', [cards]);
  String get teiichiRuleToEnd => t('teiichiRuleToEnd');
}
