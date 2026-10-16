import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/design.dart';
import '../../config/links.dart';
import '../../config/vector_art.dart';
import '../../data/karuta_rules.dart';
import '../../l10n/rules_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../settings/settings_rows.dart';

/// "Full karuta rules", from Help: the All Japan Karuta Association's
/// competition rules, every chapter and article as it stands. Where they
/// come from and a link to the PDF on top; in English the app's
/// translation, with a switch to the Japanese original.
class KarutaRulesScreen extends StatefulWidget {
  const KarutaRulesScreen({super.key});

  @override
  State<KarutaRulesScreen> createState() => _KarutaRulesScreenState();
}

class _KarutaRulesScreenState extends State<KarutaRulesScreen> {
  final _loaded = Future.wait([KarutaRules.load(KarutaRules.original), KarutaRules.load(KarutaRules.translation)]);
  final _chapters = <String, GlobalKey>{};
  var _original = false;
  var _contentsOpen = false;

  void _jump(String chapter) {
    final target = _chapters[chapter]?.currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: KarutaRulesLayout.jump, curve: Motion.routeCurve);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pdf = Uri.parse(Links.karutaRules);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HeaderStyle.topGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: MangaHeader(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ScreenTitle(s.rulesTitle, sub: s.other.rulesTitle),
                ),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
            ),
            const SizedBox(height: Gaps.section),
            Expanded(
              child: FutureBuilder(
                future: _loaded,
                builder: (context, snapshot) {
                  final loaded = snapshot.data;
                  if (loaded == null) return const SizedBox.shrink();
                  final rules = s.ja || _original ? loaded.first : loaded.last;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        Gaps.gutter, Gaps.tight, Gaps.gutter, KarutaRulesLayout.bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s.rulesSource, style: _sourceStyle),
                        const SizedBox(height: KarutaRulesLayout.blockGap),
                        SettingsGroup(children: [
                          SettingsTapRow(
                            title: s.rulesOpenPdf,
                            note: '${pdf.host}${pdf.path}',
                            opensPage: true,
                            onTap: () => launchUrl(pdf, mode: LaunchMode.externalApplication),
                          ),
                        ]),
                        const SizedBox(height: KarutaRulesLayout.blockGap),
                        MangaPanel(
                          color: Palette.sunSoft,
                          border: Strokes.label,
                          padding: NarrationStyle.padding,
                          child: Text(s.rulesDisclaimer, style: _sourceStyle.copyWith(fontWeight: Weights.black)),
                        ),
                        if (!s.ja) ...[
                          const SizedBox(height: KarutaRulesLayout.blockGap),
                          SettingsGroup(children: [
                            SettingsSwitch(
                              title: s.rulesShowOriginal,
                              note: s.rulesShowOriginalNote,
                              value: _original,
                              onChanged: (on) => setState(() => _original = on),
                            ),
                          ]),
                        ],
                        const SizedBox(height: KarutaRulesLayout.blockGap),
                        SettingsGroup(children: [
                          SettingsTapRow(
                            title: s.rulesContents,
                            value: _contentsOpen ? s.rulesContentsHide : s.rulesContentsShow,
                            onTap: () => setState(() => _contentsOpen = !_contentsOpen),
                          ),
                          if (_contentsOpen)
                            for (final c in rules.chapters)
                              SettingsTapRow(title: '${c.number}  ${c.title}', opensPage: true, onTap: () => _jump(c.id)),
                        ]),
                        const SizedBox(height: KarutaRulesLayout.titleGap),
                        Text(rules.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: Fonts.display, fontSize: KarutaRulesLayout.titleFont)),
                        const SizedBox(height: KarutaRulesLayout.authorGap),
                        Text(rules.author,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaRulesLayout.authorFont)),
                        for (final c in rules.chapters) ...[
                          _ChapterBand(c, key: _chapters.putIfAbsent(c.id, GlobalKey.new)),
                          for (final (i, a) in c.articles.indexed) ...[
                            if (i > 0) const _Rule(),
                            _Article(a, notesLabel: rules.notesLabel),
                          ],
                        ],
                        _Closing(rules.closing),
                        const SizedBox(height: KarutaRulesLayout.footnoteGap),
                        Text(s.rulesDisclaimerShort,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: Weights.bold,
                                fontSize: KarutaRulesLayout.footnoteFont,
                                color: Palette.inkSoft)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _sourceStyle = TextStyle(
  fontSize: KarutaRulesLayout.sourceFont,
  fontWeight: Weights.bold,
  height: KarutaRulesLayout.sourceLineHeight,
);

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

/// A chapter's heading: an ink band with its number and title.
class _ChapterBand extends StatelessWidget {
  const _ChapterBand(this.chapter, {super.key});

  final RulesChapter chapter;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaRulesLayout.chapterGap),
        child: Semantics(
          header: true,
          child: ColoredBox(
            color: Palette.ink,
            child: Padding(
              padding: KarutaRulesLayout.bandPadding,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(chapter.number,
                    style: const TextStyle(
                        fontWeight: Weights.black,
                        fontSize: KarutaRulesLayout.chapterNumberFont,
                        letterSpacing: KarutaRulesLayout.chapterNumberFont * KarutaRulesLayout.chapterNumberTracking,
                        color: Palette.sun)),
                const SizedBox(width: KarutaRulesLayout.bandGap),
                Expanded(
                  child: Text(chapter.title,
                      style: const TextStyle(
                          fontWeight: Weights.black, fontSize: KarutaRulesLayout.chapterTitleFont, color: Palette.paper)),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// The thin rule between two articles.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: KarutaRulesLayout.ruleHeight, child: ColoredBox(color: KarutaRulesLayout.rule));
}

/// One article: its number tag and title, then its paragraphs, or its body
/// with its list and notes, all set in to the paragraphs' text column.
class _Article extends StatelessWidget {
  const _Article(this.article, {required this.notesLabel});

  final RulesArticle article;
  final String notesLabel;

  @override
  Widget build(BuildContext context) {
    final a = article;
    final indent = MediaQuery.textScalerOf(context).scale(KarutaRulesLayout.labelColumn);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KarutaRulesLayout.articlePad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          header: true,
          child: Row(children: [
            InkTag(a.number, fontSize: KarutaRulesLayout.articleTagFont),
            const SizedBox(width: KarutaRulesLayout.headingGap),
            Expanded(
              child: Text(a.title,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: KarutaRulesLayout.articleTitleFont)),
            ),
          ]),
        ),
        const SizedBox(height: KarutaRulesLayout.headingTextGap),
        if (a.body case final body?)
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(body, style: _bodyStyle),
              for (final entry in a.list)
                Padding(
                  padding: const EdgeInsets.only(top: KarutaRulesLayout.entryGap),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.label, style: _labelStyle),
                    const SizedBox(width: KarutaRulesLayout.listLabelGap),
                    Expanded(child: Text(entry.text, style: _bodyStyle)),
                  ]),
                ),
              if (a.notes.isNotEmpty) _Notes(a.notes, label: notesLabel),
            ]),
          ),
        for (final (i, item) in a.items.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : KarutaRulesLayout.entryGap),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: indent, child: Text(item.label, style: _labelStyle)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(item.text, style: _bodyStyle),
                  if (item.notice case final notice?) _Notice(notice),
                  if (item.notes.isNotEmpty) _Notes(item.notes, label: notesLabel),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// A group of supplementary notes under its pill, set in from a grey rule.
class _Notes extends StatelessWidget {
  const _Notes(this.notes, {required this.label});

  final List<RulesNote> notes;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaRulesLayout.notesGap),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: KarutaRulesLayout.rule, width: KarutaRulesLayout.notesRule)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: KarutaRulesLayout.notesIndent),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill(label),
              const SizedBox(height: KarutaRulesLayout.notesLabelGap),
              for (final (i, n) in notes.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : KarutaRulesLayout.noteGap),
                  child: n.kind == RulesNoteKind.notice ? _Notice(n.text) : _Note(n),
                ),
            ]),
          ),
        ),
      );
}

/// A ○ point or a ※ remark, its mark hanging, and the notice it ends with.
class _Note extends StatelessWidget {
  const _Note(this.note);

  final RulesNote note;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(note.kind == RulesNoteKind.remark ? KarutaRulesLayout.remarkMark : KarutaRulesLayout.pointMark,
            style: _noteStyle),
        const SizedBox(width: KarutaRulesLayout.markGap),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(note.text, style: _noteStyle),
            if (note.notice case final notice?) _Notice(notice),
          ]),
        ),
      ]);
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

/// When the rules came into force, and the ※ remarks on this edition.
class _Closing extends StatelessWidget {
  const _Closing(this.closing);

  final RulesClosing closing;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: Strokes.label, child: ColoredBox(color: Palette.ink)),
        const SizedBox(height: KarutaRulesLayout.closingGap),
        Text(closing.enacted, style: _labelStyle),
        for (final r in closing.remarks)
          Padding(
            padding: const EdgeInsets.only(top: KarutaRulesLayout.noteGap),
            child: _Note(RulesNote(kind: RulesNoteKind.remark, text: r)),
          ),
      ]);
}
