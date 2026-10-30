import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import 'markdown_blocks.dart';
import 'marker_heading.dart';
import 'prose.dart';

/// A Markdown document, laid out by [blocks]: by default the card
/// explanations' [ProseBlocks] in [accent].
class MarkdownProse extends StatelessWidget {
  const MarkdownProse(this.source, {super.key, this.accent = Palette.sun, this.blocks});

  final String source;
  final Color accent;
  final MarkdownBlocks? blocks;

  @override
  Widget build(BuildContext context) => (blocks ?? ProseBlocks(accent: accent)).build(source);
}

/// How a prose document's headings and numbered lists look.
enum ProseStyle {
  /// A card's explanation: a `#` heading is the page's [MarkerHeading] in
  /// the accent colour, the deeper ones display type, then bold.
  explanation,

  /// A guide: each `#` heading is a numbered chapter ([ProseChapter]),
  /// numbered in order, a deeper one a small heading ([ProseSubhead]), and
  /// a numbered list steps ([ProseStep]).
  guide,
}

/// Prose in a [style]. Write `# Title | Sub` to add a sub in the other
/// language to a `#` heading.
class ProseBlocks extends MarkdownBlocks {
  const ProseBlocks({super.accent, super.options, this.style = ProseStyle.explanation});

  final ProseStyle style;

  static const _chapter = 'chapter';

  @override
  List<Widget> layout(List<md.Node> nodes) {
    if (style == ProseStyle.guide) {
      var chapter = 0;
      for (final h in nodes.whereType<md.Element>().where((e) => e.tag == 'h1')) {
        h.attributes[_chapter] = '${++chapter}';
      }
    }
    return super.layout(nodes);
  }

  @override
  Widget heading(md.Element e, int level) {
    if (style == ProseStyle.guide) {
      if (level > 1) return ProseSubhead(plain(e.children ?? const []));
      final (title, sub) = titleAndSub(e);
      return ProseChapter(int.parse(e.attributes[_chapter]!), title, sub, first: true);
    }
    if (level == 1) return _marker(e);
    final (size, family) = switch (level) {
      2 => (MarkdownLayout.h2Font, Fonts.display),
      3 => (MarkdownLayout.h3Font, null),
      _ => (MarkdownLayout.h4Font, null),
    };
    return Semantics(
      header: true,
      child: Text.rich(
        inline(e.children ?? const []),
        style: TextStyle(
          fontFamily: family,
          fontWeight: family == null ? Weights.black : null,
          fontSize: size,
          height: MarkdownLayout.headingLineHeight,
          color: Palette.ink,
        ),
      ),
    );
  }

  Widget _marker(md.Element e) {
    final (title, sub) = titleAndSub(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: MarkdownLayout.markerGap),
      child: MarkerHeading(title, sub, color: accent),
    );
  }

  @override
  Widget list(md.Element e, {required bool ordered}) {
    if (style == ProseStyle.explanation || !ordered) return super.list(e, ordered: ordered);
    final start = int.tryParse(e.attributes['start'] ?? '') ?? 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, item) in MarkdownBlocks.items(e).indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : GuideLayout.stepGap),
          child: ProseStep(start + i, inline(item.children ?? const [])),
        ),
    ]);
  }

  @override
  double gapBefore(md.Node node, md.Node previous) {
    if (style == ProseStyle.guide) return _guideGap(node) + (MarkdownBlocks.isPicture(previous) ? GuideLayout.pictureGap : 0);
    if (previous is md.Element && previous.tag == 'h1') return 0;
    return switch (node) {
      md.Element(tag: 'h1') => MarkdownLayout.h1Gap,
      md.Element(tag: 'h2') => MarkdownLayout.h2Gap,
      md.Element(tag: 'h3' || 'h4') => MarkdownLayout.h3Gap,
      _ => MarkdownLayout.blockGap,
    };
  }

  double _guideGap(md.Node node) {
    if (MarkdownBlocks.isPicture(node)) return GuideLayout.pictureGap;
    if (MarkdownBlocks.tobiLine(node) != null) return GuideLayout.tobiGap;
    return switch (node) {
      md.Element(tag: 'h1') => GuideLayout.chapterGap,
      md.Element(tag: 'h2' || 'h3' || 'h4') => GuideLayout.subheadGap,
      md.Element(tag: 'ol') => GuideLayout.stepGap,
      _ => GuideLayout.paragraphGap,
    };
  }
}
