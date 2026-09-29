import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/rating.dart';
import '../../domain/xp.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/onboarding_strings.dart';
import '../../l10n/profile_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';

/// My Profile (opened from Home's level button): Tobi's welcome, the
/// player's rank, how much of the deck they've learned and hold onto well,
/// their level with its XP progress, and their first swipe ever, if any.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final now = DateTime.now();
    final rating = progress.currentRating;
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : 0.0;
    final fraction = next == null ? 1.0 : (rating - floor) / (next.minRating - floor);
    final learned = progress.knownCards.length;
    final remembered = progress.trainer.wellRememberedCount(progress.allStats, now);
    final firstSwipe = progress.firstSwipeAt;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.myProfile, sub: s.other.myProfile),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Welcome(s.tobiHello),
                      const SizedBox(height: Gaps.section),
                      _RankPanel(band: band, rating: rating, fraction: fraction, next: next),
                      const SizedBox(height: Gaps.section),
                      Row(
                        children: [
                          Expanded(child: _StatPanel(s.learnedOf, [learned, 100])),
                          const SizedBox(width: Gaps.panelWide),
                          Expanded(child: _StatPanel(s.wellRememberedOf, [remembered, 100])),
                        ],
                      ),
                      const SizedBox(height: Gaps.section),
                      _LevelPanel(progress.xp.level),
                      if (firstSwipe != null) ...[
                        const SizedBox(height: Gaps.section),
                        NarrationBox(child: Text(s.firstSwipeOn(s.sessionDate(firstSwipe)))),
                      ],
                      const SizedBox(height: Gaps.section),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome(this.greeting);
  final String greeting;

  @override
  Widget build(BuildContext context) => MangaPanel(
        padding: const EdgeInsets.all(Gaps.inner),
        child: Row(
          children: [
            const SizedBox(width: ProfileLayout.tobiWidth, height: ProfileLayout.tobiHeight, child: Tobi(pose: TobiPose.waving)),
            const SizedBox(width: Gaps.inner),
            Expanded(
              child: Text(greeting, style: const TextStyle(fontWeight: Weights.black, fontSize: ProfileLayout.greetingFont)),
            ),
          ],
        ),
      );
}

/// Rank (級 + rating), the same composition as Home's known-mode rank panel
/// (`_RankRow` in `known_home.dart`), reused here on its own.
class _RankPanel extends StatelessWidget {
  const _RankPanel({required this.band, required this.rating, required this.fraction, required this.next});
  final RankBand band;
  final double rating;
  final double fraction;
  final RankBand? next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const bold = TextStyle(fontWeight: Weights.black);
    return MangaPanel(
      padding: const EdgeInsets.all(Gaps.inner),
      child: Row(
        children: [
          RankSticker(band),
          const SizedBox(width: HomeLayout.rankGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.ratingLabel,
                  style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: HomeLayout.ratingLabelFont,
                    letterSpacing: HomeLayout.ratingLabelTracking * HomeLayout.ratingLabelFont,
                  ),
                ),
                Text(
                  rating.round().toString(),
                  style: const TextStyle(
                      fontFamily: Fonts.display, fontSize: HomeLayout.ratingFont, height: TypeScale.displayLineHeight),
                ),
                const SizedBox(height: HomeLayout.ratingBarGap),
                RatingBar(fraction),
                const SizedBox(height: HomeLayout.ratingBarGap),
                next == null
                    ? Text(s.topBand, style: bold)
                    : NumberedText(
                        s.toNextBand.replaceAll('{band}', next!.label),
                        [(next!.minRating - rating).ceil(), next!.minRating.round()],
                        style: const TextStyle(fontSize: HomeLayout.ratingNoteFont, fontWeight: Weights.bold),
                        numberStyle: bold,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One "{0} / {1} …" line (cards learned, cards well remembered), the
/// numbers set in display type by `NumberedText`.
class _StatPanel extends StatelessWidget {
  const _StatPanel(this.template, this.values);
  final String template;
  final List<Object> values;

  @override
  Widget build(BuildContext context) => MangaPanel(
        padding: const EdgeInsets.all(Gaps.inner),
        child: NumberedText(
          template,
          values,
          style: const TextStyle(fontWeight: Weights.black, fontSize: ProfileLayout.statLabelFont),
          numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: ProfileLayout.statNumberFont),
        ),
      );
}

/// The level, with its bar filled toward the next one.
class _LevelPanel extends StatelessWidget {
  const _LevelPanel(this.level);
  final XpLevel level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      padding: const EdgeInsets.all(Gaps.inner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.levelShort(level.level), style: const TextStyle(fontFamily: Fonts.display, fontSize: ProfileLayout.levelFont)),
          const SizedBox(height: Gaps.small),
          _LevelBar(level.fraction),
          const SizedBox(height: Gaps.small),
          Text(s.xpToNext(level.toNext, level.level + 1),
              style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
        ],
      ),
    );
  }
}

/// A paper track filled in pink up to [fraction] (`RatingBar`'s composition,
/// stretched to the panel's own width instead of a fixed one).
class _LevelBar extends StatelessWidget {
  const _LevelBar(this.fraction);
  final double fraction;

  @override
  Widget build(BuildContext context) => Container(
        height: ProfileLayout.levelBarHeight,
        decoration: const BoxDecoration(color: Palette.paper, border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.label))),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          heightFactor: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.pink,
              border: Border(right: BorderSide(color: Palette.ink, width: Strokes.label)),
            ),
          ),
        ),
      );
}
