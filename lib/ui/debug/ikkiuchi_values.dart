import 'dart:math' as math;

import '../../config/config.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../../domain/truncated_normal.dart';
import '../../domain/tuning_curve.dart';
import 'ikkiuchi_groups_dealt.dart';

/// How one of Tobi's values reads, alone, as a range, and on a graph's axis.
enum IkkiuchiUnit {
  ms,
  percent,
  plain;

  String format(double v) => switch (this) {
        ms => v >= Duration.millisecondsPerSecond ? '${_seconds(v)} s' : '${v.round()} ms',
        percent => '${_percent(v)}%',
        plain => v.toStringAsFixed(2),
      };

  /// [lo] to [hi], the unit written once; one value when both read alike.
  String range(double lo, double hi) {
    if (format(lo) == format(hi)) return format(lo);
    return switch (this) {
      ms when hi < Duration.millisecondsPerSecond => '${lo.round()}–${hi.round()} ms',
      ms => '${_seconds(lo)}–${_seconds(hi)} s',
      percent => '${_percent(lo)}–${_percent(hi)}%',
      plain => '${format(lo)}–${format(hi)}',
    };
  }

  /// [v] as a tick on a graph's value axis: no trailing zeros, 0 bare.
  String axis(double v) {
    if (v == 0) return '0';
    return switch (this) {
      ms => v >= Duration.millisecondsPerSecond ? '${_trim(v / Duration.millisecondsPerSecond)} s' : '${v.round()} ms',
      percent => '${_trim(v * 100)}%',
      plain => _trim(v),
    };
  }

  // Seconds from ms: two decimals, one from ten seconds up.
  static String _seconds(double ms) {
    final s = ms / Duration.millisecondsPerSecond;
    return s.toStringAsFixed(s < 10 ? 2 : 1);
  }

  // A share as a percentage: one decimal under 10%.
  static String _percent(double share) {
    final p = share * 100;
    return p.toStringAsFixed(p > 0 && p < 10 ? 1 : 0);
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }
}

/// A value's graph against rating: its [title], a [note] on what it shows,
/// and a [floor] no value goes under, drawn dashed.
class IkkiuchiGraph {
  const IkkiuchiGraph(this.title, this.note, {this.floor});

  final String title;
  final String note;
  final double? floor;
}

/// A draw added to a rating, as its graph shows it: where the rating lands
/// once [draw] is added, held within the curves' ratings, [band] either
/// side marked with the share of draws inside. [whose] names whose rating
/// it is added to.
class IkkiuchiDraw {
  const IkkiuchiDraw(this.graph, this.draw, {required this.whose, required this.band});

  final IkkiuchiGraph graph;
  final TruncatedNormal draw;
  final String whose;
  final double band;
}

/// The ranked draw: Tobi's rating in a ranked match around the player's.
const _rankedDraw = IkkiuchiRating.rankedDraw;

String _drawRule(TruncatedNormal draw) => 'sd ${draw.sd.round()}, drawn again past ±${draw.cutOff.round()}, then '
    'held within ${IkkiuchiTuning.ratingMin.round()}–${IkkiuchiTuning.ratingMax.round()}';

/// The draws the curves page graphs first: where Tobi's rating lands in a
/// ranked match, around the player's, and what his form does to it.
final ikkiuchiDraws = [
  IkkiuchiDraw(
    IkkiuchiGraph("Tobi's rating in ranked", "Where Tobi's rating lands in a ranked match, with the slider as your "
        'rating: ${_drawRule(_rankedDraw)}.'),
    _rankedDraw,
    whose: 'you',
    band: IkkiuchiToolsTuning.rankedBand,
  ),
  IkkiuchiDraw(
    IkkiuchiGraph("Tobi's form", "Where Tobi's rating lands for a whole match, ranked or free, once his form on the "
        'day is added, with the slider as his rating: ${_drawRule(IkkiuchiTobi.formDraw)}.'),
    IkkiuchiTobi.formDraw,
    whose: 'Tobi',
    band: IkkiuchiToolsTuning.formBand,
  ),
];

/// What a range reads when there is none: a value with no randomness.
const ikkiuchiNoRange = '—';

/// How far [sds] standard deviations of his form reach from his rating:
/// never past its cut-off, where it is drawn again.
double ikkiuchiFormReach(num sds) =>
    math.min(sds * IkkiuchiTobi.formDraw.sd, IkkiuchiTobi.formDraw.cutOff);

/// A chance per group's two lines: the chance itself, and the share of
/// games with at least one group kept together.
const ikkiuchiPerGroup = 'per group';
const ikkiuchiAnyInGame = 'any in a game';
const _gameDeal = '${IkkiuchiToolsTuning.gamePerSide} cards a side';

String _wholePercent(double share) => '${(share * 100).round()}';

/// One value Tobi plays with: its [name] in the table and its [unit].
/// A value read from his curves moves with his form from match to match;
/// one he draws per card also spreads from card to card around that value,
/// its median. A fixed value is the same at every rating and never random.
class IkkiuchiValue {
  /// A value read from his curves at his rating: [curve] is its own in the
  /// config, for a value read straight from one, and otherwise [anchors]
  /// are the points of the curve it is worked out from; [drawSpread] is the
  /// standard deviation of the log of his draw on each card, for a value he
  /// draws per card (log-normal); [anyInGame] is, for a chance per group,
  /// the share of games with at least one group kept together.
  const IkkiuchiValue(
    this.name,
    this.unit,
    double Function(IkkiuchiTobi tobi) read, {
    this.curve,
    this._anchors = const [],
    this.drawSpread,
    this.anyInGame,
    this.graph,
  })  : _read = read,
        _fixed = null;

  const IkkiuchiValue.fixed(this.name, this.unit, double value)
      : _fixed = value,
        _read = null,
        curve = null,
        _anchors = const [],
        drawSpread = null,
        anyInGame = null,
        graph = null;

  final String name;
  final IkkiuchiUnit unit;
  final TuningCurve? curve;
  final List<(double, double)> _anchors;
  final double Function(IkkiuchiTobi tobi)? drawSpread;
  final IkkiuchiValue? anyInGame;
  final IkkiuchiGraph? graph;
  final double Function(IkkiuchiTobi tobi)? _read;
  final double? _fixed;

  bool get isFixed => _read == null;

  /// The points its graph rings.
  List<(double, double)> get anchors => curve?.anchors ?? _anchors;

  double at(double rating) => _fixed ?? _read!(IkkiuchiTobi(rating));

  /// The lowest and highest it reads at a rating within [sds] standard
  /// deviations of his form of [rating] ([ikkiuchiFormReach]), kept within
  /// the curves' ratings; null for a fixed value.
  (double, double)? matchRange(double rating, num sds) {
    if (isFixed) return null;
    final reach = ikkiuchiFormReach(sds);
    final from = math.max(IkkiuchiTuning.ratingMin, rating - reach);
    final to = math.min(IkkiuchiTuning.ratingMax, rating + reach);
    var lo = double.infinity, hi = double.negativeInfinity;
    for (var r = from;; r = math.min(r + IkkiuchiToolsTuning.curveStep, to)) {
      final v = at(r);
      lo = math.min(lo, v);
      hi = math.max(hi, v);
      if (r >= to) break;
    }
    return (lo, hi);
  }

  /// His draws on a card at [rating] within [sds] standard deviations of
  /// the median: median × e^±(sds × spread); null for a value he doesn't
  /// draw per card.
  (double, double)? cardRange(double rating, num sds) {
    final spread = drawSpread;
    if (spread == null) return null;
    final median = at(rating), s = sds * spread(IkkiuchiTobi(rating));
    return (median * math.exp(-s), median * math.exp(s));
  }

  String matchRangeText(double rating, num sds) => _text(matchRange(rating, sds));
  String cardRangeText(double rating, num sds) => _text(cardRange(rating, sds));

  String _text((double, double)? range) => range == null ? ikkiuchiNoRange : unit.range(range.$1, range.$2);
}

/// A group of Tobi's values: one band in the table and one section of
/// graphs. [shares] add up to 1 at every rating and share one stacked graph.
class IkkiuchiValueGroup {
  const IkkiuchiValueGroup(this.name, this.values, {this.shares = const [], this.sharesGraph});

  final String name;
  final List<IkkiuchiValue> values;
  final List<IkkiuchiValue> shares;
  final IkkiuchiGraph? sharesGraph;

  Iterable<IkkiuchiValue> get rows => [...values, ...shares];
}

/// Every value Tobi plays with, by group.
final ikkiuchiValueGroups = [
  IkkiuchiValueGroup('Timing', [
    IkkiuchiValue('take time', IkkiuchiUnit.ms, (t) => t.takeMs,
        curve: IkkiuchiTuning.takeMs,
        drawSpread: (t) => t.takeSpread,
        graph: const IkkiuchiGraph('Take time', 'Median time from the end of the deciding sound until his hand hits the card, '
            'for a card at average arm distance. Interpolated on a log scale.')),
    IkkiuchiValue('take spread', IkkiuchiUnit.plain, (t) => t.takeSpread,
        curve: IkkiuchiTuning.takeSpread,
        graph: const IkkiuchiGraph('Take spread', 'How much his take time varies from card to card (standard deviation '
            'of its log). Lower is more consistent.')),
    IkkiuchiValue('search time', IkkiuchiUnit.ms, (t) => t.searchMs,
        curve: IkkiuchiTuning.searchMs,
        drawSpread: (_) => IkkiuchiTuning.searchSpread,
        graph: const IkkiuchiGraph('Search time', "Median extra time he needs when he doesn't know where the card is. "
            'Interpolated on a log scale.')),
    const IkkiuchiValue.fixed('search spread', IkkiuchiUnit.plain, IkkiuchiTuning.searchSpread),
  ]),
  IkkiuchiValueGroup('Mistakes', [
    IkkiuchiValue('blank chance', IkkiuchiUnit.percent, (t) => t.blankChance,
        curve: IkkiuchiTuning.blankChance,
        graph: const IkkiuchiGraph('Blank chance', "Chance per read that he doesn't know where the card is and has to "
            'search for it.')),
    IkkiuchiValue('look-alike pull', IkkiuchiUnit.percent, (t) => t.lookAlikePull,
        curve: IkkiuchiTuning.lookAlikePull,
        graph: const IkkiuchiGraph('Look-alike pull', 'Chance per read that he goes for a look-alike of the called card first, '
            'when one is on the field.')),
    IkkiuchiValue('stray touch', IkkiuchiUnit.percent, (t) => t.strayChance,
        anchors: [for (final (r, v) in IkkiuchiTuning.lookAlikePull.anchors) (r, v * IkkiuchiTuning.strayShare)],
        graph: const IkkiuchiGraph('Stray touch', 'Chance that he touches a card on a からふだ, when no look-alike is on '
            'the field. A fixed share of the look-alike pull.')),
    const IkkiuchiValue.fixed('stray share', IkkiuchiUnit.percent, IkkiuchiTuning.strayShare),
    IkkiuchiValue.fixed(
        'correction', IkkiuchiUnit.ms, IkkiuchiTuning.correction.inMilliseconds.toDouble()),
  ]),
  IkkiuchiValueGroup('Placing', [
    IkkiuchiValue('placing per card', IkkiuchiUnit.ms, (t) => t.placingMsPerCard,
        curve: IkkiuchiTuning.placingMsPerCard,
        graph: const IkkiuchiGraph('Placing time per card', 'Time he takes to lay down each card of his side before '
            'the match; his whole side takes this times his cards. Interpolated on a log scale.')),
    IkkiuchiValue('sound grouping', IkkiuchiUnit.percent, (t) => t.soundGrouping,
        curve: IkkiuchiLayoutTuning.soundGrouping,
        anyInGame: IkkiuchiValue(ikkiuchiAnyInGame, IkkiuchiUnit.percent,
            (t) => ikkiuchiSoundsDealt.anyKept(t.soundGrouping)),
        graph: const IkkiuchiGraph('Sound grouping', 'Chance that each first-sound group is placed together. Red line: '
            'chance that a game has at least one such group ($_gameDeal, only groups with two or more '
            'of his cards count).')),
    IkkiuchiValue('友札 together', IkkiuchiUnit.percent, (t) => t.tomofudaGrouping,
        curve: IkkiuchiLayoutTuning.tomofudaGrouping,
        anyInGame: IkkiuchiValue(ikkiuchiAnyInGame, IkkiuchiUnit.percent,
            (t) => ikkiuchiFamiliesDealt.anyKept(t.tomofudaGrouping)),
        graph: const IkkiuchiGraph('友札 together', 'Chance that each 友札 family is placed side by side. Red line: '
            'chance that a game has at least one such family ($_gameDeal, only families with two or '
            'more of his cards count).')),
    IkkiuchiValue('smart send', IkkiuchiUnit.percent, (t) => t.smartSend,
        curve: IkkiuchiTuning.smartSend,
        graph: const IkkiuchiGraph('Smart send', 'Chance that he sends one card of a look-alike pair and keeps the other. '
            'Otherwise he sends a random card.')),
  ]),
  IkkiuchiValueGroup(
    'Arm',
    [
      IkkiuchiValue('arm swing', IkkiuchiUnit.ms, (t) => t.armMs,
          curve: IkkiuchiTuning.armMs,
          graph: const IkkiuchiGraph('Arm swing', 'Time his arm takes to reach a card at average distance. '
              'Part of the take time. Interpolated on a log scale.')),
      IkkiuchiValue('reach to hit', IkkiuchiUnit.ms, (t) => t.reachMs,
          curve: IkkiuchiTuning.reachMs,
          graph: IkkiuchiGraph('Reach to hit', 'Length of the strike animation, from the start of the reach to '
              'the hit. Red dashed line: the ${IkkiuchiTuning.reachFloorMs.round()} ms minimum.',
              floor: IkkiuchiTuning.reachFloorMs)),
      const IkkiuchiValue.fixed('reach floor', IkkiuchiUnit.ms, IkkiuchiTuning.reachFloorMs),
    ],
    shares: [
      IkkiuchiValue('sweep', IkkiuchiUnit.percent, (t) => t.moves.sweep, curve: IkkiuchiTuning.sweepShare),
      IkkiuchiValue('whip', IkkiuchiUnit.percent, (t) => t.moves.whip),
      IkkiuchiValue('coil and lunge', IkkiuchiUnit.percent, (t) => t.moves.coilLunge),
      IkkiuchiValue('smear', IkkiuchiUnit.percent, (t) => t.moves.smear),
    ],
    sharesGraph: IkkiuchiGraph('Arm moves', 'Share of each arm move. The sweep (払い) has its own curve; '
        'whip, coil and lunge, and smear split the rest ${_wholePercent(IkkiuchiTuning.wildMoves.whip)} / '
        '${_wholePercent(IkkiuchiTuning.wildMoves.coilLunge)} / ${_wholePercent(IkkiuchiTuning.wildMoves.smear)}.'),
  ),
];
