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
  const TrainingHero({super.key, required this.size, required this.narration, required this.balloon, this.beside});

  final HeroSize size;
  final Widget narration;
  final String balloon;

  /// Sits at the right of the narration, under Tobi (journey's Learn ahead).
  final Widget? beside;

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
                // The title gives way (shrinks) when the panel is short.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: padding.left),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
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
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: narrationLeft, right: padding.right),
                  child: _withBeside(NarrationBox(
                    // The compact (journey) panel gives the narration a fixed
                    // height with no room to wrap; clip it to one line rather
                    // than let a long string overflow the panel. The full
                    // panel sizes itself around the narration, so it's left
                    // free to wrap (e.g. known_home's due + slow lines).
                    child: compact
                        ? DefaultTextStyle.merge(maxLines: 1, overflow: TextOverflow.ellipsis, child: narration)
                        : narration,
                  )),
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
            speaker: compact ? HomeLayout.journeyBalloonSpeaker : HomeLayout.heroBalloonSpeaker,
            child: Text(
              balloon,
              style: TextStyle(fontSize: compact ? HomeLayout.journeyBalloonFont : HomeLayout.heroBalloonFont),
            ),
          ),
        ),
      ],
    );
  }

  /// The narration takes the width it needs, leaving [beside] at least
  /// its smallest share of the row; [beside] fills the rest up to its
  /// largest.
  Widget _withBeside(Widget box) {
    final beside = this.beside;
    if (beside == null) return box;
    return LayoutBuilder(
      builder: (context, row) => Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: row.maxWidth * (1 - HomeLayout.heroBesideMinShare) - HomeLayout.heroBesideGap),
            child: box,
          ),
          const SizedBox(width: HomeLayout.heroBesideGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: row.maxWidth * HomeLayout.heroBesideMaxShare),
                child: beside,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
