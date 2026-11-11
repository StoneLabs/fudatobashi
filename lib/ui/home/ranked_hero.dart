import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rank_ladder.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';
import 'training_hero.dart';

/// All-known Home's ランク戦 hero, as big as journey Home's 修行 and drawn
/// like it: the lettering over its tag (RANKED over ランク戦 in English, the
/// other way around in Japanese), the START RANKED shout, and Tobi at the
/// top right, fired up, or cheering in the top class. Its top edge slants
/// with the rank map's foot above it.
class RankedHero extends StatelessWidget {
  const RankedHero({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = ProgressScope.of(context).rating;
    final top = rating != null && RankLadder.nextBand(rating) == null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: MangaPanel(
            shape: const PanelShape(topLeft: Offset(0, KnownHomeLayout.slant)),
            art: TrainingHero.compactArt,
            padding: RankedHeroLayout.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Padding(
                  padding: RankedHeroLayout.shoutMargin,
                  child: SizedBox(
                    height: RankedHeroLayout.shoutHeight,
                    child: ShoutButton(
                      label: s.shoutRanked,
                      spec: HomeLayout.journeyShout,
                      fontSize: RankedHeroLayout.shoutFont,
                      onTap: () => startRanked(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Placed(HomeLayout.journeyTobi, child: Tobi(pose: top ? TobiPose.cheering : TobiPose.fired)),
        Placed(
          RankedHeroLayout.balloon,
          child: SpeechBalloon(
            speaker: RankedHeroLayout.balloonSpeaker,
            child: BalloonText(s.letsGo, style: const TextStyle(fontSize: RankedHeroLayout.balloonFont)),
          ),
        ),
        // The lettering is drawn last, over the balloon where they meet.
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: RankedHeroLayout.padding,
              child: Column(
                children: [
                  Expanded(child: _Title(ja: s.ja, tag: s.rankedTag)),
                  const SizedBox(height: RankedHeroLayout.shoutHeight),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The lettering over its tag, at the top left (RANKED over ランク戦 in
/// English, the other way around in Japanese).
class _Title extends StatelessWidget {
  const _Title({required this.ja, required this.tag});

  final bool ja;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: RankedHeroLayout.titlePadding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedText(
                ja ? RankedHeroLayout.title : tag,
                outlineWidth: RankedHeroLayout.titleOutline,
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: RankedHeroLayout.titleFont,
                    height: TypeScale.displayLineHeight),
              ),
              const SizedBox(height: RankedHeroLayout.bannerGap),
              InkBanner(ja ? tag : RankedHeroLayout.title, fontSize: RankedHeroLayout.bannerFont),
            ],
          ),
        ),
      ),
    );
  }
}
