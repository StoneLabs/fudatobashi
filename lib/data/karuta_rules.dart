import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The All Japan Karuta Association's competition rules (競技規程細則), from
/// `assets/l10n/<code>_rules.md`: the Japanese original word for word, and
/// the app's own English translation in exactly the same structure.
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

  static String asset(String code) => 'assets/l10n/${code}_rules.md';

  static final _chapter = RegExp(r'^# (.+) \| (.+)$', multiLine: true);

  static KarutaRules parse(String source) {
    return KarutaRules(
      body: source,
      chapters: [for (final m in _chapter.allMatches(source)) RulesChapter(number: m[1]!, title: m[2]!)],
    );
  }

  /// Decoded here rather than with `loadString`, which hands a file this
  /// size to another isolate.
  static Future<KarutaRules> load(String code) async {
    final data = await rootBundle.load(asset(code));
    return parse(utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
  }
}

/// A chapter (章), as the contents list it.
class RulesChapter {
  const RulesChapter({required this.number, required this.title});

  final String number;
  final String title;
}
