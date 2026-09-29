import 'package:flutter/painting.dart';

/// Line breaks that keep Japanese phrases whole. Japanese may break a line
/// between almost any two characters, so text marks where its phrases end
/// with [end] (a zero-width space), and [span] breaks its lines only there
/// and at spaces. Text without Japanese is left as it is.
abstract final class Phrases {
  static const end = '​';
  static const _joiner = '⁠';

  /// Characters a line may break beside: CJK punctuation, kana, kanji and
  /// full-width forms.
  static final _breaksAnywhere = RegExp(r'[⺀-鿿豈-﫿＀-￯]');

  /// [text] as a span that breaks only at spaces and phrase ends; screen
  /// readers get it without the marks.
  static TextSpan span(String text, {TextStyle? style}) =>
      TextSpan(text: _joined(text), style: style, semanticsLabel: spoken(text));

  /// [text] without its phrase marks.
  static String spoken(String text) => text.replaceAll(end, '');

  /// How many characters of [text] actually show (everything but its
  /// phrase marks) — a typewriter's pace counts these, not the marks.
  static int visibleLength(String text) => text.runes.where((r) => r != end.runes.first).length;

  /// [text] as a span with its first [shown] visible characters readable
  /// and the rest — laid out all the same, so nothing resizes — painted
  /// [hidden]: a typewriter reveal that never reflows.
  static TextSpan typed(String text, int shown, {TextStyle? style, required Color hidden}) {
    final runes = _joined(text).runes.toList();
    var seen = 0, cut = runes.length;
    for (var i = 0; i < runes.length; i++) {
      if (seen >= shown) {
        cut = i;
        break;
      }
      if (_visible(runes[i])) seen++;
    }
    return TextSpan(style: style, children: [
      TextSpan(text: String.fromCharCodes(runes, 0, cut)),
      TextSpan(text: String.fromCharCodes(runes, cut), style: TextStyle(color: hidden)),
    ]);
  }

  static bool _visible(int rune) => rune != end.runes.first && rune != _joiner.runes.first;

  static String _joined(String text) {
    final out = StringBuffer();
    String? before;
    for (final rune in text.runes) {
      final c = String.fromCharCode(rune);
      if (before != null && _joins(before, c)) out.write(_joiner);
      out.write(c);
      before = c;
    }
    return out.toString();
  }

  static bool _joins(String a, String b) =>
      !_isBreak(a) && !_isBreak(b) && (_breaksAnywhere.hasMatch(a) || _breaksAnywhere.hasMatch(b));

  static bool _isBreak(String c) => c == ' ' || c == end;
}
