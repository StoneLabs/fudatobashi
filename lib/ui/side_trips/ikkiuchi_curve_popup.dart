import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../ikkiuchi/ikkiuchi_rank_overlay.dart';
import '../manga/manga.dart';
import 'ikkiuchi_mode_box.dart';

/// Opens the popup of [change]'s mode ([IkkiuchiCurvePopup]) over
/// 一騎打ち's page.
Future<void> openIkkiuchiCurvePopup(BuildContext context, IkkiuchiRankChange change) => showMangaSheet<void>(
      context,
      barrierColor: IkkiuchiPageLayout.barrier,
      barrierLabel: S.of(context).close,
      builder: (_) => IkkiuchiCurvePopup(change),
    );

/// The rank change page's mode box after [change], the mode's last ranked
/// match, at rest ([IkkiuchiRankBoxAtRest]), in the middle of the screen:
/// its tab on the mode's ground in a strip over the box, with the close
/// button at the strip's right end. A tap outside it closes it too.
class IkkiuchiCurvePopup extends StatelessWidget {
  const IkkiuchiCurvePopup(this.change, {super.key});

  final IkkiuchiRankChange change;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const head = IkkiuchiCurvePopupLayout.head;
    const strip = head + IkkiuchiRankLayout.tabHeight + IkkiuchiRankLayout.frameStroke;
    const closeInset = (strip - ButtonMetrics.iconButton) / 2;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.gutter),
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: LayoutBuilder(
              builder: (context, room) => SizedBox(
                width: room.maxWidth,
                height: math.min(head + IkkiuchiCurvePopupLayout.height, room.maxHeight),
                child: Stack(children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: strip,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ikkiuchiModeTone(change.mode).tone.background,
                        border: Border.all(color: Palette.ink, width: IkkiuchiRankLayout.frameStroke),
                      ),
                    ),
                  ),
                  Positioned.fill(top: head, child: IkkiuchiRankBoxAtRest(change)),
                  Positioned(
                    top: closeInset,
                    right: closeInset,
                    child: InkIconButton(icon: IconArt.close, semanticLabel: s.close, onTap: () => Navigator.pop(context)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
