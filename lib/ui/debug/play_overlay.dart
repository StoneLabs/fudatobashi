import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../domain/play_session.dart';
import 'frame_stats.dart';

const _mono = TextStyle(
  fontFamily: 'monospace',
  fontSize: DebugOverlayStyle.fontSize,
  color: DebugOverlayStyle.textColor,
  height: DebugOverlayStyle.lineHeight,
);

/// A small corner readout for dev mode: the last attempt's response time,
/// outcome and taint, plus a live frame-time summary. Refreshes on its own
/// timer so it never adds work to the play/swipe frame path.
class PlayDebugOverlay extends StatefulWidget {
  const PlayDebugOverlay({super.key, required this.session});

  final PlaySession session;

  @override
  State<PlayDebugOverlay> createState() => _PlayDebugOverlayState();
}

class _PlayDebugOverlayState extends State<PlayDebugOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(DebugOverlayStyle.refresh, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.session.lastAttempt;
    final f = FrameStats.instance.summary();
    final lines = [
      if (a == null) 'no attempts yet' else '${(a.responseUs / 1000).toStringAsFixed(1)} ms  ${a.outcome.name}'
          '${a.tainted ? '  tainted' : ''}${a.wrong ? '  wrong' : ''}',
      'build ${f.avgBuildMs.toStringAsFixed(1)}  raster ${f.avgRasterMs.toStringAsFixed(1)} ms'
          '  jank ${f.jankPct.toStringAsFixed(0)}%',
    ];
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DebugOverlayStyle.background,
          borderRadius: BorderRadius.circular(DebugOverlayStyle.radius),
        ),
        child: Padding(
          padding: DebugOverlayStyle.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final l in lines) Text(l, style: _mono)],
          ),
        ),
      ),
    );
  }
}
