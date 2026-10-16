import 'dart:convert';

import 'package:flutter/foundation.dart';

enum PlayMode {
  /// 始める: free practice, a deck once through (tracked).
  free,

  /// 苦手: the slowest / shakiest cards (tracked).
  nigate,

  /// 修行: spaced-repetition training (tracked).
  training,

  /// Guest: nothing is recorded.
  guest,

  /// ランク戦: all 100 cards, either way up, the only runs that move the
  /// rating (all-known mode).
  ranked,

  /// 卒業試験: all 100 cards against Tobi, the journey's end.
  exam,
}

/// How a run is set up.
class PlayConfig {
  const PlayConfig({
    required this.mode,
    this.setIds = const ['all'],
    this.cardIds,
    this.maskLevel = 0,
  });

  /// Free practice's default deck: every card the player knows, whatever that
  /// is on the day (see `Progress.knownCards`).
  static const knownDeckId = 'known';

  final PlayMode mode;

  /// The `FudaSet`s that make up the deck (or [knownDeckId]), when [cardIds]
  /// is null.
  final List<String> setIds;

  /// A hand-picked deck (free practice customised).
  final List<int>? cardIds;

  /// 隠し字 level (0 = off).
  final int maskLevel;

  bool get tracked => mode != PlayMode.guest;

  /// Free practice's default deck: every known card.
  bool get isKnownDeck => cardIds == null && setIds.length == 1 && setIds.first == knownDeckId;

  /// Whether the run feeds FSRS and the training statistics: 修行, ランク戦,
  /// 苦手, or free practice left at its default (every known card, no 隠し字).
  /// Any other free-play deck, and the exam, are stored for History and
  /// display only.
  bool get countsForSrs => switch (mode) {
        PlayMode.training || PlayMode.ranked || PlayMode.nigate => true,
        PlayMode.free => isKnownDeck && maskLevel == 0,
        PlayMode.guest || PlayMode.exam => false,
      };

  /// All 100 cards against the clock, misses adding time (see
  /// `RankedScore`).
  bool get scored => mode == PlayMode.ranked || mode == PlayMode.exam;

  /// Runs with the same key count as "the same operation" in history.
  String get historyKey => jsonEncode([mode.index, [...setIds]..sort(), if (cardIds != null) [...cardIds!]..sort(), maskLevel]);

  Map<String, Object?> toJson() => {'mode': mode.name, 'setIds': setIds, 'cardIds': cardIds, 'maskLevel': maskLevel};

  factory PlayConfig.fromJson(Map<String, dynamic> j) => PlayConfig(
        mode: PlayMode.values.byName(j['mode'] as String),
        setIds: (j['setIds'] as List).cast<String>(),
        cardIds: (j['cardIds'] as List?)?.cast<int>(),
        maskLevel: j['maskLevel'] as int? ?? 0,
      );
}

/// Free practice's remembered setup: the deck and 隠し字. Left at its default
/// (every known card, 隠し字 off) a run counts like 修行; see
/// [PlayConfig.countsForSrs].
class FreePracticeSetup {
  const FreePracticeSetup({this.cardIds, this.maskLevel = 0});

  /// The hand-picked deck, sorted, or null for every card the player knows.
  final List<int>? cardIds;
  final int maskLevel;

  bool get customized => cardIds != null || maskLevel > 0;

  PlayConfig get config => PlayConfig(
        mode: PlayMode.free,
        setIds: cardIds == null ? const [PlayConfig.knownDeckId] : const [],
        cardIds: cardIds,
        maskLevel: maskLevel,
      );

  Map<String, Object?> toJson() => {'cardIds': cardIds, 'maskLevel': maskLevel};

  factory FreePracticeSetup.fromJson(Map<String, dynamic> j) => FreePracticeSetup(
        cardIds: (j['cardIds'] as List?)?.cast<int>(),
        maskLevel: j['maskLevel'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is FreePracticeSetup &&
      other.maskLevel == maskLevel &&
      listEquals(other.cardIds, cardIds);

  @override
  int get hashCode => Object.hash(maskLevel, cardIds == null ? null : Object.hashAll(cardIds!));
}
