import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/romaji.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import 'guide_figures.dart';

/// "How karuta works", from Help: the poems, the reader and the two kinds
/// of card, how a match goes, faults, kimariji and what this app trains,
/// in numbered chapters with pictures and a word from Tobi here and there.
/// Every kana the text names comes from the poems ([KarutaGuideExamples]).
class KarutaGuideScreen extends StatelessWidget {
  const KarutaGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    final first = poems[KarutaGuideExamples.readFirst], second = poems[KarutaGuideExamples.shortened];
    final shared = second.kimariji.substring(0, second.kimariji.length - 1);
    final left = [for (final p in poems.all) if (p.id != first.id) p];
    final shortened = poems.kimarijiAmong(second, left);

    // Kana as English text names them: kept on one line, with how they
    // are read in romaji. Japanese text may break them like any other.
    String named(String kana, String reading) =>
        romaji ? '${kana.split('').join(_wordJoiner)} (${hepburn(reading)})' : kana;
    String say(Poem p, int length) => named(p.kamiKana.substring(0, length), p.kamiReading.substring(0, length));

    final phrase = first.kamiKana.split(Ruby.phraseBreak).first.length;
    final sixStarts = [
      for (final start in KarutaGuideExamples.sixSound)
        say(poems.all.firstWhere((p) => p.kimariji.startsWith(start)), start.length),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HeaderStyle.topGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: MangaHeader(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ScreenTitle(s.guideTitle, sub: s.other.guideTitle),
                ),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
            ),
            const SizedBox(height: Gaps.section),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Gaps.gutter, Gaps.tight, Gaps.gutter + KarutaGuideLayout.figureShadow, ProseLayout.bottomPad),
                children: [
                  const GuideFan(),
                  _Tobi(s.guideIntro, pose: TobiPose.waving),

                  ProseChapter(1, s.guidePoemsTitle, o?.guidePoemsTitle),
                  ProseBody(s.guidePoems1),
                  ProseBody(s.guidePoems2),
                  _Figure(child: GuidePoemHalves(poem: poems[KarutaGuideExamples.poem])),
                  ProseBody(s.guidePoems3),

                  ProseChapter(2, s.guideCardsTitle, o?.guideCardsTitle),
                  ProseBody(s.guideCards1),
                  ProseBody(s.guideCards2),
                  _Figure(child: GuideTwoCards(poem: poems[KarutaGuideExamples.poem])),
                  _Tobi(s.guideCardsTobi, pose: TobiPose.pointing),

                  ProseChapter(3, s.guideMatchTitle, o?.guideMatchTitle),
                  for (final (i, line) in s.guideSteps.indexed) _Step(i + 1, line),
                  const _Figure(child: GuideField()),
                  _Tobi(s.guideMatchTobi, pose: TobiPose.relaxed),

                  ProseChapter(4, s.guideFaultTitle, o?.guideFaultTitle),
                  ProseBody(s.guideFault1),
                  ProseBody(s.guideFault2),
                  ProseBody(s.guideFault3),
                  _Tobi(s.guideFaultTobi, pose: TobiPose.shocked),

                  ProseChapter(5, s.guideKimarijiTitle, o?.guideKimarijiTitle),
                  ProseBody(s.guideKimariji1),
                  _Subhead(s.guideOneTitle),
                  ProseBody(s.guideOne(named(KarutaGuideExamples.oneSound, KarutaGuideExamples.oneSound))),
                  const _Figure(child: GuideOneSoundTiles()),
                  _Subhead(s.guideLongTitle),
                  ProseBody(s.guideLong(say(first, phrase), say(second, phrase), say(second, shared.length))),
                  _Figure(
                    caption: s.guideLongCaption,
                    child: GuideKimarijiRows(rows: [
                      GuideKimarijiRow(poem: first, kimariji: first.kimariji),
                      GuideKimarijiRow(poem: second, kimariji: second.kimariji),
                    ]),
                  ),
                  _Subhead(s.guideChangeTitle),
                  ProseBody(s.guideChange(say(first, phrase), say(second, phrase), say(second, shortened.length))),
                  _Figure(
                    caption: s.guideChangeCaption,
                    child: GuideKimarijiRows(rows: [
                      GuideKimarijiRow(poem: first, kimariji: first.kimariji, read: true),
                      GuideKimarijiRow(poem: second, kimariji: shortened),
                    ]),
                  ),
                  ProseBody(s.guideSix(sixStarts)),
                  _Tobi(s.guideKimarijiTobi, pose: TobiPose.fired),

                  ProseChapter(6, s.guideAppTitle, o?.guideAppTitle),
                  ProseBody(s.guideApp1),
                  ProseBody(s.guideApp2),
                  _Tobi(s.guideAppTobi, pose: TobiPose.cheering),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the characters either side of it on one line.
const _wordJoiner = '\u2060';

/// A small heading inside a chapter.
class _Subhead extends StatelessWidget {
  const _Subhead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaGuideLayout.figureGap),
        child: Semantics(
          header: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkTag(text.toUpperCase(), fontSize: KarutaGuideLayout.subheadFont),
          ),
        ),
      );
}

/// One step of a match: its number in an ink circle, then its line.
class _Step extends StatelessWidget {
  const _Step(this.number, this.line);

  final int number;
  final String line;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaGuideLayout.stepRowGap),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox.square(
            dimension: KarutaGuideLayout.stepNumber,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
              child: Center(
                child: Text('$number',
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                        fontFamily: Fonts.display, fontSize: KarutaGuideLayout.stepNumberFont, color: Palette.paper)),
              ),
            ),
          ),
          const SizedBox(width: KarutaGuideLayout.stepGap),
          Expanded(child: Text(line, style: proseStyle)),
        ]),
      );
}

/// A picture in a panel with a hard shadow, and its [caption] under it.
class _Figure extends StatelessWidget {
  const _Figure({required this.child, this.caption});

  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KarutaGuideLayout.figureGap),
        child: MangaPanel(
          color: Palette.desk,
          shadow: const Offset(KarutaGuideLayout.figureShadow, KarutaGuideLayout.figureShadow),
          padding: KarutaGuideLayout.figurePadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            child,
            if (caption case final caption?) ...[
              const SizedBox(height: KarutaGuideLayout.captionGap),
              Text(caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.captionFont)),
            ],
          ]),
        ),
      );
}

/// Tobi saying [line] in a balloon to his right.
class _Tobi extends StatelessWidget {
  const _Tobi(this.line, {required this.pose});

  final String line;
  final TobiPose pose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KarutaGuideLayout.figureGap),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox.fromSize(size: KarutaGuideLayout.tobi, child: Tobi(pose: pose)),
          const SizedBox(width: KarutaGuideLayout.tobiGap),
          Expanded(
            child: SpeechBalloon(
              speaker: KarutaGuideLayout.speakerLeft,
              padding: KarutaGuideLayout.balloonPadding,
              child: Text(line, style: const TextStyle(fontSize: KarutaGuideLayout.balloonFont)),
            ),
          ),
        ]),
      );
}
