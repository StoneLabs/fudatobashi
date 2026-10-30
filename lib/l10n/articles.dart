import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// The long translated texts, in Markdown: one folder per language,
/// `assets/l10n/<code>_articles/`, with the rules (`rules.md`), the guides
/// and each card's explanation (`card_details/NNN.md`). A language without
/// its own file for an article gets the English one.
abstract final class Articles {
  static const fallback = 'en';

  static const rules = 'rules';

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
