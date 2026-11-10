// The class ladder every ranked mode shares: whole, rising thresholds, the
// class a rating sits in, and the points and progress to the next one.
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/domain/rank_ladder.dart';

void main() {
  test('the classes start at whole, rising ratings; 入門 has none', () {
    const bands = RankLadder.bands;
    expect(bands.first.minRating, double.negativeInfinity);
    for (var i = 1; i < bands.length; i++) {
      expect(bands[i].minRating, bands[i].minRating.roundToDouble(), reason: bands[i].labelEn);
      expect(bands[i].minRating, greaterThan(bands[i - 1].minRating), reason: bands[i].labelEn);
    }
  });

  test('a class starts at its threshold', () {
    expect(RankLadder.bandOf(2434.9).label, 'D級');
    expect(RankLadder.bandOf(2435).label, 'C級');
    expect(RankLadder.nextBand(2434.9)?.label, 'C級');
    expect(RankLadder.nextBand(RankLadder.bands.last.minRating), isNull);
  });

  test('points left are the threshold minus the rating', () {
    final next = RankLadder.nextBand(2300)!;
    expect(next.label, 'C級');
    expect(next.pointsLeft(2300), 135);
    expect(next.pointsLeft(2434.9), 1);
    expect(next.pointsLeft(next.minRating), 0);
  });

  test('progress runs from the class threshold, 入門 from the floor given', () {
    const bands = RankLadder.bands;
    final mid = (bands[2].minRating + bands[3].minRating) / 2;
    expect(RankLadder.progress(mid, floor: 0), (band: bands[2], next: bands[3], fraction: 0.5));
    expect(RankLadder.progress(bands[1].minRating / 2, floor: 0).fraction, 0.5);
    expect(RankLadder.progress(bands.last.minRating, floor: 0), (band: bands.last, next: null, fraction: 1.0));
  });
}
