import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'balloon.dart';
import 'entrance.dart';

/// A speech balloon that pops out of a tapped control for a moment ("coming
/// soon", why a button is locked), [size] across, for [life].
abstract final class BalloonPop {
  static OverlayEntry? _shown;

  /// Pops [message] over the widget [context] belongs to.
  static void show(
    BuildContext context,
    String message, {
    Size size = BalloonPopStyle.size,
    Duration life = BalloonPopStyle.life,
  }) {
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || !box.hasSize || overlay == null) return;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final anchor = MatrixUtils.transformRect(box.getTransformTo(overlayBox), Offset.zero & box.size);
    _shown?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Bubble(
        anchor: anchor,
        message: message,
        size: size,
        life: life,
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
  const _Bubble({
    required this.anchor,
    required this.message,
    required this.size,
    required this.life,
    required this.onDone,
  });
  final Rect anchor;
  final String message;
  final Size size;
  final Duration life;
  final VoidCallback onDone;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final _life = AnimationController(vsync: this, duration: widget.life)
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final a = widget.anchor;
    final above = a.top - size.height - BalloonPopStyle.gap >= safeTop;
    final left = (a.center.dx - size.width / 2).clamp(Gaps.gutter, screen.width - size.width - Gaps.gutter);
    final top = above ? a.top - size.height - BalloonPopStyle.gap : a.bottom + BalloonPopStyle.gap;
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
            final elapsed = widget.life * _life.value;
            final popIn = (elapsed.inMicroseconds / BalloonPopStyle.pop.duration.inMicroseconds).clamp(0.0, 1.0);
            final fadeOut =
                ((widget.life - elapsed).inMicroseconds / BalloonPopStyle.fade.inMicroseconds).clamp(0.0, 1.0);
            return Opacity(
              opacity: fadeOut,
              child: EntranceFrame(
                from: BalloonPopStyle.pop.from,
                progress: still ? 1 : BalloonPopStyle.pop.curve.transform(popIn),
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
