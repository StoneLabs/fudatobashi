import '../config/config.dart';

/// How fast the journey brings in new cards (see [PaceTuning]).
enum LearningPace {
  /// All 100 cards in about a month.
  month,

  /// All 100 cards in about 15 days; needs noticeably more daily practice.
  sprint;

  PaceProfile get profile => switch (this) {
    LearningPace.month => PaceTuning.month,
    LearningPace.sprint => PaceTuning.sprint,
  };

  /// Cards expected unlocked by the end of journey day [day] (0 = the first
  /// day), out of [total].
  int targetUnlocked(int day, int total) {
    final x = (day + 1) / profile.daysToAll;
    const knots = PaceTuning.curve;
    if (x >= knots.last.$1) return total;
    for (var i = 1; i < knots.length; i++) {
      final (x1, y1) = knots[i];
      if (x > x1) continue;
      final (x0, y0) = knots[i - 1];
      return (total * (y0 + (y1 - y0) * (x - x0) / (x1 - x0))).round();
    }
    return total;
  }
}
