import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/karafuda.dart';
import '../../state/scope.dart';
import 'debug_common.dart';

/// The developer's からふだ page: a board of [KarafudaDevTuning.boardCards]
/// cards dealt from the known cards (from all the cards while fewer than
/// twice as many are known),
/// the からふだ the games' own picker ([KarafudaPicker]) draws for it, each
/// marked 友札 of the board cards it is like or not, and the odds: the
/// bias, the pools' sizes and each candidate's chance. Reroll deals another
/// board; Draw again draws for the same one.
class KarafudaDevPage extends StatefulWidget {
  const KarafudaDevPage({super.key, this.seed});

  /// Seeds the deals and draws, for a test; random when null.
  final int? seed;

  @override
  State<KarafudaDevPage> createState() => _KarafudaDevPageState();
}

class _KarafudaDevPageState extends State<KarafudaDevPage> {
  static const _board = KarafudaDevTuning.boardCards;

  late final math.Random _rng = math.Random(widget.seed);
  late final List<int> _known;
  late final bool _allCards;
  late List<int> _cards;
  late KarafudaPools _pools;
  late List<int> _picks;
  int _count = Karafuda.forAnkiren(_board);

  @override
  void initState() {
    super.initState();
    final known = ProgressScope.read(context).knownCards.toList()..sort();
    _allCards = known.length < 2 * _board;
    _known = _allCards ? [for (final p in poems.all) p.id] : known;
    _reroll();
  }

  void _reroll() {
    _cards = ([..._known]..shuffle(_rng)).take(_board).toList()..sort();
    _pools = KarafudaPicker.ofPoems.pools(_cards, _known);
    _draw();
  }

  void _draw() => _picks = KarafudaPicker.draw(_pools, _count, _rng);

  static String _name(int id) => '#${'$id'.padLeft(3)} ${poems[id].kimariji}';

  static String _percent(double p) => '${(p * 100).toStringAsFixed(1)}%';

  /// [id]'s board cards it is a 友札 of, or that it is not one.
  String _friends(int id) {
    final friends = _pools.friendsOf[id];
    return friends == null ? 'not 友札' : '友札 of ${[for (final f in friends) _name(f)].join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    final odds = KarafudaPicker.odds(_pools, _count);
    final picked = _picks.toSet();
    const most = _board;
    Widget line(String text, {bool marked = false}) => Container(
          color: marked ? KarafudaDevStyle.picked : null,
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(text, style: debugMono),
        );
    return DebugScaffold(
      title: 'Karafuda',
      child: ListView(
        padding: KarafudaDevStyle.padding,
        children: [
          Wrap(spacing: KarafudaDevStyle.gap, children: [
            FilledButton(onPressed: () => setState(_reroll), child: const Text('Reroll board')),
            OutlinedButton(onPressed: () => setState(_draw), child: const Text('Draw again')),
          ]),
          const SizedBox(height: KarafudaDevStyle.gap),
          DebugSlider(
            label: 'karafuda to draw: $_count  (AnkiRen formula ${Karafuda.forAnkiren(_board)}, '
                'Teiichi formula ${Karafuda.forTeiichi(_board)})',
            value: _count.toDouble(),
            min: 1,
            max: most.toDouble(),
            divisions: most - 1,
            onChanged: (v) => setState(() {
              _count = v.round();
              _draw();
            }),
          ),
          const Divider(height: 32),
          Text('Board ($_board cards)', style: title),
          const SizedBox(height: KarafudaDevStyle.gap),
          for (final id in _cards) line(_name(id)),
          const Divider(height: 32),
          Text('Picked karafuda (${_picks.length})', style: title),
          const SizedBox(height: KarafudaDevStyle.gap),
          for (final id in _picks) line('${_name(id)}  ${_friends(id)}'),
          const Divider(height: 32),
          Text('Odds', style: title),
          const SizedBox(height: KarafudaDevStyle.gap),
          DebugKV('cards drawn from', _allCards ? 'all ${_known.length} (too few known)' : '${_known.length} known'),
          DebugKV('bias to 友札', '${KarafudaPicker.bias}'),
          DebugKV('友札 pool', '${_pools.similar.length}'),
          DebugKV('other pool', '${_pools.rest.length}'),
          DebugKV('drawn', '$_count'),
          DebugKV('each 友札', _percent(odds.similar)),
          DebugKV('each other', _percent(odds.rest)),
          DebugKV('友札 expected', (odds.similar * _pools.similar.length).toStringAsFixed(2)),
          const SizedBox(height: KarafudaDevStyle.gap),
          Text('友札 pool (${_pools.similar.length}), ${_percent(odds.similar)} each', style: title),
          const SizedBox(height: KarafudaDevStyle.gap),
          for (final id in _pools.similar) line('${_name(id)}  ${_friends(id)}', marked: picked.contains(id)),
          const SizedBox(height: KarafudaDevStyle.gap),
          Text('Other pool (${_pools.rest.length}), ${_percent(odds.rest)} each', style: title),
          const SizedBox(height: KarafudaDevStyle.gap),
          Wrap(spacing: KarafudaDevStyle.gap, children: [
            for (final id in _pools.rest) line(_name(id), marked: picked.contains(id)),
          ]),
        ],
      ),
    );
  }
}
