import '../l10n/articles.dart';

/// The All Japan Karuta Association's competition rules (競技規程細則), the
/// `rules` article (see `Articles`): the Japanese original word for word,
/// and the app's own English translation in exactly the same structure.
///
/// Each chapter is a `# Number | Title` heading and each article a
/// `## Number | Title` one. A paragraph starting with a bold label
/// (`**1** …`, `**（1）** …`) is a numbered paragraph or list entry. A
/// blockquote is a group of supplementary notes: its bold first line is the
/// label, each `○` or `※` paragraph a note, a paragraph in italics a dated
/// notice (a hard line break puts one under its note). The rules end with a
/// `---` rule, when they came into force and the `※` remarks.
class KarutaRules {
  const KarutaRules({required this.body, required this.chapters});

  /// The Markdown of the rules.
  final String body;
  final List<RulesChapter> chapters;

  /// The language codes of the original and of its translation.
  static const original = 'ja', translation = 'en';

  static String asset(String code) => Articles.asset(code, Articles.rules);

  static final _chapter = RegExp(r'^# (.+) \| (.+)$', multiLine: true);

  static KarutaRules parse(String source) {
    return KarutaRules(
      body: source,
      chapters: [for (final m in _chapter.allMatches(source)) RulesChapter(number: m[1]!, title: m[2]!)],
    );
  }

  static Future<KarutaRules> load(String code) async => parse(await Articles.load(code, Articles.rules));
}

/// A chapter (章), as the contents list it.
class RulesChapter {
  const RulesChapter({required this.number, required this.title});

  final String number;
  final String title;
}
