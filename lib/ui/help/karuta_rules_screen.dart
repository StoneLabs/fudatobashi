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
import 'rules_blocks.dart';

/// "Full karuta rules", from Help: the All Japan Karuta Association's
/// competition rules, every chapter and article as it stands. Where they
/// come from and a link to the PDF on top; the rules in the app's language.
class KarutaRulesScreen extends StatefulWidget {
  const KarutaRulesScreen({super.key});

  @override
  State<KarutaRulesScreen> createState() => _KarutaRulesScreenState();
}

class _KarutaRulesScreenState extends State<KarutaRulesScreen> {
  Future<KarutaRules>? _loaded;
  final _chapterKeys = <GlobalKey>[];
  var _contentsOpen = false;

  GlobalKey _chapterKey(int index) {
    while (_chapterKeys.length <= index) {
      _chapterKeys.add(GlobalKey());
    }
    return _chapterKeys[index];
  }

  void _jump(int chapter) {
    final target = _chapterKey(chapter).currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: KarutaRulesLayout.jump, curve: Motion.routeCurve);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    _loaded ??= KarutaRules.load(s.ja ? KarutaRules.original : KarutaRules.translation);
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
                  final rules = snapshot.data;
                  if (rules == null) return const SizedBox.shrink();
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
                        const SizedBox(height: KarutaRulesLayout.startRuleGapAbove),
                        const SizedBox(
                          key: startRuleKey,
                          height: KarutaRulesLayout.startRuleHeight,
                          child: ColoredBox(color: KarutaRulesLayout.startRule),
                        ),
                        const SizedBox(height: KarutaRulesLayout.startRuleGapBelow),
                        SettingsGroup(children: [
                          SettingsTapRow(
                            title: s.rulesContents,
                            value: _contentsOpen ? s.rulesContentsHide : s.rulesContentsShow,
                            onTap: () => setState(() => _contentsOpen = !_contentsOpen),
                          ),
                          if (_contentsOpen)
                            for (final (i, c) in rules.chapters.indexed)
                              SettingsTapRow(title: '${c.number}  ${c.title}', opensPage: true, onTap: () => _jump(i)),
                        ]),
                        const SizedBox(height: KarutaRulesLayout.titleGap),
                        Text(s.rulesDocTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: Fonts.display, fontSize: KarutaRulesLayout.titleFont)),
                        const SizedBox(height: KarutaRulesLayout.authorGap),
                        Text(s.rulesDocAuthor,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaRulesLayout.authorFont)),
                        MarkdownProse(rules.body, blocks: RulesBlocks(chapterKey: _chapterKey)),
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

/// The line above the contents.
const startRuleKey = ValueKey('rules-start-rule');

const _sourceStyle = TextStyle(
  fontSize: KarutaRulesLayout.sourceFont,
  fontWeight: Weights.bold,
  height: KarutaRulesLayout.sourceLineHeight,
);
