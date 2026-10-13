import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/rating.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../home/home_screen.dart';
import '../home/home_widgets.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';

/// A side trip's name lettered on the hub with its tag, and once it is open
/// its rank flag at the right: the head that breaks out over the top of its
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
              child: Padding(
                padding: const EdgeInsets.only(left: SideTripsLayout.headInset, bottom: SideTripsLayout.letteringDrop),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedText(
                      entry.trip.label,
                      outlineWidth: SideTripsLayout.letteringOutline,
                      style: const TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: SideTripsLayout.letteringFont,
                          height: TypeScale.displayLineHeight),
                    ),
                    const SizedBox(width: SideTripsLayout.letteringGap),
                    InkBanner(S.of(context).tripTag(entry.trip), fontSize: SideTripsLayout.bannerFont),
                  ]),
                ),
              ),
            ),
            if (entry.open)
              Padding(
                padding: const EdgeInsets.only(right: SideTripsLayout.flagRight, bottom: SideTripsLayout.flagDrop),
                child: _RankFlag(entry.band),
              ),
          ],
        ),
      );
}

/// The rank flag planted on the panel's edge, its cloth lettered with the
/// class: "F上" big, "級" small.
class _RankFlag extends StatelessWidget {
  const _RankFlag(this.band);

  final RankBand band;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: SideTripsLayout.flagSize,
        child: Stack(children: [
          Positioned.fill(
            child: Image.asset(
              SideTripsLayout.flag,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fromRect(
            rect: SideTripsLayout.flagText,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: band.stem),
                  if (band.stem != band.label)
                    const TextSpan(
                        text: RankBand.classSuffix, style: TextStyle(fontSize: SideTripsLayout.flagSuffixFont)),
                ]),
                style: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.flagFont, height: 1),
              ),
            ),
          ),
        ]),
      );
}

/// A side trip's panel on the hub, then Home's button pair. Open: its
/// rating with the last game's change, the next ranked game, and the burst
/// that starts it ([onRanked]); free play ([onFree], or why it is still
/// locked) and the rules ([onRules]) under it. Locked: the cards remembered
/// so far as pips and a grey bar saying how many more open it, where the
/// burst will be; only the rules under it.
class SideTripBody extends StatelessWidget {
  const SideTripBody(this.entry, {super.key, required this.onRanked, required this.onFree, required this.onRules});

  final SideTripEntry entry;
  final VoidCallback onRanked, onFree, onRules;

  @override
  Widget build(BuildContext context) {
    final lock = entry.lock;
    final rules = _RulesButton(onTap: onRules);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MangaPanel(
          shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
          padding: const EdgeInsets.only(top: SideTripsLayout.overlap),
          child: lock == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsRow(entry),
                    Padding(
                      padding: SideTripsLayout.burstMargin,
                      child: RankedBurst(onTap: onRanked),
                    ),
                  ],
                )
              : _LockedRows(lock),
        ),
        const SizedBox(height: SideTripsLayout.pairTop),
        if (lock == null)
          Row(children: [
            Expanded(child: _FreeButton(entry, onTap: onFree)),
            const SizedBox(width: SideTripsLayout.pairGap),
            Expanded(child: rules),
          ])
        else
          rules,
      ],
    );
  }
}

/// A row's label, with the same in the other language as its sub-label.
class _Label extends StatelessWidget {
  const _Label(this.text, this.sub);

  final String text, sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          const TextSpan(text: ' '),
          TextSpan(
            text: sub.toUpperCase(),
            style: const TextStyle(
              fontSize: SideTripsLayout.subFont,
              letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
            ),
          ),
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
/// ranked game: its level, cards a side and memorise time.
class _StatsRow extends StatelessWidget {
  const _StatsRow(this.entry);

  final SideTripEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = entry.rating;
    final change = entry.ratingChange?.round() ?? 0;
    final level = entry.rankedLevel;
    const value = TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.valueFont, height: 1);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SideTripsLayout.rowMinHeight),
      child: Padding(
        padding: SideTripsLayout.rowPadding,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                flex: SideTripsLayout.ratingFlex,
                child: _Stat(
                  label: _Label(s.rating, s.other.rating),
                  value: rating == null
                      ? Text(s.sideTripUnranked,
                          style: const TextStyle(
                              fontFamily: Fonts.display, fontSize: SideTripsLayout.unrankedFont, height: 1))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${rating.round()}', style: value),
                          if (change != 0) ...[
                            const SizedBox(width: SideTripsLayout.valueGap),
                            _ChangeTag(change),
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
                    label: _Label(s.sideTripNextGame, s.other.sideTripNextGame),
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
    );
  }
}

/// The last ranked game's change to the rating: ▲ on ink, ▼ on paper.
class _ChangeTag extends StatelessWidget {
  const _ChangeTag(this.change);

  final int change;

  @override
  Widget build(BuildContext context) {
    final up = change > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: up ? Palette.ink : Palette.paper,
        border: up ? null : Border.all(color: Palette.ink, width: Strokes.label),
      ),
      child: Padding(
        padding: SideTripsLayout.deltaPadding,
        child: Text(
          '${up ? '▲' : '▼'}${change.abs()}',
          semanticsLabel: up ? '+$change' : '$change',
          style: TextStyle(
            fontFamily: Fonts.display,
            fontSize: SideTripsLayout.deltaFont,
            height: 1,
            color: up ? Palette.paper : Palette.ink,
          ),
        ),
      ),
    );
  }
}

/// The ranked shout: `burst.svg` (pink, deep pink while pressed) at its own
/// size, or scaled down whole to fit, with its label and an arrow in the
/// art's safe box.
class RankedBurst extends StatelessWidget {
  const RankedBurst({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = s.sideTripRanked;
    final sub = s.other.sideTripRanked.toUpperCase();
    return LayoutBuilder(builder: (context, box) {
      final scale = math.min(1.0, box.maxWidth / SideTripsLayout.burst.width);
      final size = SideTripsLayout.burst * scale;
      const label = SideTripsLayout.burstLabel;
      return Center(
        child: SizedBox.fromSize(
          size: size,
          child: Pressable(
            onTap: onTap,
            drop: 0,
            scale: Press.shoutScale,
            turn: Tilt.pressShout,
            semanticLabel: '$title $sub',
            builder: (context, pressed) => Stack(children: [
              VectorArtBox(SideTripArt.burst, size: size, color: pressed ? Palette.pinkDeep : Palette.pink),
              Positioned.fromRect(
                rect: Rect.fromLTRB(label.left * scale, label.top * scale, label.right * scale, label.bottom * scale),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.burstFont, height: 1)),
                      const SizedBox(width: SideTripsLayout.burstGap),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: SideTripsLayout.burstSubFont,
                          letterSpacing: SideTripsLayout.burstSubTracking * SideTripsLayout.burstSubFont,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: SideTripsLayout.burstGap),
                      MangaIcon(IconArt.arrow,
                          size: SideTripsLayout.burstIcon, strokeWidth: SideTripsLayout.burstIconStroke),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

/// A locked trip: the cards remembered well so far out of what opens it, as
/// a count and as pips, and the bar where its ranked burst will be.
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
                label: _Label(s.sideTripRemembered, s.other.sideTripRemembered),
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
          child: CardPips(
            [for (var i = 0; i < lock.opensAt; i++) i < lock.remembered ? PipState.learned : PipState.locked],
            gap: SideTripsLayout.pipGap,
            aspect: SideTripsLayout.pipAspect,
          ),
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
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: s.other.sideTripRanked.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: Weights.black,
                            fontSize: SideTripsLayout.subFont,
                            letterSpacing: SideTripsLayout.subTracking * SideTripsLayout.subFont,
                          ),
                        ),
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

/// Free play, in Home's button style: open, it says the levels it offers;
/// locked, grey with a padlock, how many more cards open it, and a tap
/// says why.
class _FreeButton extends StatelessWidget {
  const _FreeButton(this.entry, {required this.onTap});

  final SideTripEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lock = entry.freeLock;
    final maxLevel = entry.maxLevel;
    return HomeRowButton(
      icon: lock == null ? IconArt.cards : IconArt.lock,
      title: s.freePlay,
      badge: _Sub(s.other.freePlay),
      sub: lock != null
          ? s.sideTripLockedSub(lock.needed)
          : maxLevel == null
              ? s.sideTripFreeSub
              : s.sideTripFreeUpTo(maxLevel),
      color: lock == null ? Palette.paper : Palette.desk,
      onTap: () => lock == null
          ? onTap()
          : BalloonPop.show(context, s.sideTripFreeLockedWhy(lock.needed),
              size: SideTripsLayout.lockBalloon, life: SideTripsLayout.lockBalloonLife),
    );
  }
}

/// The rules (遊び方), in Home's button style.
class _RulesButton extends StatelessWidget {
  const _RulesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return HomeRowButton(icon: IconArt.help, title: s.howToPlay, sub: s.other.howToPlay.toUpperCase(), onTap: onTap);
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
