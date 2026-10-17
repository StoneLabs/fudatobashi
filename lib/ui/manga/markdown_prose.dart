import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import 'markdown_blocks.dart';
import 'marker_heading.dart';

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

/// Prose: a `# Title` heading is the page's [MarkerHeading] in the accent
/// colour (write `# Title | Sub` to add a sub in the other language), the
/// deeper ones display type, then bold.
class ProseBlocks extends MarkdownBlocks {
  const ProseBlocks({super.accent});

  @override
  Widget heading(md.Element e, int level) {
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
    final (title, sub) = MarkdownBlocks.splitHeading(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: MarkdownLayout.markerGap),
      child: MarkerHeading(title, sub, color: accent),
    );
  }

  @override
  double gapBefore(md.Node node, md.Node previous) {
    if (previous is md.Element && previous.tag == 'h1') return 0;
    return switch (node) {
      md.Element(tag: 'h1') => MarkdownLayout.h1Gap,
      md.Element(tag: 'h2') => MarkdownLayout.h2Gap,
      md.Element(tag: 'h3' || 'h4') => MarkdownLayout.h3Gap,
      _ => MarkdownLayout.blockGap,
    };
  }
}
