import 'dart:math' as math;

import '../../config/config.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../play/time_format.dart';

/// How one of Tobi's values reads, alone, as a range, and on a graph's axis.
enum IkkiuchiUnit {
  ms,
  percent,
  plain,
  minutes;

  String format(double v) => switch (this) {
        ms => v >= Duration.millisecondsPerSecond ? '${_seconds(v)} s' : '${v.round()} ms',
        percent => '${_percent(v)}%',
        plain => v.toStringAsFixed(2),
        minutes => formatMinutes(Duration(milliseconds: (v * Duration.millisecondsPerSecond).round())),
      };

  /// [lo] to [hi], the unit written once; one value when both read alike.
  String range(double lo, double hi) {
    if (format(lo) == format(hi)) return format(lo);
    return switch (this) {
      ms when hi < Duration.millisecondsPerSecond => '${lo.round()}–${hi.round()} ms',
      ms => '${_seconds(lo)}–${_seconds(hi)} s',
      percent => '${_percent(lo)}–${_percent(hi)}%',
      plain || minutes => '${format(lo)}–${format(hi)}',
    };
  }

  /// [v] as a tick on a graph's value axis: no trailing zeros, 0 bare.
  String axis(double v) {
    if (v == 0) return '0';
    return switch (this) {
      ms => v >= Duration.millisecondsPerSecond ? '${_trim(v / Duration.millisecondsPerSecond)} s' : '${v.round()} ms',
      percent => '${_trim(v * 100)}%',
      plain => _trim(v),
      minutes => format(v),
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

/// What a range reads when there is none: a value with no randomness.
const ikkiuchiNoRange = '—';

/// One value Tobi plays with: its [name] in the table and its [unit].
/// A value read from his curves moves with his form from match to match;
/// one he draws per card also spreads from card to card around that value,
/// its median. A fixed value is the same at every rating and never random.
class IkkiuchiValue {
  /// A value read from his curves at his rating: [anchors] are its curve's,
  /// for a value with one of its own; [drawSpread] is the standard
  /// deviation of the log of his draw on each card, for a value he draws
  /// per card (log-normal).
  const IkkiuchiValue(
    this.name,
    this.unit,
    double Function(IkkiuchiTobi tobi) read, {
    this.anchors = const [],
    this.drawSpread,
    this.graph,
  })  : _read = read,
        _fixed = null;

  const IkkiuchiValue.fixed(this.name, this.unit, double value)
      : _fixed = value,
        _read = null,
        anchors = const [],
        drawSpread = null,
        graph = null;

  final String name;
  final IkkiuchiUnit unit;
  final List<(double, double)> anchors;
  final double Function(IkkiuchiTobi tobi)? drawSpread;
  final IkkiuchiGraph? graph;
  final double Function(IkkiuchiTobi tobi)? _read;
  final double? _fixed;

  bool get isFixed => _read == null;

  double at(double rating) => _fixed ?? _read!(IkkiuchiTobi(rating));

  /// The lowest and highest it reads at a rating within [sds] standard
  /// deviations of his form ([IkkiuchiTuning.formSd]) of [rating], kept
  /// within the curves' ratings; null for a fixed value.
  (double, double)? matchRange(double rating, num sds) {
    if (isFixed) return null;
    final reach = sds * IkkiuchiTuning.formSd;
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
        anchors: IkkiuchiTuning.takeMs.anchors,
        drawSpread: (t) => t.takeSpread,
        graph: const IkkiuchiGraph('Take time', 'median, at the average arm distance; smoothed on a log scale')),
    IkkiuchiValue('take spread', IkkiuchiUnit.plain, (t) => t.takeSpread,
        anchors: IkkiuchiTuning.takeSpread.anchors,
        graph: const IkkiuchiGraph('Take spread', 'sd of the log of his take time, card to card')),
    IkkiuchiValue('search time', IkkiuchiUnit.ms, (t) => t.searchMs,
        anchors: IkkiuchiTuning.searchMs.anchors,
        drawSpread: (_) => IkkiuchiTuning.searchSpread,
        graph: const IkkiuchiGraph('Search time', 'median time a blank adds; smoothed on a log scale')),
    const IkkiuchiValue.fixed('search spread', IkkiuchiUnit.plain, IkkiuchiTuning.searchSpread),
  ]),
  IkkiuchiValueGroup('Mistakes', [
    IkkiuchiValue('blank chance', IkkiuchiUnit.percent, (t) => t.blankChance,
        anchors: IkkiuchiTuning.blankChance.anchors,
        graph: const IkkiuchiGraph('Blank chance', 'per field card read: he has to look for it')),
    IkkiuchiValue('look-alike pull', IkkiuchiUnit.percent, (t) => t.lookAlikePull,
        anchors: IkkiuchiTuning.lookAlikePull.anchors,
        graph: const IkkiuchiGraph('Look-alike pull', 'per call with a look-alike on the field: he goes for it first')),
    IkkiuchiValue('stray touch', IkkiuchiUnit.percent, (t) => t.strayChance,
        anchors: [for (final (r, v) in IkkiuchiTuning.lookAlikePull.anchors) (r, v * IkkiuchiTuning.strayShare)],
        graph: const IkkiuchiGraph('Stray touch', 'on a からふだ with no look-alike: a share of the pull')),
    const IkkiuchiValue.fixed('stray share', IkkiuchiUnit.percent, IkkiuchiTuning.strayShare),
    IkkiuchiValue.fixed(
        'correction', IkkiuchiUnit.ms, IkkiuchiTuning.correction.inMilliseconds.toDouble()),
  ]),
  IkkiuchiValueGroup('Placing', [
    IkkiuchiValue('placing time', IkkiuchiUnit.minutes, (t) => t.placingSeconds,
        anchors: IkkiuchiTuning.placingSeconds.anchors,
        graph: const IkkiuchiGraph('Placing time', 'laying out his side before the match; smoothed on a log scale')),
    IkkiuchiValue('sound grouping', IkkiuchiUnit.percent, (t) => t.soundGrouping,
        anchors: IkkiuchiLayoutTuning.soundGrouping.anchors,
        graph: const IkkiuchiGraph('Sound grouping', 'chance a match keeps each first-sound group together')),
    IkkiuchiValue('友札 together', IkkiuchiUnit.percent, (t) => t.tomofudaGrouping,
        anchors: IkkiuchiLayoutTuning.tomofudaGrouping.anchors,
        graph: const IkkiuchiGraph('友札 together', 'chance a match keeps each family of look-alikes side by side')),
    IkkiuchiValue('smart send', IkkiuchiUnit.percent, (t) => t.smartSend,
        anchors: IkkiuchiTuning.smartSend.anchors,
        graph: const IkkiuchiGraph('Smart send', 'chance a 送り札 splits a look-alike pair')),
  ]),
  IkkiuchiValueGroup(
    'Arm',
    [
      IkkiuchiValue('arm swing', IkkiuchiUnit.ms, (t) => t.armMs,
          anchors: IkkiuchiTuning.armMs.anchors,
          graph: const IkkiuchiGraph('Arm swing', 'at the average distance, part of the take time; '
              'smoothed on a log scale')),
      IkkiuchiValue('reach to hit', IkkiuchiUnit.ms, (t) => t.reachMs,
          anchors: IkkiuchiTuning.reachMs.anchors,
          graph: const IkkiuchiGraph('Reach to hit', 'the take animation; red dashes: the floor',
              floor: IkkiuchiTuning.reachFloorMs)),
      const IkkiuchiValue.fixed('reach floor', IkkiuchiUnit.ms, IkkiuchiTuning.reachFloorMs),
    ],
    shares: [
      IkkiuchiValue('sweep', IkkiuchiUnit.percent, (t) => t.moves.sweep, anchors: IkkiuchiTuning.sweepShare.anchors),
      IkkiuchiValue('whip', IkkiuchiUnit.percent, (t) => t.moves.whip),
      IkkiuchiValue('coil and lunge', IkkiuchiUnit.percent, (t) => t.moves.coilLunge),
      IkkiuchiValue('smear', IkkiuchiUnit.percent, (t) => t.moves.smear),
    ],
    sharesGraph: const IkkiuchiGraph('Arm moves', 'the sweep (払い) follows its curve; the wild moves split the rest'),
  ),
];
