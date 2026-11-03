import '../domain/field_parts.dart';
import 'strings.dart';

/// Strings of 一騎打ち: the 送り札 on the band, Tobi's word as his card
/// waits, and the names of the places a card may go on the player's side.
extension IkkiuchiStrings on S {
  /// The band while a card is sent: its title, and what the player does,
  /// sending one of theirs or placing Tobi's.
  String get ikkiuchiSent => t('ikkiuchiSent');
  String get ikkiuchiSendYours => t('ikkiuchiSendYours');
  String get ikkiuchiPlaceTobis => t('ikkiuchiPlaceTobis');

  /// The tag on a card dragged over Tobi's side, and Tobi's word as his
  /// card waits.
  String get ikkiuchiToTobi => t('ikkiuchiToTobi');
  String get ikkiuchiHereYouGo => t('ikkiuchiHereYouGo');

  String ikkiuchiRowName(FieldRow row) => switch (row) {
        FieldRow.lower => t('ikkiuchiRowLower'),
        FieldRow.middle => t('ikkiuchiRowMiddle'),
        FieldRow.upper => t('ikkiuchiRowUpper'),
      };

  /// A place on the player's side: its row, and its group.
  String ikkiuchiSpotName(FieldRow row, RowPart part) =>
      f(part == RowPart.left ? 'ikkiuchiSpotLeft' : 'ikkiuchiSpotRight', [ikkiuchiRowName(row)]);
}
