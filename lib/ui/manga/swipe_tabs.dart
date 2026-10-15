import 'package:flutter/material.dart';

import '../../config/design.dart';

/// One page of [SwipeTabs]: its tab's label, a small sub-label under it
/// (the other language, or a hint), and its contents.
class SwipeTab {
  const SwipeTab({required this.label, this.sub, this.accent = Palette.ink, required this.builder});
  final String label;
  final String? sub;

  /// The picked tab's colour: its fill in a [SwipeTabsLook.strip], the bar
  /// along its top in [SwipeTabsLook.folders].
  final Color accent;
  final WidgetBuilder builder;
}

/// How [SwipeTabs] draws its tab row.
enum SwipeTabsLook {
  /// Small two-line labels over a thick rule, the picked one filled.
  strip,

  /// Two outlined folder tabs standing on a thick rule, the picked one
  /// white with a bar along its top.
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
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.ink, width: SwipeTabsStyle.rule)),
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
                            SwipeTabsLook.folders => _FolderTab(tab, picked: i == _current, first: i == 0),
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
          style: TextStyle(color: picked ? Palette.paper : SwipeTabsStyle.idle, height: SwipeTabsStyle.lineHeight),
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
  const _FolderTab(this.tab, {required this.picked, required this.first});
  final SwipeTab tab;
  final bool picked, first;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Palette.ink, width: SwipeTabsStyle.rule);
    final color = picked ? Palette.ink : SwipeTabsStyle.idle;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: picked ? Palette.paper : SwipeTabsStyle.folderIdleFill,
        border: Border(top: side, right: side, left: first ? side : BorderSide.none),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: SwipeTabsStyle.folderBar, color: picked ? tab.accent : null),
          Padding(
            padding: SwipeTabsStyle.folderPadding,
            child: Center(child: _label(color)),
          ),
        ],
      ),
    );
  }

  Widget _label(Color color) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: tab.label, style: const TextStyle(fontWeight: Weights.black, fontSize: SwipeTabsStyle.folderFont)),
            if (tab.sub case final sub?)
              TextSpan(
                  text: '  $sub',
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: SwipeTabsStyle.folderSubFont,
                      letterSpacing: SwipeTabsStyle.subTracking)),
          ]),
          maxLines: 1,
          style: TextStyle(color: color, height: SwipeTabsStyle.lineHeight),
        ),
      );
}
