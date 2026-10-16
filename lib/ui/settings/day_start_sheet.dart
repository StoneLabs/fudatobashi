import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/trainer.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// Lets the player pick the hour their practice day starts at, and stores
/// it. Closing the sheet keeps the hour as it was.
Future<void> pickDayStart(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final hour = await showMangaSheet<int>(
    context,
    barrierColor: DayStartPickerLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => _DayStartSheet(
      selected: progress.settings.dayStartHour,
      allKnown: progress.trainer.config.learningMode == LearningMode.allKnown,
    ),
  );
  if (hour == null || hour == progress.settings.dayStartHour) return;
  await progress.updateSettings(progress.settings.copyWith(dayStartHour: hour));
}

class _DayStartSheet extends StatelessWidget {
  const _DayStartSheet({required this.selected, required this.allKnown});

  final int selected;

  /// All-known mode, which has a streak and no daily set.
  final bool allKnown;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hours = [for (var h = TodaySetTuning.firstDayStartHour; h <= TodaySetTuning.lastDayStartHour; h++) h];
    const columns = DayStartPickerLayout.columns;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(0, DayStartPickerLayout.cut)),
              padding: DayStartPickerLayout.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.dayStart,
                    style: const TextStyle(
                        fontFamily: Fonts.display, fontSize: DayStartPickerLayout.title, height: TypeScale.displayLineHeight),
                  ),
                  if (s.sub != null) ...[
                    const SizedBox(height: DayStartPickerLayout.subGap),
                    Text(
                      s.sub!.dayStart,
                      style: const TextStyle(
                          fontWeight: Weights.black, fontSize: DayStartPickerLayout.sub, color: Palette.inkSoft),
                    ),
                  ],
                  const SizedBox(height: DayStartPickerLayout.gridGap),
                  for (var first = 0; first < hours.length; first += columns) ...[
                    if (first > 0) const SizedBox(height: DayStartPickerLayout.cellGap),
                    Row(children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: DayStartPickerLayout.cellGap),
                        Expanded(
                          child: first + c < hours.length
                              ? _HourCell(hour: hours[first + c], selected: hours[first + c] == selected)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ]),
                  ],
                  const SizedBox(height: DayStartPickerLayout.noteGap),
                  Text(
                    allKnown ? s.dayStartChangeKnown : s.dayStartChange,
                    style: const TextStyle(
                      fontWeight: Weights.bold,
                      fontSize: DayStartPickerLayout.note,
                      height: DayStartPickerLayout.noteLineHeight,
                      color: Palette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({required this.hour, required this.selected});

  final int hour;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).hourOfDay(hour);
    final cell = SizedBox(
      height: DayStartPickerLayout.cellHeight,
      child: InkButton(
        color: selected ? Palette.sun : Palette.paper,
        border: Strokes.control,
        padding: DayStartPickerLayout.cellPadding,
        semanticLabel: label,
        onTap: () => Navigator.pop(context, hour),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontFamily: Fonts.display, fontSize: DayStartPickerLayout.cellFont)),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: selected ? Transform.rotate(angle: DayStartPickerLayout.selectedTurnDeg * math.pi / 180, child: cell) : cell,
    );
  }
}
