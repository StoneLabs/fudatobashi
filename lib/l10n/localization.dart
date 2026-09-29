import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One available UI language: its own code and its native display name (its
/// file's own `languageName` entry), for a language picker to list.
class LanguageOption {
  const LanguageOption(this.code, this.name);

  final String code;
  final String name;
}

/// The `assets/l10n/*.json` strings, loaded once at startup (see [load]) and
/// read synchronously afterwards through `S`.
class Localization {
  Localization._();

  static Map<String, Map<String, String>> _byLanguage = const {};

  /// Every language a file exists for, in `languages.json` order.
  static List<LanguageOption> languages = const [];

  static Future<void> load() async {
    final index = jsonDecode(await rootBundle.loadString('assets/l10n/languages.json'));
    final byLanguage = <String, Map<String, String>>{};
    for (final code in (index as List).cast<String>()) {
      byLanguage[code] = _parse(await rootBundle.loadString('assets/l10n/$code.json'));
    }
    _install(byLanguage);
  }

  /// Test-only equivalent of [load] that takes already-read JSON text, the
  /// way `Poems.fromJsonString` lets tests skip `rootBundle`.
  static void loadFromSource({required String indexJson, required Map<String, String> jsonByCode}) {
    final index = (jsonDecode(indexJson) as List).cast<String>();
    _install({for (final code in index) code: _parse(jsonByCode[code]!)});
  }

  static Map<String, String> _parse(String source) =>
      (jsonDecode(source) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));

  static void _install(Map<String, Map<String, String>> byLanguage) {
    _byLanguage = byLanguage;
    languages = [for (final e in byLanguage.entries) LanguageOption(e.key, e.value['languageName'] ?? e.key)];
  }

  /// Resolves a stored language setting — a language code, or `'system'` —
  /// to the code to actually use: the device's language if a file exists for
  /// it, else English.
  static String resolve(String setting, String systemLanguageCode) {
    final code = setting == 'system' ? systemLanguageCode : setting;
    return _byLanguage.containsKey(code) ? code : 'en';
  }

  /// The string at [key] for [code], falling back to English if [code]'s
  /// file doesn't have it.
  static String lookup(String code, String key) => _byLanguage[code]?[key] ?? _byLanguage['en']?[key] ?? key;
}
