import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import 'marker_heading.dart';
import 'prose.dart';
import 'ruby_text.dart';

/// Builds one block of Markdown (a heading, a paragraph, a list …) from its
/// element.
typedef MarkdownBlockBuilder = Widget Function(md.Element element, MarkdownProse prose);

/// Markdown set in the app's own prose type (see [proseStyle]): headings,
/// paragraphs with strong and emphasised text, bulleted and numbered lists,
/// quotes, rules, pictures from the asset bundle (`![caption](assets/…)` on
/// a line of its own) and poems in a `verse` fence, one line each, with
/// furigana markup (see [Ruby]). [blocks] maps each block element to its
/// builder; add an entry there to support another one.
///
/// A `# Title` heading is the page's [MarkerHeading] in [accent]; write
/// `# Title | Sub` to add a sub in the other language.
class MarkdownProse extends StatelessWidget {
  const MarkdownProse(this.source, {super.key, this.accent = Palette.sun});

  final String source;

  /// The colour of list markers and the emphasis highlight.
  final Color accent;

  /// The fence info string that marks a poem.
  static const verseFence = 'verse';

  static final Map<String, MarkdownBlockBuilder> blocks = {
    'h1': (e, p) => p._marker(e),
    'h2': (e, p) => p._heading(e, MarkdownLayout.h2Font, Fonts.display),
    'h3': (e, p) => p._heading(e, MarkdownLayout.h3Font, null),
    'h4': (e, p) => p._heading(e, MarkdownLayout.h4Font, null),
    'p': (e, p) => p._paragraph(e),
    'ul': (e, p) => p._list(e, ordered: false),
    'ol': (e, p) => p._list(e, ordered: true),
    'blockquote': (e, p) => p._quote(e),
    'pre': (e, p) => p._fence(e),
    'hr': (e, p) => p._rule(),
  };

  /// [source]'s blocks as parsed Markdown.
  static List<md.Node> parse(String source) =>
      md.Document(extensionSet: md.ExtensionSet.commonMark, encodeHtml: false).parse(source);

  @override
  Widget build(BuildContext context) {
    final nodes = parse(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, node) in nodes.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 || _isH1(nodes[i - 1]) ? 0 : _gapBefore(node)),
            child: _block(node),
          ),
      ],
    );
  }

  bool _isH1(md.Node node) => node is md.Element && node.tag == 'h1';

  double _gapBefore(md.Node node) => switch (node) {
        md.Element(tag: 'h1') => MarkdownLayout.h1Gap,
        md.Element(tag: 'h2') => MarkdownLayout.h2Gap,
        md.Element(tag: 'h3' || 'h4') => MarkdownLayout.h3Gap,
        _ => MarkdownLayout.blockGap,
      };

  Widget _block(md.Node node) {
    if (node is! md.Element) return Text(node.textContent, style: proseStyle);
    final builder = blocks[node.tag];
    return builder != null ? builder(node, this) : Text(node.textContent, style: proseStyle);
  }

  Widget _marker(md.Element e) {
    final (title, sub) = switch (e.textContent.split(' | ')) {
      [final t, final s, ...] => (t.trim(), s.trim()),
      final parts => (parts.first.trim(), null),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: MarkdownLayout.markerGap),
      child: MarkerHeading(title, sub, color: accent),
    );
  }

  Widget _heading(md.Element e, double size, String? family) => Semantics(
        header: true,
        child: Text.rich(
          _inline(e.children ?? const []),
          style: TextStyle(
            fontFamily: family,
            fontWeight: family == null ? Weights.black : null,
            fontSize: size,
            height: MarkdownLayout.headingLineHeight,
            color: Palette.ink,
          ),
        ),
      );

  Widget _paragraph(md.Element e) {
    final children = e.children ?? const <md.Node>[];
    if (children case [md.Element(tag: 'img') && final img]) return _picture(img);
    return Text.rich(_inline(children), style: proseStyle);
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

  Widget _list(md.Element e, {required bool ordered}) {
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
    if (children.every((n) => n is md.Text || (n is md.Element && !blocks.containsKey(n.tag)))) {
      return Text.rich(_inline(children), style: proseStyle);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final n in children) _block(n),
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

  Widget _quote(md.Element e) => Container(
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
                    ? Text.rich(_inline(n.children ?? const []), style: proseStyle.copyWith(fontWeight: Weights.bold))
                    : _block(n),
              ),
          ]),
        ),
      );

  /// A fenced block: a poem for [verseFence], else its text as written.
  Widget _fence(md.Element e) {
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

  Widget _rule() => const SizedBox(height: Strokes.hairline, child: ColoredBox(color: Palette.ink));

  TextSpan _inline(List<md.Node> nodes, [TextStyle? style]) => TextSpan(style: style, children: [
        for (final n in nodes)
          switch (n) {
            md.Text(:final text) => TextSpan(text: text.replaceAll('\n', ' ')),
            md.Element(tag: 'strong') => _inline(n.children ?? const [], const TextStyle(fontWeight: Weights.black)),
            md.Element(tag: 'em') =>
              _inline(n.children ?? const [], TextStyle(backgroundColor: Color.lerp(Palette.paper, accent, MarkdownLayout.highlight))),
            md.Element(tag: 'br') => const TextSpan(text: '\n'),
            md.Element() => _inline(n.children ?? const []),
            _ => TextSpan(text: n.textContent),
          },
      ]);
}
