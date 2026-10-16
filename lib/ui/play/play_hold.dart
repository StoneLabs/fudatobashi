import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/play_session.dart';

/// Holds play while the app is hidden or a sheet is over the deck: the card
/// on screen is interrupted (see [PlaySession.interrupt]) and shown afresh
/// once play goes on, so the time away never counts as card time.
mixin PlayHold<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycle;
  bool _hidden = false;
  int _sheets = 0;

  PlaySession get heldSession;

  /// Play is held: the deck shows no card.
  bool get held => _hidden || _sheets > 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => _setHidden(true), onShow: () => _setHidden(false));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _setHidden(bool hidden) {
    if (!mounted) return;
    if (hidden) heldSession.interrupt();
    setState(() => _hidden = hidden);
  }

  /// Holds play while [sheet] is up.
  Future<R> holdFor<R>(Future<R> Function() sheet) async {
    heldSession.interrupt();
    setState(() => _sheets++);
    try {
      return await sheet();
    } finally {
      if (mounted) setState(() => _sheets--);
    }
  }
}
