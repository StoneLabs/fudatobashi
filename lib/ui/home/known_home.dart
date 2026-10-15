import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../free/free_practice_sheet.dart';
import '../rank/rank_screen.dart';
import '../run/run_launcher.dart';
import '../tour/tour_anchor.dart';
import 'guest_sheet.dart';
import 'home_widgets.dart';
import 'ranked_hero.dart';

/// Home with all cards known (spec phone 3): class and rating, the streak,
/// the ランク戦 hero, free play, 苦手 and guest mode.
class KnownHome extends StatelessWidget {
  const KnownHome({super.key});

  @override
  Widget build(BuildContext context) {
    final slow = ProgressScope.of(context).slowCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TourAnchor(TourSpot.rank, child: _RankRow()),
        const SizedBox(height: HomeLayout.heroGap),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            // The hero's slanted bottom and the mode panels' slanted top share
            // one gutter, so their boxes overlap.
            const overlap = HomeLayout.modeSlant - HomeLayout.modeGutter;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: box.maxHeight - HomeLayout.modeHeight + overlap,
                  child: const TourAnchor(TourSpot.training, child: RankedHero()),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: HomeLayout.modeHeight,
                  child: TourAnchor(TourSpot.modes, child: _ModePanels(slow: slow)),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: Gaps.panelWide),
        const TourAnchor(TourSpot.guest, child: _GuestPanel()),
      ],
    );
  }
}

/// The class and rating (unranked until the first ranked run places the
/// player), and the streak.
class _RankRow extends StatelessWidget {
  const _RankRow();

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final s = S.of(context);
    final rating = progress.rating;
    const bold = TextStyle(fontWeight: Weights.black);
    const label = TextStyle(
      fontWeight: Weights.black,
      fontSize: HomeLayout.ratingLabelFont,
      letterSpacing: HomeLayout.ratingLabelTracking * HomeLayout.ratingLabelFont,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: HomeLayout.rankFlex,
            child: Pressable(
              onTap: () => Navigator.of(context).push(MangaRoute<void>(builder: (_) => const RankScreen())),
              scale: Press.panelScale,
              turn: 0,
              semanticLabel: s.rank,
              builder: (context, _) => MangaPanel(
                shape: const PanelShape(bottomRight: Offset(HomeLayout.rankSlant, 0)),
                padding: const EdgeInsets.only(left: Gaps.inner, right: HomeLayout.rankSlant + Gaps.small),
                child: Row(
                  children: [
                    if (rating == null) const UnrankedSticker() else RankSticker(Rating.bandOf(rating)),
                    const SizedBox(width: HomeLayout.rankGap),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.ratingLabel, style: label),
                          if (rating == null)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(s.rankUnplaced,
                                  style: const TextStyle(
                                      fontFamily: Fonts.display,
                                      fontSize: UnrankedStyle.font,
                                      height: TypeScale.displayLineHeight)),
                            )
                          else
                            ..._rated(s, rating, bold),
                          if (progress.knownCardSpeedMs != null) ...[
                            const SizedBox(height: HomeLayout.knownSpeedGap),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: KnownSpeedTag(ms: progress.knownCardSpeedMs, weekAgoMs: progress.knownCardSpeedTrendAgo),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: HomeLayout.streakFlex,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(HomeLayout.rankSlant, 0)),
              color: Palette.seaSoft,
              tone: Tones.sea,
              padding: const EdgeInsets.symmetric(horizontal: HomeLayout.rankSlant),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TallyMarks(progress.streak),
                  const SizedBox(height: HomeLayout.streakGap),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ColoredBox(
                      color: Palette.paper,
                      child: Padding(
                        padding: HomeLayout.streakLabelPadding,
                        child: NumberedText(
                          s.streakDays,
                          [progress.streak],
                          style: const TextStyle(
                              fontSize: HomeLayout.streakFont, fontWeight: Weights.black, height: HomeLayout.rowLineHeight),
                          numberStyle: const TextStyle(
                              fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: HomeLayout.streakNumber),
                        ),
                      ),
                    ),
                  ),
                  // One swipe a day keeps it: there is no daily set here.
                  const SizedBox(height: StreakKeepStyle.gap),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(s.streakKeep,
                        style: const TextStyle(fontSize: StreakKeepStyle.font, fontWeight: Weights.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The rating, its bar toward the next class, and the points to it.
  List<Widget> _rated(S s, double rating, TextStyle bold) {
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : 0.0;
    final fraction = next == null ? 1.0 : (rating - floor) / (next.minRating - floor);
    return [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          rating.round().toString(),
          style:
              const TextStyle(fontFamily: Fonts.display, fontSize: HomeLayout.ratingFont, height: TypeScale.displayLineHeight),
        ),
      ),
      const SizedBox(height: HomeLayout.ratingBarGap),
      RatingBar(fraction),
      const SizedBox(height: HomeLayout.ratingBarGap),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: next == null
            ? Text(s.topBand, style: bold)
            : NumberedText(
                s.toNextBand.replaceAll('{band}', next.label),
                [(next.minRating - rating).ceil(), next.minRating.round()],
                style: const TextStyle(fontSize: HomeLayout.ratingNoteFont, fontWeight: Weights.bold),
                numberStyle: bold,
              ),
      ),
    ];
  }
}

class _ModePanels extends StatelessWidget {
  const _ModePanels({required this.slow});
  final int slow;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final split = w * HomeLayout.modeSplit;
      double topAt(double x) => HomeLayout.modeSlant * (1 - x / w);
      return Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: split,
            child: _ModePanel(
              shape: PanelShape(
                topLeft: Offset(0, topAt(0)),
                topRight: Offset(0, topAt(split)),
                bottomRight: const Offset(HomeLayout.modeGutter, 0),
              ),
              tone: Tones.sea,
              fade: Backdrops.freePlayStops,
              title: '始める',
              sub: s.freePlaySub,
              textLeft: HomeLayout.modeTextAt.dx,
              corner: MangaIcon(IconArt.cards, size: HomeLayout.modeIcon),
              cornerAt: HomeLayout.modeIconAt,
              onTap: () => openFreePractice(context),
            ),
          ),
          Positioned(
            left: split,
            top: 0,
            bottom: 0,
            right: 0,
            child: _ModePanel(
              shape: PanelShape(
                topLeft: Offset(HomeLayout.modeGutter, topAt(split + HomeLayout.modeGutter)),
              ),
              tone: Tones.sun,
              fade: Backdrops.nigateStops,
              title: '苦手',
              sub: s.nigateSub,
              textLeft: HomeLayout.nigateTextLeft,
              corner: slow > 0 ? CountBadge(slow) : null,
              cornerAt: HomeLayout.modeBadgeAt,
              onTap: () => startNigate(context),
            ),
          ),
        ],
      );
    });
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
    required this.shape,
    required this.tone,
    required this.fade,
    required this.title,
    required this.sub,
    required this.textLeft,
    required this.corner,
    required this.cornerAt,
    required this.onTap,
  });

  final PanelShape shape;
  final ToneSpec tone;

  /// Where the solid wash over the tone ends and fully fades out.
  final List<double> fade;
  final String title, sub;
  final double textLeft;
  final Widget? corner;
  final Offset cornerAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wash = tone.background!;
    return Pressable(
      onTap: onTap,
      scale: Press.panelScale,
      turn: 0,
      semanticLabel: '$title $sub',
      builder: (context, _) => MangaPanel(
        shape: shape,
        color: wash,
        tone: tone,
        art: [
          LinearLayer(
            angle: Backdrops.freePlayAngle,
            colors: [wash, wash, wash.withValues(alpha: 0)],
            stops: [0, ...fade],
          ),
        ],
        child: Stack(
          children: [
            // Large text scales down rather than running off the panel.
            Positioned(
              left: textLeft,
              top: HomeLayout.modeTextAt.dy,
              right: Gaps.inner,
              bottom: Gaps.small,
              child: LayoutBuilder(
                builder: (context, box) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: box.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontFamily: Fonts.display, fontSize: HomeLayout.modeTitle, height: HomeLayout.rowLineHeight)),
                        const SizedBox(height: HomeLayout.modeTitleGap),
                        Text(sub, style: const TextStyle(fontSize: HomeLayout.modeSub, fontWeight: Weights.black)),
                        const SizedBox(height: HomeLayout.modeNoteGap),
                        FittedBox(fit: BoxFit.scaleDown, child: HomeChip(S.of(context).notForRank)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (corner != null) Positioned(left: cornerAt.dx, top: cornerAt.dy, child: corner!),
          ],
        ),
      ),
    );
  }
}

/// Guest mode as a slim bar; the sheet it opens explains what it means.
class _GuestPanel extends StatelessWidget {
  const _GuestPanel();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Pressable(
      onTap: () => confirmGuestRun(context),
      scale: 1,
      turn: 0,
      semanticLabel: s.guestMode,
      builder: (context, _) => MangaPanel(
        padding: HomeLayout.guestPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HomeLayout.guestHeight),
          child: Row(
            children: [
              MangaIcon(IconArt.person, size: HomeLayout.guestIcon),
              const SizedBox(width: Gaps.small),
              Text(s.guestMode, style: const TextStyle(fontSize: HomeLayout.guestTitle, fontWeight: Weights.black)),
              const SizedBox(width: Gaps.small),
              UntrackedLabel(s.untrackedTag),
              const SizedBox(width: Gaps.small),
              Expanded(
                child: Text(
                  s.guestShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: HomeLayout.guestSub, fontWeight: Weights.bold, color: Palette.inkSoft),
                ),
              ),
              MangaIcon(IconArt.chevron, size: HomeLayout.guestChevron),
            ],
          ),
        ),
      ),
    );
  }
}
