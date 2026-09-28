import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// A run of furigana text: its [base], and the [reading] printed above it
/// (none for kana).
@immutable
class RubyRun {
  const RubyRun(this.base, [this.reading]);

  final String base;
  final String? reading;

  @override
  bool operator ==(Object other) => other is RubyRun && other.base == base && other.reading == reading;

  @override
  int get hashCode => Object.hash(base, reading);

  @override
  String toString() => reading == null ? base : '[$base|$reading]';
}

/// Furigana markup, as in the poem data: `[漢字|かな]` gives 漢字 the reading
/// かな, and a full-width space ends a phrase
/// (`[巡|めぐ]り[逢|あ]ひて　[見|み]しや…`).
abstract final class Ruby {
  static const phraseBreak = '　';
  static final _annotated = RegExp(r'\[([^|\]]+)\|([^\]]+)\]');

  /// [markup]'s phrases, each as its runs.
  static List<List<RubyRun>> phrases(String markup) =>
      [for (final phrase in markup.split(phraseBreak)) if (phrase.isNotEmpty) runs(phrase)];

  /// One phrase of markup as its runs, in order.
  static List<RubyRun> runs(String phrase) {
    final runs = <RubyRun>[];
    var at = 0;
    for (final m in _annotated.allMatches(phrase)) {
      if (m.start > at) runs.add(RubyRun(phrase.substring(at, m.start)));
      runs.add(RubyRun(m[1]!, m[2]));
      at = m.end;
    }
    if (at < phrase.length) runs.add(RubyRun(phrase.substring(at)));
    return runs;
  }

  /// [markup] as plain text, without its readings.
  static String plain(String markup) => markup.replaceAllMapped(_annotated, (m) => m[1]!);
}

/// Text with furigana: each reading small and centred above its run. Lines
/// break only between phrases, which sit a full-width space apart, and every
/// line keeps room for readings, so lines with and without them space evenly.
class RubyText extends StatelessWidget {
  const RubyText(this.markup, {super.key, required this.style, this.readingStyle});

  /// Furigana markup (see [Ruby]).
  final String markup;

  /// The base text's style. It needs a font size: the readings and the gap
  /// between phrases are sized from it.
  final TextStyle style;

  /// Defaults to [style] at [RubyStyle.readingScale] of its size.
  final TextStyle? readingStyle;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize!;
    final reading =
        readingStyle ?? style.copyWith(fontSize: fontSize * RubyStyle.readingScale, height: RubyStyle.readingHeight);
    return Semantics(
      label: Ruby.plain(markup).replaceAll(Ruby.phraseBreak, ' '),
      excludeSemantics: true,
      child: Wrap(
        spacing: MediaQuery.textScalerOf(context).scale(fontSize),
        children: [
          for (final phrase in Ruby.phrases(markup))
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (final run in phrase) _Run(run, style: style, readingStyle: reading)],
            ),
        ],
      ),
    );
  }
}

class _Run extends StatelessWidget {
  const _Run(this.run, {required this.style, required this.readingStyle});
  final RubyRun run;
  final TextStyle style;
  final TextStyle readingStyle;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(run.reading ?? '', maxLines: 1, softWrap: false, style: readingStyle),
          const SizedBox(height: RubyStyle.readingGap),
          Text(run.base, maxLines: 1, softWrap: false, style: style),
        ],
      );
}
