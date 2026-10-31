import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// What a tap on a field card did, to show on it.
enum CardFeedback { right, wrong }

/// A [CardFeedback] to play once: a new [serial] plays it again.
class CardFlash {
  const CardFlash(this.kind, this.serial);

  final CardFeedback kind;
  final int serial;
}

/// One 暗記練 field card: the torifuda face up ([inverted] turns it 180°),
/// or a plain back face down, turning over whenever [faceUp] changes, with
/// its [flash] and [revealed] shown on it as [TapFeedback] shows them.
class AnkirenCard extends StatefulWidget {
  const AnkirenCard({
    super.key,
    required this.poemId,
    required this.faceUp,
    required this.inverted,
    required this.showNumber,
    this.flash,
    this.revealed = false,
  });

  final int poemId;
  final bool faceUp;
  final bool inverted;
  final bool showNumber;
  final CardFlash? flash;
  final bool revealed;

  @override
  State<AnkirenCard> createState() => _AnkirenCardState();
}

class _AnkirenCardState extends State<AnkirenCard> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: AnkirenMotion.flip, value: 1);

  @override
  void didUpdateWidget(AnkirenCard old) {
    super.didUpdateWidget(old);
    if (old.faceUp != widget.faceUp) {
      MediaQuery.disableAnimationsOf(context) ? _turn.value = 1 : _turn.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = TorifudaCard(poem: poems[widget.poemId], inverted: widget.inverted, showNumber: widget.showNumber);
    const back = DecoratedBox(
      decoration: BoxDecoration(
        color: AnkirenPlayLayout.backFill,
        border: Border.fromBorderSide(
            BorderSide(color: AnkirenPlayLayout.backBorder, width: AnkirenPlayLayout.backBorderWidth)),
      ),
    );
    return TapFeedback(
      flash: widget.flash,
      revealed: widget.revealed,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) {
          // The first half of the turn narrows the side that was showing, the
          // second widens the new one.
          final t = _turn.value;
          final showingUp = t < 0.5 ? !widget.faceUp : widget.faceUp;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values((t - 0.5).abs() * 2, 1, 1),
            child: showingUp ? face : back,
          );
        },
      ),
    );
  }
}

/// What a tap did, on what was tapped ([child]: a field card, or the
/// からふだ button): a new [flash] plays a right tap's glow, or a wrong one's
/// red tint and shake; while [revealed] it rumbles in place (a steady
/// outline under reduced motion, which also drops the shake).
class TapFeedback extends StatefulWidget {
  const TapFeedback({super.key, required this.child, this.flash, this.revealed = false});

  final Widget child;
  final CardFlash? flash;
  final bool revealed;

  @override
  State<TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<TapFeedback> with SingleTickerProviderStateMixin {
  late final _flash = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(TapFeedback old) {
    super.didUpdateWidget(old);
    final flash = widget.flash;
    if (flash != null && flash.serial != old.flash?.serial) {
      _flash.duration = flash.kind == CardFeedback.right ? AnkirenMotion.rightGlow : AnkirenMotion.wrongFlash;
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget shown = AnimatedBuilder(
      animation: _flash,
      child: widget.child,
      builder: (context, child) {
        final f = _flash.value;
        final kind = widget.flash?.kind;
        final fading = f < 1 ? 1 - f : 0.0;
        final shake = kind == CardFeedback.wrong && !still
            ? math.sin(f * AnkirenMotion.wrongShakes * 2 * math.pi) * AnkirenMotion.wrongShakeReach * fading
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(fit: StackFit.passthrough, children: [
            child!,
            if (fading > 0 && kind == CardFeedback.wrong) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                      color: AnkirenPlayLayout.wrongTint.withValues(alpha: AnkirenPlayLayout.wrongTintOpacity * fading)),
                ),
              ),
              _Outline(AnkirenPlayLayout.wrongTint.withValues(alpha: fading)),
            ],
            if (fading > 0 && kind == CardFeedback.right)
              _Outline(AnkirenPlayLayout.rightGlow.withValues(alpha: fading)),
            if (widget.revealed && still) const _Outline(AnkirenPlayLayout.revealGlow),
          ]),
        );
      },
    );
    if (widget.revealed && !still) {
      shown = Shake(
        reach: AnkirenMotion.revealShakeReach,
        step: AnkirenMotion.revealShakeStep,
        seed: AnkirenMotion.revealShakeSeed,
        child: shown,
      );
    }
    return RepaintBoundary(child: shown);
  }
}

/// A coloured outline over a card, in its [Stack].
class _Outline extends StatelessWidget {
  const _Outline(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: color, width: AnkirenPlayLayout.glowWidth)),
            ),
          ),
        ),
      );
}
