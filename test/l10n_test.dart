import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/l10n/localization.dart';
import 'package:fudatobashi/l10n/romaji.dart';
import 'package:fudatobashi/l10n/strings.dart';

/// `{0}`, `{1}` … or a named slot like `{band}`.
final _placeholder = RegExp(r'\{[a-zA-Z0-9]+\}');

void main() {
  final en = jsonDecode(File('assets/l10n/en.json').readAsStringSync()) as Map<String, dynamic>;
  final ja = jsonDecode(File('assets/l10n/ja.json').readAsStringSync()) as Map<String, dynamic>;

  test('languages.json lists every bundled assets/l10n/*.json file', () {
    final index = (jsonDecode(File('assets/l10n/languages.json').readAsStringSync()) as List).cast<String>();
    final files = {
      for (final f in Directory('assets/l10n').listSync())
        if (f.path.endsWith('.json') && !f.path.endsWith('languages.json')) f.path.split('/').last.replaceAll('.json', ''),
    };
    expect(index.toSet(), files);
  });

  test('every key in en.json exists in ja.json and vice versa', () {
    expect(en.keys.toSet(), ja.keys.toSet());
  });

  test('every value is a string', () {
    for (final v in [...en.values, ...ja.values]) {
      expect(v, isA<String>());
    }
  });

  test('placeholders match between en.json and ja.json for every key', () {
    for (final key in en.keys) {
      final enSlots = _placeholder.allMatches(en[key] as String).map((m) => m.group(0)).toSet();
      final jaSlots = _placeholder.allMatches(ja[key] as String).map((m) => m.group(0)).toSet();
      expect(jaSlots, enSlots, reason: key);
    }
  });

  test('each file names its own language', () {
    expect(en['languageName'], 'English');
    expect(ja['languageName'], '日本語');
  });

  test('every one of the 100 poems has a kimariji key and a pre-generated voice clip', () {
    for (var id = 1; id <= 100; id++) {
      final key = 'kimariji${id.toString().padLeft(3, '0')}';
      expect(en[key], isA<String>(), reason: key);
      expect(ja[key], isA<String>(), reason: key);
      expect(File('assets/voice/kimariji/${id.toString().padLeft(3, '0')}.m4a').existsSync(), isTrue, reason: key);
    }
  });

  test("hepburn reads each card's kimariji as its romaji key does (long vowels aside)", () {
    final poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
    for (final poem in poems.all) {
      final key = 'kimariji${poem.id.toString().padLeft(3, '0')}';
      final romaji = (en[key] as String).replaceAll('ō', 'oo').replaceAll('ū', 'uu');
      expect(hepburn(poem.kamiReading.substring(0, poem.kimariji.length)), romaji, reason: key);
    }
  });

  group('Localization', () {
    setUp(() {
      Localization.loadFromSource(
        indexJson: '["en", "ja", "xx"]',
        jsonByCode: {
          'en': '{"languageName": "English", "greeting": "Hello", "onlyInEnglish": "Only in English"}',
          'ja': '{"languageName": "日本語", "greeting": "こんにちは"}',
          // A third language missing every key, to exercise the fallback.
          'xx': '{"languageName": "Xx"}',
        },
      );
    });

    test('reads the string for the requested language', () {
      expect(Localization.lookup('ja', 'greeting'), 'こんにちは');
    });

    test('falls back to English when a key is missing in the language', () {
      expect(Localization.lookup('ja', 'onlyInEnglish'), 'Only in English');
      expect(Localization.lookup('xx', 'greeting'), 'Hello');
    });

    test('falls back to the key itself when English has nothing either', () {
      expect(Localization.lookup('en', 'noSuchKey'), 'noSuchKey');
    });

    test('lists every language with its own native name', () {
      expect({for (final l in Localization.languages) l.code: l.name}, {'en': 'English', 'ja': '日本語', 'xx': 'Xx'});
    });

    test('resolve: a stored code wins over the device language', () {
      expect(Localization.resolve('ja', 'en'), 'ja');
    });

    test('resolve: "system" picks the device language when a file exists for it', () {
      expect(Localization.resolve('system', 'ja'), 'ja');
    });

    test('resolve: "system" falls back to English when no file matches the device language', () {
      expect(Localization.resolve('system', 'fr'), 'en');
    });

    test('resolve: an unavailable stored code falls back to English', () {
      expect(Localization.resolve('fr', 'en'), 'en');
    });

    test('S.other is Japanese unless the UI is already Japanese, even with a third language', () {
      expect(const S('en').other.code, 'ja');
      expect(const S('ja').other.code, 'en');
      expect(const S('xx').other.code, 'ja');
    });
  });
}
