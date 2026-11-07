import '../domain/field_parts.dart';
import 'strings.dart';

/// Strings of 一騎打ち: the memory time, the greetings, the 送り札 on the band, Tobi's word as his card
/// waits, the names of the places a card may go on the player's side, the
/// game column, and a からふだ's tag.
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

  /// The score's names.
  String get ikkiuchiTobi => t('ikkiuchiTobi');
  String get ikkiuchiYou => t('ikkiuchiYou');

  /// The tag before the words of a からふだ read.
  String get ikkiuchiKarafuda => t('ikkiuchiKarafuda');

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
}
