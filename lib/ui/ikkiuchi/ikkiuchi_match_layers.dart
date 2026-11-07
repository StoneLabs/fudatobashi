import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_call_strip.dart';
import 'ikkiuchi_match_column.dart';
import 'ikkiuchi_send_flow.dart';

/// The call over a landscape board, in board dp, moving with the board as
/// it is laid out afresh: the strip in the gap between the sides, centred
/// on the field ([IkkiuchiCallStrip]), reading the scene's call, or saying
/// what to do while a card is sent or the player moves their cards. It
/// takes no touches; it lies over the cards and under what a 送り札 or
/// 並べ替え draws over them (`IkkiuchiBoardView.overCards`), so a dragged
/// card rides over it.
class IkkiuchiCallLayer extends StatelessWidget {
  const IkkiuchiCallLayer({super.key, required this.scene});

  final IkkiuchiBoardScene scene;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          final band = scene.band, field = scene.field;
          const bleed = IkkiuchiCallStyle.bleed;
          return Stack(children: [
            Positioned.fromRect(
              rect: Rect.fromLTRB(field.left, band.top - bleed, field.right, band.bottom + bleed),
              child: IgnorePointer(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      height: band.height + 2 * bleed,
                      child: IkkiuchiCallStrip(reader: scene.reader, karafuda: scene.karafuda, prompt: _prompt(S.of(context))),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      );

  /// What to do instead of the call: send a card, place Tobi's, or move
  /// one's own.
  ({String title, String line})? _prompt(S s) {
    if (scene.arrange.active) return (title: s.ikkiuchiArranging, line: s.ikkiuchiArrangeHint);
    return switch (scene.send.stage) {
      IkkiuchiSendStage.none => null,
      IkkiuchiSendStage.sending => (title: s.ikkiuchiSent, line: s.ikkiuchiSendShort),
      IkkiuchiSendStage.carrying || IkkiuchiSendStage.waiting => (title: s.ikkiuchiSent, line: s.ikkiuchiPlaceTobis),
    };
  }
}

/// The game column over a landscape board, in board dp, at the layout's
/// place and moving with it ([IkkiuchiMatchColumn]): the score live, and
/// 並べ替え starting and ending the scene's [IkkiuchiBoardScene.arrange],
/// free only while nothing else is under way. [onEnd] gets 終了 once held.
/// Only its buttons take touches. It is one of the board's match parts
/// (`IkkiuchiBoardView.parts`), so a card a 送り札 holds up lies over it.
class IkkiuchiColumnLayer extends StatelessWidget {
  const IkkiuchiColumnLayer({super.key, required this.scene, required this.onEnd});

  final IkkiuchiBoardScene scene;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          final column = scene.column, score = scene.cardsLeft;
          final arrange = scene.arrange;
          return Stack(children: [
            if (column != null && score != null)
              Positioned.fromRect(
                rect: column,
                child: IkkiuchiMatchColumn(
                  tobi: score.tobi,
                  player: score.player,
                  split: scene.band.center.dy - column.top,
                  arranging: arrange.active,
                  onArrange: arrange.canStart ? arrange.start : null,
                  onDone: arrange.finish,
                  onEnd: onEnd,
                ),
              ),
          ]);
        },
      );
}
