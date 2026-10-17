import 'strings.dart';

/// Strings of the full karuta rules page in Help. The rules themselves
/// come from `assets/l10n/` (see `KarutaRules`).
extension RulesStrings on S {
  String get rulesTitle => t('rulesTitle');
  String get rulesRowNote => t('rulesRowNote');
  String get rulesSource => t('rulesSource');
  String get rulesOpenPdf => t('rulesOpenPdf');
  String get rulesDisclaimer => t('rulesDisclaimer');
  String get rulesDisclaimerShort => t('rulesDisclaimerShort');
  String get rulesShowOriginal => t('rulesShowOriginal');
  String get rulesShowOriginalNote => t('rulesShowOriginalNote');
  String get rulesContents => t('rulesContents');
  String get rulesContentsShow => t('rulesContentsShow');
  String get rulesContentsHide => t('rulesContentsHide');
}
