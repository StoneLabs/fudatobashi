import '../../data/fuda_sets.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';

/// A run's name in History and on Results: its mode, and for free play which
/// deck it used (全部, カスタム, an island) and whether 隠し字 was on.
String runLabel(S s, PlayConfig c) {
  final mode = switch (c.mode) {
    PlayMode.training => s.training,
    PlayMode.nigate => s.weakCards,
    PlayMode.free => s.freePlay,
    PlayMode.guest => s.guest,
  };
  if (c.mode != PlayMode.free) return mode;
  final set = c.cardIds == null && c.setIds.length == 1
      ? fudaSets.all.where((f) => f.id == c.setIds.first).firstOrNull
      : null;
  final deck = c.isKnownDeck ? s.deckAllKnown : set?.label ?? s.deckCustom;
  return [mode, deck, if (c.maskLevel > 0) '隠し字'].join(' · ');
}
