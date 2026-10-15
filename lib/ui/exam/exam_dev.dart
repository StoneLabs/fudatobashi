import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/play_session.dart';
import '../../domain/ranked.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';

/// Developer mode: swipes every card not swiped yet once, in a free-play
/// run of its own (a hand-picked deck, so FSRS is left alone), which opens
/// the graduation exam.
Future<void> openExamForDev(Progress progress) async {
  final ids = [
    for (final p in poems.all)
      if (progress.attemptsOf(ItemKey(p.id, false)).isEmpty && progress.attemptsOf(ItemKey(p.id, true)).isEmpty) p.id,
  ];
  if (ids.isEmpty) return;
  final run = PlaySession([for (final id in ids) CardRef(id)]);
  var at = Duration.zero;
  for (var i = 0; i < ids.length; i++) {
    run.revealed(at);
    at += const Duration(milliseconds: ExamDevTuning.openCardMs);
    run.commit(responseTs: at, commitTs: at, outcome: Outcome.known);
  }
  await progress.recordRun(run, PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: ids), DateTime.now());
}

/// [pace] sped up to [ExamDevTuning.fastTobiMs] (developer mode's fast Tobi),
/// his cards keeping their rhythm.
TobiPace fastTobi(TobiPace pace) {
  const total = Duration(milliseconds: ExamDevTuning.fastTobiMs);
  final share = ExamDevTuning.fastTobiMs / pace.total.inMilliseconds;
  final ends = [for (final end in pace.cardEnds) end * share];
  ends[ends.length - 1] = total;
  return TobiPace(total, ends);
}
