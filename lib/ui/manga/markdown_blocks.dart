import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import '../../l10n/article_template.dart';
import '../../l10n/romaji.dart';
import 'article_picture.dart';
import 'phrases.dart';
import 'prose.dart';
import 'ruby_text.dart';
import 'tobi.dart';
import 'tobi_line.dart';

/// How a document shows what depends on its reader and its screen.
@immutable
class MarkdownOptions {
  const MarkdownOptions({
    this.romaji = false,
    this.kanaBesideRomaji = false,
    this.phrases = false,
  });

  /// Whether the reader reads kana in romaji: a kana mark shows its romaji,
  /// and the document's template can choose on it (`env.romaji_mode`, see
  /// [ArticleTemplate]).
  final bool romaji;

  /// Whether a kana mark in romaji keeps its kana, on one line, in front of
  /// the romaji: む⁠す⁠め (musume).
  final bool kanaBesideRomaji;

  /// Whether the document marks where its phrases end, so that Japanese
  /// breaks its lines only there ([Phrases]).
  final bool phrases;
}

/// What every Markdown document shares: the parsing and the widgets for
/// paragraphs with strong and emphasised text, bulleted and numbered lists,
/// quotes, rules, pictures (`![caption](assets/…)` on a line of its own,
/// see [ArticlePicture]), Tobi's lines (`>{.tobi} Text`, or
/// `>{.tobi pose=waving} Text`, see [TobiPose.named]) and poems in a
/// `verse` fence, one line each, with furigana markup (see [Ruby]). In any
/// text, a kana mark (`{あきの}`, the kana as they sound) shows as romaji
/// when the reader reads romaji. An HTML comment (`<!-- … -->`) on lines of
/// its own is left out. A document's own class decides how its headings
/// look ([heading]) and may override any other block, or [layout] to group
/// blocks itself. Show one with `MarkdownProse`.
abstract class MarkdownBlocks {
  const MarkdownBlocks({this.accent = Palette.sun, this.options = const MarkdownOptions()});

  /// The colour of list markers and the emphasis highlight.
  final Color accent;

  final MarkdownOptions options;

  /// The fence info string that marks a poem.
  static const verseFence = 'verse';

  /// The tags of the elements that [block] builds a widget for.
  static const blockTags = {'h1', 'h2', 'h3', 'h4', 'p', 'ul', 'ol', 'blockquote', 'pre', 'hr'};

  /// The tag of a kana mark's element.
  static const kanaTag = 'kana';

  /// [source]'s blocks as parsed Markdown.
  static List<md.Node> parse(String source) => [
        for (final node in md.Document(
          extensionSet: md.ExtensionSet.commonMark,
          inlineSyntaxes: [_KanaMark()],
          encodeHtml: false,
        ).parse(source))
          if (!(node is md.Text && node.text.trimLeft().startsWith('<!--'))) node,
      ];

  static final _tobiMark = RegExp(r'^\{\.tobi((?:\s+[\w-]+=[\w-]*)*)\s*\}\s*');
  static final _attribute = RegExp(r'([\w-]+)=([\w-]*)');

  /// A Tobi line's pose as written (null for none) and its words, or null
  /// when [node] is no Tobi line.
  static ({String? pose, List<md.Node> words})? tobiLine(md.Node node) {
    if (node case md.Element(tag: 'blockquote', children: [md.Element(tag: 'p', :final children?), ...])) {
      if (children case [md.Text(:final text), ...final rest]) {
        final mark = _tobiMark.matchAsPrefix(text);
        if (mark == null) return null;
        final pose = [for (final a in _attribute.allMatches(mark[1]!)) if (a[1] == 'pose') a[2]!].firstOrNull;
        return (pose: pose, words: [md.Text(text.substring(mark.end)), ...rest]);
      }
    }
    return null;
  }

  /// Whether [node] is a picture: a paragraph that holds only one.
  static bool isPicture(md.Node node) => node is md.Element && node.tag == 'p' && _picture(node) != null;

  static md.Element? _picture(md.Element p) => switch (p.children) {
        [md.Element(tag: 'img') && final img] => img,
        _ => null,
      };

  Widget build(String source) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: layout(parse(ArticleTemplate.fill(source, romaji: options.romaji))));

  /// The blocks in order, each with its gap above.
  List<Widget> layout(List<md.Node> nodes) => [
        for (final (i, node) in nodes.indexed)
          Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : gapBefore(node, nodes[i - 1])), child: block(node)),
      ];

  double gapBefore(md.Node node, md.Node previous) => MarkdownLayout.blockGap;

  Widget heading(md.Element e, int level);

  /// A heading's text split at ` | ` into a title and its sub.
  (String, String?) titleAndSub(md.Element e) => switch (plain(e.children ?? const []).split(' | ')) {
        [final t, final s, ...] => (t.trim(), s.trim()),
        final parts => (parts.first.trim(), null),
      };

  Widget block(md.Node node) {
    if (node is! md.Element) return Text(node.textContent, style: proseStyle);
    return switch (node.tag) {
      'h1' => heading(node, 1),
      'h2' => heading(node, 2),
      'h3' => heading(node, 3),
      'h4' => heading(node, 4),
      'p' => paragraph(node),
      'ul' => list(node, ordered: false),
      'ol' => list(node, ordered: true),
      'blockquote' => quote(node),
      'pre' => fence(node),
      'hr' => rule(),
      _ => Text(node.textContent, style: proseStyle),
    };
  }

  Widget paragraph(md.Element e) {
    if (_picture(e) case final img?) return picture(img);
    return Text.rich(inline(e.children ?? const []), style: proseStyle);
  }

  Widget picture(md.Element img) => ArticlePicture(
        src: img.attributes['src']!,
        caption: img.attributes['alt'] ?? '',
      );

  Widget list(md.Element e, {required bool ordered}) {
    final start = int.tryParse(e.attributes['start'] ?? '') ?? 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, item) in items(e).indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : MarkdownLayout.itemGap),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: MarkdownLayout.markerColumn,
              child: ordered ? _number(start + i) : _diamond(),
            ),
            Expanded(child: itemBody(item)),
          ]),
        ),
    ]);
  }

  /// A list's items.
  static List<md.Element> items(md.Element list) =>
      [for (final n in list.children ?? const <md.Node>[]) if (n is md.Element && n.tag == 'li') n];

  /// A list item's text, or its blocks when it holds paragraphs of its own
  /// (a "loose" list).
  Widget itemBody(md.Element item) {
    final children = item.children ?? const <md.Node>[];
    if (children.every((n) => n is md.Text || (n is md.Element && !blockTags.contains(n.tag)))) {
      return Text.rich(inline(children), style: proseStyle);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final n in children) block(n),
    ]);
  }

  Widget _number(int n) => Text('$n.',
      style: const TextStyle(
          fontFamily: Fonts.display, fontSize: MarkdownLayout.numberFont, height: MarkdownLayout.numberLineHeight));

  Widget _diamond() => Padding(
        padding: const EdgeInsets.only(top: MarkdownLayout.diamondTop, left: MarkdownLayout.diamondLeft),
        child: Align(
          alignment: Alignment.topLeft,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: MarkdownLayout.diamond,
              height: MarkdownLayout.diamond,
              decoration: BoxDecoration(color: accent, border: Border.all(color: Palette.ink, width: Strokes.label)),
            ),
          ),
        ),
      );

  /// A quote, or Tobi saying a line.
  Widget quote(md.Element e) {
    if (tobiLine(e) case (:final pose, :final words)) {
      return TobiLine(plain(words).trim(),
          pose: TobiPose.named(pose ?? '') ?? TobiPose.standard, phrases: options.phrases);
    }
    return Container(
      padding: MarkdownLayout.quotePadding,
      decoration: const BoxDecoration(
        color: Palette.desk,
        border: Border(left: BorderSide(color: Palette.ink, width: MarkdownLayout.quoteRule)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: Weights.bold),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, n) in (e.children ?? const <md.Node>[]).indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : MarkdownLayout.blockGap),
              child: n is md.Element && n.tag == 'p'
                  ? Text.rich(inline(n.children ?? const []), style: proseStyle.copyWith(fontWeight: Weights.bold))
                  : block(n),
            ),
        ]),
      ),
    );
  }

  /// A fenced block: a poem for [verseFence], else its text as written.
  Widget fence(md.Element e) {
    final code = e.children?.whereType<md.Element>().firstOrNull;
    final text = (code?.textContent ?? e.textContent).trimRight();
    if (code?.attributes['class'] != 'language-$verseFence') return Text(text, style: proseStyle);
    return Container(
      padding: MarkdownLayout.versePadding,
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: Strokes.label),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (i, line) in text.split('\n').indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : MarkdownLayout.verseLineGap),
            child: RubyText(line, style: MarkdownLayout.verseStyle),
          ),
      ]),
    );
  }

  Widget rule() => const SizedBox(height: Strokes.hairline, child: ColoredBox(color: Palette.ink));

  TextSpan inline(List<md.Node> nodes, [TextStyle? style]) => TextSpan(style: style, children: [
        for (final n in nodes)
          switch (n) {
            md.Text(:final text) => _words(text.replaceAll('\n', ' ')),
            md.Element(tag: kanaTag) => _words(kana(n.textContent)),
            md.Element(tag: 'strong') => inline(n.children ?? const [], const TextStyle(fontWeight: Weights.black)),
            md.Element(tag: 'em') =>
              inline(n.children ?? const [], TextStyle(backgroundColor: Color.lerp(Palette.paper, accent, MarkdownLayout.highlight))),
            md.Element(tag: 'br') => const TextSpan(text: '\n'),
            md.Element() => inline(n.children ?? const []),
            _ => TextSpan(text: n.textContent),
          },
      ]);

  TextSpan _words(String text) => options.phrases ? Phrases.span(text) : TextSpan(text: text);

  /// [nodes] as plain text, kana marks as the reader reads them.
  String plain(List<md.Node> nodes) => [
        for (final n in nodes)
          switch (n) {
            md.Text(:final text) => text.replaceAll('\n', ' '),
            md.Element(tag: kanaTag) => kana(n.textContent),
            md.Element(tag: 'br') => '\n',
            md.Element(:final children) => plain(children ?? const []),
            _ => n.textContent,
          },
      ].join();

  /// A kana mark's text: its [kana], or in romaji their romaji, after them
  /// with [MarkdownOptions.kanaBesideRomaji].
  String kana(String kana) {
    if (!options.romaji) return kana;
    final romaji = hepburn(kana);
    return options.kanaBesideRomaji ? '${kana.split('').join(_wordJoiner)} ($romaji)' : romaji;
  }
}

/// Keeps the characters either side of it on one line.
const _wordJoiner = '⁠';

/// `{あきの}`: kana that show as romaji when the reader reads romaji. Braces
/// that start with a dot (`{.tobi}`) are no kana mark.
class _KanaMark extends md.InlineSyntax {
  _KanaMark() : super(r'\{(?!\s*\.)([^{}\n]+)\}', startCharacter: 0x7B);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(MarkdownBlocks.kanaTag, match[1]!));
    return true;
  }
}
