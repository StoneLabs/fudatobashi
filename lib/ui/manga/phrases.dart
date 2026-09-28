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
