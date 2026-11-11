import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/entrance.dart';
import '../manga/lettering.dart';
import 'ikkiuchi_board_painter.dart';
import 'ikkiuchi_match_flow.dart';
import 'ikkiuchi_match_layers.dart';
import 'ikkiuchi_match_result.dart';

/// A match's board as it is played ([IkkiuchiMatchFlow]), in board dp: the
/// board taking the player's finger; the call in the gap or on the band,
/// and how each read ended over it ([IkkiuchiCallLayer]); the game column,
/// whose 終了 calls [onEnd], named 投了 while it would [surrender] the
/// match; the greetings over everything as play begins and once it is over
/// ([IkkiuchiGreeting]); and then how the match ended
/// ([IkkiuchiMatchResult]), a tap on it letting the match be done.
class IkkiuchiMatchBoard extends StatelessWidget {
  const IkkiuchiMatchBoard(this.flow, {super.key, required this.onEnd, this.surrender = false});

  final IkkiuchiMatchFlow flow;
  final VoidCallback onEnd;
  final bool surrender;

  @override
  Widget build(BuildContext context) {
    final scene = flow.scene;
    return Stack(children: [
      Positioned.fill(
        child: IkkiuchiBoardView(
          scene,
          onPointer: scene.pointer,
          overCards: IkkiuchiCallLayer(scene: scene, flow: flow),
          parts: IkkiuchiColumnLayer(scene: scene, flow: flow, onEnd: onEnd, surrender: surrender),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: ListenableBuilder(
            listenable: Listenable.merge([flow, scene]),
            builder: (context, _) {
              final s = S.of(context);
              return Stack(children: [
                if (flow.stage == IkkiuchiStage.gameStart)
                  Positioned.fill(child: IkkiuchiGreeting(s.ikkiuchiGreeting, key: const ValueKey(IkkiuchiStage.gameStart), flow: flow)),
                if (flow.stage == IkkiuchiStage.gameEnd)
                  Positioned.fill(child: IkkiuchiGreeting(s.ikkiuchiThanks, key: const ValueKey(IkkiuchiStage.gameEnd), flow: flow)),
              ]);
            },
          ),
        ),
      ),
      Positioned.fill(
        child: ListenableBuilder(
          listenable: Listenable.merge([flow, scene]),
          builder: (context, _) {
            final result = flow.result;
            if (flow.stage != IkkiuchiStage.result || result == null) return const SizedBox.shrink();
            final tobi = scene.tobi;
            return IkkiuchiMatchResult(
              result: result,
              left: flow.tally,
              tobi: Rect.fromLTWH(tobi.origin.x, tobi.origin.y, tobi.rig.size.x * tobi.k, tobi.rig.size.y * tobi.k),
              rating: flow.rating?.round(),
              onTap: flow.dismissResult,
            );
          },
        ),
      ),
    ]);
  }
}

/// The players' [text] over the dimmed board, slammed onto each half in
/// comic lettering: Tobi's half first, then the player's.
class IkkiuchiGreeting extends StatelessWidget {
  const IkkiuchiGreeting(this.text, {super.key, required this.flow});

  final String text;
  final IkkiuchiMatchFlow flow;

  @override
  Widget build(BuildContext context) {
    final scene = flow.scene;
    final field = scene.field, band = scene.band;
    final size = scene.layout.size;
    return EntranceStage(
      length: IkkiuchiGreetingStyle.length,
      child: Stack(children: [
        const Positioned.fill(child: ColoredBox(color: IkkiuchiGreetingStyle.scrim)),
        Positioned.fromRect(
          rect: Rect.fromLTRB(0, field.top, size.x, band.top),
          child: _Line(text, spec: IkkiuchiGreetingStyle.tobiIn, turnDeg: IkkiuchiGreetingStyle.tobiTurnDeg),
        ),
        Positioned.fromRect(
          rect: Rect.fromLTRB(0, band.bottom, size.x, field.bottom),
          child: _Line(text, spec: IkkiuchiGreetingStyle.playerIn, turnDeg: IkkiuchiGreetingStyle.playerTurnDeg),
        ),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text, {required this.spec, required this.turnDeg});

  final String text;
  final EntranceSpec spec;
  final double turnDeg;

  @override
  Widget build(BuildContext context) => Padding(
        padding: IkkiuchiGreetingStyle.inset,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Entrance(
              spec,
              child: Transform.rotate(
                angle: turnDeg * math.pi / 180,
                child: OutlinedText(
                  text,
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: IkkiuchiGreetingStyle.font,
                      height: 1,
                      color: IkkiuchiGreetingStyle.fill),
                  outline: IkkiuchiGreetingStyle.ink,
                  outlineWidth: IkkiuchiGreetingStyle.outline,
                ),
              ),
            ),
          ),
        ),
      );
}
