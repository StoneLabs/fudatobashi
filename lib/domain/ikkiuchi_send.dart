import 'dart:math' as math;

import '../config/config.dart';
import 'field_parts.dart';
import 'ikkiuchi_layout.dart';
import 'placing.dart';

/// Both sides of a match (一騎打ち) as they stand, and how a 送り札 changes
/// them. Tobi's side is always laid out by his [homes]: each card he has
/// at its home, his groups packed to the side's edges. The player's lies as
/// the player laid it.
///
/// A card the player sends him goes to its home on his side. A card he
/// sends the player is theirs to place by [IkkiuchiSides.rules]: at the
/// inner end of any group, or on any card's place (the cards inward of it
/// moving a place in), in any of their rows, each at most
/// [IkkiuchiLayoutTuning.rowSlots] pitches across with its groups
/// [IkkiuchiLayoutTuning.groupGap] apart.
class IkkiuchiSides {
  IkkiuchiSides({required this.homes, required Iterable<int> tobi, required List<IkkiuchiRow> player})
      : tobiCards = Set.unmodifiable(tobi),
        player = List.unmodifiable(player);

  /// The start of a match: Tobi's own cards at their homes, and the
  /// player's side as laid out.
  IkkiuchiSides.start(IkkiuchiHomes homes, List<IkkiuchiRow> player)
      : this(homes: homes, tobi: homes.own, player: player);

  final IkkiuchiHomes homes;
  final Set<int> tobiCards;

  /// The player's rows, 下段 first, each group from its outer edge in.
  final List<IkkiuchiRow> player;

  /// Tobi's rows, 下段 first, each group from its outer edge in.
  late final List<IkkiuchiRow> tobi = homes.sideWith(tobiCards);

  List<int> get playerCards => [for (final r in player) ...[...r.left, ...r.right]];

  /// The placing rules of a player's side of [rows] rows: no open middle,
  /// and each row's room.
  static PlacingRules rules(int rows) => PlacingRules(
        rows: FieldRow.values.take(rows).toList(),
        room: const RowRoom(
          slots: IkkiuchiLayoutTuning.rowSlots,
          clusterGap: IkkiuchiLayoutTuning.groupGap,
          middleMargin: 0,
        ),
      );

  /// The player's side as the placing rules have it: each right group from
  /// its inner end out.
  PlacingBoard get playerBoard => PlacingBoard(
        rules(player.length),
        PlacingSide([
          for (final r in FieldRow.values)
            r.index < player.length
                ? PlacingRow(left: player[r.index].left, middle: const [], right: player[r.index].right.reversed.toList())
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
  /// homes, the player's group closing up.
  IkkiuchiSides without(int card) => IkkiuchiSides(
        homes: homes,
        tobi: tobiCards.where((c) => c != card),
        player: [
          for (final r in player)
            IkkiuchiRow([
              for (final c in r.left)
                if (c != card) c,
            ], [
              for (final c in r.right)
                if (c != card) c,
            ]),
        ],
      );

  /// The sides once the player sent Tobi [card]: off theirs, and at its
  /// home on his.
  IkkiuchiSides toTobi(int card) {
    final rest = without(card);
    return IkkiuchiSides(homes: homes, tobi: {...rest.tobiCards, card}, player: rest.player);
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
          IkkiuchiRow(board.side.row(r).left, board.side.row(r).right.reversed.toList()),
      ],
    );
  }
}
