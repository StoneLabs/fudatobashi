import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import 'prose.dart';
import 'ruby_text.dart';

/// What every Markdown document shares: the parsing and the widgets for
/// paragraphs with strong and emphasised text, bulleted and numbered lists,
/// quotes, rules, pictures from the asset bundle (`![caption](assets/…)` on
/// a line of its own) and poems in a `verse` fence, one line each, with
/// furigana markup (see [Ruby]). A document's own class decides how its
/// headings look ([heading]) and may override any other block, or [layout]
/// to group blocks itself. Show one with `MarkdownProse`.
abstract class MarkdownBlocks {
  const MarkdownBlocks({this.accent = Palette.sun});

  /// The colour of list markers and the emphasis highlight.
  final Color accent;

  /// The fence info string that marks a poem.
  static const verseFence = 'verse';

  /// The tags of the elements that [block] builds a widget for.
  static const blockTags = {'h1', 'h2', 'h3', 'h4', 'p', 'ul', 'ol', 'blockquote', 'pre', 'hr'};

  /// [source]'s blocks as parsed Markdown.
  static List<md.Node> parse(String source) =>
      md.Document(extensionSet: md.ExtensionSet.commonMark, encodeHtml: false).parse(source);

  /// A heading's text split at ` | ` into a title and its sub.
  static (String, String?) splitHeading(md.Element e) => switch (e.textContent.split(' | ')) {
        [final t, final s, ...] => (t.trim(), s.trim()),
        final parts => (parts.first.trim(), null),
      };

  Widget build(String source) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: layout(parse(source)));

  /// The blocks in order, each with its gap above.
  List<Widget> layout(List<md.Node> nodes) => [
        for (final (i, node) in nodes.indexed)
          Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : gapBefore(node, nodes[i - 1])), child: block(node)),
      ];

  double gapBefore(md.Node node, md.Node previous) => MarkdownLayout.blockGap;

  Widget heading(md.Element e, int level);

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
    final children = e.children ?? const <md.Node>[];
    if (children case [md.Element(tag: 'img') && final img]) return _picture(img);
    return Text.rich(inline(children), style: proseStyle);
  }

  /// A picture from the asset bundle, as wide as it fits up to its own
  /// size, its alt text as the caption under it.
  Widget _picture(md.Element img) {
    final caption = img.attributes['alt'] ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: MarkdownLayout.pictureMaxHeight),
        child: Image.asset(img.attributes['src']!, semanticLabel: caption, fit: BoxFit.contain),
      ),
      if (caption.isNotEmpty) ...[
        const SizedBox(height: MarkdownLayout.captionGap),
        Text(caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: Weights.bold, fontSize: MarkdownLayout.captionFont, color: MarkdownLayout.captionColor)),
      ],
    ]);
  }

  Widget list(md.Element e, {required bool ordered}) {
    final start = int.tryParse(e.attributes['start'] ?? '') ?? 1;
    final items = [for (final n in e.children ?? const <md.Node>[]) if (n is md.Element && n.tag == 'li') n];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, item) in items.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : MarkdownLayout.itemGap),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: MarkdownLayout.markerColumn,
              child: ordered ? _number(start + i) : _diamond(),
            ),
            Expanded(child: _itemBody(item)),
          ]),
        ),
    ]);
  }

  /// A list item's text, or its blocks when it holds paragraphs of its own
  /// (a "loose" list).
  Widget _itemBody(md.Element item) {
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

  Widget quote(md.Element e) => Container(
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
            md.Text(:final text) => TextSpan(text: text.replaceAll('\n', ' ')),
            md.Element(tag: 'strong') => inline(n.children ?? const [], const TextStyle(fontWeight: Weights.black)),
            md.Element(tag: 'em') =>
              inline(n.children ?? const [], TextStyle(backgroundColor: Color.lerp(Palette.paper, accent, MarkdownLayout.highlight))),
            md.Element(tag: 'br') => const TextSpan(text: '\n'),
            md.Element() => inline(n.children ?? const []),
            _ => TextSpan(text: n.textContent),
          },
      ]);
}
