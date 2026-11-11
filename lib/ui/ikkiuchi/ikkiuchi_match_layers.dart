import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_call_strip.dart';
import 'ikkiuchi_feedback_banner.dart';
import 'ikkiuchi_match_column.dart';
import 'ikkiuchi_match_flow.dart';
import 'ikkiuchi_send_flow.dart';

/// The call over the board, in board dp, moving with the board as it is
/// laid out afresh, where the layout has it ([IkkiuchiBoardScene.words])
/// and in its look ([IkkiuchiBoardLayout.callLook]): the strip
/// ([IkkiuchiCallStrip]) reading the scene's call, or saying what to do
/// while a card is sent or the player moves their cards, or, with a
/// [flow], the time left of its memory time, or the 下の句; and with a
/// [flow], how each read ended ([IkkiuchiFeedbackBanner]). Their words are
/// as wide as the call's room at most, their strip reaching past it. It
/// takes no touches; it lies over the cards and under the game column and
/// what a 送り札 or 並べ替え draws over them (`IkkiuchiBoardView.overCards`),
/// so a dragged card rides over it.
class IkkiuchiCallLayer extends StatelessWidget {
  const IkkiuchiCallLayer({super.key, required this.scene, this.flow});

  final IkkiuchiBoardScene scene;
  final IkkiuchiMatchFlow? flow;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([scene, flow]),
        builder: (context, _) {
          final s = S.of(context), words = scene.words, look = scene.layout.callLook, flow = this.flow;
          const bleed = IkkiuchiCallStyle.bleed, padding = IkkiuchiCallStyle.fade + IkkiuchiCallStyle.inset;
          final room = Rect.fromLTRB(words.left - padding, words.top - bleed, words.right + padding, words.bottom + bleed);
          Widget over(Widget child) => Positioned.fromRect(rect: room, child: IgnorePointer(child: Center(child: child)));
          return Stack(children: [
            over(IkkiuchiCallStrip(reader: scene.reader, look: look, prompt: _prompt(s), shimonoku: flow?.shimonoku(s))),
            if (flow?.feedback case final end? when flow!.stage == IkkiuchiStage.feedback)
              over(IkkiuchiFeedbackBanner(
                text: s.ikkiuchiFeedback(end.callouts),
                at: IkkiuchiMatchTuning.feedback.inMicroseconds / Duration.microsecondsPerMillisecond - flow.left,
                look: look,
              )),
          ]);
        },
      );

  /// What to do instead of the call: send a card, place Tobi's, or move
  /// one's own; or the memory time left, while placing too.
  ({String title, String line})? _prompt(S s) {
    if (scene.arrange.active) return (title: s.ikkiuchiArranging, line: s.ikkiuchiArrangeHint);
    if (flow case final flow? when flow.stage == IkkiuchiStage.placing || flow.stage == IkkiuchiStage.memoryTime) {
      return (title: s.ikkiuchiMemoryTime, line: s.ikkiuchiTimeLeft(ikkiuchiClock(flow.left)));
    }
    return switch (scene.send.stage) {
      IkkiuchiSendStage.none => null,
      IkkiuchiSendStage.sending => (title: s.ikkiuchiSent, line: s.ikkiuchiSendShort),
      IkkiuchiSendStage.placing => (title: s.ikkiuchiSent, line: s.ikkiuchiTobiPlaces),
      IkkiuchiSendStage.carrying || IkkiuchiSendStage.waiting => (title: s.ikkiuchiSent, line: s.ikkiuchiPlaceTobis),
    };
  }
}

/// The game column over the board, in board dp, at the layout's place and
/// moving with it ([IkkiuchiMatchColumn]): down its right edge in
/// landscape, along the band in portrait. The score live, and at its foot
/// 並べ替え starting and ending the scene's
/// [IkkiuchiBoardScene.arrange], free only while nothing else is under way,
/// and with a [flow] only while it lets the player move cards, started
/// through it ([IkkiuchiMatchFlow.startArranging]). With a
/// [flow], while the player places their cards 完了 stands there instead,
/// for once every card is placed ([IkkiuchiMatchFlow.donePlacing]), and
/// blinking from then until tapped; in the
/// memory time after it 覚えた stands over 並べ替え, ending it at once
/// ([IkkiuchiMatchFlow.startEarly]). [onEnd] gets 終了
/// once held, named 投了 while it would [surrender] the match, faded once
/// the match can't be ended ([IkkiuchiMatchFlow.canEnd]). Only its
/// buttons take touches. It is one of the board's
/// match parts (`IkkiuchiBoardView.parts`), so a card a 送り札 holds up lies
/// over it.
class IkkiuchiColumnLayer extends StatelessWidget {
  const IkkiuchiColumnLayer(
      {super.key, required this.scene, required this.onEnd, this.flow, this.surrender = false});

  final IkkiuchiBoardScene scene;
  final VoidCallback onEnd;
  final IkkiuchiMatchFlow? flow;
  final bool surrender;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([scene, flow]),
        builder: (context, _) {
          final column = scene.column, score = scene.cardsLeft;
          return Stack(children: [
            if (score != null)
              Positioned.fromRect(
                rect: column ?? scene.band,
                child: IkkiuchiMatchColumn(
                  tobi: score.tobi,
                  player: score.player,
                  split: column == null ? null : scene.band.center.dy - column.top,
                  buttons: _buttons(S.of(context)),
                  onEnd: onEnd,
                  surrender: surrender,
                  canEnd: flow?.canEnd ?? true,
                ),
              ),
          ]);
        },
      );

  List<IkkiuchiColumnButton> _buttons(S s) {
    final flow = this.flow, arrange = scene.arrange, opening = scene.opening;
    IkkiuchiColumnButton go(String label, VoidCallback? onTap, {bool blink = false}) => (
          label: label,
          icon: IconArt.arrow,
          fill: onTap == null ? IkkiuchiColumnStyle.arrangeFill : IkkiuchiColumnStyle.doneFill,
          onTap: onTap,
          blink: blink,
        );
    if (flow?.stage == IkkiuchiStage.placing) {
      return [go(s.done, opening.allPlaced ? flow!.donePlacing : null, blink: opening.allPlaced)];
    }
    if (arrange.active) {
      return [(label: s.done, icon: IconArt.check, fill: IkkiuchiColumnStyle.doneFill, onTap: arrange.finish, blink: false)];
    }
    return [
      if (flow?.stage == IkkiuchiStage.memoryTime) go(s.ikkiuchiReady, flow!.startEarly),
      (
        label: s.ikkiuchiArrange,
        icon: IconArt.swap,
        fill: IkkiuchiColumnStyle.arrangeFill,
        onTap: switch (flow) {
          final flow? => flow.canArrange ? flow.startArranging : null,
          null => arrange.canStart ? arrange.start : null,
        },
        blink: false,
      ),
    ];
  }
}

/// [ms] as minutes and seconds, the seconds rounded up: 14:57.
String ikkiuchiClock(double ms) {
  final seconds = (ms / Duration.millisecondsPerSecond).ceil();
  return '${seconds ~/ Duration.secondsPerMinute}:${(seconds % Duration.secondsPerMinute).toString().padLeft(2, '0')}';
}
