import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/trainer.dart';
import '../../state/progress.dart';

/// Where a beginner is on the island journey.
class JourneyState {
  JourneyState._(this.islands, this.current, this.unlocked, this.upNext);

  factory JourneyState.of(Progress p) {
    final islands = p.islands;
    var current = islands.indexWhere((i) => i.unlocked < i.total);
    if (current < 0) current = islands.indexWhere((i) => !i.complete);
    if (current < 0) current = islands.length - 1;
    final unlocked = {
      for (final id in [for (final i in islands) ...i.poemIds])
        if (p.trainer.items[ItemKey(id, false)]!.unlocked) id,
    };
    return JourneyState._(islands, current, unlocked, p.trainer.nextBatch(poems, fudaSets).toSet());
  }

  final List<IslandProgress> islands;

  /// The island being learned now.
  final int current;

  /// Poem ids whose upright card is unlocked.
  final Set<int> unlocked;

  /// Poem ids that unlock next.
  final Set<int> upNext;

  IslandProgress get island => islands[current];
  int get cardsUnlocked => unlocked.length;
  int get islandsAhead => islands.length - 1 - current;

  /// Every card unlocked and every island complete.
  bool get finished => islands.every((i) => i.complete);

  /// An island passed on the way (all its cards unlocked).
  bool done(int index) => index < current && islands[index].unlocked == islands[index].total;
}
