import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/design.dart';
import '../../l10n/data_strings.dart';
import '../../l10n/strings.dart';
import '../../state/data_store.dart';
import '../manga/manga.dart';
import '../settings/data_actions.dart';
import '../settings/hold_warning_screen.dart';
import '../settings/settings_rows.dart';

/// Shown instead of the app when its data won't open: save the file as it
/// is, restore a backup, or start fresh with the file set aside. The error
/// can be selected and copied for a bug report. In the device's language,
/// as the language setting is in the data.
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key, required this.store, required this.error});

  final DataStore store;
  final String error;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: ListView(
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(title: ScreenTitle(s.recoveryTitle, sub: s.sub?.recoveryTitle)),
              const SizedBox(height: Gaps.section),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox.fromSize(size: RecoveryLayout.tobi, child: const Tobi(pose: TobiPose.shocked)),
                  const SizedBox(width: Gaps.small),
                  Expanded(
                    child: NarrationBox(
                      child: Text(s.recoveryBody,
                          style: const TextStyle(
                              fontSize: RecoveryLayout.bodyFont, height: RecoveryLayout.bodyLineHeight)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gaps.section),
              SettingsGroup(children: [
                SettingsTapRow(
                  title: s.recoverySave,
                  note: s.recoverySaveNote,
                  onTap: () => saveDataCopy(context, store.saveDataFile),
                ),
                SettingsTapRow(
                  title: s.restoreBackup,
                  note: s.recoveryRestoreNote,
                  opensPage: true,
                  onTap: () => Navigator.of(context)
                      .push(MangaRoute<void>(builder: (_) => RestorePage(store: store, confirm: false))),
                ),
                SettingsTapRow(
                  title: s.startFresh,
                  note: s.startFreshNote,
                  danger: true,
                  onTap: () => _startFresh(context),
                ),
              ]),
              const SizedBox(height: SettingsLayout.sectionGap),
              SettingsSection(
                title: s.errorDetails,
                sub: s.sub?.errorDetails,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.paper,
                      border: Border.all(color: Palette.ink, width: Strokes.label),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: RecoveryLayout.errorMaxHeight),
                      child: SingleChildScrollView(
                        padding: RecoveryLayout.errorPadding,
                        child: SelectableText(
                          error,
                          style: const TextStyle(
                            fontFamily: RecoveryLayout.errorFamily,
                            fontSize: RecoveryLayout.errorFont,
                            height: RecoveryLayout.errorLineHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SettingsGroup(children: [
                    SettingsTapRow(
                      title: s.copyText,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: error));
                        if (context.mounted) MangaToast.show(context, s.copiedText);
                      },
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: SettingsLayout.sectionGap),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startFresh(BuildContext context) async {
    final confirmed =
        await Navigator.of(context).push(MangaRoute<bool>(builder: (_) => HoldWarningScreen.startFresh(S.of(context))));
    if (confirmed == true) await store.startFresh();
  }
}
