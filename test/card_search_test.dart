import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/card_search.dart';
import 'package:fudatobashi/l10n/romaji.dart';

void main() {
  final poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final en = jsonDecode(File('assets/l10n/en.json').readAsStringSync()) as Map<String, dynamic>;
  String romajiOf(int id) => en['kimariji${id.toString().padLeft(3, '0')}'] as String;
  final search = CardSearch(poems.all, romajiOf: romajiOf);

  List<int> ids(String query) => [for (final m in search.find(query)) m.poem.id];

  test('an empty search lists every card, nothing marked', () {
    final all = search.find('  ');
    expect(all.length, 100);
    expect(all.every((m) => m.kind == CardMatchKind.all && m.marked == 0), isTrue);
  });

  test('a number matches from its start', () {
    expect(ids('2'), [2, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]);
    expect(ids('100'), [100]);
    expect(ids('２０'), [20], reason: 'full-width digits');
    expect(ids('101'), isEmpty);
    expect(ids('0'), isEmpty);
    final m = search.find('10').first;
    expect((m.kind, m.marked), (CardMatchKind.number, 2));
    expect(CardSearch.isNumber(CardSearch.normalize(' 12 ')), isTrue);
  });

  test('a kimariji in kana, katakana or as the start of the first half', () {
    expect(ids('わ'), [8, 11, 20, 38, 54, 76, 92]);
    expect(ids('ワビ'), [20]);
    expect(ids('あきのた'), [1], reason: 'past the kimariji, into the first half');
    expect(ids('あきのたのかりほ'), [1], reason: 'the first half as written');
    expect(ids('あきのたのかりお'), [1], reason: 'the first half as read');
    final m = search.find('あきのた').single;
    expect((m.kind, m.marked), (CardMatchKind.kana, 3), reason: 'the mark stops at the kimariji');
  });

  test('a kimariji in romaji, long vowels typed any way', () {
    expect(ids('wabi'), [20]);
    expect(ids('WA'), [8, 11, 20, 38, 54, 76, 92]);
    for (final typed in ['ōko', 'ooko', 'ouko', 'ōkotono', 'oukotono']) {
      expect(ids(typed), [44], reason: typed);
    }
    expect(ids('ook'), [5, 44, 95], reason: 'oku, ōko and ōkenaku');
    final m = search.find('ook').firstWhere((m) => m.poem.id == 44);
    expect((m.kind, m.marked), (CardMatchKind.romaji, 2), reason: '"ōk" of ōko');
    expect(search.find('akinotano').single.marked, romajiOf(1).length);
  });

  test('only when no first half matches, the start of the second half', () {
    expect(search.find('わが').map((e) => e.kind).toSet(), {CardMatchKind.kana}, reason: 'わがい, わがそ');
    expect(ids('わがころもで'), [1, 15]);
    final shimo = search.find('ころもほす');
    expect([for (final e in shimo) e.poem.id], [2]);
    expect((shimo.single.kind, shimo.single.marked, shimo.single.shimo), (CardMatchKind.shimo, 5, 'ころもほすてふあまのかぐやま'));
    expect(ids('みをつくしても'), [20], reason: 'the taking-card kimariji');
    expect(ids('ぱ'), isEmpty);
  });

  test('hepburn reads small kana, っ and long vowels as written', () {
    expect(hepburn('きょう'), 'kyou');
    expect(hepburn('しゃ'), 'sha');
    expect(hepburn('ちょう'), 'chou');
    expect(hepburn('じゃくれん'), 'jakuren');
    expect(hepburn('まっち'), 'matchi');
    expect(hepburn('きって'), 'kitte');
    expect(hepburn('むすめふさほせ'), 'musumefusahose');
  });

  test('the poem romaji is plain Hepburn of each verse as read', () {
    expect(poems[1].versesRomaji, ['akinotano', 'karionoiono', 'tomaoarami', 'wagakoromodewa', 'tsuyuninuretsutsu']);
    expect(poems[20].versesRomaji, ['wabinureba', 'imahataonaji', 'naniwanaru', 'miotsukushitemo', 'awantozoomou']);
    expect(poems[1].authorRomaji, 'Tenjitennou');
    for (final p in poems.all) {
      expect(p.versesRomaji.length, 5);
      expect(p.versesRomaji.join(), matches(RegExp(r'^[a-z]+$')), reason: '#${p.id}');
      expect(p.versesRomaji.skip(3).join(), hepburn(p.shimoReading), reason: '#${p.id}');
    }
  });
}
