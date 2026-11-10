import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rank_ladder.dart';
import 'debug_common.dart';

/// The rating a 一騎打ち developer page shows Tobi at, pinned over the
/// page's scrolling body: the rating large, a [note] beside it, a slider
/// over the curves' ratings with its whole track in plain sight, and the
/// rating classes under it.
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
            // In line with the thumb's run: half the track's height in from
            // each end of the track.
            Padding(
              padding: EdgeInsets.only(
                left: IkkiuchiToolsStyle.sliderPadding.left + IkkiuchiToolsStyle.sliderTrack / 2,
                right: IkkiuchiToolsStyle.sliderPadding.right + IkkiuchiToolsStyle.sliderTrack / 2,
              ),
              child: _RankBar(rating),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rating classes over the slider's ratings, each a segment as wide as
/// its span, named in full where the name fits and by its stem where it
/// doesn't, the class at [rating] inked.
class _RankBar extends StatelessWidget {
  const _RankBar(this.rating);

  final double rating;

  @override
  Widget build(BuildContext context) {
    const min = IkkiuchiTuning.ratingMin, max = IkkiuchiTuning.ratingMax;
    const bands = RankLadder.bands;
    final on = RankLadder.bandOf(rating);
    final spans = [
      for (final (i, band) in bands.indexed)
        (band, math.max(band.minRating, min), i + 1 < bands.length ? math.min(bands[i + 1].minRating, max) : max),
    ].where((s) => s.$3 > s.$2);
    final base = DefaultTextStyle.of(context).style.copyWith(fontSize: IkkiuchiToolsStyle.rankFont);
    final scaler = MediaQuery.textScalerOf(context);

    // The band's full name if it fits in [room], else its stem, else none.
    String fitting(RankBand band, TextStyle style, double room) {
      for (final name in [band.label, band.stem]) {
        final tp = TextPainter(
            text: TextSpan(text: name, style: style), textDirection: TextDirection.ltr, textScaler: scaler)
          ..layout();
        final fits = tp.width <= room;
        tp.dispose();
        if (fits) return name;
      }
      return '';
    }

    Widget segment(RankBand band, double width, {required bool first}) {
      final isOn = band == on;
      final style = base.copyWith(
        color: isOn ? IkkiuchiToolsStyle.rankOnText : IkkiuchiToolsStyle.rankText,
        fontWeight: isOn ? Weights.bold : null,
      );
      final gap = first ? 0.0 : IkkiuchiToolsStyle.rankGap;
      return SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.only(left: gap),
          child: ColoredBox(
            color: isOn ? IkkiuchiToolsStyle.rankOnFill : IkkiuchiToolsStyle.rankFill,
            child: Center(
              child: Text(
                fitting(band, style, width - gap - 2 * IkkiuchiToolsStyle.rankLabelPadding),
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: IkkiuchiToolsStyle.rankHeight,
      child: LayoutBuilder(
        builder: (context, box) => Row(children: [
          for (final (i, (band, lo, hi)) in spans.indexed)
            segment(band, box.maxWidth * (hi - lo) / (max - min), first: i == 0),
        ]),
      ),
    );
  }
}
