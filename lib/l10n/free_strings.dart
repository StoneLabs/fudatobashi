import 'strings.dart';

/// Strings of free practice (始める): its lock, setup sheet and pickers. The
/// sheet's notes mark Japanese phrase ends with `​` (see `Phrases`).
extension FreeStrings on S {
  String get freeSheetTag => t('freeSheetTag');
  String get freeStart => t('freeStart');
  String get deckCount => t('deckCount');
  String get freeLocked => t('freeLocked');
  String freeLockedSub(int n) => f('freeLockedSub', [n]);
  String freeLockedWhy(int n) => f(n == 1 ? 'freeLockedWhyOne' : 'freeLockedWhyOther', [n]);

  /// Whether the run counts: the tag, and a line on what that means.
  String get countsTag => t('countsTag');
  String get countsNote => t('countsNote');
  String get customTag => t('customTag');
  String get customNote => t('customNote');
  String get resetToDefault => t('resetToDefault');
  String get resetToDefaultLabel => t('resetToDefaultLabel');

  /// Home's free-play panel: what the next run is.
  String get homeFreeCounts => t('homeFreeCounts');
  String get homeFreeCustom => t('homeFreeCustom');

  String get islandsRow => t('islandsRow');
  String get cardsRow => t('cardsRow');
  String get lookAlikesRow => t('lookAlikesRow');
  String get allKnownIslands => t('allKnownIslands');
  /// [n] of [of] islands wholly in the deck, and [partly] more in part.
  String islandsOf(int n, int of, {int partly = 0}) =>
      f('islandsOf', [n, of]) + (partly > 0 ? f('islandsOfPartly', [partly]) : '');
  String cardsOf(int n, int of) => f('freeCardsOf', [n, of]);
  String setsOf(int n, int of) => f('setsOf', [n, of]);
  String get noSetsYet => t('noSetsYet');

  String get maskRow => t('maskRow');
  String get maskOff => t('maskOff');
  String maskLevel(int level) => switch (level) {
        1 => t('maskLevel1'),
        2 => t('maskLevel2'),
        3 => t('maskLevel3'),
        4 => t('maskLevel4'),
        5 => t('maskLevel5'),
        6 => t('maskLevel6'),
        7 => t('maskLevel7'),
        _ => t('maskLevelDefault'),
      };

  // Pickers
  String get pickIslands => t('pickIslands');
  String get pickCards => t('pickCards');
  String get pickLookAlikes => t('pickLookAlikes');
  String get pickIslandsHint => t('pickIslandsHint');
  String get pickCardsHint => t('pickCardsHint');
  String get pickLookAlikesHint => t('pickLookAlikesHint');
  String get noLookAlikes => t('noLookAlikes');
  String get selectAll => t('selectAll');
  String get selectNone => t('selectNone');
  String get legendInDeck => t('legendInDeck');
  String get legendOut => t('legendOut');
  String get legendUnknown => t('legendUnknown');

  /// History and Results: which deck a free-play run used.
  String get deckAllKnown => t('deckAllKnown');
  String get deckCustom => t('deckCustom');
  String get customRunNote => t('customRunNote');
}
