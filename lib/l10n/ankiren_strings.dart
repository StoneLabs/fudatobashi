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

  /// A free-play level's strikes so far, out of those that end it, for
  /// screen readers.
  String ankirenStrikesLabel(int strikes, int of) => f('ankirenStrikesLabel', [strikes, of]);
  String get ankirenLeaveTitle => t('ankirenLeaveTitle');
  String get ankirenLeaveNote => t('ankirenLeaveNote');
  String get ankirenLeave => t('ankirenLeave');

  String get ankirenScoreLabel => t('ankirenScoreLabel');

  String ankirenScoreOf(String max) => f('ankirenScoreOf', [max]);

  /// The results of a game with no score: the cards found.
  String get ankirenFoundLabel => t('ankirenFoundLabel');
  String get ankirenFirstTryLabel => t('ankirenFirstTryLabel');

  /// A game's strikes: its wrong taps and Don't knows (お手つき).
  String ankirenStrikes(int n) => switch (n) {
        0 => t('ankirenStrikesNone'),
        1 => f('ankirenStrikesOne', [n]),
        _ => f('ankirenStrikesOther', [n]),
      };

  String get ankirenAvgLabel => t('ankirenAvgLabel');
  String get ankirenAvgNote => t('ankirenAvgNote');
  String ankirenPlacement(int game, int of) => f('ankirenPlacement', [game, of]);
  String get ankirenCustomNote => t('ankirenCustomNote');

  /// A guest's game (Guest mode): its tag, and Results' note that nothing
  /// of it was saved.
  String get ankirenGuest => t('ankirenGuest');
  String get ankirenGuestNote => t('ankirenGuestNote');

  String ankirenLevelNotCleared(int level) => f('ankirenLevelNotCleared', [level]);
  String ankirenClearHow(int strikes) => f('ankirenClearHow', [strikes]);
  String get ankirenAllCleared => t('ankirenAllCleared');
  String get ankirenCustomOpened => t('ankirenCustomOpened');
  String get ankirenRankedOpened => t('ankirenRankedOpened');
  String get ankirenRankedNeedsAllKnown => t('ankirenRankedNeedsAllKnown');
  String get ankirenBackToPage => t('ankirenBackToPage');

  /// A setup's name: its level, or a custom one's cards per side and
  /// memorise time.
  String ankirenLevelTag(int level) => f('ankirenLevelTag', [level]);
  String ankirenCustomTag(int perSide, String memorise) => f('ankirenCustomTag', [perSide, memorise]);

  String get ankirenLevelRow => t('ankirenLevelRow');
  String get ankirenCustom => t('ankirenCustom');
  String ankirenLevelNeeds(int level, int cards, int known) => f('ankirenLevelNeeds', [level, cards, known]);

  /// A field's cards per side ("7×2"), as a template; and the cards on a
  /// level key.
  String get ankirenPerSideCount => t('ankirenPerSideCount');
  String ankirenKeyCards(int perSide) => f('ankirenKeyCards', [perSide]);
  String get ankirenPerSide => t('ankirenPerSide');
  String get ankirenMemoriseTime => t('ankirenMemoriseTime');
  String get ankirenLess => t('ankirenLess');
  String get ankirenMore => t('ankirenMore');
  String ankirenNeedCards(int n) => f('ankirenNeedCards', [n]);

  /// The free-play menu: its title and burst, how levels open, why a level
  /// or the custom setups are still shut, the stamp once every level is
  /// cleared, and the guest's line.
  String get ankirenSelectLevel => t('ankirenSelectLevel');
  String get ankirenConfirm => t('ankirenConfirm');
  String ankirenUnlockLine(int strikes) => f('ankirenUnlockLine', [strikes]);
  String ankirenLevelLocked(int clear, int level) => f('ankirenLevelLocked', [clear, level]);
  String ankirenCustomLocked(int clear) => f('ankirenCustomLocked', [clear]);
  String get ankirenAllClearStamp => t('ankirenAllClearStamp');
  String get ankirenGuestLine => t('ankirenGuestLine');

  /// 暗記練's page: the hub's way in, the ranked panel with its last games
  /// or placement and what still keeps it shut, the next level to clear,
  /// and Guest mode.
  String get ankirenOpenPage => t('ankirenOpenPage');
  String get ankirenPageTitle => t('ankirenPageTitle');
  String get ankirenLast5 => t('ankirenLast5');
  String get ankirenPlacementTitle => t('ankirenPlacementTitle');
  String get ankirenPlacementNext => t('ankirenPlacementNext');
  String get ankirenRankedMode => t('ankirenRankedMode');
  String get ankirenCards => t('ankirenCards');

  /// Beside the check on the top level once every level is cleared.
  String get ankirenClearedMark => t('ankirenClearedMark');
  String get ankirenMemoriseLabel => t('ankirenMemoriseLabel');
  String get ankirenNextToClear => t('ankirenNextToClear');
  String get ankirenAllClearedTitle => t('ankirenAllClearedTitle');
  String get ankirenAllLevels => t('ankirenAllLevels');
  String ankirenPlayLevel(int level) => f('ankirenPlayLevel', [level]);
  String get ankirenGuestMode => t('ankirenGuestMode');
  String get ankirenGuestButton => t('ankirenGuestButton');
  String get ankirenGuestSub => t('ankirenGuestSub');

  /// Ranked's one setup: [perSide] cards a side and the memorise time.
  String ankirenRankedFacts(int perSide, String memorise) => f('ankirenRankedFacts', [perSide, memorise]);
  String get ankirenRankedReal => t('ankirenRankedReal');

  /// What still opens ranked: the all-known mode, clearing [level], or
  /// both.
  String ankirenRankedLocked({required bool allKnown, required bool cleared, required int level}) => allKnown
      ? f('ankirenRankedLockedLevel', [level])
      : cleared
          ? t('ankirenRankedLockedMode')
          : f('ankirenRankedLockedBoth', [level]);

  /// Templates: what clears a level ([AnkirenTuning.strikesOut] strikes
  /// end it), and the cards a level needs.
  String get ankirenClearRule => t('ankirenClearRule');
  String get ankirenLevelFrom => t('ankirenLevelFrom');

  /// The level tag as a template, for its number in display type.
  String get ankirenLevelValue => t('ankirenLevelTag');

  /// The field preview, for screen readers.
  String ankirenPreviewLabel(int perSide) => f('ankirenPreviewLabel', [perSide]);

  /// The rating page's band; on the last placement game's; over 暗記練's
  /// rank-up after a breakthrough, and over its rank-down after a fall
  /// into a lower class.
  String get ankirenRatingBand => t('ankirenRatingBand');
  String get ankirenRankBand => t('ankirenRankBand');

  /// The big shout of the AnkiRen rating screen, for how the rating moved.
  String get ankirenTitleUp => t('ankirenTitleUp');
  String get ankirenTitleHeld => t('ankirenTitleHeld');
  String get ankirenTitleDown => t('ankirenTitleDown');
  String get ankirenTitlePlacing => t('ankirenTitlePlacing');
  String get ankirenTitlePlaced => t('ankirenTitlePlaced');
  String get ankirenRankUpBand => t('ankirenRankUpBand');
  String get ankirenRankDownBand => t('ankirenRankDownBand');

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
