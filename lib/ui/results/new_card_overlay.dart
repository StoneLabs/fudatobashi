import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/trainer.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../play/sfx_overlay.dart';
import '../shell/coming_soon.dart';
import '../torifuda/torifuda_painter.dart';
import 'celebration_chrome.dart';
import 'celebrations.dart';

/// "A new card appears" (spec phone 5): the card rises out of a flash of
/// focus lines, with its kimariji, where it is decided and on which island.
/// Accepting flicks the card away like a swipe in play, then moves on.
class NewCardOverlay extends StatefulWidget {
  const NewCardOverlay({super.key, required this.data, required this.onNext});
  final NewCardCelebration data;
  final VoidCallback onNext;

  @override
  State<NewCardOverlay> createState() => _NewCardOverlayState();
}

class _NewCardOverlayState extends State<NewCardOverlay> with SingleTickerProviderStateMixin {
  late final _flick = AnimationController(vsync: this, duration: PlaySfxTuning.duration);
  Timer? _leave;

  @override
  void dispose() {
    _leave?.cancel();
    _flick.dispose();
    super.dispose();
  }

  void _accept() {
    if (_leave != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onNext();
      return;
    }
    _flick.forward();
    _leave = Timer(NewCardMotion.flickLength, widget.onNext);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = poems[widget.data.poemId];
    return EntranceStage(
      length: NewCardMotion.actions.end,
      child: CelebrationChrome(
        color: Palette.seaDeep,
        onNext: _accept,
        backdrop: const [
          Entrance(
            NewCardMotion.lines,
            child: Throb(
              amount: NewCardMotion.linesThrob,
              period: NewCardMotion.throbPeriod,
              child: BoilingLines(NewCardLayout.focus,
                  frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
            ),
          ),
          Entrance(
            NewCardMotion.flash,
            child: Throb(
              amount: NewCardMotion.glowThrob,
              period: NewCardMotion.throbPeriod,
              child: CelebrationGlow(
                at: NewCardLayout.glowAt,
                size: NewCardLayout.glowSize,
                colors: NewCardLayout.glowColors,
                stops: NewCardLayout.glowStops,
              ),
            ),
          ),
        ],
        child: Jolt(
          NewCardMotion.jolt,
          reach: NewCardMotion.joltReach,
          steps: NewCardMotion.joltSteps,
          seed: NewCardMotion.joltSeed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: NewCardLayout.topGap),
              _Header(shout: s.newCardShout, band: s.newCardBand),
              Expanded(child: _CardStage(poem: poem, flick: _flick)),
              Stack(clipBehavior: Clip.none, children: [
                Entrance(NewCardMotion.info, child: _InfoPanel(poem: poem)),
                const Placed(
                  NewCardLayout.exclaim,
                  child: Entrance(
                    NewCardMotion.tobi,
                    child: _Exclaim(),
                  ),
                ),
                const Placed(
                  NewCardLayout.tobi,
                  child: Entrance(
                    NewCardMotion.tobi,
                    child: Shake(
                      reach: NewCardMotion.tobiTremble,
                      step: NewCardMotion.tobiTrembleStep,
                      seed: NewCardLayout.bangSeed,
                      child: Tobi(pose: TobiPose.shocked),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: NewCardLayout.actionsGap),
              Entrance(
                NewCardMotion.actions,
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: NewCardLayout.learnFlex, child: _LearnButton(label: s.learnAboutCard)),
                    const SizedBox(width: NewCardLayout.actionsGap),
                    Expanded(
                      flex: NewCardLayout.acceptFlex,
                      child: CelebrationCta(
                        label: s.bringItOn,
                        sub: s.other.bringItOn,
                        onTap: _accept,
                        height: NewCardLayout.actionHeight,
                        fontSize: NewCardLayout.acceptFont,
                        subFontSize: NewCardLayout.acceptSubFont,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: Gaps.section),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The 新しい札、登場!! shout, the band under it, and ババーン!! across both.
class _Header extends StatelessWidget {
  const _Header({required this.shout, required this.band});
  final String shout;
  final String band;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Entrance(
            NewCardMotion.shout,
            child: SizedBox(
              height: NewCardLayout.shoutHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: const ShoutPainter(NewCardLayout.shout, fill: Palette.paper),
                child: Padding(
                  padding: NewCardLayout.shoutPadding,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(shout,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: NewCardLayout.shoutFont, height: 1)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: NewCardLayout.bandGap),
          Padding(
            padding: const EdgeInsets.only(left: NewCardLayout.bandIndent),
            child: InkTag(band,
                fontSize: NewCardLayout.bandFont, tracking: NewCardLayout.bandTracking, padding: NewCardLayout.bandPadding),
          ),
        ]),
        Positioned(
          top: NewCardLayout.bangTop,
          right: NewCardLayout.bangRight,
          child: Entrance(
            NewCardMotion.sfx,
            child: Transform.rotate(
              angle: NewCardLayout.bangTurnDeg * math.pi / 180,
              child: const SfxText(NewCardLayout.bang,
                  size: NewCardLayout.bangFont,
                  color: Palette.sun,
                  seed: NewCardLayout.bangSeed,
                  outline: NewCardLayout.sfxOutline),
            ),
          ),
        ),
      ]);
}

/// The card, as large as the space allows, flanked by rumble lettering. On
/// accept it flies off along [flick] with an SFX pop and a speed streak.
class _CardStage extends StatelessWidget {
  const _CardStage({required this.poem, required this.flick});
  final Poem poem;
  final Animation<double> flick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final width = math.min(box.maxWidth * NewCardLayout.cardWidthShare,
            math.max(0.0, box.maxHeight - 2 * NewCardLayout.cardMargin) / TorifudaSpec.aspect);
        final card = Rect.fromCenter(
            center: box.biggest.center(Offset.zero), width: width, height: width * TorifudaSpec.aspect);
        Widget rumble(String text, int seed, double drop, {required bool left}) => Positioned(
              left: left ? 0 : card.right,
              right: left ? box.maxWidth - card.left : 0,
              top: card.top + card.height * drop,
              child: Center(
                child: Entrance(
                  NewCardMotion.sfx,
                  child: Shake(
                    reach: NewCardMotion.rumbleReach,
                    step: NewCardMotion.rumbleStep,
                    seed: seed,
                    child: SfxText(text,
                        size: NewCardLayout.rumbleFont,
                        color: Palette.paper,
                        halo: const Color(0x00000000),
                        outline: NewCardLayout.rumbleOutline,
                        seed: seed,
                        vertical: true),
                  ),
                ),
              ),
            );
        return Stack(clipBehavior: Clip.none, children: [
          rumble(NewCardLayout.rumbleLeft, NewCardLayout.rumbleLeftSeed, NewCardLayout.rumbleLeftDrop, left: true),
          rumble(NewCardLayout.rumbleRight, NewCardLayout.rumbleRightSeed, NewCardLayout.rumbleRightDrop, left: false),
          Positioned.fromRect(
            rect: card,
            child: _Flick(
              flick: flick,
              child: Entrance(
                NewCardMotion.card,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(
                    child: EntranceBuilder(
                      NewCardMotion.flyStreakFade,
                      builder: (context, t, _) => _Streak(NewCardMotion.flyStreak,
                          opacity: ((1 - t) / (1 - NewCardMotion.flyStreakHold)).clamp(0.0, 1.0)),
                    ),
                  ),
                  Positioned.fill(
                    child: Sway(
                      turnDeg: NewCardMotion.swayDeg,
                      lift: NewCardMotion.swayLift,
                      period: NewCardMotion.swayPeriod,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(boxShadow: [NewCardLayout.cardShadow]),
                        child: TorifudaCard(poem: poem),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]);
      });
}

/// The play loop's card flick: [child] flies off with a speed streak behind
/// it and an SFX pop above it, driven by [flick] (0–1 over the SFX pop).
class _Flick extends StatelessWidget {
  const _Flick({required this.flick, required this.child});
  final Animation<double> flick;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: flick,
        child: child,
        builder: (context, child) {
          final elapsed = PlaySfxTuning.duration * flick.value;
          double share(Duration part) => (elapsed.inMicroseconds / part.inMicroseconds).clamp(0.0, 1.0);
          final fly = NewCardMotion.flyCurve.transform(share(NewCardMotion.flyLength));
          final streak = share(NewCardMotion.streakLength);
          final streakOpacity = streak < NewCardMotion.streakPeak
              ? streak / NewCardMotion.streakPeak
              : 1 - (streak - NewCardMotion.streakPeak) / (1 - NewCardMotion.streakPeak);
          const to = NewCardMotion.flickTo;
          return Stack(clipBehavior: Clip.none, children: [
            if (flick.value > 0 && streak < 1) Positioned.fill(child: _Streak(NewCardMotion.streak, opacity: streakOpacity.clamp(0.0, 1.0))),
            Transform.translate(
              offset: to * fly,
              child: Transform.rotate(angle: NewCardMotion.flickTurnDeg * fly * math.pi / 180, child: child),
            ),
            if (flick.value > 0)
              Align(
                alignment: Alignment.topCenter,
                child: FractionalTranslation(
                  translation: const Offset(0, -0.6),
                  child: Transform.rotate(
                    angle: NewCardMotion.flickWordTurnDeg * math.pi / 180,
                    child: SfxPop(
                      progress: flick.value,
                      child: const SfxText(NewCardMotion.flickWord,
                          size: NewCardMotion.flickWordFont, color: PlaySfxTuning.knownColor),
                    ),
                  ),
                ),
              ),
          ]);
        },
      );
}

/// A speed streak trailing the card along its flight path (in from the
/// lower left, out to the upper right).
class _Streak extends StatelessWidget {
  const _Streak(this.spec, {required this.opacity});
  final SpeedLinesSpec spec;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    const to = NewCardMotion.flickTo;
    return OverflowBox(
      minWidth: NewCardMotion.streakBox.width,
      maxWidth: NewCardMotion.streakBox.width,
      minHeight: NewCardMotion.streakBox.height,
      maxHeight: NewCardMotion.streakBox.height,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: math.atan2(to.dy, to.dx),
          child: Transform.translate(
            offset: const Offset(-NewCardMotion.streakBack, 0),
            child: CustomPaint(size: NewCardMotion.streakBox, painter: SpeedLinesPainter(spec)),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.poem});
  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final island = archipelago.islands[Trainer.islandOf(poem)];
    final order = island.sites.indexWhere((site) => site.poemId == poem.id) + 1;
    final kimariji = poem.kimariji;
    final tip = s.deciderTip(kimariji.length, poems.kimarijiTwin(poem)?.kimariji).split('{0}');
    return MangaPanel(
      shape: const PanelShape(topLeft: NewCardLayout.infoCut),
      padding: NewCardLayout.infoPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: OutlinedText(kimariji,
                  style: const TextStyle(
                      fontFamily: Fonts.display, fontSize: NewCardLayout.kimarijiFont, color: Palette.pink, height: 1),
                  outline: Palette.ink,
                  outlineWidth: NewCardLayout.kimarijiOutline),
            ),
          ),
          const SizedBox(width: NewCardLayout.labelGap),
          Text(s.kimarijiLabel,
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: NewCardLayout.labelFont,
                  letterSpacing: NewCardLayout.labelTracking * NewCardLayout.labelFont,
                  height: 1.2)),
        ]),
        const SizedBox(height: NewCardLayout.metaGap),
        Text.rich(
          TextSpan(style: const TextStyle(fontWeight: Weights.black, fontSize: NewCardLayout.metaFont), children: [
            TextSpan(text: '#${poem.id} '),
            TextSpan(text: '· ${poem.author} · ', style: const TextStyle(fontWeight: Weights.bold)),
            TextSpan(text: '${island.name} $order / ${island.sites.length}'),
          ]),
        ),
        const SizedBox(height: NewCardLayout.tipGap),
        Text.rich(
          TextSpan(style: const TextStyle(fontWeight: Weights.bold, fontSize: NewCardLayout.tipFont), children: [
            TextSpan(text: tip.first),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Palette.sun,
                  border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: NewCardLayout.tipKanaBorder)),
                ),
                child: Padding(
                  padding: NewCardLayout.tipKanaPadding,
                  child: Text(kimariji.characters.last,
                      style: const TextStyle(fontWeight: Weights.black, fontSize: NewCardLayout.tipFont)),
                ),
              ),
            ),
            if (tip.length > 1) TextSpan(text: tip.last),
          ]),
        ),
      ]),
    );
  }
}

class _Exclaim extends StatelessWidget {
  const _Exclaim();

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: NewCardLayout.exclaimTurnDeg * math.pi / 180,
        child: const OutlinedText(NewCardLayout.exclaimText,
            style: TextStyle(fontFamily: Fonts.display, fontSize: NewCardLayout.exclaimFont, color: Palette.sun, height: 1),
            outline: Palette.ink,
            outlineWidth: NewCardLayout.sfxOutline),
      );
}

/// Not built yet: pops a coming-soon balloon.
class _LearnButton extends StatelessWidget {
  const _LearnButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NewCardLayout.actionHeight),
        child: Builder(
          builder: (context) => InkButton(
            onTap: () => ComingSoonBubble.show(context),
            padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.small),
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: Weights.black, fontSize: NewCardLayout.learnFont, height: 1.2)),
          ),
        ),
      );
}
