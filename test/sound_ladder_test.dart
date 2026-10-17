// The sound ladder against its separate reference: .scratchpad's
// ladder_check.py wrote test/fixtures/sound_ladder*.json from poems.json, one
// list of [sound, cards] per card, the sound as its kana with the consonant
// step's consonant in brackets ("あき[n]").
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/sound_ladder.dart';

void main() {
  final poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  List<Object> written(Poem poem, LadderStep step) => [
        '${poem.kamiReading.substring(0, step.kana)}${step.consonant == null ? '' : '[${step.consonant}]'}',
        step.cards,
      ];

  for (final (mode, file, kanaOnly) in [
    ('sounds', 'test/fixtures/sound_ladder.json', false),
    ('kana only', 'test/fixtures/sound_ladder_kana.json', true),
  ]) {
    test('every card\'s ladder matches the reference ($mode)', () {
      final expected = jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
      expect(expected.length, 100);
      for (final poem in poems.all) {
        final steps = SoundLadder.of(poem, poems.all, kanaOnly: kanaOnly);
        expect([for (final s in steps) written(poem, s)], expected['${poem.id}'], reason: '#${poem.id} ${poem.kimariji}');
      }
    });
  }

  test('the first step is the card alone, and each card joins the ladder once', () {
    for (final kanaOnly in [false, true]) {
      for (final poem in poems.all) {
        final steps = SoundLadder.of(poem, poems.all, kanaOnly: kanaOnly);
        expect(steps.first.cards, [poem.id]);
        expect(steps.first.joining, isEmpty);
        final joined = [for (final s in steps) ...s.joining];
        expect(joined.toSet().length, joined.length, reason: '#${poem.id}');
        expect({...joined, poem.id}, {...steps.last.cards}, reason: '#${poem.id}');
      }
    }
  });

  test('kana only starts from the kimariji and has no consonant steps', () {
    for (final poem in poems.all) {
      final steps = SoundLadder.of(poem, poems.all, kanaOnly: true);
      expect(steps.first.kana, poem.kimariji.length);
      expect(steps.any((s) => s.isConsonant), isFalse);
    }
  });

  test('sh, ch and ts are one consonant each, and vowels have none', () {
    expect(SoundLadder.consonantAt('あし', 1), 'sh');
    expect(SoundLadder.consonantAt('ちは', 0), 'ch');
    expect(SoundLadder.consonantAt('つく', 0), 'ts');
    expect(SoundLadder.consonantAt('ふ', 0), 'f');
    expect(SoundLadder.consonantAt('きょう', 0), 'ky');
    expect(SoundLadder.consonantAt('あし', 0), isNull);
    expect(SoundLadder.consonantAt('をぐ', 0), isNull);
    expect(SoundLadder.consonantAt('あ', 1), isNull);
  });

  group('labels', () {
    LadderStep stepOf(Poem poem, String sound) => SoundLadder.of(poem, poems.all)
        .firstWhere((s) => written(poem, s).first == sound);

    test('in kana: the kept kana, then the rest faded; a consonant step ends in its consonant', () {
      final akino = poems.byKimariji('あきの');
      expect(SoundLadder.inKana(akino, stepOf(akino, 'あき[n]')), (kept: 'あきn-', faded: ''));
      expect(SoundLadder.inKana(akino, stepOf(akino, 'あき')), (kept: 'あき', faded: 'の'));
      expect(SoundLadder.inKana(akino, stepOf(akino, 'あ[k]')), (kept: 'あk-', faded: ''));
      final ashi = poems.byKimariji('あし');
      expect(SoundLadder.inKana(ashi, SoundLadder.of(ashi, poems.all).first), (kept: 'あsh-', faded: ''));
    });

    test('in romaji, long vowels written as the kimariji writes them', () {
      final kimi = poems.byKimariji('きみがためは');
      final steps = SoundLadder.of(kimi, poems.all);
      expect([for (final s in steps) SoundLadder.inRomaji(kimi, 'kimigatameha', s)], [
        (kept: 'kimigatameh-', faded: ''),
        (kept: 'kim-', faded: ''),
        (kept: 'ki', faded: 'migatameha'),
        (kept: 'k-', faded: ''),
      ]);
      final oko = poems.byKimariji('おおこ');
      expect([for (final s in SoundLadder.of(oko, poems.all)) SoundLadder.inRomaji(oko, 'ōko', s)], [
        (kept: 'ōko', faded: ''),
        (kept: 'ōk-', faded: ''),
        (kept: 'ō', faded: 'ko'),
        (kept: 'o', faded: 'oko'),
      ]);
      final ashi = poems.byKimariji('あし');
      expect(SoundLadder.inRomaji(ashi, 'ashi', SoundLadder.of(ashi, poems.all).first), (kept: 'ash-', faded: ''));
    });
  });
}
