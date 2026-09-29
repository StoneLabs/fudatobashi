import 'package:flutter/widgets.dart';

/// The things on Home that Tobi's tour points at.
enum TourSpot { brand, training, map, islandPlan, rank, modes, guest, level, tabs, settings }

/// One [GlobalKey] per [TourSpot], so the tour can find where each one is
/// laid out, at any font scale.
class TourKeys {
  final Map<TourSpot, GlobalKey> _keys = {for (final s in TourSpot.values) s: GlobalKey(debugLabel: 'tour ${s.name}')};

  GlobalKey operator [](TourSpot spot) => _keys[spot]!;

  /// Where [spot] is, in [ancestor]'s coordinates; null while it is not
  /// laid out on screen.
  Rect? rectOf(TourSpot spot, RenderBox ancestor) {
    final box = _keys[spot]!.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(box.getTransformTo(ancestor), Offset.zero & box.size);
  }
}

/// Hands [keys] down to the [TourAnchor]s below it.
class TourAnchors extends InheritedWidget {
  const TourAnchors({super.key, required this.keys, required super.child});

  final TourKeys keys;

  @override
  bool updateShouldNotify(TourAnchors old) => old.keys != keys;
}

/// Marks [child] as [spot] for the tour. Without [TourAnchors] above it,
/// it is just [child].
class TourAnchor extends StatelessWidget {
  const TourAnchor(this.spot, {super.key, required this.child});

  final TourSpot spot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keys = context.getInheritedWidgetOfExactType<TourAnchors>()?.keys;
    return keys == null ? child : KeyedSubtree(key: keys[spot], child: child);
  }
}
