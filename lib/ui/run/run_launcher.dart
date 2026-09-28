import 'package:flutter/widgets.dart';

import '../../domain/play_session.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';
import 'shaky_sheet.dart';

// Entry points for starting a run. Screens call only these; the play and
// results screens behind them may change without touching the callers.

/// 修行: unlocks what was earned, plans a spaced-repetition session and plays
/// it. Always startable: after the dues come speed drills.
Future<void> startTraining(BuildContext context) async {
  final planned = await ProgressScope.read(context).planTraining();
  if (!context.mounted || planned.cards.isEmpty) return;
  await _push(context, planned.cards, const PlayConfig(mode: PlayMode.training));
}

/// "Learn next cards" (journey): unlocks the next batch now and plays a
/// training round with it, after Tobi's warning if cards are still shaky.
/// [replace] swaps the current route (Results) for the round.
Future<void> startLearnNext(BuildContext context, {bool replace = false}) async {
  final progress = ProgressScope.read(context);
  final readiness = progress.readiness;
  if (!readiness.ready && !await confirmLearnWhileShaky(context, readiness.shaky)) return;
  final planned = await progress.learnNextCards();
  if (!context.mounted || planned.cards.isEmpty) return;
  const config = PlayConfig(mode: PlayMode.training);
  if (replace) {
    await Navigator.of(context).pushReplacement(MangaRoute<void>(
      transition: MangaTransition.zoom,
      builder: (_) => PlayScreen(cards: planned.cards, config: config),
    ));
  } else {
    await _push(context, planned.cards, config);
  }
}

/// 始める: the cards of [config]'s sets, once each.
Future<void> startFreePlay(BuildContext context, PlayConfig config) {
  final run = config.copyWith(mode: PlayMode.free);
  return _push(context, ProgressScope.read(context).freeDeck(run), run);
}

/// 苦手: the slowest and shakiest cards.
Future<void> startNigate(BuildContext context) async {
  const run = PlayConfig(mode: PlayMode.nigate);
  final deck = ProgressScope.read(context).nigateDeck(run);
  if (deck.isEmpty) {
    MangaToast.show(context, S.of(context).nigateEmpty);
    return;
  }
  await _push(context, deck, run);
}

/// A guest run of [config]'s sets: nothing is recorded.
Future<void> startGuest(BuildContext context, PlayConfig config) {
  final run = config.copyWith(mode: PlayMode.guest);
  return _push(context, ProgressScope.read(context).freeDeck(run), run);
}

Future<void> _push(BuildContext context, List<CardRef> cards, PlayConfig config) async {
  if (cards.isEmpty) return;
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(cards: cards, config: config),
  ));
}

/// Results' "Keep going": training plans the next round, other modes
/// reshuffle the same deck. Replaces Results in place, so the stack never
/// grows past Home → Play (this is the only caller that isn't a start*
/// entry point above).
Future<void> keepGoing(BuildContext context, PlayConfig config) async {
  final progress = ProgressScope.read(context);
  final cards = switch (config.mode) {
    PlayMode.training => (await progress.planTraining()).cards,
    PlayMode.nigate => progress.nigateDeck(config),
    PlayMode.free || PlayMode.guest => progress.freeDeck(config),
  };
  if (!context.mounted) return;
  if (cards.isEmpty) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    return;
  }
  Navigator.of(context).pushReplacement(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(cards: cards, config: config),
  ));
}
