// 一騎打ち's Tobi: his curves read by rating.
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/domain/tuning_curve.dart';

void main() {
  group("Tobi's curves", () {
    final curves = {
      'takeMs': IkkiuchiTuning.takeMs,
      'takeSpread': IkkiuchiTuning.takeSpread,
      'blankChance': IkkiuchiTuning.blankChance,
      'searchMs': IkkiuchiTuning.searchMs,
      'lookAlikePull': IkkiuchiTuning.lookAlikePull,
      'armMs': IkkiuchiTuning.armMs,
      'reachMs': IkkiuchiTuning.reachMs,
      'smartSend': IkkiuchiTuning.smartSend,
      'placingMsPerCard': IkkiuchiTuning.placingMsPerCard,
      'sweepShare': IkkiuchiTuning.sweepShare,
      'soundGrouping': IkkiuchiLayoutTuning.soundGrouping,
      'tomofudaGrouping': IkkiuchiLayoutTuning.tomofudaGrouping,
    };

    test('each runs in rising rating over the rating range, log ones above 0', () {
      for (final MapEntry(key: name, value: curve) in curves.entries) {
        final ratings = [for (final (r, _) in curve.anchors) r];
        expect(ratings.first, IkkiuchiTuning.ratingMin, reason: name);
        expect(ratings.last, IkkiuchiTuning.ratingMax, reason: name);
        for (var i = 1; i < ratings.length; i++) {
          expect(ratings[i], greaterThan(ratings[i - 1]), reason: name);
        }
        if (curve.scale == CurveScale.log) {
          expect(curve.anchors.every((a) => a.$2 > 0), isTrue, reason: name);
        }
      }
    });

    test('each hits its anchors', () {
      for (final MapEntry(key: name, value: curve) in curves.entries) {
        for (final (r, v) in curve.anchors) {
          expect(curve.at(r), v, reason: '$name at $r');
        }
      }
    });

    test('times read on a log scale, chances and shares on a plain one', () {
      for (final curve in [IkkiuchiTuning.takeMs, IkkiuchiTuning.searchMs, IkkiuchiTuning.armMs, IkkiuchiTuning.placingMsPerCard]) {
        expect(curve.scale, CurveScale.log);
      }
      for (final curve in [IkkiuchiTuning.blankChance, IkkiuchiTuning.lookAlikePull, IkkiuchiTuning.sweepShare]) {
        expect(curve.scale, CurveScale.plain);
      }
    });

    test('his arm moves add up to the whole', () {
      for (var r = IkkiuchiTuning.ratingMin; r <= IkkiuchiTuning.ratingMax; r += 100) {
        final m = IkkiuchiTobi(r).moves;
        expect(m.sweep + m.whip + m.coilLunge + m.smear, closeTo(1, 1e-9), reason: '$r');
      }
    });

    test('his reach falls through its anchors, and no hit goes under the floor', () {
      const reach = IkkiuchiTuning.reachMs;
      expect(reach.scale, CurveScale.plain);
      for (final (r, v) in reach.anchors) {
        expect(IkkiuchiTobi(r).reachMs, closeTo(v, 1e-9));
      }
      expect(IkkiuchiTobi(IkkiuchiTuning.ratingMax).reachMs, greaterThanOrEqualTo(IkkiuchiTuning.reachFloorMs));
      const floor = IkkiuchiTuning.reachFloorMs;
      expect(IkkiuchiTobi.hitReach(floor - 40), floor);
      expect(IkkiuchiTobi.hitReach(0), floor);
      expect(IkkiuchiTobi.hitReach(floor + 1), floor + 1);
    });

    test('a stray touch is the set share of the look-alike pull', () {
      const tobi = IkkiuchiTobi(1600);
      expect(tobi.strayChance, closeTo(tobi.lookAlikePull * IkkiuchiTuning.strayShare, 1e-12));
    });
  });
}
