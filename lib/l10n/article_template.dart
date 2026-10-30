import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:jinja/jinja.dart';

/// Every article is a Jinja template before it is Markdown. What an article
/// can know is the reader's kana setting, as `env.romaji_mode`, so one
/// picture can be named for both settings:
/// `![](assets/artworks/articles/stairs_{{ "romaji" if env.romaji_mode else "hiragana" }}.en.webp)`.
/// Text is not escaped, a `{% … %}` line on its own leaves no blank line,
/// and a name the template does not know is an error.
abstract final class ArticleTemplate {
  static final _environment = Environment(
    trimBlocks: true,
    leftStripBlocks: true,
    keepTrailingNewLine: true,
    getItem: _strictItem,
    undefined: (name, [path]) => throw StateError('Article template: "$name" is not defined'),
  );

  static Object? _strictItem(Object? key, dynamic object) {
    if (object is! Map) return null;
    if (!object.containsKey(key)) throw StateError('Article template: "$key" is not defined');
    return object[key];
  }

  /// [source] with its template filled in for a reader who reads kana in
  /// romaji or not. A broken template is an error in a debug build; a
  /// release build shows the text as it is.
  static String fill(String source, {required bool romaji}) {
    try {
      return _environment.fromString(source).render({
        'env': {'romaji_mode': romaji},
      });
    } catch (_) {
      if (kDebugMode) rethrow;
      return source;
    }
  }
}
