import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../manga/manga.dart';

/// A group of settings under a header: [title] in an ink banner, the
/// second-language [sub] beside it and a rule running out to the edge.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.sub, required this.children, this.footnote});

  final String title;
  final String sub;
  final List<Widget> children;

  /// A small note under the section's last setting.
  final String? footnote;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(children: [
              const SizedBox(width: SettingsLayout.headerInset),
              InkBanner(title.toUpperCase(), fontSize: SettingsLayout.headerFont),
              const SizedBox(width: SettingsLayout.headerSubGap),
              Text(sub, style: const TextStyle(fontWeight: Weights.black, fontSize: SettingsLayout.headerSubFont)),
              const SizedBox(width: SettingsLayout.headerSubGap),
              const Expanded(
                child: SizedBox(height: SettingsLayout.headerRule, child: ColoredBox(color: Palette.ink)),
              ),
            ]),
          ),
          const SizedBox(height: SettingsLayout.headerGap),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: SettingsLayout.itemGap),
            child,
          ],
          if (footnote != null) ...[
            const SizedBox(height: SettingsLayout.footnoteGap),
            Text(footnote!, style: _noteStyle),
          ],
        ],
      );
}

/// A setting's name with its one-line [note] under it, above the choice
/// buttons it names.
class SettingsLabel extends StatelessWidget {
  const SettingsLabel({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: SettingsLayout.labelGap),
        child: _TitleNote(title: title, note: note),
      );
}

/// Rows in one ink panel, split by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => MangaPanel(
        padding: const EdgeInsets.all(Strokes.panel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: Strokes.hairline, child: ColoredBox(color: Palette.ink)),
              child,
            ],
          ],
        ),
      );
}

/// A switch with its name and note; tapping anywhere on the row flips it.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.title, this.note, required this.value, required this.onChanged});

  final String title;
  final String? note;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: _Row(
            children: [
              Expanded(child: _TitleNote(title: title, note: note)),
              Switch(value: value, onChanged: onChanged, activeThumbColor: Palette.pink),
            ],
          ),
        ),
      );
}

/// A slider under its name and note, e.g. the music volume; [enabled] false
/// dims the whole row and disables the slider (its switch is off).
class SettingsSlider extends StatelessWidget {
  const SettingsSlider({
    super.key,
    required this.title,
    this.note,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String? note;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: enabled ? 1 : SettingsLayout.disabledOpacity,
        duration: Motion.stampFade,
        child: Padding(
          padding: SettingsLayout.rowPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TitleNote(title: title, note: note),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Palette.pink,
                  thumbColor: Palette.pink,
                  trackHeight: SettingsLayout.sliderTrackHeight,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: SettingsLayout.sliderThumbRadius),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: SettingsLayout.sliderOverlayRadius),
                ),
                child: Slider(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  label: '${(value * 100).round()}%',
                ),
              ),
            ],
          ),
        ),
      );
}

/// A row that stamps when tapped: its name and note on the left, then
/// [value] and, when it opens a page, a chevron.
class SettingsTapRow extends StatelessWidget {
  const SettingsTapRow({
    super.key,
    required this.title,
    this.note,
    this.value,
    this.opensPage = false,
    this.danger = false,
    required this.onTap,
  });

  final String title;
  final String? note;
  final String? value;
  final bool opensPage;

  /// Titled in alarm red: it leads to something that can't be undone.
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        drop: 0,
        turn: 0,
        scale: Press.panelScale,
        builder: (context, pressed) => Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: pressed ? Tones.stampOpacity : 0,
                duration: Motion.stampFade,
                child: const ToneBox(Tones.stamp),
              ),
            ),
            _Row(children: [
              Expanded(child: _TitleNote(title: title, note: note, color: danger ? Palette.alarmDeep : Palette.ink)),
              if (value != null)
                Text(value!,
                    style: const TextStyle(
                        fontWeight: Weights.bold, fontSize: SettingsLayout.valueFont, color: Palette.inkSoft)),
              if (opensPage) ...[
                const SizedBox(width: Gaps.small),
                MangaIcon(IconArt.chevron, size: SettingsLayout.chevron, color: Palette.mute),
              ],
            ]),
          ],
        ),
      );
}

const _noteStyle = TextStyle(
  fontWeight: Weights.bold,
  fontSize: SettingsLayout.noteFont,
  height: SettingsLayout.noteLineHeight,
  color: Palette.inkSoft,
);

class _Row extends StatelessWidget {
  const _Row({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SettingsLayout.rowMinHeight),
        child: Padding(
          padding: SettingsLayout.rowPadding,
          child: Row(children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(width: SettingsLayout.rowGap),
              child,
            ],
          ]),
        ),
      );
}

class _TitleNote extends StatelessWidget {
  const _TitleNote({required this.title, this.note, this.color = Palette.ink});
  final String title;
  final String? note;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontWeight: Weights.black, fontSize: SettingsLayout.titleFont, color: color)),
          if (note != null) ...[
            const SizedBox(height: SettingsLayout.noteGap),
            Text(note!, style: _noteStyle),
          ],
        ],
      );
}
