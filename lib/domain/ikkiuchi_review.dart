import '../config/config.dart';
import 'field_parts.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_rating.dart';
import 'ikkiuchi_record.dart';
import 'ikkiuchi_side.dart';
import 'rating.dart';
import 'xp.dart';

/// Where a card on the field went in the end: the player or the opponent
/// took it, both took it at the same time (同時, the card going to the side
/// it lay on), or it was still on the field as the match ended (残り札).
enum IkkiuchiCardEnd { player, opponent, tied, left }

/// A touch on a read, in the order the replay numbers them: who touched
/// which card and when, from the deciding sound of the card read; a [fault]
/// (お手つき), else a reach of the card read; and for a fault, whether the
/// card touched is a look-alike (友札) of the card read.
typedef IkkiuchiTouch = ({IkkiuchiSide by, int card, Duration at, bool fault, bool lookAlike});

/// A 送り札 as the replay shows it: the card, and the side and place it
/// was laid on.
typedef IkkiuchiSentTo = ({int card, IkkiuchiSpot to});

/// How the field cards read in one part of the field went: those read
/// while lying there, and those the player took.
typedef IkkiuchiTakes = ({int took, int read});

/// The field cards read with a kimariji of [length] kana: how many, the
/// player's takes among them, and each player's median time to reach them.
typedef IkkiuchiLengthSpeed = ({int length, int read, int took, Duration? player, Duration? opponent});

/// The class a rating sits in, the next one, and how far toward it.
typedef IkkiuchiClassProgress = ({RankBand band, RankBand? next, double fraction});

/// One stored 一騎打ち [match] against the matches recorded before it
/// ([all] holds every recorded match, this one among them), with the [xp]
/// it earned, as History's match page shows it.
class IkkiuchiReview {
  IkkiuchiReview(this.match, List<IkkiuchiMatchRecord> all, {this.xp})
      : earlier = List.unmodifiable([for (final m in all) if (m.id! < match.id!) m]);

  final IkkiuchiMatchRecord match;
  final XpGain? xp;

  /// The matches recorded before it, oldest first.
  final List<IkkiuchiMatchRecord> earlier;

  static final _layout = IkkiuchiLayout.ofPoems();

  // The match as a whole.

  /// From its start to its end, the memory time included.
  Duration get matchTime => match.endedAt.difference(match.startedAt);

  /// The reads of a card on the field, in order: every read but the
  /// からふだ.
  List<IkkiuchiReadLog> get fieldReads => [for (final r in match.reads) if (!r.karafuda) r];

  /// The cards the opponent took that the player reached too, though not at
  /// the same time: the player's slowest first.
  List<IkkiuchiReadLog> get beaten => [
        for (final r in fieldReads)
          if (r.taker == IkkiuchiSide.opponent && !r.tied && r.playerTake != null) r,
      ]..sort((a, b) => b.playerTake!.compareTo(a.playerTake!));

  /// The player's takes, the fastest first.
  List<IkkiuchiReadLog> get fastestTakes => [
        for (final r in fieldReads)
          if (r.taker == IkkiuchiSide.player && r.playerTake != null) r,
      ]..sort((a, b) => a.playerTake!.compareTo(b.playerTake!));

  /// The field cards read by the length of their kimariji, as
  /// [kimarijiLength] counts it, shortest first.
  List<IkkiuchiLengthSpeed> byKimariji(int Function(int poemId) kimarijiLength) {
    final groups = <int, List<IkkiuchiReadLog>>{};
    for (final r in fieldReads) {
      (groups[kimarijiLength(r.poemId)] ??= []).add(r);
    }
    return [
      for (final length in groups.keys.toList()..sort())
        (
          length: length,
          read: groups[length]!.length,
          took: groups[length]!.where((r) => r.taker == IkkiuchiSide.player).length,
          player: IkkiuchiMatchRecord.medianOf([for (final r in groups[length]!) ?r.playerTake]),
          opponent: IkkiuchiMatchRecord.medianOf([for (final r in groups[length]!) ?r.opponentTake]),
        ),
    ];
  }

  // The same setup before.

  /// The earlier matches with the same setup, oldest first: every ranked
  /// one for a ranked match; for a free one, those with as many cards a
  /// side, the same memory time and the opponent at the same rating.
  late final List<IkkiuchiMatchRecord> peers = [for (final m in earlier) if (_sameSetup(m)) m];

  IkkiuchiMatchRecord? get last => peers.lastOrNull;

  bool _sameSetup(IkkiuchiMatchRecord other) {
    final a = match.setup, b = other.setup;
    if (a.ranked || b.ranked) return a.ranked && b.ranked;
    return a.perSide == b.perSide && a.memorise == b.memorise && a.opponentRating == b.opponentRating;
  }

  // The field, read by read.

  /// The field as the first card was read: the sides laid out and moved
  /// about in the memory time. Empty for a match with no read.
  IkkiuchiLaidField get atRest => match.reads.firstOrNull?.field ?? IkkiuchiLaidField.empty;

  /// Where each card on the field at rest went in the end.
  late final Map<int, IkkiuchiCardEnd> cardEnds = () {
    final taken = {
      for (final r in fieldReads)
        if (r.taker case final taker?)
          r.poemId: r.tied
              ? IkkiuchiCardEnd.tied
              : (taker == IkkiuchiSide.player ? IkkiuchiCardEnd.player : IkkiuchiCardEnd.opponent),
    };
    return {
      for (final side in IkkiuchiSide.values)
        for (final card in atRest.cardsOf(side)) card: taken[card] ?? IkkiuchiCardEnd.left,
    };
  }();

  /// Where the card [read] read lay as the read began; null on a からふだ.
  IkkiuchiSpot? spotOf(IkkiuchiReadLog read) => read.field.spotOf(read.poemId);

  /// The touches on [read] in the order they came: both players' reaches
  /// of the card read, and every fault; the player's first on a tie.
  List<IkkiuchiTouch> touchesOf(IkkiuchiReadLog read) => [
        for (final f in read.faults)
          (by: f.by, card: f.card, at: f.at, fault: true, lookAlike: _layout.alike(f.card, read.poemId)),
        for (final by in IkkiuchiSide.values)
          if (read.takeOf(by) case final at? when !read.karafuda)
            (by: by, card: read.poemId, at: at, fault: false, lookAlike: false),
      ]..sort((a, b) => a.at != b.at ? a.at.compareTo(b.at) : b.by.index.compareTo(a.by.index));

  /// The 送り札 made after [read], in order, each with the side it went to.
  List<IkkiuchiSentTo> sentAfter(IkkiuchiReadLog read) {
    var field = _taken(read);
    final sent = <IkkiuchiSentTo>[];
    for (final s in read.sends) {
      final from = field.spotOf(s.card)?.side;
      if (from == null) continue;
      final to = from == IkkiuchiSide.player ? IkkiuchiSide.opponent : IkkiuchiSide.player;
      sent.add((card: s.card, to: IkkiuchiSpot(to, s.row, s.part, s.index)));
      field = field.withSent(s);
    }
    return sent;
  }

  /// The field once [read] was over: the card taken gone, and each
  /// 送り札 made after it laid where it went.
  IkkiuchiLaidField fieldAfter(IkkiuchiReadLog read) =>
      read.sends.fold(_taken(read), (field, s) => field.withSent(s));

  static IkkiuchiLaidField _taken(IkkiuchiReadLog read) =>
      read.taker == null ? read.field : read.field.without(read.poemId);

  /// The field cards read while lying on [side], and those the player took.
  IkkiuchiTakes takesOn(IkkiuchiSide side) => _takes((spot) => spot.side == side);

  /// The field cards read while lying in [row] of either side, and those
  /// the player took.
  IkkiuchiTakes takesInRow(FieldRow row) => _takes((spot) => spot.row == row);

  IkkiuchiTakes _takes(bool Function(IkkiuchiSpot spot) there) {
    final read = [
      for (final r in fieldReads)
        if (spotOf(r) case final spot? when there(spot)) r,
    ];
    return (took: read.where((r) => r.taker == IkkiuchiSide.player).length, read: read.length);
  }

  // The rating.

  /// The ranked matches before it.
  late final List<IkkiuchiMatchRecord> _rankedBefore = [for (final m in earlier) if (m.ranked) m];

  /// The player's rating before this ranked match: the last earlier ranked
  /// match's, which while placing is the estimate so far, from
  /// [IkkiuchiRating.start]; null for free play.
  double? get ratingBefore => match.ranked ? _rankedBefore.lastOrNull?.rating ?? IkkiuchiRating.start : null;

  /// The rating after it, or the estimate while placing; null for free
  /// play.
  double? get ratingAfter => match.rating;

  double? get ratingChange => switch ((ratingBefore, ratingAfter)) {
        (final double before, final double after) => after - before,
        _ => null,
      };

  /// Which of the placement matches this ranked match was, from 1; null
  /// for one after placement, and for free play.
  int? get placementMatch =>
      match.ranked && IkkiuchiRating.isPlacement(_rankedBefore.length) ? _rankedBefore.length + 1 : null;

  /// The matches that place the rating.
  static int get placementMatches => IkkiuchiRating.placementMatches;

  /// Whether this match ended placement: its estimate became the first
  /// rating.
  bool get endedPlacement => match.ranked && IkkiuchiRating.endsPlacement(_rankedBefore.length);

  /// [rating]'s class, the next one and how far toward it, from the
  /// class's floor (the lowest rating Tobi plays at for the lowest class).
  static IkkiuchiClassProgress classProgress(double rating) {
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : IkkiuchiTuning.ratingMin;
    final fraction = next == null ? 1.0 : ((rating - floor) / (next.minRating - floor)).clamp(0.0, 1.0);
    return (band: band, next: next, fraction: fraction);
  }
}
