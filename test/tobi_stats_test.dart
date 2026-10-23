import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/ui/debug/tobi_stats.dart';

void main() {
  test('Tobi card times: fixed seed, mean inside his per-card range, spread above zero', () {
    final a = TobiExamStats.sample(draws: 300, seed: 5);
    final b = TobiExamStats.sample(draws: 300, seed: 5);
    expect(a.mean, b.mean);
    expect(a.mean, inInclusiveRange(ExamTuning.tobiMinMs / RankedTuning.cards, ExamTuning.tobiMaxMs / RankedTuning.cards));
    expect(a.sd, greaterThan(0));
  });
}
