import '../config/config.dart';

/// A class (級) of the [RankLadder].
class RankBand {
  const RankBand(this.id, this.label, this.labelEn, this.minRating);

  final String id;

  /// e.g. "F下級". The 上/下 split echoes 上の句 / 下の句.
  final String label;
  final String labelEn;

  /// The rating at or above which the class is reached (−∞ for 入門).
  final double minRating;

  /// The 級 that ends every class's [label] but 入門's.
  static const classSuffix = '級';

  /// [label] without its [classSuffix], e.g. "F上"; 入門 as it is.
  String get stem => label.endsWith(classSuffix) ? label.substring(0, label.length - classSuffix.length) : label;

  /// The whole points [rating] still needs to reach this class (0 once
  /// reached).
  int pointsLeft(double rating) => rating >= minRating ? 0 : (minRating - rating).ceil();
}

/// The class a rating sits in, the next one, and how far toward it (0–1).
typedef ClassProgress = ({RankBand band, RankBand? next, double fraction});

/// The classes every ranked mode rates on, lowest first.
abstract final class RankLadder {
  static const bands = [
    RankBand('nyumon', '入門', 'Novice', double.negativeInfinity),
    RankBand('F-', 'F下級', 'F-', RankLadderTuning.fLowerMinRating),
    RankBand('F+', 'F上級', 'F+', RankLadderTuning.fUpperMinRating),
    RankBand('E-', 'E下級', 'E-', RankLadderTuning.eLowerMinRating),
    RankBand('E+', 'E上級', 'E+', RankLadderTuning.eUpperMinRating),
    RankBand('D', 'D級', 'D', RankLadderTuning.dMinRating),
    RankBand('C', 'C級', 'C', RankLadderTuning.cMinRating),
    RankBand('B', 'B級', 'B', RankLadderTuning.bMinRating),
    RankBand('A', 'A級', 'A', RankLadderTuning.aMinRating),
  ];

  static RankBand bandOf(double rating) => bands.lastWhere((b) => rating >= b.minRating, orElse: () => bands.first);

  static RankBand? nextBand(double rating) {
    final i = bands.indexOf(bandOf(rating));
    return i + 1 < bands.length ? bands[i + 1] : null;
  }

  /// [rating]'s class, the next one and how far toward it, from the class's
  /// threshold ([floor] for 入門, which has none).
  static ClassProgress progress(double rating, {required double floor}) {
    final band = bandOf(rating);
    final next = nextBand(rating);
    final from = band.minRating.isFinite ? band.minRating : floor;
    final fraction = next == null ? 1.0 : ((rating - from) / (next.minRating - from)).clamp(0.0, 1.0);
    return (band: band, next: next, fraction: fraction);
  }
}
