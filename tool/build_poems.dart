// Generates assets/data/poems.json from StoneLabs' hyakuninissyu-csv
// (https://github.com/StoneLabs/hyakuninissyu-csv, public domain).
//
//   dart run tool/build_poems.dart            # fetch data.csv from GitHub
//   dart run tool/build_poems.dart --csv FILE # use a local copy
//
// The script validates the data (torifuda text and column split, kimariji
// uniqueness, standard distributions) and refuses to write on any failure.
import 'dart:convert';
import 'dart:io';

const csvUrl = 'https://raw.githubusercontent.com/StoneLabs/hyakuninissyu-csv/master/data.csv';
const outPath = 'assets/data/poems.json';

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
      if (r['number'] != '序歌') _poem(r),
  ]..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

  final errors = _validate(poems);
  if (errors.isNotEmpty) {
    stderr.writeln('Validation failed:\n  ${errors.join('\n  ')}');
    exit(1);
  }
  await File(outPath).writeAsString('${const JsonEncoder.withIndent('  ').convert(poems)}\n');
  stdout.writeln('Wrote ${poems.length} poems to $outPath');
}

Map<String, Object> _poem(Map<String, String> r) {
  final id = int.parse(r['number']!);
  String join(List<String> keys, [String sep = '　']) => keys.map((k) => r[k]!).join(sep);
  var kamiReading = join(['verse_1_hiragana_yomi', 'verse_2_hiragana_yomi', 'verse_3_hiragana_yomi'], '');
  // #44 逢ふことの: karuta convention writes this long vowel おお (like 大江山
  // おおえ and おほけなく おおけ); the CSV's kimariji is "おおこ", so the reading
  // is spelled the same way to keep the kimariji a prefix of it.
  if (id == 44 && kamiReading.startsWith('おう')) kamiReading = 'おお${kamiReading.substring(2)}';
  final shimoKana = join(['verse_4_hiragana', 'verse_5_hiragana']);
  final kamiKana = join(['verse_1_hiragana', 'verse_2_hiragana', 'verse_3_hiragana']);
  final kimarijiReading = r['kimariji_kami_yomi']!;
  return {
    'id': id,
    'author': r['author_kanji']!,
    'authorKana': r['author_hiragana']!,
    'kami': join(['verse_1_kanji', 'verse_2_kanji', 'verse_3_kanji']),
    'shimo': join(['verse_4_kanji', 'verse_5_kanji']),
    'kamiRuby': join(['verse_1', 'verse_2', 'verse_3']),
    'shimoRuby': join(['verse_4', 'verse_5']),
    'kamiKana': kamiKana,
    'shimoKana': shimoKana,
    'kamiReading': kamiReading,
    'torifuda': _stripDakuten(shimoKana.replaceAll('　', '')),
    'torifudaColumns': [r['torifuda_1']!, r['torifuda_2']!, r['torifuda_3']!],
    'kimariji': _conventionalKimariji(kimarijiReading, kamiKana.replaceAll('　', '')),
    'kimarijiReading': kimarijiReading,
    'color': r['color']!,
  };
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
