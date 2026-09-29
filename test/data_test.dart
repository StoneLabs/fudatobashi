import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/joka.dart';
import 'package:fudatobashi/data/poem.dart';

void main() {
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final sets = FudaSets(p);

  test('100 poems with torifuda split 5 / 5 / rest', () {
    expect(p.all.length, 100);
    for (final poem in p.all) {
      expect(poem.columns.join(), poem.torifuda, reason: '#${poem.id}');
      expect(poem.columns[0].length, 5);
      expect(poem.columns[1].length, 5);
      expect(poem.columns[2].length, inInclusiveRange(4, 6));
    }
  });

  test('kimariji are unique', () {
    expect(p.all.map((x) => x.kimariji).toSet().length, 100);
  });

  test('initial-kana groups have the classic sizes and cover all 100', () {
    final sizes = {
      for (final s in sets.ofKind(FudaSetKind.initial)) s.label: s.poemIds.length,
    };
    expect(sizes, {
      'むすめふさほせ': 7, 'うつしもゆ': 10, 'いちひき': 12, 'はやよか': 16, 'み': 5,
      'た': 6, 'こ': 6, 'お': 7, 'わ': 7, 'な': 8, 'あ': 16,
    });
    expect(sets.ofKind(FudaSetKind.initial).expand((s) => s.poemIds).toSet().length, 100);
  });

  test('confusable sets really share a torifuda start', () {
    for (final s in sets.ofKind(FudaSetKind.confusable)) {
      final starts = s.poemIds.map((id) => p[id].torifuda.substring(0, 2)).toSet();
      expect(starts.length, 1, reason: '${s.label}: $starts');
    }
  });

  test('kimariji-length sets have the standard 7/42/37/6/2/6 distribution', () {
    expect([for (var n = 1; n <= 6; n++) sets['len:$n'].poemIds.length], [7, 42, 37, 6, 2, 6]);
  });

  test('a card\'s kimariji twin shares every kana but the last', () {
    expect(p.kimarijiTwin(p.byKimariji('きみがためは'))?.kimariji, 'きみがためお');
    expect(p.kimarijiTwin(p.byKimariji('あきの'))?.kimariji, 'あきか');
    expect(p.kimarijiTwin(p.byKimariji('む')), isNull);
  });

  test('the start card font keeps every character of its lettering', () {
    final script = File('scripts/joka_font.sh').readAsStringSync();
    final kept = RegExp(r"TEXT='([^']*)'").firstMatch(script)!.group(1)!;
    final lettering = [...jokaPhrases, jokaTitle, jokaGreeting].join();
    expect(lettering.split('').where((c) => !kept.contains(c)), isEmpty, reason: 'rerun scripts/joka_font.sh');
  });
}
