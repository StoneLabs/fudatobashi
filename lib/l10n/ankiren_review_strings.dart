import '../domain/ankiren_field.dart';
import '../domain/rating.dart';
import 'ranked_strings.dart';
import 'strings.dart';

/// Strings of History's 暗記練 game page.
extension AnkirenReviewStrings on S {
  String get ankirenTabField => t('ankirenTabField');
  String get ankirenTabScore => t('ankirenTabScore');
  String get ankirenTabTaps => t('ankirenTabTaps');
  String ankirenASide(Object a0) => f('ankirenASide', [a0]);
  String get ankirenPointsLabel => t('ankirenPointsLabel');
  String ankirenOfMax(Object a0) => f('ankirenOfMax', [a0]);
  String get ankirenBestRankedStamp => t('ankirenBestRankedStamp');
  String get ankirenFirstTapFact => t('ankirenFirstTapFact');
  String get ankirenMemorisedFact => t('ankirenMemorisedFact');
  String ankirenUpFrom(Object a0) => f('ankirenUpFrom', [a0]);
  String ankirenClassLine(RankBand band) => f('ankirenClassLine', [className(band)]);
  String get ankirenMixTitle => t('ankirenMixTitle');
  String get ankirenThisGame => t('ankirenThisGame');
  String ankirenCardsCount(Object a0) => f('ankirenCardsCount', [a0]);
  String get ankirenUsual => t('ankirenUsual');
  String get ankirenSameSetup => t('ankirenSameSetup');
  String get ankirenMemoTitle => t('ankirenMemoTitle');
  String ankirenMemoAllowed(Object a0) => f('ankirenMemoAllowed', [a0]);
  String ankirenMemoUsed(Object a0) => f('ankirenMemoUsed', [a0]);
  String ankirenMemoEarly(Object a0) => f('ankirenMemoEarly', [a0]);
  String ankirenMemoPays(Object a0) => f('ankirenMemoPays', [a0]);
  String ankirenMemoTicks(Object a0) => f('ankirenMemoTicks', [a0]);
  String get ankirenFieldTitle => t('ankirenFieldTitle');
  String get ankirenFieldNote => t('ankirenFieldNote');
  String get ankirenFirstTapLegend => t('ankirenFirstTapLegend');
  String get ankirenSecondTapLegend => t('ankirenSecondTapLegend');
  String get ankirenStartReview => t('ankirenStartReview');
  String get ankirenShowAll => t('ankirenShowAll');
  String get ankirenTheirSide => t('ankirenTheirSide');
  String get ankirenYourSide => t('ankirenYourSide');
  String ankirenStepCard(Object a0, Object a1, Object a2) => f('ankirenStepCard', [a0, a1, a2]);
  String ankirenFoundIn(Object a0) => f('ankirenFoundIn', [a0]);
  String ankirenShownFound(Object a0) => f('ankirenShownFound', [a0]);
  String get ankirenNotFound => t('ankirenNotFound');
  String get ankirenNoTap => t('ankirenNoTap');
  String get ankirenFieldMissing => t('ankirenFieldMissing');
  String ankirenLookAlike(Object a0, Object a1) => f('ankirenLookAlike', [a0, a1]);
  String get ankirenFieldLabel => t('ankirenFieldLabel');
  String get ankirenStepBack => t('ankirenStepBack');
  String get ankirenStepNext => t('ankirenStepNext');
  String get ankirenFindTitle => t('ankirenFindTitle');
  String get ankirenSeconds => t('ankirenSeconds');
  String get ankirenRankedTitle => t('ankirenRankedTitle');
  String get ankirenColThis => t('ankirenColThis');
  String get ankirenColBest => t('ankirenColBest');
  String get ankirenColAverage => t('ankirenColAverage');
  String get ankirenColLast => t('ankirenColLast');
  String get ankirenRowPoints => t('ankirenRowPoints');
  String get ankirenRowCardPoints => t('ankirenRowCardPoints');
  String get ankirenRowFirstTap => t('ankirenRowFirstTap');
  String get ankirenRowMedian => t('ankirenRowMedian');
  String get ankirenRowMemorised => t('ankirenRowMemorised');
  String get ankirenFirstRanked => t('ankirenFirstRanked');
  String get ankirenMisplacedTitle => t('ankirenMisplacedTitle');
  String get ankirenAllGames => t('ankirenAllGames');
  String get ankirenColCard => t('ankirenColCard');
  String get ankirenColDealt => t('ankirenColDealt');
  String get ankirenColRightFirst => t('ankirenColRightFirst');
  String get ankirenColUsualFirst => t('ankirenColUsualFirst');
  String get ankirenMisplacedNone => t('ankirenMisplacedNone');
  String get ankirenEqFirstRight => t('ankirenEqFirstRight');
  String get ankirenEqOther => t('ankirenEqOther');
  String ankirenEqEarly(Object a0) => f('ankirenEqEarly', [a0]);
  String get ankirenEqOnTime => t('ankirenEqOnTime');
  String get ankirenEqPoints => t('ankirenEqPoints');
  String get ankirenColFor => t('ankirenColFor');
  String get ankirenColCards => t('ankirenColCards');
  String get ankirenColPoints => t('ankirenColPoints');
  String ankirenPartRight(Object a0) => f('ankirenPartRight', [a0]);
  String ankirenPartNear(Object a0) => f('ankirenPartNear', [a0]);
  String ankirenPartSecond(Object a0) => f('ankirenPartSecond', [a0]);
  String ankirenPartSpeed(Object a0) => f('ankirenPartSpeed', [a0]);
  String get ankirenRatingHead => t('ankirenRatingHead');
  String get ankirenPreviousRating => t('ankirenPreviousRating');
  String get ankirenPlayedLike => t('ankirenPlayedLike');
  String get ankirenNewRating => t('ankirenNewRating');
  String ankirenClassAt(Object a0, RankBand band, Object a2) => f('ankirenClassAt', [a0, className(band), a2]);
  String get ankirenTapsTitle => t('ankirenTapsTitle');
  String ankirenTapsNote(Object a0) => f('ankirenTapsNote', [a0]);
  String get ankirenColNumber => t('ankirenColNumber');
  String get ankirenColFirstSecond => t('ankirenColFirstSecond');
  String get ankirenColFind => t('ankirenColFind');
  String get ankirenColSpeed => t('ankirenColSpeed');
  String get ankirenColPts => t('ankirenColPts');
  String get ankirenShown => t('ankirenShown');
  String get ankirenTotal => t('ankirenTotal');
  String get ankirenTapsCaption => t('ankirenTapsCaption');
  String get ankirenTapsCaptionCustom => t('ankirenTapsCaptionCustom');
  String get ankirenRightFirstLabel => t('ankirenRightFirstLabel');
  String get ankirenNotScored => t('ankirenNotScored');
  String get ankirenFoundFact => t('ankirenFoundFact');
  String get ankirenWrongTapsFact => t('ankirenWrongTapsFact');
  String ankirenMemorisedOf(Object a0) => f('ankirenMemorisedOf', [a0]);
  String get ankirenMedianFact => t('ankirenMedianFact');
  String get ankirenCustomUnscored => t('ankirenCustomUnscored');
  String get ankirenSetupTitle => t('ankirenSetupTitle');
  String ankirenSetupNote(Object a0) => f('ankirenSetupNote', [a0]);
  String ankirenMoreFirst(Object a0) => f('ankirenMoreFirst', [a0]);
  String ankirenFewerFirst(Object a0) => f('ankirenFewerFirst', [a0]);
  String get ankirenSameFirst => t('ankirenSameFirst');
  String ankirenFaster(Object a0) => f('ankirenFaster', [a0]);
  String ankirenSlower(Object a0) => f('ankirenSlower', [a0]);
  String ankirenMemoOf(Object a0, Object a1) => f('ankirenMemoOf', [a0, a1]);
  String get ankirenSetupFirst => t('ankirenSetupFirst');

  /// "{0} games at Lv {1}" (ranked's without a level), and "{0} games".
  String ankirenGamesAtLevel(int games, int? level) => level == null
      ? f(games == 1 ? 'ankirenRankedGamesOne' : 'ankirenRankedGamesOther', [games])
      : f(games == 1 ? 'ankirenGamesAtLevelOne' : 'ankirenGamesAtLevelOther', [games, level]);
  String ankirenGames(int games) => f(games == 1 ? 'ankirenGamesOne' : 'ankirenGamesOther', [games]);

  /// Where a tap landed, in a word or two for a chip.
  String ankirenChip(TapProximity place) => switch (place) {
        TapProximity.card => t('ankirenChipCard'),
        TapProximity.neighbour => t('ankirenChipNeighbour'),
        TapProximity.row => t('ankirenChipRow'),
        TapProximity.quadrant => t('ankirenChipQuadrant'),
        TapProximity.side => t('ankirenChipSide'),
        TapProximity.otherSide => t('ankirenChipOtherSide'),
      };
}
