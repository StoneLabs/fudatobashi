import '../domain/field_parts.dart';
import '../domain/ikkiuchi_match.dart';
import '../domain/ikkiuchi_mode.dart';
import '../domain/ikkiuchi_record.dart';
import '../domain/rating.dart';
import 'ranked_strings.dart';
import 'strings.dart';

/// Strings of 一騎打ち: its page, its custom sheet and rules, the placing
/// and the memory time, the greetings, the 送り札 on the band, Tobi's word
/// as his card waits, the names of the places a card may go on the
/// player's side, the game column, a からふだ's tag, how a read ended, and
/// History's list of matches and a match's page.
extension IkkiuchiStrings on S {
  /// The band while a card is sent: its title, and what the player does,
  /// sending one of theirs or placing Tobi's; in landscape the shorter
  /// [ikkiuchiSendShort] for sending.
  String get ikkiuchiSent => t('ikkiuchiSent');
  String get ikkiuchiSendYours => t('ikkiuchiSendYours');
  String get ikkiuchiSendShort => t('ikkiuchiSendShort');
  String get ikkiuchiPlaceTobis => t('ikkiuchiPlaceTobis');

  /// What goes on while Tobi lays the card the player sent him.
  String get ikkiuchiTobiPlaces => t('ikkiuchiTobiPlaces');

  /// The memory time before play, and the time left of it, [clock] as m:ss.
  String get ikkiuchiMemoryTime => t('ikkiuchiMemoryTime');
  String ikkiuchiTimeLeft(String clock) => f('ikkiuchiTimeLeft', [clock]);

  /// The placing: the hint before the first card is placed, the stack's
  /// tag with [n] cards left in it, and the tag on a placed card dragged
  /// back onto it.
  String get ikkiuchiPlaceHint => t('ikkiuchiPlaceHint');
  String ikkiuchiStackLeft(int n) => f('ikkiuchiStackLeft', [n]);
  String get ikkiuchiBackOnStack => t('ikkiuchiBackOnStack');

  /// The game column's button that ends the memory time early.
  String get ikkiuchiReady => t('ikkiuchiReady');

  /// The players' greeting as play begins, and their thanks once it is over.
  String get ikkiuchiGreeting => t('ikkiuchiGreeting');
  String get ikkiuchiThanks => t('ikkiuchiThanks');

  /// How a match ended, over its board: the player beat Tobi or Tobi won,
  /// and by how many cards ([n]).
  String get ikkiuchiBeatTobi => t('ikkiuchiBeatTobi');
  String get ikkiuchiTobiWins => t('ikkiuchiTobiWins');
  String ikkiuchiWonBy(int n) => f(countKey('ikkiuchiWonBy', n), [n]);
  String ikkiuchiLostBy(int n) => f(countKey('ikkiuchiLostBy', n), [n]);

  /// 並べ替え: its button, and the call's place while the player moves
  /// their cards.
  String get ikkiuchiArrange => t('ikkiuchiArrange');
  String get ikkiuchiArranging => t('ikkiuchiArranging');
  String get ikkiuchiArrangeHint => t('ikkiuchiArrangeHint');

  /// 終了's hint once it is only tapped, [seconds] being how long to hold it,
  /// rounded.
  String ikkiuchiEndHint(int seconds) => f('ikkiuchiEndHint', [seconds]);

  /// The score's names.
  String get ikkiuchiTobi => t('ikkiuchiTobi');
  String get ikkiuchiYou => t('ikkiuchiYou');

  /// The tag before the words of a からふだ read.
  String get ikkiuchiKarafuda => t('ikkiuchiKarafuda');

  /// The hub's entry: what the match is, and the burst to the page.
  String get ikkiuchiEntryLine => t('ikkiuchiEntryLine');
  String get ikkiuchiPageTitle => t('ikkiuchiPageTitle');

  /// How a match ended for the player, won or lost.
  String get ikkiuchiWon => t('ikkiuchiWon');
  String get ikkiuchiLost => t('ikkiuchiLost');

  /// A match's card margin.
  String get ikkiuchiMargin => t('ikkiuchiMargin');

  /// The page's mode box: a tab's cards a side ([n]), placement's label,
  /// a placement match won or lost, and the line on what the [left]
  /// placement matches of [mode] decide (the template, {0} for [left]).
  String ikkiuchiTabPerSide(int n) => f('ikkiuchiTabPerSide', [n]);
  String get ikkiuchiPlacementTitle => t('ikkiuchiPlacementTitle');
  String get ikkiuchiSlotWon => t('ikkiuchiSlotWon');
  String get ikkiuchiSlotLost => t('ikkiuchiSlotLost');
  String ikkiuchiPlacingLine(IkkiuchiMode mode, {required bool first}) =>
      t(first ? 'ikkiuchiPlacingFirst' : 'ikkiuchiPlacingLeft').replaceAll('{mode}', ikkiuchiModeName(mode));

  /// The box's rating curve: its caption over [n] matches, the note while
  /// it is short, and the note in its room while placing.
  String ikkiuchiCurveLast(int n) => f('ikkiuchiCurveLast', [n]);
  String get ikkiuchiCurveGrows => t('ikkiuchiCurveGrows');
  String get ikkiuchiCurveLater => t('ikkiuchiCurveLater');

  /// The box's match: the cards a side as a template ({0}).
  String get ikkiuchiBoxPerSide => t('ikkiuchiBoxPerSide');

  /// Free play: its panel's tag and heading; the bots row (its name, the
  /// tag in the bots page's title, its line) and the custom row's line.
  String get ikkiuchiFreePlay => t('ikkiuchiFreePlay');
  String get ikkiuchiRatingStays => t('ikkiuchiRatingStays');
  String get ikkiuchiBots => t('ikkiuchiBots');
  String get ikkiuchiBotsTag => t('ikkiuchiBotsTag');
  String get ikkiuchiBotsLine => t('ikkiuchiBotsLine');
  String get ikkiuchiCustomLine => t('ikkiuchiCustomLine');

  /// The bots page: its line about the bots.
  String get ikkiuchiBotsIntro => t('ikkiuchiBotsIntro');

  /// A ranked mode's name, and a ranked match of it as History names it.
  String ikkiuchiModeName(IkkiuchiMode mode) => switch (mode) {
        IkkiuchiMode.bullet => t('ikkiuchiBullet'),
        IkkiuchiMode.blitz => t('ikkiuchiBlitz'),
        IkkiuchiMode.rapid => t('ikkiuchiRapid'),
      };
  String ikkiuchiModeRanked(IkkiuchiMode mode) => f('ikkiuchiModeRanked', [ikkiuchiModeName(mode)]);

  /// Settings › 寄り道 › 一騎打ち: the rows [mode]'s ranked matches are laid
  /// out in, and a choice of [n] rows.
  String ikkiuchiRowsTitle(IkkiuchiMode mode) => f('ikkiuchiRowsTitle', [ikkiuchiModeName(mode)]);
  String ikkiuchiRowsNote(IkkiuchiMode mode) => f('ikkiuchiRowsNote', [ikkiuchiModeName(mode)]);
  String ikkiuchiRowsKey(int n) => f(countKey('ikkiuchiRowsKey', n), [n]);

  /// Custom matches: their name, Tobi's rating, the cards a side as a
  /// label and as a template ({0}×2), the burst that plays [n] a side, and
  /// the field preview's label.
  String get ikkiuchiCustom => t('ikkiuchiCustom');
  String get ikkiuchiTobiRating => t('ikkiuchiTobiRating');
  String get ikkiuchiPerSide => t('ikkiuchiPerSide');
  String get ikkiuchiPerSideCount => t('ikkiuchiPerSideCount');
  String ikkiuchiPlayCards(int n) => f('ikkiuchiPlayCards', [n]);
  String ikkiuchiPreviewLabel(int n) => f('ikkiuchiPreviewLabel', [n]);

  /// The custom sheet: the steppers' labels, the cards section's label,
  /// its burst, and guest mode's title and line.
  String get ikkiuchiAnyRating => t('ikkiuchiAnyRating');
  String get ikkiuchiAnyCount => t('ikkiuchiAnyCount');
  String get ikkiuchiCardsPerSide => t('ikkiuchiCardsPerSide');
  String get ikkiuchiConfirm => t('ikkiuchiConfirm');
  String get ikkiuchiGuestMode => t('ikkiuchiGuestMode');
  String get ikkiuchiGuestLine => t('ikkiuchiGuestLine');

  /// The rules (遊び方): the match, how it is won, 送り札, faults, からふだ
  /// ([karafuda] for every [field] cards), ranked's modes (each mode's
  /// cards a side and memory time, in [IkkiuchiMode]'s order), placement
  /// ([matches] from [start]), the rating after it, and custom matches.
  String get ikkiuchiRuleMatch => t('ikkiuchiRuleMatch');
  String get ikkiuchiRuleWin => t('ikkiuchiRuleWin');
  String get ikkiuchiRuleSend => t('ikkiuchiRuleSend');
  String get ikkiuchiRuleFault => t('ikkiuchiRuleFault');
  String ikkiuchiRuleKarafuda(int karafuda, int field) => f('ikkiuchiRuleKarafuda', [karafuda, field]);
  String ikkiuchiRuleRanked(List<({int perSide, String memory})> modes) =>
      f('ikkiuchiRuleRanked', [for (final m in modes) ...[m.perSide, m.memory]]);
  String ikkiuchiRulePlacement(int matches, int start) => f('ikkiuchiRulePlacement', [matches, start]);
  String get ikkiuchiRuleRating => t('ikkiuchiRuleRating');
  String get ikkiuchiRuleCustom => t('ikkiuchiRuleCustom');

  /// Asking before a ranked match is left once it counts: the question,
  /// what leaving does, and the two answers.
  String get ikkiuchiLeaveTitle => t('ikkiuchiLeaveTitle');
  String get ikkiuchiLeaveNote => t('ikkiuchiLeaveNote');
  String get ikkiuchiLeave => t('ikkiuchiLeave');
  String get ikkiuchiKeepPlaying => t('ikkiuchiKeepPlaying');

  /// How a read ended, its parts joined: あなたの取り・トビのお手つき.
  String ikkiuchiFeedback(List<IkkiuchiCallout> parts) => [
        for (final p in parts)
          switch (p) {
            IkkiuchiCallout.tied => t('ikkiuchiTied'),
            IkkiuchiCallout.karafuda => ikkiuchiKarafuda,
            IkkiuchiCallout.youTook => t('ikkiuchiYouTook'),
            IkkiuchiCallout.tobiTook => t('ikkiuchiTobiTook'),
            IkkiuchiCallout.yourFault => t('ikkiuchiYourFault'),
            IkkiuchiCallout.yourDoubleFault => t('ikkiuchiYourDoubleFault'),
            IkkiuchiCallout.tobiFault => t('ikkiuchiTobiFault'),
            IkkiuchiCallout.tobiDoubleFault => t('ikkiuchiTobiDoubleFault'),
          },
      ].join(t('ikkiuchiFeedbackJoin'));

  /// The tag on a card dragged over Tobi's side, Tobi's word as his card
  /// waits, and how to place it, under its tag.
  String get ikkiuchiToTobi => t('ikkiuchiToTobi');
  String get ikkiuchiHereYouGo => t('ikkiuchiHereYouGo');
  String get ikkiuchiSentHint => t('ikkiuchiSentHint');

  String ikkiuchiRowName(FieldRow row) => switch (row) {
        FieldRow.lower => t('ikkiuchiRowLower'),
        FieldRow.middle => t('ikkiuchiRowMiddle'),
        FieldRow.upper => t('ikkiuchiRowUpper'),
      };

  /// A place on the player's side: its row, and its group or open middle.
  String ikkiuchiSpotName(FieldRow row, RowPart part) => f(
        switch (part) {
          RowPart.left => 'ikkiuchiSpotLeft',
          RowPart.middle => 'ikkiuchiSpotMiddle',
          RowPart.right => 'ikkiuchiSpotRight',
        },
        [ikkiuchiRowName(row)],
      );

  /// The name on the open middle's dashed spot.
  String get ikkiuchiOpenMiddle => t('ikkiuchiOpenMiddle');

  /// How a match ended: won, lost or given up.
  String ikkiuchiResult(IkkiuchiResult r) => switch (r) {
        IkkiuchiResult.won => ikkiuchiWon,
        IkkiuchiResult.lost => ikkiuchiLost,
        IkkiuchiResult.gaveUp => t('ikkiuchiGaveUp'),
      };

  /// History's row of a match: its setup ([memory] as m:ss), its faults,
  /// and the caption under the cards left on each side.
  String ikkiuchiSetupLine(int perSide, String memory, int rating) =>
      f('ikkiuchiSetupLine', [perSide, memory, rating]);
  String ikkiuchiFaultsLine(int you, int tobi) => f('ikkiuchiFaultsLine', [you, tobi]);
  String get ikkiuchiLeftCaption => t('ikkiuchiLeftCaption');

  /// A match's page: its tabs, and Tobi at his rating ([rating]) in its
  /// header and stamp.
  String get ikkiuchiTabOverview => t('ikkiuchiTabOverview');
  String get ikkiuchiTabField => t('ikkiuchiTabField');
  String get ikkiuchiTabSpeed => t('ikkiuchiTabSpeed');
  String get ikkiuchiTabRating => t('ikkiuchiTabRating');
  String get ikkiuchiTabReads => t('ikkiuchiTabReads');
  String ikkiuchiTobiAt(int rating) => f('ikkiuchiTobiAt', [rating]);

  /// The Overview: the hero's bar (each one's takes, or both in a line and
  /// the cards [n] left), the tiles' labels and notes (the [n] reads,
  /// Tobi's [n] faults and his median take, [seconds]).
  String ikkiuchiTookCount(int n) => f('ikkiuchiTookCount', [n]);
  String ikkiuchiTobiTookCount(int n) => f('ikkiuchiTobiTookCount', [n]);
  String ikkiuchiTakesBoth(int you, int tobi) => f('ikkiuchiTakesBoth', [you, tobi]);
  String ikkiuchiLeftCount(int n) => f('ikkiuchiLeftCount', [n]);
  String get ikkiuchiResultLabel => t('ikkiuchiResultLabel');
  String get ikkiuchiMatchTime => t('ikkiuchiMatchTime');
  String ikkiuchiReadCount(int n) => f(countKey('ikkiuchiReadCount', n), [n]);
  String get ikkiuchiFaultsLabel => t('ikkiuchiFaultsLabel');
  String ikkiuchiTobiTimes(int n) => f('ikkiuchiTobiTimes', [n]);
  String get ikkiuchiRatingLabel => t('ikkiuchiRatingLabel');
  String get ikkiuchiMedianTake => t('ikkiuchiMedianTake');
  String ikkiuchiTobiSeconds(String seconds) => f('ikkiuchiTobiSeconds', [seconds]);

  /// The Overview's panels: the cards Tobi took that the player reached
  /// too, and the match against the last one with the same setup ([n]
  /// cards a side), its rows and how this one compares ([n] cards or
  /// faults, [seconds]).
  String get ikkiuchiBeatenTitle => t('ikkiuchiBeatenTitle');
  String get ikkiuchiBeatenNote => t('ikkiuchiBeatenNote');
  String get ikkiuchiSameSetup => t('ikkiuchiSameSetup');
  String ikkiuchiPerSideOf(int n) => f('ikkiuchiPerSideCount', [n]);
  String get ikkiuchiColThis => t('ikkiuchiColThis');
  String get ikkiuchiRowTaken => t('ikkiuchiRowTaken');
  String ikkiuchiMoreTaken(int n) => f('ikkiuchiMoreTaken', [n]);
  String ikkiuchiFewerTaken(int n) => f('ikkiuchiFewerTaken', [n]);
  String ikkiuchiFewerFaults(int n) => f('ikkiuchiFewerFaults', [n]);
  String ikkiuchiMoreFaults(int n) => f('ikkiuchiMoreFaults', [n]);
  String get ikkiuchiSame => t('ikkiuchiSame');
  String ikkiuchiFaster(String seconds) => f('ikkiuchiFaster', [seconds]);
  String ikkiuchiSlower(String seconds) => f('ikkiuchiSlower', [seconds]);
  String get ikkiuchiSetupFirst => t('ikkiuchiSetupFirst');

  /// The Field: its panel, its label, the band's sides, the review's
  /// button, its step box (read [n] of [count], the side and row a card
  /// lay in, the touches' chips, both times as [you] and [tobi] in
  /// [seconds], the 送り札 to and from Tobi, the names joined, a fault on a
  /// look-alike by [who]), the touches' legend, the tiles' label and the
  /// caption.
  String get ikkiuchiFieldTitle => t('ikkiuchiFieldTitle');
  String get ikkiuchiFieldNote => t('ikkiuchiFieldNote');
  String get ikkiuchiFieldLabel => t('ikkiuchiFieldLabel');

  /// Who took a card in the end, in the Field's and the chart's legends.
  String get ikkiuchiYouTook => t('ikkiuchiYouTook');
  String get ikkiuchiTobiTook => t('ikkiuchiTobiTook');
  String get ikkiuchiTheirSide => t('ikkiuchiTheirSide');
  String get ikkiuchiOwnSide => t('ikkiuchiOwnSide');
  String get ikkiuchiStartReview => t('ikkiuchiStartReview');
  String get ikkiuchiShowAll => t('ikkiuchiShowAll');
  String ikkiuchiStepRead(int n, int count) => f('ikkiuchiStepRead', [n, count]);
  String get ikkiuchiStepBack => t('ikkiuchiStepBack');
  String get ikkiuchiStepNext => t('ikkiuchiStepNext');
  String get ikkiuchiBoxPlace => t('ikkiuchiBoxPlace');
  String get ikkiuchiBoxTouches => t('ikkiuchiBoxTouches');
  String get ikkiuchiBoxTime => t('ikkiuchiBoxTime');
  String get ikkiuchiOffField => t('ikkiuchiOffField');
  String ikkiuchiSideRow(String side, String row) => f('ikkiuchiSideRow', [side, row]);
  String get ikkiuchiNoTouches => t('ikkiuchiNoTouches');
  String get ikkiuchiYourFaultChip => t('ikkiuchiYourFaultChip');
  String get ikkiuchiTobiFaultChip => t('ikkiuchiTobiFaultChip');
  String ikkiuchiBoxTimes(String you, String tobi) => f('ikkiuchiBoxTimes', [you, tobi]);
  String ikkiuchiBoxSeconds(String seconds) => f('ikkiuchiBoxSeconds', [seconds]);
  String ikkiuchiSentTo(String cards) => f('ikkiuchiSentTo', [cards]);
  String ikkiuchiSentFrom(String cards) => f('ikkiuchiSentFrom', [cards]);
  String get ikkiuchiSentNone => t('ikkiuchiSentNone');
  String get ikkiuchiNamesJoin => t('ikkiuchiNamesJoin');
  String ikkiuchiLookAlike(String who, String card) => f('ikkiuchiLookAlike', [who, card]);
  String get ikkiuchiFirstTouch => t('ikkiuchiFirstTouch');
  String get ikkiuchiSecondTouch => t('ikkiuchiSecondTouch');
  String get ikkiuchiTileTakes => t('ikkiuchiTileTakes');
  String get ikkiuchiFieldCaption => t('ikkiuchiFieldCaption');

  /// The Speed tab: the chart, its caption, both medians with the takes
  /// and faults under them, how they compare ([seconds]), the rows by
  /// kimariji length ([n] kana, [cards] read and [took]), and the fastest
  /// takes.
  String get ikkiuchiTakesTitle => t('ikkiuchiTakesTitle');
  String get ikkiuchiSeconds => t('ikkiuchiSeconds');
  String get ikkiuchiTobiMedian => t('ikkiuchiTobiMedian');
  String get ikkiuchiYourMedian => t('ikkiuchiYourMedian');
  String get ikkiuchiTakesCaption => t('ikkiuchiTakesCaption');
  String ikkiuchiTakesFaults(int taken, int faults) =>
      f(countKey('ikkiuchiTakesFaults', faults), [taken, faults]);
  String ikkiuchiFasterThanTobi(String seconds) => f('ikkiuchiFasterThanTobi', [seconds]);
  String ikkiuchiSlowerThanTobi(String seconds) => f('ikkiuchiSlowerThanTobi', [seconds]);
  String get ikkiuchiByLength => t('ikkiuchiByLength');
  String get ikkiuchiTickTobi => t('ikkiuchiTickTobi');
  String ikkiuchiKimarijiLength(int n) => f('ikkiuchiKimarijiLength', [n]);
  String ikkiuchiLengthNote(int cards, int took) => f(countKey('ikkiuchiLengthNote', cards), [cards, took]);
  String get ikkiuchiFastestTitle => t('ikkiuchiFastestTitle');

  /// The Rating & XP tab: the rating's hero and its lines (the estimate's
  /// while placing), the placement as its bar ([n] of [count] played, [n]
  /// left), the class label ([points] to [band] at [rating]), and a free
  /// match's panel.
  String get ikkiuchiRatingHead => t('ikkiuchiRatingHead');
  String get ikkiuchiPreviousRating => t('ikkiuchiPreviousRating');
  String get ikkiuchiNewRating => t('ikkiuchiNewRating');
  String get ikkiuchiPreviousEstimate => t('ikkiuchiPreviousEstimate');
  String get ikkiuchiNewEstimate => t('ikkiuchiNewEstimate');
  String get ikkiuchiFirstRating => t('ikkiuchiFirstRating');
  String ikkiuchiPlacing(int n, int count) => f('ikkiuchiPlacing', [n, count]);
  String ikkiuchiPlacedIn(int n) => f('ikkiuchiPlacedIn', [n]);
  String ikkiuchiClassAt(int points, RankBand band, String rating) =>
      f('ikkiuchiClassAt', [points, className(band), rating]);
  String get ikkiuchiFree => t('ikkiuchiFree');
  String get ikkiuchiNoRank => t('ikkiuchiNoRank');
  String get ikkiuchiOnlyRanked => t('ikkiuchiOnlyRanked');

  /// Every read: the panel, its table's heads, a side's faults on a read,
  /// the medians' row, the caption under it, and the line for a match with
  /// none.
  String get ikkiuchiReadsTitle => t('ikkiuchiReadsTitle');
  String ikkiuchiReadsNote(int n) => f(countKey('ikkiuchiReadsNote', n), [n]);
  String get ikkiuchiColNumber => t('ikkiuchiColNumber');
  String get ikkiuchiColCard => t('ikkiuchiColCard');
  String get ikkiuchiColSide => t('ikkiuchiColSide');
  String get ikkiuchiColTaken => t('ikkiuchiColTaken');
  String get ikkiuchiTied => t('ikkiuchiTied');
  String ikkiuchiFaultCount(int n) => f(countKey('ikkiuchiFaultCount', n), [n]);
  String get ikkiuchiMedianRow => t('ikkiuchiMedianRow');
  String get ikkiuchiReadsCaption => t('ikkiuchiReadsCaption');
  String get ikkiuchiNoReads => t('ikkiuchiNoReads');
}
