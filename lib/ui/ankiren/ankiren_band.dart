import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// [d] as m:ss, e.g. 1:05.
String formatMinutes(Duration d) {
  final seconds = d.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// 暗記練's centre band, a paper strip between ink rules: [leading] and
/// [trailing] controls in equal slots either side, so [center] sits in the
/// middle of the screen, shrinking rather than crowding them.
class AnkirenBand extends StatelessWidget {
  const AnkirenBand({super.key, required this.landscape, required this.leading, required this.center, this.trailing});

  final bool landscape;
  final Widget leading;
  final Widget center;
  final Widget? trailing;

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
            SizedBox(width: AnkirenPlayLayout.sideSlot, child: Align(alignment: Alignment.centerLeft, child: leading)),
            const SizedBox(width: AnkirenPlayLayout.bandGap),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: center)),
            const SizedBox(width: AnkirenPlayLayout.bandGap),
            SizedBox(
              width: AnkirenPlayLayout.sideSlot,
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

/// The kimariji asked for ([text]), or the one just [found] while the next
/// waits (with a tick), and how many cards are [done] out of [total].
class PromptText extends StatelessWidget {
  const PromptText({
    super.key,
    required this.text,
    required this.found,
    required this.done,
    required this.total,
    required this.landscape,
  });

  /// Null while nothing is asked yet.
  final String? text;
  final bool found;
  final int done, total;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final color = found ? AnkirenPlayLayout.foundText : Palette.ink;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (found) ...[
        MangaIcon(IconArt.check, size: AnkirenPlayLayout.controlIcon, color: color),
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
