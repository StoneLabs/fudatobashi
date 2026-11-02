import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_score.dart';
import 'debug_common.dart';

/// What a tap earns by where it lands, as the first and as the second tap
/// (weighted), and a first tap there followed by the right card: 暗記練's
/// rules, which 定位置's calls follow too.
class TapPointsTable extends StatelessWidget {
  const TapPointsTable({super.key});

  static const _names = {
    TapProximity.card: 'Spot on',
    TapProximity.neighbour: 'Neighbour',
    TapProximity.row: 'Same row',
    TapProximity.quadrant: 'Same quadrant',
    TapProximity.side: 'Same side',
    TapProximity.otherSide: 'Other side',
  };

  static String _points(TapProximity place, int tap) =>
      _n(AnkirenTuning.cardPoints * AnkirenTuning.tapShare[place]! * AnkirenTuning.tapWeights[tap]);

  static String _n(double x) => x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) => DebugGrid([
        ['tap on', '1st tap', '2nd tap', '1st+right'],
        for (final place in TapProximity.values)
          [
            _names[place]!,
            place == TapProximity.card
                ? '${AnkirenTuning.cardPoints} + 0–${AnkirenTuning.speedMax} speed'
                : _points(place, 0),
            _points(place, 1),
            place == TapProximity.card ? '—' : _n(AnkirenScore.pointsOf([place, TapProximity.card], null).toDouble()),
          ],
      ]);
}
