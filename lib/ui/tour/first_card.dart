import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';

/// The tour's first real card ([TourTuning.firstCard]): its new card
/// screen with Tobi on it, one swipe, then Tobi on being honest. Pops with
/// true once Tobi is done, null when left early; [onSkip] skips the whole
/// tour from inside it.
///
/// The swipe is real progress, recorded as a one-card training round, the
/// same as opening 修行, swiping the card and ending there. That only holds
/// while the card is still new and 修行 would open with it: on a replay of
/// the tour, with the card met already, the round shows the same screens
/// and records nothing.
Future<bool?> playFirstCard(BuildContext context, {VoidCallback? onSkip}) async {
  const poemId = TourTuning.firstCard;
  final progress = ProgressScope.read(context);
  var record = false;
  if (!progress.knows(poemId)) {
    final planned = await progress.planTraining();
    record = planned.newPoems.contains(poemId) && planned.cards.firstOrNull?.poemId == poemId;
  }
  if (!context.mounted) return null;
  return Navigator.of(context).push<bool>(
    MangaRoute(transition: MangaTransition.zoom, builder: (_) => PlayScreen.firstCard(record: record, onSkip: onSkip)),
  );
}
