import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// Positions [child] in a [Stack] by a [Placement] token.
class Placed extends StatelessWidget {
  const Placed(this.placement, {super.key, required this.child});

  final Placement placement;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
        left: placement.left,
        top: placement.top,
        right: placement.right,
        bottom: placement.bottom,
        width: placement.size.width,
        height: placement.size.height,
        child: child,
      );
}
