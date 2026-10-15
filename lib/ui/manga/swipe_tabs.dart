import 'package:flutter/material.dart';

import '../../config/design.dart';

/// One page of [SwipeTabs]: its tab's label, a small sub-label under it
/// (the other language, or a hint), and its contents.
class SwipeTab {
  const SwipeTab({
    required this.label,
    this.sub,
    this.accent = Palette.ink,
    this.onAccent = Palette.paper,
    required this.builder,
  });
  final String label;
  final String? sub;

  /// The picked tab's colour: its fill in a [SwipeTabsLook.strip], the bar
  /// along its top in [SwipeTabsLook.folders].
  final Color accent;

  /// The picked tab's lettering on [accent] in a [SwipeTabsLook.strip].
  final Color onAccent;
  final WidgetBuilder builder;
}

/// How [SwipeTabs] draws its tab row.
enum SwipeTabsLook {
  /// Small two-line labels over a thick rule, the picked one filled.
  strip,

  /// Outlined folder tabs standing on a thick rule, the picked one white
  /// with a bar along its top, pulled up and open into its page.
  folders,
}

/// Pages side by side under a row of tabs: swipe between them, or tap a
/// tab.
class SwipeTabs extends StatefulWidget {
  const SwipeTabs({
    super.key,
    required this.tabs,
    this.initial = 0,
    this.look = SwipeTabsLook.strip,
    this.padding = EdgeInsets.zero,
    this.onChanged,
  });

  final List<SwipeTab> tabs;
  final int initial;
  final SwipeTabsLook look;

  /// Around the tab row only; the pages keep the full width.
  final EdgeInsets padding;
  final ValueChanged<int>? onChanged;

  @override
  State<SwipeTabs> createState() => _SwipeTabsState();
}

class _SwipeTabsState extends State<SwipeTabs> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _current = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(i, duration: Motion.sheet, curve: Motion.routeCurve);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: widget.padding,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: widget.look == SwipeTabsLook.strip
                    ? const Border(bottom: BorderSide(color: Palette.ink, width: SwipeTabsStyle.rule))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, tab) in widget.tabs.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == _current,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _go(i),
                          child: switch (widget.look) {
                            SwipeTabsLook.strip => _StripTab(tab, picked: i == _current),
                            SwipeTabsLook.folders => _FolderTab(
                                tab,
                                picked: i == _current,
                                first: i == 0,
                                beforePicked: i + 1 == _current,
                              ),
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) {
                setState(() => _current = i);
                widget.onChanged?.call(i);
              },
              children: [
                for (final tab in widget.tabs) Builder(builder: tab.builder),
              ],
            ),
          ),
        ],
      );
}

class _StripTab extends StatelessWidget {
  const _StripTab(this.tab, {required this.picked});
  final SwipeTab tab;
  final bool picked;

  @override
  Widget build(BuildContext context) => Container(
        color: picked ? tab.accent : null,
        padding: SwipeTabsStyle.stripPadding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: picked ? tab.onAccent : SwipeTabsStyle.idle, height: SwipeTabsStyle.lineHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(tab.label,
                    maxLines: 1, style: const TextStyle(fontWeight: Weights.black, fontSize: SwipeTabsStyle.font)),
              ),
              if (tab.sub case final sub?) ...[
                const SizedBox(height: SwipeTabsStyle.subGap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(sub,
                      maxLines: 1,
                      style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: SwipeTabsStyle.subFont,
                          letterSpacing: SwipeTabsStyle.subTracking)),
                ),
              ],
            ],
          ),
        ),
      );
}

class _FolderTab extends StatelessWidget {
  const _FolderTab(this.tab, {required this.picked, required this.first, required this.beforePicked});
  final SwipeTab tab;

  /// The picked tab is open at the bottom into its page and draws both
  /// sides; the others stand on the rule and leave their sides to it.
  final bool picked, first, beforePicked;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Palette.ink, width: SwipeTabsStyle.rule);
    final color = picked ? Palette.ink : SwipeTabsStyle.idle;
    return AnimatedPadding(
      duration: Motion.tab,
      padding: EdgeInsets.only(top: picked ? 0 : SwipeTabsStyle.folderDrop),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: picked ? Palette.paper : SwipeTabsStyle.folderIdleFill,
          border: Border(
            top: side,
            left: picked || first ? side : BorderSide.none,
            right: beforePicked ? BorderSide.none : side,
            bottom: picked ? BorderSide.none : side,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: SwipeTabsStyle.folderBar, color: picked ? tab.accent : null),
            Padding(
              padding: EdgeInsets.only(
                top: SwipeTabsStyle.folderPadding.top,
                bottom: SwipeTabsStyle.folderPadding.bottom + (picked ? SwipeTabsStyle.folderDrop : 0),
                left: SwipeTabsStyle.folderPadding.left,
                right: SwipeTabsStyle.folderPadding.right,
              ),
              child: Center(child: _label(color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(Color color) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: tab.label,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: SwipeTabsStyle.folderFont)),
            if (tab.sub case final sub?)
              TextSpan(
                  text: '  ${sub.toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: SwipeTabsStyle.folderSubFont,
                      letterSpacing: SwipeTabsStyle.folderSubTracking)),
          ]),
          maxLines: 1,
          style: TextStyle(color: color, height: SwipeTabsStyle.lineHeight),
        ),
      );
}
