import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';
import '../tour/tour_anchor.dart';
import 'guest_sheet.dart';
import 'home_screen.dart';
import 'home_widgets.dart';
import 'rank_map.dart';
import 'ranked_hero.dart';

/// Home with all cards known, built like journey Home: the rank map with
/// the rating and the streak at its foot, the ランク戦 hero, free play and
/// 苦手 side by side, and guest mode.
class KnownHome extends StatelessWidget {
  const KnownHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final weak = ProgressScope.of(context).weakCards.cards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // The map's slanted foot and the hero's slanted top run parallel,
          // so their boxes overlap.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: KnownHomeLayout.heroHeight + KnownHomeLayout.heroGap - KnownHomeLayout.slant,
                child: RankMap(),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: KnownHomeLayout.heroHeight,
                child: TourAnchor(TourSpot.training, child: RankedHero()),
              ),
            ],
          ),
        ),
        const SizedBox(height: KnownHomeLayout.buttonsGap),
        TourAnchor(
          TourSpot.modes,
          child: Row(
            children: [
              const Expanded(child: FreePlayButton()),
              const SizedBox(width: Gaps.panel),
              Expanded(
                child: HomeRowButton(
                  leading: weak > 0 ? CountBadge(weak) : const _NothingWeak(),
                  title: s.weakLettering,
                  sub: s.nigateSub,
                  displayTitle: true,
                  color: Palette.sunSoft,
                  onTap: () => startNigate(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KnownHomeLayout.guestGap),
        const TourAnchor(TourSpot.guest, child: _GuestBar()),
      ],
    );
  }
}

/// The 苦手 button's mark with no weak cards: a check on land green.
class _NothingWeak extends StatelessWidget {
  const _NothingWeak();

  @override
  Widget build(BuildContext context) => Container(
        width: KnownHomeLayout.doneMark,
        height: KnownHomeLayout.doneMark,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Palette.land,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.ink, width: Strokes.control),
        ),
        child: MangaIcon(IconArt.check, size: KnownHomeLayout.doneCheck),
      );
}

/// Guest mode as a slim bar; the sheet it opens explains what it means.
class _GuestBar extends StatelessWidget {
  const _GuestBar();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Pressable(
      onTap: () => confirmGuestRun(context),
      scale: 1,
      turn: 0,
      semanticLabel: s.guestTitle,
      builder: (context, _) => MangaPanel(
        padding: HomeLayout.guestPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HomeLayout.guestHeight),
          child: Row(
            children: [
              MangaIcon(IconArt.person, size: HomeLayout.guestIcon),
              const SizedBox(width: HomeLayout.guestGap),
              Text(s.guestTitle, style: const TextStyle(fontSize: HomeLayout.guestTitle, fontWeight: Weights.black)),
              const SizedBox(width: HomeLayout.guestGap),
              UntrackedLabel(s.untrackedTag),
              const SizedBox(width: HomeLayout.guestGap),
              Expanded(
                child: Text(
                  s.guestShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: HomeLayout.guestSub, fontWeight: Weights.bold, color: Palette.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
