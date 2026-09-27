import 'dart:convert';

import '../data/fuda_sets.dart';

enum PlayMode {
  /// 始める: the chosen sets, once each (tracked).
  free,

  /// 苦手: the slowest / shakiest cards (tracked).
  nigate,

  /// 修行: spaced-repetition training (tracked).
  training,

  /// Guest: nothing is recorded.
  guest,
}

/// 札の方向
enum CardOrientation { random, upright, inverted }

/// How a run is set up.
class PlayConfig {
  const PlayConfig({
    required this.mode,
    this.setIds = const ['all'],
    this.orientation = CardOrientation.random,
    this.maskLevel = 0,
  });

  final PlayMode mode;
  final List<String> setIds;
  final CardOrientation orientation;

  /// 隠し字 level (0 = off).
  final int maskLevel;

  bool get tracked => mode != PlayMode.guest;

  /// History label like the original: the set name, or ミックス for several.
  String label(FudaSets sets) {
    if (mode == PlayMode.training) return '修行';
    if (mode == PlayMode.nigate) return '苦手';
    if (setIds.length == 1) return sets[setIds.first].label;
    return 'ミックス';
  }

  /// Runs with the same key count as "the same operation" in history.
  String get historyKey => jsonEncode([mode.index, [...setIds]..sort(), orientation.index, maskLevel]);

  Map<String, Object> toJson() => {
        'mode': mode.name,
        'setIds': setIds,
        'orientation': orientation.name,
        'maskLevel': maskLevel,
      };

  factory PlayConfig.fromJson(Map<String, dynamic> j) => PlayConfig(
        mode: PlayMode.values.asNameMap()[j['mode']] ?? PlayMode.free,
        setIds: (j['setIds'] as List?)?.cast<String>() ?? const ['all'],
        orientation: CardOrientation.values.asNameMap()[j['orientation']] ?? CardOrientation.random,
        maskLevel: j['maskLevel'] as int? ?? 0,
      );

  PlayConfig copyWith({PlayMode? mode, List<String>? setIds, CardOrientation? orientation, int? maskLevel}) =>
      PlayConfig(
        mode: mode ?? this.mode,
        setIds: setIds ?? this.setIds,
        orientation: orientation ?? this.orientation,
        maskLevel: maskLevel ?? this.maskLevel,
      );
}
