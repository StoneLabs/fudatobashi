import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/sound_ladder.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A card's sound ladder (see [SoundLadder]) as a staircase going down to
/// the right. Each step: a count badge (sun on the top step, ink on a
/// consonant step), its sound with the part no longer needed faded, a line
/// on when it is enough, and chips for the cards that join on it, folded
/// behind "+N more" when there are many. A chip opens that card with
/// [onOpen].
class SoundLadderView extends StatefulWidget {
  const SoundLadderView({
    super.key,
    required this.poem,
    required this.kanaOnly,
    required this.romaji,
    required this.onOpen,
  });

  final Poem poem;
  final bool kanaOnly;

  /// Sounds in romaji (the kimariji as the app writes it), else in kana.
  final String? romaji;
  final ValueChanged<int> onOpen;

  @override
  State<SoundLadderView> createState() => _SoundLadderViewState();
}

class _SoundLadderViewState extends State<SoundLadderView> {
  /// The steps whose folded chips are open.
  final _unfolded = <int>{};

  @override
  void didUpdateWidget(SoundLadderView old) {
    super.didUpdateWidget(old);
    if (old.kanaOnly != widget.kanaOnly || old.poem.id != widget.poem.id) _unfolded.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = widget.poem;
    final romaji = widget.romaji;
    final steps = SoundLadder.of(poem, poems.all, kanaOnly: widget.kanaOnly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          _Step(
            index: i,
            step: step,
            sound: romaji == null ? SoundLadder.inKana(poem, step) : SoundLadder.inRomaji(poem, romaji, step),
            kana: romaji != null && !step.isConsonant ? poem.kimariji.substring(0, step.kana) : null,
            caption: (sound) => i == 0
                ? s.ladderTop
                : s.ladderStep(step.cards.length, sound, consonant: step.isConsonant),
            unfolded: _unfolded.contains(i),
            onUnfold: () => setState(() => _unfolded.add(i)),
            onOpen: widget.onOpen,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.step,
    required this.sound,
    required this.kana,
    required this.caption,
    required this.unfolded,
    required this.onUnfold,
    required this.onOpen,
  });

  final int index;
  final LadderStep step;
  final LadderSound sound;

  /// The kana of a romaji sound, shown small after it.
  final String? kana;
  final String Function(String sound) caption;
  final bool unfolded;
  final VoidCallback onUnfold;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = index == 0;
    final count = step.cards.length;
    final badge = top ? Palette.sun : (step.isConsonant ? Palette.ink : Palette.paper);
    final badgeText = badge == Palette.ink ? Palette.paper : Palette.ink;
    final joining = step.joining;
    final folded = !unfolded && joining.length > SoundLadderTuning.foldAfter;
    final shown = folded ? joining.take(SoundLadderTuning.foldTo) : joining;
    const soundStyle =
        TextStyle(fontFamily: Fonts.display, fontSize: SoundLadderLayout.soundFont, height: SoundLadderLayout.soundLineHeight);
    final kana = this.kana;
    return Padding(
      padding: EdgeInsets.only(left: index * SoundLadderLayout.indent),
      child: CustomPaint(
        painter: _StepRules(reachBack: top ? 0 : SoundLadderLayout.indent),
        child: Padding(
          padding: SoundLadderLayout.stepPadding +
              const EdgeInsets.only(left: SoundLadderLayout.rule, top: SoundLadderLayout.rule),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: SoundLadderLayout.badge,
              height: SoundLadderLayout.badge,
              padding: const EdgeInsets.all(SoundLadderLayout.badgeBorder),
              decoration: BoxDecoration(
                  color: badge, border: Border.all(color: Palette.ink, width: SoundLadderLayout.badgeBorder)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$count',
                      style: TextStyle(
                          fontFamily: Fonts.display, fontSize: SoundLadderLayout.badgeFont, height: 1, color: badgeText)),
                  const SizedBox(height: SoundLadderLayout.badgeLabelGap),
                  Text(s.ladderCards(count),
                      style: TextStyle(
                          fontWeight: Weights.black,
                          fontSize: SoundLadderLayout.badgeLabelFont,
                          height: 1,
                          letterSpacing: SoundLadderLayout.badgeLabelFont * SoundLadderLayout.badgeLabelTracking,
                          color: badgeText)),
                ]),
              ),
            ),
            const SizedBox(width: SoundLadderLayout.badgeGap),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(style: soundStyle, children: [
                  TextSpan(text: sound.kept),
                  if (sound.faded.isNotEmpty)
                    TextSpan(
                      text: sound.faded,
                      style: TextStyle(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = SoundLadderLayout.fadedStroke
                          ..color = SoundLadderLayout.faded,
                      ),
                    ),
                  if (kana != null) ...[
                    const WidgetSpan(child: SizedBox(width: SoundLadderLayout.kanaGap)),
                    TextSpan(
                      text: kana,
                      style: const TextStyle(
                          fontFamily: Fonts.ui,
                          fontWeight: Weights.bold,
                          fontSize: SoundLadderLayout.kanaFont,
                          color: SoundLadderLayout.kanaColor),
                    ),
                  ],
                ])),
                const SizedBox(height: SoundLadderLayout.captionGap),
                Text.rich(Phrases.span(caption(sound.kept)),
                    style: const TextStyle(
                        fontWeight: Weights.bold,
                        fontSize: SoundLadderLayout.captionFont,
                        height: SoundLadderLayout.captionLineHeight,
                        color: Palette.inkSoft)),
                if (joining.isNotEmpty) ...[
                  const SizedBox(height: SoundLadderLayout.chipsGap),
                  Wrap(
                    spacing: SoundLadderLayout.chipSpacing,
                    runSpacing: SoundLadderLayout.chipSpacing,
                    children: [
                      for (final id in shown) _RivalChip(id: id, onTap: () => onOpen(id)),
                      if (folded) _MoreChip(s.ladderMore(joining.length - SoundLadderTuning.foldTo), onTap: onUnfold),
                    ],
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A step's ink rules: along its top, reaching back over the indent to the
/// step above's rule, and down its left side.
class _StepRules extends CustomPainter {
  const _StepRules({required this.reachBack});

  final double reachBack;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = Palette.ink;
    const rule = SoundLadderLayout.rule;
    canvas.drawRect(Rect.fromLTWH(-reachBack, 0, size.width + reachBack, rule), ink);
    canvas.drawRect(Rect.fromLTWH(0, 0, rule, size.height), ink);
  }

  @override
  bool shouldRepaint(_StepRules old) => old.reachBack != reachBack;
}

/// A card that joins on a step: its kimariji and number; a tap opens it.
class _RivalChip extends StatelessWidget {
  const _RivalChip({required this.id, required this.onTap});

  final int id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: '${kimarijiFor(context, id)} $id',
        builder: (context, pressed) => Container(
          padding: SoundLadderLayout.chipPadding,
          decoration: BoxDecoration(
            color: pressed ? Palette.sunSoft : Palette.paper,
            border: Border.all(color: Palette.ink, width: SoundLadderLayout.chipBorder),
          ),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: kimarijiFor(context, id),
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: SoundLadderLayout.chipFont)),
              const WidgetSpan(child: SizedBox(width: SoundLadderLayout.chipNumberGap)),
              TextSpan(
                  text: '$id',
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: SoundLadderLayout.chipNumberFont,
                      color: SoundLadderLayout.chipNumber)),
            ]),
            style: const TextStyle(height: SoundLadderLayout.chipLineHeight),
          ),
        ),
      );
}

/// The rest of a step's cards, folded: "+N more".
class _MoreChip extends StatelessWidget {
  const _MoreChip(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        builder: (context, pressed) => Container(
          padding: SoundLadderLayout.chipPadding,
          decoration: BoxDecoration(
            color: pressed ? Palette.sunSoft : Palette.desk,
            border: Border.all(color: Palette.ink, width: SoundLadderLayout.chipBorder),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: Weights.black, fontSize: SoundLadderLayout.moreFont, height: SoundLadderLayout.chipLineHeight)),
        ),
      );
}
