import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/buttons.dart';
import '../manga/hold_confirm.dart';
import '../manga/vector.dart';

/// A button at the game column's foot: its [icon] over its [label], on
/// [fill]; faded while [onTap] is null.
typedef IkkiuchiColumnButton = ({String label, VectorArt icon, Color fill, VoidCallback? onTap});

/// The game column down the board's right edge in landscape, as tall as it
/// is laid out: 終了 at its top, which ends the match once held
/// ([IkkiuchiMatchTuning.endHold]) and then tells [onEnd], and says to hold
/// it when only tapped; the score in its middle, each side's cards left
/// ([tobi], [player]), split on the line [split] down the column, the
/// middle of the gap between the sides; and the [buttons] at its foot, the
/// last lowest, as 並べ替え or 完了. Only 終了 and the buttons not faded take
/// touches; the rest lets them through to what lies under it.
class IkkiuchiMatchColumn extends StatelessWidget {
  const IkkiuchiMatchColumn({
    super.key,
    required this.tobi,
    required this.player,
    required this.split,
    required this.buttons,
    required this.onEnd,
  });

  final int tobi, player;
  final double split;
  final List<IkkiuchiColumnButton> buttons;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final endSeconds = (IkkiuchiMatchTuning.endHold.inMilliseconds / Duration.millisecondsPerSecond).round();
    return LayoutBuilder(
      builder: (context, box) => Stack(clipBehavior: Clip.none, children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: HoldToConfirmButton(
              duration: IkkiuchiMatchTuning.endHold,
              label: s.end,
              hint: s.ikkiuchiEndHint(endSeconds),
              look: IkkiuchiColumnStyle.end,
              haptics: ProgressScope.of(context).settings.haptics,
              icon: MangaIcon(IconArt.end,
                  size: IkkiuchiColumnStyle.endIcon, color: Palette.paper, strokeWidth: IkkiuchiColumnStyle.endIconStroke),
              onConfirmed: onEnd,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: box.maxHeight - split,
          child: IgnorePointer(child: _ScoreHalf(name: s.ikkiuchiTobi, count: tobi, top: true)),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: split,
          child: IgnorePointer(child: _ScoreHalf(name: s.ikkiuchiYou, count: player, top: false)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, button) in buttons.indexed) ...[
              if (i > 0) const SizedBox(height: IkkiuchiColumnStyle.buttonsGap),
              _FootButton(button),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Half of the score's ink panel, meeting the other on the split: Tobi's
/// name over his count above it ([top]), the player's count over their name
/// under it, after the rule between them.
class _ScoreHalf extends StatelessWidget {
  const _ScoreHalf({required this.name, required this.count, required this.top});

  final String name;
  final int count;
  final bool top;

  static const _name = TextStyle(
    fontFamily: Fonts.ui,
    fontWeight: Weights.black,
    fontSize: IkkiuchiColumnStyle.name,
    height: 1,
    letterSpacing: IkkiuchiColumnStyle.nameTracking * IkkiuchiColumnStyle.name,
    color: IkkiuchiColumnStyle.nameInk,
  );

  static const _count = TextStyle(
    fontFamily: Fonts.display,
    fontSize: IkkiuchiColumnStyle.count,
    height: 1,
    color: IkkiuchiColumnStyle.countInk,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    const padding = IkkiuchiColumnStyle.scorePadding;
    final label = FittedBox(fit: BoxFit.scaleDown, child: Text(name, maxLines: 1, style: _name));
    final number = FittedBox(fit: BoxFit.scaleDown, child: Text('$count', maxLines: 1, style: _count));
    const nameGap = SizedBox(height: IkkiuchiColumnStyle.nameGap);
    const ruleGap = SizedBox(height: IkkiuchiColumnStyle.ruleGap);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: IkkiuchiColumnStyle.scoreFill,
        boxShadow: [BoxShadow(color: IkkiuchiColumnStyle.shadowInk, offset: IkkiuchiColumnStyle.shadow)],
      ),
      child: Padding(
        padding: top ? padding.copyWith(bottom: 0) : padding.copyWith(top: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: top
              ? [label, nameGap, number, ruleGap]
              : [const _Rule(), ruleGap, number, nameGap, label],
        ),
      ),
    );
  }
}

/// The rule across the score, between the sides.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: IkkiuchiColumnStyle.ruleInset),
        child: SizedBox(
          height: IkkiuchiColumnStyle.rule,
          width: double.infinity,
          child: ColoredBox(color: IkkiuchiColumnStyle.ruleInk),
        ),
      );
}

/// A button at the column's foot: its icon over its word. Faded, it lets
/// touches through.
class _FootButton extends StatelessWidget {
  const _FootButton(this.button);

  final IkkiuchiColumnButton button;

  @override
  Widget build(BuildContext context) {
    final (:label, :icon, :fill, :onTap) = button;
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? IkkiuchiColumnStyle.dimmed : 1,
        child: InkButton(
          onTap: onTap,
          color: fill,
          border: Strokes.control,
          padding: IkkiuchiColumnStyle.buttonPadding,
          semanticLabel: label,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            MangaIcon(icon, size: IkkiuchiColumnStyle.buttonIcon, strokeWidth: IkkiuchiColumnStyle.buttonIconStroke),
            const SizedBox(height: IkkiuchiColumnStyle.buttonGap),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiColumnStyle.buttonFont, height: 1)),
            ),
          ]),
        ),
      ),
    );
  }
}
