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

  group('AppSettings sound switches (music, card swipe, other effects)', () {
    test('an old single Sounds switch that was off turns all three off', () {
      final s = AppSettings.fromJson({'language': 'en', 'sounds': false});
      expect([s.music, s.swipeSound, s.effectSounds], [false, false, false]);
    });

    test('an old Sounds switch that was on, or none at all, leaves all three on', () {
      for (final j in [
        {'sounds': true},
        <String, dynamic>{},
      ]) {
        final s = AppSettings.fromJson(j);
        expect([s.music, s.swipeSound, s.effectSounds], [true, true, true]);
      }
    });

    test('the new switches win over the old one, and it is no longer written', () {
      final s = AppSettings.fromJson({'sounds': false, 'swipeSound': true});
      expect([s.music, s.swipeSound, s.effectSounds], [false, true, false]);
      expect(s.toJson().containsKey('sounds'), isFalse);
    });

    test('each round-trips through toJson on its own', () {
      final s = AppSettings.fromJson(const AppSettings(music: false, effectSounds: false).toJson());
      expect([s.music, s.swipeSound, s.effectSounds], [false, true, false]);
    });

    test('plays routes each category to its own switch', () {
      const s = AppSettings(music: false, swipeSound: true, effectSounds: false);
      expect(s.plays(SoundCategory.music), isFalse);
      expect(s.plays(SoundCategory.swipe), isTrue);
      expect(s.plays(SoundCategory.effects), isFalse);
    });
  });

  group('AppSettings.musicVolume', () {
    test('defaults when nothing is saved yet', () {
      expect(AppSettings.fromJson({}).musicVolume, DefaultSettings.musicVolume);
    });

    test('round-trips through toJson', () {
      final s = AppSettings.fromJson(const AppSettings(musicVolume: 0.2).toJson());
      expect(s.musicVolume, 0.2);
    });

    test('copyWith changes only the volume', () {
      const s = AppSettings(music: true);
      final louder = s.copyWith(musicVolume: 0.9);
      expect(louder.musicVolume, 0.9);
      expect(louder.music, isTrue);
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
