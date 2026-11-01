import 'strings.dart';

/// Strings of History's 定位置 game page; the rest it shares with the
/// 暗記練 game page's.
extension TeiichiReviewStrings on S {
  String get teiichiTabPlacing => t('teiichiTabPlacing');

  /// A game's setup: "25 cards · 3 rows".
  String teiichiSetupLine(int cards, int rows) => f(countKey('teiichiSetupLine', rows), [cards, rows]);

  /// The Overview: a best placing time's stamp and the best it beat, the
  /// best when the game was played, a game that does not count for it, and
  /// wrong taps against the last game.
  String get teiichiBestStamp => t('teiichiBestStamp');
  String teiichiBestWas(String time) => f('teiichiBestWas', [time]);
  String teiichiBestThen(String time) => f('teiichiBestThen', [time]);
  String get teiichiNotCounted => t('teiichiNotCounted');
  String teiichiMoreTaps(int n) => f('teiichiMoreTaps', [n]);
  String teiichiFewerTaps(int n) => f('teiichiFewerTaps', [n]);

  /// The Field's tiles of the left and right groups, and what they leave
  /// out.
  String get teiichiGroupLeft => t('teiichiGroupLeft');
  String get teiichiGroupRight => t('teiichiGroupRight');
  String get teiichiMiddleNeither => t('teiichiMiddleNeither');

  /// Placing: the layout numbered in the order placed, and the placing
  /// times.
  String get teiichiLayoutTitle => t('teiichiLayoutTitle');
  String get teiichiLayoutNote => t('teiichiLayoutNote');
  String get teiichiLayoutLabel => t('teiichiLayoutLabel');
  String get teiichiTimesTitle => t('teiichiTimesTitle');
  String get teiichiTimesCaption => t('teiichiTimesCaption');

  /// Taps: what its marked rows are.
  String get teiichiTapsCaption => t('teiichiTapsCaption');

  /// The level games' name in the filter, and the Score: the cards never
  /// placed and what they earn, what a forfeit counts as, and the placing
  /// time in the sum.
  String get teiichiKindLevels => t('teiichiKindLevels');
  String get teiichiPartUnplaced => t('teiichiPartUnplaced');
  String get teiichiUnplacedTitle => t('teiichiUnplacedTitle');
  String get teiichiUnplacedPoints => t('teiichiUnplacedPoints');
  String get teiichiForfeitPoints => t('teiichiForfeitPoints');
  String teiichiEqPlaced(String time) => f('teiichiEqPlaced', [time]);
}
