import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../manga/lines.dart';
import '../manga/seeded_random.dart';

/// The 一騎打ち board's effects, drawn on a canvas in board dp: the burst and
/// lettering of a hit, the speed lines behind a sliding card, and the
/// お手つき stamp on a faulted card. Text is recorded once and replayed.
abstract final class IkkiuchiEffects {
  static final _sfx = <(String, double), (ui.Picture, Size)>{};
  static (ui.Picture, Size)? _stamp;

  /// A hit [age] ms after it landed: a paper flash, a burst of focus lines
  /// growing as it fades, and its lettering popping in, set off against
  /// the way out from Tobi's reach.
  static void paintImpact(Canvas canvas, IkkiuchiImpact hit, double age) {
    final out = hit.out;
    final big = hit.move == IkkiuchiMove.smear, clean = hit.move == IkkiuchiMove.sweep;
    final life = big ? IkkiuchiArmStyle.lifeBigMs : IkkiuchiArmStyle.lifeMs;
    if (age < 0 || age > life) return;
    final p = age / life;
    final size = big ? IkkiuchiArmStyle.sizeBig : (clean ? IkkiuchiArmStyle.sizeClean : IkkiuchiArmStyle.sizeSmall);
    canvas
      ..save()
      ..translate(hit.point.x, hit.point.y);
    final flash = big ? IkkiuchiArmStyle.flashBigMs : IkkiuchiArmStyle.flashMs;
    if (!clean && age < flash) {
      final r = size * (big ? IkkiuchiArmStyle.flashBigShare : IkkiuchiArmStyle.flashShare) * (IkkiuchiArmStyle.flashGrow + p);
      canvas
        ..drawCircle(Offset.zero, r, Paint()..color = Palette.paper)
        ..drawCircle(
            Offset.zero,
            r,
            Paint()
              ..color = IkkiuchiArmStyle.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = IkkiuchiArmStyle.flashStroke);
    }
    final spec = big ? IkkiuchiArmStyle.burstBig : (clean ? IkkiuchiArmStyle.burstClean : IkkiuchiArmStyle.burstSmall);
    final fade = 1 - ((p - IkkiuchiArmStyle.burstFade) / (1 - IkkiuchiArmStyle.burstFade)).clamp(0.0, 1.0);
    final grow = ui.lerpDouble(IkkiuchiArmStyle.burstFrom, IkkiuchiArmStyle.burstTo, Curves.easeOutCubic.transform(p))!;
    canvas
      ..save()
      ..scale(grow)
      ..translate(-spec.center.dx, -spec.center.dy)
      ..drawPath(FocusLines.path(spec.reseeded(hit.card), spec.box),
          Paint()..color = IkkiuchiArmStyle.ink.withValues(alpha: fade))
      ..restore()
      ..restore();

    final (picture, box) = _lettering(clean ? IkkiuchiArmStyle.sfxSweep : IkkiuchiArmStyle.sfx,
        big ? IkkiuchiArmStyle.sfxBigSize : IkkiuchiArmStyle.sfxSize);
    final pop = age < IkkiuchiArmStyle.sfxPopMs
        ? ui.lerpDouble(IkkiuchiArmStyle.sfxPop, 1, Curves.easeOutCubic.transform(age / IkkiuchiArmStyle.sfxPopMs))!
        : 1.0;
    final alpha = 1 - ((p - (1 - IkkiuchiArmStyle.sfxFade)) / IkkiuchiArmStyle.sfxFade).clamp(0.0, 1.0);
    final at = hit.point + Vec(-out.x * IkkiuchiArmStyle.sfxOut + IkkiuchiArmStyle.sfxAcross, -IkkiuchiArmStyle.sfxUp);
    canvas
      ..save()
      ..translate(at.x, at.y)
      ..rotate(IkkiuchiArmStyle.sfxTurn)
      ..scale(pop)
      ..translate(-box.width / 2, -box.height / 2)
      ..saveLayer(Offset.zero & box, Paint()..color = Palette.ink.withValues(alpha: alpha))
      ..drawPicture(picture)
      ..restore()
      ..restore();
  }

  /// Sound-effect lettering, each character jittered, scaled and turned as
  /// [SfxStyle] says, in [IkkiuchiArmStyle.sfxColor] with an ink outline
  /// and a paper halo.
  static (ui.Picture, Size) _lettering(String text, double fontSize) => _sfx[(text, fontSize)] ??= () {
        final r = SeededRandom(text.hashCode);
        final glyphs = [
          for (final (i, ch) in text.characters.indexed)
            (
              ch: ch,
              scale: i == 0 ? SfxStyle.firstScale : SfxStyle.scaleMin + r.next() * SfxStyle.scaleRange,
              turn: (r.next() - 0.5) * SfxStyle.rotationDeg * math.pi / 180,
              shift: (r.next() - 0.5) * SfxStyle.shift,
            ),
        ];
        TextPainter layer(String ch, Paint? stroke) => TextPainter(
              text: TextSpan(
                text: ch,
                style: TextStyle(
                  fontFamily: Fonts.sfx,
                  fontSize: fontSize,
                  height: 1,
                  foreground: stroke,
                  color: stroke == null ? IkkiuchiArmStyle.sfxColor : null,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
        Paint outline(double width, Color color) => Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..color = color;
        final halo = SfxStyle.outline + SfxStyle.halo;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        var x = halo / 2;
        for (final g in glyphs) {
          final layers = [
            layer(g.ch, outline(halo, Palette.paper)),
            layer(g.ch, outline(SfxStyle.outline, Palette.ink)),
            layer(g.ch, null),
          ];
          final w = layers.last.width, h = layers.last.height;
          canvas
            ..save()
            ..translate(x + w / 2, halo / 2 + h / 2 + g.shift)
            ..rotate(g.turn)
            ..scale(g.scale)
            ..translate(-w / 2, -h / 2);
          for (final tp in layers) {
            tp
              ..paint(canvas, Offset.zero)
              ..dispose();
          }
          canvas.restore();
          x += w * (1 + SfxStyle.overlap);
        }
        return (recorder.endRecording(), Size(x + halo / 2, fontSize + halo));
      }();

  /// Speed lines behind a card [box] sliding at [velocity]: tapered ink
  /// streaks trailing from its back, longer the faster it goes.
  static void paintStreaks(Canvas canvas, CardBox box, Vec velocity) {
    final speed = velocity.length;
    if (speed < IkkiuchiBoardStyle.streakMinSpeed) return;
    final dir = velocity * (1 / speed);
    final nrm = dir.perp;
    final length = math.min(IkkiuchiBoardStyle.streakMax, speed * IkkiuchiBoardStyle.streakPerSpeed);
    final reach = box.reachAlong(nrm), back = box.reachAlong(dir);
    final paint = Paint()
      ..color = IkkiuchiArmStyle.ink.withValues(
          alpha: ((speed - IkkiuchiBoardStyle.streakMinSpeed) / IkkiuchiBoardStyle.streakFullOver).clamp(0.0, 1.0));
    for (final (across, share, width) in IkkiuchiBoardStyle.streaks) {
      final start = box.centre + nrm * (across * reach) + dir * (-back - IkkiuchiBoardStyle.streakBack);
      final end = start + dir * (-length * share);
      final side = nrm * (width / 2);
      canvas.drawPath(
        Path()
          ..moveTo(start.x + side.x, start.y + side.y)
          ..lineTo(end.x, end.y)
          ..lineTo(start.x - side.x, start.y - side.y)
          ..close(),
        paint,
      );
    }
  }

  /// The お手つき stamp over the card [box], [age] ms after the fault.
  static void paintStamp(Canvas canvas, CardBox box, double age) {
    final (picture, size) = _stamp ??= () {
      final tp = TextPainter(
        text: const TextSpan(
          text: IkkiuchiBoardStyle.stamp,
          style: TextStyle(
            fontFamily: Fonts.ui,
            fontWeight: Weights.black,
            fontSize: IkkiuchiBoardStyle.stampFont,
            height: 1,
            color: IkkiuchiBoardStyle.stampInk,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final size = Size(tp.width + 2 * IkkiuchiBoardStyle.stampPadding, IkkiuchiBoardStyle.stampHeight);
      final recorder = ui.PictureRecorder();
      final rect = Offset.zero & size;
      final canvas = Canvas(recorder)
        ..drawRect(rect, Paint()..color = IkkiuchiBoardStyle.stampFill)
        ..drawRect(
            rect,
            Paint()
              ..color = IkkiuchiBoardStyle.stampBorder
              ..style = PaintingStyle.stroke
              ..strokeWidth = IkkiuchiBoardStyle.stampBorderWidth);
      tp
        ..paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2))
        ..dispose();
      return (recorder.endRecording(), size);
    }();
    final pop = age < IkkiuchiBoardStyle.stampPopMs
        ? ui.lerpDouble(IkkiuchiBoardStyle.stampPop, 1, Curves.easeOutCubic.transform(age / IkkiuchiBoardStyle.stampPopMs))!
        : 1.0;
    canvas
      ..save()
      ..translate(box.centre.x, box.centre.y - box.reachAlong(const Vec(0, 1)) - IkkiuchiBoardStyle.stampLift)
      ..rotate(IkkiuchiBoardStyle.stampTurn)
      ..scale(pop)
      ..translate(-size.width / 2, -size.height / 2)
      ..drawPicture(picture)
      ..restore();
  }
}
