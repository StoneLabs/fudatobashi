import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/entrance.dart';
import '../manga/lettering.dart';
import '../manga/lines.dart';
import '../sound/sounds.dart';
import 'ikkiuchi_tobi_tag.dart';

/// How a match ended ([result]) over its board, in board dp: the board
/// dimmed, focus lines meeting in its middle, none across Tobi's box
/// ([tobi]), and his [rating] on his tag over his box or beside it, dimmed
/// with the board but clear of the lines; in the middle the result slammed
/// down in big tilted lettering, with a banner under it saying by how many
/// cards it was won or lost (the loser's cards [left]), or that it was
/// given up. Tobi's face is the board's own. A win cheers ([Sfx.best]) as
/// its lettering lands. A tap anywhere calls [onTap].
class IkkiuchiMatchResult extends StatelessWidget {
  const IkkiuchiMatchResult({
    super.key,
    required this.result,
    required this.left,
    required this.tobi,
    this.rating,
    required this.onTap,
  });

  final IkkiuchiResult result;
  final IkkiuchiTally left;
  final Rect tobi;
  final int? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = (left.opponent - left.player).abs();
    final rating = this.rating;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SoundCues(
        cues: [if (result == IkkiuchiResult.won) (Sfx.best, IkkiuchiResultStyle.letteringIn.delay)],
        child: EntranceStage(
          length: IkkiuchiResultStyle.length,
          child: Stack(fit: StackFit.expand, children: [
            const Entrance(IkkiuchiResultStyle.dimIn, child: ColoredBox(color: IkkiuchiResultStyle.scrim)),
            LayoutBuilder(
              builder: (context, box) => Entrance(
                IkkiuchiResultStyle.linesIn,
                child: CustomPaint(painter: FocusLinesPainter(_lines(box.biggest))),
              ),
            ),
            if (rating != null)
              Entrance(
                IkkiuchiResultStyle.dimIn,
                child: CustomSingleChildLayout(
                  delegate: _TagPlace(tobi),
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: const BoxDecoration(color: IkkiuchiResultStyle.scrim),
                    child: IkkiuchiTobiTag(rating),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: IkkiuchiResultStyle.inset),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Transform.rotate(
                    angle: IkkiuchiResultStyle.turnDeg * math.pi / 180,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Entrance(
                        IkkiuchiResultStyle.letteringIn,
                        child: OutlinedText(
                          result == IkkiuchiResult.won ? s.ikkiuchiBeatTobi : s.ikkiuchiTobiWins,
                          style: const TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: IkkiuchiResultStyle.font,
                              height: 1,
                              color: IkkiuchiResultStyle.fill),
                          outline: IkkiuchiResultStyle.ink,
                          outlineWidth: IkkiuchiResultStyle.outline,
                        ),
                      ),
                      const SizedBox(height: IkkiuchiResultStyle.subGap),
                      Entrance(
                        IkkiuchiResultStyle.subIn,
                        child: _Banner(s.ikkiuchiResultLine(result, margin)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// The focus lines over a board of [size], meeting in its middle, none
  /// across Tobi.
  BurstSpec _lines(Size size) {
    const lines = IkkiuchiResultStyle.lines;
    return BurstSpec(
      box: size,
      center: size.center(Offset.zero),
      count: lines.count,
      innerMin: lines.innerMin,
      innerMax: lines.innerMax,
      width: lines.width,
      seed: lines.seed,
      color: IkkiuchiResultStyle.linesColor,
      clear: tobi,
    );
  }
}

/// The line under the result, on an ink banner.
class _Banner extends StatelessWidget {
  const _Banner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: IkkiuchiResultStyle.subHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: IkkiuchiResultStyle.ink),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: IkkiuchiResultStyle.subPadding),
            child: Center(
              widthFactor: 1,
              child: Text(text,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: IkkiuchiResultStyle.subFont,
                      height: 1,
                      color: IkkiuchiResultStyle.subInk)),
            ),
          ),
        ),
      );
}

/// Tobi's tag [IkkiuchiResultStyle.tagGap] over [tobi], his box, when it
/// has room there; else the gap left of his box, by his head.
class _TagPlace extends SingleChildLayoutDelegate {
  const _TagPlace(this.tobi);

  final Rect tobi;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = IkkiuchiResultStyle.tagGap;
    final top = tobi.top - gap - childSize.height;
    if (top >= gap) return Offset(tobi.center.dx - childSize.width / 2, top);
    return Offset(
      tobi.left - gap - childSize.width,
      tobi.top + tobi.height * IkkiuchiResultStyle.tagDrop - childSize.height / 2,
    );
  }

  @override
  bool shouldRelayout(_TagPlace oldDelegate) => oldDelegate.tobi != tobi;
}
