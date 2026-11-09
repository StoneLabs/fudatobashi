import 'dart:async';

import 'package:flutter/widgets.dart';

/// [child], which once held down long calls [onTap] at once and then
/// [every] so often until it is let go or [onTap] is gone; as it is without
/// [every].
class RepeatsHeld extends StatefulWidget {
  const RepeatsHeld({super.key, required this.onTap, required this.every, required this.child});

  final VoidCallback? onTap;
  final Duration? every;
  final Widget child;

  @override
  State<RepeatsHeld> createState() => _RepeatsHeldState();
}

class _RepeatsHeldState extends State<RepeatsHeld> {
  Timer? _timer;

  void _step() {
    final onTap = widget.onTap;
    if (onTap == null) return _stop();
    onTap();
  }

  void _start(Duration every) {
    _step();
    _timer = Timer.periodic(every, (_) => _step());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final every = widget.every;
    final repeats = every != null && widget.onTap != null;
    return GestureDetector(
      onLongPressStart: repeats ? (_) => _start(every) : null,
      onLongPressEnd: repeats ? (_) => _stop() : null,
      onLongPressCancel: repeats ? _stop : null,
      child: widget.child,
    );
  }
}
