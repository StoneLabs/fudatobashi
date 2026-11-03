# Curve editor

Open with `firefox tool/curve_editor/index.html`. No build, no network.

- Import / Export use the clipboard (Ctrl+V on the page also imports).
- Format is the app's Dart expression, e.g.
  `TuningCurve.log([(0, 3400), (1600, 1300), (3600, 180)], slopes: [(1600, -0.0009)])`.
  `IkkiuchiCurve` names, newlines, trailing commas, `static const x =` and `;` are accepted.
- Drag a point; double-click empty space to add one; right-click a point (or Delete) to remove it.
- A selected point shows a tangent handle: drag a knob to set its slope; right-click a knob or
  double-click the point to go back to the automatic slope.
- Rank boundaries (from `lib/domain/rating.dart`) are the dotted lines.
