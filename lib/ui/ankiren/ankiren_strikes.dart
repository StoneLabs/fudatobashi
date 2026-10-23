import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A free-play level's strikes, [count] of them ([AnkirenTuning.strikesOut]
/// unless another; later strikes add no card), as small torifuda [cardHeight] tall: face down for each
/// strike still to come, and each landed one turned face up with a red
/// slash over it. A new strike turns its card over, stamps the slash and
/// shakes the card (see [AnkirenMotion.strike]); under reduced motion it
/// simply shows.
class AnkirenStrikes extends StatefulWidget {
  const AnkirenStrikes({
    super.key,
    required this.strikes,
    required this.cardHeight,
    this.count = AnkirenTuning.strikesOut,
  });

  final int strikes;
  final double cardHeight;
  final int count;

  @override
  State<AnkirenStrikes> createState() => _AnkirenStrikesState();
}

class _AnkirenStrikesState extends State<AnkirenStrikes> with SingleTickerProviderStateMixin {
  late final _landing = AnimationController(vsync: this, duration: AnkirenMotion.strike, value: 1);

  @override
  void didUpdateWidget(AnkirenStrikes old) {
    super.didUpdateWidget(old);
    if (widget.strikes > old.strikes && old.strikes < widget.count && !MediaQuery.disableAnimationsOf(context)) _landing.forward(from: 0);
  }

  @override
  void dispose() {
    _landing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final out = widget.count;
    final strikes = math.min(widget.strikes, out);
    final box = AnkirenArt.strikeBack.box;
    final size = Size(widget.cardHeight * box.width / box.height, widget.cardHeight);
    return Semantics(
      label: S.of(context).ankirenStrikesLabel(strikes, out),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _landing,
        builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < out; i++) ...[
            if (i > 0) const SizedBox(width: AnkirenPlayLayout.strikeGap),
            i == strikes - 1 ? _Landing(size, _landing.value) : _Card(size, struck: i < strikes),
          ],
        ]),
      ),
    );
  }
}

/// One strike card at rest: face down, or [struck].
class _Card extends StatelessWidget {
  const _Card(this.size, {required this.struck});

  final Size size;
  final bool struck;

  @override
  Widget build(BuildContext context) => struck
      ? Stack(children: [
          VectorArtBox(AnkirenArt.strikeFace, size: size),
          VectorArtBox(AnkirenArt.strikeSlash, size: size),
        ])
      : VectorArtBox(AnkirenArt.strikeBack, size: size);
}

/// The card of the strike that landed last, [t] of the way through its
/// landing: turning over, then the slash stamping in, then the shake.
class _Landing extends StatelessWidget {
  const _Landing(this.size, this.t);

  final Size size;
  final double t;

  @override
  Widget build(BuildContext context) {
    const flip = AnkirenMotion.strikeFlipShare, stamp = AnkirenMotion.strikeStampShare;
    if (t < flip) {
      final turn = math.cos(math.pi * t / flip);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(turn.abs(), 1, 1),
        child: turn > 0
            ? VectorArtBox(AnkirenArt.strikeBack, size: size)
            : VectorArtBox(AnkirenArt.strikeFace, size: size),
      );
    }
    final stamped = Curves.easeOutBack.transform(((t - flip) / (stamp - flip)).clamp(0.0, 1.0));
    final shaking = ((t - stamp) / (1 - stamp)).clamp(0.0, 1.0);
    final shake = AnkirenMotion.strikeShakeReach *
        (1 - shaking) *
        math.sin(shaking * AnkirenMotion.strikeShakes * 2 * math.pi);
    final scale = AnkirenMotion.strikeStampFrom + (1 - AnkirenMotion.strikeStampFrom) * stamped;
    return Transform.translate(
      offset: Offset(shake, 0),
      child: Stack(clipBehavior: Clip.none, children: [
        VectorArtBox(AnkirenArt.strikeFace, size: size),
        Opacity(
          opacity: (stamped * 2).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: VectorArtBox(AnkirenArt.strikeSlash, size: size)),
        ),
      ]),
    );
  }
}

/// A cleared free-play level's mark: a white check on a green disc with an
/// ink rim, [size] across.
class ClearedCheck extends StatelessWidget {
  const ClearedCheck({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AnkirenClearStyle.fill,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.ink, width: size * AnkirenClearStyle.rimShare),
          ),
          child: Center(
            child: MangaIcon(IconArt.check,
                size: size * AnkirenClearStyle.iconShare,
                color: Palette.paper,
                strokeWidth: AnkirenClearStyle.iconStroke),
          ),
        ),
      );
}
