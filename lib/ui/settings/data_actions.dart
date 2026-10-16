import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/data_strings.dart';
import '../../l10n/strings.dart';
import '../../state/backups.dart';
import '../../state/data_store.dart';
import '../manga/manga.dart';
import 'hold_warning_screen.dart';
import 'settings_rows.dart';

/// Makes the [DataStore] available to Settings and the recovery screen;
/// absent where the data is not a file (tests, the web).
class DataStoreScope extends InheritedWidget {
  const DataStoreScope({super.key, required this.store, required super.child});

  final DataStore store;

  static DataStore? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<DataStoreScope>()?.store;

  @override
  bool updateShouldNotify(DataStoreScope oldWidget) => store != oldWidget.store;
}

/// Offers [save]'s file to the system's save dialog; a toast once saved.
Future<void> saveDataCopy(BuildContext context, Future<bool> Function() save) async {
  final s = S.of(context);
  try {
    if (await save() && context.mounted) MangaToast.show(context, s.backupSaved);
  } catch (_) {
    if (context.mounted) await showDataProblem(context, s.backupSaveFailed);
  }
}

/// Checks [backup], asks for the hold to confirm when [confirm], then
/// restores it; the app then starts over (and tells how it went).
Future<void> restoreBackup(BuildContext context, DataStore store, File backup, {required bool confirm}) async {
  final s = S.of(context);
  try {
    checkBackup(backup);
  } on BackupRejected catch (e) {
    if (context.mounted) await showDataProblem(context, s.restoreProblem(e.problem));
    return;
  }
  if (!context.mounted) return;
  if (confirm) {
    final confirmed = await Navigator.of(context).push(MangaRoute<bool>(builder: (_) => HoldWarningScreen.restore(s)));
    if (confirmed != true) return;
  }
  try {
    await store.restore(backup);
  } on RestoreFailed {
    // The app has started over, and tells it there.
  }
}

/// Lets the player pick a backup file, then restores it as [restoreBackup].
Future<void> pickBackup(BuildContext context, DataStore store, {required bool confirm}) async {
  final file = await store.dialogs.pick();
  if (file != null && context.mounted) await restoreBackup(context, store, file, confirm: confirm);
}

/// A plain message about the data, with a Close button.
Future<void> showDataProblem(BuildContext context, String body, {String? title}) {
  final s = S.of(context);
  return showMangaSheet<void>(
    context,
    barrierColor: DataSheetLayout.barrier,
    barrierLabel: s.close,
    builder: (context) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              padding: DataSheetLayout.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title ?? s.restoreProblemTitle,
                    style: const TextStyle(
                        fontFamily: Fonts.display, fontSize: DataSheetLayout.title, height: TypeScale.displayLineHeight),
                  ),
                  const SizedBox(height: DataSheetLayout.gap),
                  Text(body,
                      style: const TextStyle(
                          fontWeight: Weights.bold, fontSize: DataSheetLayout.body, height: DataSheetLayout.lineHeight)),
                  const SizedBox(height: DataSheetLayout.gap),
                  SizedBox(
                    height: ButtonMetrics.rowHeight,
                    child: InkButton(
                      color: Palette.sun,
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(s.close,
                          style: const TextStyle(fontWeight: Weights.black, fontSize: SettingsLayout.titleFont)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Restore from a backup: a file the player picks, or one of the copies in
/// the app's backups folder, newest first. [confirm] asks for the hold
/// first (the current data is replaced; the recovery screen has none open).
class RestorePage extends StatelessWidget {
  const RestorePage({super.key, required this.store, required this.confirm});

  final DataStore store;
  final bool confirm;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final copies = store.copies();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.restoreBackup, sub: s.sub?.restoreBackup),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: ListView(
                  children: [
                    SettingsGroup(children: [
                      SettingsTapRow(
                        title: s.restoreChooseFile,
                        note: s.restoreChooseFileNote,
                        opensPage: true,
                        onTap: () => pickBackup(context, store, confirm: confirm),
                      ),
                    ]),
                    if (copies.isNotEmpty) ...[
                      const SizedBox(height: SettingsLayout.sectionGap),
                      SettingsSection(
                        title: s.restoreCopies,
                        sub: s.sub?.restoreCopies,
                        footnote: s.restoreCopiesNote(DataFileTuning.keptCopies),
                        children: [
                          SettingsGroup(children: [
                            for (final copy in copies)
                              SettingsTapRow(
                                title: s.copyDate(copy),
                                note: s.copyKind(copy.kind),
                                onTap: () => restoreBackup(context, store, copy.file, confirm: confirm),
                              ),
                          ]),
                        ],
                      ),
                    ],
                    const SizedBox(height: SettingsLayout.sectionGap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
