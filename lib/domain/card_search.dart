import 'package:flutter/foundation.dart';

import '../data/poem.dart';

/// What a search in the card browser found on a card.
enum CardMatchKind {
  /// An empty search: every card, nothing marked.
  all,

  /// The start of its number.
  number,

  /// The start of its kimariji or first half, in kana.
  kana,

  /// The start of its kimariji or first half, in romaji.
  romaji,

  /// The start of its second half (the torifuda), when no first half
  /// matched.
  shimo,
}

/// One card a search found: what matched, and how many leading characters
/// of the matched text to mark (of the number, the kana kimariji, the
/// romaji kimariji or [shimo]).
@immutable
class CardMatch {
  const CardMatch(this.poem, this.kind, {this.marked = 0, this.shimo});

  final Poem poem;
  final CardMatchKind kind;
  final int marked;

  /// The second half as matched, for [CardMatchKind.shimo].
  final String? shimo;
}

/// The card browser's search: a number from its start; a kimariji in kana
/// or romaji (long vowels typed ō, oo or ou all match), or the start of the
/// first half; and only when none of those match, the start of the second
/// half.
class CardSearch {
  CardSearch(this.poems, {required this.romajiOf});

  final List<Poem> poems;

  /// A card's kimariji as the app writes it in romaji, by id.
  final String Function(int id) romajiOf;

  List<CardMatch> find(String query) {
    final q = normalize(query);
    if (q.isEmpty) return [for (final p in poems) CardMatch(p, CardMatchKind.all)];
    if (isNumber(q)) {
      return [
        for (final p in poems)
          if ('${p.id}'.startsWith(q)) CardMatch(p, CardMatchKind.number, marked: q.length),
      ];
    }
    final plainQuery = _plainRomaji(q);
    final kami = <CardMatch>[];
    for (final p in poems) {
      if (p.kimariji.startsWith(q) || p.kamiReading.startsWith(q) || _unspaced(p.kamiKana).startsWith(q)) {
        kami.add(CardMatch(p, CardMatchKind.kana, marked: q.length.clamp(0, p.kimariji.length)));
        continue;
      }
      final romaji = romajiOf(p.id);
      if (_plainRomaji(romaji).startsWith(plainQuery) ||
          _plainRomaji(p.versesRomaji.take(3).join()).startsWith(plainQuery)) {
        kami.add(CardMatch(p, CardMatchKind.romaji, marked: _romajiMarked(romaji, plainQuery)));
      }
    }
    if (kami.isNotEmpty) return kami;
    return [
      for (final p in poems)
        if (_shimoMatch(p, q) case final shimo?) CardMatch(p, CardMatchKind.shimo, marked: q.length, shimo: shimo),
    ];
  }

  /// [query] as searched: lower case, no spaces, katakana as hiragana and
  /// full-width letters and digits as plain ones.
  static String normalize(String query) {
    final out = StringBuffer();
    for (final rune in query.trim().toLowerCase().runes) {
      if (rune >= _katakanaFirst && rune <= _katakanaLast) {
        out.writeCharCode(rune - _katakanaToHiragana);
      } else if (rune >= _fullWidthFirst && rune <= _fullWidthLast) {
        out.write(String.fromCharCode(rune - _fullWidthToAscii).toLowerCase());
      } else if (!_spaces.contains(String.fromCharCode(rune))) {
        out.writeCharCode(rune);
      }
    }
    return out.toString();
  }

  /// Whether a [normalize]d query looks for a card's number.
  static bool isNumber(String normalized) => _digits.hasMatch(normalized);

  /// [p]'s second half as matched, as written (like the torifuda) or else
  /// as pronounced, if either starts with [q].
  static String? _shimoMatch(Poem p, String q) {
    final written = _unspaced(p.shimoKana);
    if (written.startsWith(q) || p.kimarijiShimo.startsWith(q)) return written;
    if (p.shimoReading.startsWith(q)) return p.shimoReading;
    return null;
  }

  /// How many characters of [romaji] a plain query of [plainQuery] covers.
  static int _romajiMarked(String romaji, String plainQuery) {
    for (var k = 1; k <= romaji.length; k++) {
      if (_plainRomaji(romaji.substring(0, k)).length >= plainQuery.length) return k;
    }
    return romaji.length;
  }

  /// Romaji with long vowels shortened, however they are typed (ō, oo, ou).
  static String _plainRomaji(String romaji) => romaji
      .replaceAll('ō', 'o')
      .replaceAll('ū', 'u')
      .replaceAll(_longO, 'o')
      .replaceAll('uu', 'u');

  static String _unspaced(String text) => text.replaceAll(_spacesPattern, '');

  static final _digits = RegExp(r'^\d+$');
  static final _longO = RegExp('o[ou]');
  static const _spaces = ' 　\t\n';
  static final _spacesPattern = RegExp('[ 　]');
  static const _katakanaFirst = 0x30A1, _katakanaLast = 0x30F6, _katakanaToHiragana = 0x60;
  static const _fullWidthFirst = 0xFF01, _fullWidthLast = 0xFF5E, _fullWidthToAscii = 0xFEE0;
}
