import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../manga/vector.dart';
import 'ikkiuchi_reader.dart';

/// The call in the gap between the sides in landscape: paper words on a
/// see-through strip that fades out toward both ends, as tall as it is
/// laid out. It shows the [reader]'s call sound by sound as each is heard,
/// each kana opening its room and popping in so the words grow from the
/// middle; or, instead of the call, a [prompt]: its title and what to do.
/// Once nothing is read the last words fade out.
class IkkiuchiCallStrip extends StatefulWidget {
  const IkkiuchiCallStrip({super.key, required this.reader, this.prompt, this.shimonoku});

  final IkkiuchiReader reader;
  final ({String title, String line})? prompt;
  final ({String word, double share})? shimonoku;

  @override
  State<IkkiuchiCallStrip> createState() => _IkkiuchiCallStripState();
}

class _IkkiuchiCallStripState extends State<IkkiuchiCallStrip> {
  /// The words shown last, kept while they fade out.
  Widget? _shown;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.reader,
        builder: (context, _) {
          final words = _words();
          if (words != null) _shown = words;
          return AnimatedOpacity(
            opacity: words == null ? 0 : 1,
            duration: IkkiuchiCallStyle.fadeOut,
            child: _shown == null ? const SizedBox.shrink() : IkkiuchiStrip(child: _shown!),
          );
        },
      );

  /// The words to show now: the 下の句, the prompt, or the sounds heard of
  /// the call; null with none.
  Widget? _words() {
    if (widget.shimonoku case (:final word, :final share)) return IkkiuchiShimonokuWords(word: word, share: share);
    if (widget.prompt case (:final title, :final line)) return _Prompt(title: title, line: line);
    final reader = widget.reader;
    final call = reader.call;
    if (call == null || reader.heard == 0) return null;
    return Row(
      key: ValueKey(reader.serial),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < reader.heard; i++) _Sound(call.sounds[i], key: ValueKey(i)),
      ],
    );
  }

}

/// The see-through strip behind the words, solid under them and
/// [IkkiuchiCallStyle.inset] beyond, fading out over
/// [IkkiuchiCallStyle.fade] at each end.
class IkkiuchiStrip extends StatelessWidget {
  const IkkiuchiStrip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _StripPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: IkkiuchiCallStyle.fade + IkkiuchiCallStyle.inset),
          child: Center(widthFactor: 1, child: child),
        ),
      );
}

class _StripPainter extends CustomPainter {
  const _StripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fade = IkkiuchiCallStyle.fade / size.width;
    final clear = IkkiuchiCallStyle.fill.withValues(alpha: 0);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [clear, IkkiuchiCallStyle.fill, IkkiuchiCallStyle.fill, clear],
          stops: [0, fade, 1 - fade, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_StripPainter old) => false;
}

/// A sound of the call as it is heard: its room opens from nothing as it
/// pops in from [IkkiuchiCallStyle.kanaPop] its size.
class _Sound extends StatelessWidget {
  const _Sound(this.text, {super.key});

  final String text;

  static const _style = TextStyle(
    fontFamily: Fonts.display,
    fontSize: IkkiuchiCallStyle.kimariji,
    height: 1,
    color: IkkiuchiCallStyle.ink,
  );

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: IkkiuchiCallStyle.kanaIn,
        curve: IkkiuchiCallStyle.kanaCurve,
        child: Text(text, style: _style),
        builder: (context, t, child) => Align(
          widthFactor: t,
          child: Opacity(
            opacity: t,
            child: Transform.scale(scale: lerpDouble(IkkiuchiCallStyle.kanaPop, 1, t), child: child),
          ),
        ),
      );
}

/// A prompt: its title in display lettering, a dot, then what to do.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.title, required this.line});

  final String title, line;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(title,
            style: const TextStyle(
                fontFamily: Fonts.display, fontSize: IkkiuchiCallStyle.title, height: 1, color: IkkiuchiCallStyle.ink)),
        const SizedBox(width: IkkiuchiCallStyle.dotGap),
        const Text(IkkiuchiCallStyle.dot,
            style: TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiCallStyle.line, color: IkkiuchiCallStyle.lineInk)),
        const SizedBox(width: IkkiuchiCallStyle.dotGap),
        Text(line,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
                fontFamily: Fonts.ui,
                fontWeight: Weights.black,
                fontSize: IkkiuchiCallStyle.line,
                height: 1,
                color: IkkiuchiCallStyle.lineInk)),
      ]);
}

/// The 下の句 being read: its [word] and the 余韻 mark lying along the line,
/// wiped away from the left by [share] (0 all shown, 1 none) of it played,
/// in [ink].
class IkkiuchiShimonokuWords extends StatelessWidget {
  const IkkiuchiShimonokuWords(
      {super.key, required this.word, required this.share, this.ink = IkkiuchiCallStyle.ink});

  final String word;
  final double share;
  final Color ink;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final edge = IkkiuchiCallStyle.shimonokuEdge, front = share * (bounds.width + edge);
          return LinearGradient(
            colors: const [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
            stops: [0, ((front - edge) / bounds.width).clamp(0, 1), (front / bounds.width).clamp(0, 1), 1],
          ).createShader(bounds);
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(word,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: IkkiuchiCallStyle.kimariji,
                  height: 1,
                  color: ink)),
          const SizedBox(width: IkkiuchiCallStyle.shimonokuGap),
          RotatedBox(
            quarterTurns: 3,
            child: VectorArtBox(CardArt.yomifudaEnd,
                size: const Size(IkkiuchiCallStyle.kimariji, IkkiuchiCallStyle.shimonokuTail), color: ink),
          ),
        ]),
      );
}
