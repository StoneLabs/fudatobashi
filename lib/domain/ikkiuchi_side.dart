/// The two sides of the 一騎打ち field: the opponent's, across the band at
/// the top, and the player's. Stored by name.
enum IkkiuchiSide {
  opponent,
  player;

  /// The side across the band from this one.
  IkkiuchiSide get other => this == player ? opponent : player;
}
