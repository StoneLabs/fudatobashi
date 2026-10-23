import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';

/// 暗記練's centre band, a paper strip between ink rules: [leading] and
/// [trailing] controls in equal slots either side, each [slot] wide, so
/// [center] sits in the middle of the screen, shrinking rather than
/// crowding them.
class AnkirenBand extends StatelessWidget {
  const AnkirenBand({
    super.key,
    required this.landscape,
    required this.leading,
    required this.center,
    this.trailing,
    this.slot = AnkirenPlayLayout.sideSlot,
  });

  final bool landscape;
  final Widget leading;
  final Widget center;
  final Widget? trailing;
  final double slot;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AnkirenPlayLayout.bandColor,
          border: Border.symmetric(
              horizontal: BorderSide(color: Palette.ink, width: AnkirenPlayLayout.bandRule)),
        ),
        child: Padding(
          padding: landscape ? AnkirenPlayLayout.bandPaddingLandscape : AnkirenPlayLayout.bandPadding,
          child: Row(children: [
            SizedBox(width: slot, child: Align(alignment: Alignment.centerLeft, child: leading)),
            const SizedBox(width: AnkirenPlayLayout.bandGap),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: center)),
            const SizedBox(width: AnkirenPlayLayout.bandGap),
            SizedBox(
              width: slot,
              child: Align(alignment: Alignment.centerRight, child: trailing ?? const SizedBox.shrink()),
            ),
          ]),
        ),
      );
}

/// A band control: an icon and a word in an ink button as tall as the band
/// allows, shrinking its contents to fit.
class BandButton extends StatelessWidget {
  const BandButton({super.key, required this.icon, required this.label, required this.onTap, this.color = Palette.paper});

  final VectorArt icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AnkirenPlayLayout.sideSlot,
        height: double.infinity,
        child: InkButton(
          onTap: onTap,
          color: color,
          border: Strokes.control,
          padding: AnkirenPlayLayout.controlPadding,
          semanticLabel: label,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              MangaIcon(icon, size: AnkirenPlayLayout.controlIcon),
              const SizedBox(width: Gaps.tight),
              Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPlayLayout.controlFont)),
            ]),
          ),
        ),
      );
}

/// The memorise countdown: the time [left], m:ss, and what it counts.
class MemoriseClock extends StatelessWidget {
  const MemoriseClock({super.key, required this.left, required this.landscape});

  final ValueListenable<Duration> left;
  final bool landscape;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: left,
            builder: (context, left, _) => Text(
              formatMinutes(left),
              style: TextStyle(
                fontFamily: Fonts.display,
                height: 1,
                fontSize: landscape ? AnkirenPlayLayout.timerFontLandscape : AnkirenPlayLayout.timerFont,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AnkirenPlayLayout.bandGap),
          Text(
            S.of(context).ankirenMemorise,
            style: const TextStyle(
              fontWeight: Weights.black,
              fontSize: AnkirenPlayLayout.labelFont,
              letterSpacing: AnkirenPlayLayout.labelTracking * AnkirenPlayLayout.labelFont,
            ),
          ),
        ],
      );
}

/// Where the band's prompt stands: a card asked for, or the last one, found
/// or given up, while the next waits.
enum PromptState { asked, found, givenUp }

/// The kimariji of the card [state] says ([text]), and how many cards are
/// [done] out of [total].
class PromptText extends StatelessWidget {
  const PromptText({
    super.key,
    required this.text,
    required this.state,
    required this.done,
    required this.total,
    required this.landscape,
  });

  /// Null while nothing is asked yet.
  final String? text;
  final PromptState state;
  final int done, total;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      PromptState.asked => (Palette.ink, null),
      PromptState.found => (AnkirenPlayLayout.foundText, IconArt.check),
      PromptState.givenUp => (AnkirenPlayLayout.givenUpText, IconArt.question),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null && text != null) ...[
        MangaIcon(icon, size: AnkirenPlayLayout.controlIcon, color: color),
        const SizedBox(width: Gaps.tight),
      ],
      Text(
        text ?? '',
        style: TextStyle(
          fontFamily: Fonts.display,
          height: 1,
          color: color,
          fontSize: landscape ? AnkirenPlayLayout.promptFontLandscape : AnkirenPlayLayout.promptFont,
        ),
      ),
      const SizedBox(width: AnkirenPlayLayout.bandGap),
      Text(
        '$done/$total',
        style: const TextStyle(
          fontWeight: Weights.black,
          fontSize: AnkirenPlayLayout.countFont,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ]);
  }
}
