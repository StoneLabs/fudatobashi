import 'strings.dart';

/// Strings of からふだ (空札), in 暗記練 and 定位置: the button, the setup
/// sheets' stepper, and how results and History show them. からふだ in
/// Japanese, Karafuda in English.
extension KarafudaStrings on S {
  /// The からふだ button.
  String get karafuda => t('karafuda');

  /// The rules: from level [level] on in 暗記練, every game in 定位置, and
  /// how 暗記練's ranked scores them.
  String karafudaRule(int level) => f('karafudaRule', [level]);
  String get karafudaRuleTeiichi => t('karafudaRuleTeiichi');
  String get karafudaScore => t('karafudaScore');

  /// The setup sheets' stepper, and its value at 0.
  String get karafudaStepper => t('karafudaStepper');
  String get karafudaOff => t('karafudaOff');

  /// How many a game called, in a summary's header.
  String karafudaCount(int n) => f('karafudaCount', [n]);

  /// How a game's からふだ went: right first out of those called, the cards
  /// tapped on them, and the presses of the button on the cards' calls.
  String karafudaRightOf(int right, int called) => f('karafudaRightOf', [right, called]);
  String karafudaTouched(int n) => f(countKey('karafudaTouched', n), [n]);
  String karafudaPressedOnCards(int n) => f(countKey('karafudaPressedOnCards', n), [n]);

  /// A score bar's からふだ part, in points, and the same in a note.
  String karafudaPoints(String points) => f('karafudaPoints', [points]);
  String karafudaPointsNote(String points) => f('karafudaPointsNote', [points]);

  /// 定位置's wrong taps on [cards] field cards' calls and [karafuda] からふだ
  /// calls.
  String teiichiWrongOnKarafuda(int cards, int karafuda) =>
      f(countKey('teiichiWrongOnKarafuda', cards), [cards, karafuda]);
}
