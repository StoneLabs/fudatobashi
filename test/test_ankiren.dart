// Shared by the tests that record 暗記練 games.
import 'dart:math';

import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';

/// A 暗記練 game dealt from all the poems, played out: each card found
/// [ms] after its prompt, after one wrong tap on another card of its side
/// for the prompts in [wrongAt], or given up for those in [giveUpAt]; ended
/// early after [endAfter] prompts.
AnkirenGame playAnkiren(AnkirenSetup setup,
    {int seed = 1, int ms = 700, Set<int> wrongAt = const {}, Set<int> giveUpAt = const {}, int? endAfter}) {
  final rng = Random(seed);
  final field = AnkirenDealer.ofPoems()
      .deal([for (final p in poems.all) p.id], setup.perSide, rng, allInMiddle: setup.allInMiddle);
  final game = AnkirenGame(field: field, setup: setup, rng: rng)..startRecall();
  var t = const Duration(seconds: 100);
  for (var i = 0; game.phase == AnkirenPhase.recall; i++) {
    if (i == endAfter) {
      game.end();
      break;
    }
    game.promptRevealed(t);
    final asked = game.current!;
    if (wrongAt.contains(i)) {
      final side = field.sideOf(asked);
      game.tap(field.cards.firstWhere((c) => c != asked && !game.isFound(c) && field.sideOf(c) == side),
          t + const Duration(milliseconds: 300));
    }
    t += Duration(milliseconds: ms);
    if (giveUpAt.contains(i)) {
      game.giveUp();
    } else {
      game.tap(asked, t);
    }
    t += const Duration(milliseconds: 400);
  }
  return game;
}
