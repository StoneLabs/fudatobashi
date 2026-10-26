import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A waka (和歌) as the reader reads it in a match: its poet, its five verses
/// and its reading card. Each of the 100 poems is a [Poem]; the 序歌 read
/// before them (`joka`) is a waka alone, with no taking card.
///
/// Generated into assets/data/poems.json and assets/data/joka.json by
/// tool/build_poems.dart from StoneLabs' hyakuninissyu-csv.
class Waka {
  Waka.fromJson(Map<String, dynamic> j)
      : author = j['author'] as String,
        authorKana = j['authorKana'] as String,
        authorRomaji = j['authorRomaji'] as String,
        kami = j['kami'] as String,
        shimo = j['shimo'] as String,
        kamiKana = j['kamiKana'] as String,
        shimoKana = j['shimoKana'] as String,
        kamiReading = j['kamiReading'] as String,
        shimoReading = j['shimoReading'] as String,
        versesRomaji = (j['versesRomaji'] as List).cast<String>(),
        kamiRuby = j['kamiRuby'] as String,
        shimoRuby = j['shimoRuby'] as String,
        yomifudaColumns = (j['yomifudaColumns'] as List).cast<String>();

  /// The card's number, printed on its reading card; null for a waka that
  /// isn't one of the 100.
  int? get id => null;

  final String author;
  final String authorKana;

  /// The poet's name in plain Hepburn romaji, as one word ("Tenjitennou").
  final String authorRomaji;

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

  /// Lower verse as pronounced (modern kana).
  final String shimoReading;

  /// Each of the five verses in plain Hepburn romaji of how it is
  /// pronounced, without word breaks ("akinotano").
  final List<String> versesRomaji;

  /// Verses with furigana markup: "[秋|あき]の[田|た]の　…".
  final String kamiRuby;
  final String shimoRuby;

  /// The poet's name with its reading, in the same markup.
  String get authorRuby => '[$author|$authorKana]';

  /// The five verses in furigana markup, upper verse first.
  List<String> get versesRuby => [...kamiRuby.split('　'), ...shimoRuby.split('　')];

  /// The yomifuda's text as read in competitive karuta (競技読み), in four
  /// columns right to left: verses 1–2, 3, 4 and 5. Furigana markup, plus
  /// ー for a long and ｰ for a short held sound; a reading over kana
  /// (`[は|わ]`) says how to read it.
  final List<String> yomifudaColumns;

  /// The kimariji as pronounced, printed red on the reading card; null for
  /// a waka no taking card answers.
  String? get kimarijiReading => null;

  static Waka fromJsonString(String s) => Waka.fromJson(jsonDecode(s) as Map<String, dynamic>);

  static Future<Waka> load(String asset) async => fromJsonString(await rootBundle.loadString(asset));
}

/// One of the 100 poems of the Ogura Hyakunin Isshu: a waka with its taking
/// card, its kimariji and its 五色 colour group.
class Poem extends Waka {
  Poem.fromJson(super.j)
      : id = j['id'] as int,
        torifuda = j['torifuda'] as String,
        columns = (j['torifudaColumns'] as List).cast<String>(),
        kimariji = j['kimariji'] as String,
        kimarijiReading = j['kimarijiReading'] as String,
        kimarijiShimo = j['kimarijiShimo'] as String,
        color = j['color'] as String,
        colorNumber = j['colorNumber'] as int,
        super.fromJson();

  @override
  final int id;

  /// Text printed on the torifuda: lower verse, historical kana, no dakuten.
  final String torifuda;

  /// The torifuda text as printed in three columns, right to left: 5 / 5 / rest.
  final List<String> columns;

  /// Static kimariji (決まり字) in modern kana.
  final String kimariji;

  /// [kimariji] as pronounced: the start of [kamiReading] only this poem
  /// has (ひとわ for ひとは).
  @override
  final String kimarijiReading;

  /// The kimariji of the lower verse: the start of the torifuda that tells
  /// it apart from every other torifuda.
  final String kimarijiShimo;

  /// 五色百人一首 colour group (桃, 青, 黄, 緑, 橙).
  final String color;

  /// This card's place, 1–20, in its [color] group.
  final int colorNumber;

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

  /// [p]'s kimariji while only [left] are still to be read: the fewest
  /// first sounds no other poem of [left] starts with, as [Poem.kimariji]
  /// writes them. With all 100 left it is [Poem.kimariji] itself.
  String kimarijiAmong(Poem p, Iterable<Poem> left) {
    final reading = p.kamiReading;
    var n = 1;
    while (n < reading.length &&
        left.any((q) => q.id != p.id && q.kamiReading.startsWith(reading.substring(0, n)))) {
      n++;
    }
    return p.kimariji.length >= n ? p.kimariji.substring(0, n) : reading.substring(0, n);
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
