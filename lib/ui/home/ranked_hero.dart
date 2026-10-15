import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';

/// All-known Home's ランク戦 hero, in the slot journey Home gives 修行: its
/// lettering and tag (ランク戦 under the RANKED tag in Japanese; in English
/// RANKED, with ランク戦 as the tag under it), what a ranked run is, where
/// the rating stands (or that the first run sets it), the START RANKED
/// shout, and Tobi fired up at the top right.
class RankedHero extends StatelessWidget {
  const RankedHero({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const padding = RankedHeroLayout.padding;
    return LayoutBuilder(builder: (context, box) {
      // A short panel (a small phone, large text) takes journey Home's
      // smaller shout, leaving room for the chips.
      final compact = box.maxHeight < RankedHeroLayout.compactBelow;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: MangaPanel(
              shape: const PanelShape(bottomRight: Offset(0, HomeLayout.heroCut)),
              color: Palette.pinkSoft,
              art: const [ToneLayer(Tones.pink, fadeAngle: Backdrops.heroToneAngle, fadeStops: Backdrops.heroToneStops)],
              padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: padding.left, right: padding.right),
                      child: CustomMultiChildLayout(
                        delegate: _PitchLayout(tagBelow: !s.ja),
                        children: [
                          LayoutId(
                            id: _Part.tag,
                            child: InkTag(s.ja ? s.rankedTag : RankedHeroLayout.title, color: Palette.pink),
                          ),
                          LayoutId(
                            id: _Part.title,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: OutlinedText(
                                s.ja ? RankedHeroLayout.title : s.rankedTag,
                                outlineWidth: RankedHeroLayout.titleOutline,
                                style: const TextStyle(
                                    fontFamily: Fonts.display,
                                    fontSize: RankedHeroLayout.titleFont,
                                    height: TypeScale.displayLineHeight),
                              ),
                            ),
                          ),
                          LayoutId(
                            id: _Part.chips,
                            child: _Chips([
                              HomeChip(s.rankedChipAll),
                              HomeChip(s.rankedChipMixed),
                              HomeChip(s.rankedChipNoMask),
                              HomeChip(s.rankedChipCounts, color: Palette.sun),
                            ]),
                          ),
                          LayoutId(id: _Part.line, child: const _RatingLine()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: RankedHeroLayout.shoutGap),
                  Padding(
                    padding: const EdgeInsets.only(left: HomeLayout.heroShoutLeft, right: HomeLayout.heroShoutRight),
                    child: SizedBox(
                      height: compact ? HomeLayout.journeyShoutHeight : HomeLayout.heroShoutHeight,
                      child: ShoutButton(
                        label: s.shoutRanked,
                        spec: compact ? HomeLayout.journeyShout : HomeLayout.heroShout,
                        onTap: () => startRanked(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Placed(RankedHeroLayout.tobi, child: Tobi(pose: TobiPose.fired)),
          Placed(
            RankedHeroLayout.balloon,
            child: SpeechBalloon(
              speaker: RankedHeroLayout.balloonSpeaker,
              child: Text(s.letsGo, style: const TextStyle(fontSize: RankedHeroLayout.balloonFont)),
            ),
          ),
        ],
      );
    });
  }
}

/// The chips one under another when there is room for that, else flowing
/// side by side and scaled down to fit, or left out with no room for two
/// rows of them.
class _Chips extends StatelessWidget {
  const _Chips(this.chips);
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final line = MediaQuery.textScalerOf(context).scale(RankedHeroLayout.chipFont) * PillStyle.lineHeight;
    final chipHeight = line + PillStyle.padding.vertical + Strokes.label * 2;
    final stacked = chips.length * chipHeight + (chips.length - 1) * RankedHeroLayout.chipGap;
    return LayoutBuilder(builder: (context, box) {
      if (box.maxHeight < chipHeight * 2 + RankedHeroLayout.chipGap) return const SizedBox.shrink();
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: box.maxWidth,
          child: stacked <= box.maxHeight
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, chip) in chips.indexed) ...[
                      if (i > 0) const SizedBox(height: RankedHeroLayout.chipGap),
                      chip,
                    ],
                  ],
                )
              : Wrap(spacing: RankedHeroLayout.chipGap, runSpacing: RankedHeroLayout.chipGap, children: chips),
        ),
      );
    });
  }
}

enum _Part { tag, title, chips, line }

/// The hero above its shout: the tag and the lettering (the tag over it,
/// or under it with [tagBelow]), the chips under them, and the rating line
/// at the foot, with any room to spare above the line. Short of room, the
/// lettering shrinks first, kept clear of Tobi, then the chips down to
/// [RankedHeroLayout.titleMin] of it.
class _PitchLayout extends MultiChildLayoutDelegate {
  _PitchLayout({required this.tagBelow});

  final bool tagBelow;

  @override
  void performLayout(Size size) {
    final wide = BoxConstraints(maxWidth: size.width);
    final tag = layoutChild(_Part.tag, wide);
    final line = layoutChild(_Part.line, wide);
    final room = math.max(0.0,
        size.height - tag.height - line.height - RankedHeroLayout.tagGap - RankedHeroLayout.titleGap - RankedHeroLayout.lineGap);
    final chips = layoutChild(_Part.chips, wide.copyWith(maxHeight: math.max(0.0, room - RankedHeroLayout.titleMin)));
    final title = layoutChild(
      _Part.title,
      BoxConstraints(
          maxWidth: math.max(0.0, size.width - RankedHeroLayout.titleRight), maxHeight: math.max(0.0, room - chips.height)),
    );
    final head = tag.height + RankedHeroLayout.tagGap;
    final titleTop = tagBelow ? 0.0 : head;
    positionChild(_Part.title, Offset(0, titleTop));
    positionChild(_Part.tag, Offset(0, tagBelow ? title.height + RankedHeroLayout.tagGap : 0));
    positionChild(_Part.chips, Offset(0, titleTop + title.height + (tagBelow ? head : 0) + RankedHeroLayout.titleGap));
    positionChild(_Part.line, Offset(0, size.height - line.height));
  }

  @override
  bool shouldRelayout(_PitchLayout oldDelegate) => oldDelegate.tagBelow != tagBelow;
}

/// Where the rating stands and how far the next class is; before the first
/// ranked run, that it sets the rank.
class _RatingLine extends StatelessWidget {
  const _RatingLine();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = ProgressScope.of(context).rating;
    const style = TextStyle(fontSize: RankedHeroLayout.lineFont, fontWeight: Weights.bold);
    const numbers = TextStyle(fontWeight: Weights.black);
    final next = rating == null ? null : Rating.nextBand(rating);
    final Widget line = rating == null
        ? Text(s.rankedUnplacedLine, style: style.copyWith(fontWeight: Weights.black))
        : next == null
            ? NumberedText(s.rankedRatingTop, [rating.round()], style: style, numberStyle: numbers)
            : NumberedText(s.rankedRatingLine(next.label), [rating.round(), (next.minRating - rating).ceil()],
                style: style, numberStyle: numbers);
    return Center(child: FittedBox(fit: BoxFit.scaleDown, child: line));
  }
}

/// A small bordered label: what a ranked run is on the ランク戦 hero, and
/// "doesn't change rank" on the practice panels. Long text wraps.
class HomeChip extends StatelessWidget {
  const HomeChip(this.text, {super.key, this.color = Palette.paper});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: color, border: Border.all(color: Palette.ink, width: Strokes.label)),
        child: Padding(
          padding: PillStyle.padding,
          child: Text(
            text,
            style: const TextStyle(
                fontWeight: Weights.black, fontSize: RankedHeroLayout.chipFont, height: PillStyle.lineHeight),
          ),
        ),
      );
}

/// The class sticker before the first ranked run: blank, with a question
/// mark where the class goes.
class UnrankedSticker extends StatelessWidget {
  const UnrankedSticker({super.key});

  @override
  Widget build(BuildContext context) => const Sticker(
        color: UnrankedStyle.sticker,
        child: Text(UnrankedStyle.mark,
            style: TextStyle(fontFamily: Fonts.display, fontSize: HomeLayout.classFont, height: 1)),
      );
}
