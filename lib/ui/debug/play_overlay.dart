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

/// A small corner readout for dev mode: the last attempt's card time, how
/// it was counted (see `CardTime`), outcome and taint, plus a live
/// frame-time summary. Refreshes on its own timer so it never adds work to
/// the play/swipe frame path.
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
    final t = a?.time;
    final lines = [
      if (a == null || t == null)
        'no attempts yet'
      else ...[
        'card time      ${_ms(t.us)}  ${a.outcome.name}${a.tainted ? '  tainted' : ''}${a.wrong ? '  wrong' : ''}',
        'reaction       ${_ms(t.reactionUs)}  shown to touch',
        'swipe          ${_ms(t.gestureUs)}  touch to let go',
        'thinking added ${_ms(t.extraUs)}  swipe over ${_ms(SwipeTuning.gestureBudget.inMicroseconds)}',
      ],
      'build ${f.avgBuildMs.toStringAsFixed(1)}  raster ${f.avgRasterMs.toStringAsFixed(1)} ms'
          '  jank ${f.jankPct.toStringAsFixed(0)}%',
    ];
    return DebugReadout(lines);
  }
}

String _ms(int us) => '${(us / 1000).toStringAsFixed(1)} ms';

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

/// Dev mode's corner readout as tables, one fact a line: each of [columns]
/// a table of labels and values in two aligned columns, the tables side by
/// side on one dark chip, never taking taps.
class DebugTable extends StatelessWidget {
  const DebugTable(this.columns, {super.key});

  final List<List<DebugRow>> columns;

  @override
  Widget build(BuildContext context) => _DebugPanel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, rows) in columns.indexed) ...[
              if (i > 0) const SizedBox(width: DebugOverlayStyle.tableGap),
              Table(
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
            ],
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
