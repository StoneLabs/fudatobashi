import '../config/config.dart';

/// 一騎打ち's ranked modes, as chess has its time controls: each deals its
/// own cards with its own memory time, and has its own rating, class and
/// placement ([IkkiuchiModeTuning]). Stored by name.
enum IkkiuchiMode {
  bullet(IkkiuchiModeTuning.bullet),
  blitz(IkkiuchiModeTuning.blitz),
  rapid(IkkiuchiModeTuning.rapid);

  const IkkiuchiMode(this._spec);

  final IkkiuchiModeSpec _spec;

  /// The cards dealt to each side, and the memory time before play.
  int get perSide => _spec.perSide;
  Duration get memorise => _spec.memorise;

  /// The rows a side is laid out in unless the player picks others, and
  /// the rows they may pick, fewest first.
  int get defaultRows => _spec.rows;
  List<int> get rowChoices => [for (var r = _spec.fewestRows; r <= IkkiuchiLayoutTuning.rows; r++) r];

  /// What the seed of Tobi's ranked draw is offset by in this mode.
  int get drawSeedOffset => _spec.drawSeedOffset;
}
