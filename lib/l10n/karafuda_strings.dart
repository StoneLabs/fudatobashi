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
}
