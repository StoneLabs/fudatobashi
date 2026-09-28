import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'buttons.dart';
import 'pressable.dart';
import 'vector.dart';

/// One destination of [MangaTabBar].
@immutable
class MangaTab {
  const MangaTab({required this.icon, required this.label, this.ready = true});
  final VectorArt icon;
  final String label;

  /// False for a destination not built yet: tapping it calls
  /// [MangaTabBar.onUnready] instead of selecting it.
  final bool ready;
}

/// The bottom navigation: a row of ink-bordered tiles; the current one is
/// solid ink.
class MangaTabBar extends StatelessWidget {
  const MangaTabBar({super.key, required this.tabs, required this.current, required this.onSelect, this.onUnready});

  final List<MangaTab> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  /// A tile that is not [MangaTab.ready] was tapped (its context).
  final ValueChanged<BuildContext>? onUnready;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TabBarStyle.height,
      child: Row(
        children: [
          for (final (i, tab) in tabs.indexed) ...[
            if (i > 0) const SizedBox(width: TabBarStyle.gap),
            Expanded(
              child: Builder(
                builder: (tile) => _Tile(
                  tab: tab,
                  active: i == current,
                  onTap: () => tab.ready ? onSelect(i) : onUnready?.call(tile),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tab, required this.active, required this.onTap});
  final MangaTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Palette.paper : Palette.ink;
    return Semantics(
      selected: active,
      child: Pressable(
        onTap: onTap,
        scale: Press.tabScale,
        turn: 0,
        semanticLabel: tab.label,
        builder: (context, _) => AnimatedContainer(
          duration: Motion.tab,
          decoration: BoxDecoration(
            color: active ? Palette.ink : Palette.paper,
            border: Border.all(color: Palette.ink, width: Strokes.control),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MangaIcon(tab.icon, size: TabBarStyle.icon, color: fg),
              const SizedBox(height: TabBarStyle.iconGap),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: TextStyle(fontSize: TabBarStyle.label, fontWeight: Weights.black, color: fg, height: TabBarStyle.lineHeight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
