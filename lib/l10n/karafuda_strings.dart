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

  /// How many a game called, in a game page's header.
  String karafudaCount(int n) => f('karafudaCount', [n]);

  /// How a game's からふだ went: right first out of those called.
  String karafudaRightOf(int right, int called) => f('karafudaRightOf', [right, called]);

  /// A score bar's からふだ part, in points, and the same in a note.
  String karafudaPoints(String points) => f('karafudaPoints', [points]);
  String karafudaPointsNote(String points) => f('karafudaPointsNote', [points]);

  /// History's からふだ panel: how many were called, its rows and caption.
  String karafudaCalled(int n) => f('karafudaCalled', [n]);
  String get karafudaRowRightFirst => t('karafudaRowRightFirst');
  String get karafudaRowLate => t('karafudaRowLate');
  String get karafudaRowMissed => t('karafudaRowMissed');
  String get karafudaRowTouched => t('karafudaRowTouched');
  String get karafudaRowPressedOnCards => t('karafudaRowPressedOnCards');
  String get karafudaRowMedian => t('karafudaRowMedian');

  /// The same-setup table's row of the からふだ answered first.
  String get karafudaRowFirstTap => t('karafudaRowFirstTap');
  String get karafudaCaption => t('karafudaCaption');

  /// The Field's review, stepping through a game with からふだ call by
  /// call: the call's count, how a からふだ went (pressed on tap [tap]),
  /// where it lay, and a card tapped on it.
  String karafudaStepCall(int step, int of) => f('karafudaStepCall', [step, of]);
  String karafudaBoxPressedOn(int tap) => f('karafudaBoxPressedOn', [tap]);
  String karafudaBoxShownPressed(int tap) => f('karafudaBoxShownPressed', [tap]);
  String get karafudaNotPressed => t('karafudaNotPressed');
  String get karafudaOffField => t('karafudaOffField');
  String get karafudaBoxCard => t('karafudaBoxCard');

  /// Where a tap landed: the からふだ button, or a card on a からふだ call.
  String get karafudaChip => t('karafudaChip');
  String get karafudaChipCard => t('karafudaChipCard');

  /// The Taps table's note for a game with からふだ, and the Score's part.
  String karafudaTapsNote(int calls, int karafuda) => f('karafudaTapsNote', [calls, karafuda]);
  String get karafudaPart => t('karafudaPart');

  /// 定位置's wrong taps on [cards] field cards' calls and [karafuda] からふだ
  /// calls.
  String teiichiWrongOnKarafuda(int cards, int karafuda) =>
      f(countKey('teiichiWrongOnKarafuda', cards), [cards, karafuda]);
}
