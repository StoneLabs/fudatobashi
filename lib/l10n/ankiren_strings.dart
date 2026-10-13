import 'strings.dart';

/// Strings of 暗記練: its settings page, the play screen, results and the
/// free-play setup sheet.
extension AnkirenStrings on S {
  /// The game's name: AnkiRen in English, 暗記練 in Japanese.
  String get ankirenName => t('ankirenName');
  String get ankirenLayout => t('ankirenLayout');
  String get ankirenLayoutNote => t('ankirenLayoutNote');
  String get ankirenPortrait => t('ankirenPortrait');
  String get ankirenPortraitSub => t('ankirenPortraitSub');
  String get ankirenLandscape => t('ankirenLandscape');
  String get ankirenLandscapeSub => t('ankirenLandscapeSub');
  String get ankirenPrompt => t('ankirenPrompt');
  String get ankirenPromptNote => t('ankirenPromptNote');
  String get ankirenPromptVoice => t('ankirenPromptVoice');
  String get ankirenPromptText => t('ankirenPromptText');

  String get ankirenMemorise => t('ankirenMemorise');
  String get ankirenReady => t('ankirenReady');
  String get ankirenDontKnow => t('ankirenDontKnow');
  String get ankirenLeaveTitle => t('ankirenLeaveTitle');
  String get ankirenLeaveNote => t('ankirenLeaveNote');
  String get ankirenLeave => t('ankirenLeave');

  String get ankirenScoreLabel => t('ankirenScoreLabel');
  String ankirenScoreOf(int max) => f('ankirenScoreOf', [max]);
  String ankirenEarlyBonus(int points) => f('ankirenEarlyBonus', [points]);
  String get ankirenFirstTryLabel => t('ankirenFirstTryLabel');

  /// Every wrong tap of a game (お手つき).
  String ankirenWrongTaps(int n) => switch (n) {
        0 => t('ankirenWrongTapsNone'),
        1 => f('ankirenWrongTapsOne', [n]),
        _ => f('ankirenWrongTapsOther', [n]),
      };

  String get ankirenAvgLabel => t('ankirenAvgLabel');
  String get ankirenAvgNote => t('ankirenAvgNote');
  String ankirenNextLevel(int level) => f('ankirenNextLevel', [level]);
  String ankirenPlacement(int game, int of) => f('ankirenPlacement', [game, of]);
  String get ankirenFreeNote => t('ankirenFreeNote');
  String get ankirenAgainSub => t('ankirenAgainSub');
  String get ankirenDoneSub => t('ankirenDoneSub');

  /// A setup's name: its level, or a custom one's cards per side and
  /// memorise time.
  String ankirenLevelTag(int level) => f('ankirenLevelTag', [level]);
  String ankirenCustomTag(int perSide, String memorise) => f('ankirenCustomTag', [perSide, memorise]);

  String get ankirenLevelRow => t('ankirenLevelRow');
  String get ankirenCustom => t('ankirenCustom');
  String ankirenLevelNeeds(int level, int cards, int known) => f('ankirenLevelNeeds', [level, cards, known]);
  String get ankirenScoredAs => t('ankirenScoredAs');

  /// The level a setup scores as and a field's cards per side ("7×2"), as
  /// templates; and the cards on a level key.
  String get ankirenPerSideCount => t('ankirenPerSideCount');
  String ankirenKeyCards(int perSide) => f('ankirenKeyCards', [perSide]);
  String get ankirenPerSide => t('ankirenPerSide');
  String get ankirenMemoriseTime => t('ankirenMemoriseTime');
  String get ankirenLess => t('ankirenLess');
  String get ankirenMore => t('ankirenMore');
  String ankirenNeedCards(int n) => f('ankirenNeedCards', [n]);

  /// 暗記練's page: the hub's way in, its last games or placement, and the
  /// next ranked game with why it plays that level.
  String get ankirenOpenPage => t('ankirenOpenPage');
  String get ankirenPageTitle => t('ankirenPageTitle');
  String get ankirenPageSub => t('ankirenPageSub');
  String get ankirenLast5 => t('ankirenLast5');
  String get ankirenPlacementTitle => t('ankirenPlacementTitle');
  String get ankirenPlacementCount => t('ankirenPlacementCount');
  String get ankirenPlacementNext => t('ankirenPlacementNext');
  String get ankirenNextRanked => t('ankirenNextRanked');
  String get ankirenCards => t('ankirenCards');
  String get ankirenMemoriseLabel => t('ankirenMemoriseLabel');
  String get ankirenSetByRating => t('ankirenSetByRating');
  String get ankirenCapped => t('ankirenCapped');
  String get ankirenTopLevel => t('ankirenTopLevel');

  /// Templates: the rating points still to go to the next level, and the
  /// cards a level needs.
  String get ankirenToLevel => t('ankirenToLevel');
  String get ankirenLevelFrom => t('ankirenLevelFrom');

  /// The level tag as a template, for its number in display type.
  String get ankirenLevelValue => t('ankirenLevelTag');

  /// The field preview, for screen readers.
  String ankirenPreviewLabel(int perSide) => f('ankirenPreviewLabel', [perSide]);

  /// The rating page's band; on the last placement game's, and over the
  /// rank-up after a breakthrough.
  String get ankirenRatingBand => t('ankirenRatingBand');
  String get ankirenRankBand => t('ankirenRankBand');
  String get ankirenRankUpBand => t('ankirenRankUpBand');

  /// A placement game's slot on the rating page: "GAME 2".
  String ankirenSlot(int game) => f('ankirenSlot', [game]);

  /// The placement games still to play before the first class shows, `{0}`
  /// marking how many.
  String ankirenPlacementLeft(int games) => t(games == 1 ? 'ankirenPlacementLeftOne' : 'ankirenPlacementLeftOther');

  /// The last placement game's line before its class shows.
  String get ankirenRankIs => t('ankirenRankIs');

  /// The rating page's button after a game that lowered the rating.
  String get ankirenNextTime => t('ankirenNextTime');
}
