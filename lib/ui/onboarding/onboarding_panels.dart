import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../manga/manga.dart';
import '../shell/header_actions.dart';
import 'welcome_sea.dart';

/// Display lettering that grows with the system text size only so far.
class _Lettering extends StatelessWidget {
  const _Lettering({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: OnboardingLayout.letteringMaxScale, child: child);
}

/// [text] kept to its own lines (explicit line breaks only), shrunk to fit
/// the width if it has to.
class _FitLines extends StatelessWidget {
  const _FitLines(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, softWrap: false, style: style));
}

/// The first step's sky: big lettering (Japanese in both languages), the
/// banner under it, and Tobi waving from his island with a balloon: a
/// greeting, a question and the question in the other language.
class WelcomePanel extends StatelessWidget {
  const WelcomePanel({
    super.key,
    required this.title,
    required this.banner,
    required this.hello,
    required this.question,
    required this.other,
  });

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
              WelcomeSeaLayer(),
            ],
            child: Stack(
              children: [
                const Positioned.fill(child: WelcomeSeaFront()),
                Positioned(
                  left: OnboardingLayout.titleAt.dx,
                  top: OnboardingLayout.titleAt.dy,
                  child: _Lettering(
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
                _FitLines(
                  hello,
                  style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontWeight: Weights.regular,
                    fontSize: OnboardingLayout.balloonTitle,
                  ),
                ),
                const SizedBox(height: OnboardingLayout.balloonGap),
                _FitLines(question, style: const TextStyle(fontSize: OnboardingLayout.balloonBody)),
                const SizedBox(height: OnboardingLayout.balloonGap),
                _FitLines(
                  other,
                  style: const TextStyle(
                    fontSize: OnboardingLayout.balloonSmall,
                    fontWeight: Weights.bold,
                    color: Palette.mute,
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

/// A first-step choice: an illustration on the left, then a tag, title,
/// subtitle and note, with the go button beside the note. At least
/// [OnboardingLayout.choiceHeight] tall; taller when the text needs it.
class ModeChoice extends StatelessWidget {
  const ModeChoice({
    super.key,
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
  final VectorArt art;
  final String tag, title, sub, note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: Press.panelScale,
      turn: 0,
      semanticLabel: '$title: $sub',
      builder: (context, _) => MangaPanel(
        shape: shape,
        color: color,
        child: Stack(
          children: [
            Positioned(
              left: OnboardingLayout.illustrationInset,
              top: 0,
              bottom: 0,
              child: Center(child: VectorArtBox(art, size: const Size.square(OnboardingLayout.illustration))),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: OnboardingLayout.choiceHeight),
              child: Padding(
                padding: OnboardingLayout.textInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
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
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
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
                        const SizedBox(width: OnboardingLayout.goGap),
                        const GoButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pace step's header: the banner, the question in big lettering and
/// the question in the other language.
class PaceHeader extends StatelessWidget {
  const PaceHeader({super.key, required this.banner, required this.question, required this.other});

  final String banner, question, other;

  @override
  Widget build(BuildContext context) {
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, OnboardingLayout.paceHeaderCut)),
      art: const [RadialLayer(center: Backdrops.paceSkyCenter, colors: Backdrops.skyColors, stops: Backdrops.skyStops)],
      padding: OnboardingLayout.paceHeaderInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Lettering(child: InkBanner(banner)), const Spacer(), const LanguageSwitch()],
          ),
          const SizedBox(height: OnboardingLayout.paceQuestionGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _Lettering(
              child: OutlinedText(
                question,
                outlineWidth: OnboardingLayout.paceQuestionOutline,
                style: const TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: OnboardingLayout.paceQuestion,
                  height: TypeScale.displayLineHeight,
                ),
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.paceOtherGap),
          Text(
            other,
            style: const TextStyle(fontSize: OnboardingLayout.paceOther, fontWeight: Weights.bold, color: Palette.mute),
          ),
        ],
      ),
    );
  }
}

/// How Tobi says his line on a pace choice.
enum PaceCall { balloon, shout }

/// A pace choice's caption: its length (the headline), a subtitle and a note.
@immutable
class PaceCaption {
  const PaceCaption({required this.title, required this.sub, required this.note});
  final String title, sub, note;
}

/// A pace choice, poster style: a tag, Tobi as big as fits saying [call],
/// the go button at his feet, and a band along the bottom with [caption].
class PaceChoice extends StatelessWidget {
  const PaceChoice({
    super.key,
    required this.shape,
    required this.art,
    required this.band,
    required this.pose,
    required this.callStyle,
    required this.call,
    required this.tag,
    required this.caption,
    required this.beside,
    required this.onTap,
    this.go = Palette.pink,
  });

  final PanelShape shape;
  final List<ArtLayer> art;
  final Color band;
  final TobiPose pose;
  final PaceCall callStyle;
  final String call, tag;
  final PaceCaption caption;

  /// The caption of the choice beside this one: the band is as tall as the
  /// taller of the two, so the bands line up.
  final PaceCaption beside;
  final Color go;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clear = EdgeInsets.only(left: shape.bottomLeft.dx, right: shape.bottomRight.dx);
    return Pressable(
      onTap: onTap,
      scale: Press.panelScale,
      turn: 0,
      semanticLabel: '${caption.title}: ${Phrases.spoken(caption.sub)}',
      builder: (context, _) => MangaPanel(
        shape: shape,
        art: art,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: OnboardingLayout.paceInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkTag(tag, padding: TagStyle.compactPadding),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: OnboardingLayout.paceArtMin),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Call(call, style: callStyle),
                                  const SizedBox(height: OnboardingLayout.paceCallGap),
                                  Flexible(
                                    child: Padding(
                                      padding: OnboardingLayout.paceTobiPadding,
                                      child: FittedBox(
                                        child: SizedBox.fromSize(
                                            size: OnboardingLayout.paceTobi, child: Tobi(pose: pose)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(right: 0, bottom: 0, child: GoButton(color: go)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: band,
                border: const Border(top: BorderSide(color: Palette.ink, width: Strokes.panel)),
              ),
              child: Padding(
                padding: OnboardingLayout.paceBandInsets,
                child: Stack(
                  children: [
                    Visibility(
                      visible: false,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: _Caption(beside, clear: clear),
                    ),
                    _Caption(caption, clear: clear),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.caption, {required this.clear});
  final PaceCaption caption;

  /// Keeps the headline, which fills the width, off a slanted bottom corner.
  final EdgeInsets clear;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: clear, child: _Headline(caption.title)),
          const SizedBox(height: OnboardingLayout.paceSubGap),
          Text.rich(Phrases.span(caption.sub),
              style: const TextStyle(fontSize: OnboardingLayout.paceSub, fontWeight: Weights.black)),
          const SizedBox(height: OnboardingLayout.paceNoteGap),
          Text.rich(
            Phrases.span(caption.note),
            style: const TextStyle(
              fontSize: OnboardingLayout.paceNote,
              fontWeight: Weights.bold,
              height: OnboardingLayout.paceNoteLineHeight,
              color: Palette.inkSoft,
            ),
          ),
        ],
      );
}

class _Call extends StatelessWidget {
  const _Call(this.text, {required this.style});
  final String text;
  final PaceCall style;

  @override
  Widget build(BuildContext context) {
    final line = _FitLines(
      text,
      style: const TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: OnboardingLayout.paceCall),
    );
    return switch (style) {
      PaceCall.balloon => SpeechBalloon(
          speaker: OnboardingLayout.paceCallSpeaker,
          padding: OnboardingLayout.paceCallPadding,
          child: line,
        ),
      PaceCall.shout => CustomPaint(
          painter: const ShoutPainter(OnboardingLayout.sprintShout, fill: Palette.paper),
          child: Padding(padding: OnboardingLayout.paceShoutPadding, child: Center(child: line)),
        ),
    };
  }
}

/// A pace's length in display type, its figures large ("About 15 days").
/// It keeps one line's height when it has to shrink to fit, sitting on the
/// bottom, so headlines side by side line up.
class _Headline extends StatelessWidget {
  const _Headline(this.text);
  final String text;

  static final _figures = RegExp(r'\d+');

  @override
  Widget build(BuildContext context) {
    const figure = TextStyle(fontSize: OnboardingLayout.paceFigure);
    final spans = <TextSpan>[];
    var at = 0;
    for (final m in _figures.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      spans.add(TextSpan(text: m[0], style: figure));
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return _Lettering(
      child: Builder(
        builder: (context) => SizedBox(
          height: MediaQuery.textScalerOf(context).scale(OnboardingLayout.paceFigure) * TypeScale.displayLineHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Text.rich(
              TextSpan(children: spans),
              softWrap: false,
              style: const TextStyle(
                fontFamily: Fonts.display,
                fontSize: OnboardingLayout.paceUnit,
                height: TypeScale.displayLineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
