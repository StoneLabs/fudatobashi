import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, AssetManifest, rootBundle;

/// The long translated texts, in Markdown: one folder per language,
/// `assets/l10n/<code>_articles/`, with the rules (`rules.md`), the guides
/// (`GuideScreen`) and each card's explanation (`card_details/NNN.md`). A
/// language without its own file for an article gets the English one.
abstract final class Articles {
  static const fallback = 'en';

  static const rules = 'rules';
  static const karutaGuide = 'karuta';
  static const kimarijiGuide = 'kimariji';
  static const teiichiGuide = 'teiichi';

  static String asset(String code, String name) => 'assets/l10n/${code}_articles/$name.md';

  static final _texts = <String, String>{};

  /// Article [name] in [code], read once and kept.
  static Future<String> load(String code, String name, {AssetBundle? bundle}) async =>
      _texts['$code/$name'] ??= await _read(code, name, bundle ?? rootBundle);

  static Future<String> _read(String code, String name, AssetBundle bundle) async {
    try {
      return await _decode(bundle, asset(code, name));
    } catch (_) {
      if (code == fallback) rethrow;
      return _decode(bundle, asset(fallback, name));
    }
  }

  /// Decoded here rather than with `loadString`, which hands a file the
  /// size of the rules to another isolate.
  static Future<String> _decode(AssetBundle bundle, String key) async {
    final data = await bundle.load(key);
    return utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}

/// The pictures articles show, in `assets/artworks/articles/` and shared by
/// every language. A picture may come in versions: `name.webp` is the
/// picture, `name.<code>.webp` its version for a language, and
/// `name_hiragana.webp` / `name_romaji.webp` its versions for the kana
/// setting, also by language (`name_romaji.ja.webp`). An article names the
/// picture itself; [pick] finds the version for its reader.
abstract final class ArticlePictures {
  static const folder = 'assets/artworks/articles/';

  /// The file name ends for the kana setting.
  static const kana = '_hiragana', romaji = '_romaji';

  static Set<String>? _files;

  /// Every picture file there is.
  static Future<Set<String>> load({AssetBundle? bundle}) async => _files ??= {
        for (final asset in (await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle)).listAssets())
          if (asset.startsWith(folder)) asset,
      };

  /// The version of picture [src] among [files] for a reader of [language]
  /// who reads kana in romaji or not: the one for both, then for the kana
  /// setting, then for the language, English standing in for a language
  /// without its own; else [src] itself.
  static String pick(String src, Set<String> files, {required String language, required bool romaji}) {
    final dot = src.lastIndexOf('.');
    if (dot < 0) return src;
    final stem = src.substring(0, dot), extension = src.substring(dot);
    final languages = {'.$language', '.${Articles.fallback}', ''};
    for (final script in [romaji ? ArticlePictures.romaji : kana, '']) {
      for (final code in languages) {
        final file = '$stem$script$code$extension';
        if (files.contains(file)) return file;
      }
    }
    return src;
  }
}
