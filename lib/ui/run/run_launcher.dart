import 'package:flutter/widgets.dart';

import '../../domain/ankiren_level.dart';
import '../../domain/play_session.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_screen.dart';
import '../debug/ankiren_debug_game.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';

// Entry points for starting a run. Screens call only these; the play and
// results screens behind them may change without touching the callers.

/// 修行: unlocks what was earned, plans a spaced-repetition session and plays
/// it. Always startable: after the dues come speed drills.
Future<void> startTraining(BuildContext context) async {
  final planned = await ProgressScope.read(context).planTraining();
  if (!context.mounted) return;
  await _push(context, planned.cards, const PlayConfig(mode: PlayMode.training),
      newPoems: planned.newPoems, planner: planned.planner);
}

/// Home's "Learn ahead" (journey, once `Progress.learnAhead` is open):
/// unlocks the next batch now and plays a training round with it.
Future<void> startLearnAhead(BuildContext context) async {
  final planned = await ProgressScope.read(context).learnAheadCards();
  if (!context.mounted || planned.cards.isEmpty) return;
  await _push(context, planned.cards, const PlayConfig(mode: PlayMode.training),
      newPoems: planned.newPoems, planner: planned.planner);
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

Future<void> _push(BuildContext context, List<CardRef> cards, PlayConfig config,
    {Set<int> newPoems = const {}, RunPlanner? planner}) async {
  if (cards.isEmpty) return;
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(cards: cards, config: config, newPoems: newPoems, planner: planner),
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
    builder: (_) =>
        PlayScreen(cards: cards, config: config, newPoems: planned?.newPoems ?? const {}, planner: planned?.planner),
  ));
}

/// 暗記練's ranked game, at the level its rating has reached (capped by the
/// known cards). Re-checks the lock and the known cards off [context], like
/// [startFreePlay]; [replace] puts it in place of the current screen
/// (Results' Again).
Future<void> startAnkirenRanked(BuildContext context, {bool replace = false}) async {
  final progress = ProgressScope.read(context);
  final entry = progress.sideTripsHub()[SideTrip.ankiren];
  if (!entry.open) return;
  final level = entry.rankedLevel;
  if (level == null) {
    MangaToast.show(context, S.of(context).ankirenNeedCards(AnkirenLevels.of(0).cards));
    return;
  }
  await _pushAnkiren(context, AnkirenSetup.forLevel(level, ranked: true), progress.knownCards.toList(),
      replace: replace);
}

/// 暗記練's free play at [setup], once 暗記練 is open and the known cards
/// fill the field.
Future<void> startAnkirenFree(BuildContext context, AnkirenSetup setup, {bool replace = false}) async {
  final progress = ProgressScope.read(context);
  final known = progress.knownCards.toList();
  if (!progress.sideTripsHub()[SideTrip.ankiren].open || setup.ranked) return;
  if (setup.cards > known.length) {
    MangaToast.show(context, S.of(context).ankirenNeedCards(setup.cards));
    return;
  }
  await _pushAnkiren(context, setup, known, replace: replace);
}

/// Developer mode's 暗記練 test game ([AnkirenDebugGame]) at [level],
/// recording nothing, on [seed]'s deal if given.
Future<void> startAnkirenTest(BuildContext context, {int level = 0, int? seed, bool replace = false}) async {
  final route = MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => AnkirenDebugGame(known: ProgressScope.read(context).knownCards.toList(), level: level, seed: seed),
  );
  final navigator = Navigator.of(context);
  await (replace ? navigator.pushReplacement(route) : navigator.push(route));
}

/// 暗記練 Results' Again: the next game, started the way [setup]'s was.
Future<void> ankirenAgain(BuildContext context, AnkirenSetup setup, {required bool tracked}) => !tracked
    ? startAnkirenTest(context, level: setup.level ?? 0, replace: true)
    : setup.ranked
        ? startAnkirenRanked(context, replace: true)
        : startAnkirenFree(context, setup, replace: true);

Future<void> _pushAnkiren(BuildContext context, AnkirenSetup setup, List<int> known,
    {bool tracked = true, required bool replace}) async {
  final route = MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => AnkirenScreen(setup: setup, known: known, tracked: tracked),
  );
  final navigator = Navigator.of(context);
  await (replace ? navigator.pushReplacement(route) : navigator.push(route));
}
