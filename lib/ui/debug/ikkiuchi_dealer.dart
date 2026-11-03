import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_send.dart';
import '../../state/scope.dart';
import '../ikkiuchi/ikkiuchi_board_layout.dart';
import '../ikkiuchi/ikkiuchi_board_scene.dart';
import '../ikkiuchi/ikkiuchi_card_faces.dart';
import '../ikkiuchi/ikkiuchi_tobi_art.dart';

/// Deals the full 一騎打ち fields of the developer's pages, and keeps the
/// board scene of the one shown. A deal's seed shuffles the deck and gives
/// each side [IkkiuchiToolsTuning.dealPerSide] cards, or the [perSide] asked; Tobi's layout lays
/// out both sides, his at his rating and the player's at one drawn from the
/// seed. The scene is set out afresh when the board's size, its layout, the
/// rating or the seed changes; the cards' faces are drawn once for them all.
class IkkiuchiDealer {
  /// Tobi's layout, which lays out both sides.
  final layout = IkkiuchiLayout.ofPoems();
  final _rig = IkkiuchiTobiArt.rig();
  IkkiuchiCardFaces? _faces;
  IkkiuchiBoardScene? _scene;
  ({Size size, bool landscape, double rating, int seed, int perSide})? _key;

  /// The board as drawn now.
  IkkiuchiBoardScene? get scene => _scene;

  /// A rating drawn from [seed], anywhere in Tobi's range.
  static double drawnRating(int seed) {
    final rng = math.Random(seed);
    return IkkiuchiTuning.ratingMin + rng.nextDouble() * (IkkiuchiTuning.ratingMax - IkkiuchiTuning.ratingMin);
  }

  /// The rating the player's side of deal [seed] is laid out at.
  static double playerRating(int seed) => drawnRating(seed + IkkiuchiToolsTuning.playerSeedOffset);

  /// The scene of deal [seed], Tobi's side at [rating], on a board filling
  /// [room]. The landscape layout lies turned in it ([turned]), so the
  /// board's own size is [room] turned too. [onNew] gets each scene set out
  /// afresh.
  IkkiuchiBoardScene sceneFor(
    BuildContext context,
    Size room, {
    required bool landscape,
    required double rating,
    required int seed,
    int perSide = IkkiuchiToolsTuning.dealPerSide,
    ValueChanged<IkkiuchiBoardScene>? onNew,
  }) {
    final size = landscape ? room.flipped : room;
    final key = (size: size, landscape: landscape, rating: rating, seed: seed, perSide: perSide);
    final old = _scene;
    if (old != null && key == _key) return old;
    _faces ??= IkkiuchiCardFaces(showNumber: ProgressScope.of(context).settings.showPoemNumber);
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    const rows = IkkiuchiToolsTuning.dealRows;
    final own = deck.sublist(0, perSide), others = deck.sublist(perSide, 2 * perSide);
    final playerSeed = seed + IkkiuchiToolsTuning.playerSeedOffset;
    final sides = IkkiuchiSides.start(
      layout.generate(rating: rating, own: own, others: others, rows: rows, seed: seed),
      layout.generate(rating: drawnRating(playerSeed), own: others, others: own, rows: rows, seed: playerSeed).start,
    );
    final board = IkkiuchiBoardLayout.of(
      size: size,
      landscape: landscape,
      tobiRows: sides.tobi,
      playerRows: sides.player,
      rig: _rig,
    );
    if (old != null) SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
    _key = key;
    final scene = _scene = IkkiuchiBoardScene(board, _faces!, sides: sides, tobiRating: rating, seed: seed);
    onNew?.call(scene);
    return scene;
  }

  /// [board] as its layout lies on the page: turned a quarter turn for the
  /// landscape layout, so the board turns and the page does not.
  static Widget turned(Widget board, {required bool landscape}) =>
      landscape ? RotatedBox(quarterTurns: 1, child: board) : board;

  void dispose() {
    _scene?.dispose();
    _faces?.dispose();
  }
}
