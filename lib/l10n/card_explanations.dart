import 'package:flutter/services.dart' show AssetBundle;

import 'articles.dart';

/// Each card's explanation (解説) on its About page: one article per card,
/// `card_details/NNN.md` (see `MarkdownProse` for what they may hold), and
/// 000.md for the 序歌 (`jokaNumber`).
abstract final class CardExplanations {
  static String article(int id) => 'card_details/${id.toString().padLeft(3, '0')}';

  static String asset(String code, int id) => Articles.asset(code, article(id));

  /// Poem [id]'s explanation in [code].
  static Future<String> load(String code, int id, {AssetBundle? bundle}) =>
      Articles.load(code, article(id), bundle: bundle);
}
