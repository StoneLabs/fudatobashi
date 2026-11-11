import 'dart:math' as math;

import '../config/config.dart';
import 'field_parts.dart';
import 'ikkiuchi_field.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_record.dart';
import 'ikkiuchi_side.dart';
import 'placing.dart';

/// Both sides of a match (一騎打ち) as they stand, and how a 送り札 changes
/// them. Tobi's side is always laid out by his [homes]: each card he has
/// at its home, his groups packed to the side's edges. The player's lies as
/// the player laid it.
///
/// A card the player sends him goes to its home on his side. A card he
/// sends the player is theirs to place by [IkkiuchiSides.rules]: at the
/// inner end of any group, in the open middle of their
/// [IkkiuchiPlacingTuning.middleRow], or on any card's place (the cards
/// inward of it moving a place in), in any of their rows, each at most its
/// [IkkiuchiLayoutTuning.rowSlots] pitches across with its groups
/// [IkkiuchiLayoutTuning.groupGap] apart, or its middle cards
/// [IkkiuchiPlacingTuning.middleMargin] clear of them.
///
/// A card sent as the match is decided lies on top of the other's side, in
/// no row ([onTop], [sentLast]). A side that is full takes no other card
/// ([receives]).
class IkkiuchiSides {
  IkkiuchiSides(
      {required this.homes,
      required Iterable<int> tobi,
      required List<IkkiuchiRow> player,
      Map<int, IkkiuchiSide> onTop = const {}})
      : tobiCards = Set.unmodifiable(tobi),
        player = List.unmodifiable(player),
        onTop = Map.unmodifiable(onTop);

  /// The start of a match: Tobi's own cards at their homes, and the
  /// player's side as laid out.
  IkkiuchiSides.start(IkkiuchiHomes homes, List<IkkiuchiRow> player)
      : this(homes: homes, tobi: homes.own, player: player);

  final IkkiuchiHomes homes;

  /// Tobi's cards, those [onTop] of his side too.
  final Set<int> tobiCards;

  /// The player's rows, 下段 first, each group from its outer edge in and
  /// the open middle left to right.
  final List<IkkiuchiRow> player;

  /// The cards sent across as the match was decided, in the order sent,
  /// each with the side it went to: in no row, they lie on top of it
  /// ([IkkiuchiField.onTop]).
  final Map<int, IkkiuchiSide> onTop;

  /// Tobi's rows, 下段 first, each group from its outer edge in: his cards
  /// at their homes, but those [onTop].
  late final List<IkkiuchiRow> tobi = homes.sideWith(tobiCards.where((c) => !onTop.containsKey(c)));

  /// The player's cards, those [onTop] of their side too.
  List<int> get playerCards => [
        for (final r in player) ...[...r.left, ...r.middle, ...r.right],
        for (final MapEntry(key: card, value: side) in onTop.entries)
          if (side == IkkiuchiSide.player) card,
      ];

  /// Both sides as they lie now.
  IkkiuchiLaidField get field => IkkiuchiLaidField(opponent: tobi, player: player);

  /// The placing rules of a player's side of [rows] rows: the open middle
  /// of [IkkiuchiPlacingTuning.middleRow] when that row is played, and each
  /// row's room.
  static PlacingRules rules(int rows) {
    final played = FieldRow.values.take(rows).toList();
    return PlacingRules(
      rows: played,
      openMiddle: played.contains(IkkiuchiPlacingTuning.middleRow) ? IkkiuchiPlacingTuning.middleRow : null,
      room: RowRoom(
        slots: IkkiuchiLayoutTuning.rowSlots[rows]!,
        clusterGap: IkkiuchiLayoutTuning.groupGap,
        middleMargin: IkkiuchiPlacingTuning.middleMargin,
      ),
    );
  }

  /// The player's side as the placing rules have it: each right group from
  /// its inner end out.
  PlacingBoard get playerBoard => PlacingBoard(
        rules(player.length),
        PlacingSide([
          for (final r in FieldRow.values)
            r.index < player.length
                ? PlacingRow(
                    left: player[r.index].left,
                    middle: player[r.index].middle,
                    right: player[r.index].right.reversed.toList(),
                  )
                : PlacingRow.empty(),
        ]),
      );

  /// The card Tobi sends: with [smart]'s chance one whose look-alike
  /// ([alike]) stays on his side, when he has one; else any of his at
  /// random. Null when he has none.
  int? tobiSends({required double smart, required bool Function(int a, int b) alike, required math.Random rng}) {
    final mine = tobiCards.toList()..sort();
    if (mine.isEmpty) return null;
    final splits = [
      for (final c in mine)
        if (mine.any((d) => alike(c, d))) c,
    ];
    final roll = rng.nextDouble();
    if (splits.isNotEmpty && roll < smart) return splits[rng.nextInt(splits.length)];
    return mine[rng.nextInt(mine.length)];
  }

  /// The sides with [card] off whichever holds it: his packed by his
  /// homes, the player's group or open middle closing up.
  IkkiuchiSides without(int card) {
    List<int> drop(List<int> cards) => [
          for (final c in cards)
            if (c != card) c,
        ];
    return IkkiuchiSides(
      homes: homes,
      tobi: tobiCards.where((c) => c != card),
      player: [for (final r in player) IkkiuchiRow(drop(r.left), drop(r.right), middle: drop(r.middle))],
      onTop: {...onTop}..remove(card),
    );
  }

  /// The sides once the player sent Tobi [card]: off theirs, and at its
  /// home on his.
  IkkiuchiSides toTobi(int card) {
    final rest = without(card);
    return IkkiuchiSides(homes: homes, tobi: {...rest.tobiCards, card}, player: rest.player, onTop: rest.onTop);
  }

  /// The narrowest a field may be, in card widths, for a card more to have
  /// room at every free spot of the player's side: as wide as the widest of
  /// their rows with it added at one of them ([IkkiuchiField.rowWidth]); 0
  /// with none free.
  double get playerRoomForOne => [
        for (final spot in playerBoard.freeSpots)
          switch (spot) {
            ClusterEnd(:final row, :final part) => _widthWith(player[row.index], part),
            OpenMiddle(:final row) => _widthWith(player[row.index], RowPart.middle),
            CardSpot() => throw StateError('a free spot is never a card'),
          },
      ].fold(0.0, math.max);

  /// [row]'s width ([IkkiuchiField.rowWidth]) with a card more in its [part].
  static double _widthWith(IkkiuchiRow row, RowPart part) => IkkiuchiField.rowWidth(
      row.left.length + (part == RowPart.left ? 1 : 0), row.right.length + (part == RowPart.right ? 1 : 0),
      middle: row.middle.length + (part == RowPart.middle ? 1 : 0));

  /// Whether [to]'s side takes a card more: the player's while it has a
  /// free spot, Tobi's while a row of his is under its limit
  /// ([IkkiuchiLayout.rowLimit]).
  bool receives(IkkiuchiSide to) => to == IkkiuchiSide.player
      ? playerBoard.freeSpots.isNotEmpty
      : tobi.any((r) => r.length < IkkiuchiLayout.rowLimit(homes.rows));

  /// The sides once [card] was sent across as the match was decided: off
  /// the side it lay on, and on top of the other's, after any sent so.
  IkkiuchiSides sentLast(int card) {
    final rest = without(card), toTobi = !tobiCards.contains(card);
    return IkkiuchiSides(
      homes: homes,
      tobi: toTobi ? {...rest.tobiCards, card} : rest.tobiCards,
      player: rest.player,
      onTop: {...rest.onTop, card: toTobi ? IkkiuchiSide.opponent : IkkiuchiSide.player},
    );
  }

  /// The sides once the game has put [cards], on neither, on the
  /// player's one by one by the placing's rules: each at the inner end of
  /// the group with the fewest cards in the row with the fewest, the row
  /// nearest the player and the left group first on a tie; in an open
  /// middle when no group end takes it, and left off with nowhere to go.
  IkkiuchiSides autoPlaced(Iterable<int> cards) {
    var sides = this;
    for (final card in cards) {
      final board = sides.playerBoard;
      // Fewer cards in the row first, then in the group.
      int fewer(ClusterEnd a, ClusterEnd b) {
        final (ra, rb) = (board.side.row(a.row), board.side.row(b.row));
        final rows = ra.cards.length.compareTo(rb.cards.length);
        if (rows != 0) return rows;
        List<int> group(PlacingRow row, ClusterEnd end) => end.part == RowPart.left ? row.left : row.right;
        return group(ra, a).length.compareTo(group(rb, b).length);
      }

      final free = board.freeSpots;
      final ends = [for (final s in free) if (s is ClusterEnd) s];
      // Listed by row, left group first: the first of the fewest wins.
      final spot = ends.isEmpty ? free.firstOrNull : ends.reduce((a, b) => fewer(b, a) < 0 ? b : a);
      if (spot != null) sides = sides.placed(card, spot) ?? sides;
    }
    return sides;
  }

  /// The sides with [card], on neither, put at [spot] on the player's;
  /// null when it may not go there.
  IkkiuchiSides? placed(int card, PlacingSpot spot) {
    final board = without(card).playerBoard.put(card, spot);
    if (board == null) return null;
    return IkkiuchiSides(
      homes: homes,
      tobi: tobiCards.where((c) => c != card),
      player: [
        for (final r in FieldRow.values.take(player.length))
          IkkiuchiRow(board.side.row(r).left, board.side.row(r).right.reversed.toList(),
              middle: board.side.row(r).middle),
      ],
      onTop: {...onTop}..remove(card),
    );
  }
}
