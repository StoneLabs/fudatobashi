import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'labels.dart';

/// A short narration box that drops in near the bottom of the screen and
/// leaves by itself.
abstract final class MangaToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _Toast(message, onDone: () {
          if (_current == entry) _current = null;
          entry.remove();
        }));
    _current = entry;
    overlay.insert(entry);
  }
}

class _Toast extends StatefulWidget {
  const _Toast(this.message, {required this.onDone});
  final String message;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
    _timer = Timer(ToastStyle.hold, () {
      if (mounted) setState(() => _shown = false);
      _timer = Timer(ToastStyle.fade, widget.onDone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + ToastStyle.bottom;
    return Positioned(
      left: Gaps.gutter,
      right: Gaps.gutter,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, ToastStyle.slide),
          duration: ToastStyle.fade,
          curve: Motion.routeCurve,
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: ToastStyle.fade,
            child: Center(child: NarrationBox(child: Text(widget.message, textAlign: TextAlign.center))),
          ),
        ),
      ),
    );
  }
}
