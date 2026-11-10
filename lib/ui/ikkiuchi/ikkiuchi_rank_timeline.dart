import 'dart:ui' show lerpDouble;

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/ikkiuchi_records.dart';
import '../results/celebrations.dart';

/// When the rank change page's parts move and what its rating reads
/// ([IkkiuchiRankMotion]): the opening, then this match's point running to
/// its place over the eased count, and what follows in the page's
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

  Duration get runAt => won ? IkkiuchiRankMotion.winRunAt : IkkiuchiRankMotion.runAt;

  /// Where on its way the line crosses a class line, 0–1: the class it
  /// ranks up into, or the one it ranks down out of; null when it crosses
  /// none.
  double? get gateShare {
    final line = ranksUp ? change.to.minRating : (ranksDown ? change.from.minRating : null);
    return line == null ? null : (line - change.before) / (change.after - change.before);
  }

  /// How far into the run the eased count reaches the class line.
  late final Duration _gateRun = _runReaching(gateShare ?? 0);

  /// When the point reaches the class line it crosses.
  Duration get gateAt => runAt + _gateRun;

  /// When a rank up breaks through, after straining at the line.
  Duration get breakAt => gateAt + IkkiuchiRankMotion.breakAfter;

  /// When the point lands: the run, and a rank up's wait at the line.
  Duration get landAt => runAt + IkkiuchiRankMotion.run + (ranksUp ? IkkiuchiRankMotion.breakAfter : Duration.zero);

  /// How far the point has gone from the last match's to its own, 0–1.
  double shareAt(Duration elapsed) {
    if (ranksUp && elapsed >= gateAt && elapsed < breakAt) return gateShare!;
    var run = elapsed - runAt;
    if (ranksUp && run > _gateRun) {
      run = run - IkkiuchiRankMotion.breakAfter < _gateRun ? _gateRun : run - IkkiuchiRankMotion.breakAfter;
    }
    final t = (run.inMicroseconds / IkkiuchiRankMotion.run.inMicroseconds).clamp(0.0, 1.0);
    return IkkiuchiRankMotion.runCurve.transform(t);
  }

  double ratingAt(Duration elapsed) => lerpDouble(change.before, change.after, shareAt(elapsed))!;

  /// The rating the page reads at [elapsed].
  int shownAt(Duration elapsed) => ratingAt(elapsed).round();

  /// The shortest stretch of the run whose eased count reaches [share].
  Duration _runReaching(double share) {
    var lo = 0, hi = IkkiuchiRankMotion.run.inMicroseconds;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (IkkiuchiRankMotion.runCurve.transform(mid / IkkiuchiRankMotion.run.inMicroseconds) >= share) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return Duration(microseconds: hi);
  }

  /// A tick each time the rating read passes a point, as it does: slowly at
  /// first, rushing, slowing into the landing. Where points pass faster
  /// than [IkkiuchiRankMotion.tickSpacing], a tick waits out the spacing
  /// while the read still shows its point, and is left out once it has
  /// moved on, so the rush ticks evenly; none comes closer than the spacing
  /// to the landing.
  late final List<Duration> ticks = () {
    final from = change.before.round(), to = change.after.round();
    final step = to > from ? 1 : -1;
    Duration reaching(int value) {
      var lo = runAt, hi = landAt;
      while (hi - lo > const Duration(milliseconds: 1)) {
        final mid = lo + (hi - lo) ~/ 2;
        if (shownAt(mid) * step >= value * step) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      return hi;
    }

    final passed = [for (var v = from + step; v * step <= to * step; v += step) reaching(v)];
    const spacing = IkkiuchiRankMotion.tickSpacing;
    final ticks = <Duration>[];
    for (final (i, at) in passed.indexed) {
      final tick = ticks.isEmpty || at - ticks.last >= spacing ? at : ticks.last + spacing;
      final shown = i + 1 < passed.length ? passed[i + 1] : landAt;
      if (tick < shown && landAt - tick >= spacing) ticks.add(tick);
    }
    return ticks;
  }();

  // ------------------------------------------------------------ the points

  /// The points changing hands: off Tobi's plate to the curve before a
  /// win's run, from the new point to Tobi after a loss has landed (after
  /// a rank down, with the class change).
  Duration get chipPopAt => won
      ? IkkiuchiRankMotion.chipPopAt
      : ranksDown
          ? labelAt
          : landAt + IkkiuchiRankMotion.chipAfterLand;
  Duration get chipFlyAt => won ? IkkiuchiRankMotion.chipFlyAt : chipPopAt + IkkiuchiRankMotion.chipFlyAfter;
  Duration get chipLandAt => won ? IkkiuchiRankMotion.winRunAt : chipFlyAt + IkkiuchiRankMotion.chipFly;

  /// When the change tag stamps on (with the slot of a placement match).
  Duration get tagAt => switch (moment) {
        IkkiuchiRankMoment.rankUp => cutAt + IkkiuchiRankMotion.tagAfterCut,
        IkkiuchiRankMoment.rankDown => labelAt,
        _ => landAt + IkkiuchiRankMotion.tagAfterLand,
      };

  // -------------------------------------------------------- the climaxes

  /// The last placement match's drumroll, its heartbeats and the reveal.
  Duration get suspenseAt => won
      ? landAt + IkkiuchiRankMotion.suspenseAfterLand
      : chipLandAt + IkkiuchiRankMotion.suspenseAfterChip;
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
            thudAt + IkkiuchiRankMotion.labelAfterThud, landAt + IkkiuchiRankMotion.tagAfterLand),
        _ => settleAt + IkkiuchiRankMotion.labelAfterSettle,
      };

  /// The first class's bar and ここから.
  Duration get gaugeAt => labelAt + IkkiuchiRankMotion.gaugeAfterLabel;
  Duration get hereAt => labelAt + IkkiuchiRankMotion.hereAfterLabel;

  /// When the button pops, and when the page is at rest.
  Duration get ctaAt => switch (moment) {
        IkkiuchiRankMoment.rankUp => cutAt + IkkiuchiRankMotion.ctaAfterCut,
        IkkiuchiRankMoment.placed => labelAt + IkkiuchiRankMotion.placedCtaAfterLabel,
        _ => won ? landAt + IkkiuchiRankMotion.ctaAfterLand : chipLandAt + IkkiuchiRankMotion.ctaAfterChip,
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
      if (placing) (Sfx.stamp, tagAt),
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
