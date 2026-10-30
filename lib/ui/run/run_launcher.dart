import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../data/poem.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/play_session.dart';
import '../../domain/ranked.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_screen.dart';
import '../debug/ankiren_debug_game.dart';
import '../exam/exam_dev.dart';
import '../exam/exam_screen.dart';
import '../exam/exam_sheets.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';
import '../teiichi/teiichi_screen.dart';
import 'ranked_sheets.dart';

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

/// Free play of the cards [poemIds] (those still known), as History's
/// "Practise these" starts it.
Future<void> startCardsPlay(BuildContext context, List<int> poemIds) async {
  final progress = ProgressScope.read(context);
  final run = PlayConfig(mode: PlayMode.free, cardIds: [...poemIds]..sort());
  await _push(context, progress.freeDeck(run), run);
}

/// 苦手: a drill of the weak cards, missed lately or slow (see
/// `Progress.weakDrill`).
Future<void> startNigate(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final drill = progress.weakDrill();
  if (drill.cards.isEmpty) {
    final s = S.of(context);
    MangaToast.show(context, progress.allStats.values.any((st) => st.seen) ? s.nigateNone : s.nigateEmpty);
    return;
  }
  await _push(context, drill.cards, drill.config, planner: drill.planner);
}

/// ランク戦 (all-known mode): asks first, since leaving early is a
/// forfeit, then plays all 100 cards. [replace] puts it in place of the
/// current screen (Results' Keep going).
Future<void> startRanked(BuildContext context, {bool replace = false}) async {
  if (!await confirmRankedStart(context) || !context.mounted) return;
  const run = PlayConfig(mode: PlayMode.ranked);
  final route = MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(cards: ProgressScope.read(context).rankedDeck(), config: run),
  );
  final navigator = Navigator.of(context);
  await (replace ? navigator.pushReplacement(route) : navigator.push(route));
}

/// 卒業試験 (journey mode, once every card has been swiped): asks first,
/// then uses up the hour's try before it starts, so leaving it early still
/// counts.
Future<void> startExam(BuildContext context) async {
  final progress = ProgressScope.read(context);
  if (!progress.exam().canStart) return;
  if (!await confirmExamStart(context) || !context.mounted) return;
  await progress.noteExamStarted(DateTime.now());
  if (!context.mounted) return;
  final settings = progress.settings;
  final tobi = TobiPace.draw(math.Random());
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => ExamScreen(cards: progress.rankedDeck(), tobi: settings.debugMode && settings.fastTobi ? fastTobi(tobi) : tobi),
  ));
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

/// Results' "Keep going": training plans the next round, 苦手 the next
/// drill, other modes reshuffle the same deck. Replaces Results in place, so the stack never
/// grows past Home → Play (this is the only caller that isn't a start*
/// entry point above).
Future<void> keepGoing(BuildContext context, PlayConfig config) async {
  if (config.mode == PlayMode.ranked) return startRanked(context, replace: true);
  final progress = ProgressScope.read(context);
  final planned = config.mode == PlayMode.training ? await progress.planTraining() : null;
  final drill = config.mode == PlayMode.nigate ? progress.weakDrill() : null;
  final cards = switch (config.mode) {
    PlayMode.training => planned!.cards,
    PlayMode.nigate => drill!.cards,
    PlayMode.free || PlayMode.guest => progress.freeDeck(config),
    PlayMode.ranked || PlayMode.exam => const <CardRef>[],
  };
  if (!context.mounted) return;
  if (cards.isEmpty) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    return;
  }
  Navigator.of(context).pushReplacement(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => PlayScreen(
        cards: cards,
        config: drill?.config ?? config,
        newPoems: planned?.newPoems ?? const {},
        planner: planned?.planner ?? drill?.planner),
  ));
}

/// 暗記練's ranked game, always [AnkirenSetup.ranked]'s field, once ranked
/// is open (see [RankedLock]). Re-checks the locks and the known cards off
/// [context], like [startFreePlay].
Future<void> startAnkirenRanked(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final entry = progress.sideTripsHub()[SideTrip.ankiren];
  const setup = AnkirenSetup.ranked();
  final known = progress.knownCards.toList();
  if (!entry.rankedOpen || setup.cards > known.length) return;
  await _pushAnkiren(context, setup, known);
}

/// 暗記練's free play at [setup], once 暗記練 is open, the setup is (a level
/// opened by clearing the one before, or custom once that opens; see
/// [AnkirenLadder]) and the known cards fill the field.
Future<void> startAnkirenFree(BuildContext context, AnkirenSetup setup) async {
  final progress = ProgressScope.read(context);
  final known = progress.knownCards.toList();
  final entry = progress.sideTripsHub()[SideTrip.ankiren];
  final level = setup.level;
  final open = level == null ? entry.ladder.customOpen : entry.ladder.isOpen(level);
  if (!entry.open || setup.ranked || !open) return;
  if (setup.cards > known.length) {
    MangaToast.show(context, S.of(context).ankirenNeedCards(setup.cards));
    return;
  }
  await _pushAnkiren(context, setup, known);
}

/// 暗記練 for a guest at [setup], any level or custom setup, dealt from all
/// the cards: nothing of it is recorded (see [AnkirenPlayer.guest]).
Future<void> startAnkirenGuest(BuildContext context, AnkirenSetup setup) async {
  if (setup.ranked) return;
  await _pushAnkiren(context, setup, [for (final p in poems.all) p.id], player: AnkirenPlayer.guest);
}

/// Developer mode's 暗記練 test game ([AnkirenDebugGame]) at [level],
/// recording nothing, on [seed]'s deal if given.
Future<void> startAnkirenTest(BuildContext context, {int level = 0, int? seed}) async {
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => AnkirenDebugGame(known: ProgressScope.read(context).knownCards.toList(), level: level, seed: seed),
  ));
}

Future<void> _pushAnkiren(BuildContext context, AnkirenSetup setup, List<int> known,
    {AnkirenPlayer player = AnkirenPlayer.owner}) async {
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => AnkirenScreen(setup: setup, known: known, player: player),
  ));
}

/// 定位置 at [setup], once 定位置 is open, laid out from the known cards,
/// which must hold it.
Future<void> startTeiichi(BuildContext context, TeiichiSetup setup) async {
  final progress = ProgressScope.read(context);
  if (!progress.sideTripsHub()[SideTrip.teiichi].open) return;
  final known = progress.knownCards.toList();
  if (setup.cards > known.length) {
    MangaToast.show(context, S.of(context).teiichiNeedCards(setup.cards));
    return;
  }
  await _pushTeiichi(context, setup, known);
}

/// 定位置 for a guest at [setup], laid out from all the cards: nothing of it
/// is recorded (see [AnkirenPlayer.guest]).
Future<void> startTeiichiGuest(BuildContext context, TeiichiSetup setup) =>
    _pushTeiichi(context, setup, [for (final p in poems.all) p.id], player: AnkirenPlayer.guest);

Future<void> _pushTeiichi(BuildContext context, TeiichiSetup setup, List<int> known,
    {AnkirenPlayer player = AnkirenPlayer.owner}) async {
  await Navigator.of(context).push(MangaRoute<void>(
    transition: MangaTransition.zoom,
    builder: (_) => TeiichiScreen(setup: setup, known: known, player: player),
  ));
}
