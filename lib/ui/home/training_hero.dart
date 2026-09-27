import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';

enum HeroSize { compact, full }

/// The 修行 hero panel: title lettering, a narration box with the day's work,
/// the START TRAINING shout, and Tobi fired up above it.
class TrainingHero extends StatelessWidget {
  const TrainingHero({super.key, required this.size, required this.narration, required this.balloon});

  final HeroSize size;
  final Widget narration;
  final String balloon;

  static const _toneFade = ToneLayer(Tones.pink, fadeAngle: Backdrops.heroToneAngle, fadeStops: Backdrops.heroToneStops);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final compact = size == HeroSize.compact;
    final padding = compact ? HomeLayout.journeyHeroPadding : HomeLayout.heroPadding;
    final titleSize = compact ? HomeLayout.journeyTitle : HomeLayout.heroTitle;
    final shoutLeft = compact ? HomeLayout.journeyShoutLeft : HomeLayout.heroShoutLeft;
    final shoutRight = compact ? HomeLayout.journeyShoutRight : HomeLayout.heroShoutRight;
    final narrationLeft = padding.left + (compact ? 0 : HomeLayout.heroNarrationIndent);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: MangaPanel(
            shape: compact
                ? const PanelShape(topLeft: Offset(0, HomeLayout.journeyHeroCut))
                : const PanelShape(bottomRight: Offset(0, HomeLayout.heroCut)),
            art: compact
                ? const [FillLayer(Palette.paper), BurstLayer(Bursts.journeyHero), _toneFade]
                : const [
                    RadialLayer(center: Backdrops.heroCenter, colors: Backdrops.heroColors, stops: Backdrops.heroStops),
                    BurstLayer(Bursts.hero),
                    _toneFade,
                  ],
            padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: padding.left),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedText(
                        '修行',
                        outlineWidth: compact ? HomeLayout.journeyTitleOutline : HomeLayout.heroTitleOutline,
                        style: TextStyle(
                            fontFamily: Fonts.display, fontSize: titleSize, height: TypeScale.displayLineHeight),
                      ),
                      InkBanner(s.trainingBanner),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(left: narrationLeft, right: padding.right),
                  child: NarrationBox(child: narration),
                ),
                SizedBox(height: compact ? HomeLayout.journeyNarrationGap : HomeLayout.heroNarrationGap),
                Padding(
                  padding: EdgeInsets.only(left: shoutLeft, right: shoutRight),
                  child: SizedBox(
                    height: compact ? HomeLayout.journeyShoutHeight : HomeLayout.heroShoutHeight,
                    child: ShoutButton(
                      label: s.shoutStart,
                      spec: compact ? HomeLayout.journeyShout : HomeLayout.heroShout,
                      onTap: () => startTraining(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Placed(
          compact ? HomeLayout.journeyTobi : HomeLayout.heroTobi,
          child: const Tobi(pose: TobiPose.fired),
        ),
        Placed(
          compact ? HomeLayout.journeyBalloon : HomeLayout.heroBalloon,
          child: SpeechBalloon(
            tail: compact ? HomeLayout.journeyBalloonTail : HomeLayout.heroBalloonTail,
            tailTurn: compact ? HomeLayout.journeyBalloonTailTurn : HomeLayout.heroBalloonTailTurn,
            child: Text(
              balloon,
              style: TextStyle(fontSize: compact ? HomeLayout.journeyBalloonFont : HomeLayout.heroBalloonFont),
            ),
          ),
        ),
      ],
    );
  }
}
