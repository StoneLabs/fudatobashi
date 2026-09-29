import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/trainer.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../free/free_practice_sheet.dart';
import '../shell/header_actions.dart';
import '../tour/tour_anchor.dart';
import 'guest_sheet.dart';
import 'home_widgets.dart';
import 'journey_home.dart';
import 'known_home.dart';

/// Home: the logo bar, then the journey (beginners) or the manga home (all
/// cards known).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final journey = ProgressScope.of(context).trainer.config.learningMode == LearningMode.journey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: HeaderStyle.topGap),
          MangaHeader(
            title: TourAnchor(TourSpot.brand, child: BrandTitle(sub: s.brandSub)),
            actions: const [
              TourAnchor(TourSpot.level, child: LevelButton()),
              TourAnchor(TourSpot.settings, child: SettingsButton()),
            ],
          ),
          const SizedBox(height: HeaderStyle.topGap),
          Expanded(child: journey ? const JourneyHome() : const KnownHome()),
        ],
      ),
    );
  }
}

/// A compact mode button of the journey home's bottom row.
class HomeRowButton extends StatelessWidget {
  const HomeRowButton({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.color = Palette.paper,
    this.displayTitle = false,
    this.badge,
  });

  final VectorArt icon;
  final String title, sub;
  final VoidCallback onTap;
  final Color color;

  /// Sets [title] in display type (karuta words like 始める).
  final bool displayTitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ButtonMetrics.rowHeight,
      child: InkButton(
        onTap: onTap,
        color: color,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: ButtonMetrics.rowPadding),
        semanticLabel: '$title $sub',
        child: Row(
          children: [
            MangaIcon(icon, size: ButtonMetrics.rowIcon),
            const SizedBox(width: ButtonMetrics.rowGap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        title,
                        maxLines: 1,
                        style: displayTitle
                            ? const TextStyle(
                                fontFamily: Fonts.display, fontSize: HomeLayout.rowJpFont, height: HomeLayout.rowLineHeight)
                            : const TextStyle(
                                fontWeight: Weights.black, fontSize: TypeScale.button, height: HomeLayout.rowLineHeight),
                      ),
                      if (badge != null) ...[const SizedBox(width: HomeLayout.untrackedGap), badge!],
                    ]),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: Weights.bold, fontSize: HomeLayout.rowSubFont, height: HomeLayout.rowLineHeight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free play and the guest entry, side by side.
class FreeAndGuestRow extends StatelessWidget {
  const FreeAndGuestRow({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        const Expanded(child: _FreePlayButton()),
        const SizedBox(width: Gaps.panelWide),
        Expanded(
          child: HomeRowButton(
            icon: IconArt.person,
            title: s.guestTitle,
            sub: s.guestShort,
            badge: UntrackedLabel(s.untrackedTag),
            onTap: () => confirmGuestRun(context),
          ),
        ),
      ],
    );
  }
}

/// The journey's 始める: opens free practice's setup, or while it is still
/// locked (`Progress.freePractice`) says how many more cards to remember.
class _FreePlayButton extends StatelessWidget {
  const _FreePlayButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final access = ProgressScope.of(context).freePractice();
    return HomeRowButton(
      icon: access.open ? IconArt.cards : IconArt.lock,
      title: '始める',
      sub: access.open ? s.freePlaySub : s.freeLockedSub(access.needed),
      displayTitle: true,
      color: access.open ? Palette.seaSoft : Palette.desk,
      onTap: () => access.open
          ? openFreePractice(context)
          : BalloonPop.show(context, s.freeLockedWhy(access.needed),
              size: FreePracticeLayout.lockBalloon, life: FreePracticeLayout.lockBalloonLife),
    );
  }
}
