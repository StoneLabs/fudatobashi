import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_geometry.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';

void main() {
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final sets = FudaSets(p);
  final tomo = {for (final x in p.all) x.id: sets.tomofuda(x.id)};
  final dealer = AnkirenDealer(tomofuda: (id) => tomo[id]!, kimarijiLength: (id) => p[id].kimariji.length);
  final all = [for (var id = 1; id <= 100; id++) id];
  bool linked(int a, int b) => tomo[a]!.contains(b);

  group('levels', () {
    test('the table: cards per side and memorise time, both growing level by level', () {
      expect([for (final l in AnkirenLevels.all) l.perSide], [4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 25]);
      expect(AnkirenLevels.of(0).memorise, const Duration(seconds: 20));
      expect(AnkirenLevels.of(4).memorise, const Duration(seconds: 90));
      expect(AnkirenLevels.of(AnkirenLevels.top).memorise, const Duration(minutes: 5));
      for (var l = 1; l <= AnkirenLevels.top; l++) {
        expect(AnkirenLevels.of(l).perSide, greaterThan(AnkirenLevels.of(l - 1).perSide));
        expect(AnkirenLevels.of(l).memorise, greaterThan(AnkirenLevels.of(l - 1).memorise));
      }
    });

    test('the known cards cap the level: it needs twice its per-side count', () {
      expect(AnkirenLevels.maxLevelFor(0), isNull);
      expect(AnkirenLevels.maxLevelFor(7), isNull);
      expect(AnkirenLevels.maxLevelFor(8), 0);
      expect(AnkirenLevels.maxLevelFor(11), 0);
      expect(AnkirenLevels.maxLevelFor(12), 1);
      expect(AnkirenLevels.maxLevelFor(24), 4);
      expect(AnkirenLevels.maxLevelFor(25), 4, reason: 'level 4 deals 24 cards');
      expect(AnkirenLevels.maxLevelFor(28), 5);
      expect(AnkirenLevels.maxLevelFor(49), 9);
      expect(AnkirenLevels.maxLevelFor(50), 10);
      expect(AnkirenLevels.maxLevelFor(100), 10);
    });

    test('setups: a preset carries its level, a custom one stays within the known cards', () {
      final preset = AnkirenSetup.forLevel(4, ranked: true);
      expect((preset.perSide, preset.memorise, preset.level, preset.ranked, preset.cards),
          (12, const Duration(seconds: 90), 4, true, 24));
      expect(preset, AnkirenSetup.forLevel(4, ranked: true));
      expect(preset, isNot(AnkirenSetup.forLevel(4)));
      const custom = AnkirenSetup.custom(perSide: 7, memorise: Duration(seconds: 40));
      expect((custom.level, custom.ranked), (null, false));

      expect(AnkirenSetup.maxCustomPerSide(3), isNull);
      expect(AnkirenSetup.maxCustomPerSide(4), 2);
      expect(AnkirenSetup.maxCustomPerSide(31), 15);
      expect(AnkirenSetup.maxCustomPerSide(100), 25);
    });

    test('custom memorise times: 10 s steps to a minute, then 30 s steps to 15 minutes', () {
      final options = AnkirenSetup.memoriseOptions;
      expect(options.first, const Duration(seconds: 10));
      expect(options.last, const Duration(minutes: 15));
      expect(options.take(6), [for (var s = 10; s <= 60; s += 10) Duration(seconds: s)]);
      expect(options, contains(const Duration(seconds: 90)));
      expect(options, isNot(contains(const Duration(seconds: 70))));
      expect(options.length, 6 + 28);
    });
  });

  group('row split', () {
    test('下段 fills first, 中段 never outnumbers it, 上段 is the sparsest', () {
      expect(AnkirenDealer.rowCounts(25), [9, 9, 7]);
      expect(AnkirenDealer.rowCounts(12), [4, 4, 4]);
      expect(AnkirenDealer.rowCounts(4), [2, 2, 0]);
      expect(AnkirenDealer.rowCounts(1), [1, 0, 0]);
      for (var c = 0; c <= AnkirenTuning.customMaxPerSide; c++) {
        final [lower, middle, upper] = AnkirenDealer.rowCounts(c);
        expect(lower + middle + upper, c);
        expect(lower >= middle && middle >= upper && upper >= 0, isTrue, reason: '$c: $lower/$middle/$upper');
      }
    });

    test('an odd row puts its extra card left, except 中段 which puts it right', () {
      expect(AnkirenDealer.leftCount(FieldRow.lower, 5), 3);
      expect(AnkirenDealer.leftCount(FieldRow.middle, 5), 2);
      expect(AnkirenDealer.leftCount(FieldRow.upper, 5), 3);
      expect(AnkirenDealer.leftCount(FieldRow.middle, 4), 2);
    });
  });

  group('dealer', () {
    /// Everything a dealt field must satisfy; returns what it breaks.
    List<String> problems(AnkirenField f, List<int> known, int perSide) {
      final out = <String>[];
      final field = f.cards.toSet();
      if (field.length != 2 * perSide) out.add('field has ${field.length} distinct cards');
      if (!field.every(known.contains)) out.add('an unknown card was dealt');
      for (final side in FieldSide.values) {
        final half = f.half(side);
        final cards = half.cards;
        if (cards.length != perSide) out.add('$side has ${cards.length} cards');

        final middle = half.middleCards;
        final k = middle.length;
        if (k > 0) {
          final rows = [for (final r in FieldRow.values) if (half.row(r).middle.isNotEmpty) r];
          if (rows.length != 1 || !AnkirenTuning.middleRows.contains(rows.single)) out.add('$side middle rows $rows');
          if (k < AnkirenTuning.middleMin || k > math.min(AnkirenTuning.middleMax, perSide ~/ 2)) {
            out.add('$side has $k middle cards');
          }
          for (final a in middle) {
            if (middle.any((b) => linked(a, b))) out.add('$side middle holds a 友札 pair');
          }
          final paired = cards.any((c) => tomo[c]!.any(field.contains));
          if (paired && !middle.any((c) => tomo[c]!.any(field.contains))) out.add('$side middle skipped the 友札');
        }

        final counts = [for (final r in half.rows) r.left.length + r.right.length];
        if (counts.toString() != AnkirenDealer.rowCounts(perSide - k).toString()) out.add('$side rows $counts');
        for (final r in FieldRow.values) {
          final row = half.row(r);
          if (row.left.length != AnkirenDealer.leftCount(r, counts[r.index])) out.add('$side $r left/right split');
        }

        for (final cluster in [half.rows.map((r) => r.left), half.rows.map((r) => r.right)]) {
          final lengths = [for (final row in cluster) row.map((c) => p[c].kimariji.length).toList()];
          for (var r = 1; r < lengths.length; r++) {
            final below = lengths.take(r).expand((l) => l);
            if (below.isNotEmpty && lengths[r].isNotEmpty && below.reduce(math.max) > lengths[r].reduce(math.min)) {
              out.add('$side: a longer kimariji sits below a shorter one');
            }
          }
        }

        final left = {for (final r in half.rows) ...r.left}, right = {for (final r in half.rows) ...r.right};
        final clustered = {...left, ...right};
        bool single(int c) => !clustered.any((o) => linked(c, o));
        for (final c in clustered) {
          final family = {c, ...tomo[c]!.where(clustered.contains)};
          final inLeft = family.where(left.contains).length, inRight = family.length - inLeft;
          final short = inLeft - inRight >= 2 ? right : inRight - inLeft >= 2 ? left : null;
          if (short != null && short.any(single)) out.add('$side left a 友札 family together: $family');
        }
      }
      return out;
    }

    test('20 000 games per level: sound fields, about 1 in 5 with middle cards', () {
      const games = 20000;
      for (final level in [0, 2, 4, 7, 10]) {
        final perSide = AnkirenLevels.of(level).perSide;
        final rng = math.Random(level);
        final found = <String>{};
        var sidesWithMiddle = 0, gamesWithMiddle = 0, maxMiddle = 0;
        final middleRows = <FieldRow>{};
        for (var g = 0; g < games; g++) {
          final known = level.isEven ? all : all.sublist(0, AnkirenLevels.of(level).cards + g % 7);
          final f = dealer.deal(known, perSide, rng);
          found.addAll(problems(f, known, perSide));
          final withMiddle = FieldSide.values.where((s) => f.half(s).middleCards.isNotEmpty).length;
          sidesWithMiddle += withMiddle;
          if (withMiddle > 0) gamesWithMiddle++;
          for (final s in FieldSide.values) {
            maxMiddle = math.max(maxMiddle, f.half(s).middleCards.length);
            if (f.half(s).middleRow case final r?) middleRows.add(r);
          }
        }
        expect(found, isEmpty, reason: 'level $level');
        final perSideChance = sidesWithMiddle / (2 * games);
        expect(perSideChance, closeTo(AnkirenTuning.middleChancePerSide, 0.008), reason: 'level $level');
        final anySide = 1 - math.pow(1 - AnkirenTuning.middleChancePerSide, 2);
        expect(gamesWithMiddle / games, closeTo(anySide, 0.012), reason: 'level $level');
        expect(maxMiddle, math.min(AnkirenTuning.middleMax, perSide ~/ 2));
        expect(middleRows, AnkirenTuning.middleRows.toSet());
      }
    });

    test('custom sizes down to 2 per side deal sound fields', () {
      final rng = math.Random(7);
      final found = <String>{};
      for (var perSide = AnkirenTuning.customMinPerSide; perSide <= AnkirenTuning.customMaxPerSide; perSide++) {
        for (var g = 0; g < 2000; g++) {
          found.addAll(problems(dealer.deal(all, perSide, rng), all, perSide));
        }
      }
      expect(found, isEmpty);
    });

    test('a side\'s 友札 pairs go to opposite clusters', () {
      final pairs = AnkirenDealer(
        tomofuda: (id) => [id.isOdd ? id + 1 : id - 1],
        kimarijiLength: (_) => 2,
      );
      final known = [for (var id = 1; id <= 8; id++) id];
      final rng = math.Random(3);
      for (var g = 0; g < 2000; g++) {
        final f = pairs.deal(known, 4, rng);
        for (final half in [f.own, f.opponent]) {
          final left = {for (final r in half.rows) ...r.left};
          final right = {for (final r in half.rows) ...r.right};
          for (final cluster in [left, right]) {
            for (final c in cluster) {
              expect(cluster.contains(c.isOdd ? c + 1 : c - 1), isFalse, reason: 'game $g: $left | $right');
            }
          }
        }
      }
    });

    test('a middle card is preferably one of a 友札 pair on the field', () {
      // Cards 1 and 2 are 友札, the rest have none: whenever a side holding
      // one of them puts cards in the middle, that card is among them.
      final dealer = AnkirenDealer(
        tomofuda: (id) => switch (id) { 1 => [2], 2 => [1], _ => [] },
        kimarijiLength: (_) => 2,
      );
      final known = [for (var id = 1; id <= 50; id++) id];
      final rng = math.Random(11);
      var checked = 0;
      for (var g = 0; g < 20000; g++) {
        final f = dealer.deal(known, 25, rng);
        for (final half in [f.own, f.opponent]) {
          final pair = half.cards.where((c) => c <= 2);
          if (half.middleCards.isEmpty || pair.isEmpty) continue;
          checked++;
          expect(half.middleCards.any(pair.contains), isTrue);
        }
      }
      expect(checked, greaterThan(100));
    });

    test('the same seed deals the same field', () {
      List<List<int>> layout(AnkirenField f) => [
            for (final h in [f.own, f.opponent])
              for (final r in h.rows) ...[r.left, r.middle, r.right],
          ];
      for (var seed = 0; seed < 50; seed++) {
        expect(layout(dealer.deal(all, 25, math.Random(seed))), layout(dealer.deal(all, 25, math.Random(seed))));
      }
      expect(layout(dealer.deal(all, 25, math.Random(1))), isNot(layout(dealer.deal(all, 25, math.Random(2)))));
    });
  });

  group('geometry', () {
    const eps = 1e-9;
    const pitch = AnkirenFieldSize.cardW + AnkirenFieldSize.cardGap;

    AnkirenField fieldOf(List<List<List<int>>> own, List<List<List<int>>> opponent) {
      AnkirenHalf half(List<List<List<int>>> rows) =>
          AnkirenHalf([for (final r in rows) AnkirenRow(left: r[0], middle: r[1], right: r[2])]);
      return AnkirenField(own: half(own), opponent: half(opponent));
    }

    /// Everything a laid-out field must satisfy; returns what it breaks.
    List<String> problems(AnkirenField f, FieldGeometry g, {required bool folded}) {
      final out = <String>[];
      final edge =
          folded ? 0.0 : (AnkirenFieldSize.territoryW - AnkirenFieldSize.slots * pitch + AnkirenFieldSize.cardGap) / 2;
      if (folded ? g.width >= AnkirenFieldSize.territoryW : g.width != AnkirenFieldSize.territoryW) {
        out.add('width ${g.width}');
      }
      for (final side in FieldSide.values) {
        final half = f.half(side);
        final rects = g.half(side);
        if (rects.length != half.cards.length) out.add('$side: ${rects.length} rects');
        // In the owner's view, whichever way the half is shown.
        FieldRect at(int id) => side == FieldSide.own ? rects[id]! : rects[id]!.turned(g.width, g.height);
        final list = rects.values.toList();
        for (var i = 0; i < list.length; i++) {
          final r = list[i];
          if (r.x < -eps || r.y < -eps || r.right > g.width + eps || r.bottom > g.height + eps) {
            out.add('$side: $r outside ${g.width} × ${g.height}');
          }
          for (var j = i + 1; j < list.length; j++) {
            if (r.overlaps(list[j])) out.add('$side: $r overlaps ${list[j]}');
          }
        }
        double? rowY;
        for (final r in FieldRow.values) {
          final row = half.row(r);
          if (row.isEmpty) continue;
          final y = at(row.cards.first).y;
          if (row.cards.any((c) => at(c).y != y)) out.add('$side $r is not one row');
          if (rowY != null && y >= rowY) out.add('$side $r is not above the row before');
          rowY = y;
          if (r == FieldRow.lower && (at(row.cards.first).bottom - g.height).abs() > eps) {
            out.add('$side 下段 is not at its owner\'s edge');
          }
          if (row.left.isNotEmpty && (at(row.left.first).x - edge).abs() > eps) {
            out.add('$side $r left is off the edge');
          }
          if (row.right.isNotEmpty && (at(row.right.last).right - (g.width - edge)).abs() > eps) {
            out.add('$side $r right is off the edge');
          }
          final gapStart = row.left.isEmpty ? edge : at(row.left.last).right;
          final gapEnd = row.right.isEmpty ? g.width - edge : at(row.right.first).x;
          for (final c in row.middle) {
            if (!(at(c).x > gapStart && at(c).right < gapEnd)) out.add('$side $r middle card outside the gap');
          }
          if (row.middle.length > 1) {
            final steps = [for (var i = 1; i < row.middle.length; i++) at(row.middle[i]).x - at(row.middle[i - 1]).x];
            if (steps.any((s) => (s - steps.first).abs() > eps)) out.add('$side $r middle cards unevenly spread');
          }
        }
      }
      return out;
    }

    test('dealt fields at every size lay out without overlaps, inside the half, in true scale and folded', () {
      final rng = math.Random(5);
      final found = <String>{};
      for (var perSide = AnkirenTuning.customMinPerSide; perSide <= AnkirenTuning.customMaxPerSide; perSide++) {
        for (var g = 0; g < 400; g++) {
          final f = dealer.deal(all, perSide, rng);
          for (final folded in [false, true]) {
            found.addAll(problems(f, FieldGeometry.of(f, folded: folded), folded: folded));
          }
        }
      }
      expect(found, isEmpty);
    });

    test('the most crowded rows still fit their middle cards in the open gap', () {
      // 25 per side with 5 middle cards in the fullest row, and with none.
      final crowded = fieldOf(
        [
          [[1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12]],
          [[13, 14, 15], [], [16, 17, 18, 19]],
          [[20, 21, 22], [], [23, 24, 25]],
        ],
        [
          [[26, 27, 28, 29, 30], [], [31, 32, 33, 34]],
          [[35, 36, 37, 38], [], [39, 40, 41, 42, 43]],
          [[44, 45, 46, 47], [], [48, 49, 50]],
        ],
      );
      for (final folded in [false, true]) {
        final g = FieldGeometry.of(crowded, folded: folded);
        expect(problems(crowded, g, folded: folded), isEmpty, reason: 'folded: $folded');
      }
      final folded = FieldGeometry.of(crowded, folded: true);
      final widest = 5 + 5 + 5 + 2 * AnkirenFieldSize.middleMargin;
      expect(folded.width, closeTo(widest * pitch - AnkirenFieldSize.cardGap, eps),
          reason: 'widest left + room for 5 middle cards + widest right');
    });

    test('folded closes the open middle and drops rows no half uses; true scale keeps all three', () {
      final f = dealer.deal(all, 4, math.Random(1));
      expect(f.own.middleCards.isEmpty && f.opponent.middleCards.isEmpty, isTrue);
      final folded = FieldGeometry.of(f, folded: true);
      final real = FieldGeometry.of(f, folded: false);
      expect(folded.width, closeTo((2 + AnkirenFieldSize.foldedHole) * pitch - AnkirenFieldSize.cardGap, eps));
      expect(folded.height, closeTo(2 * AnkirenFieldSize.cardH + AnkirenFieldSize.rowGap, eps));
      expect(real.width, AnkirenFieldSize.territoryW);
      expect(real.height, closeTo(3 * AnkirenFieldSize.cardH + 2 * AnkirenFieldSize.rowGap, eps));
    });

    test('the opponent half is turned: its 下段 at the top, its owner\'s left on the right', () {
      final f = fieldOf(
        [
          [[1], [], [2]],
          [[3], [], []],
          [[], [], []],
        ],
        [
          [[4], [], [5]],
          [[6], [], []],
          [[], [], []],
        ],
      );
      final g = FieldGeometry.of(f, folded: true);
      final own = g.half(FieldSide.own), opponent = g.half(FieldSide.opponent);
      expect(own[3]!.x, closeTo(0, eps), reason: 'own 中段, left: top left');
      expect(own[3]!.y, closeTo(0, eps));
      expect(own[1]!.bottom, closeTo(g.height, eps), reason: 'own 下段 at the bottom');
      expect(opponent[4]!.y, closeTo(0, eps), reason: 'opponent 下段 at the top');
      expect(opponent[4]!.right, closeTo(g.width, eps), reason: 'its owner\'s left is the screen\'s right');
      expect(opponent[6]!.bottom, closeTo(g.height, eps));
      expect(opponent[5]!.x, closeTo(0, eps));
    });
  });
}
