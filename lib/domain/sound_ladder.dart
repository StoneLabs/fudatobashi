import 'package:flutter/foundation.dart';

import '../data/poem.dart';
import '../l10n/romaji.dart';

/// One step of a card's sound ladder: a start of its reading, its first
/// [kana] kana and then, if given, only the [consonant] of the next sound,
/// with every card whose reading starts the same way.
@immutable
class LadderStep {
  const LadderStep({required this.kana, this.consonant, required this.cards, required this.joining});

  final int kana;
  final String? consonant;

  /// The cards on this step, this card among them, by id.
  final List<int> cards;

  /// The cards this step adds to the steps before it, by id.
  final List<int> joining;

  bool get isConsonant => consonant != null;
}

/// A step's sound as text: the part that is heard, then the rest of the
/// kimariji, no longer needed, to show faded.
typedef LadderSound = ({String kept, String faded});

/// How far a card's first sounds can shrink as other cards are read: from
/// its kimariji down to its first sound, every start of its reading, each
/// kana whole and then only its consonant (し as sh, きょ as ky; vowels, を
/// and ん have none). A step's sound is enough once the other cards on it
/// are gone. When two steps in a row hold the same cards, only the shorter
/// sound is kept, so the first step is the shortest sound no other card has.
abstract final class SoundLadder {
  /// [poem]'s ladder among [all] the poems; with [kanaOnly], whole kana only,
  /// starting from the kimariji itself.
  static List<LadderStep> of(Poem poem, List<Poem> all, {bool kanaOnly = false}) {
    final reading = poem.kamiReading;
    final levels = <({int kana, String? consonant, List<int> cards})>[];
    for (var length = poem.kimariji.length; length >= 1; length--) {
      final start = reading.substring(0, length);
      levels.add((kana: length, consonant: null, cards: [for (final p in all) if (p.kamiReading.startsWith(start)) p.id]));
      final consonant = kanaOnly ? null : consonantAt(reading, length - 1);
      if (consonant == null) continue;
      final before = reading.substring(0, length - 1);
      levels.add((
        kana: length - 1,
        consonant: consonant,
        cards: [
          for (final p in all)
            if (p.kamiReading.startsWith(before) && consonantAt(p.kamiReading, length - 1) == consonant) p.id,
        ],
      ));
    }
    final kept = [levels.first];
    for (final level in levels.skip(1)) {
      if (listEquals(level.cards, kept.last.cards)) {
        kept.last = level;
      } else {
        kept.add(level);
      }
    }
    final seen = {poem.id};
    return [
      for (final level in kept)
        LadderStep(
          kana: level.kana,
          consonant: level.consonant,
          cards: level.cards,
          joining: [for (final id in level.cards) if (seen.add(id)) id],
        ),
    ];
  }

  /// The consonant of the sound at [at] in [reading], or null when it has
  /// none of its own (a vowel, を, ん, っ, or past the end).
  static String? consonantAt(String reading, int at) {
    if (at >= reading.length) return null;
    final sound = soundAt(reading, at)?.sound;
    if (sound == null || sound.consonant.isEmpty || sound.vowel.isEmpty) return null;
    return sound.consonant;
  }

  /// [step]'s sound in [poem]'s kana: あき then a faded の, or あk- for a
  /// consonant step.
  static LadderSound inKana(Poem poem, LadderStep step) {
    final kana = poem.kimariji.substring(0, step.kana);
    return switch (step.consonant) {
      final consonant? => (kept: '$kana$consonant-', faded: ''),
      null => (kept: kana, faded: poem.kimariji.substring(step.kana)),
    };
  }

  /// [step]'s sound in romaji, where [romaji] is [poem]'s kimariji as the
  /// app writes it in romaji (ōko): ki then a faded migatameha, or kim- for
  /// a consonant step.
  static LadderSound inRomaji(Poem poem, String romaji, LadderStep step) {
    final start = _romajiStart(poem, romaji, step.kana);
    return switch (step.consonant) {
      final consonant? => (kept: '${start.kept}$consonant-', faded: ''),
      null => start,
    };
  }

  /// The first [kana] kana of [poem]'s kimariji in romaji, and the rest.
  static LadderSound _romajiStart(Poem poem, String romaji, int kana) {
    final length = poem.kimariji.length;
    if (kana >= length) return (kept: romaji, faded: '');
    final kept = _longVowels(hepburn(poem.kamiReading.substring(0, kana)));
    if (romaji.startsWith(kept)) return (kept: kept, faded: romaji.substring(kept.length));
    final whole = hepburn(poem.kamiReading.substring(0, length));
    return (kept: kept, faded: whole.startsWith(kept) ? whole.substring(kept.length) : '');
  }

  /// Long vowels written as the kimariji romaji writes them (oo as ō).
  static String _longVowels(String romaji) => romaji.replaceAll('oo', 'ō').replaceAll('uu', 'ū');
}
