import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import 'debug_common.dart';

/// The rating a 一騎打ち developer page shows Tobi at, pinned over the
/// page's scrolling body: the rating large, a [note] beside it, and a
/// slider over the curves' ratings with its whole track in plain sight.
class IkkiuchiRatingHeader extends StatelessWidget {
  const IkkiuchiRatingHeader({super.key, required this.rating, required this.onChanged, this.note});

  final double rating;
  final ValueChanged<double> onChanged;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final soft = debugMono.copyWith(color: IkkiuchiToolsStyle.soft);
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: IkkiuchiToolsStyle.headerRule))),
      child: Padding(
        padding: IkkiuchiToolsStyle.headerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text.rich(TextSpan(style: soft, children: [
                  const TextSpan(text: 'rating '),
                  TextSpan(
                    text: '${rating.round()}',
                    style: debugMono.copyWith(
                        fontSize: IkkiuchiToolsStyle.ratingFont, fontWeight: Weights.bold, color: Palette.ink),
                  ),
                ])),
                const SizedBox(width: IkkiuchiToolsStyle.gap),
                if (note case final note?)
                  Expanded(
                    child: Text(note, style: soft, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: IkkiuchiToolsStyle.sliderActive,
                inactiveTrackColor: IkkiuchiToolsStyle.sliderInactive,
                thumbColor: IkkiuchiToolsStyle.sliderActive,
                trackHeight: IkkiuchiToolsStyle.sliderTrack,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: IkkiuchiToolsStyle.sliderThumb),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: IkkiuchiToolsStyle.sliderOverlay),
                padding: IkkiuchiToolsStyle.sliderPadding,
              ),
              child: Slider(
                value: rating,
                min: IkkiuchiTuning.ratingMin,
                max: IkkiuchiTuning.ratingMax,
                divisions: (IkkiuchiTuning.ratingMax - IkkiuchiTuning.ratingMin) ~/ IkkiuchiToolsTuning.ratingStep,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
