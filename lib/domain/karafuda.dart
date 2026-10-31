import 'dart:math' as math;

import '../config/config.dart';
import '../data/poem.dart';
import 'ankiren_tomofuda.dart';

/// からふだ (空札): in a real match half the cards read are not on the field.
/// A game of 暗記練 or 定位置 calls some known cards that are not on its board
/// among its own, and the player answers each with the からふだ button,
/// which on any other call is a wrong tap, as one on the other side.
/// How many a board calls: [forAnkiren], [forTeiichi]; which ones:
/// [KarafudaPicker]; in what order: [order].
abstract final class Karafuda {
  /// A tap's card when the tap was on the からふだ button: no poem's id.
  static const int button = 0;

  /// [per] for every [perCards] of [cards], rounded up.
  static int share(int cards, int per, int perCards) => (cards * per + perCards - 1) ~/ perCards;

  /// 暗記練's からふだ for a field of [cards] (see [AnkirenTuning.karafudaPer]).
  static int forAnkiren(int cards) => share(cards, AnkirenTuning.karafudaPer, AnkirenTuning.karafudaPerCards);

  /// 定位置's for [cards] laid out (see [TeiichiTuning.karafudaPer]).
  static int forTeiichi(int cards) => share(cards, TeiichiTuning.karafudaPer, TeiichiTuning.karafudaPerCards);

  /// The most a custom game of [cards] may call when [known] cards are
  /// known: no more than its cards, nor than the known cards left over.
  static int customMax(int cards, int known) => math.max(0, math.min(cards, known - cards));

  /// The calls of a game: its [board] cards and [karafuda] in an order [rng]
  /// draws, the last always a board card. Without からふだ the board is
  /// shuffled as it always was.
  static List<int> order(List<int> board, List<int> karafuda, math.Random rng) {
    if (karafuda.isEmpty) return [...board]..shuffle(rng);
    final rest = [...board];
    final last = rest.removeAt(rng.nextInt(rest.length));
    return [...([...rest, ...karafuda]..shuffle(rng)), last];
  }
}

/// The cards a board's からふだ are drawn from: the known cards not on it,
/// split into [similar], each a 友札 of a board card ([friendsOf] says
/// which), and the [rest]; each list by id.
class KarafudaPools {
  const KarafudaPools({required this.similar, required this.rest, required this.friendsOf});

  final List<int> similar, rest;

  /// The board cards each of [similar] is a 友札 of.
  final Map<int, List<int>> friendsOf;

  int get size => similar.length + rest.length;
}

/// Draws a board's からふだ: each from the board cards' 友札 ([AnkirenTomofuda])
/// with [AnkirenTuning.karafudaTomofudaShare], else from the other known
/// cards, and from whichever pool still has cards when one runs out.
class KarafudaPicker {
  KarafudaPicker(this._tomofuda);

  /// Over the real poems' 友札.
  static final KarafudaPicker ofPoems = KarafudaPicker(AnkirenTomofuda(poems).of);

  final List<int> Function(int poemId) _tomofuda;

  static double get bias => AnkirenTuning.karafudaTomofudaShare;

  KarafudaPools pools(Iterable<int> board, Iterable<int> known) {
    final on = board.toSet();
    final similar = <int>[], rest = <int>[];
    final friendsOf = <int, List<int>>{};
    for (final id in {...known}.toList()..sort()) {
      if (on.contains(id)) continue;
      final friends = [for (final f in _tomofuda(id)) if (on.contains(f)) f];
      if (friends.isEmpty) {
        rest.add(id);
      } else {
        similar.add(id);
        friendsOf[id] = friends;
      }
    }
    return KarafudaPools(similar: similar, rest: rest, friendsOf: friendsOf);
  }

  /// [count] からふだ for [board] from [known], fewer only when the known
  /// cards left over are fewer.
  List<int> pick(Iterable<int> board, Iterable<int> known, int count, math.Random rng) =>
      draw(pools(board, known), count, rng);

  static List<int> draw(KarafudaPools pools, int count, math.Random rng) {
    final similar = [...pools.similar], rest = [...pools.rest];
    final picks = <int>[];
    while (picks.length < count && (similar.isNotEmpty || rest.isNotEmpty)) {
      final fromSimilar = rng.nextDouble() < bias;
      final pool = (fromSimilar && similar.isNotEmpty) || rest.isEmpty ? similar : rest;
      picks.add(pool.removeAt(rng.nextInt(pool.length)));
    }
    return picks;
  }

  /// The chance [draw] takes each card of [pools]' similar and rest pools
  /// when it draws [count]: within a pool every card is as likely.
  static ({double similar, double rest}) odds(KarafudaPools pools, int count) {
    final s = pools.similar.length, r = pools.rest.length;
    final n = math.min(count, s + r);
    // How many similar cards are drawn after each draw, with its chance.
    var drawn = <int, double>{0: 1};
    for (var step = 0; step < n; step++) {
      final next = <int, double>{};
      for (final MapEntry(key: i, value: p) in drawn.entries) {
        final similarLeft = s - i, restLeft = r - (step - i);
        final toSimilar = similarLeft == 0 ? 0.0 : (restLeft == 0 ? 1.0 : bias);
        if (toSimilar > 0) next[i + 1] = (next[i + 1] ?? 0) + p * toSimilar;
        if (toSimilar < 1) next[i] = (next[i] ?? 0) + p * (1 - toSimilar);
      }
      drawn = next;
    }
    final expected = drawn.entries.fold(0.0, (sum, e) => sum + e.key * e.value);
    return (similar: s == 0 ? 0 : expected / s, rest: r == 0 ? 0 : (n - expected) / r);
  }
}

/// One call as [KarafudaTally] counts it: a からふだ's or a field card's,
/// whether it was found (the button pressed, or the card tapped), the
/// wrong taps on it, and what the taps that count hit.
typedef KarafudaCall = ({bool karafuda, bool found, int wrongTaps, List<int> tapped});

/// How a game's からふだ went: its calls ([called]); those answered with the
/// first press ([right]), after a card was tapped ([late]), or never
/// ([missed]: given up, or the game ended first); the cards tapped on them
/// ([touched]); and the presses of the button on a field card's call
/// ([wrongPresses]), of the taps that count (`AnkirenTuning.tapWeights`).
class KarafudaTally {
  const KarafudaTally({
    this.called = 0,
    this.right = 0,
    this.late = 0,
    this.touched = 0,
    this.wrongPresses = 0,
  });

  factory KarafudaTally.of(Iterable<KarafudaCall> calls) {
    var called = 0, right = 0, late = 0, touched = 0, wrongPresses = 0;
    for (final c in calls) {
      if (!c.karafuda) {
        wrongPresses += c.tapped.where((t) => t == Karafuda.button).length;
        continue;
      }
      called++;
      touched += c.wrongTaps;
      if (c.found) c.wrongTaps == 0 ? right++ : late++;
    }
    return KarafudaTally(called: called, right: right, late: late, touched: touched, wrongPresses: wrongPresses);
  }

  final int called, right, late, touched, wrongPresses;

  int get missed => called - right - late;

  /// The game called none: it is shown as before からふだ.
  bool get none => called == 0;
}
