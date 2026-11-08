import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_tobi.dart';
import 'debug_common.dart';
import 'ikkiuchi_graphs.dart';
import 'ikkiuchi_rating_header.dart';
import 'ikkiuchi_values.dart';

/// The developer's view of Tobi's curves (一騎打ち): every value he plays
/// with at the rating the slider picks, by group, with the ranges his form
/// and his own draws give it; the rules that never change; then a graph of
/// each value against his rating, the shares of his arm moves stacked.
class IkkiuchiCurvesPage extends StatefulWidget {
  const IkkiuchiCurvesPage({super.key, this.rating = IkkiuchiToolsTuning.ratingStart});

  /// The rating the page opens at.
  final double rating;

  @override
  State<IkkiuchiCurvesPage> createState() => _IkkiuchiCurvesPageState();
}

class _IkkiuchiCurvesPageState extends State<IkkiuchiCurvesPage> {
  late double _rating = widget.rating;

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    const gap = SizedBox(height: IkkiuchiToolsStyle.gap);
    const section = SizedBox(height: IkkiuchiToolsStyle.sectionGap);
    return DebugScaffold(
      title: "Tobi's curves",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IkkiuchiRatingHeader(
            rating: _rating,
            note: 'form sd ${_form.sd.round()}, never past ±${_form.cutOff.round()}',
            onChanged: (v) => setState(() => _rating = v),
          ),
          Expanded(
            child: ListView(
              padding: IkkiuchiToolsStyle.padding,
              children: [
                Text('At ${_rating.round()}', style: title),
                gap,
                _ValuesTable(_rating),
                gap,
                Text(_rangesNote, style: _small),
                section,
                Text('Fixed rules', style: title),
                gap,
                const _FixedRules(),
                section,
                Text('By rating', style: title),
                for (final group in ikkiuchiValueGroups) ...[
                  gap,
                  _GroupBand(group.name),
                  for (final value in group.values)
                    if (value.graph case final graph?) ...[
                      const SizedBox(height: IkkiuchiCurvesStyle.graphGap),
                      IkkiuchiCurveGraph(value, graph, _rating),
                    ],
                  if (group.sharesGraph case final graph?) ...[
                    const SizedBox(height: IkkiuchiCurvesStyle.graphGap),
                    IkkiuchiSharesGraph(group.shares, graph, _rating),
                  ],
                  gap,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Small notes in the UI face, its missing glyphs (σ) from monospace.
final _small = TextStyle(
  fontSize: IkkiuchiCurvesStyle.smallFont,
  color: IkkiuchiToolsStyle.soft,
  fontFamilyFallback: [?debugMono.fontFamily],
);
final _number = debugMono.copyWith(fontSize: IkkiuchiCurvesStyle.numberFont);

final _sigmaNames = [for (final s in IkkiuchiToolsTuning.sigmas) '$sσ'];

const _form = IkkiuchiTobi.formDraw;

final _rangesNote = '${_sigmaNames.join(', ')}: per match from his form (rating '
    '${[for (final s in IkkiuchiToolsTuning.sigmas) '±${ikkiuchiFormReach(s).round()}'].join(', ')}, never past '
    '±${_form.cutOff.round()}); per card from his own draw, median × e^±σ; $ikkiuchiNoRange: fixed.';

/// A group's name on a band across the page, in tracked capitals.
class _GroupBand extends StatelessWidget {
  const _GroupBand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Container(
        color: IkkiuchiCurvesStyle.groupFill,
        padding: IkkiuchiCurvesStyle.groupPadding,
        child: _GroupName(name),
      );
}

class _GroupName extends StatelessWidget {
  const _GroupName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Text(
        name.toUpperCase(),
        style: const TextStyle(
          fontSize: IkkiuchiCurvesStyle.smallFont,
          fontWeight: Weights.bold,
          letterSpacing: IkkiuchiCurvesStyle.groupTracking,
        ),
      );
}

/// Each value at [rating] by group, with its ranges at each of
/// [IkkiuchiToolsTuning.sigmas]: from his form on its own row, from his
/// draws on a per-card row under a value he draws per card, and under a
/// chance per group its share of games with any group kept together.
class _ValuesTable extends StatelessWidget {
  const _ValuesTable(this.rating);

  final double rating;

  @override
  Widget build(BuildContext context) {
    const sigmas = IkkiuchiToolsTuning.sigmas;
    const edge = IkkiuchiCurvesStyle.groupPadding;
    const name = TextStyle(fontSize: IkkiuchiCurvesStyle.nameFont);

    // A cell in column [column] of the [columns], its text at the right
    // but in the first.
    Widget cell(int column, String text, TextStyle style, {double indent = 0}) => Padding(
          padding: IkkiuchiCurvesStyle.rowPadding.copyWith(
            left: column == 0 ? edge.left + indent : IkkiuchiCurvesStyle.columnGap,
            right: column == sigmas.length + 1 ? edge.right : 0,
          ),
          child: Text(text, style: style, textAlign: column == 0 ? TextAlign.start : TextAlign.end),
        );
    TableRow row(List<(String, TextStyle)> cells, {double indent = 0}) => TableRow(children: [
          for (final (i, (text, style)) in cells.indexed) cell(i, text, style, indent: indent),
        ]);

    return Table(
      columnWidths: const {0: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        row([('', _small), ('at ${rating.round()}', _small), for (final s in _sigmaNames) (s, _small)]),
        for (final group in ikkiuchiValueGroups) ...[
          TableRow(
            decoration: const BoxDecoration(color: IkkiuchiCurvesStyle.groupFill),
            children: [
              Padding(padding: edge, child: _GroupName(group.name)),
              for (var i = 0; i <= sigmas.length; i++) const SizedBox(),
            ],
          ),
          for (final value in group.rows) ...[
            row([
              (value.name, name),
              (value.unit.format(value.at(rating)), _number),
              for (final s in sigmas) (value.matchRangeText(rating, s), _number),
            ]),
            if (value.drawSpread != null)
              row([
                ('per card', _small),
                ('', _number),
                for (final s in sigmas) (value.cardRangeText(rating, s), _number),
              ], indent: IkkiuchiCurvesStyle.subIndent),
            if (value.anyInGame case final any?)
              row([
                (any.name, _small),
                (any.unit.format(any.at(rating)), _number),
                for (final s in sigmas) (any.matchRangeText(rating, s), _number),
              ], indent: IkkiuchiCurvesStyle.subIndent),
          ],
        ],
      ],
    );
  }
}

/// The rules that are the same at every rating: each its name, its rule
/// and a note on what it means.
class _FixedRules extends StatelessWidget {
  const _FixedRules();

  @override
  Widget build(BuildContext context) {
    const wild = IkkiuchiTuning.wildMoves;
    String percent(double share) => IkkiuchiUnit.percent.format(share);
    // Breaks a line only between a rule's parts.
    String whole(String part) => part.replaceAll(' ', ' ');
    final rules = [
      (
        'arm by distance',
        'swing × (1 + ${IkkiuchiTuning.armDistanceWeight} × (d − 1))',
        "d: the card's distance, 1 the average",
      ),
      (
        'wild moves',
        [
          whole('whip ${percent(wild.whip)}'),
          whole('coil and lunge ${percent(wild.coilLunge)}'),
          whole('smear ${percent(wild.smear)}'),
        ].join(' · '),
        'their split of what the sweep leaves',
      ),
      (
        'form',
        'sd ${_form.sd.round()} rating points, drawn again past ±${_form.cutOff.round()}',
        'drawn once a match and added to his rating',
      ),
    ];
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final (name, rule, note) in rules)
          TableRow(children: [
            Padding(
              padding: IkkiuchiCurvesStyle.rowPadding.copyWith(right: IkkiuchiCurvesStyle.columnGap),
              child: Text(name, style: const TextStyle(fontSize: IkkiuchiCurvesStyle.nameFont)),
            ),
            Padding(
              padding: IkkiuchiCurvesStyle.rowPadding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rule, style: _number),
                Text(note, style: _small),
              ]),
            ),
          ]),
      ],
    );
  }
}
