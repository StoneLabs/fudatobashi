import 'dart:math' as math;

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

  /// The picked tab's colour: its chip's fill in [SwipeTabsLook.slant], the
  /// bar along its top in [SwipeTabsLook.folders].
  final Color accent;

  /// The picked tab's lettering on [accent] in [SwipeTabsLook.slant].
  final Color onAccent;
  final WidgetBuilder builder;
}

/// How [SwipeTabs] draws its tab row.
enum SwipeTabsLook {
  /// Outlined folder tabs standing on a thick rule, the picked one white
  /// with a bar along its top, pulled up and open into its page.
  folders,

  /// Small labels on a thick rule, the picked one standing on it as a chip
  /// slanted like the banners, filled with its accent.
  slant,
}

/// Pages side by side under a row of tabs: swipe between them, or tap a
/// tab.
class SwipeTabs extends StatefulWidget {
  const SwipeTabs({
    super.key,
    required this.tabs,
    this.initial = 0,
    required this.look,
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
            child: _Ruled(
              look: widget.look,
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
                            SwipeTabsLook.folders => _FolderTab(
                                tab,
                                picked: i == _current,
                                first: i == 0,
                                beforePicked: i + 1 == _current,
                              ),
                            SwipeTabsLook.slant => _SlantTab(tab, picked: i == _current),
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

/// The tab row's thick rule over the foot of the slanted chip; none under
/// the folders.
class _Ruled extends StatelessWidget {
  const _Ruled({required this.look, required this.child});
  final SwipeTabsLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (look) {
        SwipeTabsLook.folders => child,
        SwipeTabsLook.slant => Stack(children: [
            child,
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: SwipeTabsStyle.rule,
              child: ColoredBox(color: Palette.ink),
            ),
          ]),
      };
}

/// A tab of [SwipeTabsLook.slant]: its label, and when [picked] the
/// slanted chip behind it.
class _SlantTab extends StatelessWidget {
  const _SlantTab(this.tab, {required this.picked});
  final SwipeTab tab;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Palette.ink, width: SwipeTabsStyle.chipBorder);
    final sub = tab.sub;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SwipeTabsStyle.slantHeight),
      child: Stack(children: [
        if (picked)
          Positioned(
            left: SwipeTabsStyle.chipInset,
            right: SwipeTabsStyle.chipInset,
            top: SwipeTabsStyle.chipTop,
            bottom: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(Tilt.tagSkew * math.pi / 180),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tab.accent,
                  border: const Border(top: side, left: side, right: side),
                ),
              ),
            ),
          ),
        Padding(
          padding: SwipeTabsStyle.slantPadding,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: picked ? tab.onAccent : SwipeTabsStyle.slantIdle,
              fontWeight: picked ? Weights.black : Weights.bold,
              height: SwipeTabsStyle.lineHeight,
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tab.label, maxLines: 1, style: const TextStyle(fontSize: SwipeTabsStyle.slantFont)),
                ),
                if (sub != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(sub,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: SwipeTabsStyle.subFont, letterSpacing: SwipeTabsStyle.subTracking)),
                  ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
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
