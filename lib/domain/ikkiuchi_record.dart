import '../config/config.dart';
import 'field_parts.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_match.dart';
import 'ikkiuchi_mode.dart';
import 'ikkiuchi_rating.dart';
import 'ikkiuchi_side.dart';
import 'xp.dart';

/// Who a 一騎打ち match is played against, across the board. Stored by
/// name.
enum IkkiuchiOpponent { tobi }

/// A match's setup: ranked or free play, its mode, the opponent and their
/// rating, the cards dealt to each side, the rows each side is laid out in,
/// and the memory time before play.
class IkkiuchiSetup {
  const IkkiuchiSetup({
    required this.ranked,
    required this.mode,
    required this.opponent,
    required this.opponentRating,
    required this.perSide,
    required this.rows,
    required this.memorise,
  });

  /// A free match against Tobi: a custom one, of no mode.
  const IkkiuchiSetup.free({
    required this.opponentRating,
    required this.perSide,
    required this.memorise,
    this.rows = IkkiuchiFreeTuning.rows,
  })  : ranked = false,
        mode = null,
        opponent = IkkiuchiOpponent.tobi;

  /// A ranked match of [mode] against Tobi at [opponentRating], each side
  /// laid out in [rows]: the mode's cards and memory time.
  IkkiuchiSetup.ranked(IkkiuchiMode this.mode, {required this.opponentRating, required this.rows})
      : ranked = true,
        opponent = IkkiuchiOpponent.tobi,
        perSide = mode.perSide,
        memorise = mode.memorise;

  /// The free setup before any free match.
  static const firstFree = IkkiuchiSetup.free(
    opponentRating: IkkiuchiFreeTuning.rating,
    perSide: IkkiuchiFreeTuning.perSide,
    memorise: IkkiuchiFreeTuning.memorise,
  );

  final bool ranked;

  /// The ranked mode it was played in; null for a custom match.
  final IkkiuchiMode? mode;
  final IkkiuchiOpponent opponent;
  final double opponentRating;
  final int perSide;
  final int rows;
  final Duration memorise;
}

/// How a match ended for the player.
enum IkkiuchiResult {
  /// Played to its end with fewer cards left than the opponent: the
  /// player's side was emptied first.
  won,

  /// Played to its end otherwise.
  lost,

  /// The player ended it (終了) or left it before its end; a loss when
  /// ranked.
  gaveUp;

  /// How a match ended that was [completed] or not, with [playerLeft] and
  /// [opponentLeft] cards on the sides.
  static IkkiuchiResult of({required bool completed, required int playerLeft, required int opponentLeft}) =>
      !completed
          ? gaveUp
          : playerLeft < opponentLeft
              ? won
              : lost;
}

/// A place on one side of the field: its row, the part of the row, and the
/// place in that part, a group's counted from its outer edge in and the
/// open middle's from the left.
class IkkiuchiSpot {
  const IkkiuchiSpot(this.side, this.row, this.part, this.index);

  final IkkiuchiSide side;
  final FieldRow row;
  final RowPart part;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is IkkiuchiSpot && other.side == side && other.row == row && other.part == part && other.index == index;

  @override
  int get hashCode => Object.hash(side, row, part, index);

  @override
  String toString() => 'IkkiuchiSpot(${side.name}, ${row.name}, ${part.name}, $index)';
}

/// Both sides of the field as they lay, each as its owner sees it: its
/// rows 下段 first, each group from its outer edge in and the open middle
/// left to right (the opponent's open middles hold only the cards sent to
/// him as the match was decided).
class IkkiuchiLaidField {
  const IkkiuchiLaidField({required this.opponent, required this.player});

  /// A field stored by [toJson].
  factory IkkiuchiLaidField.fromJson(Map<String, dynamic> json) {
    List<int> ids(List cards) => [for (final id in cards) id as int];
    List<IkkiuchiRow> rows(IkkiuchiSide side) => [
          for (final row in json[side.name] as List)
            switch (row) {
              [final List left, final List middle, final List right] =>
                IkkiuchiRow(ids(left), ids(right), middle: ids(middle)),
              _ => throw FormatException('Not a row: $row'),
            },
        ];
    return IkkiuchiLaidField(opponent: rows(IkkiuchiSide.opponent), player: rows(IkkiuchiSide.player));
  }

  /// No card on either side.
  static const empty = IkkiuchiLaidField(opponent: [], player: []);

  final List<IkkiuchiRow> opponent, player;

  List<IkkiuchiRow> of(IkkiuchiSide side) => side == IkkiuchiSide.opponent ? opponent : player;

  /// Every card on [side].
  List<int> cardsOf(IkkiuchiSide side) => [
        for (final r in of(side)) ...[...r.left, ...r.middle, ...r.right],
      ];

  /// Where [card] lies; null when it lies on neither side.
  IkkiuchiSpot? spotOf(int card) {
    for (final side in IkkiuchiSide.values) {
      for (final (r, row) in of(side).indexed) {
        for (final part in RowPart.values) {
          final at = _part(row, part).indexOf(card);
          if (at >= 0) return IkkiuchiSpot(side, FieldRow.values[r], part, at);
        }
      }
    }
    return null;
  }

  /// The field with [card] off whichever side holds it.
  IkkiuchiLaidField without(int card) {
    List<IkkiuchiRow> drop(List<IkkiuchiRow> rows) => [
          for (final r in rows)
            IkkiuchiRow([...r.left]..remove(card), [...r.right]..remove(card), middle: [...r.middle]..remove(card)),
        ];
    return IkkiuchiLaidField(opponent: drop(opponent), player: drop(player));
  }

  /// The field once [sent] went across: off the side it lay on, and laid at
  /// its place on the other. Unchanged when the card lies on neither side.
  IkkiuchiLaidField withSent(IkkiuchiSent sent) {
    final from = spotOf(sent.card)?.side;
    if (from == null) return this;
    final to = from == IkkiuchiSide.opponent ? IkkiuchiSide.player : IkkiuchiSide.opponent;
    return without(sent.card).laidAt(sent.card, IkkiuchiSpot(to, sent.row, sent.part, sent.index));
  }

  /// The field with [card] laid at [spot] too, wherever else it lies; a
  /// place past the end of its part is the part's end.
  IkkiuchiLaidField laidAt(int card, IkkiuchiSpot spot) {
    final rows = [
      ...of(spot.side),
      for (var r = of(spot.side).length; r <= spot.row.index; r++) const IkkiuchiRow([], []),
    ];
    final parts = [
      for (final part in RowPart.values) [..._part(rows[spot.row.index], part)],
    ];
    final into = parts[spot.part.index];
    into.insert(spot.index.clamp(0, into.length), card);
    rows[spot.row.index] =
        IkkiuchiRow(parts[RowPart.left.index], parts[RowPart.right.index], middle: parts[RowPart.middle.index]);
    return spot.side == IkkiuchiSide.opponent
        ? IkkiuchiLaidField(opponent: rows, player: player)
        : IkkiuchiLaidField(opponent: opponent, player: rows);
  }

  static List<int> _part(IkkiuchiRow row, RowPart part) => switch (part) {
        RowPart.left => row.left,
        RowPart.middle => row.middle,
        RowPart.right => row.right,
      };

  /// The field as JSON: each side's rows by its name, each row its left
  /// group, open middle and right group.
  Map<String, Object> toJson() => {
        for (final side in IkkiuchiSide.values)
          side.name: [
            for (final r in of(side)) [r.left, r.middle, r.right],
          ],
      };
}

/// A fault (お手つき): who made it, the card touched, and when, from the
/// deciding sound of the card read (negative before it).
class IkkiuchiFault {
  const IkkiuchiFault(this.by, this.card, this.at);

  /// A fault stored by [toJson].
  factory IkkiuchiFault.fromJson(List<dynamic> json) => switch (json) {
        [final String by, final int card, final int us] =>
          IkkiuchiFault(IkkiuchiSide.values.byName(by), card, Duration(microseconds: us)),
        _ => throw FormatException('Not a fault: $json'),
      };

  final IkkiuchiSide by;
  final int card;
  final Duration at;

  /// The fault as JSON: who made it, the card and when, µs.
  List<Object> toJson() => [by.name, card, at.inMicroseconds];
}

/// A 送り札: the card sent, and where it was laid on the side it went to:
/// its row, the part of the row and its place there (as [IkkiuchiSpot]).
class IkkiuchiSent {
  const IkkiuchiSent(this.card, this.row, this.part, this.index);

  /// [card] laid at [spot].
  IkkiuchiSent.at(this.card, IkkiuchiSpot spot)
      : row = spot.row,
        part = spot.part,
        index = spot.index;

  /// A 送り札 stored by [toJson].
  factory IkkiuchiSent.fromJson(List<dynamic> json) => switch (json) {
        [final int card, final int row, final String part, final int index] =>
          IkkiuchiSent(card, FieldRow.values[row], RowPart.values.byName(part), index),
        _ => throw FormatException('Not a 送り札: $json'),
      };

  final int card;
  final FieldRow row;
  final RowPart part;
  final int index;

  /// The 送り札 as JSON: the card, the row (0 is 下段), the part and the
  /// place in it.
  List<Object> toJson() => [card, row.index, part.name, index];
}

/// One read of a match, once it has ended: the card read ([poemId]), the
/// side it lay on and who took it, both null on a からふだ; whether both
/// took it at the same time; the sides each player faulted on (お手つき),
/// 0 to 2; when each reached the card from its deciding sound, negative
/// for one before it, null for one who never did; the [field] it was
/// played on, every fault made on it and the 送り札 it left.
class IkkiuchiReadLog {
  const IkkiuchiReadLog({
    required this.poemId,
    this.cardSide,
    this.taker,
    this.tied = false,
    this.playerFaults = 0,
    this.opponentFaults = 0,
    this.playerTake,
    this.opponentTake,
    this.field = IkkiuchiLaidField.empty,
    this.faults = const [],
    this.sends = const [],
  });

  /// [poemId]'s read on [field], which ended in [end] with [faults].
  IkkiuchiReadLog.of(this.poemId, IkkiuchiReadEnd end,
      {this.playerTake, this.opponentTake, this.field = IkkiuchiLaidField.empty, this.faults = const []})
      : cardSide = end.cardSide,
        taker = end.taker,
        tied = end.tied,
        playerFaults = end.playerFaults.length,
        opponentFaults = end.tobiFaults.length,
        sends = const [];

  final int poemId;
  final IkkiuchiSide? cardSide, taker;
  final bool tied;
  final int playerFaults, opponentFaults;
  final Duration? playerTake, opponentTake;

  /// Both sides as the read began: 並べ替え and 送り札 are made only between
  /// the reads, so the whole read was played on it.
  final IkkiuchiLaidField field;

  /// Every fault made on it, in the order made: each card a player touched
  /// that was a fault, at its first such touch.
  final List<IkkiuchiFault> faults;

  /// The 送り札 made after it, in order.
  final List<IkkiuchiSent> sends;

  bool get karafuda => cardSide == null;

  /// What its end said, as the match's banner said it.
  List<IkkiuchiCallout> get callouts => IkkiuchiReadEnd.calloutsOf(
      tied: tied, karafuda: karafuda, taker: taker, playerFaults: playerFaults, tobiFaults: opponentFaults);

  /// When [side] reached the card; null for one who never did.
  Duration? takeOf(IkkiuchiSide side) => side == IkkiuchiSide.player ? playerTake : opponentTake;

  /// This read with [sent] made after it too.
  IkkiuchiReadLog withSent(IkkiuchiSent sent) => IkkiuchiReadLog(
        poemId: poemId,
        cardSide: cardSide,
        taker: taker,
        tied: tied,
        playerFaults: playerFaults,
        opponentFaults: opponentFaults,
        playerTake: playerTake,
        opponentTake: opponentTake,
        field: field,
        faults: faults,
        sends: [...sends, sent],
      );
}

/// A match once it is over, as it is stored: its setup, when it ran, the
/// memory time it used, whether it was played to its end, the cards left
/// on each side, and every read in order. Its [id], the player's [rating]
/// after a ranked match and the experience it earned ([xp]) come with
/// storing it ([stored]).
class IkkiuchiMatchRecord {
  const IkkiuchiMatchRecord({
    this.id,
    required this.setup,
    required this.startedAt,
    required this.endedAt,
    this.memorised = Duration.zero,
    required this.completed,
    required this.playerLeft,
    required this.opponentLeft,
    this.rating,
    this.xp,
    this.reads = const [],
  });

  /// Its row's id; null until it is stored.
  final int? id;

  final IkkiuchiSetup setup;
  final DateTime startedAt, endedAt;

  /// The memory time used: from the start of the placing to the first
  /// read, cut short when the player was ready early (覚えた).
  final Duration memorised;

  /// Played to its end, a side emptied; false when the player ended it
  /// (終了) or left it.
  final bool completed;

  final int playerLeft, opponentLeft;

  /// The player's 一騎打ち rating in its mode after this ranked match; null
  /// for free play, and until it is stored.
  final double? rating;

  /// The experience it earned, settled as it was stored; null until then.
  final XpAward? xp;

  final List<IkkiuchiReadLog> reads;

  bool get ranked => setup.ranked;

  /// How many cards fewer the player had left than the opponent at the
  /// end; negative when they had more.
  int get margin => opponentLeft - playerLeft;

  IkkiuchiResult get result =>
      IkkiuchiResult.of(completed: completed, playerLeft: playerLeft, opponentLeft: opponentLeft);

  /// This match as the rating reads it.
  IkkiuchiRatedMatch get rated => (opponentRating: setup.opponentRating, won: result == IkkiuchiResult.won);

  /// The faults (お手つき) each made over the match, a fault on both sides of
  /// one read counting two.
  int get playerFaults => reads.fold(0, (n, r) => n + r.playerFaults);
  int get opponentFaults => reads.fold(0, (n, r) => n + r.opponentFaults);

  /// The cards [side] took, ties among them.
  int takenBy(IkkiuchiSide side) => reads.where((r) => r.taker == side).length;

  /// [side]'s median time to the field cards read that they reached; null
  /// when they reached none.
  Duration? medianTake(IkkiuchiSide side) => medianOf([
        for (final r in reads)
          if (!r.karafuda) ?r.takeOf(side),
      ]);

  /// The median of [times]; null when there are none.
  static Duration? medianOf(Iterable<Duration> times) {
    if (times.isEmpty) return null;
    final sorted = [...times]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) ~/ 2;
  }

  /// This match as stored, under [id], with the player's [rating] after it
  /// and the [xp] it earned.
  IkkiuchiMatchRecord stored({required int id, required double? rating, required XpAward xp}) => IkkiuchiMatchRecord(
        id: id,
        setup: setup,
        startedAt: startedAt,
        endedAt: endedAt,
        memorised: memorised,
        completed: completed,
        playerLeft: playerLeft,
        opponentLeft: opponentLeft,
        rating: rating,
        xp: xp,
        reads: reads,
      );
}
