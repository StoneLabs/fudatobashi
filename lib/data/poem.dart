import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One of the 100 poems of the Ogura Hyakunin Isshu.
///
/// Generated into assets/data/poems.json by tool/build_poems.dart from
/// StoneLabs' hyakuninissyu-csv.
class Poem {
  const Poem({
    required this.id,
    required this.author,
    required this.authorKana,
    required this.kami,
    required this.shimo,
    required this.kamiKana,
    required this.shimoKana,
    required this.kamiReading,
    required this.torifuda,
    required this.columns,
    required this.kimariji,
    required this.kamiRuby,
    required this.shimoRuby,
    required this.color,
  });

  final int id;
  final String author;
  final String authorKana;

  /// Upper verse in kanji-kana form, phrases separated by "　".
  final String kami;

  /// Lower verse in kanji-kana form, phrases separated by "　".
  final String shimo;

  /// Upper verse in historical kana (as printed on the yomifuda).
  final String kamiKana;

  /// Lower verse in historical kana.
  final String shimoKana;

  /// Upper verse as pronounced (modern kana), used for kimariji.
  final String kamiReading;

  /// Text printed on the torifuda: lower verse, historical kana, no dakuten.
  final String torifuda;

  /// The torifuda text as printed in three columns, right to left: 5 / 5 / rest.
  final List<String> columns;

  /// Static kimariji (決まり字) in modern kana.
  final String kimariji;

  /// Verses with furigana markup: "[秋|あき]の[田|た]の　…".
  final String kamiRuby;
  final String shimoRuby;

  /// The poet's name with its reading, in the same markup.
  String get authorRuby => '[$author|$authorKana]';

  /// 五色百人一首 colour group (桃, 青, 黄, 緑, 橙).
  final String color;

  factory Poem.fromJson(Map<String, dynamic> j) => Poem(
        id: j['id'] as int,
        author: j['author'] as String,
        authorKana: j['authorKana'] as String,
        kami: j['kami'] as String,
        shimo: j['shimo'] as String,
        kamiKana: j['kamiKana'] as String,
        shimoKana: j['shimoKana'] as String,
        kamiReading: j['kamiReading'] as String,
        torifuda: j['torifuda'] as String,
        columns: (j['torifudaColumns'] as List).cast<String>(),
        kimariji: j['kimariji'] as String,
        kamiRuby: j['kamiRuby'] as String,
        shimoRuby: j['shimoRuby'] as String,
        color: j['color'] as String,
      );

  @override
  String toString() => 'Poem($id $kimariji)';
}

/// The full, immutable set of 100 poems.
class Poems {
  Poems(this.all)
      : assert(all.length == 100),
        _byKimariji = {for (final p in all) p.kimariji: p};

  final List<Poem> all;
  final Map<String, Poem> _byKimariji;

  Poem operator [](int id) => all[id - 1];

  /// The card this one's last kimariji kana tells it apart from: the one
  /// sharing every kana before it (null for one-kana cards).
  Poem? kimarijiTwin(Poem p) {
    final prefix = p.kimariji.substring(0, p.kimariji.length - 1);
    if (prefix.isEmpty) return null;
    for (final q in all) {
      if (q.id != p.id && q.kimariji.startsWith(prefix)) return q;
    }
    return null;
  }

  Poem byKimariji(String k) {
    final p = _byKimariji[k];
    if (p == null) throw ArgumentError('Unknown kimariji: $k');
    return p;
  }

  static Poems fromJsonString(String s) => Poems([
        for (final e in jsonDecode(s) as List) Poem.fromJson(e as Map<String, dynamic>),
      ]);

  static Future<Poems> load() async =>
      fromJsonString(await rootBundle.loadString('assets/data/poems.json'));
}

/// Loaded once at startup in `main`.
late final Poems poems;
