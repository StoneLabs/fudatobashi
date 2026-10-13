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
final _label = _mono.copyWith(color: DebugOverlayStyle.labelColor);
final _head = _mono.copyWith(color: DebugOverlayStyle.headColor, fontWeight: FontWeight.bold);

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
    return DebugReadout(lines);
  }
}

/// Dev mode's corner readout: [lines] of monospace on a dark chip, never
/// taking taps.
class DebugReadout extends StatelessWidget {
  const DebugReadout(this.lines, {super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => _DebugPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final l in lines) Text(l, style: _mono)],
        ),
      );
}

/// One line of a [DebugTable]: a [label] and its [value]; a [head] line
/// starts a part of the table and stands out.
typedef DebugRow = ({String label, String value, bool head});

/// Dev mode's corner readout as a table, one fact a line: [rows] of labels
/// and values in two aligned columns on a dark chip, never taking taps.
class DebugTable extends StatelessWidget {
  const DebugTable(this.rows, {super.key});

  final List<DebugRow> rows;

  @override
  Widget build(BuildContext context) => _DebugPanel(
        child: Table(
          columnWidths: const {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
          children: [
            for (final r in rows)
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.only(right: DebugOverlayStyle.columnGap),
                  child: Text(r.label, style: r.head ? _head : _label),
                ),
                Text(r.value, style: r.head ? _head : _mono),
              ]),
          ],
        ),
      );
}

/// The dark chip under a dev-mode readout, letting every tap through.
class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DebugOverlayStyle.background,
            borderRadius: BorderRadius.circular(DebugOverlayStyle.radius),
          ),
          child: Padding(padding: DebugOverlayStyle.padding, child: child),
        ),
      );
}
