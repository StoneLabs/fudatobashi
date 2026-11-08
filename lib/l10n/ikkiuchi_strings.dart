import '../domain/field_parts.dart';
import '../domain/ikkiuchi_match.dart';
import '../domain/ikkiuchi_record.dart';
import 'strings.dart';

/// Strings of 一騎打ち: its page, its custom sheet and rules, the memory
/// time, the greetings, the 送り札 on the band, Tobi's word as his card
/// waits, the names of the places a card may go on the player's side, the
/// game column, a からふだ's tag, how a read ended, and History's list of
/// matches and a match's page.
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

  /// The players' greeting as play begins, and their thanks once it is over.
  String get ikkiuchiGreeting => t('ikkiuchiGreeting');
  String get ikkiuchiThanks => t('ikkiuchiThanks');

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

  /// How a match ended for the player, won or lost; also the page's
  /// played placement matches.
  String get ikkiuchiWon => t('ikkiuchiWon');
  String get ikkiuchiLost => t('ikkiuchiLost');

  /// The page's class strip: the wins of the last ranked matches, and the
  /// average card margin.
  String get ikkiuchiWins => t('ikkiuchiWins');
  String get ikkiuchiMargin => t('ikkiuchiMargin');

  /// The page's ranked panel: its tag, and placement's heading and the
  /// mark under the next placement match.
  String get ikkiuchiRankedMode => t('ikkiuchiRankedMode');
  String get ikkiuchiPlacementTitle => t('ikkiuchiPlacementTitle');
  String get ikkiuchiPlacementNext => t('ikkiuchiPlacementNext');

  /// The page's custom panel: its tag, the button to its sheet, its facts'
  /// labels, the templates of the cards a side ({0}×2) and the からふだ read,
  /// the burst that plays [n] a side, and the field preview's label.
  String get ikkiuchiCustom => t('ikkiuchiCustom');
  String get ikkiuchiCustomSetup => t('ikkiuchiCustomSetup');
  String get ikkiuchiTobiRating => t('ikkiuchiTobiRating');
  String get ikkiuchiPerSide => t('ikkiuchiPerSide');
  String get ikkiuchiPerSideCount => t('ikkiuchiPerSideCount');
  String get ikkiuchiKarafudaLine => t('ikkiuchiKarafudaLine');
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

  /// The rules (遊び方): the match with [perSide] cards a side, how it is
  /// won, 送り札, faults, からふだ ([karafuda] for every [field] cards),
  /// ranked's setup ([memory] to learn the field), placement ([matches]
  /// from [start]), the rating after it, and custom matches.
  String ikkiuchiRuleMatch(int perSide) => f('ikkiuchiRuleMatch', [perSide]);
  String get ikkiuchiRuleWin => t('ikkiuchiRuleWin');
  String get ikkiuchiRuleSend => t('ikkiuchiRuleSend');
  String get ikkiuchiRuleFault => t('ikkiuchiRuleFault');
  String ikkiuchiRuleKarafuda(int karafuda, int field) => f('ikkiuchiRuleKarafuda', [karafuda, field]);
  String ikkiuchiRuleRanked(int perSide, String memory) => f('ikkiuchiRuleRanked', [perSide, memory]);
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

  /// The tag on a card dragged over Tobi's side, and Tobi's word as his
  /// card waits.
  String get ikkiuchiToTobi => t('ikkiuchiToTobi');
  String get ikkiuchiHereYouGo => t('ikkiuchiHereYouGo');

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

  /// A match's page: the summary's facts.
  String get ikkiuchiResultLabel => t('ikkiuchiResultLabel');
  String get ikkiuchiYourLeft => t('ikkiuchiYourLeft');
  String get ikkiuchiTobiLeft => t('ikkiuchiTobiLeft');
  String get ikkiuchiMatchTime => t('ikkiuchiMatchTime');
  String get ikkiuchiYourFaults => t('ikkiuchiYourFaults');
  String get ikkiuchiTobiFaults => t('ikkiuchiTobiFaults');

  /// A match's page: the reads' panel, its table's heads, a side's faults
  /// on a read, the caption under it, and the line for a match with none.
  String get ikkiuchiReadsTitle => t('ikkiuchiReadsTitle');
  String ikkiuchiReadsNote(int n) => f(countKey('ikkiuchiReadsNote', n), [n]);
  String get ikkiuchiColNumber => t('ikkiuchiColNumber');
  String get ikkiuchiColCard => t('ikkiuchiColCard');
  String get ikkiuchiColTaken => t('ikkiuchiColTaken');
  String get ikkiuchiTied => t('ikkiuchiTied');
  String ikkiuchiFaultCount(int n) => f(countKey('ikkiuchiFaultCount', n), [n]);
  String get ikkiuchiReadsCaption => t('ikkiuchiReadsCaption');
  String get ikkiuchiNoReads => t('ikkiuchiNoReads');
}
