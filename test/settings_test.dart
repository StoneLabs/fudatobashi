import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
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

  group('AppSettings.kimarijiScript', () {
    test('defaults to auto', () {
      expect(const AppSettings().kimarijiScript, KimarijiScript.auto);
      expect(DefaultSettings.kimarijiScript, KimarijiScript.auto);
    });

    test('auto resolves to hiragana or romaji per UI language', () {
      expect(KimarijiScript.auto.resolve(uiJapanese: true), KimarijiScript.hiragana);
      expect(KimarijiScript.auto.resolve(uiJapanese: false), KimarijiScript.romaji);
    });

    test('an explicit choice overrides auto in either UI language', () {
      expect(KimarijiScript.hiragana.resolve(uiJapanese: false), KimarijiScript.hiragana);
      expect(KimarijiScript.romaji.resolve(uiJapanese: true), KimarijiScript.romaji);
    });

    test('a missing value defaults to auto', () {
      expect(AppSettings.fromJson({}).kimarijiScript, KimarijiScript.auto);
    });

    test('round-trips through toJson', () {
      final s = AppSettings.fromJson(const AppSettings(kimarijiScript: KimarijiScript.romaji).toJson());
      expect(s.kimarijiScript, KimarijiScript.romaji);
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

  group('AppSettings: the About page\'s card swipe and sound ladder', () {
    test('not swiped yet and the sounds ladder by default', () {
      expect((AppSettings.fromJson({}).cardPanelSwiped, AppSettings.fromJson({}).soundLadder),
          (false, SoundLadderMode.sounds));
    });

    test('both round-trip, and an unknown ladder falls back to sounds', () {
      final s = AppSettings.fromJson(
          const AppSettings().copyWith(cardPanelSwiped: true, soundLadder: SoundLadderMode.kana).toJson());
      expect((s.cardPanelSwiped, s.soundLadder), (true, SoundLadderMode.kana));
      expect(AppSettings.fromJson({'soundLadder': 'morse'}).soundLadder, SoundLadderMode.sounds);
    });
  });

  group('AppSettings.accessibilityMode', () {
    test('off by default, round-trips, and copyWith changes only it', () {
      expect(const AppSettings().accessibilityMode, isFalse);
      expect(AppSettings.fromJson({}).accessibilityMode, isFalse);
      final on = const AppSettings(language: 'ja').copyWith(accessibilityMode: true);
      expect((on.accessibilityMode, on.language), (true, 'ja'));
      expect(AppSettings.fromJson(on.toJson()).accessibilityMode, isTrue);
    });

    test('takes over 暗記練\'s old zoom switch, which then is no longer stored', () {
      expect(AppSettings.fromJson({'ankiren': {'zoom': true}}).accessibilityMode, isTrue);
      expect(AppSettings.fromJson({'ankiren': {'zoom': false}}).accessibilityMode, isFalse);
      expect(AppSettings.fromJson({'accessibilityMode': false, 'ankiren': {'zoom': true}}).accessibilityMode, isFalse,
          reason: 'the new switch wins');
      final migrated = AppSettings.fromJson({'ankiren': {'zoom': true, 'layout': 'landscape'}});
      expect(migrated.ankiren.layout, AnkirenLayout.landscape);
      expect(migrated.toJson()['accessibilityMode'], isTrue);
    });
  });

  group('AppSettings.ankiren (Settings › 寄り道 › 暗記練)', () {
    AppSettings roundTrip(AppSettings s) =>
        AppSettings.fromJson((jsonDecode(jsonEncode(s.toJson())) as Map).cast<String, dynamic>());

    test('defaults: portrait, text + voice, free play at level 0', () {
      for (final s in [const AppSettings(), AppSettings.fromJson({})]) {
        final a = s.ankiren;
        expect([a.layout, a.prompt], [AnkirenLayout.portrait, AnkirenPrompt.textAndVoice]);
        expect(a.freeSetup, AnkirenSetup.forLevel(0));
      }
    });

    test('every option round-trips through JSON, leaving the rest of the settings alone', () {
      const ankiren = AnkirenSettings(layout: AnkirenLayout.landscape, prompt: AnkirenPrompt.textOnly);
      final s = roundTrip(const AppSettings(language: 'ja', ankiren: ankiren));
      expect([s.ankiren.layout, s.ankiren.prompt], [AnkirenLayout.landscape, AnkirenPrompt.textOnly]);
      expect(s.language, 'ja');
    });

    test('the old opponent-cards and zoom options are dropped and no longer written', () {
      final a = AnkirenSettings.fromJson({'layout': 'landscape', 'zoom': true, 'opponentUpright': true});
      expect(a.layout, AnkirenLayout.landscape);
      expect(a.toJson().keys, isNot(anyOf(contains('zoom'), contains('opponentUpright'))));
      final s = AppSettings.fromJson({
        'ankiren': {'zoom': true, 'opponentUpright': true},
      });
      expect((s.toJson()['ankiren'] as Map).keys, isNot(anyOf(contains('zoom'), contains('opponentUpright'))));
    });

    test('free play remembers a preset, or a custom setup, and keeps the custom one under a preset', () {
      const custom = AnkirenSetup.custom(perSide: 13, memorise: Duration(minutes: 2, seconds: 30));
      final asCustom = const AnkirenSettings().withFreeSetup(custom);
      expect(roundTrip(AppSettings(ankiren: asCustom)).ankiren.freeSetup, custom);

      final asPreset = asCustom.withFreeSetup(AnkirenSetup.forLevel(7));
      final back = roundTrip(AppSettings(ankiren: asPreset)).ankiren;
      expect(back.freeSetup, AnkirenSetup.forLevel(7));
      expect([back.customPerSide, back.customMemorise], [13, const Duration(minutes: 2, seconds: 30)]);
    });

    test('copyWith changes only the options it is given', () {
      final a = const AnkirenSettings()
          .withFreeSetup(AnkirenSetup.forLevel(4))
          .copyWith(prompt: AnkirenPrompt.textOnly);
      expect([a.prompt, a.layout, a.freeLevel], [AnkirenPrompt.textOnly, AnkirenLayout.portrait, 4]);
    });

    test('values out of range or unknown fall back into range', () {
      final a = AnkirenSettings.fromJson({
        'layout': 'sideways',
        'prompt': 'mime',
        'freeLevel': 99,
        'customPerSide': 1,
        'customMemoriseMs': 3600000,
      });
      expect([a.layout, a.prompt], [AnkirenLayout.portrait, AnkirenPrompt.textAndVoice]);
      expect(a.freeLevel, AnkirenLevels.top);
      expect(a.customPerSide, AnkirenTuning.customMinPerSide);
      expect(a.customMemorise, AnkirenTuning.customMaxMemorise);
    });
  });
}
