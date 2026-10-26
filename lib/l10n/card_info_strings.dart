import 'strings.dart';

/// Strings of the card browser, a card's About page and its link from the
/// card's stats page.
extension CardInfoStrings on S {
  // Help › Tools
  String get cardBrowserTitle => t('cardBrowserTitle');
  String get cardBrowserNote => t('cardBrowserNote');

  // The card browser
  String get cardSearchHint => t('cardSearchHint');
  String get cardSearchClear => t('cardSearchClear');
  String cardCountAll(int n) => f('cardCountAll', [n]);
  String cardCountFound(int n, int all) => f('cardCountFound', [n, all]);
  String get cardTapHint => t('cardTapHint');
  String get cardColumnNumber => t('cardColumnNumber');
  String get cardColumnKimariji => t('cardColumnKimariji');
  String get cardColumnCard => t('cardColumnCard');
  String get cardShimoTag => t('cardShimoTag');
  String cardNoneTitle(String query) => f('cardNoneTitle', [query]);
  String get cardNoneText => t('cardNoneText');
  String cardNoneNumberTitle(String query) => f('cardNoneNumberTitle', [query]);
  String get cardNoneNumberText => t('cardNoneNumberText');

  // About this card
  String get aboutCardTitle => t('aboutCardTitle');
  String get aboutTakingCard => t('aboutTakingCard');
  String get aboutReadingCard => t('aboutReadingCard');
  String get aboutSwipe => t('aboutSwipe');
  String get aboutKeyKimariji => t('aboutKeyKimariji');
  String get aboutKeyHold => t('aboutKeyHold');
  String get aboutKeyFade => t('aboutKeyFade');
  String get aboutKeyGuide => t('aboutKeyGuide');
  String aboutSounds(int n) => f(countKey('aboutSounds', n), [n]);
  String get aboutPoem => t('aboutPoem');
  String get aboutFirstHalf => t('aboutFirstHalf');
  String get aboutSecondHalf => t('aboutSecondHalf');
  String get aboutKana => t('aboutKana');
  String get aboutRomaji => t('aboutRomaji');
  String get aboutFacts => t('aboutFacts');
  String get aboutPoet => t('aboutPoet');
  String get aboutTakingKimariji => t('aboutTakingKimariji');
  String get aboutColourGroup => t('aboutColourGroup');
  String get aboutSource => t('aboutSource');

  /// Where the 序歌 comes from, named in the UI's language.
  String get aboutJokaSource => t('aboutJokaSource');

  /// A card's 五色 group: the group's own name, led by its colour in words
  /// where the language has one (the colour strings carry their own separator).
  String aboutColourName(String group) =>
      f('aboutColourName', [t('colourGroup${_colourKeys[group] ?? group}'), group]);

  /// A card's place in its 五色 group and the group's size.
  String aboutColourPlace(int place, int size) => f('aboutColourPlace', [place, size]);

  String get aboutSimilar => t('aboutSimilar');
  String get aboutReadExplanation => t('aboutReadExplanation');
  String get aboutLadderSounds => t('aboutLadderSounds');
  String get aboutLadderKana => t('aboutLadderKana');
  String get aboutLadderLead => t('aboutLadderLead');
  String get aboutLadderLeadKana => t('aboutLadderLeadKana');
  String get ladderKimariji => t('ladderKimariji');
  String get ladderTop => t('ladderTop');

  /// A step's line: [cards] start with [sound], and the [cards] − 1 others
  /// must be gone first.
  String ladderStep(int cards, String sound, {required bool consonant}) =>
      f(countKey(consonant ? 'ladderConsonantStep' : 'ladderStep', cards - 1), [cards, sound, cards - 1]);

  String ladderCards(int n) => t(countKey('ladderCards', n));
  String ladderMore(int n) => f('ladderMore', [n]);
  String get aboutConfused => t('aboutConfused');
  String get aboutPoemPart => t('aboutPoemPart');
  String get aboutMyRecord => t('aboutMyRecord');
  String get aboutMyRecordNote => t('aboutMyRecordNote');
  String get aboutPrevious => t('aboutPrevious');
  String get aboutNext => t('aboutNext');

  // A card's stats page
  String get statsAboutCard => t('statsAboutCard');
  String get statsAboutCardNote => t('statsAboutCardNote');

  static const _colourKeys = {'青': 'Blue', '桃': 'Pink', '黄': 'Yellow', '緑': 'Green', '橙': 'Orange'};
}
