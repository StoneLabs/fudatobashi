// Shared by the tests that lay out and record 定位置 games.
import 'dart:math';

import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_placing.dart';

/// Where the [i]th card placed goes: round the rows in play, the left
/// cluster then the right.
TeiichiSpot dealtSpot(TeiichiSetup setup, int i) {
  final rows = setup.rowsInPlay;
  return ClusterEnd(rows[i % rows.length], (i ~/ rows.length).isEven ? RowPart.left : RowPart.right);
}

/// A 定位置 game of [setup] laid out from [deck] (poems 1 up by default),
/// each card [placeMs] on top of the stack, then played: each card found
/// [findMs] after its prompt, after a wrong tap on another card for the
/// prompts in [wrongAt]; ended early after [endAfter] prompts.
({TeiichiPlacing placing, AnkirenGame game}) playTeiichi(TeiichiSetup setup,
    {List<int>? deck, int placeMs = 1000, int findMs = 800, Set<int> wrongAt = const {}, int? endAfter, int seed = 1}) {
  final placing = TeiichiPlacing(setup, deck ?? [for (var id = 1; id <= setup.cards; id++) id]);
  var at = Duration.zero;
  for (var i = 0; !placing.allPlaced; i++) {
    at += Duration(milliseconds: placeMs);
    placing.placeTop(dealtSpot(setup, i), at);
  }
  placing.finish(at);
  final game = placing.recall(Random(seed))..startRecall(memorised: at);
  var t = const Duration(seconds: 100);
  for (var i = 0; game.phase == AnkirenPhase.recall; i++) {
    if (i == endAfter) {
      game.end();
      break;
    }
    game.promptRevealed(t);
    final asked = game.current!;
    if (wrongAt.contains(i)) {
      game.tap(game.field.cards.firstWhere((c) => c != asked && !game.isDone(c)), t + const Duration(milliseconds: 300));
    }
    t += Duration(milliseconds: findMs);
    game.tap(asked, t);
    t += const Duration(milliseconds: 400);
  }
  return (placing: placing, game: game);
}
