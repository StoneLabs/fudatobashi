import 'dart:math' as math;

import '../config/config.dart';
import '../data/poem.dart';

/// The two groups of a row of Tobi's side, left and right as he sees it.
enum IkkiuchiGroup { left, right }

/// Where a card lives on Tobi's side: its [row] (0 is 下段, nearest him),
/// its [group], and its [order] in that group from the outer edge in,
/// among every card homed there.
class IkkiuchiHome {
  const IkkiuchiHome(this.row, this.group, this.order);

  final int row;
  final IkkiuchiGroup group;
  final int order;

  @override
  bool operator ==(Object other) =>
      other is IkkiuchiHome && other.row == row && other.group == group && other.order == order;

  @override
  int get hashCode => Object.hash(row, group, order);

  @override
  String toString() => 'IkkiuchiHome($row, ${group.name}, $order)';
}

/// One row of Tobi's side: each group's cards from its outer edge in.
class IkkiuchiRow {
  const IkkiuchiRow(this.left, this.right);

  final List<int> left;
  final List<int> right;

  List<int> group(IkkiuchiGroup g) => g == IkkiuchiGroup.left ? left : right;
  int get length => left.length + right.length;
}

/// Tobi's home spots for one match ([IkkiuchiLayout.generate]): one for
/// each card dealt, his [own] and every card that may come to him.
class IkkiuchiHomes {
  IkkiuchiHomes._(this.soundGrouped, this.tomofudaGrouped, this.own, this.plan)
      : _homes = {
          for (final (r, row) in plan.indexed)
            for (final g in IkkiuchiGroup.values)
              for (final (i, id) in row.group(g).indexed) id: IkkiuchiHome(r, g, i),
        };

  /// The match's layout habits: whether he keeps each first-sound group
  /// together ([IkkiuchiLayoutTuning.soundGrouping]), and each family of
  /// 友札 side by side ([IkkiuchiLayoutTuning.tomofudaGrouping]).
  final bool soundGrouped;
  final bool tomofudaGrouped;
  final List<int> own;

  /// Every card homed in each row, 下段 first.
  final List<IkkiuchiRow> plan;
  final Map<int, IkkiuchiHome> _homes;

  int get rows => plan.length;
  Iterable<int> get cards => _homes.keys;
  IkkiuchiHome homeOf(int poemId) => _homes[poemId]!;

  /// His side at the start: his own cards in their homes.
  List<IkkiuchiRow> get start => sideWith(own);

  /// His side with [present] on it, each card at its home. A row with more
  /// cards than it has room for ([IkkiuchiLayout.rowRoom]) passes its
  /// innermost ones to the inner end of the same group in the nearest row
  /// with room.
  List<IkkiuchiRow> sideWith(Iterable<int> present) {
    final on = present.toSet();
    final side = [
      for (final row in plan)
        IkkiuchiRow([
          for (final id in row.left)
            if (on.contains(id)) id,
        ], [
          for (final id in row.right)
            if (on.contains(id)) id,
        ]),
    ];
    final room = IkkiuchiLayout.rowRoom;
    for (var r = 0; r < side.length; r++) {
      while (side[r].length > room) {
        final to = _nearestWithRoom(side, r, room);
        if (to == null) break;
        final from = side[r].left.length >= side[r].right.length ? IkkiuchiGroup.left : IkkiuchiGroup.right;
        side[to].group(from).add(side[r].group(from).removeLast());
      }
    }
    return side;
  }

  static int? _nearestWithRoom(List<IkkiuchiRow> side, int row, int room) {
    for (var d = 1; d < side.length; d++) {
      for (final r in [row - d, row + d]) {
        if (r >= 0 && r < side.length && side[r].length < room) return r;
      }
    }
    return null;
  }
}

/// Lays out Tobi's own fixed layout for a match from his rating. Every random
/// choice comes from the seed, so a seed always gives the same homes.
///
/// His cards sort into groups by the first sound of their kimariji; the
/// short cards ([IkkiuchiLayoutTuning.nearRowSounds], the one-sound cards)
/// make one group. Once a match he decides his two habits, each with its
/// chance at his rating, and they set which cards lie together as runs:
/// - Grouping by sound ([IkkiuchiLayoutTuning.soundGrouping]), each group
///   is a run, in kana order, so its 友札 sit side by side.
/// - Else, keeping 友札 together ([IkkiuchiLayoutTuning.tomofudaGrouping]),
///   each family of look-alikes is a run.
/// - A run lies in one row's group. Longer runs are laid first, each where
///   there is the most room; one too long for its place goes on in the
///   nearest place with room, the same row's other group first.
/// - Every other card is placed alone, look-alikes first, each where the
///   fewest of its look-alikes are (none if it can), else where there is
///   the most room.
/// - Short cards go to 下段, nearest his hand, while it has room.
///
/// His own cards fill his rows first: 下段 the fullest, each row split
/// evenly between left and right. Then each card dealt to the player gets
/// a home by the same rules, a kept group's card joining its group, every
/// row taking at most [rowRoom] homes while any row has room. A card he
/// receives goes to its home, so one sent back and forth lands in the same
/// place.
class IkkiuchiLayout {
  IkkiuchiLayout({required this.kimariji});

  /// A layout over the app's poems.
  factory IkkiuchiLayout.ofPoems() => IkkiuchiLayout(kimariji: (id) => poems[id].kimariji);

  final String Function(int poemId) kimariji;

  /// The cards a row has room for.
  static int get rowRoom => (IkkiuchiLayoutTuning.rowSlots - IkkiuchiLayoutTuning.groupGap).floor();

  /// Whether a side of [perSide] cards may be laid out in [rows] rows.
  static bool rowsAllowed(int perSide, int rows) =>
      rows == IkkiuchiLayoutTuning.rows ||
      (rows == 2 && perSide <= IkkiuchiLayoutTuning.twoRowsUpTo) ||
      (rows == 1 && perSide <= IkkiuchiLayoutTuning.oneRowUpTo);

  /// Whether [poemId] is a short card.
  bool isShort(int poemId) => kimariji(poemId).length <= IkkiuchiLayoutTuning.nearRowSounds;

  /// The group [poemId] sorts into: its kimariji's first sound, or '' for
  /// the short cards.
  String groupOf(int poemId) => isShort(poemId) ? '' : kimariji(poemId)[0];

  /// Whether two cards are look-alikes (友札).
  bool alike(int a, int b) => a != b && areAlike(kimariji(a), kimariji(b));

  static bool areAlike(String a, String b) {
    var shared = 0;
    while (shared < a.length && shared < b.length && a[shared] == b[shared]) {
      shared++;
    }
    return shared >= IkkiuchiLayoutTuning.lookAlikeShared && shared >= math.min(a.length, b.length) - 1;
  }

  int _byKana(int a, int b) => kimariji(a).compareTo(kimariji(b));

  /// [cards] linked by look-alikes, directly or not, in families of two or
  /// more, each in kana order.
  List<List<int>> families(Iterable<int> cards) {
    final list = cards.toList();
    final seen = <int>{};
    final out = <List<int>>[];
    for (final c in list) {
      if (!seen.add(c)) continue;
      final family = [c];
      for (var i = 0; i < family.length; i++) {
        for (final d in list) {
          if (alike(family[i], d) && seen.add(d)) family.add(d);
        }
      }
      if (family.length > 1) out.add(family..sort(_byKana));
    }
    return out;
  }

  /// The homes for a match against Tobi at [rating] with [own] on his side,
  /// laid out in [rows] rows ([rowsAllowed]), and [others] dealt to the
  /// player.
  IkkiuchiHomes generate({
    required double rating,
    required List<int> own,
    required List<int> others,
    required int rows,
    required int seed,
  }) {
    assert(rowsAllowed(own.length, rows), '${own.length} cards in $rows rows');
    assert(own.toSet().intersection(others.toSet()).isEmpty, 'a card dealt to both sides');
    final rng = math.Random(seed);
    final bySound = rng.nextDouble() < IkkiuchiLayoutTuning.soundGrouping.at(rating);
    final byTomofuda = rng.nextDouble() < IkkiuchiLayoutTuning.tomofudaGrouping.at(rating);
    final familyOf = {
      for (final family in families([...own, ...others]))
        for (final id in family) id: family.first,
    };
    final plan = _Plan(this, rows, rng, (id) => bySound ? groupOf(id) : (byTomofuda ? familyOf[id] : null));

    final shape = [
      for (var r = 0; r < rows; r++) own.length ~/ rows + (r < own.length % rows ? 1 : 0),
    ];
    final leftOf = [for (final n in shape) n ~/ 2 + (n.isOdd && rng.nextBool() ? 1 : 0)];
    plan.room = (box) =>
        (box.group == IkkiuchiGroup.left ? leftOf[box.row] : shape[box.row] - leftOf[box.row]) - box.count;
    plan.place(own);

    plan.room = (box) => rowRoom - plan.rowCount(box.row);
    plan.place(others);

    return IkkiuchiHomes._(bySound, byTomofuda, List.unmodifiable(own), [
      for (var r = 0; r < rows; r++)
        IkkiuchiRow(plan.box(r, IkkiuchiGroup.left).cards.toList(), plan.box(r, IkkiuchiGroup.right).cards.toList()),
    ]);
  }

  /// The share of pairs of cards from one group ([groupOf]) whose homes
  /// share a row and a group: 1 when every group sits together. Null with
  /// no such pairs.
  double? groupedShare(IkkiuchiHomes homes) => _togetherShare(homes, (a, b) => groupOf(a) == groupOf(b));

  /// The share of look-alike pairs whose homes share a row and a group:
  /// near 0 when they are all split. Null with no look-alikes.
  double? lookAlikesTogether(IkkiuchiHomes homes) => _togetherShare(homes, alike);

  static double? _togetherShare(IkkiuchiHomes homes, bool Function(int a, int b) paired) {
    final cards = homes.cards.toList();
    var pairs = 0, together = 0;
    for (var i = 0; i < cards.length; i++) {
      for (var j = i + 1; j < cards.length; j++) {
        if (!paired(cards[i], cards[j])) continue;
        pairs++;
        final a = homes.homeOf(cards[i]), b = homes.homeOf(cards[j]);
        if (a.row == b.row && a.group == b.group) together++;
      }
    }
    return pairs == 0 ? null : together / pairs;
  }
}

/// One group of one row while the homes are laid: its runs of cards from
/// the outer edge in, each a run's cards or a single card.
class _Box {
  _Box(this.row, this.group);

  final int row;
  final IkkiuchiGroup group;
  final List<List<int>> units = [];

  int get count => units.fold(0, (n, u) => n + u.length);
  Iterable<int> get cards => units.expand((u) => u);

  /// How far apart two places are: a row counts more than the gap between
  /// a row's groups.
  int distanceTo(_Box o) => 2 * (row - o.row).abs() + (group == o.group ? 0 : 1);
}

/// The homes while they are laid, by [IkkiuchiLayout]'s rules.
class _Plan {
  _Plan(this.layout, int rows, this.rng, this.runOf)
      : boxes = [
          for (var r = 0; r < rows; r++)
            for (final g in IkkiuchiGroup.values) _Box(r, g),
        ];

  final IkkiuchiLayout layout;
  final math.Random rng;
  final List<_Box> boxes;

  /// The run a card lies in, the same for each of its cards; null for a
  /// card placed alone.
  final Object? Function(int poemId) runOf;

  /// The cards a box may still take: its share of his starting rows, then
  /// its row's room.
  late int Function(_Box box) room;

  _Box box(int row, IkkiuchiGroup group) => boxes[row * IkkiuchiGroup.values.length + group.index];
  int rowCount(int row) => boxes.where((b) => b.row == row).fold(0, (n, b) => n + b.count);

  /// Homes [cards]: the short cards first, then each run ([runOf]), the
  /// longest first, then the other cards one by one, look-alikes first.
  void place(List<int> cards) {
    final byRun = <Object, List<int>>{};
    final alone = <int>[];
    for (final id in [...cards]..sort(layout._byKana)) {
      final run = runOf(id);
      run == null ? alone.add(id) : byRun.putIfAbsent(run, () => []).add(id);
    }

    final runs = [
      for (final run in byRun.values) (cards: run, short: layout.isShort(run.first), tie: rng.nextDouble()),
    ]..sort((a, b) {
        if (a.short != b.short) return a.short ? -1 : 1;
        if (a.cards.length != b.cards.length) return b.cards.length - a.cards.length;
        return a.tie.compareTo(b.tie);
      });
    final singles = [
      for (final id in alone)
        (id: id, short: layout.isShort(id), alike: cards.any((c) => layout.alike(c, id)), tie: rng.nextDouble()),
    ]..sort((a, b) {
        if (a.short != b.short) return a.short ? -1 : 1;
        if (a.alike != b.alike) return a.alike ? -1 : 1;
        return a.tie.compareTo(b.tie);
      });

    for (final s in singles.where((s) => s.short)) {
      _placeSingle(s.id);
    }
    for (final run in runs) {
      _placeRun(run.cards);
    }
    for (final s in singles.where((s) => !s.short)) {
      _placeSingle(s.id);
    }
  }

  /// A [run] joins its run's cards where most of them lie, or else starts
  /// where there is the most room.
  void _placeRun(List<int> run) {
    final key = runOf(run.first);
    int ofRun(_Box b) => b.cards.where((c) => runOf(c) == key).length;
    final holding = boxes.where((b) => ofRun(b) > 0).toList();
    if (holding.isEmpty) {
      _layRun(run, _pick(_choices(short: layout.isShort(run.first)), _roomier));
      return;
    }
    final home = _pick(holding, (a, b) => ofRun(b) - ofRun(a));
    _layRun(run, home, into: home.units.firstWhere((u) => runOf(u.first) == key));
  }

  /// Lays [run] in [start] as far as its room goes, joining the unit [into]
  /// in kana order when given, the rest on in the nearest place with room;
  /// with no room left anywhere, in the least full row.
  void _layRun(List<int> run, _Box start, {List<int>? into}) {
    var rest = run;
    var target = start;
    var unit = into;
    while (rest.isNotEmpty) {
      final fits = math.min(rest.length, math.max(0, room(target)));
      if (fits > 0) {
        final part = rest.sublist(0, fits);
        if (unit != null) {
          unit
            ..addAll(part)
            ..sort(layout._byKana);
        } else {
          _insert(target, part);
        }
        rest = rest.sublist(fits);
        continue;
      }
      final open = boxes.where((b) => room(b) > 0).toList();
      if (open.isEmpty) {
        _insert(_pick(boxes, _roomier), rest);
        return;
      }
      target = _pick(open, (a, b) => a.distanceTo(start) - b.distanceTo(start));
      unit = null;
    }
  }

  /// [id] alone, where the fewest of its look-alikes are, then where there
  /// is the most room.
  void _placeSingle(int id) {
    int alikeIn(_Box b) => b.cards.where((c) => layout.alike(c, id)).length;
    _insert(
      _pick(_choices(short: layout.isShort(id)), (a, b) {
        final byAlike = alikeIn(a) - alikeIn(b);
        return byAlike != 0 ? byAlike : _roomier(a, b);
      }),
      [id],
    );
  }

  /// The places with room, only 下段's for [short] cards while it has room;
  /// every place once none has room.
  List<_Box> _choices({required bool short}) {
    final open = boxes.where((b) => room(b) > 0).toList();
    if (open.isEmpty) return boxes;
    final near = open.where((b) => b.row == 0).toList();
    return short && near.isNotEmpty ? near : open;
  }

  /// More room first, then fewer cards.
  int _roomier(_Box a, _Box b) {
    final byRoom = room(b) - room(a);
    return byRoom != 0 ? byRoom : a.count - b.count;
  }

  /// The first of [from], in random order, that [compare] puts first.
  _Box _pick(List<_Box> from, int Function(_Box a, _Box b) compare) {
    final shuffled = [...from]..shuffle(rng);
    return shuffled.reduce((best, b) => compare(b, best) < 0 ? b : best);
  }

  /// [unit] into [box] at a random place between its runs.
  void _insert(_Box box, List<int> unit) => box.units.insert(rng.nextInt(box.units.length + 1), unit);
}
