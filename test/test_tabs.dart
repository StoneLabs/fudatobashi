import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/manga/tab_bar.dart';

/// The bottom bar's button named [label]; the bar shows icons only, so the
/// name lives in the tooltip.
Finder tabButton(String label) => find.descendant(of: find.byType(MangaTabBar), matching: find.byTooltip(label));
