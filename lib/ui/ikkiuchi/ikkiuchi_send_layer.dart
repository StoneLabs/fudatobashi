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

/// What a layer of a 送り札 or 並べ替え draws on the board: the part [under]
/// the board's cards, the part [over] them, which takes the touches, or
/// the cards it holds up ([top]), over the match's own parts too.
enum IkkiuchiLayerPart { under, over, top }

/// What a 送り札 ([IkkiuchiSendFlow]) draws on the board, in board dp, and
/// the touches it takes, with the placing's look
/// ([IkkiuchiSendStyle.look]). Its [part] under the board's cards: Tobi's
/// side as one dashed spot while the player sends him a card, lit while
/// the card dragged is over it; the dashed spots Tobi's waiting card may
/// go. Over them: the band's words while a card is sent, Tobi's balloon
/// while his card waits, where a card dragged would land, and the touches.
/// On top: Tobi's card waiting as a stack of one, and a card being
/// dragged.
class IkkiuchiSendLayer extends StatelessWidget {
  const IkkiuchiSendLayer({super.key, required this.scene, required this.part});

  final IkkiuchiBoardScene scene;
  final IkkiuchiLayerPart part;

  IkkiuchiSendFlow get _flow => scene.send;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          if (!_flow.active) return const SizedBox.shrink();
          return switch (part) {
            IkkiuchiLayerPart.under => _under(context),
            IkkiuchiLayerPart.over => _over(context),
            IkkiuchiLayerPart.top => IgnorePointer(child: _top(context)),
          };
        },
      );

  static const _look = IkkiuchiSendStyle.look;

  Widget _under(BuildContext context) => switch (_flow.stage) {
        IkkiuchiSendStage.sending => Stack(children: [
            Positioned.fromRect(
              rect: _flow.tobiSide,
              child: _flow.overTobi ? const PlacingLanding(look: _look) : const PlacingDashedSpot(look: _look),
            ),
          ]),
        IkkiuchiSendStage.waiting => _spots(context),
        IkkiuchiSendStage.none || IkkiuchiSendStage.placing || IkkiuchiSendStage.carrying => const SizedBox.shrink(),
      };

  /// The dashed spots, while Tobi's card waits.
  Widget _spots(BuildContext context) {
    final targets = _flow.targets();
    return PlacingSpots(
      spots: [for (final (spot, r) in targets.freeSpots) (spot, Rect.fromLTWH(r.x, r.y, r.w, r.h))],
      cards: [for (final r in targets.cards.values) Rect.fromLTWH(r.x, r.y, r.w, r.h)],
      look: _look,
      middleLabel: S.of(context).ikkiuchiOpenMiddle,
    );
  }

  Widget _over(BuildContext context) {
    final s = S.of(context);
    final flow = _flow, stage = flow.stage;
    final spot = flow.drag?.spot;
    final landing = spot == null ? null : flow.rectOf(spot);
    return PlacingGestures(
      cardAt: flow.cardAt,
      onTap: flow.tap,
      onDragStart: flow.dragStart,
      onDrag: flow.dragTo,
      onDragEnd: flow.dragEnd,
      child: Stack(clipBehavior: Clip.none, children: [
        if (!scene.layout.landscape)
          Positioned.fromRect(
          rect: scene.band,
          child: IkkiuchiBandWords(title: s.ikkiuchiSent, line: switch (stage) {
            IkkiuchiSendStage.sending => s.ikkiuchiSendYours,
            IkkiuchiSendStage.placing => s.ikkiuchiTobiPlaces,
            _ => s.ikkiuchiPlaceTobis,
          }),
        ),
        if (stage == IkkiuchiSendStage.waiting)
          Positioned.fromRect(rect: _balloonRect(), child: _Balloon(s.ikkiuchiHereYouGo)),
        if (landing != null) Positioned.fromRect(rect: landing, child: const PlacingLanding(look: _look)),
      ]),
    );
  }

  Widget _top(BuildContext context) {
    final s = S.of(context);
    final showNumber = ProgressScope.of(context).settings.showPoemNumber;
    final flow = _flow, drag = flow.drag;
    return Stack(clipBehavior: Clip.none, children: [
      if (flow.stage == IkkiuchiSendStage.waiting)
        Positioned.fromRect(
          rect: scene.wait,
          child: drag == null
              ? PlacingStack(cards: [flow.card!], tag: s.ikkiuchiSent, look: _look, showNumber: showNumber)
              : const PlacingDashedSpot(look: _look),
        ),
      if (drag != null)
        Positioned.fill(
          child: PlacingRiding(
            drag: drag,
            landing: drag.fromStack ? _spotName(s, drag.spot) : (flow.overTobi ? s.ikkiuchiToTobi : null),
            card: flow.cardSize,
            width: scene.layout.size.x,
            look: _look,
            showNumber: showNumber,
          ),
        ),
    ]);
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

/// Words on the band in portrait instead of a call, as while a card is
/// sent: a title over a line saying what goes on.
class IkkiuchiBandWords extends StatelessWidget {
  const IkkiuchiBandWords({super.key, required this.title, required this.line});

  final String title, line;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: IkkiuchiBoardStyle.wordsTitle,
                    height: 1,
                    color: IkkiuchiBoardStyle.wordsTitleInk)),
            const SizedBox(height: IkkiuchiBoardStyle.wordsGap),
            Text(line,
                style: const TextStyle(
                    fontFamily: Fonts.ui,
                    fontSize: IkkiuchiBoardStyle.wordsLine,
                    height: 1,
                    color: IkkiuchiBoardStyle.wordsLineInk)),
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
