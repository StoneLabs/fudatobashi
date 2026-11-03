// 一騎打ち's Tobi: the homes his layout generator gives every card dealt
// for a match.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  group("Tobi's layout", () {
    final layout = IkkiuchiLayout.ofPoems();

    // [perSide] cards a side dealt from all 100 by [seed]: his, then the player's.
    (List<int>, List<int>) deal(int perSide, int seed) {
      final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
      return (deck.sublist(0, perSide), deck.sublist(perSide, 2 * perSide));
    }

    IkkiuchiHomes homes(double rating, int perSide, int rows, int seed) {
      final (own, others) = deal(perSide, seed);
      return layout.generate(rating: rating, own: own, others: others, rows: rows, seed: seed);
    }

    final setups = [
      for (final perSide in [8, 12, 16, 20, 25])
        for (var rows = 1; rows <= IkkiuchiLayoutTuning.rows; rows++)
          if (IkkiuchiLayout.rowsAllowed(perSide, rows)) (perSide: perSide, rows: rows),
    ];
    const ratings = [0.0, 1600.0, 2800.0, 3600.0];

    test('allows 2 rows only up to its card count, and 1 row only up to its own', () {
      const two = IkkiuchiLayoutTuning.twoRowsUpTo, one = IkkiuchiLayoutTuning.oneRowUpTo;
      expect(IkkiuchiLayout.rowsAllowed(25, IkkiuchiLayoutTuning.rows), isTrue);
      expect(IkkiuchiLayout.rowsAllowed(two, 2), isTrue);
      expect(IkkiuchiLayout.rowsAllowed(two + 1, 2), isFalse);
      expect(IkkiuchiLayout.rowsAllowed(one, 1), isTrue);
      expect(IkkiuchiLayout.rowsAllowed(one + 1, 1), isFalse);
      expect(IkkiuchiLayout.rowsAllowed(one, 0), isFalse);
    });

    test('a row has room for its pitches less the gap between its groups', () {
      expect(IkkiuchiLayout.rowRoom, (IkkiuchiLayoutTuning.rowSlots - IkkiuchiLayoutTuning.groupGap).floor());
    });

    test('tells look-alikes by their opening sounds', () {
      expect(IkkiuchiLayout.areAlike('あさぼらけあ', 'あさぼらけう'), isTrue);
      expect(IkkiuchiLayout.areAlike('あさじ', 'あさぼらけあ'), isTrue);
      expect(IkkiuchiLayout.areAlike('なにし', 'なにわが'), isTrue);
      expect(IkkiuchiLayout.areAlike('あけ', 'あい'), isFalse);
      expect(IkkiuchiLayout.areAlike('あきの', 'あさじ'), isFalse);
    });

    test('gives the same homes for the same seed', () {
      for (final rating in ratings) {
        final a = homes(rating, 25, 3, 7), b = homes(rating, 25, 3, 7);
        for (final id in a.cards) {
          expect(b.homeOf(id), a.homeOf(id), reason: '$rating #$id');
        }
      }
      final a = homes(1600, 25, 3, 7), c = homes(1600, 25, 3, 8);
      expect(a.cards.toSet(), isNot(c.cards.toSet()));
    });

    test('homes every card dealt, each in its own spot, in the rows in play', () {
      for (final s in setups) {
        for (final rating in ratings) {
          for (var seed = 0; seed < 20; seed++) {
            final (own, others) = deal(s.perSide, seed);
            final h = layout.generate(rating: rating, own: own, others: others, rows: s.rows, seed: seed);
            final why = '${s.perSide} in ${s.rows} rows at $rating, seed $seed';
            expect(h.cards.toSet(), {...own, ...others}, reason: why);
            expect(h.rows, s.rows, reason: why);
            final spots = {for (final id in h.cards) h.homeOf(id)};
            expect(spots, hasLength(own.length + others.length), reason: '$why: two cards in one spot');
            for (final (r, row) in h.plan.indexed) {
              for (final g in IkkiuchiGroup.values) {
                for (final (i, id) in row.group(g).indexed) {
                  expect(h.homeOf(id), IkkiuchiHome(r, g, i), reason: why);
                }
              }
            }
          }
        }
      }
    });

    test('lays out his own cards in his rows: 下段 the fullest, each row evenly split, all in their homes', () {
      for (final s in setups) {
        for (final rating in ratings) {
          for (var seed = 0; seed < 20; seed++) {
            final h = homes(rating, s.perSide, s.rows, seed);
            final why = '${s.perSide} in ${s.rows} rows at $rating, seed $seed';
            final start = h.start;
            expect({for (final row in start) ...row.left, for (final row in start) ...row.right}, h.own.toSet(),
                reason: why);
            final lengths = [for (final row in start) row.length];
            expect(lengths.reduce(math.max) - lengths.reduce(math.min), lessThanOrEqualTo(1), reason: why);
            expect(lengths.first, lengths.reduce(math.max), reason: why);
            for (final row in start) {
              expect((row.left.length - row.right.length).abs(), lessThanOrEqualTo(1), reason: why);
              expect(row.length, lessThanOrEqualTo(IkkiuchiLayout.rowRoom), reason: why);
            }
            for (final (r, row) in start.indexed) {
              for (final g in IkkiuchiGroup.values) {
                final ids = row.group(g);
                for (final id in ids) {
                  expect((h.homeOf(id).row, h.homeOf(id).group), (r, g), reason: '$why #$id');
                }
                final orders = [for (final id in ids) h.homeOf(id).order];
                expect(orders, [...orders]..sort(), reason: '$why: kept in home order');
              }
            }
          }
        }
      }
    });

    test('keeps every row within its room while the cards dealt fit the side', () {
      final room = IkkiuchiLayout.rowRoom;
      for (final s in setups.where((s) => 2 * s.perSide <= s.rows * room)) {
        for (final rating in ratings) {
          for (var seed = 0; seed < 20; seed++) {
            final h = homes(rating, s.perSide, s.rows, seed);
            for (final row in h.plan) {
              expect(row.length, lessThanOrEqualTo(room), reason: '${s.perSide} in ${s.rows} rows, seed $seed');
            }
          }
        }
      }
    });

    test('keeps any side that fits within its rows, and every card it can in its home row and group', () {
      final room = IkkiuchiLayout.rowRoom;
      for (final rating in ratings) {
        for (var seed = 0; seed < 40; seed++) {
          final h = homes(rating, 25, 3, seed);
          final rng = math.Random(seed);
          final all = h.cards.toList()..shuffle(rng);
          final present = all.take(rng.nextInt(h.rows * room + 1)).toList();
          final side = h.sideWith(present);
          expect([for (final row in side) ...row.left, for (final row in side) ...row.right]..sort(),
              [...present]..sort());
          for (final row in side) {
            expect(row.length, lessThanOrEqualTo(room), reason: 'seed $seed');
          }
          final homeRows = [for (var r = 0; r < h.rows; r++) present.where((id) => h.homeOf(id).row == r).length];
          for (final (r, row) in side.indexed) {
            for (final g in IkkiuchiGroup.values) {
              for (final id in row.group(g)) {
                final home = h.homeOf(id);
                if (homeRows[home.row] <= room) expect((r, g), (home.row, home.group), reason: 'seed $seed #$id');
              }
            }
          }
        }
      }
    });

    test('puts a received card in its home, and back again when it is sent back', () {
      for (var seed = 0; seed < 20; seed++) {
        final (own, others) = deal(25, seed);
        final h = layout.generate(rating: 1600, own: own, others: others, rows: 3, seed: seed);
        final received = others[seed % others.length];
        final sent = own[seed % own.length];
        final home = h.homeOf(received);
        final side = h.sideWith([...own.where((id) => id != sent), received]);
        final group = side[home.row].group(home.group);
        expect(group, contains(received));
        final before = [for (final id in group) if (id != received && h.homeOf(id).order < home.order) id];
        expect(group.indexOf(received), before.length);
        final back = h.sideWith(own);
        for (final (r, row) in h.start.indexed) {
          expect(back[r].left, row.left);
          expect(back[r].right, row.right);
        }
      }
    });

    test('puts short cards in 下段 while it has room', () {
      for (final rating in ratings) {
        for (var seed = 0; seed < 40; seed++) {
          final h = homes(rating, 25, 3, seed);
          final short = h.own.where(layout.isShort).toList();
          if (short.length > h.start.first.length) continue;
          for (final id in short) {
            expect(h.homeOf(id).row, 0, reason: '$rating, seed $seed, #$id');
          }
        }
      }
    });

    test('groups a weak Tobi\'s cards by first sound and splits a strong one\'s look-alikes', () {
      // The mean of each share over many deals, leaving out a deal with no
      // pairs to share.
      ({double grouped, double alike}) mean(double rating) {
        final grouped = <double>[], alike = <double>[];
        for (var seed = 0; seed < 200; seed++) {
          final h = homes(rating, 25, 3, seed);
          if (layout.groupedShare(h) case final share?) grouped.add(share);
          if (layout.lookAlikesTogether(h) case final share?) alike.add(share);
        }
        double average(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
        return (grouped: average(grouped), alike: average(alike));
      }

      final weak = mean(IkkiuchiTuning.ratingMin), strong = mean(IkkiuchiTuning.ratingMax);
      expect(weak.grouped, greaterThan(strong.grouped + 0.4), reason: '$weak vs $strong');
      expect(weak.alike, greaterThan(0.7), reason: '$weak');
      expect(strong.alike, lessThan(0.15), reason: '$strong');
    });
  });
}
