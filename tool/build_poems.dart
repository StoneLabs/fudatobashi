// Generates assets/data/poems.json from StoneLabs' hyakuninissyu-csv
// (https://github.com/StoneLabs/hyakuninissyu-csv, public domain), and
// assets/data/joka.json from its 序歌 row: the opening poem, which has a
// reading card but no taking card, kimariji or colour, so it is kept out of
// the hundred.
//
//   dart run tool/build_poems.dart            # fetch data.csv from GitHub
//   dart run tool/build_poems.dart --csv FILE # use a local copy
//
// The script validates the data (torifuda text and column split, reading-card
// columns, kimariji uniqueness, standard distributions) and refuses to write
// on any failure.
import 'dart:convert';
import 'dart:io';

import 'package:fudatobashi/l10n/romaji.dart';

const csvUrl = 'https://raw.githubusercontent.com/StoneLabs/hyakuninissyu-csv/master/data.csv';
const outPath = 'assets/data/poems.json';
const jokaPath = 'assets/data/joka.json';

/// The CSV's number for the 序歌's row.
const jokaNumber = '序歌';

Future<void> main(List<String> args) async {
  final i = args.indexOf('--csv');
  final text = i >= 0 ? await File(args[i + 1]).readAsString() : await _fetch(csvUrl);
  final rows = _parseCsv(text);
  final header = rows.first;
  final records = [
    for (final r in rows.skip(1))
      if (r.length == header.length) {for (var c = 0; c < header.length; c++) header[c]: r[c]},
  ];

  final poems = [
    for (final r in records)
      if (r['number'] != jokaNumber) _poem(r),
  ]..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  final joka = _joka(records.singleWhere((r) => r['number'] == jokaNumber));

  final errors = [..._validate(poems), ..._validateVerses(jokaNumber, joka)];
  if (errors.isNotEmpty) {
    stderr.writeln('Validation failed:\n  ${errors.join('\n  ')}');
    exit(1);
  }
  const json = JsonEncoder.withIndent('  ');
  await File(outPath).writeAsString('${json.convert(poems)}\n');
  await File(jokaPath).writeAsString('${json.convert(joka)}\n');
  stdout.writeln('Wrote ${poems.length} poems to $outPath and the $jokaNumber to $jokaPath');
}

/// A poem's or the 序歌's poet and verses, as `Waka.fromJson` reads them
/// (its reading card's columns are [_yomifudaColumns]).
Map<String, Object> _verses(Map<String, String> r) {
  String join(List<String> keys, [String sep = '　']) => keys.map((k) => r[k]!).join(sep);
  var kamiReading = join(['verse_1_hiragana_yomi', 'verse_2_hiragana_yomi', 'verse_3_hiragana_yomi'], '');
  // #44 逢ふことの: karuta convention writes this long vowel おお (like 大江山
  // おおえ and おほけなく おおけ); the CSV's kimariji is "おおこ", so the reading
  // is spelled the same way to keep the kimariji a prefix of it.
  if (r['number'] == '44' && kamiReading.startsWith('おう')) kamiReading = 'おお${kamiReading.substring(2)}';
  final versesYomi = _versesYomi(r);
  final authorRomaji = hepburn(r['author_hiragana']!);
  return {
    'author': r['author_kanji']!,
    'authorKana': r['author_hiragana']!,
    'authorRomaji': '${authorRomaji[0].toUpperCase()}${authorRomaji.substring(1)}',
    'kami': join(['verse_1_kanji', 'verse_2_kanji', 'verse_3_kanji']),
    'shimo': join(['verse_4_kanji', 'verse_5_kanji']),
    'kamiRuby': join(['verse_1', 'verse_2', 'verse_3']),
    'shimoRuby': join(['verse_4', 'verse_5']),
    'kamiKana': join(['verse_1_hiragana', 'verse_2_hiragana', 'verse_3_hiragana']),
    'shimoKana': join(['verse_4_hiragana', 'verse_5_hiragana']),
    'kamiReading': kamiReading,
    'shimoReading': versesYomi.skip(3).join(),
    'versesRomaji': [for (final v in versesYomi) hepburn(v)],
  };
}

Map<String, Object> _poem(Map<String, String> r) {
  final verses = _verses(r);
  final kimarijiReading = r['kimariji_kami_yomi']!;
  return {
    'id': int.parse(r['number']!),
    ...verses,
    'torifuda': _stripDakuten((verses['shimoKana'] as String).replaceAll('　', '')),
    'torifudaColumns': [r['torifuda_1']!, r['torifuda_2']!, r['torifuda_3']!],
    'kimariji': _conventionalKimariji(kimarijiReading, (verses['kamiKana'] as String).replaceAll('　', '')),
    'kimarijiReading': kimarijiReading,
    'kimarijiShimo': r['kimariji_shimo']!,
    'color': r['color']!,
    'colorNumber': int.parse(r['color_num']!),
    'yomifudaColumns': _yomifudaColumns(r),
  };
}

/// The 序歌's poet, verses and reading card; the card's title is the CSV's
/// number for the row (序歌).
Map<String, Object> _joka(Map<String, String> r) =>
    {..._verses(r), 'yomifudaTitle': r['number']!, 'yomifudaColumns': _yomifudaColumns(r)};

/// The five verses as pronounced (modern kana).
List<String> _versesYomi(Map<String, String> r) => [for (var v = 1; v <= 5; v++) r['verse_${v}_hiragana_yomi']!];

/// The reading card's four columns, split from its competition reading:
/// verses 1–2, 3, 4 and 5.
List<String> _yomifudaColumns(Map<String, String> r) {
  final versesYomi = _versesYomi(r);
  return [
    ..._splitReading(r['kyougi_yomi_kami']!, versesYomi[0].length + versesYomi[1].length, r['number']!),
    ..._splitReading(r['kyougi_yomi_shimo']!, versesYomi[3].length, r['number']!),
  ];
}

/// Furigana markup (`[漢字|かな]`), one character, or a stretch mark.
final _rubyToken = RegExp(r'\[([^|\]]+)\|([^\]]+)\]|.');
const _stretchMarks = 'ーｰ';

/// Splits a reading card's half ([kyougi] markup) into its two columns after
/// the first [at] kana of reading, keeping the stretch marks that follow them
/// in the first column, as the printed cards do.
List<String> _splitReading(String kyougi, int at, String number) {
  var read = 0;
  for (final m in _rubyToken.allMatches(kyougi)) {
    if (read == at && !_stretchMarks.contains(m[0]!)) {
      return [kyougi.substring(0, m.start), kyougi.substring(m.start)];
    }
    if (!_stretchMarks.contains(m[0]!)) read += (m[2] ?? m[0]!).length;
    if (read > at) break;
  }
  throw FormatException('#$number: no column break after $at kana of reading in $kyougi');
}

List<String> _validate(List<Map<String, Object>> poems) {
  final errors = <String>[];
  if (poems.length != 100) errors.add('expected 100 poems, got ${poems.length}');
  for (var k = 0; k < poems.length; k++) {
    final p = poems[k];
    final id = p['id'] as int;
    if (id != k + 1) errors.add('id sequence broken at $id');
    final tori = p['torifuda'] as String;
    final cols = (p['torifudaColumns'] as List).cast<String>();
    if (cols.join() != tori) errors.add('#$id torifuda columns ${cols.join('/')} != $tori');
    if (cols[0].length != 5 || cols[1].length != 5 || cols[2].length > 6) {
      errors.add('#$id unexpected column split ${cols.join('/')}');
    }
    if (!RegExp(r'^[ぁ-ゖ]+$').hasMatch(tori) || _stripDakuten(tori) != tori) {
      errors.add('#$id torifuda must be plain hiragana without dakuten: $tori');
    }
    errors.addAll(_validateVerses('$id', p));
  }
  final readings = [for (final p in poems) p['kamiReading'] as String];
  for (final p in poems) {
    final r = p['kamiReading'] as String;
    var n = 1;
    while (readings.where((o) => o != r && o.startsWith(r.substring(0, n))).isNotEmpty) {
      n++;
    }
    if (r.substring(0, n) != p['kimarijiReading']) {
      errors.add('#${p['id']} kimariji ${p['kimarijiReading']} != shortest unique prefix ${r.substring(0, n)}');
    }
  }
  final byLength = <int, int>{};
  for (final p in poems) {
    final l = (p['kimariji'] as String).length;
    byLength[l] = (byLength[l] ?? 0) + 1;
  }
  const expected = {1: 7, 2: 42, 3: 37, 4: 6, 5: 2, 6: 6};
  if (expected.entries.any((e) => byLength[e.key] != e.value)) {
    errors.add('kimariji length distribution $byLength != $expected');
  }
  return errors;
}

/// What [_verses] made of row [number]: five verses, and romaji with no
/// kana left over.
List<String> _validateVerses(String number, Map<String, Object> w) {
  final errors = <String>[];
  final verses = '${w['kamiRuby']}　${w['shimoRuby']}'.split('　');
  if (verses.length != 5) errors.add('#$number verses must not contain a full-width space: $verses');
  for (final romaji in [w['authorRomaji'] as String, ...(w['versesRomaji'] as List).cast<String>()]) {
    if (!RegExp(r'^[A-Za-z]+$').hasMatch(romaji)) errors.add('#$number romaji has a kana left over: $romaji');
  }
  return errors;
}

/// The CSV's kimariji are pure pronunciation (ひとわ). Karuta players write the
/// topic particle は as は (ひとは, いまは, よのなかは), like the original app.
String _conventionalKimariji(String reading, String kamiKana) {
  final last = reading.length - 1;
  if (reading.endsWith('わ') && kamiKana.length > last && kamiKana[last] == 'は') {
    return '${reading.substring(0, last)}は';
  }
  return reading;
}

String _stripDakuten(String s) {
  const voiced = 'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽゔ';
  const plain = 'かきくけこさしすせそたちつてとはひふへほはひふへほう';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final k = voiced.indexOf(ch);
    b.write(k >= 0 ? plain[k] : ch);
  }
  return b.toString();
}

Future<String> _fetch(String url) async {
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    if (res.statusCode != 200) throw HttpException('GET $url → ${res.statusCode}');
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

/// Minimal RFC 4180 parser (quoted fields, escaped quotes, CRLF).
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var k = 0; k < text.length; k++) {
    final ch = text[k];
    if (quoted) {
      if (ch == '"') {
        if (k + 1 < text.length && text[k + 1] == '"') {
          field.write('"');
          k++;
        } else {
          quoted = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && k + 1 < text.length && text[k + 1] == '\n') k++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
