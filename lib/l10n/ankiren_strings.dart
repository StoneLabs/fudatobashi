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
  String get ankirenForgot => t('ankirenForgot');

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
  String ankirenSetupLine(int perSide, String memorise) => f('ankirenSetupLine', [perSide, memorise]);
  String ankirenLevelNeeds(int level, int cards, int known) => f('ankirenLevelNeeds', [level, cards, known]);
  String get ankirenPerSide => t('ankirenPerSide');
  String get ankirenMemoriseTime => t('ankirenMemoriseTime');
  String get ankirenLess => t('ankirenLess');
  String get ankirenMore => t('ankirenMore');
  String ankirenNeedCards(int n) => f('ankirenNeedCards', [n]);
}
