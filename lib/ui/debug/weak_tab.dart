import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/weak_cards.dart';
import '../../state/scope.dart';
import 'debug_common.dart';

const _mono = debugMono;

String _name(ItemKey k) => '${k.poemId.toString().padLeft(3)} ${poems[k.poemId].kimariji}${k.inverted ? ' (inverted)' : ''}';

String _ms(double v) => v.toStringAsFixed(0);

/// How the 苦手 drill would be built right now, from the real selection code.
class WeakTab extends StatefulWidget {
  const WeakTab({super.key});

  @override
  State<WeakTab> createState() => _WeakTabState();
}

class _WeakTabState extends State<WeakTab> {
  int _seed = math.Random().nextInt(1 << 30);

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    final weak = p.weakCards;
    final pick = p.weakPick(math.Random(_seed));
    final drill = p.weakDrill(rng: math.Random(_seed));
    final unlocked = [for (final s in p.trainer.unlocked) s.key]..sort((a, b) => a.id.compareTo(b.id));
    final notPlayed = [for (final k in unlocked) if (!weak.verdicts.containsKey(k)) k];
    final quickCount = weak.quick.length;
    final shown = weak.sides.length;
    final lookReason = {
      for (final e in pick.lookAlikes.entries) e.key: e.value.friend ? '友札, same way up' : 'its other side',
    };
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Text('Weak drill breakdown', style: Theme.of(context).textTheme.titleMedium)),
        TextButton(onPressed: () => setState(() => _seed = math.Random().nextInt(1 << 30)), child: const Text('Re-roll')),
      ]),
      const Text('Totals', style: _mono),
      DebugKV('pool (unlocked sides)', '${unlocked.length}'),
      DebugKV('played / not played', '${weak.verdicts.length} / ${notPlayed.length}'),
      DebugKV('weak sides', '$shown'),
      DebugKV('weak cards (Home badge)', '${weak.cards}'),
      DebugKV('quick sides', '$quickCount'),
      DebugKV('drill size', '${drill.cards.length} cards'),
      DebugKV(
        'how decided',
        'worst ${WeakTuning.targets} of $shown weak sides = ${pick.targets.length} targets, '
            '${pick.lookAlikes.length} look-alikes, ${pick.anchors.length} anchors, '
            'then ${pick.fillers.length} fillers waiting in between if needed, cut at ${WeakTuning.maxSwipes} swipes',
      ),
      DebugKV('usual time (median)', '${_ms(weak.usualMs)} ms'),
      DebugKV('weak line', '${_ms(weak.lineMs)} ms (usual x ${WeakTuning.lineRatio})'),
      DebugKV('weak if', 'a miss in the last ${WeakTuning.recentMissLooks} attempts, or expected time over the line'),
      const Divider(height: 32),
      Text('Chosen drill', style: Theme.of(context).textTheme.titleMedium),
      const Text('Targets (worst first, shuffled for the drill)', style: _mono),
      if (pick.targets.isEmpty) const Text('none: no weak side', style: _mono),
      for (final k in pick.targets) Text('${_name(k)}  ${_reason(weak.verdicts[k]!)}', style: _mono),
      const SizedBox(height: 8),
      const Text('Look-alikes', style: _mono),
      for (final e in pick.lookAlikes.entries)
        Text('${_name(e.value.key)}  for ${_name(e.key)}  (${lookReason[e.key]})', style: _mono),
      const SizedBox(height: 8),
      Text('Anchors: a quick side after every ${WeakTuning.anchorEvery} targets, one first', style: _mono),
      for (final k in pick.anchors) Text('${_name(k)}  ${_ms(weak.verdicts[k]!.expectedMs)} ms, at or under usual', style: _mono),
      const SizedBox(height: 8),
      const Text('Fillers: quick sides that wait when every target is still waiting', style: _mono),
      for (final k in pick.fillers) Text('${_name(k)}  ${_ms(weak.verdicts[k]!.expectedMs)} ms', style: _mono),
      const SizedBox(height: 8),
      const Text('Start order (first cards of the drill)', style: _mono),
      for (final (i, c) in drill.cards.indexed)
        Text('${(i + 1).toString().padLeft(2)}. ${_name(ItemKey(c.poemId, c.inverted))}', style: _mono),
      const Divider(height: 32),
      Text('Pool', style: Theme.of(context).textTheme.titleMedium),
      const Text('side, expected ms, last attempts (X miss, o ok, newest first), verdict', style: _mono),
      for (final k in unlocked) Text(_poolRow(k, weak), style: _mono),
    ]);
  }

  String _poolRow(ItemKey k, WeakCards weak) {
    final v = weak.verdicts[k];
    if (v == null) return '${_name(k)}  not played';
    final looks = v.recentMisses.map((m) => m ? 'X' : 'o').join();
    return '${_name(k)}  ${_ms(v.expectedMs).padLeft(5)}  ${looks.padRight(WeakTuning.recentMissLooks)}  ${_reason(v)}';
  }

  String _reason(WeakVerdict v) => switch ((v.missed, v.slow)) {
    (true, true) => 'weak: missed and slow',
    (true, false) => 'weak: missed recently',
    (false, true) => 'weak: slow (${_ms(v.expectedMs)} ms)',
    _ => 'not weak',
  };
}
