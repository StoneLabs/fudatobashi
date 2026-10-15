import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../home/home_screen.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'burst_button.dart';

/// A side trip's entry on the hub: its head ([SideTripHead]) hanging over
/// the top of its panel and buttons ([SideTripBody]).
class SideTripEntryView extends StatelessWidget {
  const SideTripEntryView(this.entry, {super.key, this.onOpen});

  final SideTripEntry entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => _HeadOver(
        head: SideTripHead(entry),
        body: SideTripBody(entry, onOpen: onOpen),
      );
}

/// A side trip's name lettered on the hub with its tag, and once it is open
/// its rank stamp at the right: the head that breaks out over the top of its
/// panel ([SideTripBody]).
class SideTripHead extends StatelessWidget {
  const SideTripHead(this.entry, {super.key});

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: SideTripsLayout.letteringMaxScale,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: _Lettering(S.of(context).tripName(entry.trip), S.of(context).tripTag(entry.trip),
                  fontSize: SideTripsLayout.letteringFont),
            ),
            if (entry.open)
              Padding(
                padding: const EdgeInsets.only(bottom: SideTripsLayout.stampLift),
                child: Transform.translate(
                  offset: const Offset(SideTripsLayout.stampHang, 0),
                  child: _RankStamp(entry.band),
                ),
              ),
          ],
        ),
      );
}

/// A name lettered on the hub, shrinking rather than overflowing, with its
/// [tag] on an ink banner beside it.
class _Lettering extends StatelessWidget {
  const _Lettering(this.text, this.tag, {required this.fontSize});

  final String text, tag;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: SideTripsLayout.headInset, bottom: SideTripsLayout.letteringDrop),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // The island's own node already says its name.
            ExcludeSemantics(
              child: OutlinedText(
                text,
                outlineWidth: SideTripsLayout.letteringOutline,
                style: TextStyle(fontFamily: Fonts.display, fontSize: fontSize, height: TypeScale.displayLineHeight),
              ),
            ),
            const SizedBox(width: SideTripsLayout.letteringGap),
            InkBanner(tag, fontSize: SideTripsLayout.bannerFont),
          ]),
        ),
      );
}

/// The entry of an island still being built: 近日公開 lettered over a small
/// panel saying that it is under construction.
class SideTripSoonEntry extends StatelessWidget {
  const SideTripSoonEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _HeadOver(
      head: MediaQuery.withClampedTextScaling(
        maxScaleFactor: SideTripsLayout.letteringMaxScale,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: _Lettering(s.sideTripsSoonLettering, s.sideTripsSoonBanner,
              fontSize: SideTripsLayout.soonLetteringFont),
        ),
      ),
      body: MangaPanel(
        shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
        padding: const EdgeInsets.only(top: SideTripsLayout.overlap),
        child: Padding(
          padding: SideTripsLayout.soonPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: s.sideTripsSoonTitle,
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.soonTitleFont),
                  ),
                  if (s.sub != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: s.sub!.sideTripsSoonTitle.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: Weights.black,
                        fontSize: SideTripsLayout.subFont,
                        letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
                      ),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: SideTripsLayout.soonLineGap),
              Text(
                s.sideTripsSoonLine,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: SideTripsLayout.soonLineFont),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [head] hanging [SideTripsLayout.overlap] over the top of [body], and
/// painted over it.
class _HeadOver extends MultiChildRenderObjectWidget {
  _HeadOver({required Widget head, required Widget body}) : super(children: [body, head]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeadOver();
}

class _HeadOverParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeadOver extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeadOverParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeadOverParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeadOverParentData) child.parentData = _HeadOverParentData();
  }

  @override
  void performLayout() {
    final body = firstChild!;
    final head = childAfter(body)!;
    final width = BoxConstraints.tightFor(width: constraints.maxWidth);
    head.layout(width, parentUsesSize: true);
    body.layout(width, parentUsesSize: true);
    final top = head.size.height - SideTripsLayout.overlap;
    (body.parentData! as _HeadOverParentData).offset = Offset(0, top);
    size = constraints.constrain(Size(constraints.maxWidth, top + body.size.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// The class stamped on the panel's corner in vermilion on paper, "F上" big
/// and "級" small, inside a double rule.
class _RankStamp extends StatelessWidget {
  const _RankStamp(this.band);

  final RankBand band;

  @override
  Widget build(BuildContext context) => Sticker(
        color: Palette.paper,
        borderColor: Palette.vermilion,
        tilt: SideTripsLayout.stampTilt,
        padding: const EdgeInsets.all(Strokes.control + SideTripsLayout.stampGap),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: Palette.vermilion, width: Strokes.hairline)),
          child: Padding(
            padding: SideTripsLayout.stampPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SideTripsLayout.stampMaxWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: S.of(context).classStem(band)),
                    if (S.of(context).classStem(band) != S.of(context).className(band))
                      const TextSpan(
                          text: RankBand.classSuffix, style: TextStyle(fontSize: SideTripsLayout.stampSuffixFont)),
                  ]),
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: SideTripsLayout.stampFont,
                    height: 1,
                    color: Palette.vermilion,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// A side trip's panel on the hub. Open: its rating with the last game's
/// change and the next ranked game, and the burst that opens the trip's
/// page ([onOpen]), as does the row above it. Locked: the cards remembered
/// so far as pips and a grey bar saying how many more open it, where the
/// burst will be.
class SideTripBody extends StatelessWidget {
  const SideTripBody(this.entry, {super.key, this.onOpen});

  final SideTripEntry entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final lock = entry.lock;
    return MangaPanel(
      shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
      padding: const EdgeInsets.only(top: SideTripsLayout.overlap),
      child: lock == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatsRow(entry, onTap: onOpen),
                Padding(
                  padding: SideTripsLayout.burstMargin,
                  child: PageBurst(onTap: onOpen),
                ),
              ],
            )
          : _LockedRows(lock),
    );
  }
}

/// A row's label, with the same in the other language as its sub-label.
class _Label extends StatelessWidget {
  const _Label(this.text, this.sub);

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (sub != null) ...[
            const TextSpan(text: ' '),
            TextSpan(
              text: sub!.toUpperCase(),
              style: const TextStyle(
                fontSize: SideTripsLayout.subFont,
                letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
              ),
            ),
          ],
        ]),
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
            fontWeight: Weights.black, fontSize: SideTripsLayout.labelFont, height: SideTripsLayout.labelLineHeight),
      );
}

/// A [label] over its [value], both shrinking rather than overflowing.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final Widget label, value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: label),
          const SizedBox(height: SideTripsLayout.labelGap),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
        ],
      );
}

/// The ranked rating and its last change (or "unranked"), and the next
/// ranked game: its level, cards a side and memorise time; a tap opens the
/// trip's page ([onTap]).
class _StatsRow extends StatelessWidget {
  const _StatsRow(this.entry, {required this.onTap});

  final SideTripEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = entry.rating;
    final change = entry.ratingChange?.round() ?? 0;
    final level = entry.rankedLevel;
    const value = TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.valueFont, height: 1);
    return Pressable(
      onTap: onTap,
      scale: Press.panelScale,
      turn: 0,
      semanticLabel: s.ankirenOpenPage,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SideTripsLayout.rowMinHeight),
        child: Padding(
          padding: SideTripsLayout.rowPadding,
          child: Row(children: [
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: SideTripsLayout.ratingFlex,
                      child: _Stat(
                        label: _Label(s.rating, s.sub?.rating),
                        value: rating == null
                            ? Text(s.sideTripUnranked,
                                style: const TextStyle(
                                    fontFamily: Fonts.display, fontSize: SideTripsLayout.unrankedFont, height: 1))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('${rating.round()}', style: value),
                                if (change != 0) ...[
                                  const SizedBox(width: SideTripsLayout.valueGap),
                                  RatingChangeTag(change),
                                ],
                              ]),
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(width: SideTripsLayout.rowGap),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: SideTripsLayout.ruleInset),
                        child: SizedBox(width: SideTripsLayout.ruleWidth, child: ColoredBox(color: Palette.ink)),
                      ),
                      const SizedBox(width: SideTripsLayout.rowGap),
                      Flexible(
                        flex: SideTripsLayout.nextFlex,
                        child: _Stat(
                          label: _Label(s.sideTripNextGame, s.sub?.sideTripNextGame),
                          value: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(s.ankirenLevelTag(level), style: value),
                              const SizedBox(width: SideTripsLayout.valueGap),
                              NumberedText(
                                s.sideTripNextFacts,
                                [AnkirenLevels.of(level).perSide, formatMinutes(AnkirenLevels.of(level).memorise)],
                                style: const TextStyle(fontWeight: Weights.black, fontSize: SideTripsLayout.factsFont),
                                numberStyle:
                                    const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.factsNumber),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A ranked game's change to the rating: ▲ on ink, ▼ on paper (± when
/// none), at the hub's size unless given another.
class RatingChangeTag extends StatelessWidget {
  const RatingChangeTag(
    this.change, {
    super.key,
    this.fontSize = SideTripsLayout.deltaFont,
    this.padding = SideTripsLayout.deltaPadding,
    this.border = Strokes.label,
  });

  final int change;
  final double fontSize;
  final EdgeInsets padding;
  final double border;

  @override
  Widget build(BuildContext context) {
    final up = change > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: up ? Palette.ink : Palette.paper,
        border: up ? null : Border.all(color: Palette.ink, width: border),
      ),
      child: Padding(
        padding: padding,
        child: Text(
          '${up ? '▲' : change < 0 ? '▼' : '±'}${change.abs()}',
          semanticsLabel: up ? '+$change' : '$change',
          style: TextStyle(
            fontFamily: Fonts.display,
            fontSize: fontSize,
            height: 1,
            color: up ? Palette.paper : Palette.ink,
          ),
        ),
      ),
    );
  }
}

/// The ranked shout ([BurstButton]).
class RankedBurst extends StatelessWidget {
  const RankedBurst({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BurstButton(title: s.sideTripRanked, sub: s.sub?.sideTripRanked.toUpperCase(), onTap: onTap);
  }
}

/// The shout that opens the trip's page, where its games start
/// ([BurstButton]); grey while there is nowhere to go.
class PageBurst extends StatelessWidget {
  const PageBurst({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BurstButton(title: s.ankirenPageTitle, sub: s.sub?.ankirenPageTitle.toUpperCase(), onTap: onTap);
  }
}

/// A locked trip: the cards remembered well so far out of what opens it, as
/// a count and as rows of pips, and the bar where its ranked burst will be.
class _LockedRows extends StatelessWidget {
  const _LockedRows(this.lock);

  final SideTripLock lock;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SideTripsLayout.lockedRowMinHeight),
          child: Padding(
            padding: SideTripsLayout.rowPadding,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Stat(
                label: _Label(s.sideTripRemembered, s.sub?.sideTripRemembered),
                value: NumberedText(
                  s.sideTripRememberedCount,
                  [lock.remembered, lock.opensAt],
                  style: const TextStyle(fontWeight: Weights.black, fontSize: SideTripsLayout.factsFont),
                  numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.valueFont),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: SideTripsLayout.pipsPadding,
          child: Column(children: [
            for (var row = 0; row < lock.opensAt; row += SideTripsLayout.pipsPerRow) ...[
              if (row > 0) const SizedBox(height: SideTripsLayout.pipRowGap),
              CardPips(
                [
                  for (var i = row; i < math.min(row + SideTripsLayout.pipsPerRow, lock.opensAt); i++)
                    i < lock.remembered ? PipState.learned : PipState.locked,
                ],
                gap: SideTripsLayout.pipGap,
                aspect: SideTripsLayout.pipAspect,
              ),
            ],
          ]),
        ),
        const SizedBox(height: SideTripsLayout.lockTop),
        _LockBar(lock),
      ],
    );
  }
}

/// Where the ranked burst will be: a padlock, ranked, and how many more
/// cards open it; a tap says what to do.
class _LockBar extends StatelessWidget {
  const _LockBar(this.lock);

  final SideTripLock lock;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Pressable(
      onTap: () => BalloonPop.show(context, s.sideTripLockedWhy(lock.needed),
          size: SideTripsLayout.lockBalloon, life: SideTripsLayout.lockBalloonLife),
      scale: 1,
      turn: 0,
      semanticLabel: '${s.sideTripRanked} ${s.sideTripLockedSub(lock.needed)}',
      builder: (context, _) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.desk,
          border: Border(top: BorderSide(color: Palette.ink, width: Strokes.control)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SideTripsLayout.lockMinHeight),
          child: Padding(
            padding: SideTripsLayout.lockPadding,
            child: Row(children: [
              MangaIcon(IconArt.lock, size: SideTripsLayout.lockIcon, strokeWidth: SideTripsLayout.lockIconStroke),
              const SizedBox(width: SideTripsLayout.lockGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                          text: s.sideTripRanked,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.lockTitleFont),
                        ),
                        if (s.sub != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: s.sub!.sideTripRanked.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: Weights.black,
                              fontSize: SideTripsLayout.subFont,
                              letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
                            ),
                          ),
                        ],
                      ])),
                    ),
                    NumberedText(
                      s.sideTripLandIn(lock.needed),
                      [lock.needed],
                      style: const TextStyle(fontWeight: Weights.black, fontSize: SideTripsLayout.lockLineFont),
                      numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.lockLineNumber),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Free play, in Home's button style, saying the levels it offers.
class SideTripFreeButton extends StatelessWidget {
  const SideTripFreeButton(this.entry, {super.key, required this.onTap});

  final SideTripEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final maxLevel = entry.maxLevel;
    return HomeRowButton(
      icon: IconArt.cards,
      title: s.freePlay,
      badge: s.sub == null ? null : _Sub(s.sub!.freePlay),
      sub: maxLevel == null ? s.sideTripFreeSub : s.sideTripFreeUpTo(maxLevel),
      onTap: onTap,
    );
  }
}

/// The rules (遊び方), in Home's button style.
class SideTripRulesButton extends StatelessWidget {
  const SideTripRulesButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return HomeRowButton(icon: IconArt.help, title: s.howToPlay, sub: s.sub?.howToPlay.toUpperCase(), onTap: onTap);
  }
}

/// A button title's other-language sub-label, in small tracked capitals.
class _Sub extends StatelessWidget {
  const _Sub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        maxLines: 1,
        style: const TextStyle(
          fontWeight: Weights.black,
          fontSize: SideTripsLayout.subFont,
          letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
        ),
      );
}
