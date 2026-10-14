import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_rank_overlay.dart';
import '../ankiren/ankiren_rating_overlay.dart';
import '../sound/sounds.dart';
import 'celebration_overlays.dart';
import 'celebrations.dart';
import 'day_done_overlay.dart';
import 'graduation_overlay.dart';
import 'island_complete_overlay.dart';
import 'level_up_overlay.dart';
import 'new_card_overlay.dart';
import 'rank_up_overlay.dart';
import 'rating_overlay.dart';
import 'xp_overlay.dart';

/// Celebration [pages] one after another over an opaque backdrop: the
/// sequence fades in, cross-fades between pages, and after the last one
/// fades out and lets go of the screen, calling [onDone] once it is fully
/// gone (play resumes only then). Every game that celebrates plays its
/// pages through it: a main run's, and a 暗記練 game's.
class CelebrationSequence extends StatefulWidget {
  const CelebrationSequence({super.key, required this.pages, required this.onDone});

  final List<Celebration> pages;
  final VoidCallback onDone;

  @override
  State<CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<CelebrationSequence> with SingleTickerProviderStateMixin {
  late final _presence = AnimationController(vsync: this, duration: ResultsLayout.overlayFade);
  int _shown = 0;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leaving) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _presence.value = 1;
    } else if (_presence.isDismissed) {
      _presence.forward();
    }
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  /// Page [from] is done; a late tap on a page already fading out is ignored.
  void _next(int from) {
    if (from != _shown || _leaving) return;
    if (_shown + 1 < widget.pages.length) {
      setState(() => _shown++);
      return;
    }
    setState(() => _leaving = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    _presence.reverse().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i = _shown;
    return IgnorePointer(
      ignoring: _leaving,
      child: FadeTransition(
        opacity: _presence,
        child: ColoredBox(
          color: Palette.paper,
          child: AnimatedSwitcher(
            duration: ResultsLayout.overlayFade,
            transitionBuilder: _transition,
            child: SoundCues(
              key: ValueKey(i),
              cues: _soundsOf(widget.pages[i]),
              child: _page(widget.pages[i], () => _next(i)),
            ),
          ),
        ),
      ),
    );
  }

  /// Pages cross-fade, except that a rating breaking through into the next
  /// class cuts straight to the rank-up at the peak of its flash.
  Widget _transition(Widget child, Animation<double> animation) {
    final i = (child.key! as ValueKey<int>).value;
    final before = i > 0 ? widget.pages[i - 1] : null;
    final cut = switch (before) {
      RatingCelebration() => before.ranksUp,
      AnkirenRatingCelebration() => before.moment == AnkirenRatingMoment.rankUp,
      _ => false,
    };
    return cut ? child : FadeTransition(opacity: animation, child: child);
  }

  Widget _page(Celebration c, VoidCallback onNext) {
    final progress = ProgressScope.read(context);
    return switch (c) {
      NewCardCelebration() => NewCardOverlay(data: c, onNext: onNext),
      ConfusableWarningCelebration() => ConfusableWarningOverlay(data: c, onNext: onNext),
      IslandCompleteCelebration() => IslandCompleteOverlay(
          islandIndex: c.islandIndex,
          islandsDone: progress.islands.where((i) => i.complete).length,
          cardsUnlocked: progress.trainer.unlocked.where((s) => !s.key.inverted).length,
          onNext: onNext,
        ),
      RankUpCelebration() => RankUpOverlay(data: c, onNext: onNext),
      GoalUpCelebration() => GoalUpOverlay(goalMs: progress.trainer.goalMs.round(), onNext: onNext),
      GraduationCelebration() => GraduationOverlay(onNext: onNext),
      DayDoneCelebration() => DayDoneOverlay(day: c.day, onNext: onNext),
      XpCelebration() => XpOverlay(gain: c.gain, onNext: onNext),
      LevelUpCelebration() => LevelUpOverlay(gain: c.gain, onNext: onNext),
      RatingCelebration() => RatingOverlay(data: c, onNext: onNext),
      AnkirenRatingCelebration() => AnkirenRatingOverlay(data: c, onNext: onNext),
      AnkirenRankCelebration() =>
        c.up ? AnkirenRankUpOverlay(data: c, onNext: onNext) : AnkirenRankDownOverlay(data: c, onNext: onNext),
    };
  }
}

/// Each page's sounds, in step with its entrance.
List<(Sfx, Duration)> _soundsOf(Celebration c) => switch (c) {
      NewCardCelebration() => const [(Sfx.cardAppears, NewCardMotion.landAt)],
      ConfusableWarningCelebration() => const [(Sfx.lookAlike, Duration.zero)],
      IslandCompleteCelebration() => [(Sfx.island, IslandCompleteMotion.title.delay)],
      RankUpCelebration() => const [(Sfx.stamp, RankUpMotion.impactAt), (Sfx.rankUp, RankUpMotion.impactAt)],
      GoalUpCelebration() => const [(Sfx.goalUp, Duration.zero)],
      GraduationCelebration() => [
          for (final b in FireworksStyle.bursts.take(GraduationMotion.fireworkSounds))
            (Sfx.firework, Duration(microseconds: (b.delay * 1e6).round())),
          (Sfx.graduation, GraduationMotion.title.delay),
          (Sfx.stamp, GraduationMotion.fullImpactAt),
          (Sfx.stamp, GraduationMotion.kaidenImpactAt),
        ],
      DayDoneCelebration() => const [(Sfx.goalUp, Duration.zero), (Sfx.stamp, DayDoneMotion.impactAt)],
      XpCelebration() => XpTimeline(c.gain).sounds,
      LevelUpCelebration() => const [(Sfx.stamp, LevelUpMotion.impactAt), (Sfx.levelUp, LevelUpMotion.impactAt)],
      RatingCelebration() => RatingTimeline(c).sounds,
      AnkirenRatingCelebration() => AnkirenRatingTimeline(c).sounds,
      AnkirenRankCelebration() => c.up
          ? const [
              (Sfx.cardFlick, AnkirenRankUpMotion.slashAt),
              (Sfx.stamp, AnkirenRankUpMotion.impactAt),
              (Sfx.rankUp, AnkirenRankUpMotion.impactAt),
            ]
          : const [(Sfx.ankirenWrong, AnkirenRankDownMotion.hitAt), (Sfx.stamp, AnkirenRankDownMotion.landAt)],
    };
