import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// Tobi holding the spot for a screen that is still being built.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox.fromSize(
          size: ComingSoonStyle.box,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Placed(ComingSoonStyle.tobi, child: Tobi(pose: TobiPose.pointing)),
              Placed(
                ComingSoonStyle.balloon,
                child: SpeechBalloon(
                  speaker: ComingSoonStyle.speaker,
                  child: Text(message, style: const TextStyle(fontSize: TypeScale.button)),
                ),
              ),
            ],
          ),
        ),
      );
}

/// A "coming soon" balloon that pops out of a tapped control for a moment,
/// for features that are not built yet.
abstract final class ComingSoonBubble {
  static OverlayEntry? _shown;

  /// Pops the balloon over the widget [context] belongs to.
  static void show(BuildContext context) {
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || !box.hasSize || overlay == null) return;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final anchor = MatrixUtils.transformRect(box.getTransformTo(overlayBox), Offset.zero & box.size);
    final message = S.of(context).comingSoon;
    _shown?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Bubble(
        anchor: anchor,
        message: message,
        onDone: () {
          if (_shown != entry) return;
          entry.remove();
          _shown = null;
        },
      ),
    );
    _shown = entry;
    overlay.insert(entry);
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({required this.anchor, required this.message, required this.onDone});
  final Rect anchor;
  final String message;
  final VoidCallback onDone;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final _life = AnimationController(vsync: this, duration: ComingSoonStyle.bubbleLife)
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = ComingSoonStyle.bubble;
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final a = widget.anchor;
    final above = a.top - size.height - ComingSoonStyle.bubbleGap >= safeTop;
    final left = (a.center.dx - size.width / 2).clamp(Gaps.gutter, screen.width - size.width - Gaps.gutter);
    final top = above ? a.top - size.height - ComingSoonStyle.bubbleGap : a.bottom + ComingSoonStyle.bubbleGap;
    final target = Offset(a.center.dx, above ? a.top : a.bottom);
    final speaker = Alignment((target.dx - left) / size.width * 2 - 1, (target.dy - top) / size.height * 2 - 1);
    final still = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _life,
          builder: (context, child) {
            final elapsed = ComingSoonStyle.bubbleLife * _life.value;
            final popIn = (elapsed.inMicroseconds / ComingSoonStyle.bubblePop.duration.inMicroseconds).clamp(0.0, 1.0);
            final fadeOut = ((ComingSoonStyle.bubbleLife - elapsed).inMicroseconds /
                    ComingSoonStyle.bubbleFade.inMicroseconds)
                .clamp(0.0, 1.0);
            return Opacity(
              opacity: fadeOut,
              child: EntranceFrame(
                from: ComingSoonStyle.bubblePop.from,
                progress: still ? 1 : ComingSoonStyle.bubblePop.curve.transform(popIn),
                child: child!,
              ),
            );
          },
          child: SpeechBalloon(
            speaker: speaker,
            color: Palette.sun,
            child: Text(widget.message, style: const TextStyle(fontSize: TypeScale.button)),
          ),
        ),
      ),
    );
  }
}
