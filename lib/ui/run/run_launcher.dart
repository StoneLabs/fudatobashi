import 'package:flutter/widgets.dart';

import '../../domain/play_session.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';

// Entry points for starting a run. Screens call only these; the play and
// results screens behind them may change without touching the callers.

/// 修行: unlocks what was earned, plans a spaced-repetition session and plays
/// it. Always startable: after the dues come speed drills.
Future<void> startTraining(BuildContext context) async {
  final planned = await ProgressScope.read(context).planTraining();
  if (!context.mounted) return;
  await _push(context, planned.cards, const PlayConfig(mode: PlayMode.training), newPoems: planned.newPoems);
}

/// Home's "Learn ahead" (journey, once `Progress.learnAhead` is open):
/// unlocks the next batch now and plays a training round with it.
Future<void> startLearnAhead(BuildContext context) async {
  final planned = await ProgressScope.read(context).learnAheadCards();
  if (!context.mounted || planned.cards.isEmpty) return;
  await _push(context, planned.cards, const PlayConfig(mode: PlayMode.training), newPoems: planned.newPoems);
}

/// Stats' "Play this island" (journey, once every card of it is uncovered):
/// a free-play round of exactly its cards. Reads the island's progress fresh
/// off [context], so a partly uncovered island can never start a run here,
/// whatever the tapped button believed.
Future<void> startIslandPlay(BuildContext context, int islandIndex) async {
  final progress = ProgressScope.read(context);
  final island = progress.islands[islandIndex];
  if (!progress.isIslandPlayable(island)) return;
  final run = PlayConfig(mode: PlayMode.free, setIds: ['initial:${island.name}']);
  await _push(context, progress.freeDeck(run), run);
}

/// 始める: free practice with [setup]'s deck (every known card unless
/// customised), once each. Re-checks the lock off [context], like
/// [startIslandPlay].
Future<void> startFreePlay(BuildContext context, FreePracticeSetup setup) async {
  final progress = ProgressScope.read(context);
  if (!progress.freePractice().open) return;
  final run = progress.freePracticeRun(setup);
  await _push(context, progress.freeDeck(run), run);
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

/// A guest run of all 100 cards: nothing is recorded.
Future<void> startGuest(BuildContext context) {
  const run = PlayConfig(mode: PlayMode.guest);
  return _push(context, ProgressScope.read(context).freeDeck(run), run);
}

Future<void> _push(BuildContext context, List<CardRef> cards, PlayConfig config, {Set<int> newPoems = const {}}) async {
  if (cards.isEmpty) return;
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(cards: cards, config: config, newPoems: newPoems),
  ));
}

/// Results' "Keep going": training plans the next round, other modes
/// reshuffle the same deck. Replaces Results in place, so the stack never
/// grows past Home → Play (this is the only caller that isn't a start*
/// entry point above).
Future<void> keepGoing(BuildContext context, PlayConfig config) async {
  final progress = ProgressScope.read(context);
  final planned = config.mode == PlayMode.training ? await progress.planTraining() : null;
  final cards = switch (config.mode) {
    PlayMode.training => planned!.cards,
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
    builder: (_) => PlayScreen(cards: cards, config: config, newPoems: planned?.newPoems ?? const {}),
  ));
}
