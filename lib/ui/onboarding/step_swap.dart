import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// Shows the page [builder] makes for [step]. When [step] changes, the
/// pieces ([SwapPiece]) of the page on show slide off one side in turn while
/// the new page's pieces slide in from the other: a later step comes in from
/// the right, an earlier one from the left. Taps are ignored until it's over.
/// Under reduced motion the new page just appears.
class StepSwap extends StatefulWidget {
  const StepSwap({super.key, required this.step, required this.builder});

  final int step;
  final Widget Function(BuildContext context, int step) builder;

  @override
  State<StepSwap> createState() => _StepSwapState();
}

class _StepSwapState extends State<StepSwap> with SingleTickerProviderStateMixin {
  late final _swap = AnimationController(vsync: this, duration: OnboardingMotion.length)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _leaving = null);
    });

  /// The step sliding out while [_swap] runs.
  int? _leaving;

  @override
  void didUpdateWidget(StepSwap old) {
    super.didUpdateWidget(old);
    if (widget.step == old.step) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _swap.stop();
      _leaving = null;
    } else {
      _leaving = old.step;
      _swap.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaving = _leaving;
    return LayoutBuilder(builder: (context, box) {
      Widget page(int step) => _SwapScope(
            key: ValueKey(step),
            progress: _swap,
            leaving: leaving == null ? null : step == leaving,
            forward: leaving == null || widget.step > leaving,
            width: box.maxWidth,
            child: widget.builder(context, step),
          );
      return IgnorePointer(
        ignoring: leaving != null,
        child: Stack(
          fit: StackFit.expand,
          children: [if (leaving != null) page(leaving), page(widget.step)],
        ),
      );
    });
  }
}

class _SwapScope extends InheritedWidget {
  const _SwapScope({
    super.key,
    required this.progress,
    required this.leaving,
    required this.forward,
    required this.width,
    required super.child,
  });

  final Animation<double> progress;

  /// Whether this page is leaving or arriving; null when no swap is running.
  final bool? leaving;
  final bool forward;
  final double width;

  /// How far piece [order] is from its place, px (negative is left).
  double shift(int order) {
    final leaving = this.leaving;
    if (leaving == null) return 0;
    final start = OnboardingMotion.stagger * order + (leaving ? Duration.zero : OnboardingMotion.enterDelay);
    final length = leaving ? OnboardingMotion.exit : OnboardingMotion.enter;
    final elapsed = OnboardingMotion.length * progress.value - start;
    final t = (elapsed.inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);
    final away = width * (forward ? 1 : -1);
    return leaving ? -away * OnboardingMotion.exitCurve.transform(t) : away * (1 - OnboardingMotion.enterCurve.transform(t));
  }

  @override
  bool updateShouldNotify(_SwapScope old) =>
      old.progress != progress || old.leaving != leaving || old.forward != forward || old.width != width;
}

/// One piece of a [StepSwap] page; [order] counts from the top, and pieces
/// leave and arrive in that order. At rest outside a [StepSwap].
class SwapPiece extends StatelessWidget {
  const SwapPiece({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final swap = context.dependOnInheritedWidgetOfExactType<_SwapScope>();
    if (swap == null) return child;
    return AnimatedBuilder(
      animation: swap.progress,
      child: child,
      builder: (context, child) => Transform.translate(offset: Offset(swap.shift(order), 0), child: child),
    );
  }
}
