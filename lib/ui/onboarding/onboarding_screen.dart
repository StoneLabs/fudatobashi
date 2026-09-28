import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../domain/trainer.dart';
import '../../l10n/onboarding_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../shell/header_actions.dart';

/// First launch: Tobi asks how well the player knows the 100 cards, and the
/// answer picks the learning mode (and so the Home screen). A beginner then
/// picks the journey's pace.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  bool _pickingPace = false;

  Future<void> _choose(LearningMode mode, {LearningPace? pace}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ProgressScope.read(context).setLearningMode(mode, pace: pace);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: OnboardingLayout.topGap),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: OnboardingLayout.skyHeight),
                  child: _pickingPace
                      ? _Welcome(
                          title: 'ペース',
                          banner: s.paceBanner,
                          hello: s.tobiPace,
                          question: s.howFast,
                          other: s.other.howFast,
                        )
                      : _Welcome(
                          title: 'ようこそ!',
                          banner: s.welcomeBanner,
                          hello: s.tobiHello,
                          question: s.howWell,
                          other: s.other.howWell,
                        ),
                ),
              ),
              const SizedBox(height: Gaps.panelWide),
              ...(_pickingPace ? _paceChoices(s) : _modeChoices(s)),
              const SizedBox(height: Gaps.section),
              Row(
                children: [
                  if (_pickingPace) ...[
                    InkIconButton(
                      icon: IconArt.back,
                      semanticLabel: s.back,
                      onTap: _busy ? null : () => setState(() => _pickingPace = false),
                    ),
                    const SizedBox(width: Gaps.panelWide),
                  ],
                  Expanded(child: _ChangeLaterNote(where: _pickingPace ? s.paceLaterWhere : s.changeLaterWhere)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _modeChoices(S s) {
    final first = fudaSets['initial:${initialGroups.first}'];
    return [
      _Choice(
        shape: const PanelShape(topLeft: Offset(0, OnboardingLayout.choiceCut)),
        color: Palette.landSoft,
        art: const _SceneArt(PrerenderedArt.beginner),
        tag: s.beginnerTag,
        title: s.beginnerTitle,
        sub: s.beginnerSub,
        note: s.firstStop(first.label, first.poemIds.length),
        onTap: _busy ? null : () => setState(() => _pickingPace = true),
      ),
      const SizedBox(height: Gaps.panel),
      _Choice(
        shape: const PanelShape(bottomRight: Offset(0, OnboardingLayout.choiceCut)),
        color: Palette.sunSoft,
        art: const _SceneArt(PrerenderedArt.expert),
        tag: s.expertTag,
        title: s.expertTitle,
        sub: s.expertSub,
        note: s.expertNote,
        onTap: _busy ? null : () => _choose(LearningMode.allKnown),
      ),
    ];
  }

  List<Widget> _paceChoices(S s) => [
    _Choice(
      shape: const PanelShape(topLeft: Offset(0, OnboardingLayout.choiceCut)),
      color: Palette.landSoft,
      art: const _SceneArt(PrerenderedArt.beginner),
      tag: s.relaxedTag,
      title: s.relaxedTitle,
      sub: s.relaxedSub,
      note: s.relaxedNote,
      onTap: _busy ? null : () => _choose(LearningMode.journey, pace: LearningPace.month),
    ),
    const SizedBox(height: Gaps.panel),
    _Choice(
      shape: const PanelShape(bottomRight: Offset(0, OnboardingLayout.choiceCut)),
      color: Palette.sunSoft,
      art: SizedBox.fromSize(
        size: OnboardingLayout.sprintTobi,
        child: const Tobi(pose: TobiPose.fired),
      ),
      tag: s.sprintTag,
      title: s.sprintTitle,
      sub: s.sprintSub,
      note: s.sprintNote,
      onTap: _busy ? null : () => _choose(LearningMode.journey, pace: LearningPace.sprint),
    ),
  ];
}

class _SceneArt extends StatelessWidget {
  const _SceneArt(this.art);
  final ArtImage art;

  @override
  Widget build(BuildContext context) => ArtImageBox(art, size: const Size.square(OnboardingLayout.illustration));
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
          const MangaIcon(IconArt.settings, size: OnboardingLayout.noteIcon),
          const SizedBox(width: Gaps.panelWide),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: s.changeLaterBefore),
                  TextSpan(
                    text: where,
                    style: const TextStyle(fontWeight: Weights.black),
                  ),
                  TextSpan(text: s.changeLaterAfter),
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

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.title,
    required this.banner,
    required this.hello,
    required this.question,
    required this.other,
  });

  /// Big lettering (Japanese in both languages), the banner under it, and
  /// Tobi's balloon: a greeting, a question and the question in the other
  /// language.
  final String title, banner, hello, question, other;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: MangaPanel(
            shape: const PanelShape(bottomRight: Offset(0, OnboardingLayout.skyCut)),
            art: const [
              RadialLayer(center: Backdrops.skyCenter, colors: Backdrops.skyColors, stops: Backdrops.skyStops),
              BurstLayer(Bursts.onboarding),
            ],
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: OnboardingLayout.seaHeight,
                  child: ArtImageBox(PrerenderedArt.welcomeSea),
                ),
                Positioned(
                  left: OnboardingLayout.titleAt.dx,
                  top: OnboardingLayout.titleAt.dy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedText(
                        title,
                        outlineWidth: OnboardingLayout.titleOutline,
                        style: const TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: OnboardingLayout.title,
                          height: TypeScale.displayLineHeight,
                        ),
                      ),
                      const SizedBox(height: OnboardingLayout.titleBannerGap),
                      InkBanner(banner),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: OnboardingLayout.langInset, right: OnboardingLayout.langInset, child: LanguageSwitch()),
        const Placed(OnboardingLayout.tobi, child: Tobi(pose: TobiPose.waving)),
        Placed(
          OnboardingLayout.balloon,
          child: SpeechBalloon(
            speaker: OnboardingLayout.balloonSpeaker,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hello,
                  style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontWeight: Weights.regular,
                    fontSize: OnboardingLayout.balloonTitle,
                  ),
                ),
                const SizedBox(height: OnboardingLayout.balloonGap),
                Text(question, style: const TextStyle(fontSize: OnboardingLayout.balloonBody)),
                const SizedBox(height: OnboardingLayout.balloonGap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    other,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: OnboardingLayout.balloonSmall,
                      fontWeight: Weights.bold,
                      color: Palette.mute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.shape,
    required this.color,
    required this.art,
    required this.tag,
    required this.title,
    required this.sub,
    required this.note,
    required this.onTap,
  });

  final PanelShape shape;
  final Color color;
  final Widget art;
  final String tag, title, sub, note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: OnboardingLayout.choiceHeight,
      child: Pressable(
        onTap: onTap,
        scale: Press.panelScale,
        turn: 0,
        semanticLabel: '$title: $sub',
        builder: (context, _) => MangaPanel(
          shape: shape,
          color: color,
          child: Stack(
            children: [
              Positioned(left: OnboardingLayout.illustrationAt.dx, top: OnboardingLayout.illustrationAt.dy, child: art),
              Positioned.fill(
                child: Padding(
                  padding: OnboardingLayout.textInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkTag(tag, padding: TagStyle.compactPadding),
                      const SizedBox(height: OnboardingLayout.choiceTitleGap),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: OnboardingLayout.choiceTitle,
                            height: TypeScale.displayLineHeight,
                          ),
                        ),
                      ),
                      const SizedBox(height: OnboardingLayout.choiceSubGap),
                      Text(
                        sub,
                        style: const TextStyle(fontSize: OnboardingLayout.choiceSub, fontWeight: Weights.black),
                      ),
                      const SizedBox(height: OnboardingLayout.choiceNoteGap),
                      Padding(
                        padding: const EdgeInsets.only(right: OnboardingLayout.choiceNoteRightRoom),
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: OnboardingLayout.choiceNote,
                            fontWeight: Weights.bold,
                            height: OnboardingLayout.choiceNoteLineHeight,
                            color: Palette.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(right: OnboardingLayout.goInset, bottom: OnboardingLayout.goInset, child: GoButton()),
            ],
          ),
        ),
      ),
    );
  }
}
