// 一騎打ち's Tobi: his curves read by rating.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ikkiuchi_curve.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';

void main() {
  group('a curve', () {
    const plain = IkkiuchiCurve([(0, 10), (1000, 20), (3000, 0)]);
    const log = IkkiuchiCurve.log([(0, 1000), (2000, 10)]);

    test('gives each anchor its value exactly', () {
      expect(plain.at(0), 10);
      expect(plain.at(1000), 20);
      expect(plain.at(3000), 0);
      expect(log.at(2000), 10);
    });

    test('reads plain anchors in straight lines', () {
      expect(plain.at(500), closeTo(15, 1e-9));
      expect(plain.at(2500), closeTo(5, 1e-9));
    });

    test('reads log anchors straight on a log scale', () {
      expect(log.at(1000), closeTo(100, 1e-9));
      expect(log.at(500), closeTo(1000 * math.pow(0.01, 0.25), 1e-9));
    });

    test('is held flat past its ends', () {
      expect(plain.at(-500), 10);
      expect(plain.at(9999), 0);
      expect(log.at(-1), 1000);
      expect(log.at(3600), 10);
    });
  });

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
      'placingSeconds': IkkiuchiTuning.placingSeconds,
      'sweepShare': IkkiuchiTuning.sweepShare,
      'grouping': IkkiuchiLayoutTuning.grouping,
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
      for (final curve in [IkkiuchiTuning.takeMs, IkkiuchiTuning.searchMs, IkkiuchiTuning.armMs]) {
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

    test('his reach falls straight between its ends, and no hit goes under the floor', () {
      const reach = IkkiuchiTuning.reachMs;
      final (r0, v0) = reach.anchors.first;
      final (r1, v1) = reach.anchors.last;
      expect(reach.scale, CurveScale.plain);
      expect(IkkiuchiTobi((r0 + r1) / 2).reachMs, closeTo((v0 + v1) / 2, 1e-9));
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
