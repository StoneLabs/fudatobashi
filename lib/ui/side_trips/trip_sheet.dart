import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../ankiren/ankiren_strikes.dart';
import '../manga/manga.dart';
import '../shell/tab_chains.dart';

/// A side trip's sheets' frame: free practice's floating panel, its top edge
/// tilted, at the bottom of the screen. Its head is [title] in display
/// type with the other language's [sub], each breaking only between
/// words, an optional [line] under them and a close button; then [body],
/// a block at a time, scrolling when the screen is short; then [footer],
/// which stays in view.
class TripSheet extends StatelessWidget {
  const TripSheet({super.key, required this.title, this.sub, this.line, required this.body, this.footer});

  final String title;
  final String? sub;
  final String? line;
  final List<Widget> body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final line = this.line;
    final footer = this.footer;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(0, FreePracticeLayout.sheetCut)),
              padding: AnkirenSheetLayout.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(children: [
                              Phrases.span(title),
                              if (sub != null) ...[
                                const TextSpan(text: '  '),
                                Phrases.span(
                                  sub!.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: Fonts.ui,
                                    fontWeight: Weights.black,
                                    fontSize: AnkirenSheetLayout.titleSubFont,
                                    letterSpacing: AnkirenSheetLayout.titleSubTracking * AnkirenSheetLayout.titleSubFont,
                                  ),
                                ),
                              ],
                            ]),
                            style: const TextStyle(
                                fontFamily: Fonts.display,
                                fontSize: AnkirenSheetLayout.titleFont,
                                height: TypeScale.displayLineHeight),
                          ),
                        ),
                        if (line != null) ...[
                          const SizedBox(height: AnkirenSheetLayout.lineGap),
                          Text.rich(
                            Phrases.span(line),
                            style: const TextStyle(
                                fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.lineFont, color: Palette.mute),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(width: AnkirenSheetLayout.headGap),
                    InkIconButton(icon: IconArt.close, semanticLabel: s.close, onTap: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: AnkirenSheetLayout.gap),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, block) in body.indexed) ...[
                            if (i > 0) const SizedBox(height: AnkirenSheetLayout.gap),
                            block,
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (footer != null) ...[const SizedBox(height: AnkirenSheetLayout.gap), footer],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section's label, with the other language's [sub] in small tracked
/// capitals, each breaking only between words.
class SheetLabel extends StatelessWidget {
  const SheetLabel(this.text, this.sub, {super.key});

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(text),
          if (sub != null) ...[
            const TextSpan(text: ' '),
            Phrases.span(
              sub!.toUpperCase(),
              style: const TextStyle(
                fontSize: AnkirenSheetLayout.labelSubFont,
                letterSpacing: AnkirenSheetLayout.labelSubTracking * AnkirenSheetLayout.labelSubFont,
              ),
            ),
          ],
        ]),
        style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.labelFont),
      );
}

/// One key of the level keys: Settings' choice colours (sun when [chosen],
/// desk grey when the known cards do not [fits] it or it is [locked]),
/// [top] over [bottom]; chained when [locked], checked when [cleared].
class SheetKey extends StatelessWidget {
  const SheetKey({
    super.key,
    required this.semanticLabel,
    required this.chosen,
    required this.fits,
    required this.locked,
    required this.cleared,
    required this.onTap,
    required this.top,
    this.bottom,
  });

  final String semanticLabel;
  final bool chosen, fits, locked, cleared;
  final VoidCallback onTap;
  final Widget top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: chosen,
        child: SizedBox(
          height: AnkirenSheetLayout.keyHeight,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: InkButton(
                onTap: onTap,
                color: chosen
                    ? Palette.sun
                    : fits && !locked
                        ? Palette.paper
                        : Palette.desk,
                border: chosen ? AnkirenSheetLayout.keyChosenBorder : AnkirenSheetLayout.keyBorder,
                padding: AnkirenSheetLayout.keyPadding,
                semanticLabel: semanticLabel,
                child: Opacity(
                  opacity: locked ? AnkirenSheetLayout.lockedOpacity : 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DefaultTextStyle.merge(style: const TextStyle(height: 1), child: top),
                      if (bottom != null) ...[
                        const SizedBox(height: AnkirenSheetLayout.keyLabelGap),
                        DefaultTextStyle.merge(style: const TextStyle(height: 1), child: bottom!),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
            if (locked) const Positioned.fill(child: ClipRect(child: TabChains(scale: AnkirenSheetLayout.chainScale))),
            if (cleared)
              const Positioned(
                right: -AnkirenSheetLayout.checkOut,
                top: -AnkirenSheetLayout.checkOut,
                child: ClearedCheck(size: AnkirenSheetLayout.check),
              ),
          ]),
        ),
      );
}

/// [keys] in rows of [perRow], as wide as each other.
class SheetKeyGrid extends StatelessWidget {
  const SheetKeyGrid(this.keys, {super.key, this.perRow = AnkirenSheetLayout.keysPerRow});

  final List<Widget> keys;
  final int perRow;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var row = 0; row < keys.length; row += perRow) ...[
          if (row > 0) const SizedBox(height: AnkirenSheetLayout.keyGap),
          Row(children: [
            for (var i = row; i < row + perRow; i++) ...[
              if (i > row) const SizedBox(width: AnkirenSheetLayout.keyGap),
              Expanded(child: i < keys.length ? keys[i] : const SizedBox.shrink()),
            ],
          ]),
        ],
      ]);
}

/// How the levels open ([line]), by a struck card; or, once every level is
/// cleared, the all-clear stamp and a cheer.
class SheetUnlockNote extends StatelessWidget {
  const SheetUnlockNote({super.key, required this.allCleared, required this.line});

  final bool allCleared;
  final String line;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.noteFont);
    return Row(children: [
      if (allCleared)
        Sticker(
          tilt: AnkirenSheetLayout.stampTilt,
          child: Text(s.ankirenAllClearStamp,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stampFont, height: 1)),
        )
      else
        const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenSheetLayout.noteCard),
      const SizedBox(width: AnkirenSheetLayout.noteGap),
      Expanded(child: Text.rich(Phrases.span(allCleared ? s.ankirenAllCleared : line), style: style)),
    ]);
  }
}

/// A stepper: its [label] at the left, which gives way first, then − value
/// +; an end reached disables its button. Given [repeatEvery], a button
/// held down steps on by itself that often until it is let go or its end is
/// reached.
class SheetStepper extends StatelessWidget {
  const SheetStepper(
      {super.key, required this.label, required this.value, required this.onLess, required this.onMore, this.repeatEvery});

  final Widget label, value;
  final VoidCallback? onLess, onMore;
  final Duration? repeatEvery;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget button(String sign, String name, VoidCallback? onTap) => SizedBox.square(
          dimension: AnkirenSheetLayout.stepperButton,
          child: _RepeatsHeld(
            onTap: onTap,
            every: repeatEvery,
            child: InkButton(
              onTap: onTap,
              color: onTap == null ? Palette.desk : Palette.paper,
              border: Strokes.control,
              semanticLabel: name,
              child: Text(sign,
                  style:
                      const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperSignFont, height: 1)),
            ),
          ),
        );
    return Row(children: [
      Expanded(child: label),
      const SizedBox(width: AnkirenSheetLayout.stepperGap),
      button('−', s.ankirenLess, onLess),
      SizedBox(
        width: AnkirenSheetLayout.stepperValueWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AnkirenSheetLayout.stepperGap),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: value)),
        ),
      ),
      button('+', s.ankirenMore, onMore),
    ]);
  }
}

/// [child], which once held down long calls [onTap] at once and then
/// [every] so often until it is let go or [onTap] is gone; as it is without
/// [every].
class _RepeatsHeld extends StatefulWidget {
  const _RepeatsHeld({required this.onTap, required this.every, required this.child});

  final VoidCallback? onTap;
  final Duration? every;
  final Widget child;

  @override
  State<_RepeatsHeld> createState() => _RepeatsHeldState();
}

class _RepeatsHeldState extends State<_RepeatsHeld> {
  Timer? _timer;

  void _step() {
    final onTap = widget.onTap;
    if (onTap == null) return _stop();
    onTap();
  }

  void _start(Duration every) {
    _step();
    _timer = Timer.periodic(every, (_) => _step());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final every = widget.every;
    final repeats = every != null && widget.onTap != null;
    return GestureDetector(
      onLongPressStart: repeats ? (_) => _start(every) : null,
      onLongPressEnd: repeats ? (_) => _stop() : null,
      onLongPressCancel: repeats ? _stop : null,
      child: widget.child,
    );
  }
}
