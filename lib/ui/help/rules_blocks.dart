import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import '../../config/design.dart';
import '../manga/manga.dart';

const _bodyStyle = TextStyle(
  fontSize: KarutaRulesLayout.bodyFont,
  fontWeight: Weights.medium,
  height: KarutaRulesLayout.bodyLineHeight,
  color: Palette.inkBody,
);

const _labelStyle = TextStyle(
  fontSize: KarutaRulesLayout.bodyFont,
  fontWeight: Weights.bold,
  height: KarutaRulesLayout.bodyLineHeight,
);

const _noteStyle = TextStyle(
  fontSize: KarutaRulesLayout.noteFont,
  fontWeight: Weights.medium,
  height: KarutaRulesLayout.noteLineHeight,
  color: Palette.inkSoft,
);

const _noticeStyle = TextStyle(
  fontSize: KarutaRulesLayout.noticeFont,
  fontWeight: Weights.bold,
  height: KarutaRulesLayout.noteLineHeight,
  color: Palette.mute,
);

/// The karuta rules' Markdown (see `KarutaRules` for its format): a `#`
/// heading is a chapter's band, a `##` one an article's number tag and
/// title, with its paragraphs and notes set in to the text column, and
/// everything after the `---` rule the closing lines. [chapterKey] gives
/// the key the contents list jumps to for the chapter at an index.
class RulesBlocks extends MarkdownBlocks {
  const RulesBlocks({required this.chapterKey});

  final GlobalKey Function(int index) chapterKey;

  @override
  List<Widget> layout(List<md.Node> nodes) {
    final blocks = nodes.whereType<md.Element>().toList();
    final out = <Widget>[];
    var chapter = 0, firstInChapter = true;
    for (var i = 0; i < blocks.length; i++) {
      final e = blocks[i];
      switch (e.tag) {
        case 'h1':
          out.add(KeyedSubtree(key: chapterKey(chapter++), child: heading(e, 1)));
          firstInChapter = true;
        case 'h2':
          final end = blocks.indexWhere((b) => const {'h1', 'h2', 'hr'}.contains(b.tag), i + 1);
          final body = blocks.sublist(i + 1, end < 0 ? blocks.length : end);
          if (!firstInChapter) out.add(const _Rule());
          firstInChapter = false;
          out.add(_article(e, body));
          i += body.length;
        case 'hr':
          out.add(_closing(blocks.sublist(i + 1)));
          return out;
      }
    }
    return out;
  }

  @override
  Widget heading(md.Element e, int level) {
    final (title, sub) = MarkdownBlocks.splitHeading(e);
    if (level == 2) return _articleHeading(title, sub ?? '');
    return _chapterBand(title, sub ?? '');
  }

  Widget _chapterBand(String number, String title) => Padding(
        padding: const EdgeInsets.only(top: KarutaRulesLayout.chapterGap),
        child: Semantics(
          header: true,
          child: ColoredBox(
            color: Palette.ink,
            child: Padding(
              padding: KarutaRulesLayout.bandPadding,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(number,
                    style: const TextStyle(
                        fontWeight: Weights.black,
                        fontSize: KarutaRulesLayout.chapterNumberFont,
                        letterSpacing: KarutaRulesLayout.chapterNumberFont * KarutaRulesLayout.chapterNumberTracking,
                        color: Palette.sun)),
                const SizedBox(width: KarutaRulesLayout.bandGap),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: Weights.black, fontSize: KarutaRulesLayout.chapterTitleFont, color: Palette.paper)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _articleHeading(String number, String title) => Semantics(
        header: true,
        child: Row(children: [
          InkTag(number, fontSize: KarutaRulesLayout.articleTagFont),
          const SizedBox(width: KarutaRulesLayout.headingGap),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: Weights.black, fontSize: KarutaRulesLayout.articleTitleFont)),
          ),
        ]),
      );

  /// An article: its heading, then either one body paragraph with its
  /// list entries and notes, or numbered paragraphs each with its own
  /// notes, all set in to the paragraphs' text column.
  Widget _article(md.Element head, List<md.Element> body) => Builder(builder: (context) {
        final indent = MediaQuery.textScalerOf(context).scale(KarutaRulesLayout.labelColumn);
        final hasBody = body.isNotEmpty && _labelled(body.first) == null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: KarutaRulesLayout.articlePad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            heading(head, 2),
            const SizedBox(height: KarutaRulesLayout.headingTextGap),
            if (hasBody)
              Padding(
                padding: EdgeInsets.only(left: indent),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(body.first.textContent, style: _bodyStyle),
                  for (final e in body.skip(1))
                    if (_labelled(e) case (final label, final text))
                      Padding(
                        padding: const EdgeInsets.only(top: KarutaRulesLayout.entryGap),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(label, style: _labelStyle),
                          const SizedBox(width: KarutaRulesLayout.listLabelGap),
                          Expanded(child: Text(text, style: _bodyStyle)),
                        ]),
                      )
                    else
                      _extra(e),
                ]),
              )
            else
              ..._paragraphs(body, indent),
          ]),
        );
      });

  List<Widget> _paragraphs(List<md.Element> body, double indent) {
    final out = <Widget>[];
    for (var i = 0; i < body.length;) {
      final (label, text) = _labelled(body[i++])!;
      final extras = <Widget>[];
      while (i < body.length && _labelled(body[i]) == null) {
        extras.add(_extra(body[i++]));
      }
      out.add(Padding(
        padding: EdgeInsets.only(top: out.isEmpty ? 0 : KarutaRulesLayout.entryGap),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: indent, child: Text(label, style: _labelStyle)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(text, style: _bodyStyle), ...extras]),
          ),
        ]),
      ));
    }
    return out;
  }

  /// What follows a paragraph: its dated notice or its notes.
  Widget _extra(md.Element e) => e.tag == 'blockquote' ? _notes(e) : _Notice(e.textContent);

  /// A paragraph in italics only, which is a dated notice.
  bool _isNotice(md.Element p) => switch (p.children) {
        [md.Element(tag: 'em')] => true,
        _ => false,
      };

  /// A numbered paragraph's label (a bold start: `**1** text`) and text.
  (String, String)? _labelled(md.Element e) {
    final children = e.children ?? const <md.Node>[];
    if (e.tag != 'p' || children.isEmpty) return null;
    return switch (children.first) {
      md.Element(tag: 'strong', :final textContent) => (textContent, children.skip(1).map((n) => n.textContent).join().trim()),
      _ => null,
    };
  }

  /// A group of supplementary notes under its label's pill, set in from a
  /// grey rule.
  Widget _notes(md.Element quote) {
    final paragraphs = (quote.children ?? const <md.Node>[]).whereType<md.Element>().toList();
    return Padding(
      padding: const EdgeInsets.only(top: KarutaRulesLayout.notesGap),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: KarutaRulesLayout.rule, width: KarutaRulesLayout.notesRule)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: KarutaRulesLayout.notesIndent),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill(paragraphs.first.textContent),
            const SizedBox(height: KarutaRulesLayout.notesLabelGap),
            for (final (i, p) in paragraphs.skip(1).indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : KarutaRulesLayout.noteGap),
                child: _isNotice(p) ? _Notice(p.textContent) : _note(p),
              ),
          ]),
        ),
      ),
    );
  }

  /// A ○ point or a ※ remark, its mark hanging, and the notice that a line
  /// break puts under it.
  Widget _note(md.Element p) {
    final children = p.children ?? const <md.Node>[];
    final notice = children.whereType<md.Element>().where((c) => c.tag == 'em').firstOrNull;
    final text = [for (final c in children) if (c != notice) c.textContent].join().trim();
    final mark = text.substring(0, 1);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(mark, style: _noteStyle),
      const SizedBox(width: KarutaRulesLayout.markGap),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(text.substring(1).trim(), style: _noteStyle),
          if (notice != null) _Notice(notice.textContent),
        ]),
      ),
    ]);
  }

  /// When the rules came into force, and the ※ remarks on this edition.
  Widget _closing(List<md.Element> lines) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: Strokes.label, child: ColoredBox(color: Palette.ink)),
        const SizedBox(height: KarutaRulesLayout.closingGap),
        Text(lines.first.textContent, style: _labelStyle),
        for (final remark in lines.skip(1))
          Padding(padding: const EdgeInsets.only(top: KarutaRulesLayout.noteGap), child: _note(remark)),
      ]);
}

/// The thin rule between two articles.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: KarutaRulesLayout.ruleHeight, child: ColoredBox(color: KarutaRulesLayout.rule));
}

/// A dated notice (通達), in small grey type.
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaRulesLayout.noticeGap),
        child: Text(text, style: _noticeStyle),
      );
}
