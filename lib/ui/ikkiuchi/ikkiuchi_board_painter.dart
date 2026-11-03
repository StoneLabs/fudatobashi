import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/card_mask.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../manga/vector.dart';
import '../torifuda/card_faces.dart';
import '../torifuda/torifuda_painter.dart';
import 'ikkiuchi_arm_painter.dart';
import 'ikkiuchi_board_layout.dart';
import 'ikkiuchi_effects.dart';
import 'ikkiuchi_tobi_art.dart';

/// Each card's face drawn once as an image, at the width it is shown.
class IkkiuchiCardFaces {
  IkkiuchiCardFaces({required this.showNumber});

  final bool showNumber;
  final _images = <(int, int), ui.Image>{};

  /// Card [poemId]'s face [width] device pixels wide.
  ui.Image of(int poemId, int width) => _images[(poemId, width)] ??= () {
        final height = (width * TorifudaSpec.height / TorifudaSpec.width).round();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const style = TorifudaStyle.standard;
        CardFaces.paint(canvas, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), style.background);
        canvas.drawPicture(
            TorifudaGlyphs.picture(poems[poemId], CardMask.none, width / TorifudaSpec.width, showNumber, style));
        return recorder.endRecording().toImageSync(width, height);
      }();

  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}

/// The 一騎打ち board as it is drawn: its [layout], the board running on it,
/// the call shown on the band, and the wind switch. Every change repaints
/// the board's painter, and nothing else.
class IkkiuchiBoardScene extends ChangeNotifier {
  IkkiuchiBoardScene(this.layout, this.faces) : board = _boardOf(layout);

  final IkkiuchiBoardLayout layout;
  final IkkiuchiCardFaces faces;
  IkkiuchiBoard board;

  /// The call on the band, the tag before it on a からふだ, and a small note
  /// under it.
  String? kimariji;
  String? karafuda;
  String? note;

  /// Whether the arm leaves wind lines and smear afterimages.
  bool wind = true;

  static IkkiuchiBoard _boardOf(IkkiuchiBoardLayout l) => IkkiuchiBoard(tobi: l.tobi, size: l.size, cards: l.cards);

  /// The board as it was set out, the band cleared.
  void reset() {
    board = _boardOf(layout);
    kimariji = karafuda = note = null;
    _band();
  }

  void advance(double ms) {
    board.advance(ms);
    notifyListeners();
  }

  /// A new call on the band, its note cleared.
  void show(String? kimariji, {String? karafuda}) {
    this.kimariji = kimariji;
    this.karafuda = karafuda;
    note = null;
    _band();
  }

  void annotate(String note) {
    this.note = note;
    _band();
  }

  /// The band's text, recorded once each time it changes.
  ui.Picture? get bandText => _bandText ??= _recordBand();
  ui.Picture? _bandText;

  void _band() {
    _bandText?.dispose();
    _bandText = null;
    notifyListeners();
  }

  ui.Picture? _recordBand() {
    final text = kimariji;
    if (text == null) return null;
    final band = layout.band;
    final dim = karafuda != null;
    final call = TextPainter(
      text: TextSpan(children: [
        if (karafuda case final tag?)
          TextSpan(
            text: tag + IkkiuchiBoardStyle.karafudaGap,
            style: const TextStyle(fontSize: IkkiuchiBoardStyle.karafudaTag),
          ),
        TextSpan(
          text: text,
          style: TextStyle(
              fontSize: layout.landscape ? IkkiuchiBoardStyle.kimarijiLandscape : IkkiuchiBoardStyle.kimarijiPortrait),
        ),
      ], style: TextStyle(
        fontFamily: Fonts.display,
        height: 1,
        color: dim ? IkkiuchiBoardStyle.karafudaColor : IkkiuchiBoardStyle.kimarijiColor,
      )),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: band.width);
    final small = note == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: note,
              style: const TextStyle(
                fontFamily: Fonts.ui,
                fontSize: IkkiuchiBoardStyle.noteFont,
                height: 1,
                color: IkkiuchiBoardStyle.noteColor,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: IkkiuchiBoardStyle.noteEllipsis,
          )..layout(maxWidth: band.width - 2 * IkkiuchiBoardStyle.pad));
    final height = call.height + (small == null ? 0 : IkkiuchiBoardStyle.noteGap + small.height);
    final top = band.center.dy - height / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    call.paint(canvas, Offset(band.center.dx - call.width / 2, top));
    small?.paint(canvas, Offset(band.center.dx - small.width / 2, top + call.height + IkkiuchiBoardStyle.noteGap));
    call.dispose();
    small?.dispose();
    return recorder.endRecording();
  }

  @override
  void dispose() {
    _bandText?.dispose();
    super.dispose();
  }
}

/// Paints the whole board in one go from its [scene]: the field's cards
/// (cached faces), the band, Tobi with his striking arm, and the effects.
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
    final shown = board.cards.cards.where((c) => c.onBoard).toList()
      ..sort((a, b) => (a.taken ? 1 : 0) - (b.taken ? 1 : 0));
    for (final card in shown) {
      _paintCard(canvas, card);
    }
    canvas.restore();
    _paintBand(canvas, scene.layout.band);
    canvas
      ..save()
      ..translate(shake.dx, shake.dy);
    _paintTobi(canvas, board);
    for (final hit in board.impacts) {
      IkkiuchiEffects.paintImpact(canvas, hit, now - hit.at);
    }
    // A fault is one fault however many cards the fist touched: one stamp,
    // on the first.
    if (board.faults.entries.firstOrNull case MapEntry(key: final id, value: final at)) {
      final card = board.cards.card(id);
      if (card.onBoard) IkkiuchiEffects.paintStamp(canvas, card.box, now - at);
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

  void _paintCard(Canvas canvas, IkkiuchiCard card) {
    final box = card.box;
    if (!card.still) IkkiuchiEffects.paintStreaks(canvas, box, card.velocity);
    final image = scene.faces.of(card.id, (box.hw * 2 * pixelRatio).round());
    canvas
      ..save()
      ..translate(box.centre.x, box.centre.y)
      ..rotate(box.angle)
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: box.hw * 2, height: box.hh * 2),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Palette.ink.withValues(alpha: card.shown),
      )
      ..restore();
  }

  void _paintBand(Canvas canvas, Rect band) {
    canvas.drawRect(band, Paint()..color = IkkiuchiBoardStyle.bandFill);
    final rule = Paint()..color = IkkiuchiBoardStyle.bandRuleColor;
    const r = IkkiuchiBoardStyle.bandRule;
    canvas
      ..drawRect(Rect.fromLTWH(band.left, band.top, band.width, r), rule)
      ..drawRect(Rect.fromLTWH(band.left, band.bottom - r, band.width, r), rule);
    final text = scene.bandText;
    if (text != null) canvas.drawPicture(text);
  }

  void _paintTobi(Canvas canvas, IkkiuchiBoard board) {
    final tobi = board.tobi;
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
    final run = board.active;
    if (run == null || pose == null) return;
    final strike = run.strike;
    final tau = strike.tau(run.at(board.now));
    final shoulder = tobi.world(tobi.rig.arm(TobiFace.reaching, strike.side).shoulder, body);
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

/// The board on its tatami, its painter repainting with [scene] alone;
/// [onTap] gets each tap in board dp.
class IkkiuchiBoardView extends StatelessWidget {
  const IkkiuchiBoardView(this.scene, {super.key, this.onTap});

  final IkkiuchiBoardScene scene;
  final ValueChanged<Offset>? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(scene.layout.size.x, scene.layout.size.y),
              painter: IkkiuchiBoardPainter(scene, pixelRatio: MediaQuery.devicePixelRatioOf(context)),
            ),
          ),
        ),
      );
}
