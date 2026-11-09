import '../config/config.dart';
import 'ikkiuchi_record.dart';
import 'ikkiuchi_side.dart';
import 'xp.dart';

/// 一騎打ち's experience rules ([IkkiuchiXpTuning]), settled once, as a
/// match is recorded. Every card the player took earns its share, a tie
/// they won among them. A match played to its end adds a clear; a win adds
/// more for every card a side, so that a small match earns a small win; a
/// ranked match adds its own bonus, and the ranked match that ends
/// placement a one-off bonus. A match given up keeps only what its cards
/// earned.
abstract final class IkkiuchiXp {
  /// What [match] earns; [placed] when it is the ranked match that ends
  /// placement.
  static XpAward of(IkkiuchiMatchRecord match, {required bool placed}) {
    final taken = match.reads.where((r) => r.taker == IkkiuchiSide.player).length;
    final done = match.completed;
    return XpAward([
      for (final p in [
        XpPart(XpSource.taken, taken, taken * IkkiuchiXpTuning.perCard),
        XpPart(XpSource.won, 1, match.result == IkkiuchiResult.won ? IkkiuchiXpTuning.winPerCard * match.setup.perSide : 0),
        XpPart(XpSource.clear, 1, done ? IkkiuchiXpTuning.clear : 0),
        XpPart(XpSource.ranked, 1, done && match.ranked ? IkkiuchiXpTuning.ranked : 0),
        XpPart(XpSource.placement, 1, done && placed ? IkkiuchiXpTuning.placement : 0),
      ])
        if (p.xp > 0) p,
    ]);
  }
}
