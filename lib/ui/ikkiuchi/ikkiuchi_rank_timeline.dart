import 'dart:ui' show lerpDouble;

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/ikkiuchi_records.dart';
import '../results/celebrations.dart';

/// When the rank change page's parts move and what its rating reads
/// ([IkkiuchiRankMotion]): the opening, then this match's point running to
/// its place over the count, and what follows in the page's
/// [moment]. A rank up's run stops at the class line it crosses, strains
/// there and breaks through, then runs on to its landing.
class IkkiuchiRankTimeline {
  IkkiuchiRankTimeline(IkkiuchiRankCelebration data)
      : change = data.change,
        moment = data.moment;

  final IkkiuchiRankChange change;
  final IkkiuchiRankMoment moment;

  bool get won => change.won;
  bool get ranksUp => moment == IkkiuchiRankMoment.rankUp;
  bool get ranksDown => moment == IkkiuchiRankMoment.rankDown;
  bool get placed => moment == IkkiuchiRankMoment.placed;
  bool get placing => change.placing;

  /// Whether the page cuts to the impact frame: a rank up, or the first
  /// class.
  bool get climax => ranksUp || placed;

  /// Whether the page is the calm one of a loss or a placement on the way.
  bool get calm => !won && !placed || moment == IkkiuchiRankMoment.placing;

  // ---------------------------------------------------------------- the run

  /// The count starts as the points land by the rating.
  Duration get runAt => chipLandAt;

  /// The number of points the count passes, at least one.
  int get _points => (change.after.round() - change.before.round()).abs().clamp(1, 1 << 20);

  /// How many gaps the count has: one per point, up to
  /// [IkkiuchiRankMotion.maxTicks].
  int get _steps => _points < IkkiuchiRankMotion.maxTicks ? _points : IkkiuchiRankMotion.maxTicks;

  /// The gaps between ticks, long at both ends and short in the middle.
  late final List<Duration> _gaps = () {
    final ends = [...IkkiuchiRankMotion.tickSlowGaps, ...IkkiuchiRankMotion.tickRampGaps];
    final front = ends.take((_steps + 1) ~/ 2).toList(), back = ends.take(_steps ~/ 2).toList();
    return [
      ...front,
      for (var i = front.length + back.length; i < _steps; i++) IkkiuchiRankMotion.tickRushGap,
      ...back.reversed,
    ]..[_steps - 1] = IkkiuchiRankMotion.landingGap;
  }();

  /// When, from the run's start, the count has passed each tick's share of
  /// the points (the first after [IkkiuchiRankMotion.firstTickAt], the last
  /// at the landing).
  late final List<Duration> _nodes = () {
    var at = IkkiuchiRankMotion.firstTickAt;
    return [at, for (final gap in _gaps) at += gap];
  }();

  /// How long the count takes, the gaps added up.
  Duration get run => _nodes.last;

  /// Where on its way the line crosses a class line, 0–1: the class it
  /// ranks up into, or the one it ranks down out of; null when it crosses
  /// none.
  double? get gateShare {
    final line = ranksUp ? change.to.minRating : (ranksDown ? change.from.minRating : null);
    return line == null ? null : (line - change.before) / (change.after - change.before);
  }

  /// How far into the run the count reaches the class line.
  late final Duration _gateRun = _runReaching(gateShare ?? 0);

  /// When the point reaches the class line it crosses.
  Duration get gateAt => runAt + _gateRun;

  /// When a rank up breaks through, after straining at the line.
  Duration get breakAt => gateAt + IkkiuchiRankMotion.breakAfter;

  /// When the point lands: the run, and a rank up's wait at the line.
  Duration get landAt => runAt + run + (ranksUp ? IkkiuchiRankMotion.breakAfter : Duration.zero);

  /// How far the point has gone from the last match's to its own, 0–1.
  double shareAt(Duration elapsed) {
    if (ranksUp && elapsed >= gateAt && elapsed < breakAt) return gateShare!;
    var into = elapsed - runAt;
    if (ranksUp && into > _gateRun) {
      into = into - IkkiuchiRankMotion.breakAfter < _gateRun ? _gateRun : into - IkkiuchiRankMotion.breakAfter;
    }
    return _shareAfter(into);
  }

  /// The share of the points passed [into] the run: steady between ticks.
  double _shareAfter(Duration into) {
    if (into <= Duration.zero) return 0;
    if (into >= run) return 1;
    final k = _nodes.lastIndexWhere((node) => node <= into);
    if (k < 0) return 0;
    final gap = _nodes[k + 1] - _nodes[k];
    return (k + (into - _nodes[k]).inMicroseconds / gap.inMicroseconds) / _steps;
  }

  double ratingAt(Duration elapsed) => lerpDouble(change.before, change.after, shareAt(elapsed))!;

  /// The rating the page reads at [elapsed].
  int shownAt(Duration elapsed) => ratingAt(elapsed).round();

  /// The shortest stretch of the run that reaches [share].
  Duration _runReaching(double share) {
    final k = (share * _steps).floor().clamp(0, _steps - 1);
    final gap = _nodes[k + 1] - _nodes[k];
    return _nodes[k] + gap * (share * _steps - k).clamp(0.0, 1.0);
  }

  /// The ticks, each at its share of the points: the first as the count
  /// starts, then slowly, rushing, slowing into the landing (which sounds
  /// itself). A rank up's wait at the line pushes the later ones back.
  late final List<Duration> ticks = [
    for (var k = 0; k < _steps; k++)
      runAt + _nodes[k] + (ranksUp && _nodes[k] > _gateRun ? IkkiuchiRankMotion.breakAfter : Duration.zero),
  ];

  // ------------------------------------------------------------ the points

  /// The points changing hands before the count: the change tag pops off
  /// Tobi's plate and flies down to its place by the rating, where it
  /// stays.
  Duration get chipPopAt => IkkiuchiRankMotion.chipPopAt;
  Duration get chipFlyAt => IkkiuchiRankMotion.chipFlyAt;
  Duration get chipLandAt => chipFlyAt + IkkiuchiRankMotion.chipFly;

  /// When a placement match's slot stamps.
  Duration get slotAt => landAt + IkkiuchiRankMotion.slotAfterLand;

  // -------------------------------------------------------- the climaxes

  /// The last placement match's drumroll, its heartbeats and the reveal.
  Duration get suspenseAt => landAt + IkkiuchiRankMotion.suspenseAfterLand;
  List<Duration> get suspenseBeats => [for (final b in IkkiuchiRankMotion.suspenseBeats) suspenseAt + b];
  Duration get revealAt => suspenseAt + IkkiuchiRankMotion.revealAfterSuspense;

  /// A rank up's heartbeats at the class line.
  List<Duration> get strainBeats => [for (final b in IkkiuchiRankMotion.beats) gateAt + b];

  /// The cut to the impact frame.
  Duration get cutAt => placed
      ? revealAt + IkkiuchiRankMotion.cutAfterReveal
      : _later(breakAt + IkkiuchiRankMotion.cutAfterBreak, landAt + IkkiuchiRankMotion.cutAfterLand);
  Duration get slashAt => cutAt + IkkiuchiRankMotion.slashAfterCut;
  Duration get splitAt => cutAt + IkkiuchiRankMotion.splitAfterCut;

  /// The new class dropping onto the frame, and landing.
  Duration get stampAt => placed ? cutAt : cutAt + IkkiuchiRankMotion.stampAfterCut;
  Duration get impactAt =>
      cutAt + (placed ? IkkiuchiRankMotion.placedImpactAfterCut : IkkiuchiRankMotion.impactAfterCut);

  /// The frame fading back into the page as the class settles into its
  /// badge.
  Duration get settleAt =>
      placed ? impactAt + IkkiuchiRankMotion.placedSettleAfterImpact : cutAt + IkkiuchiRankMotion.settleAfterCut;

  /// A rank down's crack in the class line, ガーン!!, the hit, the fall and
  /// the lower class's thud.
  Duration get crackAt => gateAt;
  Duration get shockAt => crackAt + IkkiuchiRankMotion.shockAfterCrack;
  Duration get hitAt => crackAt + IkkiuchiRankMotion.hitAfterCrack;
  Duration get fallAt => crackAt + IkkiuchiRankMotion.fallAfterCrack;
  Duration get dropAt => crackAt + IkkiuchiRankMotion.dropAfterCrack;
  Duration get thudAt => crackAt + IkkiuchiRankMotion.thudAfterCrack;

  /// When the class change (or, for the first class, the rating) shows.
  Duration get labelAt => switch (moment) {
        IkkiuchiRankMoment.rankUp => cutAt + IkkiuchiRankMotion.labelAfterCut,
        IkkiuchiRankMoment.rankDown => _later(
            thudAt + IkkiuchiRankMotion.labelAfterThud, landAt + IkkiuchiRankMotion.labelAfterLand),
        _ => settleAt + IkkiuchiRankMotion.labelAfterSettle,
      };

  /// The first class's bar and ここから.
  Duration get gaugeAt => labelAt + IkkiuchiRankMotion.gaugeAfterLabel;
  Duration get hereAt => labelAt + IkkiuchiRankMotion.hereAfterLabel;

  /// When the button pops, and when the page is at rest.
  Duration get ctaAt => switch (moment) {
        IkkiuchiRankMoment.rankUp => cutAt + IkkiuchiRankMotion.ctaAfterCut,
        IkkiuchiRankMoment.placed => labelAt + IkkiuchiRankMotion.placedCtaAfterLabel,
        _ => landAt + IkkiuchiRankMotion.ctaAfterLand,
      };
  Duration get length => ctaAt + IkkiuchiRankMotion.endAfterCta;

  static Duration _later(Duration a, Duration b) => a > b ? a : b;

  // ------------------------------------------------------------- sounds

  /// The page's sounds in step with it: the points popping off and
  /// flying, a tick for each point the count passes and the landing (a
  /// jingle for a rise, a thud for a fall); a rank up's heartbeats, break,
  /// the blade and the slam; a rank down's ガーン!! and thud; a placement
  /// slot's stamp, the drumroll, the reveal and the slam of the first
  /// class. The same sound twice within [IkkiuchiRankMotion.soundGap]
  /// plays once.
  List<(Sfx, Duration)> get sounds {
    final cues = <(Sfx, Duration)>[
      (Sfx.xpPop, chipPopAt),
      (Sfx.cardFlick, chipFlyAt),
      (change.after >= change.before ? Sfx.ratingUp : Sfx.stamp, landAt),
      if (placing) (Sfx.stamp, slotAt),
      if (ranksUp) ...[
        for (final at in strainBeats) (Sfx.ratingStrain, at),
        (Sfx.ratingBreak, breakAt),
      ],
      if (ranksDown) ...[(Sfx.ankirenWrong, shockAt), (Sfx.stamp, thudAt)],
      if (placed) ...[
        for (final at in suspenseBeats) (Sfx.ratingStrain, at),
        (Sfx.ratingBreak, revealAt),
      ],
      if (ranksUp) (Sfx.cardFlick, slashAt),
      if (climax) ...[(Sfx.stamp, impactAt), (Sfx.rankUp, impactAt)],
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final kept = <(Sfx, Duration)>[];
    for (final cue in cues) {
      final twin = kept.lastWhere((k) => k.$1 == cue.$1, orElse: () => (cue.$1, -_far));
      if (cue.$2 - twin.$2 >= IkkiuchiRankMotion.soundGap) kept.add(cue);
    }
    return [...kept, for (final at in ticks) (Sfx.ratingTick, at)]..sort((a, b) => a.$2.compareTo(b.$2));
  }

  static const _far = Duration(days: 1);
}
