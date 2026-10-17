import 'card_info_strings.dart';
import 'strings.dart';

/// Strings of First sounds, the explanation of the sound ladder opened from
/// a card's About page. The cards and sounds a line names come in as `{0}`,
/// `{1}` … from the ladders themselves; the switch and the Kimariji line
/// are named as the About page labels them.
extension FirstSoundsStrings on S {
  String get firstSoundsTitle => t('firstSoundsTitle');
  String get firstSoundsIntro => t('firstSoundsIntro');

  String get firstSoundsKimarijiTitle => t('firstSoundsKimarijiTitle');
  String get firstSoundsKimariji1 => t('firstSoundsKimariji1');
  String get firstSoundsKimariji2 => t('firstSoundsKimariji2');

  /// [card] and [rival] both start with [shared], then part.
  String firstSoundsKimariji3(int card, String kimariji, int rival, String rivalKimariji, String shared) =>
      f('firstSoundsKimariji3', [card, kimariji, rival, rivalKimariji, shared]);
  String get firstSoundsKimarijiCaption => t('firstSoundsKimarijiCaption');

  String get firstSoundsShorterTitle => t('firstSoundsShorterTitle');

  /// Once [rival] is read, [card] is the only card left that starts with [shared].
  String firstSoundsShorter1(int rival, String rivalKimariji, int card, String shared) =>
      f('firstSoundsShorter1', [rival, rivalKimariji, card, shared]);
  String get firstSoundsShorterCaption => t('firstSoundsShorterCaption');

  /// [cards] cards start with [sound]; it is enough once the others are gone.
  String firstSoundsShorter2(int cards, String sound) => f('firstSoundsShorter2', [cards, sound, cards - 1]);
  String get firstSoundsShorter3 => t('firstSoundsShorter3');
  String get firstSoundsShorterTobi => t('firstSoundsShorterTobi');

  String get firstSoundsStairsTitle => t('firstSoundsStairsTitle');
  String firstSoundsStairs1(int card) => f('firstSoundsStairs1', [card]);
  String get firstSoundsStairs2 => f('firstSoundsStairs2', [ladderKimariji]);
  String get firstSoundsSoundTitle => t('firstSoundsSoundTitle');
  String get firstSoundsSound => t('firstSoundsSound');
  String get firstSoundsBadgeTitle => t('firstSoundsBadgeTitle');
  String get firstSoundsBadge => t('firstSoundsBadge');
  String get firstSoundsLineTitle => t('firstSoundsLineTitle');
  String get firstSoundsLine => t('firstSoundsLine');
  String get firstSoundsChipsTitle => t('firstSoundsChipsTitle');
  String get firstSoundsChips => t('firstSoundsChips');

  /// The step [sound] holds [cards] cards; once [rival] is read, it is
  /// enough for [card].
  String firstSoundsStairsExample(String sound, int cards, int rival, String rivalKimariji, int card) =>
      f('firstSoundsStairsExample', [sound, cards, rival, rivalKimariji, card]);

  String get firstSoundsConsonantTitle => t('firstSoundsConsonantTitle');
  String get firstSoundsConsonant1 => t('firstSoundsConsonant1');

  /// The consonant step [step] is [before], then [consonant].
  String firstSoundsConsonant2(String step, String before, String consonant) =>
      f('firstSoundsConsonant2', [step, before, consonant]);

  /// [card]'s top step [top] ends on [consonant], where [rival] has [rivalConsonant].
  String firstSoundsConsonant3(int card, String top, int rival, String rivalConsonant, String consonant) =>
      f('firstSoundsConsonant3', [card, top, rival, rivalConsonant, consonant]);

  /// [card]'s top step [top]: the one other card that starts with [before]
  /// is [rival], which goes on with a vowel, so [consonant] decides.
  String firstSoundsConsonant4(int card, String top, String before, int rival, String rivalKimariji, String consonant) =>
      f('firstSoundsConsonant4', [card, top, before, rival, rivalKimariji, consonant]);

  /// The consonant step [step] is enough once [rival] is read.
  String firstSoundsConsonant5(String step, int rival) => f('firstSoundsConsonant5', [step, rival]);

  /// [card]'s top step [top] ends on sh; cards like [other] have s there.
  String firstSoundsConsonant6(int card, String top, String other) => f('firstSoundsConsonant6', [card, top, other]);
  String get firstSoundsConsonantTobi => t('firstSoundsConsonantTobi');

  String get firstSoundsSwitchTitle => f('firstSoundsSwitchTitle', [aboutLadderSounds, aboutLadderKana]);
  String get firstSoundsSwitch1 => f('firstSoundsSwitch1', [aboutLadderSounds]);
  String get firstSoundsSwitch2 => f('firstSoundsSwitch2', [aboutLadderKana]);
  String firstSoundsSwitch3(int card) => f('firstSoundsSwitch3', [card, aboutLadderKana]);
  String get firstSoundsSwitch4 => t('firstSoundsSwitch4');
  String get firstSoundsTobi => t('firstSoundsTobi');
}
