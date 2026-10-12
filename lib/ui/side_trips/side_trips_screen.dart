import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/side_trips.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../home/home_screen.dart';
import '../manga/manga.dart';
import '../rank/rank_badges.dart';
import '../shell/coming_soon.dart';

/// The Side Trips tab (寄り道): a panel per side trip ([SideTripsHub]), then
/// a word that more are coming. Everything it shows comes from the hub, so
/// the look can change without touching the rules.
class SideTripsScreen extends StatelessWidget {
  const SideTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hub = ProgressScope.of(context).sideTripsHub();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(title: ScreenTitle(s.sideTrips, sub: s.other.sideTrips)),
          const SizedBox(height: Gaps.section),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NarrationBox(child: Text.rich(Phrases.span(s.sideTripsIntro))),
                  for (final entry in hub.entries) ...[
                    const SizedBox(height: Gaps.section),
                    SideTripPanel(entry, onRanked: ComingSoonBubble.show, onFree: ComingSoonBubble.show),
                  ],
                  const SizedBox(height: Gaps.section),
                  const _MoreToCome(),
                  const SizedBox(height: Gaps.section),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One side trip: its name lettering beside Tobi, what it is, its rank (or
/// what still keeps it shut), and its ranked and free-play buttons. An open
/// button calls [onRanked] or [onFree] with its own context; a locked one
/// says what opens it.
class SideTripPanel extends StatelessWidget {
  const SideTripPanel(this.entry, {super.key, required this.onRanked, required this.onFree});

  final SideTripEntry entry;
  final ValueChanged<BuildContext> onRanked, onFree;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lock = entry.lock;
    final level = entry.rankedLevel;
    final maxLevel = entry.maxLevel;
    return MangaPanel(
      shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
      color: Palette.seaSoft,
      padding: SideTripsLayout.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedText(
                        entry.trip.label,
                        outlineWidth: SideTripsLayout.titleOutline,
                        style: const TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: SideTripsLayout.titleFont,
                            height: TypeScale.displayLineHeight),
                      ),
                      InkBanner(s.tripBanner(entry.trip)),
                    ],
                  ),
                ),
              ),
              SizedBox.fromSize(
                size: SideTripsLayout.tobi,
                child: Tobi(pose: entry.open ? TobiPose.fired : TobiPose.pointing),
              ),
            ],
          ),
          const SizedBox(height: SideTripsLayout.gap),
          Text.rich(
            Phrases.span(s.tripAbout(entry.trip)),
            style: const TextStyle(fontWeight: Weights.bold, fontSize: SideTripsLayout.aboutFont),
          ),
          const SizedBox(height: SideTripsLayout.gap),
          if (lock == null) _RankLine(entry) else _LockLine(s.sideTripLockedWhy(lock.needed)),
          const SizedBox(height: SideTripsLayout.gap),
          _ModeButton(
            icon: IconArt.arrow,
            title: level == null ? s.sideTripRanked : s.sideTripRankedLevel(level),
            sub: s.sideTripRankedSub,
            color: Palette.pink,
            lock: lock,
            why: s.sideTripLockedWhy,
            onTap: onRanked,
          ),
          const SizedBox(height: Gaps.panel),
          _ModeButton(
            icon: IconArt.cards,
            title: s.freePlay,
            sub: maxLevel == null ? s.sideTripFreeSub : s.sideTripFreeUpTo(maxLevel),
            color: Palette.paper,
            lock: entry.freeLock,
            why: s.sideTripFreeLockedWhy,
            onTap: onFree,
          ),
        ],
      ),
    );
  }
}

/// The trip's class badge, then RATING over its rating, or "unranked"
/// before its first ranked game; and how many games it has seen.
class _RankLine extends StatelessWidget {
  const _RankLine(this.entry);
  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = entry.rating;
    final rung = rungStyle(entry.band.id);
    return Row(
      children: [
        ClassBadge(entry.band, color: rung.color, textColor: rung.text),
        const SizedBox(width: SideTripsLayout.rankGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.ratingLabel,
                style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: SideTripsLayout.ratingLabelFont,
                  letterSpacing: SideTripsLayout.ratingLabelTracking * SideTripsLayout.ratingLabelFont,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: rating == null
                    ? Text(s.sideTripUnranked,
                        style: const TextStyle(fontWeight: Weights.black, fontSize: SideTripsLayout.unrankedFont))
                    : Text(
                        '${rating.round()}',
                        style: const TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: SideTripsLayout.ratingFont,
                            height: TypeScale.displayLineHeight),
                      ),
              ),
            ],
          ),
        ),
        if (entry.games > 0) Pill(s.sideTripGames(entry.games)),
      ],
    );
  }
}

/// A padlock and what opens the trip.
class _LockLine extends StatelessWidget {
  const _LockLine(this.why);
  final String why;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          MangaIcon(IconArt.lock, size: SideTripsLayout.lockIcon),
          const SizedBox(width: SideTripsLayout.rankGap),
          Expanded(
            child: Text.rich(Phrases.span(why), style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body)),
          ),
        ],
      );
}

/// A trip's ranked or free-play button: [onTap] with its own context while
/// open; while [lock] holds it, a padlock, the cards still to go, and a tap
/// pops up [why].
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.lock,
    required this.why,
    required this.onTap,
  });

  final VectorArt icon;
  final String title, sub;
  final Color color;
  final SideTripLock? lock;
  final String Function(int needed) why;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final lock = this.lock;
    return HomeRowButton(
      icon: lock == null ? icon : IconArt.lock,
      title: title,
      sub: lock == null ? sub : S.of(context).sideTripLockedSub(lock.needed),
      color: lock == null ? color : Palette.desk,
      onTap: () => lock == null
          ? onTap(context)
          : BalloonPop.show(context, why(lock.needed),
              size: SideTripsLayout.lockBalloon, life: SideTripsLayout.lockBalloonLife),
    );
  }
}

/// The dashed box after the trips: more are on the way.
class _MoreToCome extends StatelessWidget {
  const _MoreToCome();

  @override
  Widget build(BuildContext context) => DashedBox(
        padding: SideTripsLayout.morePadding,
        child: Row(
          children: [
            MangaIcon(IconArt.question, size: SideTripsLayout.moreIcon),
            const SizedBox(width: SideTripsLayout.rankGap),
            Expanded(
              child: Text.rich(
                Phrases.span(S.of(context).sideTripsMore),
                style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button),
              ),
            ),
          ],
        ),
      );
}
