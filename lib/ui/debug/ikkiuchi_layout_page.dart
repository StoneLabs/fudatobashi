import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../history/ankiren_field_tab.dart';
import 'debug_common.dart';
import 'ikkiuchi_rating_header.dart';

/// The developer's view of Tobi's own fixed layout (一騎打ち): the cards
/// chosen a side dealt from all 100, his side laid out at the rating
/// chosen, as he sees it (下段 at the foot), the gap between left and right
/// closed up. Each first-sound group shares a pale tint, and each 友札
/// family a strong band at its cards' feet. In the full layout the player's
/// cards show too, dimmed, at the homes they would go to should they come
/// to him, the cards narrowed to fit the page.
class IkkiuchiLayoutPage extends StatefulWidget {
  const IkkiuchiLayoutPage({
    super.key,
    this.rating = IkkiuchiToolsTuning.ratingStart,
    this.perSide = IkkiuchiToolsTuning.perSideStart,
    this.seed,
    this.full = false,
  });

  final double rating;
  final int perSide;

  /// The deal and layout's seed; random when null.
  final int? seed;

  /// Whether every card dealt shows at its home, the player's too.
  final bool full;

  @override
  State<IkkiuchiLayoutPage> createState() => _IkkiuchiLayoutPageState();
}

class _IkkiuchiLayoutPageState extends State<IkkiuchiLayoutPage> {
  static const _rowNames = ['下段', '中段', '上段'];

  /// The one-sound cards' group, as the tints name it.
  static const _oneSound = '一字';

  final _layout = IkkiuchiLayout.ofPoems();
  late double _rating = widget.rating;
  late int _perSide = widget.perSide;
  int _rows = IkkiuchiLayoutTuning.rows;
  late int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiToolsTuning.seeds);
  late bool _full = widget.full;
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

  /// Each first sound among [dealt] and its tint, in kana order: the
  /// sounds with the most cards take the tints first, so the big groups
  /// never share one.
  Map<String, Color> _tints(List<int> dealt) {
    final count = <String, int>{};
    for (final id in dealt) {
      count.update(_layout.groupOf(id), (n) => n + 1, ifAbsent: () => 1);
    }
    final ranked = count.keys.where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => count[a] == count[b] ? a.compareTo(b) : count[b]! - count[a]!);
    const tints = IkkiuchiToolsStyle.soundTints;
    final tintOf = {
      for (final (i, sound) in ranked.indexed) sound: tints[i % tints.length],
      if (count.containsKey('')) '': IkkiuchiToolsStyle.shortTint,
    };
    return {for (final sound in tintOf.keys.toList()..sort()) sound: tintOf[sound]!};
  }

  @override
  Widget build(BuildContext context) {
    final dealt = [..._own, ..._others];
    final families = _layout.families(dealt)
      ..sort((a, b) => poems[a.first].kimariji.compareTo(poems[b.first].kimariji));
    const bands = IkkiuchiToolsStyle.familyFills;
    final bandOf = {
      for (final (i, family) in families.indexed)
        for (final id in family) id: bands[i % bands.length],
    };
    final tints = _tints(dealt);
    final start = _homes.start;
    const gap = SizedBox(height: IkkiuchiToolsStyle.gap);
    return DebugScaffold(
      title: "Tobi's layout",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IkkiuchiRatingHeader(rating: _rating, onChanged: (v) => _change(() => _rating = v)),
          Expanded(
            child: ListView(
              padding: IkkiuchiToolsStyle.padding,
              children: [
                _Choices(
                  label: 'cards a side',
                  children: [
                    for (final n in IkkiuchiToolsTuning.perSideChoices)
                      _chip('$n', n == _perSide, (_) => _change(() => _perSide = n)),
                  ],
                ),
                _Choices(
                  label: 'rows',
                  children: [
                    for (var rows = 1; rows <= IkkiuchiLayoutTuning.rows; rows++)
                      _chip('$rows', rows == _rows,
                          IkkiuchiLayout.rowsAllowed(_perSide, rows) ? (_) => _change(() => _rows = rows) : null),
                  ],
                ),
                gap,
                Wrap(
                  spacing: IkkiuchiToolsStyle.gap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton(onPressed: () => _change(() => _seed++), child: const Text('Reroll')),
                    Text('seed $_seed', style: debugMono),
                    FilterChip(
                      label: Text('Full teiichi', style: debugMono),
                      selected: _full,
                      visualDensity: VisualDensity.compact,
                      onSelected: (on) => setState(() => _full = on),
                    ),
                  ],
                ),
                gap,
                Wrap(spacing: IkkiuchiToolsStyle.gap, children: [
                  _Habit('sound grouping', _homes.soundGrouped),
                  _Habit('友札 together', _homes.tomofudaGrouped),
                ]),
                gap,
                _SideField(
                  rows: _full ? _homes.plan : start,
                  full: _full,
                  away: _full ? _others.toSet() : const {},
                  tint: (id) => tints[_layout.groupOf(id)]!,
                  band: (id) => bandOf[id],
                ),
                gap,
                DebugGrid([
                  ['row', 'his L', 'his R', 'homes L', 'homes R', 'room'],
                  for (var r = _homes.rows - 1; r >= 0; r--)
                    [
                      _rowNames[r],
                      for (final row in [start[r], _homes.plan[r]]) ...['${row.left.length}', '${row.right.length}'],
                      '${IkkiuchiLayout.rowRoom}',
                    ],
                ]),
                gap,
                Wrap(
                  spacing: IkkiuchiToolsStyle.legendSpacing,
                  runSpacing: IkkiuchiToolsStyle.legendRunSpacing,
                  children: [
                    for (final family in families)
                      _LegendItem(
                        color: bandOf[family.first]!,
                        children: [
                          for (final id in family)
                            TextSpan(
                              text: '${poems[id].kimariji} ',
                              style: _own.contains(id) ? null : const TextStyle(color: IkkiuchiToolsStyle.soft),
                            ),
                        ],
                      ),
                  ],
                ),
                gap,
                Wrap(
                  spacing: IkkiuchiToolsStyle.tintSpacing,
                  runSpacing: IkkiuchiToolsStyle.tintSpacing,
                  children: [
                    for (final MapEntry(key: sound, value: tint) in tints.entries)
                      _SoundTint(sound.isEmpty ? _oneSound : sound, tint),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _chip(String label, bool selected, ValueChanged<bool>? onSelected) => ChoiceChip(
        label: Text(label, style: debugMono),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: IkkiuchiToolsStyle.chipPadding,
        labelPadding: IkkiuchiToolsStyle.chipLabelPadding,
        onSelected: onSelected,
      );
}

/// A row of chips after their [label].
class _Choices extends StatelessWidget {
  const _Choices({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: IkkiuchiToolsStyle.choiceLabelWidth, child: Text(label, style: debugMono)),
        Expanded(child: Wrap(spacing: IkkiuchiToolsStyle.gap / 2, children: children)),
      ]);
}

/// One of the match's layout habits, on (inked) or off.
class _Habit extends StatelessWidget {
  const _Habit(this.name, this.on);

  final String name;
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
        padding: IkkiuchiToolsStyle.habitPadding,
        decoration: BoxDecoration(
          color: on ? Palette.ink : null,
          border: Border.all(color: on ? Palette.ink : IkkiuchiToolsStyle.soft),
          borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.habitRadius),
        ),
        child: Text('$name ${on ? 'on' : 'off'}',
            style: debugMono.copyWith(color: on ? Palette.paper : IkkiuchiToolsStyle.soft)),
      );
}

/// A 友札 family's band colour and its kimariji.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.children});

  final Color color;
  final List<TextSpan> children;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: IkkiuchiToolsStyle.swatch, height: IkkiuchiToolsStyle.familyBand, color: color),
        const SizedBox(width: IkkiuchiToolsStyle.gap / 2),
        Text.rich(TextSpan(style: debugMono, children: children)),
      ]);
}

/// A first sound on its tint; the one-sound cards as one.
class _SoundTint extends StatelessWidget {
  const _SoundTint(this.sound, this.tint);

  final String sound;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: IkkiuchiToolsStyle.tintPadding,
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(color: IkkiuchiToolsStyle.soft, width: IkkiuchiToolsStyle.tintBorder),
        ),
        child: Text(sound, style: debugMono),
      );
}

/// [rows] of Tobi's side drawn as a field, folded, each card's kimariji on
/// its first sound's [tint] over its 友札 family's [band], the [away] cards
/// dimmed. The [full] layout's cards are narrowed before it scrolls
/// sideways; the start's keep their shape.
class _SideField extends StatelessWidget {
  const _SideField({
    required this.rows,
    required this.full,
    required this.away,
    required this.tint,
    required this.band,
  });

  final List<IkkiuchiRow> rows;
  final bool full;
  final Set<int> away;
  final Color Function(int poemId) tint;
  final Color? Function(int poemId) band;

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
      const pitch = FieldGeometry.pitch;
      final fit = box.maxWidth / geometry.width;
      final scaleY = fit.clamp(IkkiuchiToolsStyle.minPitch / pitch, IkkiuchiToolsStyle.maxPitch / pitch);
      final scaleX = full ? fit.clamp(IkkiuchiToolsStyle.fullMinPitch / pitch, scaleY) : scaleY;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          color: IkkiuchiToolsStyle.ground,
          width: geometry.width * scaleX,
          height: geometry.height * scaleY,
          child: Stack(children: [
            for (final MapEntry(key: id, value: r) in geometry.half(FieldSide.own).entries)
              Positioned(
                left: r.x * scaleX,
                top: r.y * scaleY,
                width: r.w * scaleX,
                height: r.h * scaleY,
                child: Opacity(
                  opacity: away.contains(id) ? IkkiuchiToolsStyle.awayOpacity : 1,
                  child: FieldWordCard(
                    id,
                    fill: tint(id),
                    color: Palette.ink,
                    foot: switch (band(id)) {
                      final color? => Container(height: IkkiuchiToolsStyle.familyBand, color: color),
                      null => null,
                    },
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}
