import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../l10n/card_explanations.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/romaji.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';
import '../stats/card_detail_screen.dart';
import '../torifuda/torifuda_painter.dart';
import 'card_panel.dart';
import 'first_sounds_screen.dart';
import 'page_frame.dart';
import 'sound_ladder_view.dart';

/// Everything about one card, from the card browser, the new-card page and
/// the card's stats page: both cards to swipe between, the kimariji, the
/// poem, the card's facts, its sound ladder and look-alike torifuda; then,
/// under "About the poem", its explanation; then its stats and the cards
/// before and after it. Section markers take the card's colour group.
class AboutCardScreen extends StatefulWidget {
  const AboutCardScreen({super.key, required this.poemId});

  final int poemId;

  @override
  State<AboutCardScreen> createState() => _AboutCardScreenState();
}

class _AboutCardScreenState extends State<AboutCardScreen> {
  CardFace _front = CardFace.taking;
  Future<String>? _explanation;
  String? _explanationCode;

  Poem get _poem => poems[widget.poemId];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = S.of(context).code;
    if (code != _explanationCode) {
      _explanationCode = code;
      _explanation = CardExplanations.load(code, widget.poemId);
    }
  }

  void _swap(CardFace face) {
    setState(() => _front = face);
    final progress = ProgressScope.read(context);
    if (!progress.settings.cardPanelSwiped) progress.updateSettings(progress.settings.copyWith(cardPanelSwiped: true));
  }

  void _open(Widget page) => Navigator.of(context).push(MangaRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    final poem = _poem;
    final group = CardColorGroups.of(poem.color);
    final settings = ProgressScope.of(context).settings;
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    final lookAlikes = fudaSets.tomofuda(poem.id);
    void openCard(int id) => _open(AboutCardScreen(poemId: id));
    Widget heading(String title, String? sub) => Padding(
          padding: const EdgeInsets.only(bottom: AboutCardLayout.headingGap),
          child: MarkerHeading(title, sub, color: group),
        );
    return PageFrame(
      title: s.aboutCardTitle,
      body: SingleChildScrollView(
        padding: PageFrame.padding.copyWith(bottom: AboutCardLayout.bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardPanel(poem: poem, front: _front, onSwap: _swap, sticker: !settings.cardPanelSwiped),
            const SizedBox(height: AboutCardLayout.switchGap),
            PillSwitch<CardFace>(
              choices: [
                (value: CardFace.taking, label: s.aboutTakingCard, sub: s.ja ? null : s.other.aboutTakingCard),
                (value: CardFace.reading, label: s.aboutReadingCard, sub: s.ja ? null : s.other.aboutReadingCard),
              ],
              selected: _front,
              onChanged: (face) => setState(() => _front = face),
              height: AboutCardLayout.switchHeight,
              border: AboutCardLayout.switchBorder,
              fontSize: AboutCardLayout.switchFont,
              subFontSize: AboutCardLayout.switchSubFont,
              padding: AboutCardLayout.switchPadding,
              expand: true,
            ),
            AnimatedSize(
              duration: Motion.tab,
              alignment: Alignment.topCenter,
              child: _front == CardFace.reading
                  ? Padding(
                      padding: const EdgeInsets.only(top: AboutCardLayout.keyGap),
                      child: ReadingCardKey(poem: poem),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: AboutCardLayout.kimarijiGap),
            _Kimariji(poem: poem, romaji: romaji),
            const SizedBox(height: AboutCardLayout.sectionGap),
            heading(s.aboutPoem, o?.aboutPoem),
            _PoemBox(poem: poem, romaji: romaji),
            const SizedBox(height: AboutCardLayout.sectionGap),
            heading(s.aboutFacts, o?.aboutFacts),
            _Facts(poem: poem),
            const SizedBox(height: AboutCardLayout.sectionGap),
            heading(s.aboutSimilar, o?.aboutSimilar),
            _LadderBar(
              mode: settings.soundLadder,
              onExplain: () => _open(const FirstSoundsScreen()),
              onMode: (mode) {
                final progress = ProgressScope.read(context);
                progress.updateSettings(progress.settings.copyWith(soundLadder: mode));
              },
            ),
            const SizedBox(height: AboutCardLayout.barGap),
            Text.rich(
              Phrases.span(settings.soundLadder == SoundLadderMode.kana ? s.aboutLadderLeadKana : s.aboutLadderLead),
              style: const TextStyle(
                  fontWeight: Weights.medium,
                  fontSize: AboutCardLayout.leadFont,
                  height: AboutCardLayout.leadLineHeight,
                  color: Palette.inkSoft),
            ),
            const SizedBox(height: AboutCardLayout.leadGap),
            SoundLadderView(
              poem: poem,
              kanaOnly: settings.soundLadder == SoundLadderMode.kana,
              romaji: romaji ? (s.ja ? s.other : s).kimariji(poem.id) : null,
              onOpen: openCard,
            ),
            if (lookAlikes.isNotEmpty) ...[
              const SizedBox(height: AboutCardLayout.lookAlikeLabelGap),
              Text(s.aboutConfused,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: AboutCardLayout.lookAlikeLabelFont,
                      letterSpacing: AboutCardLayout.lookAlikeLabelFont * TagStyle.tracking,
                      color: Palette.inkSoft)),
              const SizedBox(height: AboutCardLayout.lookAlikeLabelBottom),
              _LookAlikes(ids: lookAlikes, romaji: romaji, onOpen: openCard),
            ],
            const SizedBox(height: AboutCardLayout.partGap),
            _PartHeading(s.aboutPoemPart, o?.aboutPoemPart),
            const SizedBox(height: AboutCardLayout.partBottomGap),
            FutureBuilder<String>(
              future: _explanation,
              builder: (context, snapshot) => switch (snapshot.data) {
                final source? => MarkdownProse(source, accent: group),
                null => const SizedBox.shrink(),
              },
            ),
            const SizedBox(height: AboutCardLayout.linkRowGap),
            LinkRow(
              title: s.aboutMyRecord,
              note: s.aboutMyRecordNote,
              onTap: () => _open(CardDetailScreen(itemKey: ItemKey(poem.id, false))),
            ),
            const SizedBox(height: AboutCardLayout.neighbourGap),
            _Neighbours(poem: poem),
          ],
        ),
      ),
    );
  }
}

/// The kimariji, big and pink in an ink outline, shrinking rather than
/// wrapping; the speaker after it and the card's number at the right; how
/// many sounds it is under it (after its kana, in romaji).
class _Kimariji extends StatelessWidget {
  const _Kimariji({required this.poem, required this.romaji});

  final Poem poem;
  final bool romaji;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sounds = s.aboutSounds(poem.kimariji.length);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Row(children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: OutlinedText(
                  kimarijiFor(context, poem.id),
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: AboutCardLayout.kimarijiFont,
                      height: AboutCardLayout.kimarijiLineHeight,
                      color: Palette.pink),
                  outline: Palette.ink,
                  outlineWidth: AboutCardLayout.kimarijiOutline,
                ),
              ),
            ),
            const SizedBox(width: AboutCardLayout.numberGap),
            KimarijiSpeakerButton(poemId: poem.id),
          ]),
        ),
        const SizedBox(width: AboutCardLayout.numberGap),
        DecoratedBox(
          decoration: const BoxDecoration(color: Palette.ink),
          child: Padding(
            padding: AboutCardLayout.numberPadding,
            child: Text('#${poem.id}',
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: AboutCardLayout.numberFont,
                    height: AboutCardLayout.numberLineHeight,
                    color: Palette.paper)),
          ),
        ),
      ]),
      const SizedBox(height: AboutCardLayout.soundsGap),
      Text(romaji ? '${poem.kimariji} · $sounds' : sounds,
          style: const TextStyle(fontWeight: Weights.bold, fontSize: AboutCardLayout.soundsFont)),
    ]);
  }
}

/// The poem on a desk panel: its halves under their tags, the kimariji in
/// pink, the poet at the end. A switch shows it in kana with furigana or
/// in romaji, starting from the player's kimariji script.
class _PoemBox extends StatefulWidget {
  const _PoemBox({required this.poem, required this.romaji});

  final Poem poem;
  final bool romaji;

  @override
  State<_PoemBox> createState() => _PoemBoxState();
}

class _PoemBoxState extends State<_PoemBox> {
  late bool _romaji = widget.romaji;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = widget.poem;
    final verses = _romaji ? _romajiVerses(poem) : null;
    Widget lines(int from, int to) => Padding(
          padding: AboutCardLayout.linesPadding,
          child: verses != null
              ? Wrap(
                  spacing: MediaQuery.textScalerOf(context).scale(AboutCardLayout.romajiFont) *
                      AboutCardLayout.romajiVerseGap,
                  runSpacing: AboutCardLayout.verseRunGap,
                  children: verses.sublist(from, to),
                )
              : RubyText(
                  from == 0 ? poem.kamiRuby : poem.shimoRuby,
                  style: const TextStyle(
                      fontWeight: Weights.bold,
                      fontSize: AboutCardLayout.poemFont,
                      height: AboutCardLayout.poemLineHeight,
                      color: Palette.ink),
                  highlight: from == 0 ? (kana: poem.kimariji.length, color: AboutCardLayout.kimariji) : null,
                  phraseGap: AboutCardLayout.verseGap,
                  lineGap: AboutCardLayout.verseRunGap,
                ),
        );
    return MangaPanel(
      color: Palette.desk,
      shadow: const Offset(AboutCardLayout.panelShadow, AboutCardLayout.panelShadow),
      padding: AboutCardLayout.poemPadding + const EdgeInsets.all(Strokes.panel),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          InkTag(s.aboutFirstHalf),
          const Spacer(),
          PillSwitch<bool>(
            choices: [(value: false, label: s.aboutKana, sub: null), (value: true, label: s.aboutRomaji, sub: null)],
            selected: _romaji,
            onChanged: (v) => setState(() => _romaji = v),
            height: AboutCardLayout.pillHeight,
            border: AboutCardLayout.pillBorder,
            fontSize: AboutCardLayout.pillFont,
            padding: AboutCardLayout.pillPadding,
          ),
        ]),
        lines(0, 3),
        Align(alignment: Alignment.centerLeft, child: InkTag(s.aboutSecondHalf, color: Palette.pink)),
        lines(3, 5),
        Align(
          alignment: Alignment.centerRight,
          child: _romaji
              ? Text(poem.authorRomaji,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: AboutCardLayout.romajiPoetFont))
              : RubyText(poem.authorRuby,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: AboutCardLayout.poetFont)),
        ),
      ]),
    );
  }

  /// The five verses in romaji, the kimariji's letters in pink.
  static List<Widget> _romajiVerses(Poem poem) {
    const style = TextStyle(
        fontWeight: Weights.bold,
        fontSize: AboutCardLayout.romajiFont,
        height: AboutCardLayout.romajiLineHeight,
        color: Palette.ink);
    var left = hepburn(poem.kimarijiReading).length;
    final verses = <Widget>[];
    for (final verse in poem.versesRomaji) {
      final cut = left.clamp(0, verse.length);
      left -= cut;
      verses.add(Text.rich(TextSpan(style: style, children: [
        if (cut > 0) TextSpan(text: verse.substring(0, cut), style: const TextStyle(color: AboutCardLayout.kimariji)),
        TextSpan(text: verse.substring(cut)),
      ])));
    }
    return verses;
  }
}

/// The card's facts in an ink-ruled table: the poet, the taking card's
/// kimariji and its 五色 colour group.
class _Facts extends StatelessWidget {
  const _Facts({required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const value = TextStyle(
        fontWeight: Weights.bold, fontSize: AboutCardLayout.factFont, height: AboutCardLayout.factLineHeight);
    final group = CardColorGroups.of(poem.color);
    final groupSize = poems.all.where((p) => p.color == poem.color).length;
    final rows = [
      (
        s.aboutPoet,
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AboutCardLayout.poetRomajiGap,
          children: [
            RubyText(poem.authorRuby, style: value),
            if (!s.ja) Text(poem.authorRomaji, style: value.copyWith(color: AboutCardLayout.mutedText)),
          ],
        ),
      ),
      (s.aboutTakingKimariji, Text(poem.kimarijiShimo, style: value)),
      (
        s.aboutColourGroup,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: AboutCardLayout.chip,
                height: AboutCardLayout.chip,
                margin: const EdgeInsets.only(right: AboutCardLayout.chipGap),
                decoration: BoxDecoration(
                    color: group, border: Border.all(color: Palette.ink, width: AboutCardLayout.chipBorder)),
              ),
            ),
            Phrases.span(s.aboutColourName(poem.color)),
          ]), style: value),
          Text.rich(Phrases.span(s.aboutColourPlace(poem.colorNumber, groupSize)), style: value),
        ]),
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: AboutCardLayout.factsBorder)),
      child: Padding(
        padding: const EdgeInsets.all(AboutCardLayout.factsBorder),
        child: Column(children: [
          for (final (i, (label, child)) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: AboutCardLayout.factsRule, width: double.infinity, child: ColoredBox(color: Palette.ink)),
            Padding(
              padding: AboutCardLayout.factPadding,
              child: Row(children: [
                SizedBox(
                  width: AboutCardLayout.factLabelColumn,
                  child: Text.rich(Phrases.span(label),
                      style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: AboutCardLayout.factLabelFont,
                          height: AboutCardLayout.factLabelLineHeight,
                          letterSpacing: AboutCardLayout.factLabelFont * TagStyle.tracking,
                          color: Palette.inkSoft)),
                ),
                const SizedBox(width: AboutCardLayout.factLabelGap),
                Expanded(child: child),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

/// The row under the ladder's heading: the link to how first sounds work,
/// and the switch between the ladder of sounds and of whole kana.
class _LadderBar extends StatelessWidget {
  const _LadderBar({required this.mode, required this.onExplain, required this.onMode});

  final SoundLadderMode mode;
  final VoidCallback onExplain;
  final ValueChanged<SoundLadderMode> onMode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Pressable(
          onTap: onExplain,
          scale: 1,
          turn: 0,
          builder: (context, _) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ButtonMetrics.iconButton),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Palette.ink, width: AboutCardLayout.linkRule))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MangaIcon(IconArt.arrow, size: AboutCardLayout.linkIcon, strokeWidth: AboutCardLayout.linkIconStroke),
                  const SizedBox(width: AboutCardLayout.linkIconGap),
                  Flexible(
                    child: Text(s.aboutReadExplanation,
                        style: const TextStyle(fontWeight: Weights.black, fontSize: AboutCardLayout.linkFont)),
                  ),
                ]),
              ),
            ),
          ),
        ),
        ),
      ),
      const SizedBox(width: AboutCardLayout.barGap),
      PillSwitch<SoundLadderMode>(
        choices: [
          (value: SoundLadderMode.sounds, label: s.aboutLadderSounds, sub: null),
          (value: SoundLadderMode.kana, label: s.aboutLadderKana, sub: null),
        ],
        selected: mode,
        onChanged: onMode,
        height: AboutCardLayout.pillHeight,
        border: AboutCardLayout.pillBorder,
        fontSize: AboutCardLayout.pillFont,
        padding: AboutCardLayout.pillPadding,
      ),
    ]);
  }
}

/// The torifuda this card is easily confused with, two to a row: each a
/// small card, its kimariji and number; a tap opens it.
class _LookAlikes extends StatelessWidget {
  const _LookAlikes({required this.ids, required this.romaji, required this.onOpen});

  final List<int> ids;
  final bool romaji;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final romajiOf = (s.ja ? s.other : s).kimariji;
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - AboutCardLayout.lookAlikeGap) / 2;
      return Wrap(
        spacing: AboutCardLayout.lookAlikeGap,
        runSpacing: AboutCardLayout.lookAlikeGap,
        children: [
          for (final id in ids)
            SizedBox(
              width: width,
              child: Pressable(
                onTap: () => onOpen(id),
                semanticLabel: '${poems[id].kimariji} #$id',
                builder: (context, pressed) => Container(
                  padding: AboutCardLayout.lookAlikePadding + const EdgeInsets.all(AboutCardLayout.lookAlikeBorder),
                  decoration: BoxDecoration(
                    color: pressed ? Palette.sunSoft : Palette.paper,
                    border: Border.all(color: Palette.ink, width: AboutCardLayout.lookAlikeBorder),
                  ),
                  child: Row(children: [
                    SizedBox(width: AboutCardLayout.lookAlikeCard, child: TorifudaCard(poem: poems[id])),
                    const SizedBox(width: AboutCardLayout.lookAlikeCardGap),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(poems[id].kimariji,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontFamily: Fonts.display,
                                  fontSize: AboutCardLayout.lookAlikeFont,
                                  height: AboutCardLayout.lookAlikeLineHeight)),
                        ),
                        Text(romaji ? '#$id · ${romajiOf(id)}' : '#$id',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: Weights.bold,
                                fontSize: AboutCardLayout.lookAlikeSubFont,
                                color: AboutCardLayout.lookAlikeSubColor)),
                      ]),
                    ),
                    MangaIcon(IconArt.chevron, size: AboutCardLayout.lookAlikeChevron),
                  ]),
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// A heading that starts a part of the page, a size up from the section
/// markers, over a heavy rule.
class _PartHeading extends StatelessWidget {
  const _PartHeading(this.title, this.sub);

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Container(
          padding: const EdgeInsets.only(top: AboutCardLayout.partRuleGap),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.ink, width: AboutCardLayout.partRule))),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: title,
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: AboutCardLayout.partFont, height: AboutCardLayout.partLineHeight)),
            if (sub case final sub?)
              TextSpan(
                  text: '  $sub',
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AboutCardLayout.partSubFont)),
          ])),
        ),
      );
}

/// The cards before and after this one, wrapping from 1 to 100; each
/// replaces this page.
class _Neighbours extends StatelessWidget {
  const _Neighbours({required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final count = poems.all.length;
    final previous = (poem.id + count - 2) % count + 1;
    final next = poem.id % count + 1;
    Widget button(int id, String label, {required bool forward}) {
      final text = Column(
        crossAxisAlignment: forward ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: AboutCardLayout.neighbourLabelFont,
                  letterSpacing: AboutCardLayout.neighbourLabelFont * AboutCardLayout.neighbourLabelTracking,
                  color: AboutCardLayout.neighbourLabelColor)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$id ${kimarijiFor(context, id)}',
                maxLines: 1, style: const TextStyle(fontFamily: Fonts.display, fontSize: AboutCardLayout.neighbourFont)),
          ),
        ],
      );
      final chevron =
          MangaIcon(forward ? IconArt.chevron : IconArt.back, size: AboutCardLayout.neighbourChevron);
      return InkButton(
        onTap: () => Navigator.of(context).pushReplacement(MangaRoute<void>(builder: (_) => AboutCardScreen(poemId: id))),
        padding: AboutCardLayout.neighbourPadding + const EdgeInsets.all(Strokes.button),
        semanticLabel: '$label $id',
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight:
                  AboutCardLayout.neighbourHeight - AboutCardLayout.neighbourPadding.vertical - 2 * Strokes.button),
          child: Row(children: [
            if (!forward) ...[chevron, const SizedBox(width: AboutCardLayout.neighbourChevronGap)],
            Expanded(child: text),
            if (forward) ...[const SizedBox(width: AboutCardLayout.neighbourChevronGap), chevron],
          ]),
        ),
      );
    }

    return Row(children: [
      Expanded(child: button(previous, s.aboutPrevious, forward: false)),
      const SizedBox(width: AboutCardLayout.neighbourGap),
      Expanded(child: button(next, s.aboutNext, forward: true)),
    ]);
  }
}
