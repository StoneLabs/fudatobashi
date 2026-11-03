import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/placing.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/balloon.dart';
import '../placing/placing_widgets.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_send_flow.dart';

/// What a 送り札 ([IkkiuchiSendFlow]) draws on the board, in board dp, and
/// the touches it takes, with the placing's look
/// ([IkkiuchiSendStyle.look]). [under] it lies under the board's cards:
/// the dashed spots Tobi's waiting card may go. Else over them: the band's
/// words while a card is sent, Tobi's card waiting as a stack of one with
/// his balloon, a card being dragged with where it would land, and the
/// touches.
class IkkiuchiSendLayer extends StatelessWidget {
  const IkkiuchiSendLayer({super.key, required this.scene, required this.under});

  final IkkiuchiBoardScene scene;
  final bool under;

  IkkiuchiSendFlow get _flow => scene.send;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          if (!_flow.active) return const SizedBox.shrink();
          return under ? _spots() : _over(context);
        },
      );

  static const _look = IkkiuchiSendStyle.look;

  /// The dashed spots, while Tobi's card waits.
  Widget _spots() {
    if (_flow.stage != IkkiuchiSendStage.waiting) return const SizedBox.shrink();
    final targets = _flow.targets();
    return PlacingSpots(
      spots: [for (final (spot, r) in targets.freeSpots) (spot, Rect.fromLTWH(r.x, r.y, r.w, r.h))],
      cards: [for (final r in targets.cards.values) Rect.fromLTWH(r.x, r.y, r.w, r.h)],
      look: _look,
    );
  }

  Widget _over(BuildContext context) {
    final s = S.of(context);
    final showNumber = ProgressScope.of(context).settings.showPoemNumber;
    final flow = _flow, drag = flow.drag;
    final stage = flow.stage;
    final waiting = stage == IkkiuchiSendStage.waiting;
    final spot = drag?.spot;
    final landing = spot == null ? null : flow.rectOf(spot);
    final band = scene.band;
    return PlacingGestures(
      cardAt: flow.cardAt,
      onTap: flow.tap,
      onDragStart: flow.dragStart,
      onDrag: flow.dragTo,
      onDragEnd: flow.dragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fromRect(
          rect: band,
          child: _BandWords(title: s.ikkiuchiSent, line: stage == IkkiuchiSendStage.sending ? s.ikkiuchiSendYours : s.ikkiuchiPlaceTobis),
        ),
        if (waiting) ...[
          Positioned.fromRect(
            rect: scene.wait,
            child: drag == null
                ? PlacingStack(cards: [flow.card!], tag: s.ikkiuchiSent, look: _look, showNumber: showNumber)
                : const PlacingDashedSpot(look: _look),
          ),
          Positioned.fromRect(rect: _balloonRect(), child: _Balloon(s.ikkiuchiHereYouGo)),
        ],
        if (landing != null) Positioned.fromRect(rect: landing, child: const PlacingLanding(look: _look)),
        if (drag != null)
          Positioned.fill(
            child: PlacingRiding(
              drag: drag,
              landing: drag.fromStack ? _spotName(s, spot) : (flow.overTobi ? s.ikkiuchiToTobi : null),
              card: flow.cardSize,
              width: scene.layout.size.x,
              look: _look,
              showNumber: showNumber,
            ),
          ),
      ]),
    );
  }

  String? _spotName(S s, PlacingSpot? spot) {
    final place = spot == null ? null : _flow.placeOf(spot);
    return place == null ? null : s.ikkiuchiSpotName(place.row, place.part);
  }

  /// Left of Tobi's head.
  Rect _balloonRect() {
    final tobi = scene.tobi;
    const size = IkkiuchiSendStyle.balloonSize;
    final height = tobi.rig.size.y * tobi.k;
    return Rect.fromLTWH(tobi.origin.x - IkkiuchiSendStyle.balloonGap - size.width,
        tobi.origin.y + IkkiuchiSendStyle.balloonDrop * height, size.width, size.height);
  }
}

/// The band's words while a card is sent: its title over what to do.
class _BandWords extends StatelessWidget {
  const _BandWords({required this.title, required this.line});

  final String title, line;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: IkkiuchiSendStyle.bandTitle, height: 1, color: IkkiuchiSendStyle.bandInk)),
            const SizedBox(height: IkkiuchiSendStyle.lineGap),
            Text(line,
                style: const TextStyle(
                    fontFamily: Fonts.ui, fontSize: IkkiuchiSendStyle.bandLine, height: 1, color: IkkiuchiSendStyle.lineInk)),
          ]),
        ),
      );
}

/// Tobi's word as his card waits.
class _Balloon extends StatelessWidget {
  const _Balloon(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SpeechBalloon(
        speaker: IkkiuchiSendStyle.balloonSpeaker,
        padding: IkkiuchiSendStyle.balloonPadding,
        child: Text(text, style: const TextStyle(fontSize: IkkiuchiSendStyle.balloonFont)),
      );
}
