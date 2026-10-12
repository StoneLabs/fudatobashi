import 'package:flutter/material.dart';

import '../../data/poem.dart';
import '../../state/scope.dart';
import 'debug_common.dart';
import 'frame_stats.dart';

/// Frame times and the last run's attempts, as the timing code measured them.
class TimingPage extends StatefulWidget {
  const TimingPage({super.key});

  @override
  State<TimingPage> createState() => _TimingPageState();
}

class _TimingPageState extends State<TimingPage> {
  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final f = FrameStats.instance.summary();
    final run = p.lastRun;
    return DebugScaffold(
      title: 'Timing',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Frames (last ≤600)')),
              IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh)),
            ],
          ),
          DebugKV('frames', '${f.frames}'),
          DebugKV('avg build / raster', '${f.avgBuildMs.toStringAsFixed(2)} / ${f.avgRasterMs.toStringAsFixed(2)} ms'),
          DebugKV('worst total span', '${f.worstTotalMs.toStringAsFixed(2)} ms'),
          DebugKV('over 8.33 ms budget', '${f.jankPct.toStringAsFixed(1)}%'),
          const Divider(height: 24),
          const Text(
            'Clocks: pointer timestamps (1 ms resolution on Android) and frame vsync timestamps '
            '(µs) share the engine monotonic clock. reveal = vsync of first frame painting the card; '
            'response = pointer-down (or first move after reveal if the finger was already down).',
          ),
          const Divider(height: 24),
          if (run == null)
            const Text('No run yet this app session.')
          else ...[
            DebugKV('cards', '${run.cards.length}, attempts ${run.attempts.length}, undone ${run.undone.length}'),
            DebugKV('total', run.total == null ? '—' : '${run.total!.inMicroseconds} µs'),
            const SizedBox(height: 8),
            const Text(' #  card  kimariji    response µs  outcome  flags', style: debugMono),
            for (final a in run.attempts)
              Text(
                '${a.index.toString().padLeft(2)}  ${a.card.poemId.toString().padLeft(3)}${a.card.inverted ? 'v' : '^'}'
                ' ${poems[a.card.poemId].kimariji.padRight(7, '　')} ${a.responseUs.toString().padLeft(10)}'
                '  ${a.outcome.name.padRight(8)} ${a.wrong ? 'wrong ' : ''}${a.tainted ? 'tainted' : ''}',
                style: debugMono,
              ),
          ],
        ],
      ),
    );
  }
}
