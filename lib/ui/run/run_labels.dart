import '../../data/fuda_sets.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/play_config.dart';

/// A run's name in History and on Results: its mode, and for free play which
/// deck it used (全部, カスタム, an island) and whether hidden kana was on.
String runLabel(S s, PlayConfig c) {
  final mode = switch (c.mode) {
    PlayMode.training => s.training,
    PlayMode.nigate => s.weakCards,
    PlayMode.free => s.freePlay,
    PlayMode.guest => s.guest,
    PlayMode.ranked => s.rankedRun,
    PlayMode.exam => s.examRun,
  };
  if (c.mode != PlayMode.free) return mode;
  return [mode, ...freeDeckLabels(s, c)].join(' · ');
}

/// A main-game mode's name as the title of its summary and its run page,
/// in [t]'s language.
String modeTitle(S t, PlayMode mode) => switch (mode) {
      PlayMode.training => t.summaryTraining,
      PlayMode.free => t.summaryFree,
      PlayMode.nigate => t.summaryWeak,
      PlayMode.guest => t.summaryGuest,
      PlayMode.ranked => t.summaryRanked,
      PlayMode.exam => t.summaryExam,
    };

/// A free-play run's deck (全部, カスタム, an island) and, when it was on,
/// hidden kana.
List<String> freeDeckLabels(S s, PlayConfig c) {
  final set = c.cardIds == null && c.setIds.length == 1
      ? fudaSets.all.where((f) => f.id == c.setIds.first).firstOrNull
      : null;
  return [c.isKnownDeck ? s.deckAllKnown : set?.label ?? s.deckCustom, if (c.maskLevel > 0) s.maskRow];
}
