import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../history/ankiren_field_tab.dart';
import 'debug_common.dart';

/// The developer's view of Tobi's own fixed layout (一騎打ち): the cards
/// chosen a side dealt from all 100, his side laid out at the rating
/// chosen, as he sees it (下段 at the foot), each look-alike family in one
/// colour. On request the player's cards show too, dimmed, at the homes
/// they would go to should they come to him.
class IkkiuchiLayoutPage extends StatefulWidget {
  const IkkiuchiLayoutPage({
    super.key,
    this.rating = IkkiuchiToolsTuning.ratingStart,
    this.perSide = IkkiuchiToolsTuning.perSideStart,
    this.seed,
    this.showAway = false,
  });

  final double rating;
  final int perSide;

  /// The deal and layout's seed; random when null.
  final int? seed;

  /// Whether the player's cards show at their homes.
  final bool showAway;

  @override
  State<IkkiuchiLayoutPage> createState() => _IkkiuchiLayoutPageState();
}

class _IkkiuchiLayoutPageState extends State<IkkiuchiLayoutPage> {
  static const _rowNames = ['下段', '中段', '上段'];

  final _layout = IkkiuchiLayout.ofPoems();
  late double _rating = widget.rating;
  late int _perSide = widget.perSide;
  int _rows = IkkiuchiLayoutTuning.rows;
  late int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiToolsTuning.seeds);
  late bool _showAway = widget.showAway;
  late List<int> _own, _others;
  late IkkiuchiHomes _homes;

  @override
  void initState() {
    super.initState();
    _lay();
  }

  /// Deals [_perSide] cards a side from [_seed] and lays out his.
  void _lay() {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(_seed));
    _own = deck.sublist(0, _perSide);
    _others = deck.sublist(_perSide, 2 * _perSide);
    _homes = _layout.generate(rating: _rating, own: _own, others: _others, rows: _rows, seed: _seed);
  }

  void _change(VoidCallback change) => setState(() {
        change();
        if (!IkkiuchiLayout.rowsAllowed(_perSide, _rows)) _rows = IkkiuchiLayoutTuning.rows;
        _lay();
      });

  static String _share(double? share) => share == null ? 'no pairs' : share.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    final families = _layout.families([..._own, ..._others])
      ..sort((a, b) => poems[a.first].kimariji.compareTo(poems[b.first].kimariji));
    const fills = IkkiuchiToolsStyle.familyFills;
    final fillOf = {
      for (final (i, family) in families.indexed)
        for (final id in family) id: fills[i % fills.length],
    };
    final shown = _showAway ? _homes.plan : _homes.start;
    final start = _homes.start;
    return DebugScaffold(
      title: "Tobi's layout",
      child: ListView(
        padding: IkkiuchiToolsStyle.padding,
        children: [
          DebugSlider(
            label: 'rating ${_rating.round()}',
            value: _rating,
            min: IkkiuchiTuning.ratingMin,
            max: IkkiuchiTuning.ratingMax,
            divisions: (IkkiuchiTuning.ratingMax - IkkiuchiTuning.ratingMin) ~/ IkkiuchiToolsTuning.ratingStep,
            onChanged: (v) => _change(() => _rating = v),
          ),
          Text('cards a side', style: debugMono),
          Wrap(spacing: IkkiuchiToolsStyle.gap, children: [
            for (final n in IkkiuchiToolsTuning.perSideChoices)
              ChoiceChip(
                label: Text('$n', style: debugMono),
                selected: n == _perSide,
                onSelected: (_) => _change(() => _perSide = n),
              ),
          ]),
          Text('rows', style: debugMono),
          Wrap(spacing: IkkiuchiToolsStyle.gap, children: [
            for (var rows = 1; rows <= IkkiuchiLayoutTuning.rows; rows++)
              ChoiceChip(
                label: Text('$rows', style: debugMono),
                selected: rows == _rows,
                onSelected: IkkiuchiLayout.rowsAllowed(_perSide, rows) ? (_) => _change(() => _rows = rows) : null,
              ),
          ]),
          const SizedBox(height: IkkiuchiToolsStyle.gap),
          Wrap(
            spacing: IkkiuchiToolsStyle.gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(onPressed: () => _change(() => _seed++), child: const Text('Reroll')),
              Text('seed $_seed', style: debugMono),
              FilterChip(
                label: Text("player's cards' homes", style: debugMono),
                selected: _showAway,
                onSelected: (on) => setState(() => _showAway = on),
              ),
            ],
          ),
          const Divider(height: IkkiuchiToolsStyle.sectionGap),
          DebugKV('sound grouping', '${_homes.soundGrouped ? 'on' : 'off'} '
              '(chance ${_share(IkkiuchiTobi(_rating).soundGrouping)})'),
          DebugKV('友札 together', '${_homes.tomofudaGrouped ? 'on' : 'off'} '
              '(chance ${_share(IkkiuchiTobi(_rating).tomofudaGrouping)})'),
          DebugKV('same sound together', _share(_layout.groupedShare(_homes))),
          DebugKV('look-alikes together', _share(_layout.lookAlikesTogether(_homes))),
          Text(
            'on/off: his habits this match. together: the share of its pairs homed in the same row and group.',
            style: debugMono.copyWith(color: Palette.mute),
          ),
          const SizedBox(height: IkkiuchiToolsStyle.gap),
          Text(_showAway ? 'Every home, the player\'s cards dimmed' : 'His side at the start', style: title),
          Text('as Tobi sees it, 下段 at the foot; the gap between left and right closed up', style: debugMono),
          const SizedBox(height: IkkiuchiToolsStyle.gap),
          _SideField(
            rows: shown,
            away: _showAway ? _others.toSet() : const {},
            fill: (id) => fillOf[id] ?? Palette.paper,
          ),
          const SizedBox(height: IkkiuchiToolsStyle.gap),
          DebugGrid([
            ['row', 'his L', 'his R', 'homes L', 'homes R', 'room'],
            for (var r = _homes.rows - 1; r >= 0; r--)
              [
                _rowNames[r],
                for (final row in [start[r], _homes.plan[r]]) ...['${row.left.length}', '${row.right.length}'],
                '${IkkiuchiLayout.rowRoom}',
              ],
          ]),
          const Divider(height: IkkiuchiToolsStyle.sectionGap),
          Text('Look-alike families', style: title),
          const SizedBox(height: IkkiuchiToolsStyle.gap),
          for (final family in families)
            Row(children: [
              Container(
                width: IkkiuchiToolsStyle.swatch,
                height: IkkiuchiToolsStyle.swatch,
                color: fillOf[family.first],
              ),
              const SizedBox(width: IkkiuchiToolsStyle.gap),
              Expanded(
                child: Text(
                  [for (final id in family) _own.contains(id) ? poems[id].kimariji : '(${poems[id].kimariji})']
                      .join(' '),
                  style: debugMono,
                ),
              ),
            ]),
          Text('(…): dealt to the player', style: debugMono.copyWith(color: Palette.mute)),
        ],
      ),
    );
  }
}

/// [rows] of Tobi's side drawn as a field, folded, each card's kimariji on
/// its [fill], the [away] cards dimmed; it scrolls sideways when its cards
/// would get too small for the page.
class _SideField extends StatelessWidget {
  const _SideField({required this.rows, required this.away, required this.fill});

  final List<IkkiuchiRow> rows;
  final Set<int> away;
  final Color Function(int poemId) fill;

  @override
  Widget build(BuildContext context) {
    final half = AnkirenHalf([
      for (final r in FieldRow.values)
        r.index < rows.length
            ? AnkirenRow(left: rows[r.index].left, middle: const [], right: rows[r.index].right.reversed.toList())
            : AnkirenRow(left: const [], middle: const [], right: const []),
    ]);
    final geometry = FieldGeometry.of(AnkirenField(own: half, opponent: AnkirenHalf.empty()), folded: true);
    return LayoutBuilder(builder: (context, box) {
      final scale = (box.maxWidth / geometry.width).clamp(
          IkkiuchiToolsStyle.minPitch / FieldGeometry.pitch, IkkiuchiToolsStyle.maxPitch / FieldGeometry.pitch);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          color: IkkiuchiToolsStyle.ground,
          width: geometry.width * scale,
          height: geometry.height * scale,
          child: Stack(children: [
            for (final MapEntry(key: id, value: r) in geometry.half(FieldSide.own).entries)
              Positioned(
                left: r.x * scale,
                top: r.y * scale,
                width: r.w * scale,
                height: r.h * scale,
                child: Opacity(
                  opacity: away.contains(id) ? IkkiuchiToolsStyle.awayOpacity : 1,
                  child: FieldWordCard(id, fill: fill(id), color: Palette.ink),
                ),
              ),
          ]),
        ),
      );
    });
  }
}
