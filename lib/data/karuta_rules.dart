import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The All Japan Karuta Association's competition rules (競技規程細則), from
/// `assets/rules/`: the Japanese original word for word, and the app's own
/// English translation in exactly the same structure.
class KarutaRules {
  const KarutaRules({
    required this.title,
    required this.author,
    required this.notesLabel,
    required this.chapters,
    required this.closing,
  });

  final String title;
  final String author;

  /// What heads a group of supplementary notes (補足).
  final String notesLabel;
  final List<RulesChapter> chapters;
  final RulesClosing closing;

  /// The language codes of the original and of its translation.
  static const original = 'ja', translation = 'en';

  static String asset(String code) => 'assets/rules/kyogi_kitei_saisoku_$code.json';

  static KarutaRules fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    return KarutaRules(
      title: j['title'] as String,
      author: j['author'] as String,
      notesLabel: (j['labels'] as Map<String, dynamic>)['notes'] as String,
      chapters: [for (final c in j['chapters'] as List) RulesChapter.fromJson(c as Map<String, dynamic>)],
      closing: RulesClosing.fromJson(j['closing'] as Map<String, dynamic>),
    );
  }

  /// Decoded here rather than with `loadString`, which hands a file this
  /// size to another isolate.
  static Future<KarutaRules> load(String code) async {
    final data = await rootBundle.load(asset(code));
    return fromJsonString(utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
  }
}

/// A chapter (章) and its articles.
class RulesChapter {
  const RulesChapter({required this.id, required this.number, required this.title, required this.articles});

  final String id;
  final String number;
  final String title;
  final List<RulesArticle> articles;

  factory RulesChapter.fromJson(Map<String, dynamic> j) => RulesChapter(
        id: j['id'] as String,
        number: j['number'] as String,
        title: j['title'] as String,
        articles: [for (final a in j['articles'] as List) RulesArticle.fromJson(a as Map<String, dynamic>)],
      );
}

/// An article (条): either numbered paragraphs (項, [items]), or one
/// [body] with an optional numbered [list] (号) and its [notes].
class RulesArticle {
  const RulesArticle({
    required this.id,
    required this.number,
    required this.title,
    this.body,
    this.list = const [],
    this.notes = const [],
    this.items = const [],
  });

  final String id;
  final String number;
  final String title;
  final String? body;
  final List<RulesEntry> list;
  final List<RulesNote> notes;
  final List<RulesEntry> items;

  factory RulesArticle.fromJson(Map<String, dynamic> j) => RulesArticle(
        id: j['id'] as String,
        number: j['number'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        list: RulesEntry.listFromJson(j['list']),
        notes: RulesNote.listFromJson(j['notes']),
        items: RulesEntry.listFromJson(j['items']),
      );
}

/// A numbered paragraph or list entry: its [label] (一, （1）…), its text,
/// the dated [notice] it ends with and the supplementary notes under it.
class RulesEntry {
  const RulesEntry({required this.id, required this.label, required this.text, this.notice, this.notes = const []});

  final String id;
  final String label;
  final String text;
  final String? notice;
  final List<RulesNote> notes;

  factory RulesEntry.fromJson(Map<String, dynamic> j) => RulesEntry(
        id: j['id'] as String,
        label: j['label'] as String,
        text: j['text'] as String,
        notice: j['notice'] as String?,
        notes: RulesNote.listFromJson(j['notes']),
      );

  static List<RulesEntry> listFromJson(Object? j) =>
      [for (final e in (j as List?) ?? const []) RulesEntry.fromJson(e as Map<String, dynamic>)];
}

/// How a supplementary note is marked: ○ a point, ※ a remark, or a dated
/// notice (通達) on a line of its own.
enum RulesNoteKind { point, remark, notice }

class RulesNote {
  const RulesNote({required this.kind, required this.text, this.notice});

  final RulesNoteKind kind;
  final String text;
  final String? notice;

  factory RulesNote.fromJson(Map<String, dynamic> j) => RulesNote(
        kind: RulesNoteKind.values.byName(j['kind'] as String),
        text: j['text'] as String,
        notice: j['notice'] as String?,
      );

  static List<RulesNote> listFromJson(Object? j) =>
      [for (final e in (j as List?) ?? const []) RulesNote.fromJson(e as Map<String, dynamic>)];
}

/// The lines after the last article: when the rules came into force, and
/// the ※ remarks on this edition.
class RulesClosing {
  const RulesClosing({required this.enacted, required this.remarks});

  final String enacted;
  final List<String> remarks;

  factory RulesClosing.fromJson(Map<String, dynamic> j) =>
      RulesClosing(enacted: j['enacted'] as String, remarks: [for (final r in j['remarks'] as List) r as String]);
}
