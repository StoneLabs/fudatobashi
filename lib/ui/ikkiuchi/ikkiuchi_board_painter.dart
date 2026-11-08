import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../manga/vector.dart';
import 'ikkiuchi_arm_painter.dart';
import 'ikkiuchi_arrange_layer.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_effects.dart';
import 'ikkiuchi_opening_layer.dart';
import 'ikkiuchi_send_flow.dart';
import 'ikkiuchi_send_layer.dart';
import 'ikkiuchi_tobi_art.dart';

/// Paints the whole board in one go from its [scene]: the field's cards
/// (cached faces), the band over them, Tobi with his moving arm and any
/// card in his hand, and the effects.
class IkkiuchiBoardPainter extends CustomPainter {
  IkkiuchiBoardPainter(this.scene, {required this.pixelRatio}) : super(repaint: scene);

  final IkkiuchiBoardScene scene;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final board = scene.board;
    final now = board.now;
    final shake = _shake(board);
    canvas
      ..save()
      ..translate(shake.dx, shake.dy);
    final shown = board.cards.cards.where((c) => c.onBoard && !c.held).toList()
      ..sort((a, b) => (a.taken ? 1 : 0) - (b.taken ? 1 : 0));
    for (final card in shown) {
      _paintCard(canvas, card);
    }
    canvas.restore();
    if (!scene.layout.landscape) _paintBand(canvas, scene.band);
    canvas
      ..save()
      ..translate(shake.dx, shake.dy);
    _paintTobi(canvas, board);
    for (final hit in board.impacts) {
      IkkiuchiEffects.paintImpact(canvas, hit, now - hit.at, size);
    }
    // A fault is one fault however many cards the fist touched: one stamp,
    // on the first.
    if (board.faults.entries.firstOrNull case MapEntry(key: final id, value: final at)) {
      final card = board.cards.card(id);
      if (card.onBoard) IkkiuchiEffects.paintStamp(canvas, card.box, now - at, size);
    }
    canvas.restore();
  }

  /// The board jolts for a moment after a hit.
  Offset _shake(IkkiuchiBoard board) {
    final hit = board.impacts.lastOrNull;
    if (hit == null) return Offset.zero;
    final age = board.now - hit.at;
    if (age < 0 || age > IkkiuchiBoardStyle.shakeMs) return Offset.zero;
    final reach = IkkiuchiBoardStyle.shakeReach * (1 - age / IkkiuchiBoardStyle.shakeMs);
    return Offset(math.sin(board.now * IkkiuchiBoardStyle.shakeRateX) * reach,
        math.cos(board.now * IkkiuchiBoardStyle.shakeRateY) * reach);
  }

  /// [card] on the field, outlined when marked (green once the player took
  /// it, unless Tobi took it first) or when the player faulted on it.
  void _paintCard(Canvas canvas, IkkiuchiCard card) {
    if (!card.still) IkkiuchiEffects.paintStreaks(canvas, card.box, card.velocity);
    final board = scene.board;
    final mark = card.id == scene.marked
        ? (board.take?.card == card.id && board.taker != IkkiuchiSide.opponent ? _taken : _mark)
        : (board.playerFaults.containsKey(card.id) ? _fault : null);
    _paintFace(canvas, card.id, card.box, shown: card.shown, mark: mark);
  }

  /// Card [id]'s face lying as [box], [shown] its share showing, with an
  /// outline in [mark] when given.
  void _paintFace(Canvas canvas, int id, CardBox box, {double shown = 1, Paint? mark}) {
    final image = scene.faces.of(id, (box.hw * 2 * pixelRatio).round());
    final face = Rect.fromCenter(center: Offset.zero, width: box.hw * 2, height: box.hh * 2);
    canvas
      ..save()
      ..translate(box.centre.x, box.centre.y)
      ..rotate(box.angle)
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        face,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Palette.ink.withValues(alpha: shown),
      );
    if (mark != null) {
      const out = IkkiuchiBoardStyle.markGap + IkkiuchiBoardStyle.markWidth / 2;
      canvas.drawRRect(RRect.fromRectAndRadius(face.inflate(out), const Radius.circular(IkkiuchiBoardStyle.markRadius)), mark);
    }
    canvas.restore();
  }

  static Paint _outline(Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = IkkiuchiBoardStyle.markWidth
    ..color = color;

  static final _mark = _outline(IkkiuchiBoardStyle.markColor);
  static final _taken = _outline(IkkiuchiBoardStyle.takenMarkColor);
  static final _fault = _outline(IkkiuchiBoardStyle.faultMarkColor);

  void _paintBand(Canvas canvas, Rect band) {
    canvas.drawRect(band, Paint()..color = IkkiuchiBoardStyle.bandFill);
    final rule = Paint()..color = IkkiuchiBoardStyle.bandRuleColor;
    const r = IkkiuchiBoardStyle.bandRule;
    canvas
      ..drawRect(Rect.fromLTWH(band.left, band.top, band.width, r), rule)
      ..drawRect(Rect.fromLTWH(band.left, band.bottom - r, band.width, r), rule);
    final text = scene.bandText;
    if (text == null) return;
    // The words were set for the band where the layout has it.
    final shift = band.center - scene.layout.band.center;
    canvas
      ..save()
      ..translate(shift.dx, shift.dy)
      ..drawPicture(text)
      ..restore();
  }

  void _paintTobi(Canvas canvas, IkkiuchiBoard board) {
    final tobi = scene.tobi;
    final k = tobi.k;
    final pose = board.pose;
    final idle = _idle(board.now);
    final face = pose?.face ?? board.idleFace;
    final body = pose?.body ?? idle.body;
    final feet = tobi.feet, pivot = tobi.pivot;
    canvas
      ..save()
      ..translate(feet.x + body.dx, feet.y + body.dy)
      ..rotate(body.rot)
      ..scale(body.sx, body.sy)
      ..translate(-pivot.x * k, -pivot.y * k);
    VectorPainter.paint(
      canvas,
      IkkiuchiTobiArt.art(face, without: pose?.arm),
      Offset.zero & Size(tobi.rig.size.x * k, tobi.rig.size.y * k),
      pixelRatio: pixelRatio * k,
      eyeOpen: pose == null ? idle.eyeOpen : 1,
    );
    canvas.restore();
    // His card in his hand, and set down until it waits for the player; the
    // card the player sent him where it was let go, in his hand, and laid
    // down until his arm is back; as the match opens, each card of his in
    // his hand and set down.
    final send = scene.send;
    if (send.stage == IkkiuchiSendStage.carrying || scene.opening.inHand != null) {
      if (board.carried case (id: final id, box: final box)) _paintFace(canvas, id, box);
    } else if (send.stage == IkkiuchiSendStage.placing) {
      final box = board.carried?.box ?? send.dropped;
      if (box != null) _paintFace(canvas, send.card!, box);
    }
    if (pose == null) return;
    Vec shoulderOf(IkkiuchiArmMove arm) => tobi.world(tobi.rig.arm(arm.armFace, arm.side).shoulder, body);
    if (board.carry case final carry? when board.carrying) {
      IkkiuchiArmPainter.paintArm(canvas, carry, carry.tau(board.carryTime), shoulderOf(carry), k);
      return;
    }
    final run = board.active;
    if (run == null) return;
    final strike = run.strike;
    final tau = strike.tau(run.at(board.now));
    final shoulder = shoulderOf(strike);
    if (scene.wind) {
      IkkiuchiArmPainter.paintWind(canvas, strike, tau, shoulder, k, strike.setup.target.hh);
      if (strike.move == IkkiuchiMove.smear) IkkiuchiArmPainter.paintSmear(canvas, strike, tau, shoulder, k);
    }
    IkkiuchiArmPainter.paintArm(canvas, strike, tau, shoulder, k);
  }

  /// Tobi between strikes: a gentle bob and now and then a blink.
  static ({TobiBody body, double eyeOpen}) _idle(double now) {
    final period = TobiStyle.bobPeriod.inMilliseconds;
    final phase = (now % period) / period;
    final e = Curves.easeInOutSine.transform(phase < 0.5 ? phase * 2 : 2 - phase * 2);
    final blink = now % TobiStyle.blinkEvery.inMilliseconds;
    final b = blink < TobiStyle.blinkLength.inMilliseconds ? blink / TobiStyle.blinkLength.inMilliseconds : 0.0;
    final closed = b == 0 ? 0.0 : 1 - (2 * b - 1).abs();
    return (
      body: TobiBody(1, 1, Tilt.bob * math.pi / 180 * e, 0, -TobiStyle.bobRise * e),
      eyeOpen: 1 - (1 - TobiStyle.blinkSquash) * closed,
    );
  }

  @override
  bool shouldRepaint(IkkiuchiBoardPainter old) => old.scene != scene || old.pixelRatio != pixelRatio;
}

/// The board on its tatami, its painter repainting with [scene] alone,
/// with the opening's, a 送り札's or 並べ替え's spots under its cards and
/// the rest of it over them ([IkkiuchiOpeningLayer], [IkkiuchiSendLayer],
/// [IkkiuchiArrangeLayer]), and [overCards] between, in board dp; [onTap]
/// gets each tap in board dp, and [onPointer] each pointer going down,
/// moving, and up or cancelled, its position in board dp. The match's own
/// [parts] lie over all that, their touches kept off the board, and the
/// cards the opening, a 送り札 or 並べ替え holds up lie over them.
class IkkiuchiBoardView extends StatelessWidget {
  const IkkiuchiBoardView(this.scene, {super.key, this.onTap, this.onPointer, this.overCards, this.parts});

  final IkkiuchiBoardScene scene;
  final ValueChanged<Offset>? onTap;
  final ValueChanged<PointerEvent>? onPointer;
  final Widget? overCards;
  final Widget? parts;

  @override
  Widget build(BuildContext context) {
    final onPointer = this.onPointer;
    final board = onPointer == null
        ? _tatami(context)
        : Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: onPointer,
            onPointerMove: onPointer,
            onPointerUp: onPointer,
            onPointerCancel: onPointer,
            child: _tatami(context),
          );
    if (parts == null && scene.sides == null) return board;
    return Stack(children: [
      board,
      if (parts case final parts?) Positioned.fill(child: parts),
      if (scene.sides != null) ...[
        Positioned.fill(child: IkkiuchiOpeningLayer(scene: scene, part: IkkiuchiLayerPart.top)),
        Positioned.fill(child: IkkiuchiSendLayer(scene: scene, part: IkkiuchiLayerPart.top)),
        Positioned.fill(child: IkkiuchiArrangeLayer(scene: scene, part: IkkiuchiLayerPart.top)),
      ],
    ]);
  }

  Widget _tatami(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTap == null ? null : (d) => onTap!(d.localPosition),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: IkkiuchiBoardStyle.ground,
            image: DecorationImage(
              image: AssetImage(IkkiuchiBoardStyle.tatami),
              repeat: ImageRepeat.repeat,
              scale: IkkiuchiBoardStyle.tatamiScale,
            ),
          ),
          child: Stack(children: [
            if (scene.sides != null) ...[
              Positioned.fill(child: IkkiuchiOpeningLayer(scene: scene, part: IkkiuchiLayerPart.under)),
              Positioned.fill(child: IkkiuchiSendLayer(scene: scene, part: IkkiuchiLayerPart.under)),
              Positioned.fill(child: IkkiuchiArrangeLayer(scene: scene, part: IkkiuchiLayerPart.under)),
            ],
            RepaintBoundary(
              child: CustomPaint(
                size: Size(scene.layout.size.x, scene.layout.size.y),
                painter: IkkiuchiBoardPainter(scene, pixelRatio: MediaQuery.devicePixelRatioOf(context)),
              ),
            ),
            if (overCards case final layer?) Positioned.fill(child: layer),
            if (scene.sides != null) ...[
              Positioned.fill(child: IkkiuchiOpeningLayer(scene: scene, part: IkkiuchiLayerPart.over)),
              Positioned.fill(child: IkkiuchiSendLayer(scene: scene, part: IkkiuchiLayerPart.over)),
              Positioned.fill(child: IkkiuchiArrangeLayer(scene: scene, part: IkkiuchiLayerPart.over)),
            ],
          ]),
        ),
      );
}
