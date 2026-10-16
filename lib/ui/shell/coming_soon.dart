import 'package:flutter/widgets.dart';

import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A "coming soon" balloon that pops out of a tapped control for a moment,
/// for features that are not built yet.
abstract final class ComingSoonBubble {
  static void show(BuildContext context) => BalloonPop.show(context, S.of(context).comingSoon);
}
