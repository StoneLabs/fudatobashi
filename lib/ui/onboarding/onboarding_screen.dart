import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../domain/trainer.dart';
import '../../l10n/onboarding_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import 'onboarding_panels.dart';
import 'step_swap.dart';

/// First launch: Tobi asks how well the player knows the 100 cards, and the
/// answer picks the learning mode (and so the Home screen). A beginner then
/// picks the journey's pace.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { mode, pace }

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  _Step _step = _Step.mode;

  Future<void> _choose(LearningMode mode, {LearningPace? pace}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ProgressScope.read(context).setLearningMode(mode, pace: pace);
  }

  VoidCallback? _goTo(_Step step) => _busy ? null : () => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: StepSwap(
          step: _step.index,
          builder: (context, step) => switch (_Step.values[step]) {
            _Step.mode => _modeStep(s),
            _Step.pace => _paceStep(s),
          },
        ),
      ),
    );
  }

  Widget _modeStep(S s) {
    final first = fudaSets['initial:${initialGroups.first}'];
    return _StepPage(
      children: [
        Flexible(
          child: SwapPiece(
            order: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: OnboardingLayout.skyMinHeight,
                maxHeight: OnboardingLayout.skyHeight,
              ),
              child: WelcomePanel(
                title: s.welcomeTitle,
                banner: s.welcomeBanner,
                hello: s.tobiHello,
                question: s.howWell,
                other: s.other.howWellOneLine,
              ),
            ),
          ),
        ),
        const SizedBox(height: Gaps.panelWide),
        SwapPiece(
          order: 1,
          child: ModeChoice(
            shape: const PanelShape(topLeft: Offset(0, OnboardingLayout.choiceCut)),
            color: Palette.landSoft,
            art: SceneArt.beginner,
            tag: s.beginnerTag,
            title: s.beginnerTitle,
            sub: s.beginnerSub,
            note: s.firstStop(first.label, first.poemIds.length),
            onTap: _goTo(_Step.pace),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        SwapPiece(
          order: 2,
          child: ModeChoice(
            shape: const PanelShape(bottomRight: Offset(0, OnboardingLayout.choiceCut)),
            color: Palette.sunSoft,
            art: SceneArt.expert,
            tag: s.expertTag,
            title: s.expertTitle,
            sub: s.expertSub,
            note: s.expertNote,
            onTap: _busy ? null : () => _choose(LearningMode.allKnown),
          ),
        ),
        const SizedBox(height: Gaps.section),
        SwapPiece(order: 3, child: _ChangeLaterNote(where: s.changeLaterWhere)),
      ],
    );
  }

  Widget _paceStep(S s) {
    final relaxed = PaceCaption(title: s.relaxedTitle, sub: s.relaxedSub, note: s.relaxedNote);
    final sprint = PaceCaption(title: s.sprintTitle, sub: s.sprintSub, note: s.sprintNote);
    return _StepPage(
      children: [
        SwapPiece(
          order: 0,
          child: PaceHeader(banner: s.paceBanner, question: s.howFast, other: s.other.howFast),
        ),
        const SizedBox(height: Gaps.panelWide),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SwapPiece(
                  order: 1,
                  child: PaceChoice(
                    shape: const PanelShape(bottomRight: Offset(OnboardingLayout.paceSlant, 0)),
                    art: const [
                      RadialLayer(
                          center: Backdrops.relaxedCenter, colors: Backdrops.relaxedColors, stops: Backdrops.relaxedStops),
                      ToneLayer(Tones.seaFaint,
                          fadeAngle: Backdrops.relaxedToneAngle, fadeStops: Backdrops.relaxedToneStops),
                    ],
                    band: OnboardingLayout.relaxedBand,
                    pose: TobiPose.relaxed,
                    callStyle: PaceCall.balloon,
                    call: s.relaxedCall,
                    tag: s.relaxedTag,
                    caption: relaxed,
                    beside: sprint,
                    onTap: _busy ? null : () => _choose(LearningMode.journey, pace: LearningPace.month),
                  ),
                ),
              ),
              Expanded(
                child: SwapPiece(
                  order: 2,
                  child: PaceChoice(
                    shape: const PanelShape(topLeft: Offset(OnboardingLayout.paceSlant, 0)),
                    art: const [
                      RadialLayer(
                          center: Backdrops.sprintCenter, colors: Backdrops.sprintColors, stops: Backdrops.sprintStops),
                      BurstLayer(Bursts.sprint),
                    ],
                    band: OnboardingLayout.sprintBand,
                    pose: TobiPose.tryHard,
                    callStyle: PaceCall.shout,
                    call: s.sprintCall,
                    go: OnboardingLayout.sprintGo,
                    tag: s.sprintTag,
                    caption: sprint,
                    beside: relaxed,
                    onTap: _busy ? null : () => _choose(LearningMode.journey, pace: LearningPace.sprint),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.section),
        SwapPiece(
          order: 3,
          child: Row(
            children: [
              InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: _goTo(_Step.mode)),
              const SizedBox(width: Gaps.panelWide),
              Expanded(child: _ChangeLaterNote(where: s.paceLaterWhere)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A step's pieces top to bottom, filling the screen; the flexible ones take
/// what's left. Scrolls instead when even their smallest sizes don't fit.
class _StepPage extends StatelessWidget {
  const _StepPage({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Gaps.gutter, OnboardingLayout.topGap, Gaps.gutter, OnboardingLayout.bottomGap),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ),
      );
}

class _ChangeLaterNote extends StatelessWidget {
  const _ChangeLaterNote({required this.where});
  final String where;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DashedBox(
      padding: OnboardingLayout.notePadding,
      child: Row(
        children: [
          MangaIcon(IconArt.settings, size: OnboardingLayout.noteIcon),
          const SizedBox(width: Gaps.panelWide),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  Phrases.span(s.changeLaterBefore),
                  Phrases.span(where, style: const TextStyle(fontWeight: Weights.black)),
                  Phrases.span(s.changeLaterAfter),
                ],
              ),
              style: const TextStyle(
                fontSize: OnboardingLayout.noteFont,
                fontWeight: Weights.bold,
                height: OnboardingLayout.noteLineHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
