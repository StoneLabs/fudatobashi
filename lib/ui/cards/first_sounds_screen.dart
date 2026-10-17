import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/sound_ladder.dart';
import '../../l10n/first_sounds_strings.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../help/guide_figures.dart';
import '../manga/manga.dart';
import 'about_card_screen.dart';
import 'page_frame.dart';
import 'sound_ladder_view.dart';

/// How to read the sound ladder, opened from a card's About page: what a
/// kimariji is, how it shrinks as cards are read, the parts of a step,
/// consonant steps and the Sounds / Kana switch, in numbered chapters like
/// the karuta guide. Every card and sound the text names is read from the
/// ladders of [FirstSoundsExamples], which the figures show as the About
/// page does, in the player's script.
class FirstSoundsScreen extends StatelessWidget {
  const FirstSoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    String name(Poem poem) => kimarijiFor(context, poem.id);
    String sound(Poem poem, LadderStep step) =>
        (romaji ? SoundLadder.inRomaji(poem, name(poem), step) : SoundLadder.inKana(poem, step)).kept;
    // A consonant step's sound without its consonant and dash: a of ak-.
    String before(Poem poem, LadderStep step) {
      final kept = sound(poem, step);
      return kept.substring(0, kept.length - step.consonant!.length - 1);
    }

    final card = poems[FirstSoundsExamples.card];
    final steps = SoundLadder.of(card, poems.all);
    final kanaSteps = SoundLadder.of(card, poems.all, kanaOnly: true);
    final pair = kanaSteps[1];
    final rival = poems[pair.joining.single];
    final shared = sound(card, pair);
    final top = steps.first;
    final consonantStep = steps.skip(1).firstWhere((step) => step.isConsonant);

    final vowel = poems[FirstSoundsExamples.consonant];
    final vowelSteps = SoundLadder.of(vowel, poems.all);
    final vowelTop = vowelSteps.first;
    final vowelRival = poems.all.singleWhere((p) =>
        p.id != vowel.id && p.kamiReading.startsWith(vowel.kamiReading.substring(0, vowelTop.kana)));

    final sh = poems[FirstSoundsExamples.sh];

    void open(int id) => Navigator.of(context).push(MangaRoute<void>(builder: (_) => AboutCardScreen(poemId: id)));
    // A picture, like the guide's: the font scale leaves its lettering alone.
    Widget ladder(Poem poem, {bool kanaOnly = false}) => GuideFigure(
          child: MediaQuery.withNoTextScaling(
            child: SoundLadderView(poem: poem, kanaOnly: kanaOnly, romaji: romaji ? name(poem) : null, onOpen: open),
          ),
        );
    Widget text(String line) => ProseBody(line, phrases: true);
    Widget tobi(String line, TobiPose pose) => GuideTobi(line, pose: pose, phrases: true);

    return PageFrame(
      title: s.firstSoundsTitle,
      sub: s.other.firstSoundsTitle,
      body: ListView(
        padding: PageFrame.padding + const EdgeInsets.only(right: KarutaGuideLayout.figureShadow),
        children: [
          tobi(s.firstSoundsIntro, TobiPose.waving),

          ProseChapter(1, s.firstSoundsKimarijiTitle, o?.firstSoundsKimarijiTitle),
          text(s.firstSoundsKimariji1),
          text(s.firstSoundsKimariji2),
          text(s.firstSoundsKimariji3(card.id, name(card), rival.id, name(rival), shared)),
          GuideFigure(
            caption: s.firstSoundsKimarijiCaption,
            child: GuideKimarijiRows(rows: [
              GuideKimarijiRow(poem: card, kimariji: card.kimariji),
              GuideKimarijiRow(poem: rival, kimariji: rival.kimariji),
            ]),
          ),

          ProseChapter(2, s.firstSoundsShorterTitle, o?.firstSoundsShorterTitle),
          text(s.firstSoundsShorter1(rival.id, name(rival), card.id, shared)),
          GuideFigure(
            caption: s.firstSoundsShorterCaption,
            child: GuideKimarijiRows(rows: [
              GuideKimarijiRow(poem: rival, kimariji: rival.kimariji, read: true),
              GuideKimarijiRow(poem: card, kimariji: card.kimariji.substring(0, pair.kana)),
            ]),
          ),
          text(s.firstSoundsShorter2(kanaSteps.last.cards.length, sound(card, kanaSteps.last))),
          text(s.firstSoundsShorter3),
          tobi(s.firstSoundsShorterTobi, TobiPose.pointing),

          ProseChapter(3, s.firstSoundsStairsTitle, o?.firstSoundsStairsTitle),
          text(s.firstSoundsStairs1(card.id)),
          ladder(card),
          text(s.firstSoundsStairs2),
          GuideSubhead(s.firstSoundsSoundTitle),
          text(s.firstSoundsSound),
          GuideSubhead(s.firstSoundsBadgeTitle),
          text(s.firstSoundsBadge),
          GuideSubhead(s.firstSoundsLineTitle),
          text(s.firstSoundsLine),
          GuideSubhead(s.firstSoundsChipsTitle),
          text(s.firstSoundsChips),
          text(s.firstSoundsStairsExample(shared, pair.cards.length, rival.id, name(rival), card.id)),

          ProseChapter(4, s.firstSoundsConsonantTitle, o?.firstSoundsConsonantTitle),
          text(s.firstSoundsConsonant1),
          text(s.firstSoundsConsonant2(
              sound(card, consonantStep), before(card, consonantStep), consonantStep.consonant!)),
          text(s.firstSoundsConsonant3(card.id, sound(card, top), rival.id,
              SoundLadder.consonantAt(rival.kamiReading, top.kana)!, top.consonant!)),
          text(s.firstSoundsConsonant4(vowel.id, sound(vowel, vowelTop), before(vowel, vowelTop), vowelRival.id,
              name(vowelRival), vowelTop.consonant!)),
          ladder(vowel),
          text(s.firstSoundsConsonant5(sound(vowel, vowelSteps[1]), vowelSteps[1].joining.single)),
          text(s.firstSoundsConsonant6(
              sh.id, sound(sh, SoundLadder.of(sh, poems.all).first), name(poems[FirstSoundsExamples.s]))),
          tobi(s.firstSoundsConsonantTobi, TobiPose.fired),

          ProseChapter(5, s.firstSoundsSwitchTitle, o?.firstSoundsSwitchTitle),
          text(s.firstSoundsSwitch1),
          text(s.firstSoundsSwitch2),
          text(s.firstSoundsSwitch3(card.id)),
          ladder(card, kanaOnly: true),
          text(s.firstSoundsSwitch4),
          tobi(s.firstSoundsTobi, TobiPose.cheering),
        ],
      ),
    );
  }
}
