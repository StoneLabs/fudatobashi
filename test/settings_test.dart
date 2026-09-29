import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/state/settings.dart';

void main() {
  group('AppSettings.language migration (old AppLanguage enum -> language code)', () {
    test('old "en" and "ja" map straight across', () {
      expect(AppSettings.fromJson({'language': 'en'}).language, 'en');
      expect(AppSettings.fromJson({'language': 'ja'}).language, 'ja');
    });

    test('old "system" still means system default', () {
      expect(AppSettings.fromJson({'language': 'system'}).language, 'system');
    });

    test('a missing language defaults to system', () {
      expect(AppSettings.fromJson({}).language, DefaultSettings.language);
      expect(DefaultSettings.language, 'system');
    });

    test('round-trips through toJson', () {
      expect(AppSettings.fromJson(const AppSettings(language: 'ja').toJson()).language, 'ja');
    });

    test('a language code a stored file didn\'t know about (e.g. a future one) still loads as-is', () {
      expect(AppSettings.fromJson({'language': 'fr'}).language, 'fr');
    });
  });

  group('AppSettings.languagePicked (first-open language picker)', () {
    test('a truly fresh install (nothing saved yet) has not picked one', () {
      expect(AppSettings.fromJson({}).languagePicked, isFalse);
    });

    test('any settings saved before this field existed count as already picked', () {
      expect(AppSettings.fromJson({'language': 'en'}).languagePicked, isTrue);
    });

    test('round-trips through toJson', () {
      expect(AppSettings.fromJson(const AppSettings(languagePicked: true).toJson()).languagePicked, isTrue);
      expect(AppSettings.fromJson(const AppSettings().toJson()).languagePicked, isFalse);
    });
  });
}
