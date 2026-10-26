import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Each card's explanation (解説) on its About page: one Markdown file per
/// card and language, `assets/l10n/<code>_card_explanations/NNN.md` (see
/// `MarkdownProse` for what they may hold), and 000.md for the 序歌. A
/// language without its own file for a card gets the English one.
abstract final class CardExplanations {
  static final _loaded = <String, Future<String>>{};

  /// The 序歌's number here, before card 1.
  static const int joka = 0;

  static String asset(String code, int id) => 'assets/l10n/${code}_card_explanations/${id.toString().padLeft(3, '0')}.md';

  /// Poem [id]'s explanation in [code], read once and kept.
  static Future<String> load(String code, int id, {AssetBundle? bundle}) =>
      _loaded.putIfAbsent('$code/$id', () => _read(code, id, bundle ?? rootBundle));

  static Future<String> _read(String code, int id, AssetBundle bundle) async {
    try {
      return await bundle.loadString(asset(code, id));
    } catch (_) {
      if (code == 'en') rethrow;
      return bundle.loadString(asset('en', id));
    }
  }
}
