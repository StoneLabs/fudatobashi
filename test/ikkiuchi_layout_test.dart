// 一騎打ち's Tobi: the homes his layout generator gives every card dealt
// for a match.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_groups_dealt.dart';

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

    test('gives the same homes and the same choices for the same seed', () {
      for (final rating in ratings) {
        final a = homes(rating, 25, 3, 7), b = homes(rating, 25, 3, 7);
        for (final id in a.cards) {
          expect(b.homeOf(id), a.homeOf(id), reason: '$rating #$id');
        }
        expect(b.soundGroups, a.soundGroups, reason: '$rating');
        expect(b.tomofudaGroups, a.tomofudaGroups, reason: '$rating');
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

    // [count] ranked games at [rating], 25 a side in 3 rows, one per seed.
    Iterable<IkkiuchiHomes> games(double rating, int count) sync* {
      for (var seed = 0; seed < count; seed++) {
        yield homes(rating, 25, 3, seed);
      }
    }

    test('decides on each group with more than one of his own cards, and only those', () {
      for (final rating in ratings) {
        for (var seed = 0; seed < 20; seed++) {
          final h = homes(rating, 25, 3, seed);
          final (own, others) = deal(25, seed);
          final why = '$rating, seed $seed';
          expect(h.soundGroups.keys.toSet(), {
            for (final sound in {for (final id in own) layout.groupOf(id)})
              if (own.where((id) => layout.groupOf(id) == sound).length > 1) sound,
          }, reason: why);
          expect(h.tomofudaGroups.keys.toSet(), {
            for (final family in layout.families([...own, ...others]))
              if (family.where(own.contains).length > 1) family.first,
          }, reason: why);
        }
      }
    });

    test('decides each group on its own, about as often as its chance', () {
      bool mixed(Map<Object, bool> groups) => groups.containsValue(true) && groups.containsValue(false);
      const count = 1000;
      var mixedSounds = 0, mixedFamilies = 0;
      for (final h in games(2600, count)) {
        if (mixed(h.soundGroups)) mixedSounds++;
        if (mixed(h.tomofudaGroups)) mixedFamilies++;
      }
      expect(mixedSounds / count, greaterThan(0.1), reason: 'sound groups both kept and split in one game');
      expect(mixedFamilies / count, greaterThan(0.05), reason: '友札 families both kept and split in one game');

      const rating = 1200.0;
      final sounds = <bool>[], families = <bool>[];
      for (final h in games(rating, 500)) {
        sounds.addAll(h.soundGroups.values);
        families.addAll(h.tomofudaGroups.values);
      }
      double kept(List<bool> groups) => groups.where((k) => k).length / groups.length;
      expect(kept(sounds), closeTo(IkkiuchiLayoutTuning.soundGrouping.at(rating), 0.03));
      expect(kept(families), closeTo(IkkiuchiLayoutTuning.tomofudaGrouping.at(rating), 0.03));
    });

    test('has at least one group together in about the share of games set, as the curves page works out', () {
      const count = 2000, close = 0.03;
      for (final (rating, target) in [(2600.0, 0.2), (3000.0, 0.1)]) {
        var sound = 0, family = 0;
        for (final h in games(rating, count)) {
          if (h.soundGroups.containsValue(true)) sound++;
          if (h.tomofudaGroups.containsValue(true)) family++;
        }
        final soundWorkedOut = ikkiuchiSoundsDealt.anyKept(IkkiuchiLayoutTuning.soundGrouping.at(rating));
        final familyWorkedOut = ikkiuchiFamiliesDealt.anyKept(IkkiuchiLayoutTuning.tomofudaGrouping.at(rating));
        expect(sound / count, closeTo(target, close), reason: 'sound groups at $rating');
        expect(family / count, closeTo(target, close), reason: '友札 at $rating');
        expect(sound / count, closeTo(soundWorkedOut, close), reason: 'sound groups at $rating, worked out');
        expect(family / count, closeTo(familyWorkedOut, close), reason: '友札 at $rating, worked out');
      }
    });

    test('keeps a kept 友札 family side by side and spreads a split one apart', () {
      var kept = 0, keptTogether = 0, pairs = 0, pairsTogether = 0;
      for (final rating in [1200.0, 2000.0, 2600.0]) {
        for (final h in games(rating, 200)) {
          (int, IkkiuchiGroup) place(int id) => (h.homeOf(id).row, h.homeOf(id).group);
          for (final MapEntry(key: first, value: together) in h.tomofudaGroups.entries) {
            if (h.soundGroups[layout.groupOf(first)]!) continue;
            final family = h.own.where((id) => id == first || layout.alike(id, first)).toList();
            if (together) {
              kept++;
              if (family.map(place).toSet().length == 1) keptTogether++;
              continue;
            }
            for (var i = 0; i < family.length; i++) {
              for (var j = i + 1; j < family.length; j++) {
                pairs++;
                if (place(family[i]) == place(family[j])) pairsTogether++;
              }
            }
          }
        }
      }
      expect(kept, greaterThan(0));
      expect(keptTogether / kept, greaterThan(0.97));
      expect(pairs, greaterThan(0));
      expect(pairsTogether / pairs, lessThan(0.03));
    });
  });
}
