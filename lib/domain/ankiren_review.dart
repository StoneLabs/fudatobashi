import 'dart:convert';

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_rating.dart';
import 'ankiren_score.dart';
import 'play_session.dart';
import 'rating.dart';
import 'xp.dart';

/// The keys of a recorded 暗記練 game's details (its run's meta JSON).
abstract final class AnkirenMeta {
  static const perSideKey = 'perSide';
  static const memoriseKey = 'memoriseMs';
  static const middleKey = 'middle';
  static const memorisedKey = 'memorisedMs';

  /// The dealt field (`AnkirenField.toJson`); missing from games recorded
  /// before the deal was kept.
  static const dealKey = 'deal';

  /// For each card asked, in order, the cards its counted taps hit.
  static const tappedKey = 'tapped';
}

/// One card of a recorded 暗記練 game and how it was answered (see
/// `AnkirenAnswer`), with the cards its taps hit when the game kept them.
class AnkirenCardTry {
  const AnkirenCardTry({
    required this.poemId,
    required this.wrongTaps,
    required this.responseUs,
    required this.taps,
    required this.firstTapUs,
    this.tapped = const [],
  });

  final int poemId;
  final int wrongTaps;
  final int? responseUs;
  final List<TapProximity> taps;
  final int? firstTapUs;

  /// The card each of [taps] hit; empty when not recorded.
  final List<int> tapped;

  TapProximity? get first => taps.firstOrNull;
  bool get found => responseUs != null;
  bool get firstTry => found && wrongTaps == 0;

  /// The card had to be shown after wrong taps.
  bool get shown => wrongTaps >= AnkirenTuning.revealAfterWrong;

  /// Its find time, ms, when it was found with a valid time.
  double? get findMs => found && Attempt.isValidTime(responseUs!) ? responseUs! / 1000 : null;

  /// Its card points (see [AnkirenScore.points]).
  int get points => AnkirenScore.pointsOf(taps, firstTapUs);

  /// The part of [points] its speed earned.
  int get speed =>
      firstTapUs == null ? 0 : (AnkirenScore.speedWeight(taps) * AnkirenScore.speedBonus(firstTapUs!)).round();

  /// The part of [points] tap [i] earned where it landed.
  int tapPoints(int i) => i < taps.length
      ? (AnkirenTuning.cardPoints * AnkirenTuning.tapWeights[i] * AnkirenTuning.tapShare[taps[i]]!).round()
      : 0;
}

/// A recorded 暗記練 game as History reviews it: its setup, its result
/// and every card asked, with the dealt field when it was kept.
class AnkirenGameRecord {
  /// A game from its stored run: [meta] is its details' JSON (see
  /// [AnkirenMeta]).
  factory AnkirenGameRecord({
    required int id,
    required DateTime startedAt,
    required bool ranked,
    required int? level,
    required int? score,
    required int? maxScore,
    required bool completed,
    required double? rating,
    required double? performance,
    required String meta,
    required List<AnkirenCardTry> cards,
  }) =>
      AnkirenGameRecord._(id, startedAt, ranked, level, score, maxScore, completed, rating, performance,
          jsonDecode(meta) as Map<String, dynamic>, cards);

  AnkirenGameRecord._(this.id, this.startedAt, this.ranked, this.level, this.score, this.maxScore, this.completed,
      this.rating, this.performance, Map<String, dynamic> meta, List<AnkirenCardTry> cards)
      : perSide = meta[AnkirenMeta.perSideKey] as int? ?? 0,
        memorise = Duration(milliseconds: meta[AnkirenMeta.memoriseKey] as int? ?? 0),
        memorised = Duration(milliseconds: meta[AnkirenMeta.memorisedKey] as int? ?? 0),
        deal = switch (meta[AnkirenMeta.dealKey]) {
          final Map<String, dynamic> json => AnkirenField.fromJson(json),
          _ => null,
        },
        cards = List.unmodifiable([
          for (final (i, c) in cards.indexed)
            switch ((meta[AnkirenMeta.tappedKey] as List?)?.elementAtOrNull(i)) {
              final List<dynamic> hit => AnkirenCardTry(
                  poemId: c.poemId,
                  wrongTaps: c.wrongTaps,
                  responseUs: c.responseUs,
                  taps: c.taps,
                  firstTapUs: c.firstTapUs,
                  tapped: [for (final id in hit) id as int],
                ),
              _ => c,
            },
        ]);

  final int id;
  final DateTime startedAt;
  final bool ranked;

  /// The level played and the score; null for a custom setup.
  final int? level;
  final int? score, maxScore;
  final bool completed;

  /// 暗記練's rating after the game and its performance; null for free play.
  final double? rating, performance;
  final int perSide;

  /// The memorise time allowed, and how much of it was used.
  final Duration memorise, memorised;

  /// The field as dealt; null for a game recorded before it was kept.
  final AnkirenField? deal;

  /// One per card asked, in order.
  final List<AnkirenCardTry> cards;

  bool get scored => level != null && score != null;
  int get firstTaps => cards.where((c) => c.firstTry).length;
  int get found => cards.where((c) => c.found).length;

  /// How many first taps landed where (cards never tapped are left out).
  Map<TapProximity, int> get mix => AnkirenReview.mixOf([this]);

  /// The median find time of the cards found with a valid time, ms.
  double? get medianFindMs => AnkirenReview.median([for (final c in cards) ?c.findMs]);

  /// The card points, out of [maxRecall], and their share.
  int get recall => cards.fold(0, (sum, c) => sum + c.points);
  int get maxRecall => AnkirenScore.maxFor(cards.length);
  double get fraction => maxRecall == 0 ? 0 : recall / maxRecall;

  /// The share of the memorise time left unused, and what it multiplies
  /// the card points by.
  double get timeLeft =>
      memorise == Duration.zero ? 0 : (1 - memorised.inMicroseconds / memorise.inMicroseconds).clamp(0.0, 1.0);
  double get earlyFactor => 1 + AnkirenTuning.earlyBonus * timeLeft;

  /// The level's factor (see [AnkirenScore.factorFor]); 1 for a custom setup.
  double get levelFactor => level == null ? 1 : AnkirenScore.factorFor(level!);

  /// Played with the same setup as [other]: the same level, or both custom
  /// with as many cards a side.
  bool sameSetup(AnkirenGameRecord other) =>
      level != null ? other.level == level : other.level == null && other.perSide == perSide;

  /// The cards on [side] of [deal] and how many of them were found with the
  /// first tap; null without a deal.
  ({int right, int of})? rightFirstOn(FieldSide side) {
    final deal = this.deal;
    if (deal == null) return null;
    final on = cards.where((c) => deal.sideOf(c.poemId) == side);
    return (right: on.where((c) => c.firstTry).length, of: on.length);
  }
}

/// How one score part of a game added up: the cards that earned it and
/// their points.
typedef AnkirenScorePart = ({int cards, int points});

/// A card the player keeps placing wrong over all the games: how often it
/// was dealt, found with the first tap, and where its wrong first taps
/// usually landed.
typedef AnkirenMisplaced = ({int poemId, int dealt, int rightFirst, TapProximity? usual});

/// The class a rating sits in, the next one and how far toward it.
typedef AnkirenClassProgress = ({RankBand band, RankBand? next, double fraction});

/// One 暗記練 [game] against the games recorded before it ([all] holds
/// every recorded game, this one among them), with the [xp] it earned.
class AnkirenReview {
  AnkirenReview(this.game, List<AnkirenGameRecord> all, {this.xp})
      : _all = all,
        _earlier = [for (final g in all) if (g.id < game.id) g];

  final AnkirenGameRecord game;
  final XpGain? xp;
  final List<AnkirenGameRecord> _all;
  final List<AnkirenGameRecord> _earlier;

  /// The earlier games with the same setup, oldest first.
  late final List<AnkirenGameRecord> peers = [for (final g in _earlier) if (game.sameSetup(g)) g];

  AnkirenGameRecord? get last => peers.lastOrNull;

  /// The best scored game played to the end among [peers].
  AnkirenGameRecord? get bestBefore {
    AnkirenGameRecord? best;
    for (final g in peers) {
      if (g.completed && g.score != null && (best == null || g.score! > best.score!)) best = g;
    }
    return best;
  }

  /// A scored game played to the end that beat [bestBefore].
  bool get isBest {
    final best = bestBefore;
    return game.completed && game.scored && best != null && game.score! > best.score!;
  }

  /// Where the first taps of [peers] landed, all together.
  Map<TapProximity, int> get usualMix => mixOf(peers);

  /// 暗記練's rating before a ranked game: the last earlier ranked game's,
  /// or the start; null for free play.
  double? get ratingBefore => game.rating == null ? null : _rated.lastOrNull?.rating ?? AnkirenRating.start;

  List<AnkirenGameRecord> get _rated => [for (final g in _earlier) if (g.ranked && g.rating != null) g];

  /// How far a ranked game moved the rating toward its performance.
  double get k => AnkirenRating.isPlacement(_rated.length)
      ? AnkirenRatingModel.placementK
      : AnkirenRatingModel.establishedK;

  /// The score parts (see [AnkirenScore.pointsOf]): right first taps, near
  /// first taps, second taps and the speed bonus.
  AnkirenScorePart get rightFirst => _part((c) => c.first == TapProximity.card, (c) => c.tapPoints(0));
  AnkirenScorePart get nearFirst =>
      _part((c) => c.first != null && c.first != TapProximity.card, (c) => c.tapPoints(0));
  AnkirenScorePart get secondTaps => _part((c) => c.taps.length > 1, (c) => c.tapPoints(1));
  AnkirenScorePart get speed => _part((c) => c.speed > 0, (c) => c.speed);

  AnkirenScorePart _part(bool Function(AnkirenCardTry) counts, int Function(AnkirenCardTry) points) {
    final cards = game.cards.where(counts);
    return (cards: cards.length, points: cards.fold(0, (sum, c) => sum + points(c)));
  }

  /// This game's cards that every game so far shows the player placing
  /// wrong: dealt at least [AnkirenReviewTuning.misplacedMinDealt] times,
  /// not always found with the first tap, the least often found first.
  List<AnkirenMisplaced> get misplaced {
    final asked = {for (final c in game.cards) c.poemId};
    final tries = <int, List<AnkirenCardTry>>{};
    for (final g in _all) {
      for (final c in g.cards) {
        if (asked.contains(c.poemId)) (tries[c.poemId] ??= []).add(c);
      }
    }
    final rows = [
      for (final MapEntry(key: id, value: list) in tries.entries)
        if (list.length >= AnkirenReviewTuning.misplacedMinDealt)
          (
            poemId: id,
            dealt: list.length,
            rightFirst: list.where((c) => c.firstTry).length,
            usual: _usual([for (final c in list) if (c.first != TapProximity.card) ?c.first]),
          ),
    ]..removeWhere((r) => r.rightFirst == r.dealt);
    rows.sort((a, b) {
      final byShare = (a.rightFirst / a.dealt).compareTo(b.rightFirst / b.dealt);
      return byShare != 0 ? byShare : b.dealt.compareTo(a.dealt);
    });
    return rows.take(AnkirenReviewTuning.misplacedRows).toList();
  }

  /// The commonest of [places], the nearest on a tie; null when empty.
  static TapProximity? _usual(List<TapProximity> places) {
    TapProximity? usual;
    var most = 0;
    for (final p in TapProximity.values) {
      final n = places.where((x) => x == p).length;
      if (n > most) (usual, most) = (p, n);
    }
    return usual;
  }

  /// Where the first taps of [games] landed, all together.
  static Map<TapProximity, int> mixOf(Iterable<AnkirenGameRecord> games) {
    final mix = {for (final p in TapProximity.values) p: 0};
    for (final g in games) {
      for (final c in g.cards) {
        if (c.first case final p?) mix[p] = mix[p]! + 1;
      }
    }
    return mix;
  }

  /// The median of [values], or null when there are none.
  static double? median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// The mean of [values], or null when there are none.
  static double? mean(Iterable<num> values) =>
      values.isEmpty ? null : values.fold(0.0, (sum, v) => sum + v) / values.length;

  /// [rating]'s class, the next one and how far toward it, from the class's
  /// floor (the start for the lowest).
  static AnkirenClassProgress classProgress(double rating) {
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : AnkirenRating.start;
    final fraction = next == null ? 1.0 : ((rating - floor) / (next.minRating - floor)).clamp(0.0, 1.0);
    return (band: band, next: next, fraction: fraction);
  }
}
