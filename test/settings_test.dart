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
}
