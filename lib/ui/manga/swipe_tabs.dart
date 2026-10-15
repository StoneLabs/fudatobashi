import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import 'buttons.dart';

/// One page of [SwipeTabs]: its tab's label, a small sub-label under it
/// (the other language, or a hint), and its contents.
class SwipeTab {
  const SwipeTab({required this.label, this.sub, required this.builder});
  final String label;
  final String? sub;
  final WidgetBuilder builder;
}

/// Pages side by side under a thin row of tabs: swipe between them, or tap
/// a tab. With [pager], a bar along the bottom steps through them too: ‹ ›,
/// the page's name, where it is and a dot for each page.
class SwipeTabs extends StatefulWidget {
  const SwipeTabs({
    super.key,
    required this.tabs,
    this.initial = 0,
    this.pager,
    this.onChanged,
    this.header,
  });

  final List<SwipeTab> tabs;
  final int initial;

  /// The bottom bar's words: "{0} of {1}" and the buttons' labels; null
  /// for no bottom bar.
  final SwipePagerWords? pager;
  final ValueChanged<int>? onChanged;

  /// Shown between the tabs and the pages.
  final Widget? header;

  @override
  State<SwipeTabs> createState() => _SwipeTabsState();
}

/// The words of [SwipeTabs]' bottom bar.
class SwipePagerWords {
  const SwipePagerWords({required this.position, required this.previous, required this.next});

  /// "{0} of {1}".
  final String position;
  final String previous, next;
}

class _SwipeTabsState extends State<SwipeTabs> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _current = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= widget.tabs.length) return;
    _pages.animateToPage(i, duration: Motion.sheet, curve: Motion.routeCurve);
  }

  @override
  Widget build(BuildContext context) {
    final pager = widget.pager;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabRow(tabs: widget.tabs, current: _current, onTap: _go),
        ?widget.header,
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
        if (pager != null)
          _PagerBar(
            words: pager,
            label: widget.tabs[_current].label,
            current: _current,
            count: widget.tabs.length,
            onGo: _go,
          ),
      ],
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.tabs, required this.current, required this.onTap});
  final List<SwipeTab> tabs;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.ink, width: Strokes.control)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, tab) in tabs.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == current,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Container(
                      color: i == current ? Palette.ink : Palette.paper,
                      padding: SwipeTabsStyle.tabPadding,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: i == current ? Palette.paper : SwipeTabsStyle.idle),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(tab.label,
                                  maxLines: 1,
                                  style: const TextStyle(fontWeight: Weights.black, fontSize: SwipeTabsStyle.font)),
                            ),
                            if (tab.sub case final sub?)
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _PagerBar extends StatelessWidget {
  const _PagerBar({
    required this.words,
    required this.label,
    required this.current,
    required this.count,
    required this.onGo,
  });

  final SwipePagerWords words;
  final String label;
  final int current, count;
  final ValueChanged<int> onGo;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.paper,
          border: Border(top: BorderSide(color: Palette.ink, width: Strokes.control)),
        ),
        child: Padding(
          padding: SwipeTabsStyle.pagerPadding,
          child: Row(
            children: [
              Opacity(
                opacity: current > 0 ? 1 : ChartStyle.dimOpacity,
                child: InkIconButton(icon: IconArt.back, semanticLabel: words.previous, onTap: () => onGo(current - 1)),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body)),
                    Text(
                      words.position.replaceAll('{0}', '${current + 1}').replaceAll('{1}', '$count').toUpperCase(),
                      style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: SwipeTabsStyle.subFont,
                          letterSpacing: SwipeTabsStyle.subTracking),
                    ),
                    const SizedBox(height: Gaps.tight),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++)
                          Container(
                            width: SwipeTabsStyle.dot,
                            height: SwipeTabsStyle.dot,
                            margin: const EdgeInsets.symmetric(horizontal: SwipeTabsStyle.dotGap / 2),
                            decoration: BoxDecoration(
                              color: i == current ? Palette.ink : Palette.paper,
                              border: Border.all(color: Palette.ink, width: Strokes.hairline),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: current < count - 1 ? 1 : ChartStyle.dimOpacity,
                child: InkIconButton(icon: IconArt.chevron, semanticLabel: words.next, onTap: () => onGo(current + 1)),
              ),
            ],
          ),
        ),
      );
}
