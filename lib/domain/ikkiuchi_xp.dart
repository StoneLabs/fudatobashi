import '../config/config.dart';
import 'ikkiuchi_record.dart';
import 'ikkiuchi_side.dart';
import 'xp.dart';

/// 一騎打ち's experience rules ([IkkiuchiXpTuning]), settled once, as a
/// match is recorded. Every card the player took earns its share, a tie
/// they won among them. A match played to its end adds the memory time it
/// used, by the minute, and a clear; a win adds more for every card a side,
/// so that a small match earns a small win; a ranked match adds its own
/// bonus, and the ranked match that ends placement a one-off bonus. A match
/// given up keeps only what its cards earned.
abstract final class IkkiuchiXp {
  /// What [match] earns; [placed] when it is the ranked match that ends
  /// placement.
  static XpAward of(IkkiuchiMatchRecord match, {required bool placed}) {
    final taken = match.takenBy(IkkiuchiSide.player);
    final done = match.completed, won = match.result == IkkiuchiResult.won;
    final memorised = done ? match.memorised : Duration.zero;
    return XpAward([
      for (final p in [
        XpPart(XpSource.taken, taken, taken * IkkiuchiXpTuning.perCard),
        XpPart(XpSource.memory, memorised.inSeconds, memoryXp(memorised)),
        XpPart(XpSource.won, 1, won ? IkkiuchiXpTuning.winPerCard * match.setup.perSide : 0),
        XpPart(XpSource.clear, 1, done ? IkkiuchiXpTuning.clear : 0),
        XpPart(XpSource.ranked, 1, done && match.ranked ? IkkiuchiXpTuning.ranked : 0),
        XpPart(XpSource.placement, 1, done && placed ? IkkiuchiXpTuning.placement : 0),
      ])
        if (p.xp > 0) p,
    ]);
  }

  /// XP [memorised] of memory time used earns.
  static int memoryXp(Duration memorised) =>
      (IkkiuchiXpTuning.memoryPerMinute * memorised.inMicroseconds / Duration.microsecondsPerMinute).round();
}
